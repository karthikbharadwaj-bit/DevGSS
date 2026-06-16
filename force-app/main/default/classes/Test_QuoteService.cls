@isTest
private class Test_QuoteService {

    private static final String PACKAGE_INFO_WITH_CONTRACT =
        '[{"id":"18","contract":{"id":"a8f0S0000008cxHQAQ","extId":"Office","billingId":"2"}}]';
    private static final String BILLING_CONTRACT =
        '"contract":{"status":null,"id":"1","extId":null,"billingId":null}';

    private static Quote prepareAttachmentForQuoteType(String quoteType) {

        triggers.switchOff();
        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);
        testQuote.RecordTypeId = TestDataGenerator.getQuoteRecordTypeIdByName(quoteType);
        update testQuote;
        triggers.switchOn();

        RC_Quote_Template__c temp = new RC_Quote_Template__c(
            Name = 'Test Template ProServ',
            Sorting_Order__c = 1.0,
            Description__c = 'Quote',
            Brand__c = 'RingCentral',
            Opportunity_Record_Type__c = 'Sales Opportunity',
            Type__c = 'Quote;Agreement',
            Active__c = true,
            Order_Type__c = 'Change Order',
            Quote_Record_Type__c = 'ProServ Quote;Sales Quote',
            Products__c = 'RingCentral',
            Template_Engine__c = TemplateEngine.PDF_ENGINE_2_0
        );
        insert temp;

