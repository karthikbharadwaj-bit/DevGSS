public with sharing class BatchJob_DeltaFilesUploadToGCS implements Database.Batchable<ContentDocument>, Database.Stateful, Database.AllowsCallouts {

    // Store files to upload
    private class FileToUpload {
        public Id contentVersionId;
        public String title;
        public FileToUpload(Id vId, String t) {
            this.contentVersionId = vId;
            this.title = t;
        }
    }

    private List<FileToUpload> filesToUpload = new List<FileToUpload>();
    private List<String> uploadFailures = new List<String>();

    // ---------------------------
    // start(): build the list of ALL matching docs for today
    // ---------------------------
    public Iterable<ContentDocument> start(Database.BatchableContext bc) {

        List<ContentDocument> docsToProcess = new List<ContentDocument>();

        // Get active prefixes
        List<DeltaFileConfig__mdt> configs = [
            SELECT FilePrefix__c
            FROM DeltaFileConfig__mdt
            WHERE IsActive__c = TRUE
        ];

        if (configs.isEmpty()) {
            System.debug('No active prefixes configured.');
            return docsToProcess;
        }

        // Build today's date in YYYYMMDD
        Date d = Date.today();
        String todayString =
            String.valueOf(d.year()) +
            String.valueOf(d.month()).leftPad(2, '0') +
            String.valueOf(d.day()).leftPad(2, '0');

        // For every prefix → get ALL file names matching PREFIX_YYYYMMDD_%
        for (DeltaFileConfig__mdt cfg : configs) {
            String prefix = cfg.FilePrefix__c;
            if (String.isBlank(prefix)){
                continue;
            }
            String pattern = prefix + '_' + todayString + '_%';

            System.debug('Searching for pattern: ' + pattern);

            try {
                // Using bind variable instead of dynamic SOQL for better security
                List<ContentDocument> docs = [
                    SELECT Id, Title, LatestPublishedVersionId, CreatedDate 
                    FROM ContentDocument 
                    WHERE Title LIKE :pattern
                    ORDER BY CreatedDate ASC
                ];
                
                if (!docs.isEmpty()) {
                    docsToProcess.addAll(docs);
                    System.debug('Found ' + docs.size() + ' docs for prefix: ' + prefix);
                } else {
                    System.debug('No docs found for prefix: ' + prefix);
                }
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Query failed for prefix ' + prefix + ' → ' + ex.getMessage());
            }
        }

        return docsToProcess;
    }

    // ---------------------------
    // execute(): collect all version IDs, no callouts here
    // ---------------------------
    public void execute(Database.BatchableContext bc, List<ContentDocument> scope) {
        for (ContentDocument cd : scope) {
            if (cd.LatestPublishedVersionId == null) {
                System.debug('Skipping file with no LatestPublishedVersionId → ' + cd.Title);
                continue;
            }
            filesToUpload.add(new FileToUpload(cd.LatestPublishedVersionId, cd.Title));
        }
        System.debug('Queued ' + scope.size() + ' files in this chunk.');
    }

    // ---------------------------
    // finish(): upload ALL files (callouts allowed)
    // ---------------------------
    public void finish(Database.BatchableContext bc) {

        System.debug('Uploading total files: ' + filesToUpload.size());

        for (FileToUpload f : filesToUpload) {
            try {
                GCSUploader.uploadFile(f.contentVersionId, f.title);
                System.debug('SUCCESS: Uploaded: ' + f.title);
            } catch (Exception ex) {
                String err = 'FAILED: Upload failed for ' + f.title + ' - ' + ex.getMessage();
                uploadFailures.add(err);
                System.debug(LoggingLevel.ERROR, err);
            }
        }

        // Log results summary
        if (!uploadFailures.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'Upload Failures (' + uploadFailures.size() + '):');
            for (String err : uploadFailures) {
                System.debug(LoggingLevel.ERROR, err);
            }
        } else {
            System.debug('SUCCESS: All files uploaded successfully!');
        }
        
        // Log governor limits
        System.debug('Governor Limits - Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
        System.debug('Governor Limits - DML Statements: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements());
        System.debug('Governor Limits - Callouts: ' + Limits.getCallouts() + '/' + Limits.getLimitCallouts());
        System.debug('Governor Limits - Heap Size: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize() + ' bytes');
    }
}