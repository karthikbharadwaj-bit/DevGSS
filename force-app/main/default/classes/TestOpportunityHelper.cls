@istest
public class TestOpportunityHelper {
    private static final String SANDBOX_NAME = 'box50';
    private static final String USER_NAME = 'asuser@aquivalabs.com';
    private static final String PACKAGE_INFO_ENGAGE =
        '[{"id":"18","version":"1","productName":"Office","productId":"6"}]';
    public static final String PACKAGE_INFO_OFFICE = '[{"id":"18","version":"3","productName":"Office","productId":"2"}]';
    private static final Map<String, String> DEFAULT_ADDRESS = new Map<String, String> {
        'BillingStreet' => 'TestStreet',
        'BillingCity' => 'TestCity',
        'BillingState' => 'TestState',
        'BillingPostalCode' => '12345',
        'BillingCountry' => 'TestCountry'
    };

    @testSetup
    static void generateData() {
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            CatalogPath__c = '/restapi/v1.0/catalog',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
    }

    static Map<String, Id> oppRecordTypeMap = new Map<String, Id>();
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void UnitOpportunityHelper() {
        Test.startTest();
        User pu = getPortalUser(PortalType.PowerPartner, null, true);
        Test.stopTest();
        Account acc = new Account(name = 'test1', Permitted_Brands__c = 'RingCentral', Partner_ID__c = '122sdf001',
                recordTypeId = OpportunityHelper.getOppRecordTypeMap('Partner Account'));
        insert acc ;
        Opportunity opp = new Opportunity(
            Parent_Order__c = null,name = 'test2', AccountId = acc.id, Sales_Model__c = 'direct', Type = 'New Business', StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON, CloseDate = System.today());
        insert opp;


        Contact objcon = new Contact();
        objcon.FirstName = 'test';
        objcon.LastName = 'testl';
        objcon.Contact_Status__c = '3.Working Opp';
        objcon.AccountId = acc.id;
        objcon.Phone = '4098764563';
        objcon.email = 'Test123@simplion.com';
        insert objcon;
        OpportunityContactRole oppContRole = new OpportunityContactRole(opportunityId = opp.Id, ContactId = objcon.Id, IsPrimary = true);
        insert oppContRole;


        List<Opportunity> newoppList = new List<Opportunity>();
        Set<Id> closedOppIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        OpportunityHelper.getOppRecordTypeMap('Sales Oportunity');
        oppRecordTypeMap = null;
        OpportunityHelper.getOppRecordTypeMap('Saves Oportunity');
        OpportunityHelper.isActiveOpp('4. Discovery');
        OpportunityHelper.isClosedOpp('4. Closed');
        OpportunityHelper.getApprovedBrandList(newoppList);
        System.RunAs(pu) {
            OpportunityHelper.getApprovedBrandList(newoppList);
        }
    }

    enum PortalType {
        CSPLiteUser, PowerPartner, PowerCustomerSuccess, CustomerSuccess
    }

    public static User getPortalUser(PortalType portalType, User userWithRole, Boolean doInsert) {
        /* Make sure the running user has a role otherwise an exception
           will be thrown. */
        if (userWithRole == null) {
            if (UserInfo.getUserRoleId() == null) {
                UserRole r = new UserRole(name = 'TEST ROLE');
                Database.insert(r);

                userWithRole = new User(alias = 'hasrole', email = 'userwithrole@roletest2.com', userroleid = r.id,
                        emailencodingkey = 'UTF-8', lastname = 'Testing2', languagelocalekey = 'en_US',
                        localesidkey = 'en_US', profileid = UserInfo.getProfileId(),
                        timezonesidkey = 'America/Los_Angeles', username = 'userwithrole2@testorg.com');
            } else {
                userWithRole = new User(Id = UserInfo.getUserId(), UserRoleId = UserInfo.getUserRoleId());
            }

            System.assert(userWithRole.userRoleId != null,
                    'This test requires the target org to have at least one UserRole created. Please create a user role in this organization and try again.');
        }

        Account a;
        Contact c;
        System.runAs(userWithRole) {
            Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
            Map<string, Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();

            Account accObj2 = new Account();
            accObj2.Name = 'Test Account Parent ';
            accObj2.Partner_ID__c = '12346';
            accObj2.RecordTypeId = rtMapById.get('Partner Account').getRecordTypeID();
            insert accObj2;

            a = new Account();
            a.Name = 'Test Account';
            a.Partner_ID__c = '12348';
            a.ParentId = accObj2.id;
            a.RecordTypeId = rtMapById.get('Partner Account').getRecordTypeID();
            Database.insert(a);

            Account accObj1 = new Account();
            accObj1.Name = 'Test Account Customer';
            accObj1.Partner_ID__c = '12348';
            accObj1.RecordTypeId = rtMapById.get('Customer Account').getRecordTypeID();
            insert accObj1;

            c = new Contact(AccountId = a.id, lastname = 'lastname');
            Database.insert(c);
        }

        /* Get any profile for the given type.*/
        Profile p = [
                select id
                from profile
                where usertype = :portalType.name()
                limit 1
        ];

        String testemail = 'puser001' + String.valueOf(Math.roundToLong(Math.random() * 10000)) + '@amamama.com';
        User pu = new User(profileId = p.id, username = testemail, email = testemail,
                emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                alias = 'cspu', lastname = 'lastname', contactId = c.id);

        if (doInsert) {
            Database.insert(pu);
        }
        return pu;
    }

    private static Id prepareTestData(Id quoteRTId) {

        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(
            Name = 'Test Price Book',
            Description = 'Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Service__c = 'Office',
            Plan__c = 'Monthly'
        );

        insert new List<Pricebook2>{
            testPriceBook1
        };

        // create Account
        Account testAccount = new Account(Name = 'Test account',
                                          BillingStreet = 'TestStreet',
                                          BillingCity = 'TestCity',
                                          BillingState = 'TestState',
                                          BillingPostalCode = '12345',
                                          BillingCountry = 'TestCountry');
        insert testAccount;

        // create Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = '1. Qualify',
            CloseDate = system.today(),
            Parent_Order__c = null,
            AccountId = testAccount.Id
        );
        insert testOpportunity;

        if(quoteRTId == null) {
            quoteRTId = QuoteHelper.RT_ID_PROSERV;
        }

        // Create Quotes
        Quote testQuote = new Quote(
            Name = 'Test ChangeOrder Quote',
            OpportunityId = testOpportunity.id,
            Pricebook2Id = testPriceBook1.id,
            RecordTypeId = quoteRTId,
            Upsell_Status__c = QuoteHelper.STATUS_UPSELL
        );

        if(testQuote != null) {
            insert new List<Quote>{
                testQuote
            };
        }

        // Create Products
        // ProServ
        Product2 testProduct1 = new Product2(
            Name = 'Test Product 1',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        Product2 testProduct2 = new Product2(
            Name = 'Test Product 2',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        insert new List<Product2>{
            testProduct1, testProduct2
        };

        // Create PricebookEntries
        // ProServ
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
            Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct1.Id,
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
            Max_Quantity__c = 100);

        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
            Product2Id = testProduct2.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct2.Id,
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
            Max_Quantity__c = 100);

        insert new List<PricebookEntry>{
            standardPrice1, standardPrice2,
            testPrice1, testPrice2
        };

