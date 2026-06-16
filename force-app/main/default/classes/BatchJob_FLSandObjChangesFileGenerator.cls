public without sharing class BatchJob_FLSandObjChangesFileGenerator implements Database.Batchable<SObject>, Database.Stateful {

    private List<String> flsRows = new List<String>();
    private List<String> objAccessRows = new List<String>();
    
    // Caches to avoid repeated SOQL
    private Map<String, Id> profileIdMap = new Map<String, Id>();
    private Map<String, Id> permSetIdMap = new Map<String, Id>();
    
    // Static regex patterns for better performance
    private static final Pattern FLS_PATTERN = Pattern.compile('Changed (?:profile|permission set) (.*?): field-level security for (.*?): (.*?) was changed from (.*?) to (.*)');
    private static final Pattern OBJ_PERM_PATTERN = Pattern.compile('Changed (?:profile|permission set) (.*?): (.*?) object permissions were changed from (.*?) to (.*)');
    private static final Pattern PERMSET_NAME_PATTERN = Pattern.compile('Permission set (.*?)(:|$)');

    public Database.QueryLocator start(Database.BatchableContext bc) {

        // Calculate datetime for 24 hours ago
        Datetime last24Hours = Datetime.now().addHours(-24);

    	String query = 'SELECT Id, CreatedDate, CreatedBy.Name, Action, Display ' +
                   'FROM SetupAuditTrail ' +
                   'WHERE Action IN (' +
                       '\'PermSetFlsChanged\', ' +
                       '\'profileFlsChangedCustom\', ' +
                       '\'PermSetEntityPermChanged\', ' +
                       '\'profileOlpChangedCustom\'' +
                   ') ' +
                   'AND CreatedDate >= :last24Hours ' +
                   'ORDER BY CreatedDate DESC';
        // Add LIMIT in test context to avoid "Too many query locator rows" error
        if (Test.isRunningTest()) {
            query += ' LIMIT 200';
        }   
    	return Database.getQueryLocator(query);
	}

    public void execute(Database.BatchableContext bc, List<SetupAuditTrail> scope) {
        for (SetupAuditTrail log : scope) {
            String csvLine = parseAuditLog(log);
            if (String.isNotBlank(csvLine)) {
                if (log.Action == 'PermSetFlsChanged' || log.Action == 'profileFlsChangedCustom') {
                    flsRows.add(csvLine);
                } else if (log.Action == 'PermSetEntityPermChanged' || log.Action == 'profileOlpChangedCustom') {
                    objAccessRows.add(csvLine);
                } 
            }
        }
    }

    private String parseAuditLog(SetupAuditTrail log) {
        String action = log.Action;
        String display = log.Display;
        String category = '';
        String name = '';
        String entityId = '';
        String objectField = '';
        String oldAccess = '';
        String newAccess = '';
        String changeType = '';

        if (action == 'PermSetFlsChanged' || action == 'profileFlsChangedCustom') {
            category = action.startsWith('PermSet') ? 'Permission Set' : 'Profile';
            Matcher m = FLS_PATTERN.matcher(display);
            if (m.find()) {
                name = m.group(1).trim();
                entityId = getEntityId(category, name);
                objectField = getQualifiedFieldName(m.group(2).trim(), m.group(3).trim());
                oldAccess = m.group(4).trim();
                newAccess = m.group(5).trim();
                changeType = 'Field-Level Security Changed';
            }
        }
        else if (action == 'PermSetEntityPermChanged' || action == 'profileOlpChangedCustom') {
            category = action.startsWith('PermSet') ? 'Permission Set' : 'Profile';
            Matcher m = OBJ_PERM_PATTERN.matcher(display);
            if (m.find()) {
                name = m.group(1).trim();
                entityId = getEntityId(category, name);
                objectField = getObjectApiName(m.group(2).trim());
                oldAccess = m.group(3).trim();
                newAccess = m.group(4).trim();
                changeType = 'Object Permission Changed';
            }
        }

        if (String.isBlank(changeType)){
            return null;
        }
        return String.join(new String[] {
            formatCsv(log.CreatedDate.format()),
            formatCsv(log.CreatedBy.Name),
            formatCsv(category),
            formatCsv(name),
            formatCsv(entityId),
            formatCsv(objectField),
            formatCsv(oldAccess),
            formatCsv(newAccess),
            formatCsv(changeType)
        }, ',');
    }

    // === Entity ID Lookup Logic ===
    private String getEntityId(String category, String name) {
        if (String.isBlank(name)){
            return '';
        }
        try {
            if (category == 'Profile') {
                if (!profileIdMap.containsKey(name)) {
                    List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :name LIMIT 1];
                    if (!profiles.isEmpty()) {
                        profileIdMap.put(name, profiles[0].Id);
                    } else {
                        System.debug(LoggingLevel.WARN, 'Profile not found: ' + name);
                        return '';
                    }
                }
                return String.valueOf(profileIdMap.get(name));
            }
            if (category == 'Permission Set') {
                if (!permSetIdMap.containsKey(name)) {
                    List<PermissionSet> permSets = [SELECT Id FROM PermissionSet WHERE Label = :name LIMIT 1];
                    if (!permSets.isEmpty()) {
                        permSetIdMap.put(name, permSets[0].Id);
                    } else {
                        System.debug(LoggingLevel.WARN, 'Permission Set not found: ' + name);
                        return '';
                    }
                }
                return String.valueOf(permSetIdMap.get(name));
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching entity ID for ' + category + ' ' + name + ': ' + e.getMessage());
        }
        return '';
    }

    private static String extractPermSetName(String text) {
        Matcher m = PERMSET_NAME_PATTERN.matcher(text);
        return m.find() ? m.group(1).trim() : '';
    }

    private static String getObjectApiName(String label) {
        if (label == 'Approval'){
            return 'Approval__c';
        }
        if (label == 'Application'){
            return 'Application__c';
        }
        return label.replaceAll('[^A-Za-z0-9_]', '') + '__c';
    }

    private static String getQualifiedFieldName(String objectLabel, String fieldLabel) {
        return getObjectApiName(objectLabel) + '.' + fieldLabel.replaceAll('[^A-Za-z0-9_]', '') + '__c';
    }

    private static String formatCsv(String input) {
        if (String.isBlank(input)){
            return '';
        }
        // RFC 4180 compliant: escape double quotes by doubling them
        return '"' + input.replace('"', '""') + '"';
    }

    // === File Generation ===
    public void finish(Database.BatchableContext bc) {
        createFileIfNotEmpty(flsRows, 'SFDC_FLS_Changes');
        createFileIfNotEmpty(objAccessRows, 'SFDC_ObjectAccess_Changes');
        
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
            String header = 'CreatedDate,CreatedBy,Type,Name,EntityId,Object/Field,OldAccess,NewAccess,ChangeType\n';
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