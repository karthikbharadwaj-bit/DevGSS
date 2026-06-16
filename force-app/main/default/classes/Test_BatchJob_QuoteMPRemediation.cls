@isTest
private class Test_BatchJob_QuoteMPRemediation {
    @isTest
    static void testQuoteServiceNameRemidiation() {
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
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_RC_MEETINGS,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => testOpp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        List<Product2> productsMonthly = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_PHONE,
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String> {'LC_HD_141', 'LC_HD_139'}),
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> standardPricebookEntry = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<String> {productsMonthly[0].Id, productsMonthly[1].Id}),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<String> {productsMonthly[0].Id, productsMonthly[1].Id}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<String> {standardPricebookEntry[0].Id, standardPricebookEntry[1].Id}),
                QuoteLineItem.Quantity => 6,
                QuoteLineItem.UnitPrice => 10
            })
            .quantity(2)
            .create()
            .getRecords();

        Integer countQuotes = [SELECT COUNT() FROM Quote WHERE RecordType.Name = 'Sales Quote v2' and ServiceName__c = null];
        Integer countQlis = [SELECT COUNT() FROM QuoteLineItem WHERE Quote.RecordType.Name = 'Sales Quote v2' and ServiceName__c = null];
        System.assertEquals(1, countQuotes, 'Quotes count with empty Service Name should be equals 1');
        System.assertEquals(2, countQlis, 'QLIs count with empty Service Name should be equals 2');

        Test.startTest();
        String query = 'SELECT Id, ServiceName__c, RecordType.Name, Opportunity.Tier_Name__c, (SELECT ServiceName__c FROM QuoteLineItems) FROM QUOTE WHERE RecordType.Name = \'Sales Quote v2\' and ServiceName__c = null';
        BatchJob_QuotesAndQLIsMPRemediation batchJob = new BatchJob_QuotesAndQLIsMPRemediation(query, true);
        Database.executeBatch(batchJob);
        Test.stopTest();

        countQuotes = [SELECT COUNT() FROM Quote WHERE RecordType.Name = 'Sales Quote v2' and ServiceName__c = null];
        countQlis = [SELECT COUNT() FROM QuoteLineItem WHERE Quote.RecordType.Name = 'Sales Quote v2' and ServiceName__c = null];
        Quote updatedQuote = [SELECT ServiceName__c, (SELECT ServiceName__c FROM QuoteLineItems) FROM Quote WHERE Id =: testQuote.Id LIMIT 1];

        System.assertEquals(0, countQuotes, 'Quotes count with empty Service Name should be equals 0 after remediation');
        System.assertEquals(0, countQlis, 'QLIs count with empty Service Name should be equals 0 after remediation');
        System.assertEquals('Meetings', updatedQuote.ServiceName__c, 'Quote Service Name should be Meetings after remediation');
        for (QuoteLineItem qli : updatedQuote.QuoteLineItems) {
            System.assertEquals('Meetings', qli.ServiceName__c, 'QLI Service Name should be Meetings after remediation');
        }

    }
}