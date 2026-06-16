@IsTest
public with sharing class Test_DealQualificationApproverSelector {
    @isTest
    static void testSelectDQApprovers() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();
        
        DQ_Approval_Step__c testDqApprovalStepRecord = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step__c.Name => 'Step 3'
            })
            .create()
            .getRecord();
        
        new SObjectBuilder(DQ_Deal_Qualification_Approver__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Approver__c.Deal_Qualification__c => testDqRecord.Id,
                DQ_Deal_Qualification_Approver__c.Approval_Step__c  => testDqApprovalStepRecord.Id
            })
            .create();

        Test.startTest();
            List<DQ_Deal_Qualification_Approver__c> selectedDQApprovers = new DealQualificationApproverSelector()
                .selectDQApprovers(testDqRecord.Id)
                .executeQuery();
        Test.stopTest();

        System.assert(!selectedDQApprovers.isEmpty(), 'Deal Qualification Approver record should be selected');
    }

    @isTest
    static void testSelectDQApproverById() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();
        
        DQ_Approval_Step__c testDqApprovalStepRecord = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step__c.Name => 'Step 3'
            })
            .create()
            .getRecord();
        
        DQ_Deal_Qualification_Approver__c testDqApprover = (DQ_Deal_Qualification_Approver__c) new SObjectBuilder(DQ_Deal_Qualification_Approver__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Approver__c.Deal_Qualification__c => testDqRecord.Id,
                DQ_Deal_Qualification_Approver__c.Approval_Step__c  => testDqApprovalStepRecord.Id
            })
            .create()
            .getRecord();

        Test.startTest();
            List<DQ_Deal_Qualification_Approver__c> selectedDQApprovers = new DealQualificationApproverSelector()
                .selectDQApproverById(testDqApprover.Id)
                .executeQuery();
        Test.stopTest();

        System.assertEquals(testDqApprover.Id, selectedDQApprovers[0].Id, 'Deal Qualification Approver record should be selected');
    }
    
    @isTest
    static void testSelectDQApproversOrder() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();
        
        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();
        
        DQ_Approval_Step__c testDqApprovalStepRecord = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step__c.Name => 'Step 3'
            })
            .create()
            .getRecord();
        
        new SObjectBuilder(DQ_Deal_Qualification_Approver__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Approver__c.Deal_Qualification__c => testDqRecord.Id,
                DQ_Deal_Qualification_Approver__c.Approval_Step__c  => testDqApprovalStepRecord.Id
            })
            .create();
                
        Test.startTest();        
            List<DQ_Deal_Qualification_Approver__c> selectedApproversOrder = new DealQualificationApproverSelector()
                .selectDQApproversOrder(testDqRecord.Id)
                .executeQuery();
        Test.stopTest();
        
        System.assert(!selectedApproversOrder.isEmpty(), 'Deal Qualification Approver record should be selected');
    }

    @isTest
    static void selectDQApproversForDQWidget() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();
        
        DQ_Approval_Step__c testDqApprovalStepRecord = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step__c.Name => 'Step 3'
            })
            .create()
            .getRecord();
        
        DQ_Deal_Qualification_Approver__c testDqApprover = (DQ_Deal_Qualification_Approver__c) new SObjectBuilder(DQ_Deal_Qualification_Approver__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Approver__c.Deal_Qualification__c => testDqRecord.Id,
                DQ_Deal_Qualification_Approver__c.Approval_Step__c  => testDqApprovalStepRecord.Id
            })
            .create()
            .getRecord();

        Test.startTest();
            List<DQ_Deal_Qualification_Approver__c> selectedDQApprovers = new DealQualificationApproverSelector()
                .selectDQApproversForDQWidget(new List<Object> {new List<String> {testDqApprover.Id}})
                .executeQuery();
        Test.stopTest();

        System.assert(!selectedDQApprovers.isEmpty(), 'Deal Qualification Approver record should be selected');
    }
}