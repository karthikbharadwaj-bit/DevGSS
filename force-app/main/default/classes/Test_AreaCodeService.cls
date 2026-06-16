@isTest
private class Test_AreaCodeService {

    private static final List<String> COUNTRIES = new List<String>{
        'USA', 'UK', 'Germany', 'France'
    };
    private static final List<String> STATES = new List<String>{
        'Utah', 'Vermont', 'Virginia', 'Washington',
        'West Virginia', 'Wisconsin', 'Wyoming'
    };
    private static final List<String> CITIES = new List<String>{
        'Arkadelphia', 'Arkansas Post', 'Batesville',
        'Benton', 'Blytheville', 'Camden', 'Conway'
    };
    private static final List<Integer> AREA_CODES = new List<Integer>{
        123, 456, 789, 101, 232
    };

    @TestSetup
    static void createTestData() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
                }
            )
            .create()
            .getRecord();

        Product2 productMonthly = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Family => Product2Helper.FAMILY_SERVICE,
                    Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                    Product2.ExtID__c => ValueProviderBuilder.provideUniqueString(
                        Product2Helper.MOBILE_USER_ELEMENT_ID
                    )
                }
            )
            .create()
            .getRecord();

        Product2 productAnnual = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                    Product2.Family => Product2Helper.FAMILY_SERVICE,
                    Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                    Product2.ExtID__c => ValueProviderBuilder.provideUniqueString()
                }
            )
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Tier_ID__c => ValueProviderBuilder.provideUniqueString()
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                    Quote.Pricebook2Id => pricebook.Id
                }
            )
            .create()
            .getRecord();

        PricebookEntry standartPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => productMonthly.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                }
            )
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => pricebook.Id,
                    PricebookEntry.Product2Id => productMonthly.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                }
            )
            .create()
            .getRecord();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => qt.Id,
                    QuoteLineItem.Deactivated__c => false,
                    QuoteLineItem.Product2Id => productMonthly.Id,
                    QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Discount => 2
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        List<Area_Codes__c> areaCodes = (List<Area_Codes__c>) new SobjectBuilder(Area_Codes__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Area_Codes__c.Area_Code__c => ValueProviderBuilder.provideList(AREA_CODES),
                    Area_Codes__c.Country__c => ValueProviderBuilder.provideList(COUNTRIES),
                    Area_Codes__c.State__c => ValueProviderBuilder.provideList(STATES),
                    Area_Codes__c.City__c => ValueProviderBuilder.provideList(CITIES)
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        List<Area_Code_Line_Item__c> aclis = (List<Area_Code_Line_Item__c>) new SobjectBuilder(
                Area_Code_Line_Item__c.SObjectType
            )
            .setFields(
                new Map<SObjectField, Object>{
                    Area_Code_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideParents(qlis),
                    Area_Code_Line_Item__c.Area_Code__c => ValueProviderBuilder.provideParents(areaCodes),
                    Area_Code_Line_Item__c.Quantity__c => 2
                }
            )
            .quantity(3)
            .create()
            .getRecords();
        Triggers.switchOn();
    }

    @isTest
    private static void testGetAreaCodeLineItems() {

        Opportunity opp = ((List<Opportunity>) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery())
            .get(0);

        Quote qt = ((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery())
            .get(0);

        Test.startTest();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'getAreaCodeLineItems';
        params.opportunityId = opp.Id;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(
            JSON.serialize(params)
        );

        AreaCodeService.handleRequest();

        Test.stopTest();

        Integer aclisQuantity = ((List<Object>) deserializeData(
            RestContext.response.responseBody.toString()
        )
        .get('areaCodeLineItems')).size();

        Integer aclisTestQuantity = ((List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
            .selectAreaCodeLineItems(new List<Object>{ (String) qt.Id })
            .executeQuery())
            .size();

        System.assertEquals(
            aclisTestQuantity,
            aclisQuantity,
            'Incorrect Area Code Line Items was retrieved'
        );
    }

    @isTest
    private static void testSyncAreaCodeLineItemsWithAreaCodes() {

        List<Area_Code_Line_Item__c> aclis = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
            .selectAreaCodeLineItemsWithAreaCodes()
            .executeQuery();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();
        
        Quote qt = ((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery())
            .get(0);

        Test.startTest();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'syncAreaCodeLineItems';
        params.areaCodeLineItems = getAreaCodeItemsFromACLIs(aclis);
        params.qliMap = getQLIToCatalogItemMaps(qlis);
        params.quoteId = qt.Id;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(
            JSON.serialize(params)
        );

        AreaCodeService.handleRequest();

        Test.stopTest();

        Integer upsertedRecords = (Integer) deserializeData(
            RestContext.response.responseBody.toString()
        )
        .get('upsertedRecords');

        Integer deletedRecords = (Integer) deserializeData(
            RestContext.response.responseBody.toString()
        )
        .get('deletedRecords');

        Integer aclisTestQuantity = ((List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
            .selectAreaCodeLineItems(new List<Object>{ (String) qt.Id })
            .executeQuery())
            .size();

        Integer areaCodesQuantity = ((List<Area_Codes__c>) new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery())
            .size();

        System.assertEquals(
            aclisTestQuantity,
            upsertedRecords,
            'Incorrect Area Code Line Items was upserted'
        );

        System.assertEquals(
            0,
            deletedRecords,
            'Incorrect Area Code Line Items was deleted'
        );

        System.assertEquals(
            areaCodesQuantity,
            3,
            'Area Codes was created incorrectly'
        );
    }

    @isTest
    private static void testSyncAreaCodeLineItemsWithoutAreaCodes() {

        List<Area_Code_Line_Item__c> aclis = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
            .selectAreaCodeLineItemsWithAreaCodes()
            .executeQuery();

        List<Area_Codes__c> areaCodes = (List<Area_Codes__c>) new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery();
        
        Quote qt = ((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery())
            .get(0);

        for (Area_Code_Line_Item__c acli : aclis) {
            acli.Area_Code__c = areaCodes.get(0).Id;
        }

        Triggers.switchOff();

        update aclis;
        areaCodes.remove(0);
        delete areaCodes;

        Triggers.switchOn();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        Test.startTest();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'syncAreaCodeLineItems';
        params.areaCodeLineItems = getAreaCodeItemsFromACLIs(aclis);
        params.qliMap = getQLIToCatalogItemMaps(qlis);
        params.quoteId = qt.Id;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(
            JSON.serialize(params)
        );

        AreaCodeService.handleRequest();

        Test.stopTest();

        Integer upsertedRecords = (Integer) deserializeData(
            RestContext.response.responseBody.toString()
        )
        .get('upsertedRecords');

        Integer deletedRecords = (Integer) deserializeData(
            RestContext.response.responseBody.toString()
        )
        .get('deletedRecords');

        Integer aclisTestQuantity = ((List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
            .selectAreaCodeLineItems(new List<Object>{ (String) qt.Id })
            .executeQuery())
            .size();

        Integer areaCodesQuantity = ((List<Area_Codes__c>) new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery())
            .size();

        System.assertEquals(
            aclisTestQuantity,
            upsertedRecords,
            'Incorrect Area Code Line Items was upserted'
        );

        System.assertEquals(
            0,
            deletedRecords,
            'Incorrect Area Code Line Items was deleted'
        );

        System.assertEquals(
            areaCodesQuantity,
            3,
            'Area Codes was created incorrectly'
        );
    }

    @isTest
    private static void testSyncAreaCodeLineItemsWithDeletedItems() {

        List<Area_Code_Line_Item__c> aclis = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
            .selectAreaCodeLineItemsWithAreaCodes()
            .executeQuery();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();
        
        Quote qt = ((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery())
            .get(0);

        Test.startTest();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'syncAreaCodeLineItems';
        List<BillingWrappers.AreaCodeLineItem> areaCodeItems = getAreaCodeItemsFromACLIs(aclis);
        areaCodeItems.get(0).isDeleted = true;
        params.areaCodeLineItems = areaCodeItems;
        params.qliMap = getQLIToCatalogItemMaps(qlis);
        params.quoteId = qt.Id;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(
            JSON.serialize(params)
        );

        AreaCodeService.handleRequest();

        Test.stopTest();

        Integer upsertedRecords = (Integer) deserializeData(
            RestContext.response.responseBody.toString()
        )
        .get('upsertedRecords');

        Integer deletedRecords = (Integer) deserializeData(
            RestContext.response.responseBody.toString()
        )
        .get('deletedRecords');

        Integer aclisTestQuantity = ((List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
            .selectAreaCodeLineItems(new List<Object>{ (String) qt.Id })
            .executeQuery())
            .size();

        Integer areaCodesQuantity = ((List<Area_Codes__c>) new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery())
            .size();

        System.assertEquals(
            aclisTestQuantity,
            upsertedRecords,
            'Incorrect Area Code Line Items was upserted'
        );

        System.assertEquals(
            1,
            deletedRecords,
            'Incorrect Area Code Line Items was deleted'
        );

        System.assertEquals(
            areaCodesQuantity,
            3,
            'Area Codes was created incorrectly'
        );
    }

    @isTest
    private static void testSyncAreaCodeLineItemsWithIncorrectData() {

        List<Area_Code_Line_Item__c> aclis = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
            .selectAreaCodeLineItemsWithAreaCodes()
            .executeQuery();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();
        
        Quote qt = ((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery())
            .get(0);

        Test.startTest();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'syncAreaCodeLineItems';
        List<BillingWrappers.AreaCodeLineItem> areaCodeItems = getAreaCodeItemsFromACLIs(aclis);
        areaCodeItems.get(0).isDeleted = null;
        params.areaCodeLineItems = areaCodeItems;
        params.qliMap = getQLIToCatalogItemMaps(qlis);
        params.quoteId = qt.Id;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(
            JSON.serialize(params)
        );

        AreaCodeService.handleRequest();

        Test.stopTest();

        Map<String,Object> emptyResponse = (Map<String,Object>) deserializeData(
            RestContext.response.responseBody.toString()
        );

        System.assertEquals(
            null,
            emptyResponse,
            'Incorrect response on error'
        );
    }

    @isTest
    private static void testSyncAreaCodeLineItemsWithIncorrectAction() {

        Test.startTest();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'errorAction';

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(
            JSON.serialize(params)
        );

        AreaCodeService.handleRequest();

        Test.stopTest();

        String errorAction = (String) deserializeData(
            RestContext.response.responseBody.toString()
        )
        .get('error');

        System.assertEquals(
            errorAction,
            AreaCodeService.ERROR_ACTION,
            'Incorrect response with failed action'
        );
    }

    private static Map<String, Object> deserializeData(String data) {
        return (Map<String, Object>) (((Map<String, Object>) JSON.deserializeUntyped(data)).get('data'));
    }

    private static List<BillingWrappers.AreaCodeLineItem> getAreaCodeItemsFromACLIs(
        List<Area_Code_Line_Item__c> aclis
    ) {
        List<BillingWrappers.AreaCodeLineItem> areaCodeItems = new List<BillingWrappers.AreaCodeLineItem>();

        for (Area_Code_Line_Item__c acli : aclis) {
            BillingWrappers.AreaCodeLineItem areaCodeItem = new BillingWrappers.AreaCodeLineItem();
            areaCodeItem.areaCodeInfo = new BillingWrappers.AreaCodeData();

            areaCodeItem.id = acli.Id;
            areaCodeItem.cartItemCatalogId = acli.Quote_Line_Item__c;
            areaCodeItem.quantity = Integer.valueOf(acli.Quantity__c);
            areaCodeItem.areaCodeInfo.country = acli.Area_Code__r.Country__c;
            areaCodeItem.areaCodeInfo.state = acli.Area_Code__r.State__c;
            areaCodeItem.areaCodeInfo.city = acli.Area_Code__r.City__c;
            areaCodeItem.areaCodeInfo.areaCode = Integer.valueOf(acli.Area_Code__r.Area_Code__c);
            areaCodeItem.isDeleted = false;

            areaCodeItems.add(areaCodeItem);
        }

        return areaCodeItems;
    }

    private static Map<String, String> getQLIToCatalogItemMaps(List<QuoteLineItem> qlis) {
        Map<String, String> qliToCatalogIdMap = new Map<String, String>();

        for (QuoteLineItem qli : qlis) {
            qliToCatalogIdMap.put(qli.Id, qli.Id);
        }

        return qliToCatalogIdMap;
    }


    @isTest
    private static void testSyncAreaCodesForAssignmentLineItemMethod() {

        Quote qt = ((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery())
            .get(0);

        Area_Codes__c testAreaCode = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Area_Codes__c.Country__c => 'United States',
                    Area_Codes__c.State__c => 'Texas',
                    Area_Codes__c.Area_Code__c => 100
                }
            )
            .create()
            .getRecord();

        BillingWrappers.AreaCodeData areaCodeDataNew = new BillingWrappers.AreaCodeData();
        areaCodeDataNew.country = 'United States';
        areaCodeDataNew.state = 'Alabama';
        areaCodeDataNew.city = '';
        areaCodeDataNew.areaCode = 200;

        BillingWrappers.AssignmentLineItem ali = new BillingWrappers.AssignmentLineItem();
        ali.areaCodeInfo = areaCodeDataNew;

        BillingWrappers.AssignmentLineItem ali2 = new BillingWrappers.AssignmentLineItem();

        BillingWrappers.AreaCodeData areaCodeDataExisting = new BillingWrappers.AreaCodeData();
        areaCodeDataExisting.country = 'United States';
        areaCodeDataExisting.state = 'Texas';
        areaCodeDataExisting.city = '';
        areaCodeDataExisting.areaCode = 100;

        ali2.areaCodeInfo = areaCodeDataExisting;

        List<BillingWrappers.AssignmentLineItem> assignmentLineItemList = new List<BillingWrappers.AssignmentLineItem>();
        assignmentLineItemList.add(ali);
        assignmentLineItemList.add(ali2);

        Map<String, Area_Codes__c> areaIdToAreaCodeMap = AreaCodeService.syncAreaCodesForAssignmentLineItem(assignmentLineItemList, qt.Id);

        Set<Id> areaCodeIdSet = new Set<Id>();
        for (Area_Codes__c ac : areaIdToAreaCodeMap.values()) {
            areaCodeIdSet.add(ac.Id);
        }

       List<Area_Codes__c> reselectedAreaCodes = (List<Area_Codes__c>) new AreaCodesSelector()
            .selectAreaCodes()
            .setCondition('Area_Code__c IN :bind0')
            .setQueryBindings(new List<Object>{ New Set<Integer>{100, 200} })
            .executeQuery();

        for (Area_Codes__c ac : reselectedAreaCodes) {
            System.assert(areaCodeIdSet.contains(ac.Id));
        }
    }
}