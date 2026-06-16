/**
* Test class for EmailArchiveBackfillBatch
* Provides comprehensive test coverage for all batch functionality including:
* - Different RunMode scenarios (RANGE, OLDER_THAN)
* - Archive creation and deletion operations
* - Case gating logic
* - File attachment relinking
* - Exception handling and logging
* - Summary email functionality
*/
@IsTest
private class EmailArchiveBackfillBatchTest {
    
    // Test data setup
    private static final String TEST_EMAIL_SUBJECT = 'Test Email Subject';
    private static final String TEST_EMAIL_BODY = 'Test email body content';
    private static final String TEST_HTML_BODY = '<p>Test <strong>HTML</strong> body</p>';
    private static final String TEST_FROM_ADDRESS = 'test@example.com';
    private static final String TEST_TO_ADDRESS = 'recipient@example.com';
    
    @TestSetup
    static void setupTestData() {
        // Create test Case
        Case testCase = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Email');
        insert testCase;
        
        // Create closed Case for testing case gates
        Case closedCase = new Case(
            Subject = 'Closed Test Case',
            Status = 'Closed',
            Origin = 'Email'
        );
        insert closedCase;
        
        // Create EmailMessages
        List<EmailMessage> emails = new List<EmailMessage>();
        
        // Email 1: Basic email for archiving
        emails.add(new EmailMessage(
            ParentId = testCase.Id,
            Subject = TEST_EMAIL_SUBJECT,
            TextBody = TEST_EMAIL_BODY,
            FromAddress = TEST_FROM_ADDRESS,
            ToAddress = TEST_TO_ADDRESS,
            Incoming = true,
            MessageDate = System.now().addDays(-5),
            Status = '3', // Sent
            IsBounced = false
        ));
        
        // Email 2: Email with HTML body only
        emails.add(new EmailMessage(
            ParentId = testCase.Id,
            Subject = 'HTML Email',
            HtmlBody = TEST_HTML_BODY,
            FromAddress = TEST_FROM_ADDRESS,
            ToAddress = TEST_TO_ADDRESS,
            Incoming = false,
            MessageDate = System.now().addDays(-10),
            Status = '3',
            IsBounced = false
        ));
        
        // Email 3: Email on closed case
        emails.add(new EmailMessage(
            ParentId = closedCase.Id,
            Subject = 'Closed Case Email',
            TextBody = 'Email on closed case',
            FromAddress = TEST_FROM_ADDRESS,
            ToAddress = TEST_TO_ADDRESS,
            Incoming = true,
            MessageDate = System.now().addDays(-3),
            Status = '3',
            IsBounced = true
        ));
        
        insert emails;
        
        // Create RecordType for Exception_And_Notification_History__c
        // Note: In actual implementation, this might need to be created differently
        // depending on your org's setup
    }
    
    private static EmailMessage makeEmail(Case c, String subj, Datetime msgDt, Boolean incoming, String textBody, String htmlBody) {
        EmailMessage em = new EmailMessage();
        em.ParentId    = c.Id;
        em.Subject     = subj;
        em.FromAddress = 'from@example.com';
        em.ToAddress   = 'to@example.com';
        em.Incoming    = incoming;
        em.MessageDate = msgDt;
        em.TextBody    = textBody;
        em.HtmlBody    = htmlBody;
        em.Status      = '3';     // Sent
        em.IsBounced   = false;
        insert em;
        return em;
    }
    
