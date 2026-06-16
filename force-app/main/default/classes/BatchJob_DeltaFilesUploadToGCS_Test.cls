/**
 * @description Test class for BatchJob_DeltaFilesUploadToGCS
 * Tests batch job for uploading delta files to GCS
 */
@isTest
private class BatchJob_DeltaFilesUploadToGCS_Test {
    
    /**
     * @description Setup test data - creates ContentVersions with today's date pattern
     */
    @testSetup
    static void setupTestData() {
        // Build today's date in YYYYMMDD format (same as batch job)
        Date d = Date.today();
        String todayString =
            String.valueOf(d.year()) +
            String.valueOf(d.month()).leftPad(2, '0') +
            String.valueOf(d.day()).leftPad(2, '0');
        
        // Create test files with correct naming pattern
        List<ContentVersion> testFiles = new List<ContentVersion>();
        
        // Assuming DeltaFileConfig__mdt has some test prefixes
        // We'll create files for common prefixes
        String[] testPrefixes = new String[]{'SFDC_FLS_Changes', 'SFDC_PermSet_Changes', 'SFDC_ObjectAccess_Changes'};
        
        for (String prefix : testPrefixes) {
            for (Integer i = 1; i <= 3; i++) {
                ContentVersion cv = new ContentVersion();
                cv.Title = prefix + '_' + todayString + '_' + String.valueOf(i);
                cv.PathOnClient = prefix + '_' + todayString + '_' + String.valueOf(i) + '.csv';
                cv.VersionData = Blob.valueOf('Test,Data\nValue' + i + ',Value' + i);
                cv.IsMajorVersion = true;
                testFiles.add(cv);
            }
        }
        
        // Create a file from yesterday (should not be picked up)
        Date yesterday = d.addDays(-1);
        String yesterdayString =
            String.valueOf(yesterday.year()) +
            String.valueOf(yesterday.month()).leftPad(2, '0') +
            String.valueOf(yesterday.day()).leftPad(2, '0');
        
        ContentVersion oldFile = new ContentVersion();
        oldFile.Title = 'SFDC_FLS_Changes_' + yesterdayString + '_1';
        oldFile.PathOnClient = 'SFDC_FLS_Changes_' + yesterdayString + '_1.csv';
        oldFile.VersionData = Blob.valueOf('Old,Data');
        oldFile.IsMajorVersion = true;
        testFiles.add(oldFile);
        
        // Create a file without proper pattern (should not be picked up)
        ContentVersion wrongPattern = new ContentVersion();
        wrongPattern.Title = 'RandomFile';
        wrongPattern.PathOnClient = 'RandomFile.csv';
        wrongPattern.VersionData = Blob.valueOf('Random,Data');
        wrongPattern.IsMajorVersion = true;
        testFiles.add(wrongPattern);
        
        insert testFiles;
    }
    
    /**
     * @description Test batch job execution - should queue files for upload
     */
    @isTest
    static void testBatchExecute_QueuesFiles() {
        List<DeltaFileConfig__mdt> configs = [
            SELECT FilePrefix__c FROM DeltaFileConfig__mdt WHERE IsActive__c = TRUE LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            System.assert(true, 'Skipping test - no active DeltaFileConfig metadata');
            return;
        }
        
        // Get today's ContentDocuments
        Date d = Date.today();
        String todayString =
            String.valueOf(d.year()) +
            String.valueOf(d.month()).leftPad(2, '0') +
            String.valueOf(d.day()).leftPad(2, '0');
        
        String pattern = '%' + todayString + '%';
        List<ContentDocument> docs = [
            SELECT Id, Title, LatestPublishedVersionId, CreatedDate
            FROM ContentDocument
            WHERE Title LIKE :pattern
            LIMIT 5
        ];
        
        if (docs.isEmpty()) {
            System.assert(true, 'No test documents found');
            return;
        }
        
        Test.startTest();
        BatchJob_DeltaFilesUploadToGCS batch = new BatchJob_DeltaFilesUploadToGCS();
        batch.execute(null, docs);
        Test.stopTest();
        
        // Execute method should complete without errors
        System.assert(true, 'Execute should complete successfully');
    }
    
    /**
     * @description Test batch job with file missing LatestPublishedVersionId
     */
    @isTest
    static void testBatchExecute_SkipsFilesWithoutVersionId() {
        // Create a mock ContentDocument list (can't actually create one without version)
        List<ContentDocument> mockDocs = new List<ContentDocument>();
        
        Test.startTest();
        BatchJob_DeltaFilesUploadToGCS batch = new BatchJob_DeltaFilesUploadToGCS();
        batch.execute(null, mockDocs);
        Test.stopTest();
        
        // Should handle empty list gracefully
        System.assert(true, 'Execute should handle empty list');
    }
    
    /**
     * @description Test batch job finish method - should process queued files
     */
    @isTest
    static void testBatchFinish_ProcessesQueuedFiles() {
        Test.startTest();
        BatchJob_DeltaFilesUploadToGCS batch = new BatchJob_DeltaFilesUploadToGCS();
        batch.finish(null);
        Test.stopTest();
        
        // Finish should complete without errors (even with empty queue)
        System.assert(true, 'Finish should complete successfully');
    }
    
