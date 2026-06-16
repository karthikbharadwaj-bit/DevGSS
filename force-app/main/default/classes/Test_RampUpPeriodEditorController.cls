@isTest private class Test_RampUpPeriodEditorController {

    @isTest
    static void testCreate() {

        Account testAcc = new Account(
            Name = 'testAccount'
        );
        insert testAcc;

        Opportunity testOpp = new Opportunity(
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Professional',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert testOpp;

        Id stdPricebookId = Test.getStandardPricebookId();

        Order testOrder = new Order(
            AccountId = testAcc.Id,
            OpportunityId = testOpp.Id,
            Status = 'New',
            EffectiveDate = Date.today(),
            Pricebook2Id = stdPricebookId,
            RecordTypeId = OrderHelper.RT_ID_CC
        );
        insert testOrder;

        testOrder = (Order) new OrderSelector()
            .selectOrders()
            .selectFields(RampUpPeriodEditorController.FIELDS_TO_QUERY)
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<String>{testOrder.Id})
            .executeQuery()
            .get(0);
        ApexPages.StandardController sc = new ApexPages.StandardController(testOrder);
        RampUpPeriodEditorController ctrl = new RampUpPeriodEditorController(sc);
        System.assertNotEquals(null, ctrl);
    }
}