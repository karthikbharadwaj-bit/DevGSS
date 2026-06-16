@isTest

public class Test_OpptyTrigger {

    private static Account testAccount;
    private static Contact testContact;
    private static Opportunity testOpportunity;
    private static User testUser;
    private static User testUser2;
    private static User testManager;
    private static Profile prof;
    private final static String TEST_COMMENT = 'This is test comment string';
    private final static String SYSTEM_ADMINISTRATOR = 'System Administrator';
    private final static String TEST_STRING = 'TestString';
    private final static String TEST_PACKAGE = '{"id":"1","version":"5","duration":"Monthly","categoryCode":"ATN","discount":{"type":"Percent","value":"3.48"},"price":"40"}';
    private final static String NEW_BUSINESS = 'New Business';

    private static final String FAKE_PRIVATE_KEY = 'MIIEowIBAAKCAQEA7FBikJgR5gXkwHOvAhptmhmOTiQL+VWxNSOJrPlvCCubEk5Nm6JQv1YAoIDfASXO3JYXNPjsAlb4J+XnitsRNwNVZTBJT1DvQysBVUHfVDXPRiTzHklK7OWYdu+eRnxYdvHBVAd7eKEjNvmG6kRjUDP4d393REzu9PSJEGJlDO0i2ZIxiOMswCDmux5H2d4ahXl1jsTyI8J2sVE6g2nI6nduZuIJK1GsxAWmmjezK4j1vMTx4+2UaF6uuwTwzJ56e7/ECQCJDJENzp6Fm3UhqYY12AqW+AE81bbw6lJ3wIoKRT0ZQGnXuOrYypgRUtnrSgZ2RBtVBa43tWZmpScoXwIDAQABAoIBADpVtZ8gCvsPZWKkrAUG5RtvR5O+jj4kizQk662JfYE00nj4X2wV63zwDAOTDHnKDYCihGQNNqV1NpkSxc+fOGauKfxqqQ4tWoLoMNINCsZM6jfUkzdcvGQyYSqrCBU6SNRD5YeKuU4T6Q9/FXDrJOD9k05cZuKzYyGQ4+zpfSxtO++l3lIzrBVeVreBQMZ+p7WA+2gEvz6cxSOFL0mglAfiPIAHTM/zTXYeLweeeWvZSh7V9Y+MTbUP3INPaLWGQB/qDM3+s5L8Ztj1rtYOnWSUXruqQELXu/Jc4z59IUzym4MvdRurg+5+U2NatiNd5QNPA11ry7GEDe1HV1jzvbECgYEA/+ciRd56DJiK75VZOHl3icjd6pOTnPEJD09E/eilrFUyc8hAZhFJV32H6wzOkpOAqkrs7GAaIJwnezxDPmwkYRemH6LlLnNdDFpN/lmcH8DuGqN3GdaXm9WCarztB2CBMiWn5QLSA62+AvnuW9EbkWNufeCkL0Zf5nyHTuKwDR0CgYEA7GdZAgolTLLMXekqG4Bv9ipyUqnrHiQSLiCYRBeehPNavyYmo9dpcC9s6M/hDnRanIZRm0fa9vTr8vpoAZvFHDyZzgv7PPMFM3fZyeFUibj3wdTDJtdLE4BdtExXjIJHb8B3KmFYaYRBiOpsOaK4XRwcHw4wBFaGDt31ZQoJHqsCgYAQ0EzuLknyneszBqsQDNsP0ITULtIaE7Q2r0ynKiwIgKiJ9vRUQHqDJxpRFUxVUR+5EKc0eLP+xIPLkxAP/+b8AiPGHFvWi3nnn99UAOtDItgCJA9lQTZA5OxmuvcP7wVOGC9J2r+Vwkqjw2wn2DtpeBEAcEwZVxRh/niddEOA+QKBgFrK7mJcJysn2FmQ/T0GvPlcIAAjhktTKzBQEGrGb3k8RXP4YQq35qTRchCQFi2I/mvzIlBy7mO+eQgep+dGPhO0KpX6AAnOhAbaVui0A9XJFk55OmImeY0J1fMzBsTOHEWNM7cxH9WWl9zPu7T/C7Om4h4DQunHmUEIegDOM+Z1AoGBAL+U92I27aHif9PS2ZTwZnG5aMDocA0282vUJHPUQY1KThdwRVoFWiVPJhPJcmEpYdimARSpV5rrrzQBUEGKx6Z3OL2ptzz7WmPgOh839SR7CXcZ8Hqcu6h94pYoSDH4b/iNfniRJuABmbstoTCNK9QciDDeCq8wIes6mocheXtU====';