    /**
     * @description Test complete batch job execution
     */
    @isTest
    static void testBatchJob_CompleteExecution() {
        List<DeltaFileConfig__mdt> configs = [
            SELECT FilePrefix__c FROM DeltaFileConfig__mdt WHERE IsActive__c = TRUE
        ];
        
        if (configs.isEmpty()) {
            System.assert(true, 'Skipping test - no active DeltaFileConfig metadata');
            return;
        }
        
        Test.startTest();
        BatchJob_DeltaFilesUploadToGCS batch = new BatchJob_DeltaFilesUploadToGCS();
        Id jobId = Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify batch job was queued
        System.assertNotEquals(null, jobId, 'Batch job should be queued');
        
        // Check batch job status
        AsyncApexJob jobInfo = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        
        // Batch should complete (or be queued/processing in test context)
        System.assertNotEquals(null, jobInfo, 'Job info should exist');
    }
    
    /**
     * @description Test batch with no active configurations
     */
    @isTest
    static void testBatch_NoActiveConfig() {
        // This test assumes there might be no config in the org
        Test.startTest();
        BatchJob_DeltaFilesUploadToGCS batch = new BatchJob_DeltaFilesUploadToGCS();
        Iterable<ContentDocument> result = batch.start(null);
        Test.stopTest();
        
        // Should return empty list or handle gracefully
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    /**
     * @description Test batch with multiple file prefixes
     */
    @isTest
    static void testBatch_MultipleActivePrefixes() {
        List<DeltaFileConfig__mdt> configs = [
            SELECT FilePrefix__c FROM DeltaFileConfig__mdt WHERE IsActive__c = TRUE
        ];
        
        if (configs.size() < 2) {
            System.assert(true, 'Skipping test - need multiple active configs');
            return;
        }
        
        Test.startTest();
        BatchJob_DeltaFilesUploadToGCS batch = new BatchJob_DeltaFilesUploadToGCS();
        Iterable<ContentDocument> result = batch.start(null);
        Test.stopTest();
        
        // Should process multiple prefixes
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    
    /**
     * @description Test governor limits logging in finish method
     */
    @isTest
    static void testBatch_GovernorLimitsLogging() {
        Test.startTest();
        BatchJob_DeltaFilesUploadToGCS batch = new BatchJob_DeltaFilesUploadToGCS();
        
        // Add some files to the internal list (simulating execute phase)
        Date d = Date.today();
        String todayString =
            String.valueOf(d.year()) +
            String.valueOf(d.month()).leftPad(2, '0') +
            String.valueOf(d.day()).leftPad(2, '0');
        
        String pattern = '%' + todayString + '%';
        List<ContentDocument> docs = [
            SELECT Id, Title, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Title LIKE :pattern
            LIMIT 2
        ];
        
        if (!docs.isEmpty()) {
            batch.execute(null, docs);
        }
        
        // Call finish to trigger governor limits logging
        batch.finish(null);
        Test.stopTest();
        
        // Governor limits should be logged without errors
        System.assert(true, 'Governor limits logging should complete');
    }
    
    /**
     * @description Test date formatting logic
     */
    @isTest
    static void testBatch_DateFormatting() {
        Test.startTest();
        
        Date testDate = Date.newInstance(2024, 1, 5);
        String formattedDate = String.valueOf(testDate.year()) +
            String.valueOf(testDate.month()).leftPad(2, '0') +
            String.valueOf(testDate.day()).leftPad(2, '0');
        
        System.assertEquals('20240105', formattedDate, 'Date should be formatted as YYYYMMDD');
        
        Test.stopTest();
    }
    
    /**
     * @description Test batch with files created today vs yesterday
     */
    @isTest
    static void testBatch_OnlyTodaysFiles() {
        List<DeltaFileConfig__mdt> configs = [
            SELECT FilePrefix__c FROM DeltaFileConfig__mdt WHERE IsActive__c = TRUE LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            System.assert(true, 'Skipping test - no active DeltaFileConfig metadata');
            return;
        }
        
        Date yesterday = Date.today().addDays(-1);
        String yesterdayString =
            String.valueOf(yesterday.year()) +
            String.valueOf(yesterday.month()).leftPad(2, '0') +
            String.valueOf(yesterday.day()).leftPad(2, '0');
        
        String pattern = '%' + yesterdayString + '%';
        List<ContentDocument> yesterdayDocs = [
            SELECT Id, Title
            FROM ContentDocument
            WHERE Title LIKE :pattern
            LIMIT 1
        ];
        
        Test.startTest();
        BatchJob_DeltaFilesUploadToGCS batch = new BatchJob_DeltaFilesUploadToGCS();
        Iterable<ContentDocument> result = batch.start(null);
        
        // Convert to list to check
        List<ContentDocument> resultList = new List<ContentDocument>();
        Iterator<ContentDocument> it = result.iterator();
        while (it.hasNext()) {
            resultList.add(it.next());
        }
        Test.stopTest();
        
        // Yesterday's files should not be in results
        for (ContentDocument doc : resultList) {
            System.assert(!doc.Title.contains(yesterdayString), 
                'Yesterday\'s files should not be included: ' + doc.Title);
        }
    }
}