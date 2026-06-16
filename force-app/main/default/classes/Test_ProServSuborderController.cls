@isTest private class Test_ProServSuborderController {

    @isTest
    static void testInvokeController() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Id stdPricebookId = Test.getStandardPricebookId();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.AccountId => testAcc.Id,
                Order.OpportunityId => testOpp.Id,
                Order.Status => 'New',
                Order.EffectiveDate => Date.today(),
                Order.Pricebook2Id => stdPricebookId,
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();

        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.standardController(testOrder);
            ProServSuborderController proServSuborderController = new ProServSuborderController(sc);
        Test.stopTest();
        
        System.assertNotEquals(null, proServSuborderController, 'Contrller should be created');
    }
}