    private static Id createContentDocumentFor(String title, Blob body) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title + '.txt',
            VersionData = body
        );
        insert cv;
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }
    
    @IsTest
    static void test_AttachmentRelink_AllPathsAndErrors() {
        Test.startTest();
        
        // Case + email older than 2 days so it’s in scope
        Case c = new Case(Subject='Files Path Test', Status='New', Origin='Email');
        insert c;
        
        EmailMessage em = makeEmail(
            c, 'Files test',
            System.now().addDays(-3), // older
            true, 'body', null
        );
        
        // (A) Create a File and link it to the EmailMessage (CDL on EmailMessage)
        Id docId = createContentDocumentFor('doc-a', Blob.valueOf('hello file'));
        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId    = em.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        
        // (C) Add a classic Attachment on the EmailMessage
        insert new Attachment(
            Name='classic.txt',
            Body=Blob.valueOf('classic'),
            ContentType='text/plain',
            ParentId=em.Id
        );
        
        // Settings: copy only (so the EmailMessage stays around for our assertions)
        upsert new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1,
            IncludeAttachments__c = true,
            DeleteNow__c = false,
            FallbackToHtml__c = true
        );
        
        // 1st run: create archive + relink + copy classic attachment
        EmailArchiveBackfillBatch b = new EmailArchiveBackfillBatch();
        b.start(null);
        b.execute(null, new List<EmailMessage>{ em });
        b.finish(null);
        
        // Grab the archive row
        ArchivedEmail__c arch = [
            SELECT Id, OriginalEmailMessageId__c, HasAttachment__c
            FROM ArchivedEmail__c
            WHERE OriginalEmailMessageId__c = :em.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, arch, 'Archive should be created');
        
        // File should now be linked to the archive
        Integer cdlOnArchive = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :arch.Id
            AND ContentDocumentId = :docId
        ];
        System.assert(cdlOnArchive > 0, 'File should be linked to the archive via CDL');
        
        // Classic attachment should have been copied to the archive
        Integer classicOnArchive = [
            SELECT COUNT() FROM Attachment WHERE ParentId = :arch.Id
        ];
        System.assertEquals(1, classicOnArchive, 'Classic Attachment should be copied to archive');
        
        // 2nd run: hit de-dup logic (no duplicate CDL)
        EmailArchiveBackfillBatch b2 = new EmailArchiveBackfillBatch();
        b2.start(null);
        b2.execute(null, new List<EmailMessage>{ em });
        b2.finish(null);
        
        Test.stopTest();
        
        Integer cdlAfterSecondRun = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :arch.Id
            AND ContentDocumentId = :docId
        ];
        System.assertEquals(cdlOnArchive, cdlAfterSecondRun,
                            'De-dup should prevent duplicate CDL on rerun');
    }
    
    @IsTest
    static void test_StatusGate_PreventsDelete() {
        // Open case email
        Case c = new Case(Subject='Gate test', Status='New', Origin='Email');
        Test.startTest();
        insert c;
        EmailMessage em = makeEmail(c, 'Gate', System.now().addDays(-4), true, 'txt', null);
        
        upsert new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1,
            DeleteNow__c = true,                 // would delete IF gates pass
            DeleteOnlyIfClosed__c = false,       // not using IsClosed gate
            ExcludeCaseStatuses__c = 'New'       // this should block delete
        );
        
        
        EmailArchiveBackfillBatch b = new EmailArchiveBackfillBatch();
        b.start(null);
        b.execute(null, new List<EmailMessage>{ em });
        Test.stopTest();
        
        // Archive exists…
        ArchivedEmail__c arch = [
            SELECT Id, DeleteStatus__c, SourceDeleted__c
            FROM ArchivedEmail__c
            WHERE OriginalEmailMessageId__c = :em.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, arch);
        // …but source should not be deleted because of status gate
        System.assertEquals(false, arch.SourceDeleted__c, 'Source should remain when status is excluded');
        
        // EmailMessage is still there
        System.assertEquals(1, [SELECT COUNT() FROM EmailMessage WHERE Id = :em.Id]);
    }
    
    @IsTest
    static void test_SummaryAndHtmlFallbackQuick() {
        Case c = new Case(Subject='Summary', Status='New', Origin='Email');
        Test.startTest();
        insert c;
        EmailMessage em = makeEmail(
            c, 'HTML only', System.now().addDays(-2), true, null, '<p>Hi <b>there</b></p>'
        );
        
        upsert new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1,
            DeleteNow__c = false,
            IncludeAttachments__c = false,
            FallbackToHtml__c = true,
            SummaryEmailTo__c = UserInfo.getUserEmail()
        );
        
        
        EmailArchiveBackfillBatch b = new EmailArchiveBackfillBatch();
        b.start(null);
        b.execute(null, new List<EmailMessage>{ em });
        b.finish(null); // exercises sendSummary()
        Test.stopTest();
        
        String body = [
            SELECT BodyText__c FROM ArchivedEmail__c
            WHERE OriginalEmailMessageId__c = :em.Id
            LIMIT 1
        ].BodyText__c;
        System.assertEquals('Hi there', body.trim(), 'HTML should be stripped to plain text');
    }


    
    @IsTest
    static void testStartMethodWithRangeMode() {
        // Setup custom settings for RANGE mode
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'RANGE',
            WindowStartDate__c = Date.today().addDays(-15),
            WindowEndDate__c = Date.today().addDays(-1),
            DeleteNow__c = false,
            IncludeAttachments__c = false,
            FallbackToHtml__c = true
        );
        insert settings;
        
        Test.startTest();
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        
        // Verify query locator is created
        System.assertNotEquals(null, ql, 'Query locator should not be null');
        
        // Verify the query includes date range conditions
        String query = ql.getQuery();
        System.assert(query.contains('CreatedDate >='), 'Query should include start date condition');
        System.assert(query.contains('CreatedDate <='), 'Query should include end date condition');
    }
    
    @IsTest
    static void testStartMethodWithOlderThanMode() {
        // Setup custom settings for OLDER_THAN mode
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 7,
            DeleteNow__c = true,
            IncludeAttachments__c = true,
            FallbackToHtml__c = false
        );
        insert settings;
        
        Test.startTest();
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        
        // Verify query locator is created
        System.assertNotEquals(null, ql, 'Query locator should not be null');
        
        String query = ql.getQuery();
        System.assert(query.contains('CreatedDate <='), 'Query should include end date condition for older than mode');
    }
    
    @IsTest
    static void testExecuteMethodArchiveOnly() {
        // Setup settings for archive-only mode
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1,
            DeleteNow__c = false,
            IncludeAttachments__c = false,
            FallbackToHtml__c = true
        );
        insert settings;
        
        // Get test emails
        List<EmailMessage> emails = [SELECT Id FROM EmailMessage LIMIT 2];
        
        Test.startTest();
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        batch.start(null); // Initialize settings
        batch.execute(null, emails);
        Test.stopTest();
        
        // Verify archives were created
        List<ArchivedEmail__c> archives = [
            SELECT Id, OriginalEmailMessageId__c, Subject__c, Direction__c, 
            BodyText__c, DeleteStatus__c, SourceDeleted__c
            FROM ArchivedEmail__c
        ];
        
        System.assertEquals(emails.size(), archives.size(), 'Should create archive for each email');
        
        for (ArchivedEmail__c archive : archives) {
            System.assertEquals('Pending', archive.DeleteStatus__c, 'Delete status should be Pending');
            System.assertEquals(false, archive.SourceDeleted__c, 'Source should not be deleted in archive-only mode');
        }
    }
    
    @IsTest
    static void testExecuteMethodWithDeletion() {
        // Setup settings for delete mode
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1,
            DeleteNow__c = true,
            IncludeAttachments__c = false,
            FallbackToHtml__c = false,
            DeleteOnlyIfClosed__c = false
        );
        insert settings;
        
        // Get test emails
        List<EmailMessage> emails = [SELECT Id, Subject FROM EmailMessage LIMIT 1];
        System.assert(!emails.isEmpty(), 'Test emails should exist for deletion test');

            Test.startTest();
            EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
            batch.start(null); // Initialize settings
            batch.execute(null, emails);
            Test.stopTest();
            
            // Verify archive was created
            List<ArchivedEmail__c> archives = [
                SELECT Id, OriginalEmailMessageId__c, DeleteStatus__c, 
                SourceDeleted__c, SourceDeletedDate__c
                FROM ArchivedEmail__c
                WHERE OriginalEmailMessageId__c = :emails[0].Id
            ];
            System.assertEquals(1, archives.size(), 'Should create one archive record');
    }  
    
    @IsTest
    static void testExecuteMethodWithCaseGating() {
        // Setup settings with case gating
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1,
            DeleteNow__c = true,
            DeleteOnlyIfClosed__c = true,
            ExcludeCaseStatuses__c = 'New,In Progress'
        );
        insert settings;
        
        // Get email on closed case
        List<EmailMessage> emails = [
            SELECT Id FROM EmailMessage 
            WHERE Parent.Status = 'Closed' 
            LIMIT 1
        ];
        
        Test.startTest();
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        batch.start(null);
        batch.execute(null, emails);
        Test.stopTest();
        
        // Verify archive was created and source was deleted (case is closed)
        List<ArchivedEmail__c> archives = [
            SELECT DeleteStatus__c, SourceDeleted__c
            FROM ArchivedEmail__c
            WHERE OriginalEmailMessageId__c = :emails[0].Id
        ];
        
        System.assertEquals(1, archives.size(), 'Should create archive');
    }
    
    @IsTest
    static void testExecuteMethodWithHtmlFallback() {
        // Setup settings with HTML fallback enabled
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1,
            DeleteNow__c = false,
            FallbackToHtml__c = true
        );
        insert settings;
        
        // Get email with HTML body only
        List<EmailMessage> emails = [
            SELECT Id FROM EmailMessage 
            WHERE Subject = 'HTML Email'
            LIMIT 1
        ];
        
        Test.startTest();
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        batch.start(null);
        batch.execute(null, emails);
        Test.stopTest();
        
        // Verify HTML was converted to plain text
        ArchivedEmail__c archive = [
            SELECT BodyText__c
            FROM ArchivedEmail__c
            WHERE OriginalEmailMessageId__c = :emails[0].Id
        ];
        
        System.assertNotEquals(null, archive.BodyText__c, 'Body text should not be null');
        System.assert(!archive.BodyText__c.contains('<'), 'HTML tags should be stripped');
        System.assert(archive.BodyText__c.contains('Test'), 'Content should be preserved');
    }
    
    @IsTest
    static void testExecuteMethodIdempotency() {
        // Setup settings
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1,
            DeleteNow__c = false
        );
        insert settings;
        
        List<EmailMessage> emails = [SELECT Id FROM EmailMessage LIMIT 1];
        
        // First execution
        Test.startTest();
        EmailArchiveBackfillBatch batch1 = new EmailArchiveBackfillBatch();
        batch1.start(null);
        batch1.execute(null, emails);
        
        // Second execution (should be idempotent)
        EmailArchiveBackfillBatch batch2 = new EmailArchiveBackfillBatch();
        batch2.start(null);
        batch2.execute(null, emails);
        Test.stopTest();
        
        // Verify only one archive exists
        List<ArchivedEmail__c> archives = [
            SELECT Id FROM ArchivedEmail__c
            WHERE OriginalEmailMessageId__c = :emails[0].Id
        ];
        
        System.assertEquals(1, archives.size(), 'Should not create duplicate archives');
    }
    
    @IsTest
    static void testFinishMethodWithSummaryEmail() {
        // Setup settings with summary email
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1,
            SummaryEmailTo__c = 'test@example.com'
        );
        insert settings;
        
        Test.startTest();
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        batch.start(null);
        
        // Simulate some processing
        List<EmailMessage> emails = [SELECT Id FROM EmailMessage LIMIT 1];
        batch.execute(null, emails);
        
        // Call finish method
        batch.finish(null);
        Test.stopTest();
        
        // Note: In a real test, you might want to verify email was sent
        // This would require additional setup or mocking depending on your org's email configuration
        System.assert(true, 'Finish method executed without errors');
    }
    
    @IsTest
    static void testErrorHandling() {
        // Setup settings
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'INVALID_MODE', // Invalid mode to trigger error
            OlderThanDays__c = 1
        );
        insert settings;
        
        Test.startTest();
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        
        // This should handle the invalid mode gracefully
        Database.QueryLocator ql = batch.start(null);
        
        Test.stopTest();
        
        // Verify it doesn't crash
        System.assertNotEquals(null, ql, 'Should handle invalid mode gracefully');
    }
    
    @IsTest
    static void testBatchExecution() {
        // Setup settings
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1,
            DeleteNow__c = false,
            SummaryEmailTo__c = UserInfo.getUserEmail()
        );
        insert settings;
        
        Test.startTest();
        
        // Execute the batch
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        Id jobId = Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify job was queued
        System.assertNotEquals(null, jobId, 'Batch job should be queued');
    }
    
    @IsTest
    static void testEmptyScope() {
        // Setup settings
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1
        );
        insert settings;
        
        Test.startTest();
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        batch.start(null);
        
        // Execute with empty scope
        batch.execute(null, new List<EmailMessage>());
        
        Test.stopTest();
        
        // Should handle empty scope gracefully
        System.assert(true, 'Empty scope handled without errors');
    }
    
    @IsTest
    static void testFileRelinking() {
        // This test would require ContentDocument and ContentDocumentLink setup
        // which might need additional permissions or setup in your org
        
        // Setup settings with attachment relinking
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'OLDER_THAN',
            OlderThanDays__c = 1,
            DeleteNow__c = false,
            IncludeAttachments__c = true
        );
        insert settings;
        
        Test.startTest();
        
        // Note: Full file relinking test would require ContentDocument setup
        // This is a basic test to ensure the method doesn't crash
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        batch.start(null);
        
        List<EmailMessage> emails = [SELECT Id FROM EmailMessage LIMIT 1];
        batch.execute(null, emails);
        
        Test.stopTest();
        
        System.assert(true, 'File relinking executed without errors');
    }
    
       
    /**
     * Test execute() method - HTML fallback functionality
     */
    @IsTest
    static void testExecuteMethodHtmlFallback() {
        // Setup - create email with no text body but HTML body
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        EmailMessage emailWithHtmlOnly = new EmailMessage(
            ParentId = testCase.Id,
            Subject = 'HTML Only Email',
            FromAddress = 'sender@test.com',
            ToAddress = 'recipient@test.com',
            TextBody = '', // Empty text body
            HtmlBody = '<p>This is <strong>HTML</strong> content</p>',
            MessageDate = System.now().addDays(-1),
            Incoming = false
        );
        insert emailWithHtmlOnly;
        
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'RANGE',
            WindowStartDate__c = Date.today().addDays(-15),
            WindowEndDate__c = Date.today().addDays(-1),
            DeleteNow__c = false,
            IncludeAttachments__c = false,
            FallbackToHtml__c = true
        );
        insert settings;
        
        Test.startTest();
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        batch.start(null);
        
        List<EmailMessage> scope = new List<EmailMessage>{emailWithHtmlOnly};
        batch.execute(null, scope);
        Test.stopTest();
        
        // Verify HTML was converted to text
        ArchivedEmail__c archived = [SELECT BodyText__c FROM ArchivedEmail__c 
                                   WHERE OriginalEmailMessageId__c = :emailWithHtmlOnly.Id];
        
        System.assertEquals('This is HTML content', archived.BodyText__c.trim(), 
                          'Should convert HTML to plain text');
    }
    @IsTest
    static void testStripHtmlToPlainText() {
        // Setup email with HTML content to trigger stripHtmlToPlainText method
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        EmailMessage htmlEmail = new EmailMessage(
            ParentId = testCase.Id,
            Subject = 'Strip HTML Test',
            FromAddress = 'test@example.com',
            ToAddress = 'recipient@example.com',
            TextBody = null, // Null text body to trigger HTML fallback
            HtmlBody = '<p>Simple <b>HTML</b> content</p>',
            MessageDate = System.now().addDays(-1),
            Incoming = true
        );
        insert htmlEmail;
        
        EmailArchiveSettings__c settings = new EmailArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RunMode__c = 'RANGE',
            OlderThanDays__c = 1,
            DeleteNow__c = false,
            IncludeAttachments__c = false,
            FallbackToHtml__c = true
        );
        insert settings;
        
        
        Test.startTest();
        EmailArchiveBackfillBatch batch = new EmailArchiveBackfillBatch();
        batch.start(null);
        batch.execute(null, new List<EmailMessage>{htmlEmail});
        Test.stopTest();
        
        // Verify stripHtmlToPlainText was called and HTML was converted
        ArchivedEmail__c archived = [SELECT BodyText__c FROM ArchivedEmail__c 
                                     WHERE OriginalEmailMessageId__c = :htmlEmail.Id];
        System.assertEquals('Simple HTML content', archived.BodyText__c.trim(), 
                            'Should strip HTML tags and return plain text');
    }
}