        QuoteSelector quoteSelector = new QuoteSelector();
        List<Object> binds = new List<Object>();
        binds.add(testQuote.Id);
        Quote quote = (Quote) quoteSelector.selectQuoteById(binds).executeQuery()[0];

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'attach';
        params.opportunityId = testOpp.Id;
        params.quoteId = testQuote.Id;
        params.templateId = temp.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        return quote;
    }

    static Opportunity selectOpportunity(Id oppId) {
        return (Opportunity) new ListOptional(new OpportunitySelector()
            .selectBillingOpportunity('Id = \'' + oppId + '\'')
            .selectFields(new List<Schema.sObjectField> {
                Opportunity.ProvisioningDetails__c,
                Opportunity.SelfProvisioned__c,
                Opportunity.NumberToBeRCMainNumber__c,
                Opportunity.NumberToBeCCNumber__c,
                Opportunity.RCCCSyncStatus__c,
                Opportunity.isTermination__c
            })
            .executeQuery()
        ).getFirst();
    }

    static void assertCheckAndUpdateOpportunity(
        BillingWrappers.QuoteWrapper wrapper,
        Id oppId,
        Boolean isUpdated,
        Boolean hasRCCC
    ) {
        Opportunity reselectedOpp = selectOpportunity(oppId);
        String action = isUpdated ? 'be' : 'not be';
        String reason = isUpdated ? 'differs' : 'has the same value';

        Map<String, Object> wrapperMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(wrapper));
        Map<String, Schema.sObjectField> wrapperPropsToOppFields =  new Map<String, Schema.sObjectField> {
            'opportunityProvisioningDetails' => Opportunity.ProvisioningDetails__c,
            'opportunitySelfProvisioned' => Opportunity.SelfProvisioned__c,
            'rcAccountNumber' => Opportunity.NumberToBeRCMainNumber__c,
            'ccAccountNumber' => Opportunity.NumberToBeCCNumber__c,
            'isTerminationOpportunity' => Opportunity.isTermination__c
        };

        for (String key : wrapperPropsToOppFields.keySet()) {
            Assert.areEqual(
                wrapperMap.get(key),
                reselectedOpp.get(wrapperPropsToOppFields.get(key)),
                String.format(
                    '{0} field value should {1} updated if {2} {3}',
                    new List<Object> { key, wrapperPropsToOppFields.get(key), action, reason }
                )
            );
        }
        String result = hasRCCC
            ? IcbHelper.CC_SYNC_STATUS_NOT_STARTED
            : IcbHelper.CC_SYNC_STATUS_NOT_APPLICABLE; 
        Assert.areEqual(result, reselectedOpp.RCCCSyncStatus__c, 'Wrong Process Order CC Sync Status');
    }

    @isTest
    static void test_getQuoteList() {

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        BillingWrappers.Params params = new BillingWrappers.Params();
                            params.opportunityId = testOpp.Id;

        RestRequest request = new RestRequest();
                    request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        List<Quote> result = (List<Quote>)JSON.deserialize(body, List<Quote>.class);

        System.assertEquals(result.size(), 1);
    }

    @isTest
    static void test_createSalesQuote() {

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        TestDataGenerator.createQuote(testOpp);

        BillingWrappers.Params params = new BillingWrappers.Params();
                               params.action = 'createSalesQuote';
                               params.opportunityId = testOpp.Id;
                               params.isPRMQuote = false;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        Quote result = (Quote) JSON.deserialize(body, Quote.class);
        Quote[] quoteList = [SELECT Id, IsPrimary__c FROM Quote WHERE OpportunityId = :testOpp.Id];

        System.assertEquals(
            QuoteHelper.STATUS_NEW_CUSTOMER,
            result.Upsell_Status__c,
            'Quote upsell status should be New Customer (because no upsell status/package info)');
        System.assertEquals(
            QuoteHelper.RT_ID_BILLING,
            result.RecordTypeId,
            'New Billing Quote should be created');
        System.assertEquals(
            quoteList.size(),
            2,
            'One quote by TestDataGenerator, second by QuoteService');
    }

    @isTest
    static void test_createBothBillingQuotes() {
        Triggers.switchOff();
        Account existingBusinessAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Existing Business Account'
            })
            .create()
            .getRecord();

        Opportunity newBusinessOppty = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => existingBusinessAcc.Id,
                Opportunity.Name => 'New Business Oppty',
                Opportunity.Type => 'New Business',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        BillingWrappers.Params salesParams = new BillingWrappers.Params();
            salesParams.action = 'createSalesQuote';
            salesParams.opportunityId = newBusinessOppty.Id;
            salesParams.initialTerm = '24';
            salesParams.isPRMQuote = false;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(salesParams));
        QuoteService.quote();

        BillingWrappers.Params pocParams = new BillingWrappers.Params();
            pocParams.action = 'createPOCQuote';
            pocParams.opportunityId = newBusinessOppty.Id;
            pocParams.initialTerm = '12';
            pocParams.isPRMQuote = false;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(pocParams));
        QuoteService.quote();
        Test.stopTest();

        List<Quote> quoteList = [
            SELECT Id, RecordTypeId, IsPrimary__c, Upsell_Status__c, QuoteType__c, Initial_Term_months__c
            FROM Quote
            WHERE OpportunityId = :newBusinessOppty.Id
            ORDER BY RecordTypeId DESC
        ];

        System.assertEquals(
            2,
            quoteList.size(),
            'List length should be 2 after two requests');
        System.assertEquals(
            QuoteHelper.STATUS_NEW_CUSTOMER,
            quoteList[0].Upsell_Status__c,
            'Quote upsell status should be New Customer (because no upsell status/package info)');
        System.assertEquals(
            QuoteHelper.STATUS_NEW_CUSTOMER,
            quoteList[1].Upsell_Status__c,
            'Quote upsell status should be New Customer (because no upsell status/package info)');
        System.assertEquals(
            QuoteHelper.RT_ID_BILLING,
            quoteList[0].RecordTypeId,
            'New Sales Quote should be created');
        System.assertEquals(
            QuoteHelper.RT_ID_POC,
            quoteList[1].RecordTypeId,
            'New POC Quote should be created');
        System.assertEquals(
            QuoteHelper.QUOTE_TYPE_QUOTE,
            quoteList[0].QuoteType__c,
            'New Sales Quote should be with "Quote" type');
        System.assertEquals(
            QuoteHelper.QUOTE_TYPE_QUOTE,
            quoteList[1].QuoteType__c,
            'New POC Quote should be with "Quote" type');
        System.assertEquals(
            true,
            quoteList[0].IsPrimary__c,
            'Sales Quote should be Primary');
        System.assertEquals(
            true,
            quoteList[1].IsPrimary__c,
            'POC Quote should be Primary');
        System.assertEquals(
            salesParams.initialTerm,
            quoteList[0].Initial_Term_months__c,
            'Initial_Term_months__c field value should be equal to initialTerm passed in params'
        );
        System.assertEquals(
            pocParams.initialTerm,
            quoteList[1].Initial_Term_months__c,
            'Initial_Term_months__c field value should be equal to initialTerm passed in params'
        );
    }

    @isTest
    static void test_createUpgrade() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'createSalesQuote';
        params.opportunityId = testOpportunity.Id;
        params.status = QuoteHelper.STATUS_UPGRADE;
        String pInfoJson = TestDataGenerator.getPackageInfoStr('1', '1', 'Annual')
            .replace('"packageInfo":null', '"packageInfo": {"displayName": "test", "oldPackageName":"oldTest"}');
        params.packageInfo = pInfoJson;
        params.isPRMQuote = false;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        Quote result = (Quote) JSON.deserialize(body, Quote.class);
        Quote[] quoteList = [SELECT Id FROM Quote WHERE OpportunityId = :testOpportunity.Id];

        System.assertEquals(quoteList.size(), 1, 'Quote should be created');
        System.assertEquals(
            QuoteHelper.STATUS_UPGRADE,
            result.Upsell_Status__c,
            'Quote status should be prepopulated based on params status');
        System.assertEquals(
            QuoteHelper.RT_ID_BILLING,
            result.RecordTypeId,
            'New Billing Quote should be created');
        System.assertEquals(
            pInfoJson,
            result.Package_Info__c,
            'Package Info should be populated');

        System.assert(
            !result.Auto_Renewal__c,
            'Incorrect Auto Renewal value on create'
        );

        System.assertEquals(
            null,
            result.Term_months__c,
            'Incorrect Renewal Terms on create'
        );

        System.assertEquals(
            null,
            result.Initial_Term_months__c,
            'Incorrect Initial Terms on create'
        );

        System.assertEquals(
            null,
            result.Start_Date__c,
            'Incorrect Start Date on create'
        );

    }

    @isTest
    static void testCreateTerminationSalesQuote() {

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.AccountId, testAccount.Id)
            .create()
            .getRecord();

        BillingWrappers.Params paramsData = new BillingWrappers.Params();
        paramsData.action = 'createTerminationSalesQuote';
        paramsData.opportunityId = testOpportunity.Id;
        paramsData.packageInfo = NGBSTestDataGenerator.generateQuotePackageInfo();

        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(paramsData));
        QuoteService.quote();
        Test.stopTest();

        Quote resultQuote = [
            SELECT Id, isTermination__c, Status
            FROM Quote
            WHERE OpportunityId = :testOpportunity.Id
            LIMIT 1
        ];

        System.assertNotEquals(null, resultQuote, 'Resulting quote should not be null');
        System.assertEquals(QuoteHelper.QUOTE_STATUS_ACTIVE, resultQuote.Status, 'Status should be active');
        System.assertEquals(true, resultQuote.isTermination__c, 'isTermination__c should be true');
    }

    @isTest
    static void test_update() {

        User swpWws = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testqq',
                    User.Username => 'qq!user@gmail.com',
                    User.Email => 'qq@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setField(RingCentralVariousSettings__c.SVP_WWS_User_ID__c, swpWws.Id)
            .create();

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Quote For Tests',
                Quote.OpportunityId => testOpp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Term_months__c => '36',
                Quote.Initial_Term_months__c => '36'
            })
            .create()
            .getRecord();

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 1,
            Line_Range_Max__c = 50,
            CurrencyIsoCode = 'USD',
            Service__c = 'Office'
        );
        insert testPriceBook;

        testQuote.Pricebook2Id = testPriceBook.Id;
        update testQuote;

        String pInfoJson = TestDataGenerator.getPackageInfoStrWithPreferredLanguage('1', '1', 'Annual')
            .replace('"contract":null', BILLING_CONTRACT);

        BillingWrappers.QuoteWrapper testQuoteWrapper = new BillingWrappers.QuoteWrapper();
        testQuoteWrapper.id = testQuote.Id;
        testQuoteWrapper.packageInfo = pInfoJson;
        testQuoteWrapper.name = 'test';
        testQuoteWrapper.autoRenewal = false;

        BillingWrappers.Params params = new BillingWrappers.Params();
                            params.action = 'update';
                            params.opportunityId = testOpp.Id;
                            params.quote = testQuoteWrapper;

        RestRequest request = new RestRequest();
                    request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        List<Quote> result = (List<Quote>)JSON.deserialize(body, List<Quote>.class);

        System.assertEquals(result.size(), 1);
        System.assertEquals(pInfoJson, result[0].Package_Info__c);

        System.assert(
            !result.get(0).Auto_Renewal__c,
            'Incorrect Auto Renewal value on Quote update'
        );

        System.assertEquals(
            null,
            result.get(0).Term_months__c,
            'Incorrect Renewal Terms on Quote update'
        );

        System.assertEquals(
            null,
            result.get(0).Initial_Term_months__c,
            'Incorrect Initial Terms on Quote update'
        );

        System.assertEquals(
            null,
            result.get(0).Start_Date__c,
            'Incorrect Start Date on Quote update'
        );

        System.assertEquals(
            null,
            result.get(0).PaymentMethod__c,
            'Quote.PaymentMethod__c field must be null if "paymentMethod" not specified in QuoteWrapper param'
        );
    }

    @isTest
    static void testUpdateWithCalculateFSCFeatureToggle() {

        User swpWws = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testqq',
                    User.Username => 'qq!user@gmail.com',
                    User.Email => 'qq@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setField(RingCentralVariousSettings__c.SVP_WWS_User_ID__c, swpWws.Id)
            .create();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.CalculateFSCInQW__c, true)
            .create();

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Quote For Tests',
                Quote.OpportunityId => testOpp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Term_months__c => '36',
                Quote.Initial_Term_months__c => '36'
            })
            .create()
            .getRecord();

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 1,
            Line_Range_Max__c = 50,
            CurrencyIsoCode = 'USD',
            Service__c = 'Office'
        );
        insert testPriceBook;

        testQuote.Pricebook2Id = testPriceBook.Id;
        update testQuote;

        String pInfoJson = TestDataGenerator.getPackageInfoStrWithPreferredLanguage('1', '1', 'Annual')
            .replace('"contract":null', BILLING_CONTRACT);

        BillingWrappers.QuoteWrapper testQuoteWrapper = new BillingWrappers.QuoteWrapper();
        testQuoteWrapper.id = testQuote.Id;
        testQuoteWrapper.packageInfo = pInfoJson;
        testQuoteWrapper.name = 'test';
        testQuoteWrapper.autoRenewal = false;
        testQuoteWrapper.creditAmount = 10.5;
        testQuoteWrapper.freeServiceTaxes = 5.4;

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'update';
        params.opportunityId = testOpp.Id;
        params.quote = testQuoteWrapper;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        List<Quote> result = (List<Quote>)JSON.deserialize(body, List<Quote>.class);

        System.assertEquals(result.size(), 1);
        System.assertEquals(pInfoJson, result[0].Package_Info__c);

        System.assertEquals(
            testQuoteWrapper.creditAmount,
            result.get(0).Credit_Amount__c,
            'Quote.Credit_Amount__c field must be populated with value from BillingWrappers.QuoteWrapper.creditAmount'
        );

        System.assertEquals(
            testQuoteWrapper.freeServiceTaxes,
            result.get(0).Free_Service_Taxes__c,
            'Quote.Free_Service_Taxes__c field must be populated with value from BillingWrappers.QuoteWrapper.freeServiceTaxes'
        );

        System.assertEquals(
            null,
            result.get(0).PaymentMethod__c,
            'Quote.PaymentMethod__c field must be null if "paymentMethod" not specified in QuoteWrapper param'
        );
    }

    @isTest
    static void test_deleteQuote() {

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);
        Quote testQuote2 = TestDataGenerator.createQuote(testOpp);

        BillingWrappers.Params params = new BillingWrappers.Params();
                            params.action = 'delete';
                            params.opportunityId = testOpp.Id;
                            params.quoteIdSet = new Set<Id>{testQuote.Id};

        RestRequest request = new RestRequest();
                    request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;
        Test.startTest();

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        List<Quote> result = (List<Quote>)JSON.deserialize(body, List<Quote>.class);

        Test.stopTest();

        System.assertEquals(result.size(), 1);
    }

    @isTest
    static void test_makePrimaryQuote() {

        List<Account> accList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .quantity(2)
            .setField(Account.Name,
                ValueProviderBuilder.provideList(new List<String>{
                    'Existing Business Account',
                    'Master Account'
                })
            )
            .create()
            .getRecords();
        Account existingBusinessAcc = accList.get(0);
        Account masterAccount = accList.get(1);

        Triggers.switchOff();
        List<Opportunity> optyList = (List<Opportunity>) new SOBjectBuilder(Opportunity.sObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .setField(Opportunity.Name,
                ValueProviderBuilder.provideList(new List<String>{
                    'New Business Oppty',
                    'Master Account Oppty'
                })
            )
            .setField(Opportunity.AccountId,
                ValueProviderBuilder.provideList(new List<Id>{
                    existingBusinessAcc.Id,
                    masterAccount.Id
                })
            )
            .create()
            .getRecords();
        Triggers.switchOn();

        Opportunity newBusinessOppty = optyList.get(0);
        Opportunity masterAccOppty = optyList.get(1);

        Quote parentQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => masterAccOppty.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId()
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .quantity(4)
            .setField(Quote.Name,
                ValueProviderBuilder.provideList(new List<String>{
                    'Initial Sales Primary Quote',
                    'Initial Sales Not Primary Quote',
                    'Initial POC Primary Quote',
                    'Initial POC Not Primary Quote'
                    }
                )
            )
            .setField(Quote.RecordTypeId,
                ValueProviderBuilder.provideList(new List<Id>{
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_POC,
                    QuoteHelper.RT_ID_POC
                    }
                )
            )
            .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_NEW_CUSTOMER)
            .setField(Quote.OpportunityId, newBusinessOppty.Id)
            .setField(Quote.ParentQuote__c,
                ValueProviderBuilder.provideList(new List<Id>{
                    parentQuote.Id,
                    null,
                    null,
                    null
                })
            )
            .setField(Quote.Start_Date__c, ValueProviderBuilder.provideUniqueDate())
            .setField(Quote.End_Date__c, ValueProviderBuilder.provideUniqueDate())
            .setField(Quote.IsPrimary__c,
                ValueProviderBuilder.provideList(new List<Boolean>{
                    true, false, true, false
                    }
                )
            )
            .setField(Quote.QuoteType__c, QuoteHelper.QUOTE_TYPE_QUOTE)
            .setField(Quote.PriceBook2Id, Test.getStandardPricebookId())
            .create()
            .getRecords();

        Quote quoteWillBeNotPrimary = quotes[0];
        Quote quoteWillBePrimary = quotes[1];
        Quote quotePocWillNotBePrimary = quotes[2];
        Quote quotePocWillBePrimary = quotes[3];

        RestRequest request = new RestRequest();


        BillingWrappers.Params salesParams = new BillingWrappers.Params();
                            salesParams.action = 'primary';
                            salesParams.opportunityId = newBusinessOppty.Id;
                            salesParams.quoteId = quoteWillBePrimary.Id;

        request.requestBody = Blob.valueOf(JSON.serialize(salesParams));
        RestContext.request = request;
        Test.startTest();
            QuoteService.quote();

        BillingWrappers.Params pocParams = new BillingWrappers.Params();
                            pocParams.action = 'primary';
                            pocParams.opportunityId = newBusinessOppty.Id;
                            pocParams.quoteId = quotePocWillBePrimary.Id;

        request.requestBody = Blob.valueOf(JSON.serialize(pocParams));
        RestContext.request = request;

        QuoteService.quote();

        Map<Id, Quote> quotesToVerify = new Map<Id, Quote>([
            SELECT Id, RecordTypeId, Name, IsPrimary__c, Upsell_Status__c, ParentQuote__c
            FROM Quote
            WHERE OpportunityId = :newBusinessOppty.Id
        ]);
        Test.stopTest();
        System.assertEquals(
            4,
            quotesToVerify.size(),
            'Quote List length should be 4'
        );
        System.assertEquals(
            false,
            quotesToVerify.get(quoteWillBeNotPrimary.Id).IsPrimary__c,
            'Initial primary Sales Quote should be not Primary'
        );
        System.assertEquals(
            true,
            quotesToVerify.get(quoteWillBePrimary.Id).IsPrimary__c,
            'Initial not Primary Sales Quote is now Primary'
        );
        System.assertEquals(
            false,
            quotesToVerify.get(quotePocWillNotBePrimary.Id).IsPrimary__c,
            'Initial primary POC Quote should be not Primary'
        );
        System.assertEquals(
            true,
            quotesToVerify.get(quotePocWillBePrimary.Id).IsPrimary__c,
            'Initial not Primary POC Quote is now Primary'
        );
        System.assertEquals(
            null,
            quotesToVerify.get(quoteWillBeNotPrimary.Id).ParentQuote__c,
            'Initial primary Sales Quote Parent lookUp should be cleared'
        );
        System.assertEquals(
            parentQuote.Id,
            quotesToVerify.get(quoteWillBePrimary.Id).ParentQuote__c,
            'Initial not Primary Sales Quote should get parent from initial Primary Sales Quote'
        );
    }

    @isTest
    static void test_deletePrimaryPOCQuote() {

        Account existingBusinessAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Existing Business Account'
            })
            .create()
            .getRecord();

        Opportunity newBusinessOppty = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => existingBusinessAcc.Id,
                Opportunity.Name => 'New Business Oppty',
                Opportunity.Type => 'New Business',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();
        Test.startTest();
            List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
                .quantity(4)
                .setField(Quote.Name,
                    ValueProviderBuilder.provideList(new List<String>{
                        'Initial Sales Primary Quote',
                        'Initial Sales Not Primary Quote',
                        'Initial POC Primary Quote',
                        'Initial POC Not Primary Quote'
                        }
                    )
                )
                .setField(Quote.RecordTypeId,
                    ValueProviderBuilder.provideList(new List<Id>{
                        QuoteHelper.RT_ID_BILLING,
                        QuoteHelper.RT_ID_BILLING,
                        QuoteHelper.RT_ID_POC,
                        QuoteHelper.RT_ID_POC
                        }
                    )
                )
                .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_NEW_CUSTOMER)
                .setField(Quote.OpportunityId, newBusinessOppty.Id)
                .setField(Quote.Start_Date__c, ValueProviderBuilder.provideUniqueDate())
                .setField(Quote.End_Date__c, ValueProviderBuilder.provideUniqueDate())
                .setField(Quote.IsPrimary__c,
                    ValueProviderBuilder.provideList(new List<Boolean>{
                        true, false, true, false
                        }
                    )
                )
                .setField(Quote.QuoteType__c, QuoteHelper.QUOTE_TYPE_QUOTE)
                .setField(Quote.PriceBook2Id, Test.getStandardPricebookId())
                .create()
                .getRecords();

            Quote quoteSalesPrimary = quotes[0];
            Quote quoteSalesNotPrimary = quotes[1];
            Quote quotPocToDelete = quotes[2];
            Quote quotePocWillBePrimary = quotes[3];

            RestRequest request = new RestRequest();

            BillingWrappers.Params params = new BillingWrappers.Params();
                                params.action = 'delete';
                                params.opportunityId = newBusinessOppty.Id;
                                params.quoteIdSet = new Set<Id>{quotPocToDelete.Id};

            request.requestBody = Blob.valueOf(JSON.serialize(params));
            RestContext.request = request;

            QuoteService.quote();
        Test.stopTest();
        Map<Id, Quote> quotesToVerify = new Map<Id, Quote>([
            SELECT Id, RecordTypeId, IsPrimary__c, Upsell_Status__c
            FROM Quote
            WHERE OpportunityId = :newBusinessOppty.Id
        ]);

        System.assertEquals(
            3,
            quotesToVerify.size(),
            'Quote List length should be 3'
        );
        System.assertEquals(
            true,
            quotesToVerify.get(quoteSalesPrimary.Id).IsPrimary__c,
            'Initial primary Sales Quote is still Primary'
        );
        System.assertEquals(
            false,
            quotesToVerify.get(quoteSalesNotPrimary.Id).IsPrimary__c,
            'Initial not Primary Sales Quote is still not Primary'
        );
        System.assertEquals(
            true,
            quotesToVerify.get(quotePocWillBePrimary.Id).IsPrimary__c,
            'Initial not primary POC Quote is now Primary'
        );
    }

    @isTest
    static void test_clearQuote() {

        Triggers.switchOff();

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        Product2 pOffice1 = TestDataGenerator.createProduct2('OFFICE1');
        Product2 pOffice2 = TestDataGenerator.createProduct2('OFFICE2');

        Pricebook2 pbOffice = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_OFFICE_PRODUCT);

        PricebookEntry spbeOffice1 = TestDataGenerator.createPricebookEntry(pOffice1, null);
        PricebookEntry spbeOffice2 = TestDataGenerator.createPricebookEntry(pOffice2, null);

        PricebookEntry pbeOffice1 = TestDataGenerator.createPricebookEntry(pOffice1, pbOffice);
        PricebookEntry pbeOffice2 = TestDataGenerator.createPricebookEntry(pOffice2, pbOffice);

        QuoteLineItem qliOffice1 = TestDataGenerator.createQuoteLineItem(testQuote, pOffice1);
        QuoteLineItem qliOffice2 = TestDataGenerator.createQuoteLineItem(testQuote, pOffice2);

        Triggers.switchOn();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'clear';
        params.quoteId = testQuote.Id;
        
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        QuoteService.quote();
        Test.stopTest();

        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotesByMasterQuoteIdToClearQLIs(new Set<Id> { testQuote.Id }, new List<String>())
            .executeQuery();

        for (Quote qt : quotes) {
            System.assertEquals(0, qt.QuoteLineItems.size(), 'Quote Line Items should be cleared');
            System.assertEquals(0, qt.AverageDiscount__c, 'Average Discount should be cleared');
            System.assertEquals(0, qt.OverallDiscretion__c, 'Overall Discretion should be cleared');
        }
    }
    @isTest
    static void test_clearQuote_techQuotes() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        update new List<Quote> {
            new Quote(Id = mpStruct.masterQuote.Id, OverallDiscretion__c = 10, AverageDiscount__c = 10, IsDeselected__c = false),
            new Quote(Id = mpStruct.serviceQuotes.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id, OverallDiscretion__c = 10, AverageDiscount__c = 10, IsDeselected__c = false),
            new Quote(Id = mpStruct.serviceQuotes.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id, OverallDiscretion__c = 10, AverageDiscount__c = 10, IsDeselected__c = false)
        };
        Triggers.switchOn();

        Test.startTest();
        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'clear';
        params.quoteId = mpStruct.masterQuote.Id;
        params.serviceNames = new List<String>{QuoteHelper.NGBS_RCCC_PRODUCT};

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        QuoteService.quote();

        Test.stopTest();

        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotesByMasterQuoteIdToClearQLIs(new Set<Id> { mpStruct.masterQuote.Id }, new List<String> { QuoteHelper.NGBS_RCCC_PRODUCT })
            .executeQuery();

        for (Quote qt : quotes) {
            System.assertEquals(0, qt.QuoteLineItems.size(), 'Quote Line Items should be cleared');
            System.assertEquals(0, qt.AverageDiscount__c, 'Average Discount should be cleared');
            System.assertEquals(0, qt.OverallDiscretion__c, 'Overall Discretion should be cleared');

            if (qt.ServiceName__c == QuoteHelper.NGBS_RCCC_PRODUCT) {
                System.assertEquals(true, qt.IsDeselected__c, 'IsDeselected__c should be true');
            } else {
                System.assertEquals(false, qt.IsDeselected__c, 'IsDeselected__c should be false');
            }
        }
    }

    // Need to cover it
    @isTest
    static void test_getTemplates() {

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        BillingWrappers.Params params = new BillingWrappers.Params();
                            params.action = 'templates';
                            params.quoteId = testQuote.Id;
                            params.opportunityId = testOpp.Id;

        RestRequest request = new RestRequest();
                    request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        List<RC_Quote_Template__c> result = (List<RC_Quote_Template__c>)JSON.deserialize(body, List<RC_Quote_Template__c>.class);

        System.assertEquals(result.size(), 0);
    }

    @isTest
    static void test_attach() {

        Quote quote = prepareAttachmentForQuoteType('ProServ_Quote');
        Test.startTest();
        QuoteService.quote();
        String attId = RestContext.response.responseBody.toString().remove('"');
        Test.stopTest();

        String expectedName = 'ProServ UC Quote ' + String.valueOf(quote.QuoteNumber)
            + ' for ' + quote.Opportunity.Account.Name + ' ' + System.today().format() + ' - Version 1' + '.pdf';
        Attachment att = [SELECT Id, Name, Body FROM Attachment WHERE Id = :attId];
        System.assertEquals(expectedName, att.Name, 'Name of the attachment does not match');
    }

    @isTest
    static void test_attach_ProServ_duplicateAttachmentShouldHaveVersions() {

        Quote quote = prepareAttachmentForQuoteType('ProServ_Quote');
        Test.startTest();
        QuoteService.quote();
        String attId = RestContext.response.responseBody.toString().remove('"');
        Test.stopTest();

        String expectedName = 'ProServ UC Quote ' + String.valueOf(quote.QuoteNumber)
            + ' for ' + quote.Opportunity.Account.Name + ' ' + System.today().format() + ' - Version 1' + '.pdf';
        Attachment att = [SELECT Id, Name, Body FROM Attachment WHERE Id = :attId];
        System.assertEquals(expectedName, att.Name, 'Name of the attachment does not match');
    }

    @isTest
    static void test_attach_ProServ_CC() {

        Quote quote = prepareAttachmentForQuoteType('CC_ProServ_Quote');
        Test.startTest();
        QuoteService.quote();
        String attId = RestContext.response.responseBody.toString().remove('"');
        Test.stopTest();

        String expectedName = 'ProServ CC Quote ' + String.valueOf(quote.QuoteNumber)
            + ' for ' + quote.Opportunity.Account.Name + ' ' + System.today().format() + ' - Version 1' + '.pdf';
        Attachment att = [SELECT Id, Name, Body FROM Attachment WHERE Id = :attId];
        System.assertEquals(expectedName, att.Name, 'Name of the attachment does not match');
    }

    @isTest
    static void test_createCostCenters() {
        Account acc = TestDataGenerator.createAccount('test Account');
        Opportunity testOpportunity = TestDataGenerator.createOpportunity(acc);
        Quote testQuote = TestDataGenerator.createQuote(testOpportunity);
        BillingWrappers.BillingCode bc = TestDataGenerator.createBillingCode();
        List<BillingWrappers.BillingCode> bcArray = new List<BillingWrappers.BillingCode>();
        bcArray.add(bc);
        NGBS_Settings__c ngbsSettings = new NGBS_Settings__c(CostCenterNestingLevel__c = 4);
        insert ngbsSettings;
        Test.startTest();
        QuoteService.createCostCenters(testQuote.Id, bcArray);
        Test.stopTest();
        List<Cost_Center__c> result = [SELECT Id,Name FROM Cost_Center__c WHERE Name = :bc.Name];
        System.assertEquals(result.size(), 1);
    }

    @isTest
    static void test_createCostCenterLineItemBundles() {

        insert new NGBS_Settings__c(CostCenterNestingLevel__c = 4);

        Account acc = TestDataGenerator.createAccount('test Account');
        Opportunity testOpportunity = TestDataGenerator.createOpportunity(acc);
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                            Quote.Name => 'quotetest',
                            Quote.OpportunityId => testOpportunity.Id,
                            Quote.Total_Number_of_Digital_Lines__c => 10,
                            Quote.Account__c => testOpportunity.AccountId,
                            Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                            Quote.Upsell_Status__c => 'New',
                            Quote.Pricebook2Id => Test.getStandardPricebookId()
                    }
            )
            .create()
            .getRecord();

        String testElementId1 = 'productElementId_1';
        String testElementId2 = 'productElementId_2';

        Product2 testProduct1 = TestDataGenerator.createProduct2(testElementId1);
        Product2 testProduct2 = TestDataGenerator.createProduct2(testElementId2);

        List<PriceBookEntry> priceEntryList = (List<PriceBookEntry>) new SObjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id> {testProduct1.Id,testProduct2.Id}),
                    PriceBookEntry.UnitPrice => 10000,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> quoteLineItemList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.ServiceDate => date.today(),
                    QuoteLineItem.Description => 'TestLineItem',
                    QuoteLineItem.UnitPrice => ValueProviderBuilder.provideList(new List<Decimal> {priceEntryList[0].UnitPrice, priceEntryList[1].UnitPrice}),
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PriceBookEntryId => ValueProviderBuilder.provideList(new List<Id> {priceEntryList[0].Id, priceEntryList[1].Id}),
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id> {testProduct1.Id, testProduct2.Id}),
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    QuoteLineItem.Discount_number__c => 0,
                    QuoteLineItem.NewQuantity__c => 5
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        QuoteLineItem qli = quoteLineItemList[0];
        QuoteLineItem qli2 = quoteLineItemList[1];

        Area_Codes__c testAreaCode = new Area_Codes__c(
            Name = '205',
            Area_Code__c = 205,
            Country__c = 'United States',
            State__c = 'Alabama',
            City__c = 'Alabaster',
            Type__c = 'Local'
        );
        insert testAreaCode;


        Test.startTest();
        // create a "bundle" with 1 license and verify that 2 linked Cost_Center_Line_Item__c are created
        BillingWrappers.Bundle testBundle = NGBSTestDataGenerator.createBundle(testElementId1, 1, null);

        BillingWrappers.BundleItem testLicense = NGBSTestDataGenerator.createBundleItem(testElementId2, null);
        BillingWrappers.AreaCodeData areaCode = new BillingWrappers.AreaCodeData();
        areaCode.type = 'Local';
        areaCode.state = 'Alabama';
        areaCode.city = 'Alabaster';
        areaCode.country = 'United States';
        areaCode.areaCode = 205;

        testLicense.areaCode = areaCode;
        testBundle.licenses.add(testLicense);

        BillingWrappers.BillingCode bc = TestDataGenerator.createBillingCode();

        bc.bundles.add(testBundle);

        List<BillingWrappers.BillingCode> bcArray = new List<BillingWrappers.BillingCode>();
        bcArray.add(bc);

        QuoteService.createCostCenters(testQuote.Id, bcArray);
        Test.stopTest();

        List<Cost_Center_Line_Item__c> result = [SELECT Id, Parent__c, Quantity__c, Quote_Line_Item__c, ElementId__c, AreaCode__c FROM Cost_Center_Line_Item__c];
        System.assertEquals(2, result.size(), '2 Cost_Center_Line_Item__c must be created');
        Map<Id, Cost_Center_Line_Item__c> qliIdToCostCenterLineItemMap = new Map<Id, Cost_Center_Line_Item__c>();
        for (Cost_Center_Line_Item__c ccli : result) {
            System.assert(
                ccli.Quote_Line_Item__c != null,
                'Cost_Center_Line_Item__c.Quote_Line_Item__c field should not be empty'
            );
            qliIdToCostCenterLineItemMap.put(ccli.Quote_Line_Item__c, ccli);
        }

        System.assert(
            qliIdToCostCenterLineItemMap.containsKey(qli.Id),
            'all created Cost_Center_Line_Item__c should be linked to corresponding QuoteLineItem' +
            '(it should be QuoteLineItem founded by Product2.ExtID__c field)'
        );
        Cost_Center_Line_Item__c parentItem = qliIdToCostCenterLineItemMap.get(qli.Id);
        System.assert(parentItem.Parent__c == null, 'parent item(bundle item) should have empty Parent__c field');
        System.assert(parentItem.Quantity__c != null, 'parent item(bundle item) should have not empty Quantity__c field');
        System.assertEquals(
            testElementId1,
            parentItem.ElementId__c,
            'parent item(bundle item) should have same ElementId__c as the associated QuoteLineItem.Product2.ExtID__c'
        );

        System.assert(
            qliIdToCostCenterLineItemMap.containsKey(qli2.Id),
            'all created Cost_Center_Line_Item__c should be linked to corresponding QuoteLineItem' +
            '(it should be QuoteLineItem founded by Product2.ExtID__c field)'
        );
        Cost_Center_Line_Item__c childItem = qliIdToCostCenterLineItemMap.get(qli2.Id);
        System.assert(childItem.Parent__c != null, 'child item(license) should have not empty Parent__c field');
        System.assertEquals(
            parentItem.Id,
            childItem.Parent__c,
            'child item(license) should have a not empty lookup to Parent'
        );
        System.assertEquals(
            testElementId2,
            childItem.ElementId__c,
            'child item(license) should have same ElementId__c as the associated QuoteLineItem.Product2.ExtID__c'
        );
        System.assertEquals(
            testAreaCode.Id,
            childItem.AreaCode__c,
            'a license may have an associated AreaCode, if present'
        );
    }

    @IsTest
    static void test_CreateTaxLocation() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Account__c => acc.Id,
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Tax_Location__c taxLocation = (Tax_Location__c) new SObjectBuilder(Tax_Location__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Tax_Location__c.Name => 'test tax location',
                Tax_Location__c.Country__c => 'United States',
                Tax_Location__c.State__c => 'New York',
                Tax_Location__c.City__c => 'Islip Terrace',
                Tax_Location__c.BillingId__c => 'test address Id',
                Tax_Location__c.ZipCode__c => '11752'
            })
            .create()
            .getRecord();

        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center__c.Name => 'test cost center',
                Cost_Center__c.Quote__c => q.Id,
                Cost_Center__c.Tax_Location__c => taxLocation.Id,
                Cost_Center__c.AddressId__c => 'test address Id',
                Cost_Center__c.BillingId__c => 'test billing id'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        List<Tax_Location__c> taxLocations = [SELECT Id FROM Tax_Location__c];
        System.assertEquals(1, taxLocations.size(), 'should not be 2 TaxLocations with the same billingId');


        BillingWrappers.BillingCode billingCodeChild1 = TestDataGenerator.createBillingCode();
        billingCodeChild1.parentId = costCenter.Id;
        billingCodeChild1.location.country = 'USA';
        billingCodeChild1.addressId = 'test address Id';

        QuoteService.createCostCenters(q.Id, new BillingWrappers.BillingCode[] {billingCodeChild1});

        taxLocations = [SELECT Id FROM Tax_Location__c];
        System.assertEquals(1, taxLocations.size(), 'should not be 2 TaxLocations with the same billingId');


        BillingWrappers.BillingCode billingCodeChild2 = TestDataGenerator.createBillingCode();
        billingCodeChild2.parentId = costCenter.Id;
        billingCodeChild2.location.country = 'USA';
        billingCodeChild2.addressId = null;

        QuoteService.createCostCenters(q.Id, new BillingWrappers.BillingCode[] {billingCodeChild2});

        taxLocations = [SELECT Id FROM Tax_Location__c];
        System.assertEquals(2, taxLocations.size(), 'should be only one record for each TaxLocation');
    }

    @isTest
    static void test_getDocuSignData() {

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);

        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        BillingWrappers.Params params = new BillingWrappers.Params();

        params.opportunityId = testOpp.Id;
        params.action = 'getDocuSignData';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));

        RestContext.request = request;

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();

        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);

        System.assert(parsedBody.containsKey('data'));
        System.assert(parsedBody.containsKey('status'));
        System.assert(parsedBody.containsKey('messages'));

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');

        System.assert(data.containsKey('isOpportunityHasActiveEnvelopes'));
        System.assert(data.containsKey('featureToggle'));
        System.assert(data.containsKey('envelopeList'));
        System.assert(data.containsKey('recipientList'));
        System.assert(data.containsKey('attachmentList'));

        System.assertEquals(false, data.get('isOpportunityHasActiveEnvelopes'));

        List<Object> envelopeList = (List<Object>) data.get('envelopeList');
        System.assertEquals(0, envelopeList.size());

        List<Object> attachmentList = (List<Object>) data.get('attachmentList');
        System.assertEquals(0, attachmentList.size());

        List<Object> recipientList = (List<Object>) data.get('recipientList');
        System.assertEquals(0, recipientList.size());
    }

    @isTest
    static void test_getDocuSignData_WithRecipients() {

        Contact cntct = new Contact(
            FirstName = 'test fname',
            LastName = 'test lname',
            Email = 'testemail@emailvendor.com'
        );
        insert cntct;

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        testOpp.Primary_Opportunity_Contact__c = cntct.Id;
        update testOpp;

        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        BillingWrappers.Params params = new BillingWrappers.Params();

        params.opportunityId = testOpp.Id;
        params.action = 'getDocuSignData';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));

        RestContext.request = request;

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();

        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);

        System.assert(parsedBody.containsKey('data'));
        System.assert(parsedBody.containsKey('status'));
        System.assert(parsedBody.containsKey('messages'));

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');

        System.assert(data.containsKey('isOpportunityHasActiveEnvelopes'));
        System.assert(data.containsKey('featureToggle'));
        System.assert(data.containsKey('envelopeList'));
        System.assert(data.containsKey('recipientList'));
        System.assert(data.containsKey('attachmentList'));

        System.assertEquals(false, data.get('isOpportunityHasActiveEnvelopes'));

        List<Object> envelopeList = (List<Object>) data.get('envelopeList');
        System.assertEquals(0, envelopeList.size());

        List<Object> attachmentList = (List<Object>) data.get('attachmentList');
        System.assertEquals(0, attachmentList.size());

        List<Object> recipientList = (List<Object>) data.get('recipientList');
        System.assertEquals(1, recipientList.size());

        Map<String, Object> recipient = (Map<String, Object>) recipientList.get(0);

        System.assertEquals(cntct.FirstName, recipient.get('FirstName'));
        System.assertEquals(cntct.LastName, recipient.get('LastName'));
        System.assertEquals(cntct.Email, recipient.get('Email'));
    }

    @isTest
    static void test_validateDocusignBeforeStart() {

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);

        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        BillingWrappers.Params params = new BillingWrappers.Params();

        params.opportunityId = testOpp.Id;
        params.action = 'validateDocusignBeforeStart';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));

        RestContext.request = request;

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();

        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);

        System.assert(parsedBody.containsKey('data'));
        System.assert(parsedBody.containsKey('status'));
        System.assert(parsedBody.containsKey('messages'));

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');

        System.assert(data.containsKey('additionalValidationResult'));
        System.assert(data.containsKey('errorsSerialized'));

        Map<String, Object> additionalValidationResult = (Map<String, Object>) data.get('additionalValidationResult');

        System.assert(additionalValidationResult.containsKey('data'));
        System.assert(additionalValidationResult.containsKey('messages'));
        System.assert(additionalValidationResult.containsKey('status'));

        String errorsSerialized = (String) data.get('errorsSerialized');
        if (errorsSerialized != null) {
            List<Object> deserializedErrors = (List<Object>) JSON.deserializeUntyped(errorsSerialized);
            System.debug('deserializedErrors >>>> ' + deserializedErrors);
        }
    }

    @isTest
    static void test_refreshEnvelopes() {

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);

        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        List<dsfs__DocuSign_Status__c> envelopeList = new List<dsfs__DocuSign_Status__c>();

        dsfs__DocuSign_Status__c testEnvelope = new dsfs__DocuSign_Status__c(
            dsfs__Envelope_Status__c = 'Sent',
            dsfs__DocuSign_Envelope_ID__c = 'some_envelope_id',
            dsfs__Opportunity__c = testOpp.Id
        );

        envelopeList.add(testEnvelope);
        insert envelopeList;

        BillingWrappers.Params params = new BillingWrappers.Params();

        params.opportunityId = testOpp.Id;
        params.action = 'refreshEnvelopes';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));

        RestContext.request = request;

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();

        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);

        System.assert(parsedBody.containsKey('data'));
        System.assert(parsedBody.containsKey('status'));
        System.assert(parsedBody.containsKey('messages'));

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');

        System.assert(data.containsKey('envelopeList'));
        System.assert(data.containsKey('isOpportunityHasActiveEnvelopes'));

        List<Object> receivedEnvelopes = (List<Object>) data.get('envelopeList');
        System.assertEquals(envelopeList.size(), receivedEnvelopes.size());

        Map<String, Object> envelope = (Map<String, Object>) receivedEnvelopes.get(0);
        System.assertEquals(testEnvelope.dsfs__DocuSign_Envelope_ID__c, envelope.get('dsfs__DocuSign_Envelope_ID__c'));
    }

    @isTest
    static void test_refreshDocuments() {

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);

        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        BillingWrappers.Params params = new BillingWrappers.Params();

        params.opportunityId = testOpp.Id;
        params.action = 'refreshDocuments';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));

        RestContext.request = request;

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();

        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);

        System.assert(parsedBody.containsKey('data'));
        System.assert(parsedBody.containsKey('status'));
        System.assert(parsedBody.containsKey('messages'));

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('opportunityList'));
        System.assert(data.containsKey('opportunityErrors'));

        List<Object> opportunityList = (List<Object>) data.get('opportunityList');
        System.assert(opportunityList.size() == 1, 'Wrong opty list was returned');
    }

    @isTest
    static void test_refreshRecipients() {

        Contact cntct = new Contact(
            FirstName = 'test fname',
            LastName = 'test lname',
            Email = 'testemail@emailvendor.com'
        );
        insert cntct;

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        testOpp.Primary_Opportunity_Contact__c = cntct.Id;
        update testOpp;

        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        BillingWrappers.Params params = new BillingWrappers.Params();

        params.opportunityId = testOpp.Id;
        params.action = 'refreshRecipients';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));

        RestContext.request = request;

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();

        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);

        System.assert(parsedBody.containsKey('data'));
        System.assert(parsedBody.containsKey('status'));
        System.assert(parsedBody.containsKey('messages'));

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('recipientList'));

        List<Object> recipientList = (List<Object>) data.get('recipientList');
        System.assertEquals(1, recipientList.size());

        Map<String, Object> recipient = (Map<String, Object>) recipientList.get(0);

        System.assertEquals(cntct.FirstName, recipient.get('FirstName'));
        System.assertEquals(cntct.LastName, recipient.get('LastName'));
        System.assertEquals(cntct.Email, recipient.get('Email'));
    }


    @isTest
    static void test_DocuSignSend() {
        Test.startTest();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        testOpp.Is_Billing_Opportunity__c = true;
        update testOpp;

        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        List<Attachment> attachmentList = new List<Attachment>();

        Attachment testDocument = new Attachment(
            Name = 'testImage.jpg',
            ContentType = 'image/jpeg',
            Body = Blob.valueOf('Unit Test Attachment Body'),
            ParentId = testOpp.Id
        );

        Test.stopTest();

        attachmentList.add(testDocument);
        insert attachmentList;

        List<Attachment> testQuoteAttachments = [SELECT Id FROM Attachment WHERE ParentId = :testOpp.Id];

        List<Id> attachmentsToSend = new List<Id>();
        attachmentsToSend.add(testDocument.Id);

        BillingWrappers.Params params = new BillingWrappers.Params();

        params.action = 'DocuSignSend';
        params.quoteId = testQuote.Id;
        params.selectedDocsIds = attachmentsToSend;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));

        RestContext.request = request;

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();

        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);

        System.assert(parsedBody.containsKey('data'));
        System.assert(parsedBody.containsKey('status'));
        System.assert(parsedBody.containsKey('messages'));

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('quoteId'));

        System.assertEquals(
            testQuote.Id,
            data.get('quoteId'),
            'Incorrect Quote Id was received'
        );

        List<Attachment> testQuoteAttachmentsReselected = [SELECT Id FROM Attachment WHERE ParentId = :testOpp.Id];
        // attachment should copy to quote
        System.assertEquals(
            testQuoteAttachments.size(),
            testQuoteAttachmentsReselected.size(),
            'Attachments should be equals'
        );

        System.assertEquals(
            attachmentsToSend.size(),
            testQuoteAttachmentsReselected.size(),
            'Sended Attachments quantity should be equals to reselected'
        );
    }

    @isTest
    static void test_getClmLicenseAvailability() {
        DocusignHelper.docusignRESTSettings = new Map<String, String>{
            'AdminRequestIntegratorKey' => null,
            'AdminRequestPrivateKey' => null,
            'RequestAuthDomain' => null,
            'DSOrganizationID' => null,
            'DSAccountID' => null,
            'AdminDataCenter' => null,
            'AdminApiVersion' => null,
            'AdminDSUserName' => null
        };

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'getClmLicenseAvailability';
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        QuoteService.quote();
        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');

        Boolean hasClmLicense = (Boolean) data.get('hasClmLicense');
        String apiErrors = (String) data.get('errors');

        System.assertEquals(false, hasClmLicense, 'Parameter "hasClmLicense" should be false, since not all parameters are filled in');
        System.assertEquals(true, String.isNotBlank(apiErrors), 'Parameter "errors" should not be blank, since not all parameters are filled in');
    }

    @isTest
    static void testCreatePOCApproval() {
        Triggers.switchOff();
        POC_GOA__c pocGoaCustomSetting = (POC_GOA__c) new SObjectBuilder(POC_GOA__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                POC_GOA__c.Sales_Rep__c => '1-5',
                POC_GOA__c.Direct_Manager__c => '6-25',
                POC_GOA__c.Segment_Leader__c => '0-0',
                POC_GOA__c.SVP_WWS_Directs__c => '26-50',
                POC_GOA__c.SVP_WWS__c => '51-9999'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('TestOpportunity'),
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Professional',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Product2 productMonthly = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_PHONE,
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

        Quote pocQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test POC Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => Quote.SObjectType.getDescribe().getRecordTypeInfosByName().get('POC Quote').getRecordTypeId(),
                Quote.Pricebook2Id => pricebook.Id
            })
            .create()
            .getRecord();

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
                QuoteLineItem.QuoteId => pocQuote.Id,
                QuoteLineItem.Product2Id => productMonthly.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.UnitPrice => 10
            })
            .quantity(3)
            .create()
            .getRecords();

        Triggers.switchOn();

        BillingWrappers.Params params = new BillingWrappers.Params();

        params.action = 'createPOCApproval';
        params.quoteId = pocQuote.Id;
        params.opportunityId = opp.Id;
        params.data = new Map<String, String>{
            'linkToSignedAgreement' => 'http://testlink'
        };

        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;
        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        Id pocApprovalId = (Id) JSON.deserialize(body, Id.class);

        System.assertNotEquals(null, pocApprovalId, 'new POC Approval record should be created');
        System.assertEquals(
            Approval__c.SObjectType,
            pocApprovalId.getSObjectType(),
            'returned Id should have SObjectType of Approval__c'
        );

        Test.stopTest();

        List<Approval__c> approvalList = [SELECT Id, Account__c, Quote__c, Opportunity__c,
                POC_Application_Form__c, Number_of_POC_Users__c, RecordTypeId, PhonesAmount__c
            FROM Approval__c
            WHERE Id = :pocApprovalId];

        Decimal phones = 0;

        for (QuoteLineItem qli : qlis) {
            phones += qli.Quantity;
        }

        System.assert(approvalList.size() > 0, 'new POC Approval record should be created');

        Approval__c createdApproval = approvalList.get(0);

        System.assertEquals(
            opp.AccountId,
            createdApproval.Account__c,
            'created Approval record should be related to Account'
        );

        System.assertEquals(
            pocQuote.Id,
            createdApproval.Quote__c,
            'created Approval record should be related to Quote, whose Id was passed as the "quoteId" parameter'
        );

        System.assertEquals(
            opp.Id,
            createdApproval.Opportunity__c,
            'created Approval record should be related to Opportunity, whose Id was passed as the "opportunityId" parameter'
        );

        System.assertEquals(
            ApprovalHelper.RT_ID_POC_ACCOUNT,
            createdApproval.RecordTypeId,
            'created POC Approval record should have RecordType "POC Account"'
        );

        System.assertEquals(
            pocQuote.Total_Number_of_Digital_Lines__c,
            createdApproval.Number_of_POC_Users__c,
            'created Approval record should have Number_of_POC_Users__c equals to Quote.Total_Number_of_Digital_Lines__c'
        );

        System.assertEquals(
            params.data.get('linkToSignedAgreement'),
            createdApproval.POC_Application_Form__c,
            'Approval.POC_Application_Form__c should be populated with "linkToSignedAgreement" passed as parameter'
        );

        System.assertEquals(
            phones,
            createdApproval.PhonesAmount__c,
            'PhonesAmount__c should be populated from the related QLIs'
        );
    }

    @isTest
    static void testCreatePOCApprovalShouldHandleErrors() {
        Triggers.switchOff();
        POC_GOA__c pocGoaCustomSetting = (POC_GOA__c) new SObjectBuilder(POC_GOA__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                POC_GOA__c.Sales_Rep__c => '1-5',
                POC_GOA__c.Direct_Manager__c => '6-25',
                POC_GOA__c.Segment_Leader__c => '0-0',
                POC_GOA__c.SVP_WWS_Directs__c => '26-50',
                POC_GOA__c.SVP_WWS__c => '51-9999'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('TestOpportunity'),
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Professional',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Quote pocQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test POC Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => Quote.SObjectType.getDescribe().getRecordTypeInfosByName().get('POC Quote').getRecordTypeId(),
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();

            BillingWrappers.Params params = new BillingWrappers.Params();
            params.action = 'createPOCApproval';

            // error case 1 (do not pass required parameter "quoteId")
            RestRequest request = new RestRequest();
            request.requestBody = Blob.valueOf(JSON.serialize(params));

            RestContext.request = request;

            QuoteService.quote();

            String body = RestContext.response.responseBody.toString();

            Map<String, String> result = (Map<String, String>) JSON.deserialize(body, Map<String, String>.class);

            System.assertNotEquals(
                null,
                result,
                'in case of error method still should return the response(with error data)'
            );

            System.assert(result.containsKey('error'), 'response body should contains error data');

            System.assertEquals(
                QuoteService.EMPTY_QUOTEID_ERR_MESSAGE,
                result.get('error'),
                'if "quoteId" parameter is missing method should return expected error'
            );

            // error case 2 (do not pass required parameter "opportunityId")
            params = new BillingWrappers.Params();
            params.action = 'createPOCApproval';
            params.quoteId = pocQuote.Id;

            request = new RestRequest();
            request.requestBody = Blob.valueOf(JSON.serialize(params));

            RestContext.request = request;

            QuoteService.quote();

            body = RestContext.response.responseBody.toString();

            result = (Map<String, String>) JSON.deserialize(body, Map<String, String>.class);

            System.assertNotEquals(
                null,
                result,
                'in case of error method still should return the response(with error data)'
            );

            System.assert(result.containsKey('error'), 'response body should contains error data');

            System.assertEquals(
                QuoteService.EMPTY_OPPID_ERR_MESSAGE,
                result.get('error'),
                'if "opportunityId" parameter is missing method should return expected error'
            );


            // error case 3 (do not pass required parameter "data")
            params = new BillingWrappers.Params();
            params.action = 'createPOCApproval';
            params.quoteId = pocQuote.Id;
            params.opportunityId = opp.Id;

            request = new RestRequest();
            request.requestBody = Blob.valueOf(JSON.serialize(params));

            RestContext.request = request;

            QuoteService.quote();

            body = RestContext.response.responseBody.toString();

            result = (Map<String, String>) JSON.deserialize(body, Map<String, String>.class);

            System.assertNotEquals(
                null,
                result,
                'in case of error method still should return the response(with error data)'
            );

            System.assert(result.containsKey('error'), 'response body should contains error data');

            System.assertEquals(
                QuoteService.EMPTY_LINK_TO_AGREEMENT_ERR_MESSAGE,
                result.get('error'),
                'if "linkToSignedAgreement" parameter is missing method should return expected error'
            );


            // error case 4(pass empty map as "data" parameter)
            params = new BillingWrappers.Params();
            params.action = 'createPOCApproval';
            params.quoteId = pocQuote.Id;
            params.opportunityId = opp.Id;
            params.data = new Map<String, String>();

            request = new RestRequest();
            request.requestBody = Blob.valueOf(JSON.serialize(params));

            RestContext.request = request;

            QuoteService.quote();

            body = RestContext.response.responseBody.toString();

            result = (Map<String, String>) JSON.deserialize(body, Map<String, String>.class);

            System.assertNotEquals(
                null,
                result,
                'in case of error method still should return the response(with error data)'
            );

            System.assert(result.containsKey('error'), 'response body should contains error data');

            System.assertEquals(
                QuoteService.EMPTY_LINK_TO_AGREEMENT_ERR_MESSAGE,
                result.get('error'),
                'if "linkToSignedAgreement" parameter is missing method should return expected error'
            );


            // error case 5 (pass "data" parameter with empty linkToSignedAgreement)
            params = new BillingWrappers.Params();
            params.action = 'createPOCApproval';
            params.quoteId = pocQuote.Id;
            params.opportunityId = opp.Id;
            params.data = new Map<String, String>{
                'linkToSignedAgreement' => ''
            };

            request = new RestRequest();
            request.requestBody = Blob.valueOf(JSON.serialize(params));

            RestContext.request = request;

            QuoteService.quote();

            body = RestContext.response.responseBody.toString();

            result = (Map<String, String>) JSON.deserialize(body, Map<String, String>.class);

            System.assertNotEquals(
                null,
                result,
                'in case of error method still should return the response(with error data)'
            );

            System.assert(result.containsKey('error'), 'response body should contains error data');

            System.assertEquals(
                QuoteService.EMPTY_LINK_TO_AGREEMENT_ERR_MESSAGE,
                result.get('error'),
                'if "linkToSignedAgreement" parameter is missing method should return expected error'
            );

        Test.stopTest();
    }

    @isTest
    static void createPOCApprovalMethodShouldThrowExpectedExceptions() {

        try {

            Approval__c result = QuoteService.createPOCApproval(null);

            throw new AquivaHelper.AquivaException('An exception should have been thrown');

        } catch (Exception ex) {
            System.assert(
                ex.getMessage().contains(QuoteService.EMPTY_PARAMSDATA_ERR_MESSAGE),
                'Unexpected exception was thrown'
            );
        }
    }

    @isTest
    static void testEnrichQuoteData() {
        final String dummyId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .build()
            .getRecord();

        BillingWrappers.QuoteWrapper quoteWrapper = new BillingWrappers.QuoteWrapper();
        quoteWrapper.Id = dummyId;
        quoteWrapper.justification = 'justification';
        quoteWrapper.startDate = null;
        quoteWrapper.endDate = null;
        quoteWrapper.mainAreaCodeId = dummyId;
        quoteWrapper.faxAreaCodeId = dummyId;
        quoteWrapper.upsellStatus = 'upsellStatus';
        quoteWrapper.shippingShipAttentionTo = 'shippingShipAttentionTo';
        quoteWrapper.shippingCountry = 'shippingCountry';
        quoteWrapper.shippingCity = 'shippingCity';
        quoteWrapper.shippingState = 'shippingState';
        quoteWrapper.shippingAddressLine = 'shippingAddressLine';
        quoteWrapper.shippingPostalCode = 'shippingPostalCode';
        quoteWrapper.shippingAdditionalAddressLine = 'shippingAdditionalAddressLine';
        quoteWrapper.shippingCustomerName = 'shippingCustomerName';
        quoteWrapper.shippingShippingOption = 'shippingShippingOption';
        quoteWrapper.shippingMultipleLocations = true;
        quoteWrapper.isTaxesAdded = true;

        Boolean isWizardHasErrors = true;
        Boolean isUpdate = false;

        QuoteService.enrichQuoteData(qt, quoteWrapper, isWizardHasErrors, isUpdate);

        System.assertEquals(dummyId, qt.Id, 'quoteWrapper id is not equal to Quote id');
        System.assertEquals('justification', qt.JustificationandDescription__c,
            'quoteWrapper justification is not equal to Quote JustificationandDescription__c');
        System.assertEquals(null, qt.Start_Date__c, 'quoteWrapper Start_Date__c is not equal to Quote Start_Date__c');
        System.assertEquals(null, qt.End_Date__c, 'quoteWrapper End_Date__c is not equal to Quote End_Date__c');
        System.assertEquals(null, qt.AreaCode__c, 'quoteWrapper AreaCode__c is not equal to Quote AreaCode__c');
        System.assertEquals(null, qt.FaxAreaCode__c, 'quoteWrapper AreaCode__c is not equal to Quote AreaCode__c');
        System.assertEquals('upsellStatus', qt.Upsell_Status__c,
            'quoteWrapper upsellStatus is not equal to Quote upsellStatus');
        System.assertEquals('shippingShipAttentionTo', qt.Ship_Attention_To__c,
            'quoteWrapper shippingShipAttentionTo is not equal to Quote Ship_Attention_To__c');
        System.assertEquals('shippingCountry', qt.Shipping_Country__c,
            'quoteWrapper shippingCountry is not equal to Quote shippingCountry');
        System.assertEquals('shippingCity', qt.Shipping_City__c,
            'quoteWrapper shippingCity is not equal to Quote Shipping_City__c');
        System.assertEquals('shippingState', qt.Shipping_State__c,
            'quoteWrapper shippingState is not equal to Quote Shipping_State__c');
        System.assertEquals('shippingAddressLine', qt.Shipping_Address_Line__c,
            'quoteWrapper ishippingAddressLined is not equal to Quote Shipping_Address_Line__c');
        System.assertEquals('shippingPostalCode', qt.Shipping_Postal_Code__c,
            'quoteWrapper shippingPostalCode is not equal to Quote Shipping_Postal_Code__c');
        System.assertEquals('shippingAdditionalAddressLine', qt.Shipping_Additional_Address_Line__c,
            'quoteWrapper shippingAdditionalAddressLine is not equal to Quote Shipping_Additional_Address_Line__c');
        System.assertEquals('shippingCustomerName', qt.Shipping_Customer_Name__c,
            'quoteWrapper shippingCustomerName is not equal to Quote Shipping_Customer_Name__c');
        System.assertEquals('shippingShippingOption', qt.Shipping_Option__c,
            'quoteWrapper shippingShippingOption is not equal to Quote Shipping_Option__c');
        System.assertEquals(true, qt.MultipleShippingLocations__c,
            'quoteWrapper MultipleShippingLocations__c is not equal to Quote MultipleShippingLocations__c');
        System.assertEquals(true, qt.NGBSTaxesAdded__c,
            'quoteWrapper NGBSTaxesAdded__c is not equal to Quote NGBSTaxesAdded__c');
        System.assertEquals(true, qt.IsQuoteHasErrors__c,
            'quoteWrapper IsQuoteHasErrors__c is not equal to Quote IsQuoteHasErrors__c');
    }

    @isTest
    static void testNeedTaxesReestimationCheckboxPopulation() {
        Triggers.switchOff();
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_Account_Based_Tax_Exemption__c, true)
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Wall street')
            .setField(Account.BillingCity, 'NYC')
            .setField(Account.BillingState, 'NY')
            .setField(Account.BillingPostalCode, '123890')
            .setField(Account.BillingCountry, 'US')
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setField(PriceBook2.Service__c, Pricebook2Helper.SERVICE_OFFICE)
            .setField(PriceBook2.IsActive, true)
            .setField(PriceBook2.Line_Range_Min__c, 5)
            .setField(PriceBook2.Tier_ID__c, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Account__c, acc.Id)
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_UPGRADE)
            .setField(Quote.Pricebook2Id, pricebook.Id)
            .setField(Quote.NeedTaxesReestimation__c, true)
            .create()
            .getRecord();
        Triggers.switchOn();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'taxesReestimated';
        params.quoteId = q.Id;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        Test.startTest();
            QuoteService.quote();
        Test.stopTest();

        Quote updatedQuote = (Quote) new QuoteSelector()
            .selectQuotesForAccount(new Set<Id>{acc.Id})
            .selectField(Quote.NeedTaxesReestimation__c)
            .executeQuery()
            .get(0);

        System.assertEquals(false, updatedQuote.NeedTaxesReestimation__c,
            'NeedTaxesReestimation__c checkbox should be set to false');
    }

    @isTest
    static void testUpgradeWithSpecialTerms() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.NGBSTaxesAdded__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'upgrade';
        params.quoteId = billingQuote.Id;
        params.opportunityId = opp.Id;
        params.status = QuoteHelper.STATUS_UPGRADE;
        params.specialTerms = QuoteHelper.FREE_MONTH_1;
        params.isPrimaryQuote = true;
        params.isRemoveAreaCodes = false;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        List<Quote> quotes = (List<Quote>) JSON.deserialize(body, List<Quote>.class);

        System.assertEquals(
            QuoteHelper.FREE_MONTH_1,
            quotes.get(0).Special_Terms__c,
            'Quote should have 1 week Special Terms'
        );

        System.assert(
            quotes.get(0).Auto_Renewal__c,
            'Incorrect Auto Renewal value on upgrade'
        );

        System.assertEquals(
            '36',
            quotes.get(0).Term_months__c,
            'Incorrect Renewal Terms on upgrade'
        );

        System.assertEquals(
            null,
            quotes.get(0).Initial_Term_months__c,
            'Incorrect Initial Terms on Quote upgrade'
        );

        System.assertEquals(
            null,
            quotes.get(0).Start_Date__c,
            'Incorrect Start Date on Quote upgrade'
        );

        System.assert(
            !quotes.get(0).NGBSTaxesAdded__c,
            'NGBSTaxesAdded__c should be false after upgrade quote'
        );
    }

    @isTest
    static void testUpgradeByNonowner() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.NGBSTaxesAdded__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'upgrade';
        params.quoteId = billingQuote.Id;
        params.opportunityId = opp.Id;
        params.status = QuoteHelper.STATUS_UPGRADE;
        params.specialTerms = QuoteHelper.FREE_MONTH_1;
        params.isPrimaryQuote = true;
        params.isRemoveAreaCodes = false;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        Profile testProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];

        List<User> users = new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Alias => 'standt',
                    User.Email => 'standarduser@testorg.com',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LastName => 'Testing',
                    User.LanguageLocaleKey => 'en_US',
                    User.ProfileId => testProfile.Id,
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.UserName => 'testrep@ringcentral.com'
                }
            )
            .create()
            .getRecords();

        System.runAs(users[0]) {
            QuoteService.quote();
        }

        String body = RestContext.response.responseBody.toString();
        List<Quote> quotes = (List<Quote>) JSON.deserialize(body, List<Quote>.class);
        System.assertEquals(
            1,
            quotes.size(),
            'Upgrade call should return a quote with out any errors'
        );
    }

    @isTest
    static void testUpgradeWithCalculateFSCFeatureToggle() {

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.CalculateFSCInQW__c, true)
            .create();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.NGBSTaxesAdded__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => PACKAGE_INFO_WITH_CONTRACT
            })
            .create()
            .getRecord();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'upgrade';
        params.quoteId = billingQuote.Id;
        params.opportunityId = opp.Id;
        params.status = QuoteHelper.STATUS_UPGRADE;
        params.specialTerms = QuoteHelper.FREE_MONTH_1;
        params.isPrimaryQuote = true;
        params.isRemoveAreaCodes = false;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        List<Quote> quotes = (List<Quote>) JSON.deserialize(body, List<Quote>.class);

        System.assertEquals(
            null,
            quotes.get(0).Special_Terms__c,
            'Quote.Special_Terms__c field must be null if Feature_Toggle__c.CalculateFSCInQW__c is true'
        );

        System.assertEquals(
            null,
            quotes.get(0).Credit_Amount__c,
            'Quote.Credit_Amount__c field must be null if Feature_Toggle__c.CalculateFSCInQW__c is true'
        );

        System.assertEquals(
            null,
            quotes.get(0).Free_Service_Taxes__c,
            'Quote.Free_Service_Taxes__c field must be null if Feature_Toggle__c.CalculateFSCInQW__c is true'
        );
    }

    @isTest
    static void testUpdatePackageWithSpecialTerms() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.NGBSTaxesAdded__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'updatePackage';
        params.quoteId = billingQuote.Id;
        params.opportunityId = opp.Id;
        params.status = QuoteHelper.STATUS_UPGRADE;
        params.specialTerms = QuoteHelper.FREE_MONTH_1;
        params.isPrimaryQuote = true;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        List<Quote> quotes = (List<Quote>) JSON.deserialize(body, List<Quote>.class);

        System.assertEquals(
            QuoteHelper.FREE_MONTH_1,
            quotes.get(0).Special_Terms__c,
            'Quote should have 1 week Special Terms'
        );

        System.assert(
            quotes.get(0).Auto_Renewal__c,
            'Incorrect Auto Renewal value on Package update'
        );

        System.assertEquals(
            '36',
            quotes.get(0).Term_months__c,
            'Incorrect Renewal Terms on Package update'
        );

        System.assertEquals(
            null,
            quotes.get(0).Initial_Term_months__c,
            'Incorrect Initial Terms on Package update'
        );

        System.assertEquals(
            null,
            quotes.get(0).Start_Date__c,
            'Incorrect Start Date on Package update'
        );

        System.assert(
            !quotes.get(0).NGBSTaxesAdded__c,
            'NGBSTaxesAdded__c should be false after update package'
        );

        System.assertEquals(
            null,
            quotes.get(0).PaymentMethod__c,
            'Quote.PaymentMethod__c field must be null if "paymentMethod" not specified in params'
        );
    }

    @isTest
    static void testUpdatePackageWithCalculateFSCFeatureToggle() {

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.CalculateFSCInQW__c, true)
            .create();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.NGBSTaxesAdded__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'updatePackage';
        params.quoteId = billingQuote.Id;
        params.opportunityId = opp.Id;
        params.status = QuoteHelper.STATUS_UPGRADE;
        params.specialTerms = QuoteHelper.FREE_MONTH_1;
        params.isPrimaryQuote = true;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        List<Quote> quotes = (List<Quote>) JSON.deserialize(body, List<Quote>.class);

        System.assertEquals(
            null,
            quotes.get(0).Special_Terms__c,
            'Quote.Special_Terms__c field must be null if Feature_Toggle__c.CalculateFSCInQW__c is true'
        );

        System.assertEquals(
            null,
            quotes.get(0).Credit_Amount__c,
            'Quote.Credit_Amount__c field must be null if Feature_Toggle__c.CalculateFSCInQW__c is true'
        );

        System.assertEquals(
            null,
            quotes.get(0).Free_Service_Taxes__c,
            'Quote.Free_Service_Taxes__c field must be null if Feature_Toggle__c.CalculateFSCInQW__c is true'
        );

        System.assertEquals(
            null,
            quotes.get(0).PaymentMethod__c,
            'Quote.PaymentMethod__c field must be null if "paymentMethod" not specified in params'
        );
    }

    @isTest
    static void testAccountBillingAddressCopiesToQuote() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingPostalCode, '123890')
            .setField(Account.BillingCountry, 'US')
            .setField(Account.BillingState, 'NY')
            .setField(Account.BillingCity, 'NYC')
            .setField(Account.BillingStreet, 'Wall street')
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setField(PriceBook2.Service__c, Pricebook2Helper.SERVICE_OFFICE)
            .setField(PriceBook2.IsActive, true)
            .setField(PriceBook2.Line_Range_Min__c, 5)
            .setField(PriceBook2.Tier_ID__c, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Account__c, acc.Id)
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_UPGRADE)
            .setField(Quote.Pricebook2Id, pricebook.Id)
            .setField(Quote.NeedTaxesReestimation__c, true)
            .create()
            .getRecord();
        Triggers.switchOn();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'updateQuoteBillingAddress';
        params.quoteId = q.Id;
        params.accountId = acc.Id;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        Test.startTest();
            QuoteService.quote();
        Test.stopTest();

        Quote updatedQuote = (Quote) new QuoteSelector()
            .selectQuotesForAccount(new Set<Id>{acc.Id})
            .selectFields(new List<String>{
                'Billing_Zip_Postal_Code__c',
                'Billing_Country__c',
                'Billing_State_Province__c',
                'Billing_City__c',
                'Billing_Street__c'
            })
            .executeQuery()
            .get(0);

        System.assertEquals(acc.BillingPostalCode, updatedQuote.Billing_Zip_Postal_Code__c,
            'Billing Postal Code should be equal on Account and Quote');
        System.assertEquals(acc.BillingCountry, updatedQuote.Billing_Country__c,
            'Billing Contry should be equal on Account and Quote');
        System.assertEquals(acc.BillingState, updatedQuote.Billing_State_Province__c,
            'Billing State should be equal on Account and Quote');
        System.assertEquals(acc.BillingCity, updatedQuote.Billing_City__c,
            'Billing City should be equal on Account and Quote');
        System.assertEquals(acc.BillingStreet, updatedQuote.Billing_Street__c,
            'Billing Street should be equal on Account and Quote');
    }

    @isTest
    private static void testSetRenewalConditionsWithContract() {
        final String TERMS_VALUE = '12';

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Term_months__c => TERMS_VALUE,
                Quote.Initial_Term_months__c => TERMS_VALUE,
                Quote.Start_Date__c => System.today()
            })
            .build()
            .getRecord();

        Test.startTest();

        QuoteService.setRenewalConditions(qt, true);

        Test.stopTest();

        System.assert(
            qt.Auto_Renewal__c,
            'Auto Renewal should not be changed with contract condition'
        );

        System.assertEquals(
            TERMS_VALUE,
            qt.Term_months__c,
            'Renewal Terms should not be changed with contract condition'
        );

        System.assertEquals(
            TERMS_VALUE,
            qt.Initial_Term_months__c,
            'Initial Terms should not be changed with contract condition'
        );

        System.assertEquals(
            System.today(),
            qt.Start_Date__c,
            'Start Date should not be changed with contract condition'
        );
    }

    @isTest
    private static void testSetRenewalConditionsWithoutContract() {

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .build()
            .getRecord();

        Test.startTest();

        QuoteService.setRenewalConditions(qt, false);

        Test.stopTest();

        System.assert(
            !qt.Auto_Renewal__c,
            'Auto Renewal should be false with contract condition'
        );

        System.assertEquals(
            null,
            qt.Term_months__c,
            'Renewal Terms should be null with contract condition'
        );

        System.assertEquals(
            null,
            qt.Initial_Term_months__c,
            'Initial Terms should be null with contract condition'
        );

        System.assertEquals(
            null,
            qt.Start_Date__c,
            'Start Date should be null with contract condition'
        );
    }

    @isTest
    private static void testCheckRenewalConditionsWithContract() {
        final String TERMS_VALUE = '24';

        Quote oldQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .build()
            .getRecord();

        Quote newQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Package_Info__c => PACKAGE_INFO_WITH_CONTRACT
            })
            .build()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .build()
            .getRecord();

        Test.startTest();

        QuoteService.checkRenewalConditions(oldQuote, newQuote, qt);

        Test.stopTest();

        System.assertEquals(
            TERMS_VALUE,
            qt.Term_months__c,
            'Renewal Terms should have default value with contract'
        );

        System.assertEquals(
            TERMS_VALUE,
            qt.Initial_Term_months__c,
            'Initial Terms should have default value with contract'
        );
    }

    @isTest
    private static void testCheckRenewalConditionsWithoutContract() {

        Quote oldQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .build()
            .getRecord();

        Quote newQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .build()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .build()
            .getRecord();

        Test.startTest();

        QuoteService.checkRenewalConditions(oldQuote, newQuote, qt);

        Test.stopTest();

        System.assertEquals(
            null,
            qt.Term_months__c,
            'Renewal Terms should be null without contract'
        );

        System.assertEquals(
            null,
            qt.Initial_Term_months__c,
            'Initial Terms should be null without contract'
        );
    }

    @isTest
    static void testEngageProserv() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setField(PriceBook2.IsActive, true)
            .create()
            .getRecord();

        PriceBook2 pricebookProServ = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setField(PriceBook2.IsActive, true)
            .setField(Pricebook2.Name, 'ProServ GBP')
            .setField(Pricebook2.ExtID__c, 'Test_ProServ_GBP')
            .setField(Pricebook2.CurrencyIsoCode, RingCentralHelper.GBP)
            .create()
            .getRecord();

        new SObjectBuilder(PriceBookAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBookAssignments__c.Name => ValueProviderBuilder.provideUniqueString('test_setting_'),
                PriceBookAssignments__c.Active__c => true,
                PriceBookAssignments__c.BrandName__c => OpportunityHelper.BRAND_AVAYA,
                PriceBookAssignments__c.SubBrandName__c => null,
                PriceBookAssignments__c.PSPriceBookExtID__c => pricebookProServ.ExtID__c,
                PriceBookAssignments__c.Currency__c => RingCentralHelper.GBP
            })
            .create();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.GBP,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Account__c => acc.Id,
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => pricebook.Id,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        final String proservDetails = 'some proserv details';

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'engageProServ';
        params.accountId = acc.Id;
        params.opportunityId = opp.Id;
        params.data = new Map<String, String>{
            'type' => 'ProServ',
            'details' => proservDetails
        };

        Test.startTest();
            RestContext.request = new RestRequest();
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
            QuoteService.quote();
            String body = RestContext.response.responseBody.toString();
        Test.stopTest();

        List<Quote> result = (List<Quote>)JSON.deserialize(body, List<Quote>.class);
        System.assert(result.size() == 2, 'After engaging ProServ account should have 2 quotes(Sales and ProServ)');

        List<Quote> reselectedQuotes = (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .selectField(Quote.ProServ_Details__c)
            .setCondition('OpportunityId = \'' + opp.Id + '\'')
            .executeQuery();

        Quote proservQuote = null;
        for (Quote qt : reselectedQuotes) {
            if (qt.RecordTypeId == QuoteHelper.RT_ID_PROSERV) {
                proservQuote = qt;
            }
        }
        System.assert(proservQuote != null, 'Quote with RecordType "ProservQuote" should be created');
        System.assertEquals(
            proservDetails,
            proservQuote.ProServ_Details__c,
            '"details" in parameters should be saved in proserv quote Quote.ProServ_Details__c field'
        );
    }

    @isTest
    static void testCancelProserv() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setField(PriceBook2.IsActive, true)
            .create()
            .getRecord();

        PriceBook2 pricebookProServ = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setField(PriceBook2.IsActive, true)
            .setField(PriceBook2.AllowedRecordType__c, 'Service Billing ProServ')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Quote salesQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Account__c => acc.Id,
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => pricebook.Id
            })
            .create()
            .getRecord();

        Quote proServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Account__c => acc.Id,
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => pricebookProServ.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        final String proservDetails = 'some details about Cancelling';

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'cancelEngageProServ';
        params.opportunityId = opp.Id;
        params.data = new Map<String, String>{
            'type' => 'ProServ',
            'details' => proservDetails
        };

        Test.startTest();
            RestContext.request = new RestRequest();
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
            QuoteService.quote();
            String body = RestContext.response.responseBody.toString();
        Test.stopTest();

        List<Quote> result = (List<Quote>)JSON.deserialize(body, List<Quote>.class);
        System.assert(result.size() == 2, 'After cancelling ProServ account should have 2 quotes(Sales and ProServ)');

        List<Quote> reselectedQuotes = (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .selectField(Quote.ProServ_Details__c)
            .selectField(Quote.ProServ_Status__c)
            .setCondition('OpportunityId = \'' + opp.Id + '\'')
            .executeQuery();

        Quote reselectedProserv = null;
        for (Quote qt : reselectedQuotes) {
            if (qt.RecordTypeId == QuoteHelper.RT_ID_PROSERV) {
                reselectedProserv = qt;
            }
        }
        System.assert(reselectedProserv != null, 'Quote with RecordType "ProservQuote" should be created');
        System.assertEquals(
            proservDetails,
            reselectedProserv.ProServ_Details__c,
            '"details" in parameters should be saved in proserv quote Quote.ProServ_Details__c field'
        );
        System.assertEquals(
            QuoteHelper.PROSERVSTATUS_CANCELLED,
            reselectedProserv.ProServ_Status__c,
            'ProServ_Status__c for ProServ Quote hould be "Cancelled"'
        );
    }

    @isTest
    static void testEngageLegalForAvayaPositive() {

        List<Quote> testQuotes = testDataForEngageLegalForAvaya();

        // with attachemnts and playbooks
        BillingWrappers.Params params = new BillingWrappers.Params();
        params.quoteId = testQuotes[0].Id;
        params.data = new Map<String, String> {
            'approvalStatus' => 'Approved',
            'orderForm' => 'Standard',
            'serviceAttachment' => 'Standard',
            'skipApprovalSubmit' => 'true',
            'legalEngagementType' => 'Special Terms and Notes on Order Forms',
            'commercialMsa' => 'Standard',
            'rcEntity' => 'USA',
            'proServAgreement' => 'Standard',
            'slaSupportService' => 'Standard',
            'baaAttachment' => 'Standard',
            'dpaAttachment' => 'Standard',
            'securityAddendum' => 'Standard',
            'standardStepUp' => 'true',
            'paymentTerms' => '45',
            'trialPeriodOutClause' => '30',
            'valueChoiceOfLaw' => 'Delaware',
            'specialTermsAndNotes' => '<b>TERMS AND NOTES</b>'
        };
        params.stepUps = new List<BillingWrappers.StepUp>{new BillingWrappers.StepUp(), new BillingWrappers.StepUp()};
        params.stepUps[0].stepUpDate = '2019-12-26';
        params.stepUps[0].stepDLs = 10;
        params.stepUps[1].stepUpDate = '2020-01-26';
        params.stepUps[1].stepDLs = 20;

        Test.startTest();

            QuoteService.processEngageLegal(params);

        Test.stopTest();

        List<Approval__c> apprs = getEngageLegalApprovals();
        System.assertEquals(1, apprs.size());
        Approval__c appr = apprs[0];

        System.assertEquals('Approved', appr.Status__c);
        System.assertEquals('Standard', appr.Order_Form__c);
        System.assertEquals('Standard', appr.Service_Attachment__c);

        System.assertEquals('USA', appr.RC_Entity__c);

        // assert all attachemnts selected
        System.assertEquals('Standard', appr.BAAs__c);
        System.assertEquals(true, appr.BAA__c);
        System.assertEquals('Standard', appr.Model_Clauses__c);
        System.assertEquals(true, appr.DPA__c);
        System.assertEquals('Standard', appr.ProServ_Agreement__c);
        System.assertEquals('Standard', appr.SLA_GSS__c);
        System.assertEquals(true, appr.SLA_Customer_Support_GSS__c);
        System.assertEquals('Standard', appr.Security_Addendums__c);
        System.assertEquals(true, appr.Security_Addendum__c);

        // assert playbooks values set
        System.assertEquals('45', appr.Payment_Terms__c);
        System.assertEquals('30', appr.Trial_Period_Out_clause__c);
        System.assertEquals('Delaware', appr.Value_Choice_of_Law__c);
        System.assertEquals(true, appr.Standard_Step_Up__c);
        System.assertEquals('<b>TERMS AND NOTES</b>', appr.Special_Terms_and_Notes__c);

        // StepUps
        System.assertEquals(2, appr.Step_Ups__r.size());

        Set<Date> stepUpDates = new Set<Date>{Date.valueOf('2019-12-26'), Date.valueOf('2020-01-26')};
        Set<Decimal> stepUpNums = new Set<Decimal>{10, 20};

        for (Step_Up__c stepUp : appr.Step_Ups__r) {
            System.assert(stepUpDates.contains(stepUp.Step_Up_Date__c));
            System.assert(stepUpNums.contains(stepUp.Step_Up_DLs__c));
        }

    }

    @isTest
    static void testEngageLegalForAvayaNegative() {

        List<Quote> testQuotes = testDataForEngageLegalForAvaya();

        // no playbooks and attachments
        BillingWrappers.Params params = new BillingWrappers.Params();
        params.quoteId = testQuotes[1].Id;
        params.data = new Map<String, String> {
            'approvalStatus' => 'Approved',
            'orderForm' => 'Standard',
            'serviceAttachment' => 'Standard',
            'skipApprovalSubmit' => 'true',
            'legalEngagementType' => 'Enterprise/Majors Agreement',
            'enterpriseAgreement' => 'Standard'
        };

        Test.startTest();

            QuoteService.processEngageLegal(params);

        Test.stopTest();

        List<Approval__c> apprs = getEngageLegalApprovals();
        System.assertEquals(1, apprs.size());
        Approval__c appr = apprs[0];

        System.assertEquals('Approved', appr.Status__c);
        System.assertEquals('Standard', appr.Order_Form__c);
        System.assertEquals('Standard', appr.Service_Attachment__c);

        // assert that no attachments selected
        System.assertEquals(null, appr.BAAs__c);
        System.assertEquals(false, appr.BAA__c);
        System.assertEquals(null, appr.Model_Clauses__c);
        System.assertEquals(false, appr.DPA__c);
        System.assertEquals(null, appr.ProServ_Agreement__c);
        System.assertEquals(null, appr.SLA_GSS__c);
        System.assertEquals(false, appr.SLA_Customer_Support_GSS__c);
        System.assertEquals(null, appr.Security_Addendums__c);
        System.assertEquals(false, appr.Security_Addendum__c);

        // assert playbooks values not set
        System.assertEquals(null, appr.Payment_Terms__c);
        System.assertEquals(null, appr.Trial_Period_Out_clause__c);
        System.assertEquals(null, appr.Value_Choice_of_Law__c);
        System.assertEquals(false, appr.Standard_Step_Up__c);
        System.assertEquals(null, appr.Special_Terms_and_Notes__c);

        // StepUps
        System.assertEquals(0, appr.Step_Ups__r.size());

    }

    private static List<Quote> testDataForEngageLegalForAvaya() {
        new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        List<Opportunity> testOpps = new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAcc.Id)
            .setField(Opportunity.CloseDate, ValueProviderBuilder.provideUniqueDate())
            .setField(Opportunity.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .quantity(2)
            .create()
            .getRecords();

        return new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Quote.OpportunityId, new ValueProvider.MultiParentProvider(testOpps))
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.Payment_Plan__c, Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT)
            .setField(Quote.PriceBook2Id, Test.getStandardPriceBookId())
            .quantity(2)
            .create()
            .getRecords();
    }

    private static List< Approval__c> getEngageLegalApprovals() {
        return new ApprovalSelector()
            .selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Quote__c,
                Approval__c.Type__c,
                Approval__c.Status__c,
                Approval__c.Commercial_MSA__c,
                Approval__c.Enterprise_Agreement__c,
                Approval__c.RC_Entity__c,
                Approval__c.Order_Form__c,
                Approval__c.Service_Attachment__c,
                Approval__c.BAAs__c,
                Approval__c.BAA__c,
                Approval__c.Model_Clauses__c,
                Approval__c.DPA__c,
                Approval__c.ProServ_Agreement__c,
                Approval__c.SLA__c,
                Approval__c.SLA_GSS__c,
                Approval__c.SLA_Customer_Support_GSS__c,
                Approval__c.Security_Addendums__c,
                Approval__c.Security_Addendum__c,
                Approval__c.Payment_Terms__c,
                Approval__c.Trial_Period_Out_clause__c,
                Approval__c.Standard_Step_Up__c,
                Approval__c.Value_Choice_of_Law__c,
                Approval__c.Special_Terms_and_Notes__c
            })
            .subselect(new StepUpSelector().selectStepUps())
            .executeQuery();
    }

    @isTest
    static void testGetCostCenterItems() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Account__c => acc.Id,
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String>{
                    'DigitalLine', 'DigitalLine Unlimited', 'Test Polycom'
                }),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{
                    'Technical License', 'Service', 'Discounted Phones'
                }),
                Product2.Feature__c => ValueProviderBuilder.provideList(new List<Decimal>{
                    Product2Helper.FEATURE_SERVICE_PLAN,
                    Product2Helper.FEATURE_SERVICE_PLAN,
                    11
                }),
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String>{
                    'LC_DL_75', 'LC_DL-UNL_50', 'LC_HD_141'
                })
            })
            .quantity(3)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(products),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .quantity(3)
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => q.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(products),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeList),
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.UnitPrice => 10
            })
            .quantity(3)
            .create()
            .getRecords();

        Tax_Location__c tl = (Tax_Location__c) new SObjectBuilder(Tax_Location__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Tax_Location__c.Name => 'test tax location',
                Tax_Location__c.Country__c => 'United States',
                Tax_Location__c.State__c => 'New York',
                Tax_Location__c.City__c => 'Islip Terrace',
                Tax_Location__c.ZipCode__c => '11752'
            })
            .create()
            .getRecord();

        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center__c.Name => 'test cost center',
                Cost_Center__c.Quote__c => q.Id,
                Cost_Center__c.Tax_Location__c => tl.Id,
                Cost_Center__c.BillingId__c => 'test billing id'
            })
            .create()
            .getRecord();

        Cost_Center_Line_Item__c bundleItem = (Cost_Center_Line_Item__c) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center_Line_Item__c.Name => 'testBundle',
                Cost_Center_Line_Item__c.Quote_Line_Item__c => qlis.get(0).Id,
                Cost_Center_Line_Item__c.Cost_Center__c => costCenter.Id,
                Cost_Center_Line_Item__c.Quantity__c => 3,
                Cost_Center_Line_Item__c.ElementId__c => 'LC_DL_75'
            })
            .create()
            .getRecord();

        List<Cost_Center_Line_Item__c> ccliList = (List<Cost_Center_Line_Item__c>) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center_Line_Item__c.Name => ValueProviderBuilder.provideUniqueString('license'),
                Cost_Center_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideParents(new List<QuoteLineItem>{
                    qlis.get(1), qlis.get(2)
                }),
                Cost_Center_Line_Item__c.Cost_Center__c => costCenter.Id,
                Cost_Center_Line_Item__c.Parent__c => bundleItem.Id,
                Cost_Center_Line_Item__c.ElementId__c => ValueProviderBuilder.provideList(new List<String>{
                    'LC_DL-UNL_50', 'LC_HD_141'
                })
            })
            .quantity(2)
            .create()
            .getRecords();
        Triggers.switchOn();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'getCostCenterItems';
        params.quoteId = q.Id;

        Test.startTest();
            RestContext.request = new RestRequest();
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
            QuoteService.quote();
            String body = RestContext.response.responseBody.toString();
        Test.stopTest();

        List<BillingWrappers.BillingCode> result = (List<BillingWrappers.BillingCode>)JSON.deserialize(
            body,
            List<BillingWrappers.BillingCode>.class
        );

        System.assertEquals(
            1,
            result.size(),
            'size of billing codes should be equal to numer of Cost_Center__c related to current quote'
        );

        BillingWrappers.BillingCode bc = result.get(0);

        System.assertEquals(costCenter.Id, bc.Id, 'BillingWrappers.BillingCode.Id should have Id of Cost_Center__c');

        System.assertEquals(
            costCenter.BillingId__c,
            bc.billingId,
            'BillingWrappers.BillingCode.billingId should have value of Cost_Center__c.BillingId__c'
        );

        System.assertEquals(
            costCenter.Name,
            bc.name,
            'BillingWrappers.BillingCode.name should have value of Cost_Center__c.Name'
        );


        List<BillingWrappers.Bundle> bundles = bc.bundles;
        System.assertEquals(
            1,
            bundles.size(),
            'BillingWrappers.BillingCode.bundles should have 1 bundle'
        );

        BillingWrappers.Bundle receivedBundle = bundles.get(0);

        List<BillingWrappers.BundleItem> receivedLicenses = receivedBundle.licenses;
        System.assertEquals(
            2,
            receivedLicenses.size(),
            'bundles should contain 2 licenses(2 Cost_Center_Line_Item__c objects with same parent)'
        );

        List<Cost_Center_Line_Item__c> allCostCenterLineItems = new List<Cost_Center_Line_Item__c>(ccliList);
        allCostCenterLineItems.add(bundleItem);

        Map<Id, Cost_Center_Line_Item__c> qliIdToCostCenterLineItemMap = new Map<Id, Cost_Center_Line_Item__c>();
        for (Cost_Center_Line_Item__c ccli : ccliList) {
            qliIdToCostCenterLineItemMap.put(ccli.Quote_Line_Item__c, ccli);
        }

        Map<Id, Cost_Center_Line_Item__c> costCenterLineItemsMap = new Map<Id, Cost_Center_Line_Item__c>(allCostCenterLineItems);

        System.assertEquals(bundleItem.ElementId__c, receivedBundle.elementID, 'ElementId__c should be copied to bundle.elementID field');
        System.assertEquals(bundleItem.Id, receivedBundle.id, 'Id should be copied to bundle.id field');
        System.assertEquals(bundleItem.Quantity__c, receivedBundle.qty, 'Quantity__c should be copied to bundle.qty field');

        for (BillingWrappers.BundleItem license : receivedLicenses) {
            System.assert(license.id != null, 'received license.id should not be empty');
            Cost_Center_Line_Item__c currentCcli = costCenterLineItemsMap.get(license.id);
            System.assertEquals(
                currentCcli.ElementId__c,
                license.elementID,
                'elementid should be filled with corresponding ElementId__c'
            );
        }

        BillingWrappers.TaxLocation taxLocation = bc.location;

        System.assertEquals(
            costCenter.Tax_Location__c,
            taxLocation.id,
            'BillingWrappers.BillingCode.location.Id should have id of Cost_Center__c.Tax_Location__c'
        );

        System.assertEquals(
            tl.Name,
            taxLocation.label,
            'BillingWrappers.BillingCode.location.label should have value of Cost_Center__c.Tax_Location__c.Name'
        );

        System.assertEquals(
            tl.Country__c,
            taxLocation.country,
            'BillingWrappers.BillingCode.location.country should have value of Cost_Center__c.Tax_Location__c.Country__c'
        );

        System.assertEquals(
            tl.State__c,
            taxLocation.state,
            'BillingWrappers.BillingCode.location.state should have value of Cost_Center__c.Tax_Location__c.State__c'
        );

        System.assertEquals(
            tl.City__c,
            taxLocation.city,
            'BillingWrappers.BillingCode.location.city should have value of Cost_Center__c.Tax_Location__c.City__c'
        );

        System.assertEquals(
            tl.ZipCode__c,
            taxLocation.zip,
            'BillingWrappers.BillingCode.location.zip should have value of Cost_Center__c.Tax_Location__c.ZipCode__c'
        );
    }


    @isTest
    static void testApprovalSubmit() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Account__c => acc.Id,
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                Quote.Level_1_Approver__c => UserInfo.getUserId(),
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'approval';
        params.opportunityId = opp.Id;
        params.quoteId = q.Id;
        params.subAction = 'Submit';

        Test.startTest();
            RestContext.request = new RestRequest();
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
            QuoteService.quote();
            String body = RestContext.response.responseBody.toString();
        Test.stopTest();

        List<Quote> result = (List<Quote>)JSON.deserialize(body, List<Quote>.class);

        Quote processedQuote = result.get(0);

        System.assertEquals(
            'Pending L1 Approval',
            processedQuote.Approved_Status__c,
            'after submitting for Approval quote should have "Pending L1 Approval" Approved_Status__c'
        );
    }

    @isTest
    static void testApprovalGenerateQLIdetails() {
        Triggers.switchOff();
        RC_Quote_Template__c template = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'test template'
            })
            .create()
            .getRecord();

        final String templateSectionContent = 'test content';

        TemplateSections__c templateSection = (TemplateSections__c) new SObjectBuilder(TemplateSections__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                TemplateSections__c.Content_1__c => templateSectionContent
            })
            .create()
            .getRecord();

        TemplateSectionJunction__c junction = (TemplateSectionJunction__c) new SObjectBuilder(
            TemplateSectionJunction__c.SObjectType
        )
            .setFields(new Map<SObjectField, Object>{
                TemplateSectionJunction__c.RC_Quote_Template__c => template.Id,
                TemplateSectionJunction__c.Template_Section__c => templateSection.Id
            })
            .create()
            .getRecord();

        new SObjectBuilder(RC_Quote_Templates__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Templates__c.Name => QuoteHelper.QUOTE_DETAILS_TEMPLATE,
                RC_Quote_Templates__c.TemplateId__c => template.Id
            })
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Account__c => acc.Id,
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'approval';
        params.opportunityId = opp.Id;
        params.quoteId = q.Id;
        params.subAction = 'GenerateQLIdetails';


        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        Test.startTest();
            QuoteService.quote();
        Test.stopTest();

        List<Quote> reselectedQuotes = (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .selectField(Quote.QLI_details__c)
            .setCondition('OpportunityId = \'' + opp.Id + '\'')
            .executeQuery();

        Quote reselectedQuote = reselectedQuotes.get(0);
        System.assertEquals(
            templateSectionContent,
            reselectedQuote.QLI_details__c,
            'Quote.QLI_details__c field should be populated after GenerateQLIdetails action'
        );
    }

    @isTest
    static void testEnrichQuoteDataWithAreaCodes() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .build()
            .getRecord();

        BillingWrappers.AreaCodeData mainAreaCode = new BillingWrappers.AreaCodeData();
        mainAreaCode.country = 'USA';
        mainAreaCode.state = 'IL';
        mainAreaCode.city = 'Chicago';
        mainAreaCode.areaCode = 123;

        BillingWrappers.AreaCodeData faxAreaCode = new BillingWrappers.AreaCodeData();
        faxAreaCode.country = 'USA';
        faxAreaCode.state = 'NY';
        faxAreaCode.city = 'NY';
        faxAreaCode.areaCode = 456;

        BillingWrappers.QuoteWrapper quoteWrapper = new BillingWrappers.QuoteWrapper();
        quoteWrapper.mainAreaCodeInfo = mainAreaCode;
        quoteWrapper.faxAreaCodeInfo = faxAreaCode;

        Test.startTest();

        QuoteService.enrichQuoteData(qt, quoteWrapper, false, false);

        Test.stopTest();

        List<Area_Codes__c> areaCodes = (List<Area_Codes__c>) new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery();

        System.assertEquals(
            2,
            areaCodes.size(),
            'Area Codes was created incorrectly'
        );

        System.assertNotEquals(
            null,
            qt.AreaCode__c,
            'Main Area Code was assigned incorrectly'
        );

        System.assertNotEquals(
            null,
            qt.FaxAreaCode__c,
            'Fax Area Code was assigned incorrectly'
        );
    }

    @isTest
    static void testSyncCostCenterItems() {
        Triggers.switchOff();
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setField(NGBS_Settings__c.CostCenterNestingLevel__c, 4)
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingPostalCode, '123890')
            .setField(Account.BillingCountry, 'US')
            .setField(Account.BillingState, 'NY')
            .setField(Account.BillingCity, 'NYC')
            .setField(Account.BillingStreet, 'Wall street')
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setField(PriceBook2.Service__c, Pricebook2Helper.SERVICE_OFFICE)
            .setField(PriceBook2.IsActive, true)
            .setField(PriceBook2.Line_Range_Min__c, 5)
            .setField(PriceBook2.Tier_ID__c, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Account__c, acc.Id)
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_UPGRADE)
            .setField(Quote.Pricebook2Id, pricebook.Id)
            .setField(Quote.NeedTaxesReestimation__c, true)
            .create()
            .getRecord();

        Cost_Center__c cc = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center__c.Name =>'testCostCenter',
                Cost_Center__c.Quote__c => q.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        // create 3 levels of costCenters(1 for update, 2 for insert)
        BillingWrappers.BillingCode billingCodeToUpdate = new BillingWrappers.BillingCode();
        billingCodeToUpdate.Id = cc.Id;
        billingCodeToUpdate.name = 'updatedName';
        billingCodeToUpdate.depth = 0;

        BillingWrappers.BillingCode billingCodeToInsert1 = new BillingWrappers.BillingCode();
        billingCodeToInsert1.name = 'testName';
        billingCodeToInsert1.depth = 1;
        billingCodeToInsert1.parentId = cc.Id;
        billingCodeToInsert1.guid = 'some_guid_id_1';

        BillingWrappers.BillingCode billingCodeToInsert2 = new BillingWrappers.BillingCode();
        billingCodeToInsert2.name = 'testName2';
        billingCodeToInsert2.depth = 2;
        billingCodeToInsert2.parentXid = 'some_guid_id_1';
        billingCodeToInsert2.guid = 'some_guid_id_2';

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'syncCostCenterItems';
        params.quoteId = q.Id;
        params.billingCodes = new List<BillingWrappers.BillingCode>{
            billingCodeToUpdate, billingCodeToInsert1, billingCodeToInsert2
        };

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        Test.startTest();
            RestContext.request = new RestRequest();
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
            QuoteService.quote();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();


        System.assert(!responseBody.contains('stacktrace'), 'Cost Center Items Sync shoud be successful');

        List<Cost_Center__c> costCenterList = [SELECT Id, Name, Cost_Center_Parent__c
            FROM Cost_Center__c
            WHERE Quote__c = :q.Id];

        System.assertEquals(3, costCenterList.size(), 'Quote should have 3 Cost_Center__c objects');

        Map<String, Cost_Center__c> nameToCostCenterMap = new Map<String, Cost_Center__c>();
        for (Cost_Center__c item : costCenterList) {
            nameToCostCenterMap.put(item.Name, item);
        }
        System.assert(
            nameToCostCenterMap.containsKey(billingCodeToUpdate.name),
            'all billing codes passed as parameters should be saved as Cost_Center__c objects'
        );
        System.assert(
            nameToCostCenterMap.containsKey(billingCodeToInsert1.name),
            'all billing codes passed as parameters should be saved as Cost_Center__c objects'
        );
        System.assert(
            nameToCostCenterMap.containsKey(billingCodeToInsert2.name),
            'all billing codes passed as parameters should be saved as Cost_Center__c objects'
        );

        Cost_Center__c topLevelCostCenter = nameToCostCenterMap.get(billingCodeToUpdate.name);
        Cost_Center__c costCenterChild1 = nameToCostCenterMap.get(billingCodeToInsert1.name);
        Cost_Center__c costCenterChild2 = nameToCostCenterMap.get(billingCodeToInsert2.name);

        System.assertEquals(
            topLevelCostCenter.Cost_Center_Parent__c,
            null,
            'top-level cost center should have empty Cost_Center_Parent__c field'
        );
        System.assertEquals(
            topLevelCostCenter.Id,
            costCenterChild1.Cost_Center_Parent__c,
            'second-level cost center should have top-level cost center as Cost_Center_Parent__c '
        );
        System.assertEquals(
            costCenterChild1.Id,
            costCenterChild2.Cost_Center_Parent__c,
            'third-level cost center should have second-level cost center as Cost_Center_Parent__c '
        );
    }

    @isTest
    static void testGetCostCenters() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Account__c => acc.Id,
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Cost_Center__c cc = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center__c.Quote__c => q.Id,
                Cost_Center__c.Name => 'testCC'
            })
            .create()
            .getRecord();

        Test.startTest();
        List<Cost_Center__c> ccList = QuoteService.getCostCenters(q.Id);
        Test.stopTest();

        System.assertEquals(
            1,
            ccList.size(),
            'Result CC List should contain exactly ONE element'
        );
        System.assertEquals(
            'testCC',
            ccList[0].Name,
            'Incorrect Name value of result CC record'
        );
    }

    @isTest
    static void testMatchTaxLocationsToBillingCodes() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Account__c => acc.Id,
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Product2 productMonthly = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_PHONE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

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

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => q.Id,
                QuoteLineItem.Product2Id => productMonthly.Id,
                QuoteLineItem.PricebookEntryId => standartPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.UnitPrice => 10
            })
            .quantity(3)
            .create()
            .getRecords();

        Tax_Location__c tl = (Tax_Location__c) new SObjectBuilder(Tax_Location__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Tax_Location__c.Name => 'test tax location',
                Tax_Location__c.Country__c => 'United States',
                Tax_Location__c.State__c => 'New York',
                Tax_Location__c.City__c => 'Islip Terrace',
                Tax_Location__c.BillingId__c => 'test address Id',
                Tax_Location__c.ZipCode__c => '11752'
            })
            .create()
            .getRecord();

        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center__c.Name => 'test cost center',
                Cost_Center__c.Quote__c => q.Id,
                Cost_Center__c.Tax_Location__c => tl.Id,
                Cost_Center__c.AddressId__c => 'test address Id',
                Cost_Center__c.BillingId__c => 'test billing id'
            })
            .create()
            .getRecord();

        List<Cost_Center_Line_Item__c> ccliList = (List<Cost_Center_Line_Item__c>) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center_Line_Item__c.Name => 'test cost center',
                Cost_Center_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideParents(qlis),
                Cost_Center_Line_Item__c.Cost_Center__c => costCenter.Id,
                Cost_Center_Line_Item__c.Quantity__c => 3
            })
            .quantity(3)
            .create()
            .getRecords();
        Triggers.switchOn();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'getCostCenterItems';
        params.quoteId = q.Id;


        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        QuoteService.quote();

        String body = RestContext.response.responseBody.toString();
        List<BillingWrappers.BillingCode> result = (List<BillingWrappers.BillingCode>)JSON.deserialize(
            body,
            List<BillingWrappers.BillingCode>.class
        );
        BillingWrappers.BillingCode bc = result.get(0);

        BillingWrappers.Address bAddress = new BillingWrappers.Address();
        bAddress.id = 'test address Id';
        bAddress.externalId = 'externalId';
        bAddress.address = bc.location;
        List<BillingWrappers.Address> bAddressesList = new List<BillingWrappers.Address>{bAddress};

        Test.startTest();
        Map<String, Tax_Location__c> taxLocationsMap = QuoteService.matchTaxLocationsToBillingCodes(result, bAddressesList);
        Test.stopTest();

        System.assertEquals(
            1,
            taxLocationsMap.size(),
            'Result Map should contain only ONE pair of key-value'
        );
        System.assertEquals(
            'test tax location',
            taxLocationsMap.get('test address Id').Name,
            'Incorrect population of Name in Tax Location'
        );
        System.assertEquals(
            'Islip Terrace',
            taxLocationsMap.get('test address Id').City__c,
            'Incorrect population of City in Tax Location'
        );
        System.assertEquals(
            'New York',
            taxLocationsMap.get('test address Id').State__c,
            'Incorrect population of State in Tax Location'
        );
        System.assertEquals(
            '11752',
            taxLocationsMap.get('test address Id').ZipCode__c,
            'Incorrect population of ZipCode in Tax Location'
        );
        System.assertEquals(
            'United States',
            taxLocationsMap.get('test address Id').Country__c,
            'Incorrect population of Country in Tax Location'
        );
        System.assertEquals(
            'test address Id',
            taxLocationsMap.get('test address Id').BillingId__c,
            'Incorrect population of BillingId in Tax Location'
        );
    }

    @isTest
    static void testMatchBillingCodesFromBillingApi() {

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setField(NGBS_Settings__c.CostCenterNestingLevel__c, 4)
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingPostalCode, '123890')
            .setField(Account.BillingCountry, 'US')
            .setField(Account.BillingState, 'NY')
            .setField(Account.BillingCity, 'NYC')
            .setField(Account.BillingStreet, 'Wall street')
            .setField(Account.Billing_ID__c, 'some_billing_id')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Quote q = NGBSTestDataGenerator.createQuote(opp.Id, QuoteHelper.STATUS_UPSELL);

        String testAddressId = 'someAddressId';

        List<Map<String, String>> billingCodePathList = new List<Map<String, String>>();

        BillingWrappers.BillingCode testBillingCode1 = new BillingWrappers.BillingCode();
        testBillingCode1.Id = 'testCostCenterBillingId';
        testBillingCode1.name = 'testName';
        testBillingCode1.addressId = testAddressId;
        billingCodePathList.add(new Map<String, String>{'name' => testBillingCode1.name, 'code' => 'testCode1'});
        testBillingCode1.billingCodePath = JSON.serialize(billingCodePathList);

        BillingWrappers.BillingCode testBillingCode2 = new BillingWrappers.BillingCode();
        testBillingCode2.Id = 'testCostCenterBillingId2';
        testBillingCode2.name = 'testName2';
        testBillingCode2.parentBillingId = 'testCostCenterBillingId';
        testBillingCode2.addressId = testAddressId;
        billingCodePathList.add(new Map<String, String>{'name' => testBillingCode2.name, 'code' => 'testCode2'});
        testBillingCode2.billingCodePath = JSON.serialize(billingCodePathList);

        BillingWrappers.BillingCode testBillingCode3 = new BillingWrappers.BillingCode();
        testBillingCode3.Id = 'testCostCenterBillingId3';
        testBillingCode3.name = 'testName3';
        testBillingCode3.parentBillingId = 'testCostCenterBillingId2';
        testBillingCode3.addressId = testAddressId;
        billingCodePathList.add(new Map<String, String>{'name' => testBillingCode3.name, 'code' => 'testCode3'});
        testBillingCode3.billingCodePath = JSON.serialize(billingCodePathList);

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'matchBillingCodesFromBillingApi';
        params.quoteId = q.Id;
        params.billingCodes = new List<BillingWrappers.BillingCode>{
            testBillingCode1, testBillingCode2, testBillingCode3
        };
        params.taxLocations = NGBSTestDataGenerator.generateTestTaxLocationResponse(testAddressId);

        Test.startTest();
            RestContext.request = new RestRequest();
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
            QuoteService.quote();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();

        System.assert(!responseBody.contains('stacktrace'), 'matchBillingCodesFromBillingApi call shoud be successful');

        List<Cost_Center__c> costCenterList = [SELECT Id, Name,
                Cost_Center_Parent__c, Billing_Code_Path__c,
                Parent_Billing_Id__c, Tax_Location__c
            FROM Cost_Center__c
            WHERE Quote__c = :q.Id];

        System.assertEquals(3, costCenterList.size(), 'Quote should have 3 Cost_Center__c objects');

        Map<String, Cost_Center__c> nameToCostCenterMap = new Map<String, Cost_Center__c>();
        for (Cost_Center__c item : costCenterList) {
            nameToCostCenterMap.put(item.Name, item);
        }
        System.assert(
            nameToCostCenterMap.containsKey(testBillingCode1.name),
            'all billing codes passed as parameters should be saved as Cost_Center__c objects'
        );
        System.assert(
            nameToCostCenterMap.containsKey(testBillingCode2.name),
            'all billing codes passed as parameters should be saved as Cost_Center__c objects'
        );
        System.assert(
            nameToCostCenterMap.containsKey(testBillingCode3.name),
            'all billing codes passed as parameters should be saved as Cost_Center__c objects'
        );

        Cost_Center__c topLevelCostCenter = nameToCostCenterMap.get(testBillingCode1.name);
        Cost_Center__c costCenterChild1 = nameToCostCenterMap.get(testBillingCode2.name);
        Cost_Center__c costCenterChild2 = nameToCostCenterMap.get(testBillingCode3.name);

        System.assertEquals(
            topLevelCostCenter.Cost_Center_Parent__c,
            null,
            'top-level cost center should have empty Cost_Center_Parent__c field'
        );
        System.assertEquals(
            topLevelCostCenter.Id,
            costCenterChild1.Cost_Center_Parent__c,
            'second-level cost center should have top-level cost center as Cost_Center_Parent__c '
        );
        System.assertEquals(
            costCenterChild1.Id,
            costCenterChild2.Cost_Center_Parent__c,
            'third-level cost center should have second-level cost center as Cost_Center_Parent__c '
        );

        List<Tax_Location__c> taxLocations = [SELECT Id, Name, BillingId__c, Country__c FROM Tax_Location__c];
        System.assertEquals(1, taxLocations.size(), '1 Tax_Location__c should be created');

        Tax_Location__c createdTaxLocation = taxLocations.get(0);
        System.assertEquals(
            testAddressId,
            createdTaxLocation.BillingId__c,
            'BillingId__c field should have value from address id'
        );

        System.assertEquals(
            createdTaxLocation.Id,
            topLevelCostCenter.Tax_Location__c,
            'created Cost_Center__c should have associated Tax_Location__c record'
        );
        System.assertEquals(
            createdTaxLocation.Id,
            costCenterChild1.Tax_Location__c,
            'created Cost_Center__c should have associated Tax_Location__c record'
        );
        System.assertEquals(
            createdTaxLocation.Id,
            costCenterChild2.Tax_Location__c,
            'created Cost_Center__c should have associated Tax_Location__c record'
        );
    }

    @isTest
    static void testUpdateQuoteWithPaymentMethod() {

        User swpWws = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testqq',
                    User.Username => 'qq!user@gmail.com',
                    User.Email => 'qq@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setField(RingCentralVariousSettings__c.SVP_WWS_User_ID__c, swpWws.Id)
            .create();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        BillingWrappers.QuoteWrapper testQuoteWrapper = new BillingWrappers.QuoteWrapper();
        testQuoteWrapper.id = testQuote.Id;
        testQuoteWrapper.packageInfo = NGBSTestDataGenerator.generateQuotePackageInfo();
        testQuoteWrapper.name = 'test';
        testQuoteWrapper.autoRenewal = false;
        testQuoteWrapper.paymentMethod = QuoteHelper.PAYMENT_METHOD_INVOICE;

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'update';
        params.opportunityId = opp.Id;
        params.quote = testQuoteWrapper;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();

            QuoteService.quote();

            String body = RestContext.response.responseBody.toString();
            List<Quote> result = (List<Quote>)JSON.deserialize(body, List<Quote>.class);

            System.assertEquals(
                QuoteHelper.PAYMENT_METHOD_INVOICE,
                result.get(0).PaymentMethod__c,
                'Quote should have "Invoice" payment method'
            );

        Test.stopTest();
    }

    @isTest
    static void testUpdatePackageWithPaymentMethod() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'updatePackage';
        params.quoteId = billingQuote.Id;
        params.opportunityId = opp.Id;
        params.paymentMethod = QuoteHelper.PAYMENT_METHOD_CREDIT_CARD;
        params.isPrimaryQuote = true;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        Test.startTest();

            QuoteService.quote();

            String body = RestContext.response.responseBody.toString();
            List<Quote> quotes = (List<Quote>) JSON.deserialize(body, List<Quote>.class);

            System.assertEquals(
                QuoteHelper.PAYMENT_METHOD_CREDIT_CARD,
                quotes.get(0).PaymentMethod__c,
                'Quote should have "CreditCard" payment method'
            );

        Test.stopTest();
    }

    @isTest
    static void testAutoSubmitPOCApprovalWithTargetPrice() {

        POC_GOA__c pocGoaCustomSetting = (POC_GOA__c) new SObjectBuilder(POC_GOA__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                POC_GOA__c.Sales_Rep__c => '1-5',
                POC_GOA__c.Direct_Manager__c => '6-25',
                POC_GOA__c.Segment_Leader__c => '0-0',
                POC_GOA__c.SVP_WWS_Directs__c => '26-50',
                POC_GOA__c.SVP_WWS__c => '51-9999'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c, true)
            .create();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('TestOpportunity'),
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Professional',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote pocQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test POC Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => Quote.SObjectType.getDescribe().getRecordTypeInfosByName().get('POC Quote').getRecordTypeId(),
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'createPOCApproval';
        params.quoteId = pocQuote.Id;
        params.opportunityId = opp.Id;
        params.data = new Map<String, String>{
            'linkToSignedAgreement' => 'http://testlink'
        };

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            QuoteService.quote();
        Test.stopTest();
        List<Approval__c> pocApprovals = new ApprovalSelector()
            .selectPOCApprovalsForQW(params.opportunityId)
            .executeQuery();

        System.assertEquals(1, pocApprovals.size(), 'new POC Approval record should be created');
        System.assertEquals(
            ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
            pocApprovals[0].Status__c,
            'POC Approval should have PendingL1Approval status as it was automatically submitted for approval'
        );
    }

    @isTest
    static void testAutoSubmitPOCApprovalWithoutTargetPrice() {
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

        POC_GOA__c pocGoaCustomSetting = (POC_GOA__c) new SObjectBuilder(POC_GOA__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                POC_GOA__c.Sales_Rep__c => '1-5',
                POC_GOA__c.Direct_Manager__c => '6-25',
                POC_GOA__c.Segment_Leader__c => '0-0',
                POC_GOA__c.SVP_WWS_Directs__c => '26-50',
                POC_GOA__c.SVP_WWS__c => '51-9999'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c, false)
            .create();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('TestOpportunity'),
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Professional',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote pocQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test POC Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => Quote.SObjectType.getDescribe().getRecordTypeInfosByName().get('POC Quote').getRecordTypeId(),
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'createPOCApproval';
        params.quoteId = pocQuote.Id;
        params.opportunityId = opp.Id;
        params.data = new Map<String, String>{
            'linkToSignedAgreement' => 'http://testlink'
        };

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            System.runAs(testUser) {
                QuoteService.quote();
            }
        Test.stopTest();
        List<Approval__c> pocApprovals = new ApprovalSelector()
            .selectPOCApprovalsForQW(params.opportunityId)
            .executeQuery();

        System.assertEquals(1, pocApprovals.size(), 'new POC Approval record should be created');
        System.assertEquals(
            ApprovalHelper.STATUS_REQUIRED,
            pocApprovals[0].Status__c,
            'POC Approval should have Required status as Target Price functionality was disabled, approval was not autosubmitted'
        );
    }

    @isTest
    static void testGetDQHistory() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c, true)
            .create();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDQDealQualification = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        List<DQ_Deal_Qualification_History__c> testDQHistoryList =
            (List<DQ_Deal_Qualification_History__c>) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => testDQDealQualification.Id,
                        DQ_Deal_Qualification_History__c.Status__c => ValueProviderBuilder.provideList(new List<String>{
                            'Approved', 'Rejected'
                        })
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

        new SObjectBuilder(DQ_Deal_Qualification_Discount_History__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_Discount_History__c.DQ_Deal_Qualification_History__c =>
                        ValueProviderBuilder.provideList(new List<Id>{
                            testDQHistoryList[0].Id, testDQHistoryList[1].Id
                        })
                }
        )
            .quantity(2)
            .create();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'getDQHistory';
        params.opportunityId = testOpp.Id;

        Test.startTest();
            RestRequest request = new RestRequest();
            request.requestBody = Blob.valueOf(JSON.serialize(params));
            RestContext.request = request;
            QuoteService.quote();
            String body = RestContext.response.responseBody.toString();
        Test.stopTest();

        List<DQ_Deal_Qualification_History__c> result =
            (List<DQ_Deal_Qualification_History__c>) JSON.deserialize(body, List<DQ_Deal_Qualification_History__c>.class);
        System.assert(!String.isBlank(body), 'Qualification History JSON should not be empty');
        System.assert(!result.isEmpty(), 'Approved Qualification History record should be obtained');
        System.assert(!result[0].DQ_Deal_Qualification_Discounts_History__r.isEmpty(), 'Discount History records should be obtained');
    }

    @isTest
    static void testAutoSubmitPOCApprovalWithPermissionSet() {

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object>{
                User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                User.LastName => 'Test AutoSubmitPOCApprovalWithPermissionSet'
            })
            .create()
            .getRecord();

        PermissionSet permSet = (PermissionSet) new PermissionSetSelector()
            .selectPermissionSetsByName(new List<Object>{new List<String>{CustomPermissionHelper.PERMISSION_TARGET_PRICE_AND_DQ_GOA}})
            .executeQuery()
            .get(0);

        new SObjectBuilder(PermissionSetAssignment.SObjectType)
            .setField(PermissionSetAssignment.PermissionSetId, permSet.Id)
            .setField(PermissionSetAssignment.AssigneeId, testUser.Id)
            .create();

        System.runAs(testUser) {
            POC_GOA__c pocGoaCustomSetting = (POC_GOA__c) new SObjectBuilder(POC_GOA__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    POC_GOA__c.Sales_Rep__c => '0-0',
                    POC_GOA__c.Direct_Manager__c => '0-0',
                    POC_GOA__c.Segment_Leader__c => '0-0',
                    POC_GOA__c.SVP_WWS_Directs__c => '0-0',
                    POC_GOA__c.SVP_WWS__c => '0-9999'
                })
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('TestOpportunity'),
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => 'Professional',
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                })
                .create()
                .getRecord();

            Quote salesQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.Account__c => opp.AccountId,
                    Quote.OpportunityId => opp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.isPrimary__c => true,
                    Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId()
                })
                .create()
                .getRecord();

            BillingWrappers.Params params = new BillingWrappers.Params();
            params.action = 'createPOCApproval';
            params.quoteId = salesQuote.Id;
            params.opportunityId = opp.Id;
            params.data = new Map<String, String>{
                'linkToSignedAgreement' => 'http://testlink'
            };

            RestRequest request = new RestRequest();
            request.requestBody = Blob.valueOf(JSON.serialize(params));
            RestContext.request = request;

            Test.startTest();
                QuoteService.quote();
            Test.stopTest();
            List<Approval__c> pocApprovals = new ApprovalSelector()
                .selectPOCApprovalsForQW(params.opportunityId)
                .executeQuery();

            System.assertEquals(1, pocApprovals.size(), 'new POC Approval record should be created');
            System.assertEquals(
                ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
                pocApprovals[0].Status__c,
                'POC Approval should have PendingL1Approval status as it was automatically submitted for approval'
            );
        }
    }

    @isTest
    static void testSubmitPocApproval() {
        POC_GOA__c pocGoaCustomSetting = (POC_GOA__c) new SObjectBuilder(POC_GOA__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                POC_GOA__c.Sales_Rep__c => '0-0',
                POC_GOA__c.Direct_Manager__c => '0-0',
                POC_GOA__c.Segment_Leader__c => '0-0',
                POC_GOA__c.SVP_WWS_Directs__c => '0-0',
                POC_GOA__c.SVP_WWS__c => '0-9999'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c, true)
            .create();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('TestOpportunity'),
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Professional',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote pocQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test POC Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => Quote.SObjectType.getDescribe().getRecordTypeInfosByName().get('POC Quote').getRecordTypeId(),
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Approval__c pocApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.Account__c => opp.AccountId,
                Approval__c.Opportunity__c => opp.Id,
                Approval__c.POC_Application_Form__c => 'http://testlink',
                Approval__c.Number_of_POC_Users__c => 1,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_POC_ACCOUNT
            })
            .create()
            .getRecord();

        Test.startTest();
            QuoteService.submitPocApproval(pocApproval.Id);
        Test.stopTest();
        List<Approval__c> pocApprovals = new ApprovalSelector()
            .selectPOCApprovalsForQW(opp.Id)
            .executeQuery();

        System.assertEquals(1, pocApprovals.size(), 'new POC Approval record should be created');
        System.assertEquals(
            ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
            pocApprovals[0].Status__c,
            'POC Approval should have PendingL1Approval status as it was automatically submitted for approval'
        );
    }

    @isTest
    static void testIsOpportunityFieldsChanged() {
        System.assertEquals(
            false,
            QuoteService.isOpportunityFieldsChanged(null, null),
            'QuoteService.isOpportunityFieldsChanged method should return false if passed params are null'
        );
        System.assertEquals(
            false,
            QuoteService.isOpportunityFieldsChanged(new Opportunity(), new Opportunity()),
            'QuoteService.isOpportunityFieldsChanged method should return false if the values of the fields ' +
            'ProvisioningDetails__c, SelfProvisioned__c, NumberToBeRCMainNumber__c, NumberToBeCCNumber__c, isTermination__c are the same'
        );

        Opportunity existingOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.ProvisioningDetails__c => 'some details',
                Opportunity.SelfProvisioned__c => false,
                Opportunity.NumberToBeRCMainNumber__c => '0001',
                Opportunity.NumberToBeCCNumber__c => '0002',
                Opportunity.isTermination__c => false
            })
            .build()
            .getRecord();

        Opportunity updatedOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.ProvisioningDetails__c => 'some updated details',
                Opportunity.SelfProvisioned__c => true,
                Opportunity.NumberToBeRCMainNumber__c => '0002',
                Opportunity.NumberToBeCCNumber__c => '0003',
                Opportunity.isTermination__c => true
            })
            .build()
            .getRecord();

        System.assertEquals(
            true,
            QuoteService.isOpportunityFieldsChanged(existingOpp, updatedOpp),
            'QuoteService.isOpportunityFieldsChanged method should return true if the values of the fields ' +
            'ProvisioningDetails__c, SelfProvisioned__c, NumberToBeRCMainNumber__c, NumberToBeCCNumber__c, isTermination__c is differs'
        );
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testCheckAndUpdateOpportunity() {
        Boolean isUpdated = false;
        Boolean hasRCCC = false;
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.ProvisioningDetails__c => 'some details',
                Opportunity.SelfProvisioned__c => false,
                Opportunity.NumberToBeRCMainNumber__c => '0001',
                Opportunity.NumberToBeCCNumber__c => '0002',
                Opportunity.isTermination__c => false
            })
            .create()
            .getRecord();

        // check Opportunity record is not updated
        BillingWrappers.QuoteWrapper wrapper = new BillingWrappers.QuoteWrapper();
        wrapper.opportunityProvisioningDetails = opp.ProvisioningDetails__c;
        wrapper.opportunitySelfProvisioned = opp.SelfProvisioned__c;
        wrapper.rcAccountNumber = opp.NumberToBeRCMainNumber__c;
        wrapper.ccAccountNumber = opp.NumberToBeCCNumber__c;
        wrapper.isTerminationOpportunity = opp.isTermination__c;

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.isPrimary__c, true)
            .build()
            .getRecord();
        qt.putSObject('Opportunity', opp);

        Test.startTest();
            QuoteService.checkAndUpdateOpportunity(qt, wrapper, hasRCCC);
            assertCheckAndUpdateOpportunity(wrapper, opp.Id, isUpdated, hasRCCC);

            // check Opportunity record is updated
            wrapper.opportunityProvisioningDetails = 'some updated details';
            wrapper.opportunitySelfProvisioned = true;
            wrapper.rcAccountNumber = '1111';
            wrapper.ccAccountNumber = '2222';
            wrapper.isTerminationOpportunity = true;

            hasRCCC = true;
            QuoteService.checkAndUpdateOpportunity(qt, wrapper, hasRCCC);        
        Test.stopTest();

        isUpdated = true;
        assertCheckAndUpdateOpportunity(wrapper, opp.Id, isUpdated, hasRCCC);
    }

    @IsTest
    private static void testMakePrimaryQuoteUpdateTerminationOnTechnicalOpportunities() {
        List<String> serviceList = new List<String>{
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
        };

        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceList);
        Map<String, Opportunity> serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(masterOpp.Id, serviceAccounts, serviceList);

        Test.startTest();
            List<Quote> testMasterQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
                .setField(Quote.IsPrimary__c, ValueProviderBuilder.provideList(new List<Boolean>{true, false}))
                .setField(Quote.OpportunityId, masterOpp.Id)
                .setField(Quote.IsMultiProductTechnicalQuote__c, false)
                .setField(Quote.Package_Info__c, PACKAGE_INFO_WITH_CONTRACT)
                .quantity(2)
                .create()
                .getRecords();

            List<Quote> testTechnicalQuotesPrimaryMasterQuote = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
                .setField(Quote.IsPrimary__c, false)
                .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{serviceOpportunities.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id, serviceOpportunities.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Id, serviceOpportunities.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id }))
                .setField(Quote.MasterQuote__c, testMasterQuotes[0].Id)
                .setField(Quote.ServiceName__c, ValueProviderBuilder.provideList(new List<String>{
                    QuoteHelper.NGBS_RCCC_PRODUCT,
                    QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
                    QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
                }))
                .setField(Quote.IsMultiProductTechnicalQuote__c, true)
                .setField(Quote.IsTermination__c, ValueProviderBuilder.provideList(new List<Boolean>{false, false, false}))
                .quantity(3)
                .create()
                .getRecords();

            List<Quote> testTechnicalQuotesNonPrimaryMasterQuote = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
                .setField(Quote.IsPrimary__c, false)
                .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{serviceOpportunities.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id, serviceOpportunities.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Id, serviceOpportunities.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id }))
                .setField(Quote.MasterQuote__c, testMasterQuotes[1].Id)
                .setField(Quote.ServiceName__c, ValueProviderBuilder.provideList(new List<String>{
                    QuoteHelper.NGBS_RCCC_PRODUCT,
                    QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
                    QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
                }))
                .setField(Quote.IsMultiProductTechnicalQuote__c, true)
                .setField(Quote.IsTermination__c, ValueProviderBuilder.provideList(new List<Boolean>{true, true, true}))
                .quantity(3)
                .create()
                .getRecords();

            BillingWrappers.Params params = new BillingWrappers.Params();
            params.opportunityId = masterOpp.Id;
            params.quoteId = testMasterQuotes[1].Id;

            QuoteService.makePrimaryQuote(params);
        Test.stopTest();
        Map<String, Opportunity> reselectedTechnicalOpportunitiesMap = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterOpp.Id);

        System.assertEquals(
            true, reselectedTechnicalOpportunitiesMap.get(QuoteHelper.NGBS_RCCC_PRODUCT).isTermination__c,
            'RingCentral Contact Center technical opportunity should be terminated'
        );

        System.assertEquals(
            true, reselectedTechnicalOpportunitiesMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).isTermination__c,
            'Engage Digital Standalone technical opportunity should be terminated'
        );
        System.assertEquals(
            true, reselectedTechnicalOpportunitiesMap.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).isTermination__c,
            'Engage Voice Standalone technical opportunity should be terminated'
        );
    }

    @IsTest
    private static void testUpdateLBOForQuotes() {
        String packageInfo = '[{"id":"65","version":"1",' +
            '"packageInfo":{"catalogId":"65","version":"1",' +
            '"name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024",' +
            '"displayName":"RingCentral Office Standard"},' +
            '"productName":"Office","duration":"Monthly",' +
            '"edition":{"id":1,"name":"Standard"},"contract":null,' +
            '"offerType":"Regular","poc":null,"globalPackageLimits":' +
            '[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT",' +
            '"name":"Monthly money amount limit",' +
            '"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
            '"target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
            '"override":false}],"permissions":null}]';
        Triggers.switchOff();
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
                Opportunity.Tier_Name__c => 'Professional',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Quote For Tests',
                Quote.OpportunityId => testOpp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Enabled_LBO__c => false,
                Quote.Package_Info__c => packageInfo
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.opportunityId = testOpp.Id;
        params.isWizardHasErrors = false;

        Test.startTest();
            QuoteService.updateLBOForQuotes(params);
        Test.stopTest();

        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotesForShippingByOppIds(new List<Id>{ testOpp.Id })
            .executeQuery();

        System.assertEquals(
            true, quotes[0].Enabled_LBO__c,
            'EnabledLBO field on quote should be true'
        );
    }

    @isTest
    static void testPopulateContractTermsOnQuoteCreation() {

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => 'Test Oppty',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        String pInfoJson = NGBSTestDataGenerator.generateQuotePackageInfo()
                .replace('"contract":null', '"contract":{"id":"some_sf_id","extId":"Office_5_US","billingId":"some_billingId"}');

        BillingWrappers.Params salesParams = new BillingWrappers.Params();
            salesParams.action = 'createSalesQuote';
            salesParams.opportunityId = testOpp.Id;
            salesParams.packageInfo = pInfoJson;
            salesParams.initialTerm = '24';
            salesParams.renewalTerm = '24';
            salesParams.isPRMQuote = false;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(salesParams));

        QuoteService.quote();

        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectField(Quote.Initial_Term_months__c)
            .selectField(Quote.Term_months__c)
            .setCondition('OpportunityId = \'' + testOpp.Id + '\'')
            .executeQuery()
            .get(0);

        System.assertEquals(
            salesParams.initialTerm,
            reselectedQuote.Initial_Term_months__c,
            'Initial_Term_months__c field value should be equal to initialTerm passed in params'
        );
        System.assertEquals(
            salesParams.renewalTerm,
            reselectedQuote.Term_months__c,
            'Term_months__c field value should be equal to renewalTerm passed in params'
        );
    }

    @isTest
    static void testEngageProservIgnite() {

        Email_Configuration__c settings = new Email_Configuration__c(
            CC_Emails_Ignite_Quote_Creation__c = 'test_partners.sales@ringcentral.com'
        );
        insert settings;

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOppNB = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.PartnerProgram__c => 'Ignite'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.PartnerProgram__c => 'Ignite'
            })
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate()
            })
            .quantity(1)
            .create()
            .getRecords();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'engageProServIgnite';
        params.opportunityId = testOpp.Id;
        params.data = new Map<String, String>{
            'type' => 'ProServ',
            'proServCaseReasons' => 'Video / Rooms in a Box',
            'selectedQuoteId' => testQuotes[0].Id
        };

        Test.startTest();
            RestContext.request = new RestRequest();
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
            QuoteService.quote();
            Integer numOfEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectField(Quote.ProServ_Details__c)
            .setCondition('Id = \'' + testQuotes[0].Id + '\'')
            .executeQuery()
            .get(0);

        System.assertEquals(1, numOfEmailInvocations, 'Email should be sent');
        System.assertEquals(QuoteHelper.STATUS_PRO_SERV_IGNITE_INITIATED, reselectedQuote.ProServ_Details__c, 'ProServ_Details__c field should has info, that ProServ was initiated from PRM');
    }

    @isTest
    static void testCancelProservIgnite() {

        Email_Configuration__c settings = new Email_Configuration__c(
            CC_Emails_Ignite_Quote_Creation__c = 'test_partners.sales@ringcentral.com'
        );
        insert settings;
        Triggers.switchOff();
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOppNB = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.PartnerProgram__c => 'Ignite'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.PartnerProgram__c => 'Ignite'
            })
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate()
            })
            .quantity(1)
            .create()
            .getRecords();
        Triggers.switchOn();
        
        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'cancelProServIgnite';
        params.opportunityId = testOpp.Id;
        params.data = new Map<String, String>{
            'type' => 'ProServ',
            'proServCaseReasons' => 'Video / Rooms in a Box',
            'selectedQuoteId' => testQuotes[0].Id
        };

        Test.startTest();
            RestContext.request = new RestRequest();
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
            QuoteService.quote();
            Integer numOfEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectField(Quote.ProServ_Details__c)
            .setCondition('Id = \'' + testQuotes[0].Id + '\'')
            .executeQuery()
            .get(0);

        System.assertEquals(1, numOfEmailInvocations, 'Email should be sent');
        System.assertEquals(QuoteHelper.STATUS_PRO_SERV_IGNITE_CANCELLED, reselectedQuote.ProServ_Details__c, 'ProServ_Details__c field should has info, that ProServ was cancelled from PRM');
    }

    @isTest
    static void testGetProservDetail() {
        Triggers.switchOff();
        Account testAccount = TestDataGenerator.createAccount('test Account');
        Opportunity testOpp = TestDataGenerator.createOpportunity(testAccount);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        ProServ_Project__c testProject = (ProServ_Project__c) new SObjectBuilder(ProServ_Project__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                ProServ_Project__c.Account__c => testAccount.Id,
                ProServ_Project__c.Quote__c => testQuote.Id,
                ProServ_Project__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.Name => 'Test Order',
                Order.AccountId => testAccount.Id,
                Order.Status => 'New',
                Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                Order.EffectiveDate => System.today(),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.ProServProject__c => testProject.Id,
                Order.CurrencyIsoCode => 'USD',
                Order.OpportunityId => testOpp.Id
            })
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Test ProServ Package',
                Package__c.Account_Package_Id__c => '12345',
                Package__c.Account__c => testAccount.Id,
                Package__c.Enterprise_Account_ID__c => testAccount.Id,
                Package__c.Package_Catalog_Id__c => '12345',
                Package__c.Service_Type__c => PackageHelper.PROSERV_SERVICE_TYPE,
                Package__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        BillingWrappers.Params params = new BillingWrappers.Params();
                params.action = 'getProservDetail';
                params.opportunityId = testOpp.Id;

        Test.startTest();
            RestContext.request = new RestRequest();
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
            QuoteService.quote();
        Test.stopTest();

        BillingWrappers.ProservParam proservParam = (BillingWrappers.ProservParam) JSON.deserialize(RestContext.response.responseBody.toString(), BillingWrappers.ProservParam.class);
        System.assertEquals(true, proservParam.isSignUpCompleted, 'isSignUpCompleted should be true');
        System.assertEquals('12345', proservParam.accountPackageId, 'accountPackageId should be 12345');
    }
}