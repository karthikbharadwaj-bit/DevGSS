@isTest
private class Test_PromotionService {

    @testSetup
    private static void createTestData(){
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Product2 p2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        Product2.Name => 'Connect Pro - Annual Fee',
                        Product2.IsActive => true,
                        Product2.Family => 'RingCentral'
                }
            )
            .create()
            .getRecord();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_PLANNING,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            ) 
            .create()
            .getRecord();
        Promotion__c promo = (Promotion__c) new SObjectBuilder(Promotion__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Promotion__c.Description__c => 'quotetest',
                    Promotion__c.Name => oppty.Id,
                    Promotion__c.Start_Date__c => datetime.now(),
                    Promotion__c.End_Date__c => datetime.now().addMonths(1),
                    Promotion__c.Discount_Templates__c => 'Test Discount Template',
                    Promotion__c.Promo_Code__c => 'Test Promo Code',
                    Promotion__c.Quote__c => q.Id,
                    Promotion__c.Active__c => true,
                    Promotion__c.Promo_Code_Id__c => 'Promo Code Id'
                }
            ) 
            .create()
            .getRecord();
    }

    @isTest
    private static void testGetPromotion() {
        Quote q = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'getQuotePromo';
        params.quoteId = q.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            PromotionService.promotion();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('promotionList'), 'promotionList parameter is expected');

        List<Object> promoList = (List<Object>) data.get('promotionList');
        System.assertEquals(1, promoList.size(), 'Promotion should be queried and returned');
    }

    @isTest
    private static void testDeletePromotions() {
        Promotion__c promo = (Promotion__c) new PromotionSelector()
            .selectPromotions()
            .executeQuery()
            .get(0);

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'deletePromo';

        BillingWrappers.Promotion promoWrapper = new BillingWrappers.Promotion();
        promoWrapper.id = promo.Id;

        params.promotionList = new List<BillingWrappers.Promotion>{promoWrapper};

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            PromotionService.promotion();
        Test.stopTest();

        List<Promotion__c> promoResultList = new PromotionSelector()
            .selectPromotions()
            .executeQuery();

        System.assertEquals(0, promoResultList.size());
    }

    @isTest
    private static void testInsertPromotions() {
        Quote q = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'createPromo';

        BillingWrappers.Promotion promoWrapper = new BillingWrappers.Promotion();
        promoWrapper.promoCodeId = 'promoCodeId';
        promoWrapper.promoCode = 'promoCode';
        promoWrapper.name = 'name';
        promoWrapper.discountTemplates = 'discountTemplates';
        promoWrapper.description = 'description';
        promoWrapper.quoteId = q.Id;

        params.promotionList = new List<BillingWrappers.Promotion>{promoWrapper};
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            PromotionService.promotion();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('promotionList'), 'promotionList parameter is expected');

        List<Object> promoList = (List<Object>) data.get('promotionList');
        System.assertEquals(1, promoList.size(), '1 Promotion record should be created');
    }
}