    @testSetup static void setup(){

        Triggers.switchOff();
        Profile testProfile = [ SELECT Id
                                FROM Profile
                                WHERE Name = 'Channel Sales - Lightning' LIMIT 1];

        User testSetupUser = new User(IsTmtTriggersDisabled__c = false,
                                        Phone = '+18885550505',
                                        IsActive = true,
                                        Mkto_Reply_Email__c = 'testSetup@opptyTriggerSetup.com',
                                        FirstName = 'TestSetup',
                                        Lastname = 'TestSetup',
                                        Email = 'testSetup@opptyTriggerSetup.com',
                                        ProfileId = testProfile.Id,
                                        Username = 'testSetup@opptyTriggerSetup.com',
                                        Alias = 'ssal',
                                        TimeZoneSidKey = 'America/Los_Angeles',
                                        LocaleSidKey = 'en_US',
                                        EmailEncodingKey = 'ISO-8859-1',
                                        LanguageLocaleKey = 'en_US');

        User testSetupManager = new User(IsTmtTriggersDisabled__c = false,
                                        Phone = '+18885550505',
                                        IsActive = true,
                                        Mkto_Reply_Email__c = 'manager@test.com',
                                        FirstName = 'manager',
                                        Lastname = 'managerson',
                                        Email = 'manager@test.com',
                                        ProfileId = testProfile.Id,
                                        Username = 'manager+1@optytriggertest.com',
                                        Alias = 'sman',
                                        TimeZoneSidKey = 'America/Los_Angeles',
                                        LocaleSidKey = 'en_US',
                                        EmailEncodingKey = 'ISO-8859-1',
                                        LanguageLocaleKey = 'en_US');

        insert new List<User>{testSetupUser, testSetupManager};

        Employee__c testSetupEmployee = new Employee__c(
            First_Name__c = 'TestFirst',
            Last_Name__c = 'TestLast',
            Email__c = 'testSetup@opptyTriggerSetup.com',
            Location__c = 'Denver, US',
            Department__c = 'Sales',
            Division__c = 'Sales - SOHO',
            User__c = testSetupUser.Id
        );
        insert testSetupEmployee;

        Account testSetupAccount = new Account(Name = 'Test Account',
                                                Partner_ID__c = 'testIDAcc',
                                                Permitted_Brands__c = 'RingCentral');
        insert testSetupAccount;

        Contact testSetupContact = new Contact(LastName = 'Test Contact',
                                                Preferred_Language__c = 'en_US',
                                                AccountId = testSetupAccount.Id,
                                                Email = 'test@domaintest.com',
                                                Phone = '+18885550505',
                                                CurrencyIsoCode = 'USD');
        insert testSetupContact;

        Opportunity testSetupOpportunity = new Opportunity(Name = 'Test Oppty',
                                                            CurrencyIsoCode = 'USD',
                                                            AccountId = testSetupAccount.Id,
                                                            CloseDate = System.today(),
                                                            StageName = '4. Proof',
                                                            RecordTypeId = OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                                                            Primary_Opportunity_Contact__c = testSetupContact.Id,
                                                            OwnerId = testSetupUser.Id,
                                                            Tier_Name__c = 'Fax1000',
                                                            Brand_Name__c = 'RingCentral',
                                                            Forecasted_Users__c = 23);
        insert testSetupOpportunity;
        Triggers.switchOn();

        Feature_Toggle__c featureToggle = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.sObjectType)
                .setField(Feature_Toggle__c.ProvisioningFlow__c, true)
                .setField(Feature_Toggle__c.Approval_For_Change_Order_Process__c, true)
                .create()
                .getRecord();

