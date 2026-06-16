@isTest
private class Test_AreaCodeLineItemSelector {

    private static final Integer QUANTITY = 3;

    @testSetup
    static void makeData() {

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Name => 'Test Product',
                        Product2.IsActive => true
                    }
                )
            .create()
            .getRecord();

        PriceBookEntry testPrice = (PriceBookEntry) new SObjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                        PriceBookEntry.Product2Id => testProduct.Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false
                    }
                )
                .create()
                .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.Name => 'Test Opportunity',
                        Opportunity.StageName => '1. Qualify'
                    }
                )
                .create()
                .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote..SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => 'Quote Test',
                        Quote.OpportunityId => testOpportunity.Id,
                        Quote.Pricebook2Id => Test.getStandardPriceBookId()
                    }
                )
                .create()
                .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.QuoteId => testQuote.Id,
                        QuoteLineItem.Product2Id => testProduct.Id,
                        QuoteLineItem.PricebookEntryId => testPrice.Id,
                        QuoteLineItem.UnitPrice => testPrice.UnitPrice,
                        QuoteLineItem.Quantity => 5
                    }
                )
                .create()
                .getRecord();

        Area_Codes__C testAc = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Area_Codes__c.Name => 'Test Area Code',
                        Area_Codes__c.State__c => 'NY',
                        Area_Codes__c.Country__c => 'United States'
                    }
                )
                .create()
                .getRecord();
    }

    @isTest
    static void testSelectACLIForSignUp() {

        Test.startTest();

        List<Area_Code_Line_Item__c> aclis = insertACLIsForTesting();

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .executeQuery();

        List<Area_Code_Line_Item__c> testACLIs = new AreaCodeLineItemSelector()
                .selectACLIForSignUp(new List<Object> {new Set<Id> {qlis[0].Id} })
                .executeQuery();

        Test.stopTest();

        System.assertEquals(
            aclis.size(),
            testACLIs.size(),
            'Incorrect Area Code Line Items were retrieved'
        );
    }

    @isTest
    static void testSelectACLIForQuotes() {

        Test.startTest();

        List<Area_Code_Line_Item__c> aclis = insertACLIsForTesting();

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .executeQuery();

        List<Area_Code_Line_Item__c> testACLIs = new AreaCodeLineItemSelector()
                .selectACLIForQuotes(new Set<Id> {qlis[0].QuoteId})
                .executeQuery();

        Test.stopTest();

        System.assertEquals(
            aclis.size(),
            testACLIs.size(),
            'Incorrect Area Code Line Items were retrieved'
        );
    }

    @isTest
    static void testSelectAreaCodeLineItems() {

        Quote qt = ((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery())
            .get(0);

        Test.startTest();

        List<Area_Code_Line_Item__c> aclis = insertACLIsForTesting();
        List<Area_Code_Line_Item__c> testACLIs = new AreaCodeLineItemSelector()
                .selectAreaCodeLineItems(new List<Object>{ (String) qt.Id })
                .executeQuery();

        Test.stopTest();

        System.assertEquals(
            aclis.size(),
            testACLIs.size(),
            'Incorrect Area Code Line Items were retrieved'
        );
    }

    @isTest
    static void testSelectAreaCodeLineItemsWithAreaCodes() {

        Test.startTest();

        List<Area_Code_Line_Item__c> aclis = insertACLIsForTesting();
        List<Area_Code_Line_Item__c> testACLIs = new AreaCodeLineItemSelector()
                .selectAreaCodeLineItemsWithAreaCodes()
                .executeQuery();

        Test.stopTest();

        System.assertEquals(
            aclis.size(),
            testACLIs.size(),
            'Incorrect Area Code Line Items were retrieved'
        );
    }

    @isTest
    static void testSelectACLIForMasterQuotes() {

        Test.startTest();

        List<Area_Code_Line_Item__c> aclis = insertACLIsForTesting();

        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery();
        List<Id> quoteIds = new List<Id>();
        for (Quote qt: quotes) {
            quoteIds.add(qt.Id);
        }

        List<Area_Code_Line_Item__c> testACLIs = new AreaCodeLineItemSelector()
                .selectACLIForMasterQuotes(new List<Object>{ quoteIds })
                .executeQuery();

        Test.stopTest();

        System.assertEquals(
            aclis.size(),
            testACLIs.size(),
            'Incorrect Area Code Line Items were retrieved'
        );
    }

    @isTest
    static void testSelectACLIForDealDeskCaseDescription() {
        Map<Id, QuoteLineItem> qlisMap = new Map<Id, QuoteLineItem>(
            (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .executeQuery()
        );

        Test.startTest();

        Map<Id, Area_Code_Line_Item__c> aclisMap = new Map<Id, Area_Code_Line_Item__c>(insertACLIsForTesting());

        List<Area_Code_Line_Item__c> result = new AreaCodeLineItemSelector()
            .selectACLIForDealDeskCaseDescription(new List<Object>{qlisMap.keySet()})
            .executeQuery();

        Test.stopTest();

        System.assertEquals(aclisMap.values().size(), result.size(), 'Area Code Line Items were retrieved incorrectly');
        for (Area_Code_Line_Item__c acli : result) {
            Assert.isNotNull(aclisMap.get(acli.Id), 'Some Area Code Line Items were retrieved incorrectly');
        }
    }

    private static List<Area_Code_Line_Item__c> insertACLIsForTesting() {

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .executeQuery();

        List<Area_Codes__c> acs = new AreaCodesSelector()
                .selectAreaCodes()
                .executeQuery();

        return new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Area_Code_Line_Item__c.Quote_Line_Item__c => qlis[0].Id,
                    Area_Code_Line_Item__c.Area_Code__c => acs[0].Id,
                    Area_Code_Line_Item__c.Quantity__c => 10
                }
            )
            .quantity(QUANTITY)
            .create()
            .getRecords();
    }
}