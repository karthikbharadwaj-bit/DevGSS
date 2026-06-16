@isTest
public class Test_DealQualificationApproverHandler {

    @isTest
    static void testSetClosedDateTime() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
            Opportunity.CloseDate => System.today(),
            Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
        })
        .create()
        .getRecord();
    
        DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id,
                DQ_Deal_Qualification__c.Status__c => DealQualificationHandler.DQ_PENDING_STATUS
            })
            .create()
            .getRecord();

        DQ_Approval_Step__c dqApprovalStep = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step__c.Name => 'Level 1'
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification_Approver__c dqa = (DQ_Deal_Qualification_Approver__c) new SObjectBuilder(DQ_Deal_Qualification_Approver__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification_Approver__c.Approval_Step__c => dqApprovalStep.Id,
                DQ_Deal_Qualification_Approver__c.Deal_Qualification__c => dq.Id,
                DQ_Deal_Qualification_Approver__c.Status__c => 'Pending'
            })
            .create()
            .getRecord();

        dqa.Status__c = DQDataHelper.STATUS_APPROVED;
        update dqa;

        List<DQ_Deal_Qualification_Approver__c> dqaList = new DealQualificationApproverSelector()
            .selectDQApprovers()
            .selectFields(new List<Schema.SObjectField> {DQ_Deal_Qualification_Approver__c.ClosedDateTime__c})
            .executeQuery();

        System.assertNotEquals(null, dqaList.get(0).ClosedDateTime__c, 'Closed DateTime should be populated on DQ Qualification');
    }

    @isTest
    static void testCountApprovalsOnDQOnInsert() {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .setField(Opportunity.BusinessIdentity__c, OpportunityHelper.businessIdentitySerialize(Integer.valueOf(RingCentralHelper.BUSINESS_IDENTITY_VERIZON), RingCentralHelper.USD))
            .build()
            .getRecord();

        Triggers.switchOn();

        List<DQ_Deal_Qualification__c> dq = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','SOHO',testOpportunity.Id);
        insert dq;

        List<DQ_Approval_Step__c> dqStep = DQApprovalTestDataFactory.generateDQApprovalStep(1);
        insert dqStep;

        insert new DQ_Deal_Qualification_Approver__c(
            Deal_Qualification__c = dq.get(0).Id,
            Approval_Step__c = dqStep.get(0).Id
        );

        List<DQ_Deal_Qualification__c> existingDqRecords = (List<DQ_Deal_Qualification__c>) new DealQualificationSelector()
            .selectDQs()
            .selectFields(
                new Set<SObjectField>{
                    DQ_Deal_Qualification__c.NumberOfApprovers__c
                }
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{ dq })
            .executeQuery();

        System.assertEquals(1, existingDqRecords.get(0).NumberOfApprovers__c, 'NumberOfApprovers__c should be 1');
    }

    @isTest
    static void testCountApprovalsOnDQOnDelete() {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .setField(Opportunity.BusinessIdentity__c, OpportunityHelper.businessIdentitySerialize(Integer.valueOf(RingCentralHelper.BUSINESS_IDENTITY_VERIZON), RingCentralHelper.USD))
            .build()
            .getRecord();

        Triggers.switchOn();

        List<DQ_Deal_Qualification__c> dq = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','SOHO',testOpportunity.Id);
        insert dq;

        List<DQ_Approval_Step__c> dqStep = DQApprovalTestDataFactory.generateDQApprovalStep(1);
        insert dqStep;

        insert new DQ_Deal_Qualification_Approver__c(
            Deal_Qualification__c = dq.get(0).Id,
            Approval_Step__c = dqStep.get(0).Id
        );

        delete [SELECT Id FROM DQ_Deal_Qualification_Approver__c];

        List<DQ_Deal_Qualification__c> existingDqRecords = (List<DQ_Deal_Qualification__c>) new DealQualificationSelector()
            .selectDQs()
            .selectFields(
                new Set<SObjectField>{
                    DQ_Deal_Qualification__c.NumberOfApprovers__c
                }
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{ dq })
            .executeQuery();

        System.assertEquals(0, existingDqRecords.get(0).NumberOfApprovers__c, 'NumberOfApprovers__c should be 0');
    }
}