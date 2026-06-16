@isTest
private class Test_PromotionSelector {
    //Account fields defined
    private static final String ACCOUNT_NAME = 'testAcc';

    //Contact fields defined
    private static final String CONTACT_FIRST_NAME = 'Test1';
    private static final String CONTACT_EMAIL = 'something@mostcommon.fake';
    private static final String CONTACT_PHONE = '1234567890';
    private static final String CONTACT_PREFFERED_LANGUAGE = 'en_US';

    //Product2 fields defined
    private static final String PRODUCT2_NAME = 'Connect Pro - Annual Fee';
    private static final String PRODUCT2_FAMILY = 'RingCentral';

    //Opportunity fields defined
    private static final String OPPORTUNITY_NAME = 'Test Opportunity';
    private static final String OPPORTUNITY_TYPE = 'Syndicated - New';

    //Quote fields defined
    private static final String QUOTE_NAME = 'quoteTest';

    //Promotion fields defined
    private static final String PROMOTION_DISCRIPTION = 'quotetest';
    private static final String PROMOTION_DISCOUNT_TEMPLATES = 'Test Discount Template';
    private static final String PROMOTION_PROMO_CODE = 'Test Promo Code';
    private static final String PROMOTION_PROMO_CODE_ID = 'Promo Code Id';

    //Assert nessages defined
    private static final String ASSERT_MESSAGE = 'Promotions should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong promotion selected';

    @testSetup
    private static void createTestData(){
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME
                }
            )
            .create()
            .getRecord();
        
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_FIRST_NAME,
                    Contact.AccountId => acc.Id,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.Phone => CONTACT_PHONE,
                    Contact.Preferred_Language__c => CONTACT_PREFFERED_LANGUAGE
                }
            )
            .create()
            .getRecord();
        Product2 p2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        Product2.Name => PRODUCT2_NAME,
                        Product2.IsActive => true,
                        Product2.Family => PRODUCT2_FAMILY
                }
            )
            .create()
            .getRecord();
        
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => OPPORTUNITY_NAME,
                    Opportunity.Type => OPPORTUNITY_TYPE,
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
                    Quote.Name => QUOTE_NAME,
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
                    Promotion__c.Description__c => PROMOTION_DISCRIPTION,
                    Promotion__c.Name => oppty.Id,
                    Promotion__c.Start_Date__c => datetime.now(),
                    Promotion__c.End_Date__c => datetime.now().addMonths(1),
                    Promotion__c.Discount_Templates__c => PROMOTION_DISCOUNT_TEMPLATES,
                    Promotion__c.Promo_Code__c => PROMOTION_PROMO_CODE,
                    Promotion__c.Quote__c => q.Id,
                    Promotion__c.Active__c => true,
                    Promotion__c.Promo_Code_Id__c => PROMOTION_PROMO_CODE_ID
                }
            ) 
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectPromotions(){
        List<Promotion__c> promotions = (List<Promotion__c>) new PromotionSelector(true, true)
            .selectPromotions()
            .executeQuery();

        System.assert(promotions.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectPromotionById(){
        List<Promotion__c> promotions = (List<Promotion__c>) new PromotionSelector()
			.selectPromotions()
			.executeQuery();

        List<Promotion__c> promotionById = (List<Promotion__c>) new PromotionSelector()
			.selectPromotionById(promotions[0].Id)
			.executeQuery();

        System.assert(promotionById.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(promotions[0].Id, promotionById[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectPromotionByQuoteId(){
        List<Promotion__c> promotions = (List<Promotion__c>) new PromotionSelector()
			.selectPromotions()
			.executeQuery();

        List<Promotion__c> promotionByQuoteId = (List<Promotion__c>) new PromotionSelector()
            .selectPromotionByQuoteId(new List<Object>{new Set<Id>{promotions[0].Quote__c}})
			.executeQuery();

        System.assert(promotionByQuoteId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(promotions[0].Id, promotionByQuoteId[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAllFieldsForCloning(){
        List<Promotion__c> promotions = (List<Promotion__c>) new PromotionSelector()
			.selectPromotions()
			.executeQuery();

        List<Promotion__c> promotionByQuoteId = (List<Promotion__c>) new PromotionSelector()
            .selectAllFieldsForCloning(new List<Object>{new Set<Id>{promotions[0].Quote__c}})
			.executeQuery();

        System.assert(promotionByQuoteId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(promotions[0].Id, promotionByQuoteId[0].Id, ASSERT_EQUALS_MESSAGE);
    }
}