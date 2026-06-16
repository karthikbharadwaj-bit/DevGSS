@isTest
public class Test_OpportunityLightningController {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void testOpportunityLightningController() {
         Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();
        string Dummycheck ='1/0';
        Test.startTest();
        OpportunityLightningController.opportunityEndOfMonth(opp.Id);
        OpportunityLightningController.opportunityEndOfQuarter(opp.Id);
        Opportunity_workwithpartnerController.getOpprecord(opp.Id);
        Opportunity_workwithpartnerController.getApprovalrecordtype(opp.Id);
        Opportunity_workwithpartnerController.getIsAllForecastedUsersZero(opp.Id);
        Opportunity_CreateSalesAgreement.getContact(opp.Id);
        Opportunity_CreateSalesAgreement.getContact(Dummycheck);
        Opportunity_SubmitRFP.getOpportunityDetail(opp.Id);
        
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
    static void OpportunityControllerwithapproval_test() {
         Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();
        String APPRecordTypeId = [Select Id From RecordType Where SobjectType = 'Approval__c' and Name = 'Channel Cross Sell'].Id;
        Approval__c App = new Approval__c();
        App.opportunity__c=opp.id;
        App.RecordTypeId=APPRecordTypeId;
        Insert App;
        Opportunity_workwithpartnerController.getApprovalrecordtype(opp.Id);
        
    }

}