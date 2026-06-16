@isTest
private class Test_AssignmentLineItemSelector {

    private static final Integer ALI_QUANTITY = 2;

    @TestSetup
    private static void prepareTestData() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Product2 productMonthly = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        Product2 productAnnual = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Tier_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => pricebook.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        PricebookEntry standartPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productMonthly.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pricebook.Id,
                PricebookEntry.Product2Id => productMonthly.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productMonthly.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();

            List<AssignmentLineItem__c> alisParent = new SobjectBuilder(AssignmentLineItem__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    AssignmentLineItem__c.Parent__c => ValueProviderBuilder.provideParents(qlis),
                    AssignmentLineItem__c.Quantity__c => 2
                })
                .quantity(ALI_QUANTITY)
                .create()
                .getRecords();

            List<AssignmentLineItem__c> alisChild = new SobjectBuilder(AssignmentLineItem__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    AssignmentLineItem__c.Child__c => ValueProviderBuilder.provideParents(qlis),
                    AssignmentLineItem__c.Quantity__c => 2
                })
                .quantity(ALI_QUANTITY)
                .create()
                .getRecords();

            List<AssignmentLineItem__c> alisAllRelated = new SobjectBuilder(AssignmentLineItem__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    AssignmentLineItem__c.Child__c => ValueProviderBuilder.provideParents(qlis),
                    AssignmentLineItem__c.Parent__c => ValueProviderBuilder.provideParents(qlis),
                    AssignmentLineItem__c.Quantity__c => 2
                })
                .quantity(ALI_QUANTITY)
                .create()
                .getRecords();

        Test.stopTest();
    }

    @isTest
    private static void testGetAllRelatedALIs() {

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        Test.startTest();

        List<AssignmentLineItem__c> assignments = new AssignmentLineItemSelector()
            .selectALIForAllRelated(new List<Object> { 
                qlis.get(0).Id,
                qlis.get(1).Id,
                null
            })
            .executeQuery();

        Test.stopTest();

        Map<Id, AssignmentLineItem__c> alisById = new Map<Id, AssignmentLineItem__c>([
            SELECT Id
            FROM AssignmentLineItem__c
            WHERE Parent__c = :qlis.get(0).Id
            AND Child__c = :qlis.get(1).Id
            AND AreaCode__c = null
        ]);

        System.assertEquals(
            assignments.size(),
            alisById.keySet().size(),
            'Assignment Line Items were retrieved incorrectly'
        );

        System.assert(
            compareListAndMap(assignments, alisById),
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    @isTest
    private static void testGetALIsForQLIsRelated() {

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        Test.startTest();

        List<AssignmentLineItem__c> assignments = new AssignmentLineItemSelector()
            .selectALIForQLIsRelated(new List<Object> { 
                qlis.get(0).Id,
                qlis.get(1).Id
            })
            .executeQuery();

        Test.stopTest();

        Map<Id, AssignmentLineItem__c> alisById = new Map<Id, AssignmentLineItem__c>([
            SELECT Id
            FROM AssignmentLineItem__c
            WHERE Parent__c = :qlis.get(0).Id
            AND Child__c = :qlis.get(1).Id
        ]);

        System.assertEquals(
            assignments.size(),
            alisById.keySet().size(),
            'Assignment Line Items were retrieved incorrectly'
        );

        System.assert(
            compareListAndMap(assignments, alisById),
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    @isTest
    private static void testGetALIsForQLI() {

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        Test.startTest();

        List<AssignmentLineItem__c> assignments = new AssignmentLineItemSelector()
            .selectALIForQLI(new List<Object> { 
                qlis.get(0).Id
            })
            .executeQuery();

        Test.stopTest();

        Map<Id, AssignmentLineItem__c> alisById = new Map<Id, AssignmentLineItem__c>([
            SELECT Id
            FROM AssignmentLineItem__c
            WHERE Parent__c = :qlis.get(0).Id
                OR Child__c = :qlis.get(0).Id
        ]);

        System.assertEquals(
            assignments.size(),
            alisById.keySet().size(),
            'Assignment Line Items were retrieved incorrectly'
        );

        System.assert(
            compareListAndMap(assignments, alisById),
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    @isTest
    private static void testGetALIsForRemove() {

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        Set<Id> qliIds = new Set<Id>();

        for (QuoteLineItem qli : qlis) {
            qliIds.add(qli.Id);
        }

        Test.startTest();

        List<AssignmentLineItem__c> assignments = new AssignmentLineItemSelector()
            .selectALIForRemove(new List<Object> { qliIds })
            .executeQuery();

        Test.stopTest();

        Map<Id, AssignmentLineItem__c> alisById = new Map<Id, AssignmentLineItem__c>([
            SELECT Id
            FROM AssignmentLineItem__c
            WHERE Parent__c IN :qliIds
            OR Child__c IN :qliIds
        ]);

        System.assertEquals(
            assignments.size(),
            alisById.keySet().size(),
            'Assignment Line Items were retrieved incorrectly'
        );

        System.assert(
            compareListAndMap(assignments, alisById),
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    @isTest static void testGetALIForQuote() {
        
        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();
        
        Test.startTest();

        List<AssignmentLineItem__c> assignments = new AssignmentLineItemSelector()
            .selectALIForQuote(new List<Object> { 
            	new Set<Id> {qlis.get(0).Id},
                new Set<Id> {qlis.get(1).Id}
            })
            .executeQuery();

        Test.stopTest();

        Set<Id> qIds = new Set<Id>();
        for (QuoteLineItem qli : qlis) {
            qIds.add(qli.QuoteId);
        }
        
        List<AssignmentLineItem__c> alisById = new AssignmentLineItemSelector()
            .selectALIForQLI(new List<Object> {qIds})
            .executeQuery();
        
        System.assertEquals(
            assignments.size(),
            alisById.size(),
            'Assignment Line Items were retrieved incorrectly'
       	);

        System.assert(
            compareLists(assignments, alisById),
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    @isTest static void testGetALIForSignUp() {
        
        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        Test.startTest();

        List<AssignmentLineItem__c> assignments = new AssignmentLineItemSelector()
            .selectALIForSignUp(new List<Object> { 
                new Set<Id> {qlis.get(0).Id}
            })
            .executeQuery();

        Test.stopTest();

        List<AssignmentLineItem__c> alisById = new AssignmentLineItemSelector()
            .selectALIForQLI(new List<Object> {
                new Set<Id> {qlis.get(0).Id}
            })
            .executeQuery();

        System.assertEquals(
            assignments.size(),
            alisById.size(),
            'Assignment Line Items were retrieved incorrectly'
        );

        System.assert(
            compareLists(assignments, alisById),
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    private static Boolean compareListAndMap(
        List<AssignmentLineItem__c> alis,
        Map<Id, AssignmentLineItem__c> alisById
    ) {
        
        for (AssignmentLineItem__c ali : alis) {
            if (alisById.get(ali.Id) == null) {
                return false;
            }
        }
        return true;
    }

    private static Boolean compareLists(
        List<AssignmentLineItem__c> alis1,
        List<AssignmentLineItem__c> alis2
    ) {
        for (Integer i = 0; i < Math.Max(alis1.size(), alis2.size()); ++i) {
            if (alis1[i] != alis2[i]) {
                return false;
            }
        }
        return true;
    }

    @isTest
    private static void testSelectALIForMasterQuotes() {
        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery();
        List<Id> quoteIds = new List<Id>();
        for (Quote quote : quotes) {
            quoteIds.add(quote.Id);
        }
        Test.startTest();
        List<AssignmentLineItem__c> assignments = new AssignmentLineItemSelector()
            .selectALIForMasterQuotes(new List<Object> { quoteIds })
            .executeQuery();
        Test.stopTest();

        System.assertEquals(
            6,
            assignments.size(),
            'Assignment Line Items were retrieved incorrectly'
       	);
    }

    @isTest
    private static void testSelectALIForDealDeskCaseDescription() {
        Map<Id, QuoteLineItem> qlisMap = new Map<Id, QuoteLineItem>(
            (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .executeQuery()
        );

        Map<Id, AssignmentLineItem__c> alisMap = new Map<Id, AssignmentLineItem__c>(
            [SELECT Id FROM AssignmentLineItem__c WHERE Parent__c IN :qlisMap.keySet()]
        );

        Test.startTest();

        List<AssignmentLineItem__c> result = new AssignmentLineItemSelector()
            .selectALIForDealDeskCaseDescription(new List<Object>{qlisMap.keySet()})
            .executeQuery();

        Test.stopTest();

        System.assertEquals(alisMap.values().size(), result.size(), 'Assignment Line Items were retrieved incorrectly');
        for (AssignmentLineItem__c ali : result) {
            Assert.isNotNull(alisMap.get(ali.Id), 'Some Assignment Line Items were retrieved incorrectly');
        }
    }
}