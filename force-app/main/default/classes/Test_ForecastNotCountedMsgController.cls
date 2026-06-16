@IsTest
public with sharing class Test_ForecastNotCountedMsgController {
    @isTest
    static void testGetDataWithUncheckedIsQuotingAvailable() {
        ForecastNotCountedMsgController.ResponseWrapper result;

        LeadConversionConfiguration__c setting =  (LeadConversionConfiguration__c) new SobjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                LeadConversionConfiguration__c.Name => 'Test brand',
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => false
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Brand_Name__c => 'Test brand',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_SOLUTION,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create()
            .getRecord();

        Test.startTest();
        result = (ForecastNotCountedMsgController.ResponseWrapper) JSON.deserialize(ForecastNotCountedMsgController.getData(opp.Id), ForecastNotCountedMsgController.ResponseWrapper.class);
        Test.stopTest();

        System.assertEquals(true, result.isDisplayMessage, 'ForecastNotCountedMsg aura component is not displayed');
        System.assert(OpportunityHelper.STAGE_NAMES_NO_FORECASTING_REPORTS.contains(result.opp.StageName), 'ForecastNotCountedMsg aura component is not displayed');
     }

    @isTest
    static void testGetDataWithCheckedIsQuotingAvailable() {
        ForecastNotCountedMsgController.ResponseWrapper result;

        LeadConversionConfiguration__c setting =  (LeadConversionConfiguration__c) new SobjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                LeadConversionConfiguration__c.Name => 'Test brand',
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => true
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Account.Name => 'Test account'
        })
        .create()
        .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Brand_Name__c => 'Test brand',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_PROBLEM
            })
            .create()
            .getRecord();

        Test.startTest();
        result = (ForecastNotCountedMsgController.ResponseWrapper) JSON.deserialize(ForecastNotCountedMsgController.getData(opp.Id), ForecastNotCountedMsgController.ResponseWrapper.class);
        Test.stopTest();

        System.assertEquals(false, result.isDisplayMessage, 'ForecastNotCountedMsg aura component is displayed');
        System.assert(!OpportunityHelper.STAGE_NAMES_NO_FORECASTING_REPORTS.contains(result.opp.StageName),'ForecastNotCountedMsg aura component is displayed');
        }
}