        NGBS_Phoenix_Settings__c phoenixSettings = (NGBS_Phoenix_Settings__c) new SObjectBuilder(NGBS_Phoenix_Settings__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableBrands__c => 'RingCentral;RingCentral Canada;RingCentral AU;RingCentral UK;RingCentral EU; Unify Office;',
                    NGBS_Phoenix_Settings__c.NGBSPhoenixAvailablePackageIDs__c => '666;210;260;220;230;231;240;241;250;251;510;900;901;902',
                    NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableProducts__c => 'RC Meetings;Meetings;'
                })
                .create()
                .getRecord();
    }


    public static void createTestData(Boolean dataSelector){

        testAccount = new Account(Name='Opty test account',
                                    Partner_ID__c='testID',
                                    Permitted_Brands__c='RingCentral');
        insert testAccount;

        testContact = new Contact(LastName='Opty test contact',
                                    Preferred_Language__c='en_US',
                                    AccountId=testAccount.Id,
                                    Email='test@test.com',
                                    Phone='+18885550505',
                                    CurrencyIsoCode='USD');
        insert testContact;

        Set<String> profNames = new Set<String>();
        profNames.add('Quoting Wizard Beta Tester');
        profNames.add('Channel Sales Manager - Lightning');

        prof = [SELECT Id FROM Profile WHERE Name IN :profNames LIMIT 1];

        List<User> users = new List<User>();

        testManager = new User(IsTmtTriggersDisabled__c=false,
                            Phone='+18885550505',
                            IsActive=true,
                            Mkto_Reply_Email__c='manager@test.com',
                            FirstName='manager',
                            Lastname='managerson',
                            Email='manager@test.com',
                            ProfileId=prof.Id,
                            Username='manager@optytriggertest.com',
                            Alias='sman',
                            TimeZoneSidKey='America/Los_Angeles',
                            LocaleSidKey='en_US',
                            EmailEncodingKey='ISO-8859-1',
                            LanguageLocaleKey='en_US');

        insert testManager;

        testUser = new User(IsTmtTriggersDisabled__c=false,
                            ManagerId=testManager.Id,
                            Phone='+18885550505',
                            IsActive=true,
                            Mkto_Reply_Email__c='sales@optytriggertest.com',
                            FirstName='sales',
                            Lastname='salesson',
                            Email='sales@optytriggertest.com',
                            ProfileId=prof.Id,
                            Username='sales@optytriggertest.com',
                            Alias='ssal',
                            TimeZoneSidKey='America/Los_Angeles',
                            LocaleSidKey='en_US',
                            EmailEncodingKey='ISO-8859-1',
                            LanguageLocaleKey='en_US');

        users.add(testUser);

        testUser2 = new User(IsTmtTriggersDisabled__c=false,
                            ManagerId=testManager.Id,
                            Phone='+18885550505',
                            IsActive=true,
                            Mkto_Reply_Email__c='sales2@optytriggertest.com',
                            FirstName='sales2',
                            Lastname='salesson2',
                            Email='sales2@optytriggertest.com',
                            ProfileId=prof.Id,
                            Username='sales2@optytriggertest.com',
                            Alias='ssal2',
                            TimeZoneSidKey='America/Los_Angeles',
                            LocaleSidKey='en_US',
                            EmailEncodingKey='ISO-8859-1',
                            LanguageLocaleKey='en_US');

        users.add(testUser2);

        try{
            insert users;
        }catch(Exception e){}


        List<Employee__c> empls = new List<Employee__c>();
        Employee__c empl;
        for (User usr : users){
            empl = new Employee__c(First_Name__c=usr.FirstName,
                                    Last_Name__c=usr.LastName,
                                    Email__c=usr.Email,
                                    Location__c='San Mateo, US',
                                    Department__c='Sales',
                                    Division__c='Sales - Fax',
                                    Team__c='Sales - Customer Success Manager US',
                                    SPID__c=usr.Alias,
                                    User__c=usr.Id);
            empls.add(empl);
        }

        insert empls;

        testOpportunity = new Opportunity(Name='Test Opportunity',
                                            CurrencyIsoCode='USD',
                                            AccountId=testAccount.Id,
                                            StageName='4. Proof',
                                            RecordTypeId=OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                                            Primary_Opportunity_Contact__c = testContact.Id,
                                            OwnerId=testUser.Id,
                                            Tier_Name__c='Fax1000',
                                            Brand_Name__c='RingCentral',
                                            Forecasted_Users__c=23);
        if (dataSelector) {
            insert testOpportunity;
        }
    }

    @isTest
    private static void testPhoenixConfirmAndCloseIncremental() {

        Id templateId = createTestTemplate('Hello-', '{! Name }!', null);
        Id templateId2 = createTestTemplate('(PhoenixIncrementalEmailTemplate)Hello-', '{! Name }!', null);
        Id templateId3 = createTestTemplate('(PhoenixSimplifiedEmailTemplate)Hello-', '{! Name }!', null);

        List<RC_Quote_Templates__c> testTemplates = (List<RC_Quote_Templates__c>) new SObjectBuilder(RC_Quote_Templates__c.sObjectType)
                .setFields(new Map<SObjectField, Object> {
                    RC_Quote_Templates__c.Name => ValueProviderBuilder.provideList(new List <String> { 'CustomerNotificationOnConfirmAndClose' , 'Phoenix NGBS Incremental Email', 'Phoenix NGBS Change Order Email'}),
                    RC_Quote_Templates__c.TemplateId__c => ValueProviderBuilder.provideList(new List <String> { templateId , templateId2, templateId3})
                })
                .quantity(3)
                .create()
                .getRecords();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
                .setField(Account.Name, 'Test Account')
                .create()
                .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setField(Opportunity.AccountId, testAccount.Id)
                .setField(Opportunity.Name, 'Test Oppty')
                .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_ORDER)
                .setField(Opportunity.Is_Billing_Opportunity__c, true)
                .create()
                .getRecord();

        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.id = '210';
        pInfo.duration = Product2Helper.CHARGE_TERM_MONTHLY;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setField(Quote.Name, 'testQuote')
                .setField(Quote.IsPrimary__c, true)
                .setField(Quote.OpportunityId, testOpportunity.Id)
                .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
                .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
                .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_UPSELL)
                .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfo}))
                .create()
                .getRecord();

        Product2 testProducts = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Product2.Name => ValueProviderBuilder.provideUniqueString(),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.IsActive => true,
                    Product2.Family => Product2Helper.FAMILY_SERVICE
                })
                .create()
                .getRecord();

        Test.startTest();
        PricebookEntry testPriceBooks = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
                .setFields(new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => testProducts.Id,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.Per_Line__c => false,
                    PricebookEntry.Min_Quantity__c => 1,
                    PricebookEntry.Max_Quantity__c => 100
                })
                .create()
                .getRecord();

        Entitlement__c testEntitlements = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Account__c => testAccount.Id,
                    Entitlement__c.Product__c => testProducts.Id,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Price__c => testPriceBooks.UnitPrice,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.Discount__c => 0,
                    Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY
                })
                .create()
                .getRecord();

        QuoteLineItem testQLIs = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
                .setFields(new Map<SObjectField, Object> {
                    QuoteLineItem.Quantity => 3,
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.UnitPrice => testPriceBooks.UnitPrice + 5,
                    QuoteLineItem.Product2Id => testProducts.Id,
                    QuoteLineItem.PricebookEntryId => testPriceBooks.Id,
                    QuoteLineItem.Entitlement__c => testEntitlements.Id,
                    QuoteLineItem.Package_Info_QLI__c => TEST_PACKAGE,
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    QuoteLineItem.DiscountValueNew__c => 0
                })
                .create()
                .getRecord();

        testOpportunity.ConfirmAndClose__c = true;
        update testOpportunity;


        Opportunity testOpty =(Opportunity) new QueryFactory(Opportunity.sObjectType)
                .selectFields(new Set<String>{'Id', 'Uuid__c', 'CustomerConfirmation__c', 'Confirm_And_Close_Quote_Info__c'})
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{ testOpportunity.Id })
                .executeQuery()
                .get(0);

        System.assertNotEquals(null, testOpty.Uuid__c);
        System.assertEquals(OpportunityHelper.PENDING, testOpty.CustomerConfirmation__c);
        System.assertNotEquals(null, testOpty.Confirm_And_Close_Quote_Info__c);
        System.assert(testOpty.Confirm_And_Close_Quote_Info__c.containsIgnoreCase('PhoenixIncrementalEmailTemplate'));
        Test.stopTest();
    }


private static Id createTestTemplate(String content1, String content2, String params ){
        RC_Quote_Template__c testTemplate = new RC_Quote_Template__c(
            Name = 'test',
            Brand__c = 'RingCentral',
            Description__c = 'test123',
            Type__c = 'test',
            Language__c = 'English',
            Parameters__c = params,
            CSS_Styles_1__c = 'body{ font-size: 12pt;}'
        );
        insert testTemplate;

        TemplateSections__c section = new TemplateSections__c(
            Name='Section Name',
            Content_1__c = content1,
            Content_2__c = content2,
            CSS_Styles_1__c = 'body{ font-size: 12pt;}'
        );
        insert section;

        TemplateSectionJunction__c junction = new TemplateSectionJunction__c(
            Position__c =1.00,
            RC_Quote_Template__c = testTemplate.id,
            Template_Section__c = section.id
        );
        insert junction;

        return testTemplate.Id;
    }


}