@isTest
private class Test_SCCaseAttachmentsController {

    private static final String CASE_INFO_SUBJECT = 'test Subject';

    private static final String ATTACHMENT_NAME = 'Attachmento testomento';
    private static final String ATTACHMENT_BODY = 'This is a 30 characters string';
    private static final Integer ATTACHMENT_LENGTH = 30;
    private static final Integer ATTACHMENT_LENGTH_TOO_LARGE = 30000000;

    private static Case createCase() {

        return (Case) new SObjectBuilder(Case.SObjectType)
            .setField(Case.RecordTypeId, CaseHelper.RT_ID_SUPPORT_T1)
            .setField(Case.Subject, ValueProviderBuilder.provideUniqueString(CASE_INFO_SUBJECT))
            .create()
            .getRecord();
    }

    @isTest
    static void testAttachFile() {

        Case caseObj = createCase();

        PageReference pageRef = Page.scCaseDetailAttachments;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',caseObj.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(caseObj);
        SCCaseAttachmentsController ctrl = new SCCaseAttachmentsController(sc);
        ctrl.attachmentName = ATTACHMENT_NAME;
        ctrl.attachmentBody = Blob.valueOf(ATTACHMENT_BODY);
        ctrl.attachmentSize = ATTACHMENT_LENGTH;
        Test.startTest();
        ctrl.attachFile();
        Test.stopTest();

        List<Attachment> realAttachments = new AttachmentSelector()
            .selectAttachmentsByParentId(new List<Id>{caseObj.Id})
            .selectFields(new List<Schema.SObjectField>{Attachment.Body})
            .executeQuery();
        
        System.assertEquals('success', ctrl.uploadStatus, 'Incorrect number of attachments on case');
        System.assertEquals(1, realAttachments.size(), 'Incorrect number of attachments on case');
        System.assertEquals(ATTACHMENT_NAME, realAttachments[0].Name, 'Incorrect attachment name');
        System.assertEquals(ATTACHMENT_BODY, realAttachments[0].Body.toString(), 'Incorrect attachment body');
    }

    @isTest
    static void testAttachFile_tooLarge_shouldFail() {

        Case caseObj = createCase();

        PageReference pageRef = Page.scCaseDetailAttachments;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',caseObj.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(caseObj);
        SCCaseAttachmentsController ctrl = new SCCaseAttachmentsController(sc);
        ctrl.attachmentName = ATTACHMENT_NAME;
        ctrl.attachmentBody = Blob.valueOf(ATTACHMENT_BODY);
        ctrl.attachmentSize = ATTACHMENT_LENGTH_TOO_LARGE;
        Test.startTest();
        ctrl.attachFile();
        Test.stopTest();

        List<Attachment> realAttachments = new AttachmentSelector()
            .selectAttachmentsByParentId(new List<Id>{caseObj.Id})
            .selectFields(new List<Schema.SObjectField>{Attachment.Body})
            .executeQuery();
        
        System.assertEquals('limitExceeded', ctrl.uploadStatus, 'Uploaded file that is too large');
        System.assertEquals(0, realAttachments.size(), 'Attachment that is too large was uploaded');
    }
}