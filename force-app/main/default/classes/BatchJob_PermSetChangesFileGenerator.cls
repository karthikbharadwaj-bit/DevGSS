public without sharing class BatchJob_PermSetChangesFileGenerator implements Database.Batchable<SObject>, Database.Stateful {
    
    // --------------------------
    // CSV ROW HOLDERS
    // --------------------------
    
    private List<String> psAssignRows = new List<String>();
    
    // Cache for Permission Set lookups to avoid SOQL in loops
    private Map<String, Id> permSetCache = new Map<String, Id>();

    // --------------------------
    // BATCH START
    // --------------------------
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Calculate datetime for 24 hours ago
        Datetime last24Hours = Datetime.now().addHours(-24);
         
       String query = 'SELECT Id, CreatedDate, CreatedById, CreatedBy.Name, ' +
               'Section, Display, Action ' +
               'FROM SetupAuditTrail ' +
               'WHERE Action IN (\'PermSetAssign\', \'PermSetUnassign\') ' +
               'AND CreatedDate >= :last24Hours ' +
               'ORDER BY CreatedDate DESC';
        
        // Add LIMIT in test context to avoid "Too many query locator rows" error
        if (Test.isRunningTest()) {
            query += ' LIMIT 200';
        }
        
        return Database.getQueryLocator(query);
    }

    // --------------------------
    // UTILITY HELPERS
    // --------------------------

    private String safe(Object o) {
        return o == null ? '' : String.valueOf(o);
    }
    
    private String getPermissionSetId(String psLabel) {
        if (String.isBlank(psLabel)){
            return '';
        }
        // Check cache first
        if (permSetCache.containsKey(psLabel)) {
            return String.valueOf(permSetCache.get(psLabel));
        }
        
        // Query if not in cache
        try {
            List<PermissionSet> psList = [
                SELECT Id 
                FROM PermissionSet
                WHERE Label = :psLabel 
                LIMIT 1
            ];
            
            if (!psList.isEmpty()) {
                permSetCache.put(psLabel, psList[0].Id);
                return String.valueOf(psList[0].Id);
            } else {
                System.debug(LoggingLevel.WARN, 'Permission Set not found: ' + psLabel);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error querying Permission Set ' + psLabel + ': ' + e.getMessage());
        }
        
        return '';
    }

    private String extractUserId(String text) {
        if (text == null){
            return '';
        }
        // Matches (UserID: [005..])
        Pattern p = Pattern.compile('\\[005[A-Za-z0-9]{12}\\]');
        Matcher m = p.matcher(text);
        if (m.find()) {
            String full = m.group(0); // [005xxxxx]
            return full.replace('[','').replace(']','');
        }
        return '';
    }

    private String extractSfid(String text) {
        if (text == null){
            return '';
        }
        Pattern p = Pattern.compile('\\b[0-9A-Za-z]{15,18}\\b');
        Matcher m = p.matcher(text);
        if (m.find()) {
            return m.group(0);
        }
        return '';
    }

    // --------------------------
    // BATCH EXECUTE
    // --------------------------
    public void execute(Database.BatchableContext bc, List<SetupAuditTrail> scope) {

        for (SetupAuditTrail s : scope) {
            String act = s.Action;

            // =====================================================================
            // 1. PERMISSION SET ASSIGNED / UNASSIGNED (WITH USER)
            // =====================================================================
            if (act == 'PermSetAssign' || act == 'PermSetUnassign') {

                String detail = safe(s.Display);

                // Extract user from: "assigned to user John Doe (UserID: [005xx])"
                String userId = extractUserId(detail);

                // Extract Permission Set Id by Label
                String psLabel = '';
                if (detail.contains('Permission set')) {
                    psLabel = detail.substringAfter('Permission set ').substringBefore(':').trim();
                }

                String psId = '';
                if (String.isNotBlank(psLabel)) {
                    psId = getPermissionSetId(psLabel);
                }

                psAssignRows.add(
                    safe(s.CreatedDate) + ',' +
                    psLabel + ',' +
                    psId + ',' +
                    act + ',' +
                    userId + ',' +
                    detail
                );
            }
        }
    }

    // --------------------------
    // BATCH FINISH → SAVE CSV FILES
    // --------------------------
    public void finish(Database.BatchableContext bc) {
        createFileIfNotEmpty(psAssignRows, 'SFDC_PermSet_Changes');
        
        // Log governor limits
        System.debug('Governor Limits - Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
        System.debug('Governor Limits - DML Statements: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements());
        System.debug('Governor Limits - Heap Size: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize() + ' bytes');
    }

    private void createFileIfNotEmpty(List<String> rows, String baseName) {
        if (rows.isEmpty()) {
            System.debug('No records to create file for: ' + baseName);
            return;
        }
        
        try {
            String header = 'Timestamp,PermissionSet Name,PermissionSetId,Action,UserId,Details\n';
            String body = header + String.join(rows, '\n');
            String timestamp = Datetime.now().format('yyyyMMdd_HHmmss');
            ContentVersion cv = new ContentVersion();
            cv.Title = baseName + '_' + timestamp;
            cv.PathOnClient = baseName + '_' + timestamp + '.csv';
            cv.VersionData = Blob.valueOf(body);
            cv.IsMajorVersion = true;
            insert cv;
            System.debug('SUCCESS: Created file ' + cv.Title + ' with ' + rows.size() + ' records');
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'FAILED: Error creating file ' + baseName + ': ' + e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'FAILED: Unexpected error creating file ' + baseName + ': ' + e.getMessage());
        }
    }

}