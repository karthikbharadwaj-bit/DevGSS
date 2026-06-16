@isTest
private class Test_AttachmentSelector {
    //Case fields defined 
    private static final String CASE_BRAND = 'Test Brand';

    //Attachment fields defined
    private static final String ATTACHMENT_NAME = 'Master Service Agreement';
    private static final String ATTACHMENT_DESCRIPTION = 'Test Discription';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Attchments should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong attachment selected';


    @testSetup
    private static void testData(){
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_PORTING_OUT,
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Account_Brand__c => CASE_BRAND
                	}
            )
            .create()
            .getRecord();
        
        Attachment testAtt = (Attachment) new SObjectBuilder(Attachment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Attachment.ParentId => testCase.Id,
                    Attachment.Name => ATTACHMENT_NAME,
                    Attachment.Body => EncodingUtil.base64Decode('Test Body'),
                    Attachment.Description => ATTACHMENT_DESCRIPTION
                	}
            )
            .create()
            .getRecord();
        
    }
    
    @isTest
    private static void testSelectAttachmentsDefault(){
        List<Attachment> attachmentsDefault = (List<Attachment>) new AttachmentSelector(true, true)
            .selectAttachmentsDefault()
			.executeQuery();

        System.assert(attachmentsDefault.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectAttachmentsByParentId(){
        List<Attachment> attachmentsDefault = (List<Attachment>) new AttachmentSelector(true, true)
            .selectAttachmentsDefault()
			.executeQuery();

        List<Attachment> attachmentsByParentId = (List<Attachment>) new AttachmentSelector()
            .selectAttachmentsByParentId(new List<Object>{new Set<Id>{attachmentsDefault[0].ParentId}})
			.executeQuery();

        System.assert(attachmentsByParentId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(attachmentsDefault[0].Id, attachmentsByParentId[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
	@isTest
    private static void testSelectAttachmentsByParentIds(){
        List<Attachment> attachmentsDefault = (List<Attachment>) new AttachmentSelector(true, true)
            .selectAttachmentsDefault()
			.executeQuery();

        List<Attachment> attachmentsByParentIds = (List<Attachment>) new AttachmentSelector()
            .selectAttachmentsByParentIds(new List<Object>{new Set<Id>{attachmentsDefault[0].ParentId}})
			.executeQuery();
        
        System.assert(attachmentsByParentIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(attachmentsDefault[0].Id, attachmentsByParentIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectAttachmentsById(){
        List<Attachment> attachmentsDefault = (List<Attachment>) new AttachmentSelector(true, true)
            .selectAttachmentsDefault()
			.executeQuery();

        List<Attachment> attachmentsById = (List<Attachment>) new AttachmentSelector()
            .selectAttachmentsById(new List<Object>{new Set<Id>{attachmentsDefault[0].Id}})
			.executeQuery();
        
        System.assert(attachmentsById.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(attachmentsDefault[0].Id, attachmentsById[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    
	@isTest
    private static void testSelectAttachmentsForCLM(){
        List<Attachment> attachmentsDefault = (List<Attachment>) new AttachmentSelector(true, true)
            .selectAttachmentsDefault()
			.executeQuery();

        List<Attachment> attachmentsForCLM = (List<Attachment>) new AttachmentSelector()
            .selectAttachmentsForCLM(new Set<Id>{attachmentsDefault[0].Id})
			.executeQuery();
        
        System.assert(attachmentsForCLM.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(attachmentsDefault[0].Id, attachmentsForCLM[0].Id, ASSERT_EQUALS_MESSAGE);
    }    
    
    @isTest
    private static void testSelectAttachmentsByListOfParentIds(){
        List<Attachment> attachmentsDefault = (List<Attachment>) new AttachmentSelector(true, true)
            .selectAttachmentsDefault()
			.executeQuery();

        List<Attachment> attachmentsByListOfParentIds = (List<Attachment>) new AttachmentSelector()
            .selectAttachmentsByListOfParentIds(new List<Object>{new Set<Id>{attachmentsDefault[0].ParentId}})
			.executeQuery();
        
        System.assert(attachmentsByListOfParentIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(attachmentsDefault[0].Id, attachmentsByListOfParentIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }    
    
    @isTest
    private static void testSelectMsaByParentId(){
        List<Attachment> attachmentsDefault = (List<Attachment>) new AttachmentSelector(true, true)
            .selectAttachmentsDefault()
			.executeQuery();

        List<Attachment> msaByParentId = (List<Attachment>) new AttachmentSelector()
            .selectMsaByParentId(new Set<Id>{attachmentsDefault[0].ParentId})
			.executeQuery();

        System.assert(msaByParentId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(attachmentsDefault[0].Id, msaByParentId[0].Id, ASSERT_EQUALS_MESSAGE);
    }    
}