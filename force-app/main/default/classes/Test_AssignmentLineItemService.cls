@isTest
private class Test_AssignmentLineItemService {

    private static final Integer ALI_QUANTITY = 2;
    private static final String EXCEPTION_MESSAGE = 'Request failed';

    static AssignmentLineItemService.RequestParams prepareRequestParams(
        String action,
        List<QuoteLineItem> qlis,
        List<Area_Codes__c> areaCodes,
        String quantity,
        String quoteId
    ) {
        AssignmentLineItemService.RequestParams params = new AssignmentLineItemService.RequestParams();

        params.action = action;
        params.parentId = qlis.get(0).Id;
        params.childId = qlis.get(1).Id;
        params.areaCodeId = areaCodes.get(0).Id;
        params.quantity = quantity;
        params.quoteId = quoteId;

        return params;
    }

    static Map<String, Object> deserializeData(String data) {
        return (Map<String, Object>) (((Map<String, Object>) JSON.deserializeUntyped(data)).get('data'));
    }

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
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.ExtID__c => ValueProviderBuilder.provideUniqueString(
                    Product2Helper.MOBILE_USER_ELEMENT_ID
                )
            })
            .create()
            .getRecord();

        new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.ExtID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create();

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

        new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productMonthly.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create();

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

        Area_Codes__c areaCode = (Area_Codes__c) new SobjectBuilder(Area_Codes__c.SObjectType)
            .setField(Area_Codes__c.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        new SobjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AssignmentLineItem__c.Parent__c => ValueProviderBuilder.provideParents(qlis),
                AssignmentLineItem__c.Quantity__c => 2
            })
            .quantity(ALI_QUANTITY)
            .create();

        new SobjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AssignmentLineItem__c.Child__c => ValueProviderBuilder.provideParents(qlis),
                AssignmentLineItem__c.Quantity__c => 2
            })
            .quantity(ALI_QUANTITY)
            .create();

        new SobjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AssignmentLineItem__c.Child__c => ValueProviderBuilder.provideParents(qlis),
                AssignmentLineItem__c.Parent__c => ValueProviderBuilder.provideParents(qlis),
                AssignmentLineItem__c.Quantity__c => 2,
                AssignmentLineItem__c.AreaCode__c => areaCode.Id
            })
            .quantity(ALI_QUANTITY)
            .create();

        Triggers.switchOn();
    }

    @isTest
    private static void testCreateAssignmentLineItem() {

        Test.startTest();

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        List<Area_Codes__c> areaCodes = new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery();

        List<Quote> quotes = new QuoteSelector()
            .selectQuotes()
            .executeQuery();

        AssignmentLineItemService.RequestParams params = prepareRequestParams(
            'createAssignmentLineItem',
            qlis,
            areaCodes,
            '3',
            quotes.get(0).Id
        );
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        AssignmentLineItemService.handleRequest();

        Test.stopTest();

        String aliId = String.valueOf(
            deserializeData(
                RestContext.response.responseBody.toString()
            )
            .get('assignmentLineItemId')
        );

        System.assertEquals(
            aliId,
            String.valueOf([
                SELECT Id
                FROM AssignmentLineItem__c
                WHERE Parent__c = :qlis.get(0).Id
                AND Child__c = :qlis.get(1).Id
                AND AreaCode__c = :areaCodes.get(0).Id
                AND Quantity__c = 3
                LIMIT 1
            ].Id),
            'Incorrect Assignment Line Item was created'
        );
    }

    @isTest
    private static void testGetAssignmentLineItems() {

        Test.startTest();

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        List<Area_Codes__c> areaCodes = new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery();

        List<Quote> quotes = new QuoteSelector()
            .selectQuotes()
            .executeQuery();

        AssignmentLineItemService.RequestParams params = prepareRequestParams(
            'getAssignmentLineItems',
            qlis,
            areaCodes,
            '2',
            quotes.get(0).Id
        );
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        AssignmentLineItemService.handleRequest();

        Test.stopTest();

        Integer aliSize = ((List<Object>) deserializeData(
            RestContext.response.responseBody.toString()
        )
        .get('assignmentLineItems')).size();

        System.assertEquals(
            aliSize, [
                SELECT COUNT()
                FROM AssignmentLineItem__c
                WHERE Parent__c = :qlis.get(0).Id
                AND Child__c = :qlis.get(1).Id
                AND AreaCode__c = :areaCodes.get(0).Id
            ],
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    @isTest
    private static void testGetAssignmentLineItemsForQuote() {

        Test.startTest();

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        List<Area_Codes__c> areaCodes = new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery();

        List<Quote> quotes = new QuoteSelector()
            .selectQuotes()
            .executeQuery();

        AssignmentLineItemService.RequestParams params = prepareRequestParams(
            'getAssignmentLineItemsForQuote',
            qlis,
            areaCodes,
            '2',
            quotes.get(0).Id
        );
        params.quoteId = quotes.get(0).Id;
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        AssignmentLineItemService.handleRequest();

        Test.stopTest();

        Integer aliSize = ((List<Object>) deserializeData(
            RestContext.response.responseBody.toString()
        )
        .get('assignmentLineItems')).size();

        System.assertEquals(
            6,
            aliSize,
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    @isTest
    private static void testUpdateAssignmentLineItem() {

        Test.startTest();

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        List<Area_Codes__c> areaCodes = new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery();

        List<Quote> quotes = new QuoteSelector()
            .selectQuotes()
            .executeQuery();

        AssignmentLineItemService.RequestParams params = prepareRequestParams(
            'updateAssignmentLineItem',
            qlis,
            areaCodes,
            '2',
            quotes.get(0).Id
        );
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        AssignmentLineItemService.handleRequest();

        Test.stopTest();

        Integer aliSize = (Integer) deserializeData(
            RestContext.response.responseBody.toString()
        )
        .get('updatedAssignmentLineItemsSize');

        System.assertEquals(
            aliSize, [
                SELECT COUNT()
                FROM AssignmentLineItem__c
                WHERE Parent__c = :qlis.get(0).Id
                AND Child__c = :qlis.get(1).Id
                AND AreaCode__c = :areaCodes.get(0).Id
            ],
            'Incorrect Assignment Line Item was updated'
        );
    }

    @isTest
    private static void testDeleteAssignmentLineItem() {

        Test.startTest();

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        List<Area_Codes__c> areaCodes = new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery();

        List<Quote> quotes = new QuoteSelector()
            .selectQuotes()
            .executeQuery();

        AssignmentLineItemService.RequestParams params = prepareRequestParams(
            'deleteAssignmentLineItem',
            qlis,
            areaCodes,
            '2',
            quotes.get(0).Id
        );
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        AssignmentLineItemService.handleRequest();

        Test.stopTest();

        System.assertEquals(
            0, [
                SELECT COUNT()
                FROM AssignmentLineItem__c
                WHERE Parent__c = :qlis.get(0).Id
                AND Child__c = :qlis.get(1).Id
                AND AreaCode__c = :areaCodes.get(0).Id
            ],
            'Incorrect Assignment Line Item was updated'
        );
    }

    @isTest
    private static void testSyncAssignmentLineItems() {

        Test.startTest();

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        List<Area_Codes__c> areaCodes = new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery();

        List<Product2> products = new Product2Selector()
            .selectProducts()
            .executeQuery();

        List<Quote> quotes = new QuoteSelector()
            .selectQuotes()
            .executeQuery();

        List<AssignmentLineItem__c> alis = new AssignmentLineItemSelector()
            .selectALIForQuote( new List<Object> { quotes.get(0).Id } )
            .executeQuery();

        BillingWrappers.AreaCodeData acData = new BillingWrappers.AreaCodeData();
        acData.country = 'USA';
        acData.areaCode = 321;

        List<BillingWrappers.AssignmentLineItem> aliWrappers = new List<BillingWrappers.AssignmentLineItem>();

        for (Integer i = 0; i < alis.size(); i++) {
            BillingWrappers.AssignmentLineItem aliWrapper = new BillingWrappers.AssignmentLineItem();
            AssignmentLineItem__c ali = alis.get(i);
            aliWrapper.childId = products.get(0).ExtID__c;
            aliWrapper.parentId = products.get(0).ExtID__c;
            aliWrapper.areaCodeId = ali.AreaCode__c;
            aliWrapper.quantity = ali.Quantity__c;
            aliWrapper.areaCodeInfo = acData;
            aliWrappers.add(aliWrapper);
        }

        AssignmentLineItemService.RequestParams params = prepareRequestParams(
            'syncAssignmentLineItems',
            qlis,
            areaCodes,
            '2',
            quotes.get(0).Id
        );
        params.alis = aliWrappers;
        params.quoteId = quotes.get(0).Id;
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        AssignmentLineItemService.handleRequest();

        Test.stopTest();

        System.assertEquals(
            0, [
                SELECT COUNT()
                FROM AssignmentLineItem__c
                WHERE Quantity__c = 5
            ],
            'Incorrect Assignment Line Item was deleted'
        );

        System.assertEquals(
            6, [
                SELECT COUNT()
                FROM AssignmentLineItem__c
                WHERE Quantity__c = 2
            ],
            'Incorrect Assignment Line Item was updated'
        );
    }

    @isTest
    private static void testIncorrectParams() {

        Test.startTest();

        AssignmentLineItemService.RequestParams params = new AssignmentLineItemService.RequestParams();
        params.action = 'error';
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        AssignmentLineItemService.handleRequest();

        Test.stopTest();

        System.assert(
            RestContext.response.responseBody.toString().contains('error'),
            'Incorrect error handling on Response'
        );
    }

    @isTest
    private static void testErrorResponse() {

        Map<String, String> resp = null;

        Test.startTest();

        try {
            throw new AquivaHelper.AquivaException(EXCEPTION_MESSAGE);
        } catch (AquivaHelper.AquivaException ex) {
            resp = AssignmentLineItemService.getErrorResponse(ex);
        }

        Test.stopTest();

        System.assert(
            resp.get('error').contains(EXCEPTION_MESSAGE),
            'Failed Response handled incorrectly'
        );
    }

    @isTest
    private static void testQueryAssignmentLineItemsByAllParams() {

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        List<Area_Codes__c> areaCodes = new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery();

        Test.startTest();

        Integer aliSize = ((List<AssignmentLineItem__c>) AssignmentLineItemService.queryAssignmentLineItems(
            String.valueOf(qlis.get(0).Id),
            String.valueOf(qlis.get(1).Id),
            String.valueOf(areaCodes.get(0).Id)
        )).size();

        Test.stopTest();

        System.assertEquals(
            aliSize,
            0,
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    @isTest
    private static void testQueryAssignmentLineItemsByQLIs() {

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        Test.startTest();

        Integer aliSize = ((List<AssignmentLineItem__c>) AssignmentLineItemService.queryAssignmentLineItems(
            String.valueOf(qlis.get(0).Id),
            String.valueOf(qlis.get(1).Id),
            null
        )).size();

        Test.stopTest();

        System.assertEquals(
            aliSize,
            0,
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    @isTest
    private static void testQueryAssignmentLineItemsByParent() {

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        Test.startTest();

        Integer aliSize = ((List<AssignmentLineItem__c>) AssignmentLineItemService.queryAssignmentLineItems(
            String.valueOf(qlis.get(0).Id),
            null,
            null
        )).size();

        Test.stopTest();

        System.assertEquals(
            aliSize,
            3,
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    @isTest
    private static void testQueryAssignmentLineItemsByChild() {

        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        Test.startTest();

        Integer aliSize = ((List<AssignmentLineItem__c>) AssignmentLineItemService.queryAssignmentLineItems(
            null,
            String.valueOf(qlis.get(1).Id),
            null
        )).size();

        Test.stopTest();

        System.assertEquals(
            aliSize,
            3,
            'Incorrect Assignment Line Item was retrieved'
        );
    }

    @isTest
    private static void testDeleteCustomAdressesAssignments() {

        QuoteLineItem qli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery()
            .get(0);

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => ValueProviderBuilder.provideList(new List<String> {'10 Avenue Jean Médecin'}),
                CustomAddress__c.City__c => ValueProviderBuilder.provideList(new List<String> {'Nice'}),
                CustomAddress__c.Country__c => ValueProviderBuilder.provideList(new List<String> {'France'}),
                CustomAddress__c.State__c => ValueProviderBuilder.provideList(new List<String> {'Nice'}),
                CustomAddress__c.PostalCode__c => ValueProviderBuilder.provideList(new List<String> {'06000'})
            })
            .create()
            .getRecord();

        List<CustomAddressAssignments__c> caa = (List<CustomAddressAssignments__c>) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.AttentionTo__c => ValueProviderBuilder.provideList(new List<String> {'Test France 1', 'Test France 2'}),
                CustomAddressAssignments__c.CustomAddress__c => ValueProviderBuilder.provideList(new List<Id> {ca.Id}),
                CustomAddressAssignments__c.Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {2, 4}),
                CustomAddressAssignments__c.QuoteLineItem__c => ValueProviderBuilder.provideList(new List<Id> {qli.Id}),
                CustomAddressAssignments__c.Type__c => 'Ground',
                CustomAddressAssignments__c.ShippingLicenseTree__c => 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80'})
            .quantity(2)
            .create()
            .getRecords();

        List<AssignmentLineItem__c> assignments = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
            .selectALIForQLI(new List<Object> { new List<Id>{ qli.Id } })
            .executeQuery();

        Test.startTest();
            AssignmentLineItemService.deleteCustomAdressesAssignments(assignments, new List<AssignmentLineItem__c>());
        Test.stopTest();
        
        List<CustomAddressAssignments__c> customAddressAssignments = new CustomAddressAssignmentsSelector()
            .selectCustomAddressAssignments()
            .selectFields(new List<String>{ 'Id' })
            .executeQuery();

        System.assertEquals(0, customAddressAssignments.size(), 'Custom address assignments should be deleted');
    }
}