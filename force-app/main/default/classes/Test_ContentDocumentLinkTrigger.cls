@isTest
public class Test_ContentDocumentLinkTrigger {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	static void testTrigger() {

        Case_RecordTypes__c setting = new Case_RecordTypes__c();
        setting.Name = 'Support - T3 - ALE';
        setting.Case_Record_Type_Name__c = CaseHelper.RT_NAME_SUPPORT_T3;
        setting.RecordType_APIName__c = 'Support_T3';
        setting.Brand__c = OpportunityHelper.BRAND_RAINBOW;
        insert setting;

        Rise_Partner_Case_Comments_Configuration__c riseSetting = new Rise_Partner_Case_Comments_Configuration__c();
        riseSetting.Name = '2000.Optus';
        riseSetting.File_Attachment__c = true;
        riseSetting.Escalation_Record_Types__c = 'Support_T2,Support_T3,Support_QoS,System_Operations,Support_T1_Shipping,Support_Fraud_Investigation,NTD_Escalations';
        insert riseSetting;
        
        Rise_Shipping_Case_Comment_Configuration__c shippingSetting = new Rise_Shipping_Case_Comment_Configuration__c();
        shippingSetting.Name = '2000.Optus';
        shippingSetting.File_Attachment__c = true;
        insert shippingSetting;

        List<Account> acctList = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String> {'Test Acc 1', 'Test Acc 2'})
            })
            .quantity(2)
            .create()
            .getRecords();

		Test.startTest();
            List<Case> caseList = (List<Case>) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.AccountId => ValueProviderBuilder.provideList(new List<Id> {acctList[0].Id, acctList[1].Id, acctList[1].Id, acctList[1].Id}),
                    Case.Subject => ValueProviderBuilder.provideList(new List<String> {'Test Unify Case', 'Test Rise Case', 'Test Escalated Case', 'Test Shipping Case'}),
                    Case.Description => ValueProviderBuilder.provideList(new List<String> {'Test Desc', 'Test Desc', 'Test Desc', 'Test Desc'}),
                    Case.Brand_Identifier__c => ValueProviderBuilder.provideList(new List<String> {OpportunityHelper.BRAND_RAINBOW, OpportunityHelper.BRAND_RISE_AMERICA, OpportunityHelper.BRAND_RISE_AMERICA, OpportunityHelper.BRAND_RISE_AMERICA}),
                    Case.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {CaseHelper.RT_ID_SUPPORT_T3, CaseHelper.RT_ID_RISE_PARTNER_SUPPORT, CaseHelper.RT_ID_RISE_PARTNER_SUPPORT, CaseHelper.RT_ID_SUPPORT_T1_SHIPPING})
                })
                .quantity(4)
                .create()
                .getRecords();
    
            caseList[2].Support_Escalate_To__c = 'Tier 2';
            update caseList[2];
        Test.stopTest();

        ContentVersion cv = (Contentversion) new SObjectBuilder(Contentversion.sObjectType)
            .setFields(new Map<sObjectField, Object> {
        		Contentversion.VersionData => Blob.valueof('JUNK'),
                Contentversion.Title => 'Test.jpg',
                Contentversion.PathOnClient => 'testpath'
            })
            .create()
            .getRecord();

        cv = [SELECT id, ContentDocumentId FROM Contentversion WHERE id = :cv.id];

        List<ContentDocumentLink> docLinks = (List<ContentDocumentLink>) new SObjectBuilder(ContentDocumentLink.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ContentDocumentLink.LinkedEntityId => ValueProviderBuilder.provideList(new List<Id> {caseList[0].Id, caseList[1].Id, caseList[2].Id, caseList[3].Id}),
                ContentDocumentLink.ContentDocumentId => ValueProviderBuilder.provideList(new List<Id> {cv.ContentDocumentId, cv.ContentDocumentId, cv.ContentDocumentId, cv.ContentDocumentId})
             })
        	.quantity(4)
            .create()
            .getRecords();

        Set<Id> caseIds = new Set<Id>{caseList[0].Id, caseList[1].Id, caseList[2].Id, caseList[3].Id};
        List<CaseComment> totalCommentsCreated = [SELECT Id from CaseComment WHERE ParentId IN :caseIds];

		Assert.areEqual(4, totalCommentsCreated.size(), 'Case Comments havent got created for all cases..!');
    }
    
    @IsTest
    static void testSupportEBondingCases() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Acc 1'
            })
            .create()
            .getRecord();

        Test.startTest();
            Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.AccountId => testAcc.Id,
                    Case.Subject => 'Test AllState Case',
                    Case.Description => 'Test Description',
                    Case.Brand_Identifier__c => 'RingCentral',
                    Case.RecordTypeId => [SELECT Id FROM RecordType WHERE Name = 'Support - Customer ebonding'].Id
                })
                .create()
                .getRecord();
        Test.stopTest();

        ContentVersion cv = (Contentversion) new SObjectBuilder(Contentversion.sObjectType)
            .setFields(new Map<sObjectField, Object> {
        		Contentversion.VersionData => Blob.valueof('JUNK'),
                Contentversion.Title => 'Test.jpg',
                Contentversion.PathOnClient => 'testpath'
            })
            .create()
            .getRecord();

        cv = [SELECT id, ContentDocumentId FROM Contentversion WHERE id = :cv.id];

        ContentDocumentLink doclink = (ContentDocumentLink) new SObjectBuilder(ContentDocumentLink.sObjectType)
            .setFields(new Map<sObjectField, Object> {
        		ContentDocumentLink.LinkedEntityId => testCase.Id,
                ContentDocumentLink.ContentDocumentId => cv.ContentDocumentId
            })
            .create()
            .getRecord();

        List<CaseComment> totalCommentsCreated = [SELECT Id from CaseComment WHERE ParentId =: testCase.Id];

		Assert.areEqual(1, totalCommentsCreated.size(), 'Case Comments havent got created for Direct Customer case..!');
    }
        
}