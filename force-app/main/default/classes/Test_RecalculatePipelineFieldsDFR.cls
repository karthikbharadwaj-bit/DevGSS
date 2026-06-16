@isTest
public with sharing class Test_RecalculatePipelineFieldsDFR {

    @isTest
    static void testOpportunityPipelineRecalculationSingleOppInsert() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Opty test account')
            .setField(Account.Partner_ID__c, 'testID')
            .setField(Account.Permitted_Brands__c, 'RingCentral')
            .setField(Account.Phone, '12314233')
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Contact_Status__c, LeadHelper.STATUS_NEW)
            .setField(Contact.Email, 'testemail@emailtester.com')
            .setField(Contact.Phone, '12314233')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.CloseDate, System.today().addMonths(5))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Estimated_12M_Total_Pipeline__c, 200)
            .setField(Opportunity.Estimated_Total_MRR__c, 1)
            .setField(Opportunity.Tier_Name__c, OpportunityHelper.TIER_OFFICE)
            .setField(Opportunity.CurrencyIsoCode, 'EUR')
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();
        
        Test.startTest();
        Database.executeBatch(new RecalculatePipelineFieldsDFR(), 200);
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String> {
                'Estimated_12M_Total_Pipeline_OC__c',
                'Opportunity_Currency__c',
                'Opportunity_Exchange_Rate__c',
                'Estimated_12M_Total_Pipeline_DC__c',
                'Estimated_12M_Total_Pipeline_TC__c'
            }
        );
        System.assertEquals(200, dfrList[0].Estimated_12M_Total_Pipeline_OC__c , 'Estimated_12M_Total_Pipeline_OC__c incorrect value');
        System.assertEquals('EUR', dfrList[0].Opportunity_Currency__c, 'Opportunity_Currency__c incorrect value');
        System.assert(dfrList[0].Opportunity_Exchange_Rate__c != null, 'Opportunity_Exchange_Rate__c incorrect value');
        System.assert(dfrList[0].Estimated_12M_Total_Pipeline_DC__c != null, 'Estimated_12M_Total_Pipeline_DC__c incorrect value');
        System.assert(dfrList[0].Estimated_12M_Total_Pipeline_TC__c.contains('EUR'), 'Estimated_12M_Total_Pipeline_TC__c incorrect value');
    }
}