        // Create Quote Line Items
        // ProServ Quote
        QuoteLineItem testProServQli1 = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = testPrice1.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = testPrice1.UnitPrice,
            Quantity = 5
        );
        QuoteLineItem testProServQli2 = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = testPrice2.Id,
            Product2Id = testProduct2.Id,
            UnitPrice = testPrice2.UnitPrice,
            Quantity = 5
        );

        QuoteTriggerHelper.byPassProServStatusUpdate = true;
        QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = true;
        QuoteLineItemTriggerHelper.byPassQuoteUpdate = true;
        insert new List<QuoteLineItem>{
            testProServQli1, testProServQli2
        };
        QuoteTriggerHelper.byPassProServStatusUpdate = false;
        QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = false;
        QuoteLineItemTriggerHelper.byPassQuoteUpdate = false;

        // Create Phase
        Phase__c testPhase = new Phase__c(
            Name = 'Test',
            Opportunity__c = testOpportunity.Id,
            Quote__c = testQuote.Id
        );
        insert new List<Phase__c>{
            testPhase
        };

        return testOpportunity.Id;
    }

    private static User createUser(String profileName){
        User user = new User(
            Username = USER_NAME + '.' + SANDBOX_NAME,
            LastName = 'testUser',
            Email = 'testUser@gmail.com',
            Alias = 'testUser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id, Name FROM Profile WHERE Name =: profileName].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        return user;
    }

    private static Opportunity getOpp(Id oppId) {
        Opportunity opportunity = [
                SELECT Id, Name, Is_Billing_Opportunity__c, Parent_Order__c, ProvisioningDetails__c, RecordType.Name, Brand_Name__c, BMID__c, OID__c, Partner_ID__c, Enable_Cost_Center_Management__c,
                    AccountId, Account.RC_User_ID__c, Account.Name, Account.Payment_Method__c, Account.Tax_Exempt__c,
                    Account.SignupType__c, Account.Partner_ID__c, Account.Monthly_Credit_Limit__c, Type,
                    Account.Sign_up_Purchase_Limit__c, Account.Payment_Terms__c, Account.Invoice_Terms__c,
                    Account.Active_Sales_Agreement__c, Account.BillingStreet, Account.BillingCity,
                    Account.BillingState, Account.BillingPostalCode, Account.BillingCountry,
                    (SELECT Id, ContactId, Role FROM OpportunityContactRoles)
                FROM Opportunity
                WHERE Id = :oppId
        ];

        return opportunity;
    }

    private static Opportunity getOpp(Id oppId, Account testAcc) {
        Opportunity opportunity = [
                SELECT Id, Name, Is_Billing_Opportunity__c, Parent_Order__c, Brand_Name__c, Type,
                Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry, ProvisioningDetails__c
                FROM Opportunity
                WHERE Id = :oppId
        ];

        Opportunity.Account.BillingStreet = testAcc.BillingStreet;
        Opportunity.Account.BillingCity = testAcc.BillingCity;
        Opportunity.Account.BillingState = testAcc.BillingState;
        Opportunity.Account.BillingPostalCode = testAcc.BillingPostalCode;
        Opportunity.Account.BillingCountry = testAcc.BillingCountry;

        return opportunity;
    }

    // Used to get  quoteList with all fields required
    private static List<Quote> getQuotesList(Id oppId, Boolean isBillingQuote, Boolean isGetPrimary, Boolean isGetProserv, Boolean isGetCcProserv, Boolean isGetCc) {
        List<Quote> quoteList = new List<Quote>();
        List<Quote> quotes = [
            SELECT Id, Name, LastModifiedDate, Approved_Status__c, Upsell_Status__c, CurrencyIsoCode,
                Initial_Term_months__c, InvalidDiscountedPhonesQuantity__c, Invalid_GO_LE_Phones_Quantity__c,
                InvalidGlobalOfficePhonesQuantity__c, InvalidLimitedExtensionPhonesQuantity__c, isPrimary__c,
                QuoteType__c, Special_Terms__c, Status, RecordType.DeveloperName, ProServ_Status__c,
                LastModifiedBy.Name, FaxAreaCode__c, AreaCode__c, Invalid_Number_of_800_Setups__c, Package_Info__c,
                Invalid_Number_of_Int_TF_Setups__c, Invalid_Number_of_Vanity_Setups__c,  RecordTypeId,
                Required_Area_Codes_are_empty__c, LastModifiedBy.Id, Credit_Amount__c, Products__c,
                OpportunityId, Opportunity.Is_Billing_Opportunity__c, Quote_is_Invalid__c, Opportunity.Brand_Name__c,
                AccountId, Account.RC_User_ID__c, Account.RC_Tier_ID__c, Payment_Plan__c,
                Total_Number_of_Digital_Lines__c, ProServSalesRep__c, IsQuoteHasErrors__c,
                Pricebook2.Service__c, Pricebook2.IsActive, Pricebook2.Brand__r.Name, Pricebook2Id,
                Pricebook2.AllowedRecordType__c, Pricebook2.Plan__c, Pricebook2.Edition__c, Pricebook2.Tier_ID__c,
                Brand__c,
                (SELECT Id, Deactivated__c, NewQuantity__c, Quantity, Zero_Quantity__c, PackageInfo__c,
                    Discount_number__c, Discount_type__c, Item_type__c, UnitPrice, EffectivePrice__c,
                    Product2Id, Product2.Name, Product2.Family, Product2.Sub_Category__c, Product2.ExtID__c,
                    Product2.Feature__c, Product2.Charge_Term__c, Entitlement__c, Entitlement__r.Quantity__c,
                    Entitlement__r.DisplayQuantity__c, SalesEndDate__c, Package_Info_QLI__c
                FROM QuoteLineItems
                WHERE isDeleted = false)

            FROM Quote
            WHERE OpportunityId = :oppId
            AND isDeleted = false
            ORDER BY CreatedDate DESC
        ];

        if (isGetPrimary) {
            quoteList.add(QuoteHelper.getPrimaryQuote(quotes, isBillingQuote));
        }
        if(isGetProserv) {
            quoteList.add(QuoteHelper.getProServQuote(quotes, isBillingQuote));
        }
        if(isGetCcProserv) {
            quoteList.add(QuoteHelper.getCCProServQuote(quotes));
        }
        if(isGetCc) {
            quoteList.add(QuoteHelper.getCCQuote(quotes));
        }
        if (!isGetPrimary && !isGetProserv && !isGetCcProserv && !isGetCc) {
            quoteList.addAll(quotes);
        }
        return quoteList;
    }
    // Used to get opportunity with all fields required
    private static Opportunity getOpty(Id oppId) {
        Opportunity opty = [
            SELECT Id, Name, Is_Billing_Opportunity__c, Brand_Name__c, BMID__c, OID__c, Partner_ID__c, Enable_Cost_Center_Management__c, AccountId, Account.RC_User_ID__c, Account.Name,
                Account.Payment_Method__c, Account.Tax_Exempt__c, Account.SignupType__c, Account.Partner_ID__c,
                Account.Monthly_Credit_Limit__c, Account.Sign_up_Purchase_Limit__c, Account.Payment_Terms__c,
                Account.Invoice_Terms__c, (SELECT Id, ContactId, Role FROM OpportunityContactRoles)
            FROM Opportunity
            WHERE Id = :oppId
        ];
        return opty;
    }

    private static List<Phase__c> getPhasesList(List<Quote> quotes) {
        List<Phase__c> phases = [
                SELECT Id, Name, Estimated_Completion_Date__c, Completed_Date__c, Order__c, Quote__c,
                        Initial_Payment__c, CurrencyIsoCode, Status__c, (
                        SELECT Id, Quote_Line_Item__c, Quote_Line_Item__r.Product2.Name, Quantity__c, CurrencyIsoCode,
                                Order_Line_Item__c, Quote_Line_Item__r.Product2.Family, Quote_Line_Item__r.UnitPrice
                        FROM Hardware_Line_Items__r
                )
                FROM Phase__c
                WHERE Quote__c IN :quotes
        ];
        return phases;
    }

    private static List<String> getErrorMessagesHeaders(List<Response.ResponseMessage> toParse) {
        List<String> headers = new List<String>();

        for(Response.ResponseMessage m : toParse) {
            headers.add(m.message);
        }

        return headers;
    }

    private static List<String> getErrorMessagesDetails(List<Response.ResponseMessage> toParse) {
        List<String> headers = new List<String>();

        for(Response.ResponseMessage m : toParse) {
            headers.add(m.messageDetails);
        }

        return headers;
    }

    private static List<String> getErrorMessageURls(List<Response.ResponseMessage> toParse) {
        List<String> urls = new List<String>();

        for(Response.ResponseMessage m : toParse) {
            urls.add(m.url);
        }

        return urls;
    }

    @isTest
    static void isClosed() {
        System.assertEquals(true, OpportunityHelper.isClosed(OpportunityHelper.STAGE_NAME_CLOSED_WON));
        System.assertEquals(true, OpportunityHelper.isClosed(OpportunityHelper.STAGE_NAME_CLOSED_CHURNED));
        System.assertEquals(true, OpportunityHelper.isClosed(OpportunityHelper.STAGE_NAME_CLOSED_SAVED));
        System.assertEquals(true, OpportunityHelper.isClosed(OpportunityHelper.STAGE_NAME_CLOSED_WINBACK));
        System.assertEquals(false, OpportunityHelper.isClosed(OpportunityHelper.STAGE_NAME_DOWNGRADED));
    }

    @isTest
    static void testIsCustomerConfirmationflow() {

        // Test case when no opportunity Id was passed to the method
        Boolean negativeResult = OpportunityHelper.isCustomerConfirmationEmailFlow(null);
        System.assertEquals(false, negativeResult);

        Feature_Toggle__c featureToggle = new Feature_Toggle__c(ModifiedCloseOpportunityFlow__c = true, Restrict_Customer_Confirmation__c = true);
        insert featureToggle;
        RingCentralVariousSettings__c rcVariousSettings = new RingCentralVariousSettings__c(
            Customer_Confirmation_MRR_Threshold__c = 0);
        insert rcVariousSettings;

        // Create PriceBook
        PriceBook2 testPrBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBook2.Name => 'Test Price Book',
                    PriceBook2.Description => 'Test Price Book Products',
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Service__c => 'Office'
                }
            )
            .create()
            .getRecord();

        // Create Opportunity
        Opportunity testOppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.CloseDate => System.today(),
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                }
            )
            .create()
            .getRecord();

        // Create Quote
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.Pricebook2Id => testPrBook.Id,
                    Quote.OpportunityId => testOppty.Id,
                    Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL,
                    Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                }
            )
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.IsActive => true,
                    Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 100,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create();

        PricebookEntry testPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPrBook.Id,
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 15,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        // create quotelineitem to populate Opportunity.Total_MRR__c
        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.Zero_Quantity__c => false,
                    QuoteLineItem.Product2Id => testProduct.Id,
                    QuoteLineItem.UnitPrice => testPbe.UnitPrice,
                    QuoteLineItem.PricebookEntryId => testPbe.Id
                }
            )
            .create()
            .getRecord();

        // Test case when Customer_Confirmation_MRR_Threshold__c is not populated or its value equals to 0
        Boolean positiveResult1 = OpportunityHelper.isCustomerConfirmationEmailFlow(testOppty.Id);
        System.assertEquals(true, positiveResult1);

        /*
        rcVariousSettings.Customer_Confirmation_MRR_Threshold__c = 50;
        update rcVariousSettings;

        // Test case when mrr amount is compared with Customer_Confirmation_MRR_Threshold__c
        Boolean positiveResult2 = OpportunityHelper.isCustomerConfirmationEmailFlow(testOppty.Id);
        System.assertEquals(true, positiveResult2);
        */

    }

    @isTest
    static void test_resetConfirmAndCloseFlag() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(Name = 'Test Oppty',
            AccountId = testAccount.Id,
            StageName = '1. Qualify',
            Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
            ConfirmAndClose__c = true
        );
        insert testOpportunity;

        Quote testPrimaryQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.id,
            Pricebook2Id = Test.getStandardPriceBookId(),
            Upsell_Status__c = QuoteHelper.STATUS_UPSELL,
            Status = QuoteHelper.QUOTE_STATUS_DRAFT,
            isPrimary__c = true,
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            QuoteType__c = QuoteHelper.QUOTE_TYPE_QUOTE
        );
        insert testPrimaryQuote;

        OpportunityHelper.resetConfirmAndCloseFlag(testOpportunity, testPrimaryQuote);

        Opportunity optyToTest = [SELECT id, ConfirmAndClose__c FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals(false, optyToTest.ConfirmAndClose__c);
    }

    private static List<Id> getIds(List<SObject> listSObjects) {
        List<Id> listIds = new List<Id>();

        for(SObject obj: listSObjects) {
            listIds.add(obj.Id);
        }

        return listIds;
    }

    private static Id createTestData() {
        Feature_Toggle__c ft = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.AutogenerateOrders__c => true
            })
            .create()
            .getRecord();

        ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Account_Trigger__c = true, Bypass_Contact_Trigger__c = true);
        insert bpt;

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'ACME, Inc.',
                Account.BillingCountry => 'United States',
                Account.BillingState => 'FL',
                Account.BillingCity => 'City',
                Account.BillingStreet => '100 Foo str',
                Account.BillingPostalCode => '12345'
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Phone => '1234567890',
                Contact.Email => 'jdoe@acme.invalid'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => acc.Name,
                Opportunity.CurrencyISOCode => 'USD',
                Opportunity.Type => 'Existing Business',
                Opportunity.CloseDate => System.today(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_ORDER,
                Opportunity.RecordType.Name => 'New Sales Opportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Professional',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.ConfirmAndClose__c => false
            })
            .create()
            .getRecord();

        OpportunityContactRole acr = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                OpportunityContactRole.OpportunityId => opp.Id,
                OpportunityContactRole.ContactId => cont.Id,
                OpportunityContactRole.IsPrimary => true,
                OpportunityContactRole.Role => 'Signatory'
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .quantity(8)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Primary Quote Product 1',
                    'Primary Quote Product 2',
                    'CC Product 1',
                    'CC Product 2',
                    'ProServ Product 1',
                    'ProServ Product 2',
                    'CC ProServ Product 1',
                    'CC ProServ Product 2'
                }),
                Product2.IsActive => true,
                Product2.Sub_Category__c => ValueProviderBuilder.provideList(new List<String> {
                    Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2Helper.SUBCATEGORY_PROSERV,
                    Product2Helper.SUBCATEGORY_PROSERV,
                    Product2Helper.SUBCATEGORY_CC_PROSERV,
                    Product2Helper.SUBCATEGORY_CC_PROSERV
                }),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL
            })
            .create()
            .getRecords();

        List<PricebookEntry> pbe = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(8)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(getIds(products)),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecords();
        Triggers.switchOff();
        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .quantity(4)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_CC,
                    QuoteHelper.RT_ID_PROSERV,
                    QuoteHelper.RT_ID_CC_PROSERV
                }),
                Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Primary Quote',
                    'Contact Center Quote',
                    'ProServ Quote',
                    'CC ProServ Quote'
                }),
                Quote.isPrimary__c => ValueProviderBuilder.provideList(new List<Boolean> {
                    true,
                    false,
                    false,
                    false
                }),
                Quote.Products__c => ValueProviderBuilder.provideList(new List<String> {
                    'RingCentral',
                    'Contact Center',
                    'Professional Services',
                    'CC Professional Services'
                }),
                Quote.Payment_Plan__c => 'Annual',
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.ProServ_Status__c => ValueProviderBuilder.provideList(new List<String> {
                    QuoteHelper.PROSERVSTATUS_IN_PROGRESS,
                    QuoteHelper.PROSERVSTATUS_IN_PROGRESS,
                    QuoteHelper.PROSERVSTATUS_CANCELLED,
                    QuoteHelper.PROSERVSTATUS_CANCELLED
                })
            })
            .create()
            .getRecords();

        List<QuoteLineItem> qli = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .quantity(pbe.size())
            .setFields(new Map <SObjectField, Object>{
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(new List<Id> {
                    quotes[0].Id,
                    quotes[0].Id,
                    quotes[1].Id,
                    quotes[1].Id,
                    quotes[2].Id,
                    quotes[2].Id,
                    quotes[3].Id,
                    quotes[3].Id
                }),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(getIds(pbe)),
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(getIds(products)),
                QuoteLineItem.UnitPrice => 100,
                QuoteLineItem.Quantity => 1
            })
            .create()
            .getRecords();

        List<Phase__c> phases = (List<Phase__c>) new SObjectBuilder(Phase__c.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Phase__c.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Proserv Phase',
                    'CC Proserv Phase'
                }),
                Phase__c.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                    PhaseHelper.RT_ID_PROSERV_PHASE,
                    PhaseHelper.RT_ID_RINGCENTRAL_HARDWARE_PHASE
                }),
                Phase__c.Estimated_Completion_Date__c => System.today().addDays(60),
                Phase__c.Quote__c => ValueProviderBuilder.provideList(new List<Id> {
                    quotes[2].Id,
                    quotes[3].Id
                }),
                Phase__c.Initial_Payment__c => 200.0,
                Phase__c.CurrencyIsoCode => 'USD',
                Phase__c.Status__c => 'New'
            })
            .create()
            .getRecords();
        Triggers.switchOn();
        return opp.Id;
    }

    @IsTest
    private static void test_validateCloseRequireCCandRCNumbers() {

        Id oppId = createTestData();

        Test.startTest();

        Opportunity opp = (Opportunity) new OpportunitySelector()
                .selectOpportunityForClose(new Set<Id>{oppId})
                .executeQuery()
                .get(0);

        QuoteLineItemSelector selectorQLI = new QuoteLineItemSelector();
        QueryFactory queryQLISubselect = selectorQLI
            .selectQuoteLineItems()
            .selectFields(new List<String> {
                'Id',
                'Deactivated__c',
                'Discount',
                'UnitPrice',
                'NewQuantity__c',
                'Entitlement__c',
                'Entitlement__r.Quantity__c',
                'Entitlement__r.Active__c',
                'Entitlement__r.Price__c',
                'Entitlement__r.EffectivePrice__c',
                'Entitlement__r.DisplayQuantity__c',
                'EffectivePriceNew__c',
                'Entitlement__r.Discount_Type__c',
                'Entitlement__r.Discount__c',
                'Entitlement__r.Product__c',
                'Discount_type__c',
                'Discount_number__c',
                'Quantity_or_Threshold__c',
                'QuoteRecordType__c',
                'Matcher_Fields__c',
                'Zero_Quantity__c',
                'Product_Family__c',
                'PackageInfo__c',
                'Package_Info_QLI__c',
                'Quantity',
                'SalesEndDate__c',
                'Product2Id',
                'Product2.Feature__c',
                'Product2.Product_Type__c',
                'Product2.Matcher_Formula__c',
                'Product2.Charge_Term__c',
                'Product2.Family',
                'Product2.Sub_Category__c',
                'Product2.ExtID__c',
                'Quote.Opportunity.Is_Billing_Opportunity__c'
            })
            .setCondition('isDeleted = false')
            .withoutSelectorOrderByIncluded();

        QuoteSelector selectorQuote = new QuoteSelector();
        List<Quote> quotes = selectorQuote
            .selectQuotes()
            .selectFields(new List<String>{
                'Id',
                'isPrimary__c',
                'Approved_Status__c',
                'LastModifiedDate',
                'RecordTypeId',
                'ProServSalesRep__c',
                'Package_Info__c',
                'AreaCode__c',
                'Enabled_LBO__c',
                'RecordType.DeveloperName',
                'ProServ_Status__c',
                'LastModifiedBy.Id',
                'LastModifiedBy.Name',
                'Upsell_Status__c',
                'PriceBook2.IsActive',
                'OpportunityId',
                'PriceBook2.Service__c',
                'PriceBook2.Tier_ID__c',
                'PriceBook2.AllowedRecordType__c',
                'Account.RC_Tier_ID__c',
                'Total_Number_of_Digital_Lines__c',
                'Products__c',
                'PriceBook2.Plan__c',
                'InvalidDiscountedPhonesQuantity__c',
                'Opportunity.Is_Billing_Opportunity__c',
                'Opportunity.Type',
                'InvalidGlobalOfficePhonesQuantity__c',
                'InvalidLimitedExtensionPhonesQuantity__c',
                'IsQuoteHasErrors__c',
                'Brand__c',
                'Payment_Plan__c',
                'Invalid_GO_LE_Phones_Quantity__c',
                'Quote_is_Invalid__c',
                'QuoteType__c',
                'Status',
                'AccountId',
                'Account.Payment_Method__c',
                'Account.Billing_ID__c',
                'Account.RC_User_ID__c',
                'Account.Active_Sales_Agreement__c',
                'Account.Active_Sales_Agreement__r.Initial_Term_months__c',
                'Account.Active_Sales_Agreement__r.Auto_Renewal__c',
                'Account.Active_Sales_Agreement__r.Term_months__c',
                'Initial_Term_months__c',
                'Auto_Renewal__c',
                'Term_months__c',
                'BusinessIdentity__c',
                'Opportunity.Type',
                'Account.Offer_Type__c',
                'IsMultiProductTechnicalQuote__c'
            })
            .subselect(queryQLISubselect)
            .setCondition('opportunityId = :bind0')
            .setQueryBindings(new List<Object> { oppId })
            .withoutSelectorOrderByIncluded()
            .executeQuery();

        Quote masterQuote = null;
        for(Quote quote : quotes) {
            if (quote.IsPrimary__c == true && quote.IsMultiProductTechnicalQuote__c == false) {
                masterQuote = quote;
            }
        }
        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            NGBSTestDataGenerator.generateQuotePackageInfo(),
            List<BillingWrappers.QuotePackageInfo>.class
        );
        pInfo[0].productName = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
        if(masterQuote != null) {
            masterQuote.Package_Info__c = JSON.serialize(pInfo);
            masterQuote.PSProjectComplexity__c = 'UC-Basic';
            masterQuote.TotalProjectHoursQuoted__c = 1;
            masterQuote.ProServ_Forecasted_Close_Date__c = System.today();
        }

        HardwareLineItemSelector selectorHLI = new HardwareLineItemSelector();
        QueryFactory queryHLISubselect = selectorHLI
            .selectHardwareLineItems()
            .selectFields(new List<String>{
                'Id',
                'CurrencyIsoCode',
                'Order_Line_Item__c',
                'Quote_Line_Item__c',
                'Quantity__c',
                'Quote_Line_Item__r.Product2.Name',
                'Quote_Line_Item__r.Product2.Family',
                'Quote_Line_Item__r.UnitPrice'
            })
            .withoutSelectorOrderByIncluded();

        PhaseSelector selectorPhase = new PhaseSelector();
        List<Phase__c> phases = (List<Phase__c>) selectorPhase
            .selectPhases()
            .selectFields(new List<String>{
                'Id',
                'Name',
                'Estimated_Completion_Date__c',
                'Completed_Date__c',
                'Order__c',
                'Quote__c',
                'Initial_Payment__c',
                'CurrencyIsoCode',
                'Status__c'
            })
            .subselect(queryHLISubselect)
            .setCondition('Quote__c IN :bind0')
            .setQueryBindings(new List<Object>{quotes})
            .withoutSelectFieldsSorted()
            .withoutSelectorOrderByIncluded()
            .executeQuery();

        Response res = OpportunityHelper.validateOpportunityOnClose(
            opp,
            new OpportunityHelper.QuotesWrapper(quotes, opp),
            phases,
            new List<Area_Code_Line_Item__c>(),
            ProfileHelper.PROFILE_NAME_SALES_MANAGER_BUSINESS_PROCESSING,
            TierTypeSetting__c.getall().values(),
            0,
            new Map<Id, Cost_Center_Line_Item__c>(),
            null,
            null,
            new Map<String, List<Approval__c>>(),
            new List<Promotion__c>(),
            null,
            new List<PartnerOperationsLog__c>(),
            null
        );

        Test.stopTest();
        system.assert(true == res.data.get('isCCPhoneNumbersRequired'));
        system.assert(true == res.data.containsKey('RCAccountNumber'));
    }

    @isTest
    private static void testOpportunityInfoConstructor() {
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.BillingStreet => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingCity => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingState => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingCountry => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString('test')
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => false
            })
            .create()
            .getRecord();

        OpportunityHelper.OpportunityInfo oppInfo;
        Test.startTest();
        oppInfo = new OpportunityHelper.OpportunityInfo(opp.Id, 'testName', 'testParentOrder', false);
        Test.stopTest();

        System.assertEquals(
            opp.Id,
            oppInfo.opportunityId,
            'Field opportunityId populated incorrectly'
        );
        System.assertEquals(
            'testName',
            oppInfo.optyName,
            'Field optyName populated incorrectly'
        );
        System.assertEquals(
            'testParentOrder',
            oppInfo.parentOrder,
            'Field parentOrder populated incorrectly'
        );
        System.assert(
            !oppInfo.isSingleOne,
            'Field isSingleOne populated incorrectly'
        );
    }

    @isTest
    private static void testIsActiveOppShouldReturnFalse() {
        Boolean result;
        Test.startTest();
        result = OpportunityHelper.isActiveOpp(null);
        Test.stopTest();
        System.assert(
            !result,
            'Method should return false for blank opportunity stage'
        );
    }

    @isTest
    private static void testIsClosedOppShouldReturnFalse() {
        Boolean result;
        Test.startTest();
        result = OpportunityHelper.isClosedOpp(null);
        Test.stopTest();
        System.assert(
            !result,
            'Method should return false for blank opportunity stage'
        );
    }

    @isTest
    private static void testGetLatestProServDocumentVersion() {
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.Name => 'TestAccountName',
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.BillingStreet => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingCity => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingState => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingCountry => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString('test')
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => billingAcc.Id,
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Phone => '1234567890',
                Contact.Email => 'jdoe@acme.invalid'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => false
            })
            .create()
            .getRecord();

        Product2 productMonthly = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestRental',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_GLOBAL_OFFICE_RENTAL
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
                Quote.Pricebook2Id => pricebook.Id,
                Quote.Initial_Term_months__c => '6'
            })
            .create()
            .getRecord();

        Attachment att = (Attachment) new SObjectBuilder(Attachment.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Attachment.ParentId => opp.Id,
                Attachment.Name => 'ProServ UC Quote null for null 1' + ' - Version ' + '7' + '.pdf',
                Attachment.Body => Blob.valueOf('Test body')
            })
            .create()
            .getRecord();

        Integer result;
        Test.startTest();
        result = OpportunityHelper.getLatestProServDocumentVersion(qt);
        Test.stopTest();

        System.assertEquals(
            7,
            result,
            'Method should return correct value for case with attachments'
        );
    }

    @isTest
    private static void testIsEngageOpptyWithEngage() {

        Opportunity engageOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Tier_Name__c, OpportunityHelper.TIER_ENGAGE_UNIFIED)
            .build()
            .getRecord();

        Test.startTest();

        Boolean isEngage = OpportunityHelper.isEngage(engageOpp);

        Test.stopTest();

        System.assert(
            isEngage,
            'Opportunity should be Engage'
        );
    }

    @isTest
    private static void testIsNewBusinessOpptyType() {
        Opportunity oppNB = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .build()
            .getRecord();

        Test.startTest();
        Boolean isNewBusiness = OpportunityHelper.isNewBusiness(oppNB);
        Test.stopTest();

        System.assert(
            isNewBusiness,
            'Opportunity should have New Business Type'
        );
    }

    @isTest
    private static void testIsEngageOpptyWoEngage() {

        Test.startTest();

        Boolean isEngage = OpportunityHelper.isEngage(new Opportunity());

        Test.stopTest();

        System.assert(
            !isEngage,
            'Opportunity should not be Engage'
        );
    }

    @isTest
    private static void testGenerateEngageCases() {

        Opportunity engageOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.SObjectType),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                Opportunity.isTermination__c => true
            })
            .create()
            .getRecord();

        new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'testLastName')
            .setField(Contact.FirstName, 'testFirstName')
            .setField(Contact.Email, new ValueProvider.UniqueEmailProvider())
            .setField(Contact.AccountId, engageOpp.AccountId)
            .create();

        new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => 'RC_EDS_Acknowledgement',
                    Emails__c.Email_Address__c => new ValueProvider.UniqueEmailProvider(),
                    Emails__c.Description__c => 'test;test'
                }
            )
            .create();

        Test.startTest();

        OpportunityHelper.generateAssistanceCases(new Set<Id> { engageOpp.Id });

        Test.stopTest();

        List<Case> engageCases = (List<Case>) new CaseSelector()
            .selectCases()
            .executeQuery();

        System.assert(
            !engageCases.isEmpty(),
            'Engage Case was not created'
        );

        System.assertEquals(
            1,
            engageCases.size(),
            'Incorrect number of Engage Cases was created'
        );
    }

    @IsTest
    private static void test_validateCloseEngageFlow() {
        /* Check/cover Engage account flow branch */
        Account engageAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Engage Account'
            })
            .create()
            .getRecord();

        Opportunity engageOpportunityNew = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => engageAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Opportunity engageOpportunity = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{engageOpportunityNew.Id})
            .executeQuery()
            .get(0);
        Quote engageQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => engageOpportunity.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => PACKAGE_INFO_ENGAGE
            })
            .create()
            .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            NGBSTestDataGenerator.generateQuotePackageInfo(),
            List<BillingWrappers.QuotePackageInfo>.class
        );
        pInfo[0].productName = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
        Quote engageMasterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => engageOpportunity.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => PACKAGE_INFO_ENGAGE,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.PSProjectComplexity__c => 'REX',
                Quote.TotalProjectHoursQuoted__c => 1,
                Quote.Package_Info__c => JSON.serialize(pInfo)
            })
            .create()
            .getRecord();

        Test.startTest();
            Response res = OpportunityHelper.validateOpportunityOnClose(
                engageOpportunity,
                new OpportunityHelper.QuotesWrapper(new List<Quote>{engageQuote}, engageOpportunity),
                new List<Phase__c>(),
                new List<Area_Code_Line_Item__c>(),
                ProfileHelper.PROFILE_NAME_SALES_MANAGER_BUSINESS_PROCESSING,
                new List<TierTypeSetting__c>(),
                0,
                new Map<Id, Cost_Center_Line_Item__c>(),
                null,
                null,
                new Map<String, List<Approval__c>>(),
                new List<Promotion__c>(),
                null,
                new List<PartnerOperationsLog__c>(),
                null
            );
        Test.stopTest();
        Assert.isTrue(res.messages.size() >= 1,'wrong validation errors amount');
    }

    @isTest
    private static void testIsNotSuitableMasterAccValidationPass() {
        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideList(new List<String>{
                        'Master Account', 'Child Account'
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Account masterAccount = accounts[0];
        Account childAccount = accounts[1];

        Contact customerContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, childAccount.Id)
            .create()
            .getRecord();

        List<AccountContactRole> contactRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        childAccount.Id, masterAccount.Id
                    }),
                    AccountContactRole.ContactId => customerContact.Id,
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => ValueProviderBuilder.provideList(new List<Boolean>{
                        true, false
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
            AccountContactRole childAccountContactRole = (AccountContactRole) new AccountContactRoleSelector()
                .selectAccountContactRoles()
                .selectFields(new List<String>{
                    'AccountId', 'Contact.FirstName', 'Contact.LastName', 'Contact.Email', 'Contact.Phone'
                })
                .setCondition('AccountId = \'' + childAccount.Id + '\'' +  ' AND IsPrimary = true AND Role = \'' +
                    AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY + '\'')
                .executeQuery()
                .get(0);

            Account masterAccountWithContactRoles = (Account) new AccountSelector()
                .selectAccountForOpportunityClose(new List<Object>{new Set<Id> {masterAccount.Id}})
                .executeQuery()
                .get(0);

            Boolean isNotSuitableMasterAccount =
                OpportunityHelper.isNotSuitableMasterAcc(childAccountContactRole, masterAccountWithContactRoles);
        Test.stopTest();

        System.assertEquals(false, isNotSuitableMasterAccount, 'Master Account should pass validation');
    }

    @isTest
    private static void testIsNotSuitableMasterAccWrongContact() {
        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideList(new List<String>{
                        'Master Account', 'Child Account'
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Account masterAccount = accounts[0];
        Account childAccount = accounts[1];

        List<Contact> contacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        masterAccount.Id, childAccount.Id
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Contact masterContact = contacts[0];
        Contact childContact = contacts[1];

        List<AccountContactRole> engageContactRole = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        childAccount.Id, masterAccount.Id
                    }),
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(new List<Id>{
                        childContact.Id, masterContact.Id
                    }),
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => ValueProviderBuilder.provideList(new List<Boolean>{
                        true, true
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
            AccountContactRole childAccountContactRole = (AccountContactRole) new AccountContactRoleSelector()
                .selectAccountContactRoles()
                .selectFields(new List<String>{
                    'AccountId', 'Contact.FirstName', 'Contact.LastName', 'Contact.Email', 'Contact.Phone'
                })
                .setCondition('AccountId = \'' + childAccount.Id + '\'' +  ' AND IsPrimary = true AND Role = \'' +
                    OpportunityHelper.CONTACT_ROLE_SIGNATORY + '\'')
                .executeQuery()
                .get(0);

            Account masterAccountWithContactRoles = (Account) new AccountSelector()
                .selectAccountForOpportunityClose(new List<Object>{new Set<Id> {masterAccount.Id}})
                .executeQuery()
                .get(0);

            Boolean isNotSuitableMasterAccount =
                OpportunityHelper.isNotSuitableMasterAcc(childAccountContactRole, masterAccountWithContactRoles);
        Test.stopTest();

        System.assertEquals(true, isNotSuitableMasterAccount, 'Contact role for master account should point to separate contact');
    }

    @isTest
    private static void testIsNotSuitableMasterAccWithLargeNumOfContactRoles() {
        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .create()
            .getRecords();

        Account masterAccount = accounts[0];
        Account childAccount = accounts[1];

        List<Contact> masterContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, masterAccount.Id)
            .quantity(100)
            .create()
            .getRecords();

        Contact childContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, childAccount.Id)
            .create()
            .getRecord();

        List<AccountContactRole> contactRoles = new List<AccountContactRole>();

        for (Contact contact : masterContacts) {
            AccountContactRole acr = new AccountContactRole();
            acr.AccountId = masterAccount.Id;
            acr.ContactId = contact.Id;
            contactRoles.add(acr);
        }

        List<AccountContactRole> childContactRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        childAccount.Id, masterAccount.Id
                    }),
                    AccountContactRole.ContactId => childContact.Id,
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => ValueProviderBuilder.provideList(new List<Boolean>{
                        true, false
                    })
                }
            )
            .quantity(2)
            .build()
            .getRecords();

        contactRoles.addAll(childContactRoles);

        insert contactRoles;

        Test.startTest();

        Account masterAccountWithContactRoles = (Account) new AccountSelector()
                .selectAccountForOpportunityClose(new List<Object>{new Set<Id> {masterAccount.Id}})
                .executeQuery()
                .get(0);

        AccountContactRole childAccountContactRole = (AccountContactRole) new AccountContactRoleSelector()
                .selectAccountContactRoles()
                .selectFields(new List<String>{
                    'AccountId', 'Contact.FirstName', 'Contact.LastName', 'Contact.Email', 'Contact.Phone'
                })
                .setCondition('AccountId = \'' + childAccount.Id + '\'' +  ' AND IsPrimary = true AND Role = \'' +
                    OpportunityHelper.CONTACT_ROLE_SIGNATORY + '\'')
                .executeQuery()
                .get(0);

        Boolean isNotSuitableMasterAccount =
                OpportunityHelper.isNotSuitableMasterAcc(childAccountContactRole, masterAccountWithContactRoles);

        Test.stopTest();

        System.assertEquals(false, isNotSuitableMasterAccount, 'Master account must be suitable');

    }

    @isTest
    private static void testGetForecastedDigitalUsers() {
        System.assertEquals(
            OpportunityHelper.getForecastedDigitalUsers(OpportunityHelper.TIER_ENGAGE_DIGITAL_LEGACY, 1),
            1,
            'Incorrect number of Forecasted Users on Digital Package'
        );

        System.assertEquals(
            OpportunityHelper.getForecastedDigitalUsers('', 1),
            null,
            'Incorrect number of Forecasted Users without Digital Package'
        );
    }

    @isTest
    private static void testGetForecastedVoiceUsers() {
        System.assertEquals(
            OpportunityHelper.getForecastedVoiceUsers(OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY, 1),
            1,
            'Incorrect number of Forecasted Users on Voice Package'
        );

        System.assertEquals(
            OpportunityHelper.getForecastedVoiceUsers('', 1),
            null,
            'Incorrect number of Forecasted Users without Voice Package'
        );
    }

    @isTest
    private static void testGetForecastedOfficeUsers() {
        System.assertEquals(
            OpportunityHelper.getForecastedOfficeUsers(OpportunityHelper.TIER_OFFICE, 1),
            1,
            'Incorrect number of Forecasted Users on Office Package'
        );

        System.assertEquals(
            OpportunityHelper.getForecastedOfficeUsers(OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY, 1),
            null,
            'Incorrect number of Forecasted Users without Office Package'
        );
    }

    @isTest
    private static void testIsChangeOrderOpportunityNegative() {
        Id oppId = createTestData();

        Test.startTest();

            OpportunitySelector oppSelector = new OpportunitySelector();
            Opportunity opp = (Opportunity) oppSelector
                .selectOpportunities()
                .selectFields(new List<String>{
                    'Id',
                    'Name',
                    'Is_Billing_Opportunity__c',
                    'RecordType.Name',
                    'AccountId',
                    'Account.RC_User_ID__c',
                    'StageName',
                    'Account.BillingStreet',
                    'Account.BillingCity',
                    'Account.BillingState',
                    'Account.BillingPostalCode',
                    'Account.Billing_ID__c',
                    'Account.BillingCountry',
                    'Account.Active_Sales_Agreement__c',
                    'ProvisioningDetails__c',
                    'NumberToBeRCMainNumber__c',
                    'NumberToBeCCNumber__c',
                    'Account.RC_Account_Number__c',
                    'ConfirmAndClose__c',
                    'GoldfingerRetention__c',
                    'Type',
                    'Parent_Order__c',
                    'Brand_Name__c'
                })
                .setCondition('Id = :bind0')
                .setLimit(1)
                .setQueryBindings(new List<Object>{
                    oppId
                })
                .withoutSelectFieldsSorted()
                .withoutSelectorOrderByIncluded()
                .executeQuery()
                .get(0);
            opp.Type = OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL;

            QuoteSelector selectorQuote = new QuoteSelector();
            List<Quote> quotes = selectorQuote
                .selectQuotes()
                .selectFields(new List<String>{
                    'Id',
                    'isPrimary__c',
                    'Approved_Status__c',
                    'LastModifiedDate',
                    'RecordTypeId',
                    'ProServSalesRep__c',
                    'Package_Info__c',
                    'Initial_Term_months__c',
                    'AreaCode__c',
                    'RecordType.DeveloperName',
                    'ProServ_Status__c',
                    'LastModifiedBy.Id',
                    'LastModifiedBy.Name',
                    'Upsell_Status__c',
                    'PriceBook2.IsActive',
                    'OpportunityId',
                    'Products__c',
                    'PriceBook2.Plan__c',
                    'Brand__c',
                    'Payment_Plan__c',
                    'Invalid_GO_LE_Phones_Quantity__c',
                    'Quote_is_Invalid__c',
                    'QuoteType__c',
                    'Status',
                    'AccountId'
                })
                .setCondition('opportunityId = :bind0')
                .setQueryBindings(new List<Object>{
                    oppId
                })
                .withoutSelectorOrderByIncluded()
                .executeQuery();

            Boolean result = false;
            result = OpportunityHelper.isChangeOrderOpportunity(opp, quotes);

        Test.stopTest();

        System.assertEquals(
            false,
            result,
            'Opportunity should not be created under Change Order Flow.'
        );
    }

    @isTest
    private static void testGetRestrictedFeatureList() {
        List<Decimal> featureSet = new List<Decimal>{7,20,29,33,37,43,45,46,51,59};
        Features__c featureSetting = new Features__c();
        featureSetting.Name = 'restrictedFeature';
        featureSetting.FeatureSet__c = '7,20,29,33,37,43,45,46,51,59';
        insert featureSetting;

        List<Decimal> result;
        Test.startTest();
        result = OpportunityHelper.getRestrictedFeatureList();
        Test.stopTest();

        System.assertEquals(
            featureSet,
            result,
            'Feature List should be equal.'
        );
    }

    @isTest
    private static void testFilterQuotesByOppId() {
        Id oppId = createTestData();

        Test.startTest();

        OpportunitySelector oppSelector = new OpportunitySelector();
        Opportunity opp = (Opportunity) oppSelector
            .selectOpportunities()
            .selectFields(new List<String>{
                'Id',
                'Name',
                'Is_Billing_Opportunity__c',
                'RecordType.Name',
                'AccountId',
                'Account.RC_User_ID__c',
                'StageName',
                'Account.BillingStreet',
                'Account.BillingCity',
                'Account.BillingState',
                'Account.BillingPostalCode',
                'Account.Billing_ID__c',
                'Account.BillingCountry',
                'Account.Active_Sales_Agreement__c',
                'ProvisioningDetails__c',
                'NumberToBeRCMainNumber__c',
                'NumberToBeCCNumber__c',
                'Account.RC_Account_Number__c',
                'ConfirmAndClose__c',
                'GoldfingerRetention__c',
                'Type',
                'Parent_Order__c',
                'Brand_Name__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                oppId
            })
            .withoutSelectFieldsSorted()
            .withoutSelectorOrderByIncluded()
            .executeQuery()
            .get(0);
        opp.Type = OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL;

        QuoteSelector selectorQuote = new QuoteSelector();
        List<Quote> quotes = selectorQuote
            .selectQuotes()
            .selectFields(new List<String>{
                'Id',
                'isPrimary__c',
                'Approved_Status__c',
                'LastModifiedDate',
                'RecordTypeId',
                'ProServSalesRep__c',
                'Package_Info__c',
                'Initial_Term_months__c',
                'AreaCode__c',
                'RecordType.DeveloperName',
                'ProServ_Status__c',
                'LastModifiedBy.Id',
                'LastModifiedBy.Name',
                'Upsell_Status__c',
                'PriceBook2.IsActive',
                'OpportunityId',
                'Products__c',
                'PriceBook2.Plan__c',
                'Brand__c',
                'Payment_Plan__c',
                'Invalid_GO_LE_Phones_Quantity__c',
                'Quote_is_Invalid__c',
                'QuoteType__c',
                'Status',
                'AccountId'
            })
            .setCondition('opportunityId = :bind0')
            .setQueryBindings(new List<Object>{
                oppId
            })
            .withoutSelectorOrderByIncluded()
            .executeQuery();

        List<Quote> result;
        result = OpportunityHelper.filterQuotesByOppId(opp.Id, quotes);

        Test.stopTest();

        System.assertEquals(
            quotes,
            result,
            'Feature List should be equal.'
        );
    }

    @isTest
    private static void testFilterQuotesByOppIds() {
        Id oppId = createTestData();

        Test.startTest();

        OpportunitySelector oppSelector = new OpportunitySelector();
        Opportunity opp = (Opportunity) oppSelector
            .selectOpportunities()
            .selectFields(new List<String>{
                'Id',
                'Name',
                'Is_Billing_Opportunity__c',
                'RecordType.Name',
                'AccountId',
                'Account.RC_User_ID__c',
                'StageName',
                'Account.BillingStreet',
                'Account.BillingCity',
                'Account.BillingState',
                'Account.BillingPostalCode',
                'Account.Billing_ID__c',
                'Account.BillingCountry',
                'Account.Active_Sales_Agreement__c',
                'ProvisioningDetails__c',
                'NumberToBeRCMainNumber__c',
                'NumberToBeCCNumber__c',
                'Account.RC_Account_Number__c',
                'ConfirmAndClose__c',
                'GoldfingerRetention__c',
                'Type',
                'Parent_Order__c',
                'Brand_Name__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                oppId
            })
            .withoutSelectFieldsSorted()
            .withoutSelectorOrderByIncluded()
            .executeQuery()
            .get(0);
        opp.Type = OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL;

        QuoteSelector selectorQuote = new QuoteSelector();
        List<Quote> quotes = selectorQuote
            .selectQuotes()
            .selectFields(new List<String>{
                'Id',
                'isPrimary__c',
                'Approved_Status__c',
                'LastModifiedDate',
                'RecordTypeId',
                'ProServSalesRep__c',
                'Package_Info__c',
                'Initial_Term_months__c',
                'AreaCode__c',
                'RecordType.DeveloperName',
                'ProServ_Status__c',
                'LastModifiedBy.Id',
                'LastModifiedBy.Name',
                'Upsell_Status__c',
                'PriceBook2.IsActive',
                'OpportunityId',
                'Products__c',
                'PriceBook2.Plan__c',
                'Brand__c',
                'Payment_Plan__c',
                'Invalid_GO_LE_Phones_Quantity__c',
                'Quote_is_Invalid__c',
                'QuoteType__c',
                'Status',
                'AccountId'
            })
            .setCondition('opportunityId = :bind0')
            .setQueryBindings(new List<Object>{
                oppId
            })
            .withoutSelectorOrderByIncluded()
            .executeQuery();

        Set<Id> oppIds = new Set<Id>{opp.Id};
        Map<Id, List<Quote>> result;
        result = OpportunityHelper.filterQuotesByOppIds(oppIds, quotes);

        Test.stopTest();

        System.assertEquals(
            new Map<Id, List<Quote>> {
                opp.Id => quotes
            },
            result,
            'Feature Map should be equal.'
        );
    }

    @isTest
    private static void testGetOpportunityCloseWizardValues() {
        Id oppId = createTestData();

        OpportunitySelector oppSelector = new OpportunitySelector();
        Opportunity opp = (Opportunity) oppSelector
            .selectOpportunities()
            .selectFields(new List<String>{
                'Id',
                'AccountId'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                oppId
            })
            .withoutSelectFieldsSorted()
            .withoutSelectorOrderByIncluded()
            .executeQuery()
            .get(0);

        Opportunity result;
        Test.startTest();
        result = OpportunityHelper.getOpportunityCloseWizardValues(oppId);
        Test.stopTest();

        System.assertEquals(
            opp.AccountId,
            result.AccountId,
            'Opportunities should be equal.'
        );
    }

    @isTest
    private static void testisRenewalOptyWithoutChangesNegative() {
        Id oppId = createTestData();

        Test.startTest();

            OpportunitySelector oppSelector = new OpportunitySelector();
            Opportunity opp = (Opportunity) oppSelector
                .selectOpportunities()
                .selectFields(new List<String>{
                    'Id',
                    'Name',
                    'Is_Billing_Opportunity__c',
                    'RecordType.Name',
                    'AccountId',
                    'Account.RC_User_ID__c',
                    'StageName',
                    'Account.BillingStreet',
                    'Account.BillingCity',
                    'Account.BillingState',
                    'Account.BillingPostalCode',
                    'Account.Billing_ID__c',
                    'Account.BillingCountry',
                    'Account.Active_Sales_Agreement__c',
                    'ProvisioningDetails__c',
                    'NumberToBeRCMainNumber__c',
                    'NumberToBeCCNumber__c',
                    'Account.RC_Account_Number__c',
                    'ConfirmAndClose__c',
                    'GoldfingerRetention__c',
                    'Type',
                    'Parent_Order__c',
                    'Brand_Name__c'
                })
                .setCondition('Id = :bind0')
                .setLimit(1)
                .setQueryBindings(new List<Object>{
                    oppId
                })
                .withoutSelectFieldsSorted()
                .withoutSelectorOrderByIncluded()
                .executeQuery()
                .get(0);
            opp.Type = OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL;

            QuoteSelector selectorQuote = new QuoteSelector();
            List<Quote> quotes = selectorQuote
                .selectQuotes()
                .selectFields(new List<String>{
                    'Id',
                    'isPrimary__c',
                    'Approved_Status__c',
                    'LastModifiedDate',
                    'RecordTypeId',
                    'ProServSalesRep__c',
                    'Package_Info__c',
                    'Initial_Term_months__c',
                    'AreaCode__c',
                    'RecordType.DeveloperName',
                    'ProServ_Status__c',
                    'LastModifiedBy.Id',
                    'LastModifiedBy.Name',
                    'Upsell_Status__c',
                    'PriceBook2.IsActive',
                    'OpportunityId',
                    'Products__c',
                    'PriceBook2.Plan__c',
                    'Brand__c',
                    'Payment_Plan__c',
                    'Invalid_GO_LE_Phones_Quantity__c',
                    'Quote_is_Invalid__c',
                    'QuoteType__c',
                    'Status',
                    'AccountId'
                })
                .setCondition('opportunityId = :bind0')
                .setQueryBindings(new List<Object>{
                    oppId
                })
                .withoutSelectorOrderByIncluded()
                .executeQuery();

            Boolean result = false;
            result = OpportunityHelper.isRenewalOptyWithoutChanges(opp, quotes);

        Test.stopTest();

        System.assertEquals(false, result, 'Response message should be equal.');
    }

    @isTest
    private static void testCheckPartnerOpportunityPermittedByBrandsNegative() {
        Id oppId = createTestData();

        OpportunitySelector oppSelector = new OpportunitySelector();
        Opportunity opp = (Opportunity) oppSelector
            .selectOpportunities()
            .selectFields(new List<String>{
                'Id',
                'Name',
                'Is_Billing_Opportunity__c',
                'RecordType.Name',
                'AccountId',
                'Account.RC_User_ID__c',
                'StageName',
                'Account.BillingStreet',
                'Account.BillingCity',
                'Account.BillingState',
                'Account.BillingPostalCode',
                'Account.Billing_ID__c',
                'Account.BillingCountry',
                'Account.Active_Sales_Agreement__c',
                'ProvisioningDetails__c',
                'NumberToBeRCMainNumber__c',
                'NumberToBeCCNumber__c',
                'Account.RC_Account_Number__c',
                'ConfirmAndClose__c',
                'GoldfingerRetention__c',
                'Type',
                'Parent_Order__c',
                'Brand_Name__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                oppId
            })
            .withoutSelectFieldsSorted()
            .withoutSelectorOrderByIncluded()
            .executeQuery()
            .get(0);

        List<Opportunity> oppList = new List<Opportunity>{opp};

        Test.startTest();
        OpportunityHelper.checkPartnerOpportunityPermittedByBrand(
            oppList,
            null,
            OpportunityHelper.getApprovedBrandList(oppList)
        );
        Test.stopTest();

        System.assert(opp.Id != null, 'Should not see the error.');
    }

    @isTest
    private static void testIsBTBusinessOpportunityPositive() {
        Id oppId = createTestData();

        OpportunitySelector oppSelector = new OpportunitySelector();
        Opportunity opp = (Opportunity) oppSelector
            .selectOpportunities()
            .selectFields(new List<String>{
                'Id',
                'Name',
                'Is_Billing_Opportunity__c',
                'RecordType.Name',
                'AccountId',
                'Account.RC_User_ID__c',
                'StageName',
                'Account.BillingStreet',
                'Account.BillingCity',
                'Account.BillingState',
                'Account.BillingPostalCode',
                'Account.Billing_ID__c',
                'Account.BillingCountry',
                'Account.Active_Sales_Agreement__c',
                'ProvisioningDetails__c',
                'NumberToBeRCMainNumber__c',
                'NumberToBeCCNumber__c',
                'Account.RC_Account_Number__c',
                'ConfirmAndClose__c',
                'GoldfingerRetention__c',
                'Type',
                'Parent_Order__c',
                'Brand_Name__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                oppId
            })
            .withoutSelectFieldsSorted()
            .withoutSelectorOrderByIncluded()
            .executeQuery()
            .get(0);
        opp.Brand_Name__c = OpportunityHelper.BRAND_BT_BUSINESS;

        Boolean result;
        Test.startTest();
        result = OpportunityHelper.isBTBusinessOpportunity(opp);
        Test.stopTest();

        System.assertEquals(true, result, 'Opp Brand_Name__c should be equal to BT Business.');
    }

    @isTest
    private static void testIsBTContactCenterOpportunityPositive() {
        Id oppId = createTestData();

        OpportunitySelector oppSelector = new OpportunitySelector();
        Opportunity opp = (Opportunity) oppSelector
            .selectOpportunities()
            .selectFields(new List<String>{
                'Id',
                'Name',
                'Is_Billing_Opportunity__c',
                'RecordType.Name',
                'AccountId',
                'Account.RC_User_ID__c',
                'StageName',
                'Account.BillingStreet',
                'Account.BillingCity',
                'Account.BillingState',
                'Account.BillingPostalCode',
                'Account.Billing_ID__c',
                'Account.BillingCountry',
                'Account.Active_Sales_Agreement__c',
                'ProvisioningDetails__c',
                'NumberToBeRCMainNumber__c',
                'NumberToBeCCNumber__c',
                'Account.RC_Account_Number__c',
                'ConfirmAndClose__c',
                'GoldfingerRetention__c',
                'Type',
                'Parent_Order__c',
                'Brand_Name__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                oppId
            })
            .withoutSelectFieldsSorted()
            .withoutSelectorOrderByIncluded()
            .executeQuery()
            .get(0);

        opp.Brand_Name__c = OpportunityHelper.BRAND_BT_BUSINESS;
        opp.Tier_Name__c = OpportunityHelper.TIER_CONTACT_CENTER;

        Boolean result;
        Test.startTest();
        result = OpportunityHelper.isBTContactCenterOpportunity(opp);
        Test.stopTest();

        System.assertEquals(true, result, 'Opp should be equal to BT Contact Center.');
    }


    @isTest
    private static void testIsAvayaPositive() {
        Id oppId = createTestData();

        OpportunitySelector oppSelector = new OpportunitySelector();
        Opportunity opp = (Opportunity) oppSelector
            .selectOpportunities()
            .selectFields(new List<String>{
                'Id',
                'Name',
                'Is_Billing_Opportunity__c',
                'RecordType.Name',
                'AccountId',
                'StageName',
                'Account.BillingStreet',
                'Account.BillingCity',
                'Account.BillingState',
                'Account.BillingPostalCode',
                'Account.Billing_ID__c',
                'Account.BillingCountry',
                'Account.Active_Sales_Agreement__c',
                'ProvisioningDetails__c',
                'NumberToBeRCMainNumber__c',
                'NumberToBeCCNumber__c',
                'Account.RC_Account_Number__c',
                'ConfirmAndClose__c',
                'GoldfingerRetention__c',
                'Type',
                'Parent_Order__c',
                'Brand_Name__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                oppId
            })
            .withoutSelectFieldsSorted()
            .withoutSelectorOrderByIncluded()
            .executeQuery()
            .get(0);
        opp.Brand_Name__c = RingCentralHelper.BRAND_AVAYA;

        Boolean result;
        Test.startTest();
        result = OpportunityHelper.isAvaya(opp);
        Test.stopTest();

        System.assertEquals(true, result, 'Opp should be equal to Avaya.');
    }

    @isTest
    private static void testValidateCloseRequireCCandRCNumbersNotBilling() {
        Id oppId = createTestData();

        Test.startTest();

            Opportunity opp = (Opportunity) new OpportunitySelector()
                .selectOpportunityForClose(new Set<Id>{oppId})
                .executeQuery()
                .get(0);

            opp.Brand_Name__c = OpportunityHelper.BRAND_BT_BUSINESS;
            opp.Is_Billing_Opportunity__c = false;
            QuoteLineItemSelector selectorQLI = new QuoteLineItemSelector();
            QueryFactory queryQLISubselect = selectorQLI
                .selectQuoteLineItems()
                .selectFields(new List<String>{
                    'Id',
                    'Deactivated__c',
                    'Discount',
                    'UnitPrice',
                    'NewQuantity__c',
                    'Entitlement__c',
                    'Entitlement__r.Quantity__c',
                    'Entitlement__r.Active__c',
                    'Entitlement__r.Price__c',
                    'Entitlement__r.EffectivePrice__c',
                    'Entitlement__r.DisplayQuantity__c',
                    'EffectivePriceNew__c',
                    'Entitlement__r.Discount_Type__c',
                    'Entitlement__r.Discount__c',
                    'Entitlement__r.Product__c',
                    'Discount_type__c',
                    'Discount_number__c',
                    'Quantity_or_Threshold__c',
                    'QuoteRecordType__c',
                    'Matcher_Fields__c',
                    'Zero_Quantity__c',
                    'Product_Family__c',
                    'PackageInfo__c',
                    'Package_Info_QLI__c',
                    'Quantity',
                    'SalesEndDate__c',
                    'Product2Id',
                    'Product2.Feature__c',
                    'Product2.Product_Type__c',
                    'Product2.Matcher_Formula__c',
                    'Product2.Charge_Term__c',
                    'Product2.Family',
                    'Product2.Sub_Category__c',
                    'Product2.ExtID__c',
                    'Quote.Opportunity.Is_Billing_Opportunity__c'
                })
                .setCondition('isDeleted = false')
                .withoutSelectorOrderByIncluded();

            QuoteSelector selectorQuote = new QuoteSelector();
            List<Quote> quotes = selectorQuote
                .selectQuotes()
                .selectFields(new List<String>{
                    'Id',
                    'isPrimary__c',
                    'Approved_Status__c',
                    'LastModifiedDate',
                    'RecordTypeId',
                    'ProServSalesRep__c',
                    'Package_Info__c',
                    'Initial_Term_months__c',
                    'AreaCode__c',
                    'RecordType.DeveloperName',
                    'ProServ_Status__c',
                    'LastModifiedBy.Id',
                    'LastModifiedBy.Name',
                    'Upsell_Status__c',
                    'PriceBook2.IsActive',
                    'OpportunityId',
                    'PriceBook2.Service__c',
                    'PriceBook2.Tier_ID__c',
                    'PriceBook2.AllowedRecordType__c',
                    'Account.RC_Tier_ID__c',
                    'Account.RC_Account_Status__c',
                    'Total_Number_of_Digital_Lines__c',
                    'Products__c',
                    'PriceBook2.Plan__c',
                    'InvalidDiscountedPhonesQuantity__c',
                    'Opportunity.Is_Billing_Opportunity__c',
                    'Opportunity.Type',
                    'InvalidGlobalOfficePhonesQuantity__c',
                    'InvalidLimitedExtensionPhonesQuantity__c',
                    'IsQuoteHasErrors__c',
                    'Brand__c',
                    'Payment_Plan__c',
                    'Invalid_GO_LE_Phones_Quantity__c',
                    'Quote_is_Invalid__c',
                    'QuoteType__c',
                    'Status',
                    'AccountId',
                    'Account.Payment_Method__c',
                    'Account.RC_User_ID__c',
                    'Account.Billing_ID__c',
                    'Account.Active_Sales_Agreement__c',
                    'Account.Offer_Type__c',
                    'BusinessIdentity__c',
                    'Opportunity.Type',
                    'IsMultiProductTechnicalQuote__c',
                    'TotalProjectHoursQuoted__c',
                    'PSProjectComplexity__c',
                    'ProServ_Forecasted_Close_Date__c'
                })
                .subselect(queryQLISubselect)
                .setCondition('opportunityId = :bind0')
                .setQueryBindings(new List<Object>{
                    oppId
                })
                .withoutSelectorOrderByIncluded()
                .executeQuery();

            HardwareLineItemSelector selectorHLI = new HardwareLineItemSelector();
            QueryFactory queryHLISubselect = selectorHLI
                .selectHardwareLineItems()
                .selectFields(new List<String>{
                    'Id',
                    'CurrencyIsoCode',
                    'Order_Line_Item__c',
                    'Quote_Line_Item__c',
                    'Quantity__c',
                    'Quote_Line_Item__r.Product2.Name',
                    'Quote_Line_Item__r.Product2.Family',
                    'Quote_Line_Item__r.UnitPrice'
                })
                .withoutSelectorOrderByIncluded();

            PhaseSelector selectorPhase = new PhaseSelector();
            List<Phase__c> phases = (List<Phase__c>) selectorPhase
                .selectPhases()
                .selectFields(new List<String>{
                    'Id',
                    'Name',
                    'Estimated_Completion_Date__c',
                    'Completed_Date__c',
                    'Order__c',
                    'Quote__c',
                    'Initial_Payment__c',
                    'CurrencyIsoCode',
                    'Status__c'
                })
                .subselect(queryHLISubselect)
                .setCondition('Quote__c IN :bind0')
                .setQueryBindings(new List<Object>{
                    quotes
                })
                .withoutSelectFieldsSorted()
                .withoutSelectorOrderByIncluded()
                .executeQuery();

            Feature_Toggle__c featureToggle = new Feature_Toggle__c(ModifiedCloseOpportunityFlow__c = true, Restrict_Customer_Confirmation__c = true);
            insert featureToggle;

            Quote masterQuote = null;
            for(Quote quote : quotes) {
                if (quote.IsPrimary__c == true && quote.IsMultiProductTechnicalQuote__c == false) {
                    masterQuote = quote;
                }
            }
            List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
            );
            pInfo[0].productName = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
            if(masterQuote != null) {
                masterQuote.Package_Info__c = JSON.serialize(pInfo);
                masterQuote.PSProjectComplexity__c = 'UC-Basic';
                masterQuote.TotalProjectHoursQuoted__c = 1;
                masterQuote.ProServ_Forecasted_Close_Date__c = System.today();
            }

            Response res = OpportunityHelper.validateOpportunityOnClose(
                opp,
                new OpportunityHelper.QuotesWrapper(quotes, opp),
                phases,
                new List<Area_Code_Line_Item__c>(),
                ProfileHelper.PROFILE_NAME_SALES_MANAGER_BUSINESS_PROCESSING,
                TierTypeSetting__c.getall().values(),
                0,
                new Map<Id, Cost_Center_Line_Item__c>(),
                null,
                null,
                new Map<String, List<Approval__c>>(),
                new List<Promotion__c>(),
                null,
                new List<PartnerOperationsLog__c>(),
                null
            );
        Test.stopTest();

        system.assertNotEquals(null, res.data.get('closeWizardURL'), 'Should return not empty url.');
    }

    @isTest
    private static void testAttachPdfToOpportunity() {

        Id oppId = createTestData();

        RC_Quote_Template__c rcTemplateObj = new RC_Quote_Template__c();
        rcTemplateObj.Template_Engine__c = TemplateEngine.PDF_ENGINE_2_0;
        insert rcTemplateObj;

        QuoteSelector selectorQuote = new QuoteSelector();
        List<Quote> quotes = selectorQuote
            .selectQuotes()
            .selectFields(new List<String>{
                'Id'
            })
            .setQueryBindings(new List<Object>{
                oppId
            })
            .withoutSelectorOrderByIncluded()
            .executeQuery();

        String attachmentId;
        Test.startTest();
        attachmentId = OpportunityHelper.AttachPdfToOpportunity(
            oppId, quotes[0].Id, rcTemplateObj.Id, null);

        Test.stopTest();

        System.assertNotEquals(
            null,
            attachmentId,
            'Attachment should be created.');
    }

    @isTest
    private static void testIsSingaporeMethod() {

        System.assertEquals(
            false,
            OpportunityHelper.isSingapore(null),
            'method should return false if passed argument is null'
        );

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.CurrencyIsoCode => 'EUR'
            })
            .build()
            .getRecord();

        System.assertEquals(
            false,
            OpportunityHelper.isSingapore(testOpp),
            'method should return true only for Opportunity with "RingCentral EU" Brand and "SGD" currency'
        );


        testOpp.Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL_CA;
        testOpp.CurrencyIsoCode = 'CAD';
        System.assertEquals(
            false,
            OpportunityHelper.isSingapore(testOpp),
            'method should return true only for Opportunity with "RingCentral EU" Brand and "SGD" currency'
        );


        testOpp.Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL_EU;
        testOpp.CurrencyIsoCode = 'SGD';
        System.assertEquals(
            true,
            OpportunityHelper.isSingapore(testOpp),
            'method should return true only for Opportunity with "RingCentral EU" Brand and "SGD" currency'
        );
    }

    @isTest
    private static void testIsIndia() {
        Boolean res;
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'testAcc'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_NAME_INR
                }
            )
            .create()
            .getRecord();


        Test.startTest();
            res = OpportunityHelper.isIndia(testOpp);
        Test.stopTest();

        System.assert(res, 'opportunity should be with RC EU Brand and India Currency (INR)');
    }

    @isTest
    private static void testIsNotIndia() {
        Boolean res;
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'testAcc'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU
                }
            )
            .create()
            .getRecord();


        Test.startTest();
            res = OpportunityHelper.isIndia(testOpp);
        Test.stopTest();

        System.assertEquals(res, false, 'opportunity should be with RC EU Brand, but not with currency INR');
    }

    @isTest
    private static void testIsAmazon() {
        Boolean res;
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'testAcc'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"62005"}'
                }
            )
            .create()
            .getRecord();


        Test.startTest();
        res = OpportunityHelper.isAmazon(testOpp);
        Test.stopTest();

        System.assertEquals(true, res, 'Method must return true for Amazon BI Id');
    }

    @isTest
    private static void testIsNotAmazon() {
        Boolean res;
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'testAcc'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"122"}'
                }
            )
            .create()
            .getRecord();


        Test.startTest();
        res = OpportunityHelper.isAmazon(testOpp);
        Test.stopTest();

        System.assertEquals(false, res, 'Method must return false for not Amazon BI Id');
    }

    @isTest
    private static void testGetBrandOptionsWithFedRamp() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.FirstName => new ValueProvider.UniqueStringProvider('firstName'),
                    User.Email => new ValueProvider.UniqueStringProvider('test@gmail.ru'),
                    User.Username => new ValueProvider.UniqueStringProvider('test@gmail.ru'),
                    User.LanguageLocaleKey => 'en_US',
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN
                }
            )
            .create()
            .getRecord();

        PermissionSet ps = (PermissionSet) new SObjectBuilder(PermissionSet.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PermissionSet.Name => 'TestPermissionSet',
                    PermissionSet.Label => 'Test Permission Set'
                }
            )
            .create()
            .getRecord();

        CustomPermission cp = (CustomPermission) new CustomPermissionSelector()
            .selectCustomPermissionsByDeveloperName(new List<Object> {CustomPermissionHelper.PERMISSION_PROCESS_FEDRAMP_ACCOUNTS})
            .executeQuery()
            .get(0);

        new SObjectBuilder(SetupEntityAccess.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    SetupEntityAccess.ParentId => ps.Id,
                    SetupEntityAccess.SetupEntityId => cp.Id
                }
            )
            .create();

        new SObjectBuilder(PermissionSetAssignment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PermissionSetAssignment.AssigneeId => testUser.Id,
                    PermissionSetAssignment.PermissionSetId => ps.Id
                }
            )
            .create();

        Test.startTest();
            List<Schema.PicklistEntry> brandList = new List<Schema.PicklistEntry>();
            System.runAs(testUser) {
                brandList = OpportunityHelper.getBrandOptions();
            }
        Test.stopTest();

        Boolean isFedRampAvailable = false;
        for (Schema.PicklistEntry entry : brandList) {
            isFedRampAvailable = entry.getValue() == OpportunityHelper.BRAND_RC_FEDRAMP;
            if (isFedRampAvailable) {
                break;
            }
        }
        System.assert(isFedRampAvailable, 'FedRamp brand should be available');
    }

    @IsTest
    private static void testGetBrandOptionsWithoutFedRamp() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => 'TestUserWithoutFedRamp',
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => 'testuserwithoutfedramp@test.com',
                    User.Alias => 'tnofrp',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();
        Test.startTest();
            List<Schema.PicklistEntry> brandList = new List<Schema.PicklistEntry>();
            System.runAs(testUser) {
            brandList = OpportunityHelper.getBrandOptions();
            }
        Test.stopTest();

        Boolean isFedRampAvailable = false;
        for (Schema.PicklistEntry entry : brandList) {
            isFedRampAvailable = entry.getValue() == OpportunityHelper.BRAND_RC_FEDRAMP;
            if (isFedRampAvailable) {
                break;
            }
        }
        System.assertEquals(false, isFedRampAvailable, 'FedRamp brand should not be available');
    }

    @isTest
    private static void testIsSalesOpportunity() {
        Boolean resNewSalesOppty;
        Boolean resSalesOppty;
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'test Account'
            })
            .create()
            .getRecord();

        List<Opportunity> oppList = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                    OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    OpportunityHelper.RT_ID_SALES_OPPORTUNITY
                })
            })
            .create()
            .getRecords();

        Test.startTest();
            resNewSalesOppty = OpportunityHelper.isSalesOpportunity(oppList[0].RecordTypeId);
            resSalesOppty = OpportunityHelper.isSalesOpportunity(oppList[1].RecordTypeId);
        Test.stopTest();
        System.assertEquals(true, resNewSalesOppty, 'Opportunity should be new sales opportunity');
        System.assertEquals(true, resSalesOppty, 'Opportunity should be sales opportunity');
    }

    @isTest
    private static void testIsPartnerOpportunity() {
        Boolean res;
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'test Account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => acc.Id,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_VAR_OPPORTUNITY
            })
            .create()
            .getRecord();

        Test.startTest();
            res = OpportunityHelper.isPartnerOpportunity(opp.RecordTypeId);
        Test.stopTest();
        System.assertEquals(true, res, 'Opportunity should be partner opportunity');
    }

    @isTest
    private static void testIsRcEuBrandNull() {

        System.assertEquals(
                false,
                OpportunityHelper.isRcEuBrand(null),
                'method should return false if passed argument is null'
        );
    }

    @isTest
    private static void testIsRcEuBrandNegative() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_CA
                })
                .build()
                .getRecord();

        System.assertEquals(
                false,
                OpportunityHelper.isRcEuBrand(testOpp),
                'method should return false for Opportunity with non "RingCentral EU" Brand'
        );
    }

    @isTest
    private static void testIsRcEuBrandPositive() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU
                })
                .build()
                .getRecord();

        System.assertEquals(
                true,
                OpportunityHelper.isRcEuBrand(testOpp),
                'method should return true only for Opportunity with "RingCentral EU" Brand'
        );
    }

    @isTest
    private static void testIsRcBrand() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA
                })
                .build()
                .getRecord();

        System.assertEquals(
                false,
                OpportunityHelper.isRcEuBrand(null),
                'method should return "false" value if passed parameter is null'
        );

        System.assertEquals(
                false,
                OpportunityHelper.isRcBrand(testOpp),
                'method should return "false" for Opportunity with non RC Brand'
        );

        testOpp.Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL;
        System.assertEquals(
                true,
                OpportunityHelper.isRcBrand(testOpp),
                'method should return "true" for Opportunity with "RingCentral" Brand'
        );

        testOpp.Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL_EU;
        System.assertEquals(
                true,
                OpportunityHelper.isRcBrand(testOpp),
                'method should return "true" for Opportunity with "RingCentral EU" Brand'
        );

        testOpp.Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL_UK;
        System.assertEquals(
                true,
                OpportunityHelper.isRcBrand(testOpp),
                'method should return "true" for Opportunity with "RingCentral UK" Brand'
        );

        testOpp.Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL_AU;
        System.assertEquals(
                true,
                OpportunityHelper.isRcBrand(testOpp),
                'method should return "true" for Opportunity with "RingCentral AU" Brand'
        );

        testOpp.Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL_CA;
        System.assertEquals(
                true,
                OpportunityHelper.isRcBrand(testOpp),
                'method should return "true" for Opportunity with "RingCentral Canada" Brand'
        );
    }

    private static void testIsAustraliaMethod() {

        System.assertEquals(
            false,
            OpportunityHelper.isAustralia(null),
            'method should return false if passed argument is null'
        );

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_CA,
                Opportunity.CurrencyIsoCode => 'CAD'
            })
            .build()
            .getRecord();

        System.assertEquals(
            false,
            OpportunityHelper.isAustralia(testOpp),
            'method should return true only for Opportunity with "RingCentral AU" Brand and "AUD" currency'
        );


        testOpp.Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL_AU;
        testOpp.CurrencyIsoCode = 'AUD';
        System.assertEquals(
            true,
            OpportunityHelper.isAustralia(testOpp),
            'method should return true only for Opportunity with "RingCentral AU" Brand and "AUD" currency'
        );
    }

    @isTest
    private static void testGetActiveBrands() {
        System.assertEquals(
            new Set<String>(),
            OpportunityHelper.getActiveBrands(),
            'method should return empty Set if custom setting "Docusign_CLM_Brands__c" is not populated'
        );

        new SObjectBuilder(Docusign_CLM_Brands__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Docusign_CLM_Brands__c.Name => ValueProviderBuilder.provideUniqueString('TestSetting_'),
                Docusign_CLM_Brands__c.Enable_DocuSign_CLM_Access__c => ValueProviderBuilder.provideList(
                    new List<Boolean>{ true, false }
                ),
                Docusign_CLM_Brands__c.Brand__c => ValueProviderBuilder.provideList(
                    new List<String>{ 'RingCentral', 'RingCentral EU' }
                )
            })
            .quantity(2)
            .create();

        Set<String> result = OpportunityHelper.getActiveBrands();
        System.assertEquals(
            1,
            result.size(),
            'method should return brands from the custom setting "Docusign_CLM_Brands__c" for which the field ' +
            '"Enable_DocuSign_CLM_Access__c" is true'
        );
        System.assert(
            result.contains('RingCentral'),
            'method should return brands from the custom setting "Docusign_CLM_Brands__c" for which the field ' +
            '"Enable_DocuSign_CLM_Access__c" is true'
        );
    }

    private static void verifyIsBusinessIdentityValidReturnCorrectValue() {
        System.assertEquals(false, OpportunityHelper.isBusinessIdentityValid(null), 'should be invalid');
        System.assertEquals(false, OpportunityHelper.isBusinessIdentityValid(''), 'should be invalid');
        System.assertEquals(false, OpportunityHelper.isBusinessIdentityValid('biId'), 'should be invalid');
        System.assertEquals(false, OpportunityHelper.isBusinessIdentityValid('{"currency":"USD"}'), 'should be invalid');

        System.assertEquals(true, OpportunityHelper.isBusinessIdentityValid('{"currency":"USD","biId":"4"}'), 'should be valid');
        System.assertEquals(true, OpportunityHelper.isBusinessIdentityValid('{"currency":"USD","biId":4}'), 'should be valid');
    }

    @isTest
    private static void testIsTelusOpportunity() {
        System.assertEquals(
            false,
            OpportunityHelper.isTelusOpportunity(null),
            'isTelusOpportunity method should return false if passed argument is null'
        );


        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_TELUS_BUSINESS_CONNECT
            })
            .build()
            .getRecord();

        System.assertEquals(
            true,
            OpportunityHelper.isTelusOpportunity(testOpp),
            'isTelusOpportunity method should return true if Opportunity.Brand_Name__c has ' + OpportunityHelper.BRAND_TELUS_BUSINESS_CONNECT + ' value'
        );


        testOpp.Brand_Name__c = 'test_brand_name';
        System.assertEquals(
            false,
            OpportunityHelper.isTelusOpportunity(testOpp),
            'isTelusOpportunity method should return true if Opportunity.Brand_Name__c has ' +
            'a value other than "' + OpportunityHelper.BRAND_TELUS_BUSINESS_CONNECT + '"'
        );
    }

    @IsTest
    private static void testCreateTechnicalOpportunities() {
        Triggers.switchOff();
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Map<String, BillingWrappers.CartItem[]> items = new Map<String, BillingWrappers.CartItem[]>{
            QuoteHelper.NGBS_OFFICE_PRODUCT => new List<BillingWrappers.CartItem>(),
            QuoteHelper.NGBS_RCCC_PRODUCT => new List<BillingWrappers.CartItem>(),
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => new List<BillingWrappers.CartItem>(),
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => new List<BillingWrappers.CartItem>()
        };
        List<String> serviceNames = new List<String>(items.keySet());
        Map<String, Account> serviceAccountsMap = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);

        Test.startTest();
        Map<String, Opportunity> result = OpportunityHelper.createTechnicalOpportunities(masterOpp, serviceAccountsMap, serviceNames);
        result = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterOpp);
        Test.stopTest();
        Triggers.switchOn();

        System.assertNotEquals(
            0, result.size(),
            'result must not be empty'
        );
        System.assertEquals(
            3, result.size(),
            'must contain 3 entries'
        );
        System.assertNotEquals(
            true, result.containsKey(QuoteHelper.NGBS_OFFICE_PRODUCT),
            'must not create technical opportunity for office service'
        );

        for (String serviceName : result.keySet()) {
            System.assertEquals(
                true, result.containsKey(serviceName),
                String.format(
                    'must create technical opportunity for service {0}',
                    new List<Object>{
                        serviceName
                    }
                )
            );

            Opportunity techOpp = result.get(serviceName);
            System.assertEquals(
                masterOpp.Id, techOpp.MasterOpportunity__c,
                String.format(
                    'technical opportunity for service {0} must be linked to master opportunity {1}',
                    new List<Object>{
                        serviceName, masterOpp.Id
                    }
                )
            );
            System.assertEquals(
                String.format('{0} [system: {1}]', new List<Object> { masterOpp.Name, serviceName }),
                techOpp.Name,
                'correct name'
            );
            System.assertEquals(
                true, techOpp.IsMultiProductTechnicalOpportunity__c,
                String.format(
                    'technical opportunity for service {0} must have technical flag set',
                    new List<Object>{
                        serviceName
                    }
                )
            );
            System.assertNotEquals(
                masterAccount.Id, techOpp.AccountId,
                String.format(
                    'technical opportunity for service {0} must not be linked to master account {1}',
                    new List<Object>{
                        serviceName, masterAccount.Id
                    }
                )
            );
            System.assertEquals(
                OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS, techOpp.Type,
                String.format(
                    'technical opportunity for service {0} must be created as {1}',
                    new List<Object>{
                        serviceName, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
                    }
                )
            );
            System.assertEquals(
                null, techOpp.RC_Account_Status__c,
                String.format(
                    'RC Account Status field of technical opportunity for service {0} must be empty',
                    new List<Object>{
                        serviceName
                    }
                )
            );
        }
    }

    @IsTest
    private static void testCreateTechnicalOpportunities_multipleOpportunities() {
        Triggers.switchOff();
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Opportunity masterOpp1 = TestDataGenerator.createOpportunity(masterAccount);

        Map<String, BillingWrappers.CartItem[]> items = new Map<String, BillingWrappers.CartItem[]> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => new List<BillingWrappers.CartItem>(),
            QuoteHelper.NGBS_RCCC_PRODUCT => new List<BillingWrappers.CartItem>()
        };
        Map<String, BillingWrappers.CartItem[]> items1 = new Map<String, BillingWrappers.CartItem[]> {
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => new List<BillingWrappers.CartItem>(),
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => new List<BillingWrappers.CartItem>()
        };

        List<String> serviceNames = new List<String>(items.keySet());
        List<String> serviceNames1 = new List<String>(items1.keySet());
        Map<String, Account> serviceAccountsMap = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);
        Map<String, Account> serviceAccountsMap1 = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames1);

        Test.startTest();
        Map<String, Opportunity> result = OpportunityHelper.createTechnicalOpportunities(masterOpp, serviceAccountsMap, serviceNames);
        result = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterOpp);
        Map<String, Opportunity> result1 = OpportunityHelper.createTechnicalOpportunities(masterOpp1, serviceAccountsMap1, serviceNames1);
        result1 = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterOpp1);
        Test.stopTest();
        Triggers.switchOn();

        Opportunity ccOpp = result.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Opportunity edOpp = result1.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Opportunity evOpp = result1.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        Account ccAccount = serviceAccountsMap.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Account edAccount = serviceAccountsMap1.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Account evAccount = serviceAccountsMap1.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        System.assertEquals(
            1, result.size(),
            'first batch contains 1 service'
        );
        System.assertEquals(
            2, result1.size(),
            'second batch contains 2 services'
        );
        System.assertEquals(
            null, result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT),
            'no technical opportunity for ed in first batch'
        );
        System.assertEquals(
            null, result.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT),
            'no technical opportunity for ed in first batch'
        );
        System.assertEquals(
            null, result1.get(QuoteHelper.NGBS_RCCC_PRODUCT),
            'no technical opportunity for cc in second batch'
        );
        System.assertEquals(
            masterOpp.Id, ccOpp.MasterOpportunity__c,
            'correct master opportunity id for CC'
        );
        System.assertEquals(
            masterOpp1.Id, edOpp.MasterOpportunity__c,
            'correct master opportunity id for ED'
        );
        System.assertEquals(
            masterOpp1.Id, evOpp.MasterOpportunity__c,
            'correct master opportunity id for EV'
        );
        System.assertEquals(
            ccAccount.Id,  ccOpp.AccountId,
            'correct account for cc opportunity'
        );
        System.assertEquals(
            edAccount.Id, edOpp.AccountId,
            'correct account for ed opportunity'
        );
        System.assertEquals(
            evAccount.Id, evOpp.AccountId,
            'correct account for ev opportunity'
        );
    }

    @IsTest
    static void testCreateTechnicalOpportunities_multipleOpportunities2() {
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Opportunity masterOpp1 = TestDataGenerator.createOpportunity(masterAccount);

        Map<String, BillingWrappers.CartItem[]> items = new Map<String, BillingWrappers.CartItem[]> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => new List<BillingWrappers.CartItem>(),
            QuoteHelper.NGBS_RCCC_PRODUCT => new List<BillingWrappers.CartItem>(),
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => new List<BillingWrappers.CartItem>(),
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => new List<BillingWrappers.CartItem>()
        };
        Map<String, BillingWrappers.CartItem[]> items1 = new Map<String, BillingWrappers.CartItem[]> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => new List<BillingWrappers.CartItem>(),
            QuoteHelper.NGBS_RCCC_PRODUCT => new List<BillingWrappers.CartItem>()
        };

        List<String> serviceNames = new List<String>(items.keySet());
        List<String> serviceNames1 = new List<String>(items1.keySet());
        Map<String, Account> serviceAccountsMap = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);

        System.debug(JSON.serializePretty((List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, serviceAccountsMap.values(), 'Id', true)));
        System.debug(JSON.serializePretty((List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, serviceAccountsMap.values(), 'Id', true)));

        Test.startTest();
        Map<String, Opportunity> result = OpportunityHelper.createTechnicalOpportunities(masterOpp, serviceAccountsMap, serviceNames);
        result = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterOpp);
        Map<String, Opportunity> result1 = OpportunityHelper.createTechnicalOpportunities(masterOpp1, serviceAccountsMap, serviceNames1);
        result1 = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterOpp1);
        Test.stopTest();

        Opportunity ccOpp = result.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Opportunity edOpp = result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Opportunity evOpp = result.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        Opportunity ccOpp1 = result1.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Opportunity edOpp1 = result1.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Opportunity evOpp1 = result1.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        System.assertNotEquals(null, ccOpp, 'cc opportunity 1 is created');
        System.assertNotEquals(null, edOpp, 'ed opportunity 1 is created');
        System.assertNotEquals(null, evOpp, 'ev opportunity 1 is created');
        System.assertNotEquals(null, ccOpp1, 'cc opportunity 2 is created');
        System.assertEquals(null, edOpp1, 'ed opportunity 2 is not created');
        System.assertEquals(null, evOpp1, 'ev opportunity 2 is not created');
    }

    @IsTest
    private static void testUpdateTechnicalOpportunitiesWhenTechnicalQuotesTerminated() {
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Quote masterQuote = TestDataGenerator.createMasterQuote(masterOpp);

        BillingWrappers.QuoteWrapper ccQuoteInfo = new BillingWrappers.QuoteWrapper();
        ccQuoteInfo.isTermination = true;

        BillingWrappers.QuoteWrapper edQuoteInfo = new BillingWrappers.QuoteWrapper();
        edQuoteInfo.isTermination = true;

        BillingWrappers.QuoteWrapper evQuoteInfo = new BillingWrappers.QuoteWrapper();
        evQuoteInfo.isTermination = false;

        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByService = new Map<String, BillingWrappers.QuoteWrapper> {
            QuoteHelper.NGBS_RCCC_PRODUCT => ccQuoteInfo,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => edQuoteInfo,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => evQuoteInfo
        };

        List<String> serviceList = new List<String>(quoteInfoByService.keySet());
        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceList);
        Map<String, Opportunity> serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(masterOpp, serviceAccounts, serviceList);

        Test.startTest();
        OpportunityHelper.updateTechnicalOpportunities(masterOpp.Id, quoteInfoByService);
        Test.stopTest();

        Map<String, Opportunity> updatedTechnicalOpportunities = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterOpp);

        System.assertEquals(
            true, updatedTechnicalOpportunities.get(QuoteHelper.NGBS_RCCC_PRODUCT).isTermination__c,
            'RingCentral Contact Center technical opportunity should be terminated'
        );

        System.assertEquals(
            true, updatedTechnicalOpportunities.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).isTermination__c,
            'Engage Digital Standalone technical opportunity should be terminated'
        );
        System.assertEquals(
            false, updatedTechnicalOpportunities.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).isTermination__c,
            'Engage Voice Standalone technical opportunity should not be terminated'
        );
    }

    @IsTest
    private static void testUpdatePartnerFieldsOnOppty() {
        Triggers.switchOff();
        Account partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields( new Map<SObjectField, Object>{
            Account.Name => 'TestAccount',
            Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
            Account.Credit_Limit__c => 150,
            Account.BusinessIdentity__c => 'RingCentral Ink.',
            Account.Partner_Type__c => 'Atos - Wholesale-Reseller',
            Account.Partner_ID__c => '12345',
            Account.PartnerStatus__c => 'Active'
        })
        .create()
        .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact partnerContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, partnerAccount.Id)
            .create()
            .getRecord();

        AccountContactRole accPartnerRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => partnerAccount.Id,
                AccountContactRole.ContactId => partnerContact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();
        Triggers.switchOn();

        String partnerInfo = '{"id":"' + partnerAccount.id + '","ngbsPartnerId":"14232005"}';
        Test.startTest();
        OpportunityHelper.updatePartnerFieldsOnOppty(opp.id, partnerInfo);
        Test.stopTest();

        opp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String>{
                'Id',
                'Name',
                'Partner_Account__c',
                'Partner_ID__c',
                'Partner_Contact__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                opp.id
            })
            .executeQuery()
            .get(0);

        Assert.areEqual(opp.Partner_Account__c, partnerAccount.Id, 'Incorrect Partner Account');
        Assert.areEqual(opp.Partner_Contact__c, accPartnerRole.ContactId, 'Incorrect Partner Contact');
        Assert.areEqual(opp.Partner_Id__c, partnerAccount.Partner_ID__c, 'Incorrect Partner Id');
    }

    @isTest
    static void testPopulateOpptyToQuotesMapStaticForDuplicateQuotes() {
        IValueProvider oppIdProvider = ValueProviderBuilder.provideDummyId(Opportunity.sObjectType);
        Id oppIdWithoutQuote = (Id) oppIdProvider.getValue();

        Integer oppWithQuoteAmount = 2;
        Set<Id> oppWithQuotesIds = new Set<Id>();
        for (Integer i = 0; i < oppWithQuoteAmount; i++) {
            oppWithQuotesIds.add((Id) oppIdProvider.getValue());
        }

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideParents(oppWithQuotesIds))
            .quantity(oppWithQuoteAmount)
            .build()
            .getRecords();

        Test.startTest();
            OpportunityHelper.populateOpptyToQuotesMapStatic(testQuotes, oppWithQuotesIds);
            Set<Id> allOppIds = new Set<Id>(oppWithQuotesIds);
            allOppIds.add(oppIdWithoutQuote);
            OpportunityHelper.populateOpptyToQuotesMapStatic(testQuotes, allOppIds);
        Test.stopTest();

        Assert.isNotNull(OpportunityHelper.opptyToQuotesMapStatic, 'opptyToQuotesMapStatic must not be null');
        Assert.isFalse(
            OpportunityHelper.opptyToQuotesMapStatic.containsKey(oppIdWithoutQuote),
            'Opportunity with no Quotes must not be in the map'
        );

        for (Id oppId : oppWithQuotesIds) {
            Assert.isTrue(
                OpportunityHelper.opptyToQuotesMapStatic.containsKey(oppId),
                'Opportunity that has Quotes must be present in the map'
            );
            Assert.isTrue(
                OpportunityHelper.opptyToQuotesMapStatic.get(oppId).size() == 1,
                'opptyToQuotesMapStatic has duplicate quotes'
            );
        }
    }

    @isTest
    private static void testIsOpportunityInvalid() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c(DisableUQTLandingPage__c = true);
        insert featureToggle;

        LeadConversionConfiguration__c config = new LeadConversionConfiguration__c(
            Name = 'RingCentral',
            isNGBS__c = true
        );
        insert config;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity validOpp = new Opportunity(
            Name = 'Valid Opportunity',
            AccountId = testAccount.Id,
            Brand_Name__c = 'RingCentral',
            BusinessIdentity__c = '{"currency":"USD","biId":"4"}',
            StageName = OpportunityHelper.STAGE_NAME_QUALIFY
        );
        insert validOpp;

        Opportunity invalidOpp = new Opportunity(
            Name = 'Invalid Opportunity',
            AccountId = testAccount.Id,
            Brand_Name__c = 'RingCentral',
            BusinessIdentity__c = null,
            StageName = OpportunityHelper.STAGE_NAME_QUALIFY
        );
        insert invalidOpp;

        Boolean isValidOppInvalid = OpportunityHelper.isOpportunityInvalid(validOpp);
        System.assertEquals(false, isValidOppInvalid, 'the opp should be valid');

        Boolean isInvalidOppInvalid = OpportunityHelper.isOpportunityInvalid(invalidOpp);
        System.assertEquals(true, isInvalidOppInvalid, 'the opp should be invalid');
    }

    @isTest
    private static void testGetOpportunityBIName() {
        Profile currentUserProfile = (Profile) new ProfileSelector()
            .selectProfileById(new List<Object>{UserInfo.getProfileId()})
            .executeQuery()
            .get(0);

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"4"}'
            })
            .create()
            .getRecord();

        PackageBusinessIdentityMapping__c pbiItem= new PackageBusinessIdentityMapping__c(
            Name = 'test Name',
            Active__c = true,
            BiId__c = '4',
            BiName__c = 'RingCentral Inc.',
            Profile__c = currentUserProfile.Name,
            Currency__c = 'USD'
        );

        Triggers.switchOff();
        insert pbiItem;
        Triggers.switchOn();

        String resultBI = OpportunityHelper.getOpportunityBIName(testOpp);
        System.assertEquals(resultBI, 'RingCentral Inc.', 'Business Identity should be RingCentral Inc.');
    }

    @IsTest
    public static void testSelectCloseWizardWithStageValidation() {
        User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testtestuser',
                    User.Username => 'testuser!user@gmail.com',
                    User.Email => 'testuser@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = :ProfileHelper.PROFILE_NAME_CHANNEL_SALES_MANAGER_LIGHTNING].Id,
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();

        Segment_Master__c segment = (Segment_Master__c) new SobjectBuilder(Segment_Master__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Segment_Master__c.Name => UserHelper.SEGMENT_MID_MARKET,
                Segment_Master__c.Max__c => 399,
                Segment_Master__c.Min__c => 100,
                Segment_Master__c.Country__c => 'United States',
                Segment_Master__c.Start_Date__c => Date.today()
            })
            .create()
            .getRecord();

        System.runAs(testUser) {
            Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Acc 1',
                Account.Segment_Name__c => segment.Id
            })
            .create()
            .getRecord();

            Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name =>'Test Oppty 1',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_PROBLEM,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.Estimated_12M_Total_Pipeline__c => 1600
            })
            .create()
            .getRecord();

            Opportunity opp2 = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id> {opp.Id})
            .executeQuery()
            .get(0);

            Test.startTest();
                String res1 = OpportunityHelper.selectCloseWizard(opp2, null, false, 1, false);
                Assert.isTrue(res1.contains('/apex/DowngradeWizardV2'));
                Assert.isTrue(res1.contains('"Why_We_Won__c"'));

        	    opp2.Why_We_Won__c = 'Brand and Reputation';
        	    opp2.Additional_details_on_why_we_won__c = 'test data';
        	    opp2.Final_Competitor_we_won_against__c = 'Avaya';
        	    opp2.Brand_Name__c = 'Vodafone Business with RingCentral';
        	    update opp2;
        	    String res2 = OpportunityHelper.selectCloseWizard(opp2, null, false, 1, false);
        	    Assert.isTrue(res2.contains('"Why_We_Won__c"'));

        	    opp2.Brand_Name__c = 'Unify Office';
        	    opp2.Partner_ID__c = '129545';
        	    opp2.Why_We_Won__c = '';
        	    update opp2;
        	    String res3 = OpportunityHelper.selectCloseWizard(opp2, null, false, 1, false);
        	    Assert.isFalse(res3.contains('"Why_We_Won__c"'));

                opp2.PartnerProgram__c = 'Channel Harmony';
                update opp2;
                String res4 = OpportunityHelper.selectCloseWizard(opp2, null, false, 1, false);
                Assert.isTrue(res4.contains('"Why_We_Won__c"'));

            Test.stopTest();
        }
    }

    @isTest
    static void testGetOpportunityBi() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'ACME, Inc.',
                Account.BillingCountry => 'United States',
                Account.BillingState => 'FL',
                Account.BillingCity => 'City',
                Account.BillingStreet => '100 Foo str',
                Account.BillingPostalCode => '12345'
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Phone => '1234567890',
                Contact.Email => 'jdoe@acme.invalid'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => acc.Name,
                Opportunity.CurrencyISOCode => 'USD',
                Opportunity.Type => 'Existing Business',
                Opportunity.CloseDate => System.today(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_ORDER,
                Opportunity.RecordType.Name => 'New Sales Opportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Professional',
                Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":4}'
            })
            .create()
            .getRecord();

        Test.startTest();
            String opportunityBi = OpportunityHelper.getOpportunityBi(opp.BusinessIdentity__c);
        Test.stopTest();
        System.assertEquals('4', opportunityBi,'Created Opportunity should have Business Identity = 4');
    }

    @isTest
    private static void testIsRiseBrand() {
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'testAcc'
            })
            .create()
            .getRecord();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RISE_AMERICA
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        Boolean isRise = OpportunityHelper.isRiseBrand(testOpp);
        Test.stopTest();

        System.assertEquals(isRise, true, 'Opportunity should be with Rise America Brand');
    }

    @isTest
    private static void testIsNotRiseBrand() {
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'testAcc'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        Boolean isRise = OpportunityHelper.isRiseBrand(testOpp);
        Test.stopTest();

        System.assertEquals(isRise, false, 'Opportunity should not be with Rise America Brand');
    }

    @isTest
    private static void testIsGSPBrand() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Rise acc'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Brand_Name__c => 'Vodafone Business with RingCentral'
            })
            .create()
            .getRecord();

        Brand_List__c GSPBrandRecord = (Brand_List__c) new SObjectBuilder(Brand_List__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Brand_List__c.Brand_Name__c => 'Vodafone Business with RingCentral',
                Brand_List__c.Name =>  'Vodafone Business with RingCentral',
                Brand_List__c.GSP_Brand__c => true
            })
            .create()
            .getRecord();

        System.assertEquals(true, OpportunityHelper.isGSPBrand(testOpp), 'Opportunity brand must be GSP type');
    }

    @IsTest
    private static void testValidateCloseRiseOpportunity() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Rise acc'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RISE_AMERICA
            })
            .create()
            .getRecord();

        Test.startTest();
            Response res = OpportunityHelper.validateOpportunityOnClose(
                testOpp,
                new OpportunityHelper.QuotesWrapper(new List<Quote>(), testOpp),
                new List<Phase__c>(),
                new List<Area_Code_Line_Item__c>(),
                ProfileHelper.PROFILE_NAME_SALES_MANAGER_BUSINESS_PROCESSING,
                new List<TierTypeSetting__c>(),
                0,
                new Map<Id, Cost_Center_Line_Item__c>(),
                null,
                null,
                new Map<String, List<Approval__c>>(),
                new List<Promotion__c>(),
                null,
                new List<PartnerOperationsLog__c>(),
                null
            );
        Test.stopTest();
        System.assertEquals(1, res.messages.size(), 'wrong validation errors amount');
    }

    @isTest
    private static void testHasIvoiceApproval() {
        Id dummyId = (Id) ValueProviderBuilder.provideDummyId(Opportunity.sObjectType).getValue();
        Test.startTest();
            Boolean hasInvoiceApproval = OpportunityHelper.hasInvoiceApproval(dummyId);
        Test.stopTest();

        System.assertEquals(false, hasInvoiceApproval, 'If there is no invoice approval, the method should return false');
    }

    @isTest
    private static void testIsMasterMultiProductOpportunities() {
        Triggers.switchOff();
        Account testAccOffice = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test'
            })
            .create()
            .getRecord();

        Account testAccEngage = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test',
                Account.Master_Account__c => testAccOffice.Id,
                Account.IsMultiProductTechnicalAccount__c => true
            })
            .create()
            .getRecord();

        Opportunity testOppOffice = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccOffice.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.IsMultiProductTechnicalOpportunity__c => false
            })
            .create()
            .getRecord();

        Opportunity testOppEngage = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccEngage.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.MasterOpportunity__c => testOppOffice.Id,
                Opportunity.IsMultiProductTechnicalOpportunity__c => true
            })
            .create()
            .getRecord();

        Quote masterQuotePrimary = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOppOffice.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => PACKAGE_INFO_OFFICE,
                Quote.isPrimary__c => true,
                Quote.IsMultiProductTechnicalQuote__c => false
            })
            .build()
            .getRecord();

        Quote masterMPLQuoteNonPrimary = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOppOffice.Id,
                Quote.Package_Info__c =>
                    '[{"id":"18","version":"3","productName":"Office","productId":"2"},'
                    + '{"id":"19","version":"3","productName":"Engage Digital Standalone","productId":"7"}]',
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.isPrimary__c => false
            })
            .build()
            .getRecord();

        Quote techMPLQuoteOffice = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOppEngage.Id,
                Quote.Package_Info__c => '[{"id":"18","version":"3","productName":"Office","productId":"2"}]',
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.isPrimary__c => false,
                Quote.MasterQuote__c => masterMPLQuoteNonPrimary.Id
            })
            .build()
            .getRecord();

        Quote techMPLQuoteEngage = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOppEngage.Id,
                Quote.Package_Info__c =>
                    '[{"id":"19","version":"3","productName":"Engage Digital Standalone","productId":"7"}]',
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.isPrimary__c => false,
                Quote.MasterQuote__c => masterMPLQuoteNonPrimary.Id
            })
            .build()
            .getRecord();

        insert new List<Quote> {
            masterQuotePrimary,
            masterMPLQuoteNonPrimary,
            techMPLQuoteOffice,
            techMPLQuoteEngage
        };
        Triggers.switchOn();

        Test.startTest();
            System.assert(!OpportunityHelper.isMasterMultiProductOpportunity(testOppOffice.Id), 'Opportunity should not be multiProduct');
        Test.stopTest();
    }

    @isTest private static void testTrimOpportunityNameIfTooLong(){
        String accAndOppName = '1199SEIU National Benefit Funds for Health and Human Service Employees 123456789012414124';

		Triggers.switchOff();
        Account testAccOffice = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => accAndOppName
            })
            .create()
            .getRecord();

        Account testAccCC = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => accAndOppName,
                Account.Master_Account__c => testAccOffice.Id,
                Account.IsMultiProductTechnicalAccount__c => true
            })
            .create()
            .getRecord();

        Opportunity testOppOffice = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => accAndOppName,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccOffice.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.IsMultiProductTechnicalOpportunity__c => false
            })
            .create()
            .getRecord();

        Opportunity testOppCC = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OpportunityHelper.trimOpportunityNameIfTooLong(testOppOffice.Name, OpportunityHelper.TIER_RC_CONTACT_CENTER),
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccCC.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_RC_CONTACT_CENTER,
                Opportunity.MasterOpportunity__c => testOppOffice.Id,
                Opportunity.IsMultiProductTechnicalOpportunity__c => true
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        String expectedResult = '1199SEIU National Benefit Funds for Health and Human Service Employees 123456789... [system: RingCentral Contact Center]';

        Test.startTest();
            String acutalResult = OpportunityHelper.trimOpportunityNameIfTooLong(accAndOppName, OpportunityHelper.TIER_RC_CONTACT_CENTER);
        Test.stopTest();

        Assert.areEqual(expectedResult, acutalResult, 'Opportunity names must match');
    }

    @IsTest
    private static void testGetPSChangeOrderOpportunityRecord() {
        Triggers.switchOff();
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Acc 1'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name =>'Test Oppty 1',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.CloseDate => Date.today()
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => testAccount.Id,
                Order.OpportunityId => opp.Id,
                Order.Status => OrderHelper.STATUS_NEW,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.EffectiveDate => System.today()
            })
            .create()
            .getRecord();

        opp.Parent_Order__c = testOrder.Id;
        update opp;

        Triggers.switchOn();

        Test.startTest();
            Opportunity actualResult = OpportunityHelper.getPSChangeOrderOpportunityRecord(testOrder.Id);
        Test.stopTest();

        Assert.isNotNull(actualResult, 'Opportunity must not be null');
        Assert.areEqual(opp.Id, actualResult.Id, 'Opportunity Ids must match');
    }

    @isTest
    private static void testGPAValidation() {
        String errorMsg = '';
		User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    User.LastName => 'testchanneluser',
                    User.Username => 'testchanneluser@rc.com',
                    User.Email => 'testchanneluser@rc.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name =: ProfileHelper.PROFILE_NAME_CHANNEL_SALES_MANAGER_LIGHTNING].Id,
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();

        System.runAs(testUser) {
            Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Account.Name => 'testGPAAcc',
                        Account.GPA_Account__c => true
                    }
                )
                .create()
                .getRecord();
            Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Contact.FirstName => 'Test',
                        Contact.LastName => 'GPAContact',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'testgpacontact@test.com',
                        Contact.Phone => '12345678901',
                        Contact.Preferred_Language__c => 'en_US'
                    })
                .create()
                .getRecord();

            Opportunity opp = new Opportunity();
            Test.startTest();
                opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                    .setFields(new Map<SObjectField, Object> {
                            Opportunity.Name => 'Test GPA Validation 1st Oppty',
                            Opportunity.CurrencyIsoCode => 'USD',
                            Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                            Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                            Opportunity.CloseDate => system.today().addMonths(1),
                            Opportunity.AccountId => acc.Id,
                            Opportunity.Primary_Opportunity_Contact__c => con.Id,
                            Opportunity.Brand_Name__c => OpportunityHelper.BRAND_ATTOFFICE,
                            Opportunity.Forecasted_Users__c => 23,
                            Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
                        })
                    .create()
                    .getRecord();

            	Opportunity oppty = [SELECT Id, Name, AccountId, Account.GPA_Account__c, Account.IsMultiProductTechnicalAccount__c, Type FROM Opportunity WHERE Id = :opp.Id];
            	Response result = OpportunityHelper.validateOpportunityOnClose(
                    oppty,
                    null,
                    null,
                    new List<Area_Code_Line_Item__c>(),
                    ProfileHelper.PROFILE_NAME_CHANNEL_SALES_MANAGER_LIGHTNING,
                    null,
                    0,
                    new Map<Id, Cost_Center_Line_Item__c>(),
                    null,
                    null,
                    new Map<String, List<Approval__c>>(),
                    new List<Promotion__c>(),
                    null,
                    new List<PartnerOperationsLog__c>(),
                    null
                );
            	System.debug('result - ' + result);
            	errorMsg = result.messages[0].messageDetails;
            	Assert.areEqual(errorMsg.contains(System.Label.GPA_Contract_Tagging_SIA_Info_and_Campaign_Missing_ErrorMsg),
                    true,
                    'Error in throwing GPA Validation');

            	acc.SIA_Information__c = 'test Info 12345';
            	update acc;

                String result2 = OpportunityHelper.GPOContractValidation(opp);
            	Assert.areEqual(result2, System.Label.GPA_Contract_Tagging_Campaign_Missing_Error_Msg, 'Error in validating GPA Opportunity...!' );

            	Campaign cmp = new Campaign (Name = 'Sales_Purchasing1', isActive=true, Intended_Product__c = 'AU General');
                insert cmp;

            	CampaignInfluenceModel primaryModel = [SELECT Id FROM CampaignInfluenceModel WHERE DeveloperName = 'primaryModel' LIMIT 1];
            	CampaignInfluence cif = new CampaignInfluence (OpportunityId = opp.Id, CampaignId = cmp.Id, ContactId = con.Id, ModelId = primaryModel.Id);
				insert cif;

            	String result3 = OpportunityHelper.GPOContractValidation(opp);
            	Assert.areEqual(result3, OpportunityHelper.SUCCESS_MSG, 'Error in validating GPA Opportunity...!' );

            	acc.SIA_Information__c = '';
            	update acc;

            	String result4 = OpportunityHelper.GPOContractValidation(opp);
            	Assert.areEqual(result4, System.Label.GPA_Contract_Tagging_SIA_Information_Missing_Error_Msg, 'Error in validating GPA Opportunity...!' );

			Test.stopTest();
        }
    }

    @IsTest
    private static void testValidateCloseRingCentralWithVerizonOpportunity() {
        GSP_Partner_Setup__c gspPartnerSetup = (GSP_Partner_Setup__c) new SObjectBuilder(GSP_Partner_Setup__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                GSP_Partner_Setup__c.Name => RingCentralHelper.BRAND_VERIZON,
                GSP_Partner_Setup__c.Validate_by_Brand__c => true,
                GSP_Partner_Setup__c.Disable_PDF__c => false,
                GSP_Partner_Setup__c.Disable_POC__c => false,
                GSP_Partner_Setup__c.Has_NGBS_Packages__c => true,
                GSP_Partner_Setup__c.Disable_ProServ__c => false,
                GSP_Partner_Setup__c.Disable_Commercial_Quoting__c => true,
                GSP_Partner_Setup__c.Validation_name__c => RingCentralHelper.BRAND_VERIZON
            })
            .create()
            .getRecord();

        Opportunity opp = attachAccountToOpportunity(
            (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            	.setFields(new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Brand_Name__c => RingCentralHelper.BRAND_VERIZON,
                    Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"4"}'
                })
                .create()
                .getRecord(),
            (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .setField(Account.GSP__c, true)
                .build()
                .getRecord()
        );

        Quote proServQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.IsPrimary__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_CANCELLED
            })
            .build()
            .getRecord();

        Test.startTest();
            OpportunityHelper.validateOpportunityOnClose(
                opp,
                new OpportunityHelper.QuotesWrapper(new List<Quote>{ proServQuote }, opp),
                new List<Phase__c>(),
                new List<Area_Code_Line_Item__c>(),
                ProfileHelper.PROFILE_NAME_SALES_MANAGER_BUSINESS_PROCESSING,
                new List<TierTypeSetting__c>(),
                0,
                new Map<Id, Cost_Center_Line_Item__c>(),
                null,
                null,
                new Map<String, List<Approval__c>>(),
                new List<Promotion__c>(),
                null,
                new List<PartnerOperationsLog__c>(),
                null
            );
        Test.stopTest();

        Assert.areEqual(OpportunityHelper.STAGE_NAME_CLOSED_WON_PROSERV, opp.StageName, 'StageName of opportunity should be Closed Won for ProServ');
    }

    private static Opportunity attachAccountToOpportunity(Opportunity oppty, Account acc) {
        Map<String, Object> opptyMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(oppty));
        opptyMap.put('Account', acc);
        return (Opportunity) JSON.deserialize(JSON.serialize(opptyMap), Opportunity.class);
    }

    @IsTest
    static void testCreateKYCApprovalsForIndiaOffice() {
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);

        Test.startTest();
            OpportunityHelper.createKYCApprovalsForIndiaOffice(new List<Opportunity>{ masterOpp });
        Test.stopTest();

        Account accountWithApprovals = (Account) new AccountSelector()
            .selectAccountWithKYCApprovals(new List<Object>{new Set<Id>{ masterAccount.Id }})
            .executeQuery()
            .get(0);

        Assert.areEqual(1, accountWithApprovals.Approvals__r.size(), 'KYC Approval should be created');
    }

    @IsTest
    static void testCreateRenewalOppty() {
        Account masterAccount = TestDataGenerator.createAccount('Master');
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            Opportunity opp = OpportunityHelper.createRenewalOppty(masterAccount, testUser.Id);
        Test.stopTest();

        Assert.areNotEqual(null, opp, 'Opportunity should be created');
    }

    @isTest
    private static void testProcessDeliveredProserv() {
        Triggers.switchOff();

        // Create an Account using SObjectBuilder
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        // Create an Order with a lookup to Account using SObjectBuilder
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.Name => 'Test Order',
                Order.AccountId => testAccount.Id,
                Order.EffectiveDate => System.today(),
                Order.Status => 'New',
                Order.PriceBook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        // Create an Opportunity with Parent_Order__c lookup to Order using SObjectBuilder
        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Parent_Order__c => testOrder.Id,
                Opportunity.StageName => 'Prospecting',
                Opportunity.CloseDate => System.today(),
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES
            })
            .create()
            .getRecord();

        // Create a Package__c linked to Account using SObjectBuilder
        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => 'Test Package',
                Package__c.Account__c => testAccount.Id,
                Package__c.Account_Package_Id__c => '456'
            })
            .create()
            .getRecord();

        // Create a Quote linked to Opportunity and Package__c using SObjectBuilder
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => testOpportunity.Id,
                Quote.BillingPackage__c => testPackage.Id,
                Quote.Status => 'Draft',
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfoProServ()
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test_product'),
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                }
            )
            .create()
            .getRecord();

        PricebookEntry testPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        OrderItem testOrderItem = (OrderItem) new SOBjectBuilder(OrderItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                OrderItem.OrderId => testOrder.Id,
                OrderItem.PricebookEntryId => testPbe.Id,
                OrderItem.Product2Id => testProduct.Id,
                OrderItem.Quantity => 1,
                OrderItem.UnitPrice => 1
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        String body = '{"packages":[{"id":12345,"catalogId":"2","version":"1","currency": "USD", "product": "Professional Services"}]}';
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        tstMock.body = body;
        tstMock.code = 200;
        tstMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, tstMock);

        // Call the method to be tested
        List<Id> quoteIds = new List<Id>{ testQuote.Id };
        Test.startTest();
        OpportunityHelper.processDeliveredProserv(quoteIds);
        Test.stopTest();

        // Verify the operations using selectors
        // Use SuborderSelector to verify Suborder__c status
        List<Suborder__c> suborders = new SuborderSelector()
            .selectSubordersByOrderId(testOrder.Id)
            .executeQuery();
        for (Suborder__c suborder : suborders) {
            Assert.areEqual(SuborderHelper.STATUS_CANCELED, suborder.Status__c, 'Suborder status should be canceled');
        }

        // Use OrderSelector to verify Order status
        List<Order> orders = new OrderSelector()
            .selectOrdersByIds(new List<Object>{new List<Id>{testOrder.Id}})
            .executeQuery();
        for (Order order : orders) {
            Assert.areEqual(OrderHelper.STATUS_COMPLETED, order.Status, 'Order status should be completed');
        }

        // Use PackageSelector to verify Package__c status
        List<Package__c> packages = new PackageSelector()
            .selectPackagesById(new List<Id>{testPackage.Id})
            .executeQuery();
        for (Package__c pkg : packages) {
            Assert.areEqual(PackageHelper.PACKAGE_STATUS_DELETED, pkg.Package_Status__c, 'Package status should be deleted');
        }
    }
}