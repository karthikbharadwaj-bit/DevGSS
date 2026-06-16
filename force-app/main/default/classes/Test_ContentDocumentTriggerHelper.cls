@isTest
public class Test_ContentDocumentTriggerHelper {

    @testSetup
    static void setupTestData() {
        // Create a test Case
        
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => 'Test Case',
                Case.Status => 'New'
                    })
            .create()
            .getRecord();

        // Create a ContentVersion (File)
        ContentVersion contentVer = (Contentversion) new SObjectBuilder(Contentversion.sObjectType)
            .setFields(new Map<sObjectField, Object> {
        		Contentversion.VersionData => Blob.valueOf('Test Data'),
                Contentversion.Title => 'Test Document',
                Contentversion.PathOnClient => 'TestDocument.pdf',
                Contentversion.IsMajorVersion => true
            })
            .create()
            .getRecord();
        
        // Fetch the ContentDocumentId
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVer.Id].ContentDocumentId;

        // Create a ContentDocumentLink 
       ContentDocumentLink contentDocLink = (ContentDocumentLink) new SObjectBuilder(ContentDocumentLink.sObjectType)
            .setFields(new Map<sObjectField, Object> {
                ContentDocumentLink.LinkedEntityId => testCase.Id,
                ContentDocumentLink.ContentDocumentId => contentDocId,
                ContentDocumentLink.ShareType => 'I'
             })
            .create()
            .getRecord();
        
    }

    @isTest
    static void testAttachmentCreation() {
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        String contentDocId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId= :testCase.Id].ContentDocumentId;
        
        Test.startTest();
        // Fetch Attachments created by the trigger
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE ParentId = :testCase.Id];
        Test.stopTest();

        // Validate attachment was created
        System.assertEquals(1, attachments.size(), 'One attachment should be created.');
        System.assert(attachments[0].Name.startsWith(contentDocId +' | ' +'Test Document'), 'Attachment name should match the file title.');
    }

    @isTest
    static void testAttachmentDeletion() {
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        String contentDocId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId= :testCase.Id].ContentDocumentId;
        //Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1].ContentDocumentId;
        
        List<Attachment> attachmentsBefore = [SELECT Id,Name FROM Attachment WHERE ParentId = :testCase.Id];

        System.assertEquals(1, attachmentsBefore.size(), 'One attachment should exist before deletion.');

        Test.startTest();
        // Delete ContentDocument (not just ContentDocumentLink)
        delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocId];
        Test.stopTest();

        // Verify Attachment is deleted
        Integer attachmentCount = [SELECT COUNT() FROM Attachment WHERE ParentId = :testCase.Id];
        System.assertEquals(0, attachmentCount, 'Attachment should be deleted.');
    }
    
    @isTest
    static void testAttachmentUpdate() {
        // Fetch test data
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        ContentVersion contentVer = [SELECT Id, Title FROM ContentVersion LIMIT 1];
        
        // Simulate file update
        contentVer.Title = 'Updated Document';
        update contentVer;

        // Fetch updated attachment
        Test.startTest();
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE ParentId = :testCase.Id];
        Test.stopTest();

        // Validate that the attachment name is updated
        System.assertEquals(1, attachments.size(), 'Only one attachment should exist (no duplicates).');
        System.assert(attachments[0].Name.contains('Updated Document'), 'Attachment name should reflect the updated file title.');
    }
}