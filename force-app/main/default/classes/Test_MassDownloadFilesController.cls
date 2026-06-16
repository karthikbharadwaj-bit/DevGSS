@isTest
private class Test_MassDownloadFilesController {
    
    @TestSetup
    static void setupTestData() {
        // Disable Triggers if necessary
        Triggers.switchOff();

        // ✅ Create a test Account
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account 1',
                        Account.RC_User_ID__c => '12345',
                        Account.BillingCountry => 'USA'
                        }
            )
            .create()
            .getRecord();
        
        // ✅ Create a test Contact
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test',
                        Contact.LastName => 'Contact',
                        Contact.Email => 'testcontact@domain.com',
                        Contact.AccountId => testAccount.Id
                        }
            )
            .create()
            .getRecord();

        // ✅ Create a test Case 
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => 'Test Case for File',
                Case.Status => 'New',
                Case.Origin => 'Web',
                Case.RecordTypeId => Schema.SObjectType.Case.getRecordTypeInfosByName().get('System Operations').getRecordTypeId(),
                Case.AccountId => testAccount.Id,
                Case.ContactId => testContact.Id
            })
            .create()
            .getRecord();

        // ✅ Create a ContentVersion
        ContentVersion testDocument = (ContentVersion) new SObjectBuilder(ContentVersion.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ContentVersion.Title => 'Test Document',
                ContentVersion.PathOnClient => 'TestDocument.pdf',
                ContentVersion.VersionData => Blob.valueOf('Test Content Data'),
                ContentVersion.IsMajorVersion => true
            })
            .create()
            .getRecord();

        // ✅ Get ContentDocumentId from ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testDocument.Id].ContentDocumentId;

        // ✅ Create ContentDocumentLink with `Case` as LinkedEntityId
        new SObjectBuilder(ContentDocumentLink.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ContentDocumentLink.LinkedEntityId => testCase.Id,
                ContentDocumentLink.ContentDocumentId => contentDocumentId,
                ContentDocumentLink.ShareType => 'V'
            })
            .create();

        // Enable Triggers
        Triggers.switchOn();
    }

    @isTest
    static void testFetchRelatedFiles_Success() {
        // ✅ Fetch test Case from setup
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case for File' LIMIT 1];

        Test.startTest();

        // ✅ Call the method under test
        List<MassDownloadFilesController.FileWrapper> fileList = MassDownloadFilesController.fetchRelatedFiles(testCase.Id);

        Test.stopTest();

        // ✅ Validate expected results
        System.assertNotEquals(0, fileList.size(), 'At least one file should be returned.');
        System.assertNotEquals(null, fileList[0].Id, 'File ID should not be null.');
        System.assertEquals('Test Document', fileList[0].Title, 'File title should match.');
    }

    @isTest
    static void testFetchRelatedFiles_NoFiles() {
        // ✅ Create a Case with no associated files
        Case emptyCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => 'Empty Case',
                Case.Status => 'New',
                Case.Origin => 'Phone'
            })
            .create()
            .getRecord();

        Test.startTest();

        // ✅ Call the method with a Case that has no files
        List<MassDownloadFilesController.FileWrapper> fileList = MassDownloadFilesController.fetchRelatedFiles(emptyCase.Id);

        Test.stopTest();

        // ✅ Validate expected results
        System.assertEquals(0, fileList.size(), 'No files should be returned for this Case.');
    }

    @isTest
    static void testFetchRelatedFiles_NullRecordId() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            // ✅ Call the method with a null record ID
            MassDownloadFilesController.fetchRelatedFiles(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, true);
    }
    
    @isTest
    static void testFetchRelatedFiles_Success2() {
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case for File' LIMIT 1];

        Test.startTest();

        // Test fetch files method
        List<MassDownloadFilesController.FileWrapper> fileList = MassDownloadFilesController.fetchRelatedFiles(testCase.Id);

        ContentDocumentLinkSelector selector = new ContentDocumentLinkSelector();

        // Test selectLinksByLinkedEntityId
        Set<Id> linkedEntityIds = new Set<Id>{testCase.Id};
        selector.selectLinksByLinkedEntityId(linkedEntityIds);
        
        // Test selectLinksByLinkedEntityAndDocumentId
        List<Object> bindings = new List<Object>{testCase.Id, 'dummyDocumentId'};
        selector.selectLinksByLinkedEntityAndDocumentId(bindings);
        
        // Test selectLinksByDocumentId
        selector.selectLinksByDocumentId(bindings);
        
        // Test selectLinksByLinkedEntityIdForBulkDownloads
        selector.selectLinksByLinkedEntityIdForBulkDownloads(linkedEntityIds);

        Test.stopTest();

        System.assertNotEquals(0, fileList.size(), 'At least one file should be returned.');
    }

}