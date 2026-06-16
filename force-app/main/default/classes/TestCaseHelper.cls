@isTest
private class TestCaseHelper {
    // Use in order to test simple functionality without inserting a case
    private class TestCaseGenerator {
        private Case testCase;

        public TestCaseGenerator() {
            this(CaseHelper.CASE_STATUS_NEW, false);
        }

        public TestCaseGenerator(Datetime createdDate) {
            this(CaseHelper.CASE_STATUS_NEW, false, createdDate, Datetime.now());
        }

        public TestCaseGenerator(String status, Boolean isClosed) {
            this(status, isClosed, Datetime.now(), Datetime.now());
        }

        public TestCaseGenerator(String status, Boolean isClosed, Datetime createdDate, Datetime closedDate) {
            Id dummyCaseId = (Id) new ValueProvider.DummyIdProvider(Case.sObjectType).getValue();
            String caseJsonFirst =
                '{"attributes":{"type":"Case","url":"/services/data/v56.0/sobjects/Case/' + dummyCaseId + '"},';
            String caseJSONSecond = String.format(
                '"Id":"{0}","Subject":"Test Subject","IsEscalated":false,"Status":"{1}","IsClosed":{2},"CreatedDate":{3},"ClosedDate":{4}}',
                new List<String> {dummyCaseId,
                                 status,
                                 JSON.serialize(isClosed),
                                 JSON.serialize(createdDate),
                                 JSON.serialize(closedDate)}
            );
            this.testCase = (Case) JSON.deserialize(caseJsonFirst + caseJSONSecond, Case.class);
        }

        public Case getCase() {
            return this.testCase;
        }
    }

    static Account createAccount() {
        return (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.recordtypeId => Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId(),
                    Account.Name => 'Test Account',
                    Account.RC_User_ID__c => '12345',
                    Account.Number_of_DL_s__c => 10,
                    Account.RC_Brand__c => 'RingCentral'
                }
            )
            .create()
            .getRecord();
    }

    static Contact createContact(Account acc) {
        return (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .create()
            .getRecord();
    }

    static Case createCase(Account acc, Contact cont, Id ownerId, Id recordTypeId) {
        return (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => recordTypeId,
                    Case.AccountId => acc.Id,
                    Case.ContactId => cont.Id,
                    Case.Subject => 'Test',
                    Case.Description => 'Test',
                    Case.Origin => 'Phone',
                    Case.OwnerId => ownerId
                }
            )
            .create()
            .getRecord();
    }

    static User createUser() {
        return (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .create()
            .getRecord();
    }

    private static Quote generateDataForManualProvisioningCaseMPUB(){
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Manual Provisioning Case Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, acc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Manual Provisioning Case Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.USD)
            .quantity(1)
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Manual Provisioning Case Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.BillingPackage__c, pkg.Id)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateQuotePackageInfo())
            .quantity(1)
            .create()
            .getRecord();
        opp.PrimaryQuote__c = qt.Id;

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'Manual Provisioning Case Test product')
            .setField(Product2.ExtID__c, ValueProviderBuilder.provideList(new List<String>{'TEST', 'TEST_1', 'TEST_2', null}))
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.IsActive, true)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_MONTHLY)
            .setField(Product2.UpsellType__c, ValueProviderBuilder.provideList(
                new List<String>{
                    Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE,
                    'manual',
                    'testUpsellType',
                    null
                }
            ))
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(PricebookEntry.UnitPrice, 10)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.CurrencyIsoCode, 'USD')
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, qt.Id)
            .setField(QuoteLineItem.Display_Name__c, ValueProviderBuilder.provideUniqueString())
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.ChargeTerm__c, QuoteLineItemHelper.CHARGE_TERM_MONTHLY)
            .setField(QuoteLineItem.UnitPrice, 10)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, false)
            .setField(QuoteLineItem.Zero_Quantity__c, false)
            .quantity(4)
            .create()
            .getRecords();

        List<Order> orderList = (List<Order> ) new SObjectBuilder(Order.SObjectType)
            .setField(Order.AccountId, acc.Id)
            .setField(Order.QuoteId, qt.Id)
            .setField(Order.OpportunityId, opp.Id)
            .setField(Order.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Order.EffectiveDate, System.today())
            .setField(Order.Status, OrderHelper.STATUS_NEW)
            .setField(Order.NumberOfMainLicenses__c, 25)
            .setField(Order.TechnicalAccountId__c, acc.Id)
            .setField(Order.TechnicalOpportunityId__c, opp.Id)
            .setField(Order.TechnicalQuoteId__c, qt.Id)
            .setField(Order.Provisioning__c, ValueProviderBuilder.provideList(
                new List<String>{
                    OrderHelper.PROVISIONING_AUTO,
                    OrderHelper.PROVISIONING_MANUAL
                }
            ))
            .quantity(2)
            .create()
            .getRecords();

        List<OrderItem> orderItemList = (List<OrderItem>) new SObjectBuilder(OrderItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                OrderItem.OrderId => ValueProviderBuilder.provideParents(orderList),
                OrderItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeList),
                OrderItem.Quantity => ValueProviderBuilder.providerRandomDecimal(1, 10, 0),
                OrderItem.UnitPrice => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                OrderItem.QuoteLineItemId => ValueProviderBuilder.provideParents(qliList)
            })
            .quantity(4)
            .create()
            .getRecords();
        Triggers.switchOn();

        return qt;
    }

    @isTest
    static void testRecordTypeNames() {
        System.assertEquals('Support - T1', CaseHelper.RT_NAME_SUPPORT_T1);
        System.assertEquals('Support - T2', CaseHelper.RT_NAME_SUPPORT_T2);
        System.assertEquals('Support - T3', CaseHelper.RT_NAME_SUPPORT_T3);
        System.assertEquals('Support-Case', CaseHelper.RT_NAME_SUPPORT_CASE);
        System.assertEquals('Support - Chat', CaseHelper.RT_NAME_SUPPORT_CHAT);
        System.assertEquals('Support - Glip', CaseHelper.RT_NAME_SUPPORT_GLIP);
        System.assertEquals('Support - Mobile', CaseHelper.RT_NAME_SUPPORT_MOBILE);
        System.assertEquals('Support - Executive Response Team', CaseHelper.RT_NAME_SUPPORT_EXECUTIVE_RESPONSE_TEAM);
        System.assertEquals('Collections Dispute', CaseHelper.RT_COLLECTIONS_DISPUTE);
        System.assertEquals('Support - FeedBack', CaseHelper.RT_NAME_SUPPORT_FEEDBACK);
        System.assertEquals('Support-RC App', CaseHelper.RT_NAME_SUPPORT_RC_APP);
    }

    @isTest
    static void testRecordTypeIds() {
        List<String> recordTypeNames = new List<string>{
            CaseHelper.RT_NAME_SUPPORT_T1,
            CaseHelper.RT_NAME_SUPPORT_T2,
            CaseHelper.RT_NAME_SUPPORT_T3,
            CaseHelper.RT_NAME_SUPPORT_CASE,
            CaseHelper.RT_NAME_SUPPORT_CHAT,
            CaseHelper.RT_NAME_SUPPORT_GLIP,
            CaseHelper.RT_NAME_SUPPORT_MOBILE,
            CaseHelper.RT_NAME_SUPPORT_EXECUTIVE_RESPONSE_TEAM,
            CaseHelper.RT_COLLECTIONS_DISPUTE,
            CaseHelper.RT_NAME_SUPPORT_FEEDBACK,
            CaseHelper.RT_NAME_SUPPORT_RC_APP};

        for (String rtName : recordTypeNames) {
            Schema.RecordTypeInfo rtiByName = CaseHelper.RT_INFO_BY_NAME.get(rtName);
            System.assertNotEquals(null, rtiByName, 'Could not find record type by name ' + rtName);

            Schema.RecordTypeInfo rtiById = CaseHelper.RT_INFO_BY_ID.get(rtiByName.getRecordTypeId());
            System.assertNotEquals(null, rtiById, 'Could not find record type by Id ' + rtName);
        }

        System.assertNotEquals(null, CaseHelper.RT_ID_SUPPORT_T1, 'Should not be null');
        System.assertNotEquals(null, CaseHelper.RT_ID_SUPPORT_RC_APP, 'Should not be null');
        System.assertNotEquals(null, CaseHelper.RT_ID_SUPPORT_T2, 'Should not be null');
        System.assertNotEquals(null, CaseHelper.RT_ID_SUPPORT_FEEDBACK, 'Should not be null');
    }

    @isTest
    static void testCaseStatuses() {
        System.assertEquals('Closed', CaseHelper.CASE_STATUS_CLOSED);
        System.assertEquals('Closed - No Response', CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE);
        System.assertEquals('Cancelled', CaseHelper.CASE_STATUS_CANCELLED);
        System.assertEquals('Duplicate', CaseHelper.CASE_STATUS_DUPLICATE);
        System.assertEquals('Completed', CaseHelper.CASE_STATUS_COMPLETED);
    }

    @isTest
    static void testCaseRtsToReassignOnCaseOwnerInactive() {
        System.assertNotEquals(null, CaseHelper.CASE_RTS_TO_REASSIGN_ON_CASE_OWNER_INACTIVE);
        List<String> statusesMustBeInSet = new List<String>{
            CaseHelper.RT_NAME_SUPPORT_T1,
            CaseHelper.RT_NAME_SUPPORT_T2,
            CaseHelper.RT_NAME_SUPPORT_T3,
            CaseHelper.RT_NAME_SUPPORT_CASE,
            CaseHelper.RT_NAME_SUPPORT_CHAT,
            CaseHelper.RT_NAME_SUPPORT_GLIP,
            CaseHelper.RT_NAME_SUPPORT_MOBILE,
            CaseHelper.RT_NAME_SUPPORT_EXECUTIVE_RESPONSE_TEAM};

        System.assertEquals(statusesMustBeInSet.size(), CaseHelper.CASE_RTS_TO_REASSIGN_ON_CASE_OWNER_INACTIVE.size());

        for (String entry : statusesMustBeInSet) {
            System.assert(CaseHelper.CASE_RTS_TO_REASSIGN_ON_CASE_OWNER_INACTIVE.contains(entry), 'Required record type name was not found');
        }
    }

    @isTest
    static void testCaseStatusesToReassignOnCaseOwnerInactive() {
        System.assertNotEquals(null, CaseHelper.CASE_STATUSES_TO_REASSIGN_ON_CASE_OWNER_INACTIVE);

        List<String> statusesMustBeInSet = new List<String>{
            CaseHelper.CASE_STATUS_CLOSED,
            CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE,
            CaseHelper.CASE_STATUS_CANCELLED,
            CaseHelper.CASE_STATUS_DUPLICATE
        };

        System.assertEquals(statusesMustBeInSet.size(), CaseHelper.CASE_STATUSES_TO_REASSIGN_ON_CASE_OWNER_INACTIVE.size());

        for (String entry : statusesMustBeInSet) {
            System.assert(CaseHelper.CASE_STATUSES_TO_REASSIGN_ON_CASE_OWNER_INACTIVE.contains(entry), 'Required record type name was not found');
        }
    }

    @isTest
    private static void testEngageCaseCreation() {
        Opportunity engageOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.SObjectType),
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                Opportunity.isTermination__c => true
            })
            .create()
            .getRecord();

        Test.startTest();

        Map<String, Group> groupMap = new Map<String, Group>{
            QueueHelper.DEAL_DESK_ENGAGE_QUEUE => new Group(
                Name = QueueHelper.DEAL_DESK_ENGAGE_QUEUE,
                DeveloperName = QueueHelper.DEAL_DESK_ENGAGE_QUEUE
            )
        };
        insert groupMap.values();

        Case engageCase = CaseHelper.buildAssistCase(engageOpp, groupMap);

        Test.stopTest();

        System.assertEquals(
            engageOpp.Id,
            engageCase.Opportunity_Reference__c,
            'Engage Case related to incorrect Opportunity'
        );

        System.assertEquals(
            groupMap.get(QueueHelper.DEAL_DESK_ENGAGE_QUEUE).Id,
            engageCase.OwnerId,
            'Engage Case has wrong Owner'
        );

        System.assertEquals(
            'Salesforce',
            engageCase.Application__c,
            'Engage Case has wrong Application__c'
        );

        System.assertEquals(
            'Systems, Process & Tools',
            engageCase.Case_Category__c,
            'Engage Case has wrong Case_Category__c'
        );

        System.assertEquals(
            'Web',
            engageCase.Origin,
            'Engage Case has wrong Origin'
        );

        System.assertEquals(
            'Level 4 - Medium',
            engageCase.Case_Severity__c,
            'Engage Case has wrong Case_Severity__c'
        );

        System.assertEquals(
            'Engage Digital Account Termination',
            engageCase.Subject,
            'Engage Case with Termination has wrong Subject'
        );
    }

    @isTest
    private static void testGetParamsAsMap(){
        BillingWrappers.CaseCreateParams params = generateCaseParams();
        Map<String, Object> paramsMap = CaseHelper.getParamsAsMap(params);
        System.assertEquals(
            (String) paramsMap.get('subject'),
            params.subject
        );
    }

    @isTest
    private static void testAddCreateCaseFromProServMapFields(){
        BillingWrappers.CaseCreateParams params = generateCaseParams();
        Map<String, Object> paramsMap = CaseHelper.getParamsAsMap(params);
        paramsMap = CaseHelper.addCreateCaseFromProServMapFields(paramsMap);
        System.assertEquals(CaseHelper.RT_ID_PROFESSIONAL_SERVICES, (String) paramsMap.get('RecordTypeId'),'Wrong record type id');
        System.assertEquals(null, (String) paramsMap.get('isFromProServ'), 'isFromProServ has to be removed');
    }

    @isTest
    private static void testAdjustParamsMapFields(){
        BillingWrappers.CaseCreateParams params = generateCaseParams();
        Map<String, Object> paramsMap = CaseHelper.getParamsAsMap(params);
        paramsMap = CaseHelper.adjustParamsMapFields(paramsMap);
        System.assertEquals(params.quoteApprovalId, (String) paramsMap.get('Quote_Approval_ID__c'), 'QuoteApprovalId has to be mapped');
        System.assertEquals(params.opportunityOwnerEmail, (String) paramsMap.get('OpportunityOwnerEmail__c'), 'OpportunityOwnerEmail has to be mapped');
        System.assertEquals(null, (String) paramsMap.get('isFromProServ'), 'isFromProServ has to be removed');
    }

    @isTest
    private static void testBuildCase(){
        BillingWrappers.CaseCreateParams params = generateCaseParams();
        Map<String, Object> paramsAsMap = CaseHelper.getParamsAsMap(params);
        paramsAsMap = CaseHelper.addSalesOrderExceptDescQueueMapFields(paramsAsMap);
        Test.startTest();
        Map<SObjectField, Object> fieldsMap = CaseHelper.buildCaseFieldsMap(paramsAsMap);
        Case caseRecord = CaseHelper.buildCase(fieldsMap);
        Test.stopTest();
        System.assertEquals(
            caseRecord.Subject,
            params.subject
        );
    }

    @isTest
    private static void testDealDeskCaseRouting(){
        BillingWrappers.CaseCreateParams params = generateCaseParams();
        Map<String, Object> paramsAsMap = CaseHelper.getParamsAsMap(params);
        paramsAsMap = CaseHelper.addSalesOrderExceptDescQueueMapFields(paramsAsMap);
        System.assertEquals(paramsAsMap.get('RecordTypeId'),CaseHelper.RT_ID_DEALDESK_CASE);
        System.assertEquals(paramsAsMap.get('OwnerId'),DealDeskCaseGenerator.DEAL_DESK_QUEUE.QueueId);
    }

    @isTest
    private static void testBizServCaseRouting(){
        Profile p = (Profile) new ProfileSelector().selectProfileByName(new List<String>{ProfileHelper.PROFILE_NAME_DEAL_DESK_LIGHTNING})
        .executeQuery()
        .get(0);

        User testUser = new User(alias = 'u111', email='u111@testorg.com',
        emailencodingkey='UTF-8', lastname='Testing11', languagelocalekey='en_US',
        localesidkey='en_US', profileid = p.Id, country='United States',
        timezonesidkey='America/Los_Angeles', username='u111@testorg.com');
        insert testUser;

        BillingWrappers.CaseCreateParams params = generateCaseParams();
        Map<String, Object> paramsAsMap = CaseHelper.getParamsAsMap(params);

        System.runAs(testUser) {
            paramsAsMap = CaseHelper.addSalesOrderExceptDescQueueMapFields(paramsAsMap);
            System.assertEquals(
                paramsAsMap.get('RecordTypeId'),
                CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES
            );
            System.assertEquals(
                paramsAsMap.get('OwnerId'),
                CaseHelper.BIZ_SERV_INNOVATION_TEAM.QueueId
            );
        }
    }

    @isTest
    private static void getCaseSerevity_WhenGetCaseSerevity_ShouldHaveAtLeastOneElement() {

        Test.startTest();
        List<String> severityOptions = CaseHelper.getCaseSeverityOptions();
        Test.stopTest();

        System.assertNotEquals(0, severityOptions.size());
    }

    @isTest
    private static void getSCRecordTypes_WhenGetSCRecordTypes_ShouldHaveAtLeastOneElement() {
        Test.startTest();
            Set<String> SCRecordTypes = CaseHelper.getSCRecordTypes('Main Support Portal');
        Test.stopTest();
        System.assertNotEquals(0, SCRecordTypes.size(), 'There should exist more than one SC Case Record Type metadata in the org');
    }

    private static BillingWrappers.CaseCreateParams generateCaseParams(){
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                    Quote.OpportunityId => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType),
                    Quote.Status => QuoteHelper.QUOTE_STATUS_PRESENTED,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                    Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate()
                }
            )
            .create()
            .getRecord();
        BillingWrappers.CaseCreateParams params = new BillingWrappers.CaseCreateParams();
        params.subject = 'subject';
        params.accountId = (String) ValueProviderBuilder.provideCommonParent(Account.SObjectType).getValue();
        params.contactId = (String) ValueProviderBuilder.provideCommonParent(Contact.SObjectType).getValue();
        params.description = 'Description';
        params.quoteApprovalId = testQuote.Id;
        params.opportunityOwnerEmail = 'testEmail@gmail.com';
        params.isFromProServ = false;

        return params;
    }

    @isTest
    private static void testCaseSelector(){
        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'Unted States',
                Account.RC_User_ID__c => '123456789'
            })
            .create()
            .getRecords();

        List<Contact> contacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'firstname',
                    Contact.LastName => 'lastname',
                    Contact.Email => 'useremail@rc.com',
                    Contact.Phone => '77777777',
                    Contact.Phone_Ext__c => 777,
                    Contact.AccountId => accounts[0].Id
                }
            )
            .create()
            .getRecords();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject => 'test Subject',
                    Case.Case_Severity__c => 'Level 4 - Medium',
                    Case.Description => 'test Description',
                    Case.Status => 'Closed',
                    Case.Site__c => 'test site',
                    Case.ContactId => contacts[0].Id,
                    Case.AccountId => accounts[0].Id
                }
            )
            .create()
            .getRecord();


        cs = (Case) new CaseSelector()
            .selectCases()
            .selectField(Case.CaseNumber)
            .selectField(Case.Id)
            .executeQuery()[0];

        Case csToTest = (Case) new CaseSelector()
            .selectCasesForApproval(new Object[]{new String[]{cs.Id}})
            .selectField(Case.CaseNumber)
            .executeQuery()[0];

        system.assertEquals(cs.CaseNumber, csToTest.CaseNumber, 'Is not the same case');

        csToTest = (Case) new CaseSelector()
            .selectCasesDefault()
            .executeQuery()[0];

        system.assertEquals(cs.Id, csToTest.Id, 'Is not the same case');

        csToTest = (Case) new CaseSelector()
            .selectCasesByStatus(new Object[]{'Closed'})
            .executeQuery()[0];

        system.assertEquals(cs.Id, csToTest.Id, 'Is not the same case');

        csToTest = (Case) new CaseSelector()
            .selectCasesForSCPreview(new Object[]{
                new String[]{'New'},
                accounts[0].Id,
                contacts[0].Id
            })
            .executeQuery()[0];

        system.assertEquals(cs.Id, csToTest.Id, 'Is not the same case');

        csToTest = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new Object[]{
                new String[]{cs.Id}
            })
            .selectField(Case.CaseNumber)
            .executeQuery()[0];

        system.assertEquals(cs.CaseNumber, csToTest.CaseNumber, 'Is not the same case');

        csToTest = (Case) new CaseSelector(false, false)
            .selectCaseByIdWithCommentsAttachmentsAndContactData(new Object[]{
                cs.Id
            })
            .executeQuery()[0];

        system.assertEquals(cs.Id, csToTest.Id, 'Is not the same case');

        csToTest = (Case) new CaseSelector(false, false)
            .selectCaseForEscalating(new Object[]{cs.Id})
            .executeQuery()[0];

        system.assertEquals(cs.Id, csToTest.Id, 'Is not the same case');

        csToTest = (Case) new CaseSelector(false, false)
            .selectCaseForReopening(new Object[]{cs.Id})
            .executeQuery()[0];

        system.assertEquals(cs.Id, csToTest.Id, 'Is not the same case');

        csToTest = (Case) new CaseSelector(false, false)
            .selectCasesIcbByNumber(new String[]{cs.CaseNumber})
            .executeQuery()[0];

        system.assertEquals(cs.Id, csToTest.Id, 'Is not the same case');

        csToTest = (Case) new CaseSelector(false, false)
            .selectInContactCasesForOpportunities(new String[]{null})
            .executeQuery()[0];

        system.assertEquals(cs.Id, csToTest.Id, 'Is not the same case');
    }

    @isTest
    static void testCreateRestResponse() {
        RestContext.response = null;

        Test.startTest();
            CaseHelper.createRestResponse();
        Test.stopTest();

        System.assertNotEquals(null, RestContext.response);
    }

    @isTest
    static void testCreateICBCase() {
        IcbHelper.ICBRequestCaseBody caseBody = new IcbHelper.ICBRequestCaseBody();
        caseBody.subject = 'Test ICB Case';
        caseBody.defaultTimeZone = 'GMT';
        caseBody.geoRegion = CaseHelper.EMEA_CASE_GEOREGION;
        caseBody.inContactSegment = '1-50 Seats';
        caseBody.customerNotification = true;
        caseBody.contactEmail = 'test@test.com';
        caseBody.implementationTeam = 'RingCentral';
        caseBody.description = 'Description';

        BillingWrappers.SubmitWrapper sWrapper = new BillingWrappers.SubmitWrapper();
        sWrapper.accountParams = new BillingWrappers.AccountParams();
        sWrapper.accountParams.geoRegionValue = caseBody.geoRegion;
        sWrapper.accountParams.implementationTeamValue = caseBody.implementationTeam;
        sWrapper.accountParams.nicSegmentValue = caseBody.inContactSegment;
        sWrapper.accountParams.timeZoneValue = caseBody.defaultTimeZone;

        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                Opportunity.CloseDate => Date.today()
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        opp = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id> {opp.Id})
            .executeQuery()
            .get(0);

        Test.startTest();
            Id caseId = CaseHelper.createICBCase(caseBody, opp);
            Id caseId2 = CaseHelper.createICBCase(opp, sWrapper.accountParams, caseBody.description);
        Test.stopTest();

        Assert.isNotNull(caseId, 'There should be an Id returned for case 1');
        Assert.isNotNull(caseId2, 'There should be an Id returned for case 2');

        Map<Id, Case> createdIcbCases = new Map<Id, Case>((List<Case>) new CaseSelector()
            .selectCasesByIds(new Set<Id> { caseId, caseId2 })
            .executeQuery()
        );

        Case createdIcbCase = createdIcbCases.get(caseId);
        Case createdIcbCase2 = createdIcbCases.get(caseId2);
        Assert.areEqual(caseBody.subject, createdIcbCase.Subject, 'Subject must be the same as in the caseBody');
        Assert.areEqual(CaseHelper.NBU_CASE_SUBJECT + ' My Account', createdIcbCase2.Subject, 'Subject must be correct');
        assertIcbCase(createdIcbCase, opp, caseBody);
        assertIcbCase(createdIcbCase2, opp, caseBody);
    }

    private static void assertIcbCase(Case cs, Opportunity opp, IcbHelper.ICBRequestCaseBody caseBody) {
        Assert.areEqual(cs.Opportunity_Reference__c, opp.Id, 'Bad opportunity reference');
        Assert.areEqual(cs.Default_Time_Zone__c, caseBody.defaultTimeZone, 'DefaultTimeZone must be correct');
        Assert.areEqual(cs.Geo_Region__c, caseBody.geoRegion, 'GeoRegion must be correct');
        Assert.areEqual(cs.inContact_Segment__c, caseBody.inContactSegment, 'NIC Segment must be correct');
        Assert.areEqual(cs.Implementation_Team__c, caseBody.implementationTeam, 'ImplementationTeam must be correct');
    }

    @isTest
    static void testIsEscalatable() {
        Case testCase = new TestCaseGenerator(Datetime.now().addDays((CaseHelper.DAYS_TO_SLA_BREACHED + 1) * -1))
            .getCase();
        testCase.IsEscalated = false;

        Test.startTest();
            Boolean isEscalatable = CaseHelper.isEscalatable(testCase);
            testCase = new TestCaseGenerator().getCase();
            Boolean notEscalatable = CaseHelper.isEscalatable(testCase);
        Test.stopTest();

        System.assertEquals(true, isEscalatable, 'The test case should be escalatable');
        System.assertEquals(false, notEscalatable, 'The test case should NOT be escalatable');
    }

    @isTest
    static void testGetEscalateErrorMessage() {
        Case testCase = new TestCaseGenerator(Datetime.now().addDays((CaseHelper.DAYS_TO_SLA_BREACHED + 1) * -1))
            .getCase();

        Test.startTest();
            String emptyReason = CaseHelper.getEscalateErrorMessage(testCase);

            testCase.IsEscalated = true;
            String isEscalatedReason = CaseHelper.getEscalateErrorMessage(testCase);

            testCase = new TestCaseGenerator(CaseHelper.CASE_STATUS_CLOSED, true).getCase();
            String isClosedReason = CaseHelper.getEscalateErrorMessage(testCase);

            testCase = new TestCaseGenerator().getCase();
            String notInSlaPeriodReason = CaseHelper.getEscalateErrorMessage(testCase);
        Test.stopTest();

        System.assertEquals('', emptyReason, 'Expected an empty error message');
        System.assertEquals(
            CaseHelper.CASE_IS_ALREADY_ESCALATED_TEXT,
            isEscalatedReason,
            'Wrong error message for an already escalated case'
        );
        System.assertEquals(
            CaseHelper.CASE_CLOSED_CANNOT_BE_ESCALATED_TEXT,
            isClosedReason,
            'Wrong error message for an already closed case'
        );
        System.assertEquals(
            CaseHelper.CASE_CANNOT_BE_ESCALATED_BEFORE_SLA_TEXT,
            notInSlaPeriodReason,
            'Wrong error message for a case in sla period'
        );
    }

    @isTest
    static void testIsInSlaPeriod() {
        Case testCase = new TestCaseGenerator().getCase();

        Test.startTest();
            Boolean inSlaPeriod = CaseHelper.isInSlaPeriod(testCase);
            testCase = new TestCaseGenerator(Datetime.now().addDays((CaseHelper.DAYS_TO_SLA_BREACHED + 1) * -1)).getCase();
            Boolean notInSlaPeriod = CaseHelper.isInSlaPeriod(testCase);
        Test.stopTest();

        System.assertEquals(true, inSlaPeriod, 'Expected to be in SlaPeriod');
        System.assertEquals(false, notInSlaPeriod, 'Expected to NOT be in SlaPeriod');
    }

    @isTest
    static void testGetReopenErrorMessage() {
        Case testCase = new TestCaseGenerator(CaseHelper.CASE_STATUS_REOPENED, false).getCase();

        Test.startTest();
            String caseStatusReopenedReason = CaseHelper.getReopenErrorMessage(testCase);
            testCase = new TestCaseGenerator().getCase();
            String caseNotClosedReason = CaseHelper.getReopenErrorMessage(testCase);
        Test.stopTest();

        System.assertEquals(
            CaseHelper.CASE_IS_ALREADY_REOPENED_TEXT,
            caseStatusReopenedReason,
            'Wrong error message for an already reopened case'
        );
        System.assertEquals(
            CaseHelper.CASE_IS_NOT_CLOSED,
            caseNotClosedReason,
            'Wrong error message for not closed case'
        );
    }

    @isTest
    static void testIsReopenable() {
        Datetime now = Datetime.now();
        Case testCase = new TestCaseGenerator(CaseHelper.CASE_STATUS_CLOSED, true, now, now).getCase();

        Test.startTest();
            Boolean reopenable = CaseHelper.isReopenable(testCase);
        Test.stopTest();

        System.assertEquals(true, reopenable, 'The case should be reopenable');
    }

    @isTest
    static void testGetTranslatedLabel() {
        String value = 'value';
        String translatedLabel = 'translated label';
        String missingValue = 'missing value';
        Map<String, String> translatedLabelByValue = new Map<String, String> {value => translatedLabel};

        Test.startTest();
            String translation = CaseHelper.getTranslatedLabel(translatedLabelByValue, value);
            String missingTranslation = CaseHelper.getTranslatedLabel(translatedLabelByValue, missingValue);
        Test.stopTest();

        System.assertEquals(translatedLabel, translation, 'The getTranslatedLabel did not return translation');
        System.assertEquals(missingValue, missingTranslation, 'The getTranslatedLabel did not return input value');
    }

    @isTest
    static void testIsValidLanguage() {
        String validLanguage = 'en_us';
        String invalidLanguage = 'klingon';

        Test.startTest();
            Boolean validLanguageOutcome = CaseHelper.isValidLanguage(validLanguage);
            Boolean invalidLanguageOutcome = CaseHelper.isValidLanguage(invalidLanguage);
        Test.stopTest();

        System.assertEquals(true, validLanguageOutcome, 'The language must pass the validation');
        System.assertEquals(false, invalidLanguageOutcome, 'The language must not pass the validation');
    }

    @isTest
    static void createCaseContactAttempts_whenCaseMeetTheRequirements_shouldCreateThreeCaseActivities() {
        Account acc = createAccount();
        Contact cont = createContact(acc);
        User testUser = createUser();

        acc.CSM__c = testUser.Id;
        update acc;

        insert new Owner_Assignment_for_Relationship_Cases__c();

        Test.startTest();
            Case aCase = createCase(acc, cont, testUser.Id, CaseHelper.RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP);
        Test.stopTest();

        Case_Activity__c[] caseActivitiesToTest = new CaseActivitySelector()
            .selectCloseAttemptsByCaseIdAndRecordType(new Object[]{
                new Id[]{aCase.Id},
                CaseHelper.RT_ID_CASE_ACTIVITY_CONTACT_ATTEMPT
            })
            .executeQuery();

        System.assertEquals(3, caseActivitiesToTest.size());

        for (Case_Activity__c caseActivity : caseActivitiesToTest) {
            System.assertEquals('New', caseActivity.Status__c, 'Case Activity status should be "New"');
            System.assertEquals(aCase.ownerId, caseActivity.Assigned_To__c, 'The case activity should be assigned to the case owner.');
        }
    }

    @isTest
    private static void testCreateProblemCase() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.AccountId => testAccount.Id
                })
            .create()
            .getRecord();

        Lead createdLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'test@email.com',
                    Lead.LastName => 'TestLastName',
                    Lead.Company => 'TestCompany',
                    Lead.Status => '1. New'
                }
            )
            .create()
            .getRecord();

        PartnerOperationsLog__c log = (PartnerOperationsLog__c) new SObjectBuilder(PartnerOperationsLog__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsLog__c.Account__c => testAccount.Id,
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isRejected__c => false,
                PartnerOperationsLog__c.isCompleted__c => false
            })
            .create()
            .getRecord();

        String testDescription = 'test description';
        String caseSubject1 = PartnerOperationsController.WHOLESALE_SUBJECT;
        String caseSubject2 = 'test case subject';

        Test.startTest();

        Response result1 = CaseHelper.createProblemCase(
            createdLead.Id, testAccount.Id, opp.Id, testDescription, caseSubject1
        );
        Response result2 = CaseHelper.createProblemCase(
            createdLead.Id, testAccount.Id, opp.Id, testDescription, caseSubject2
        );

        Case selectedCase = [
            SELECT CaseNumber
            FROM Case
            WHERE AccountId =:testAccount.Id
        ];

        Response testResp = new Response();
        testResp.setData('caseId', selectedCase.Id);
        testResp.setData(CaseHelper.CASE_NUMBER, selectedCase.CaseNumber);

        System.assertEquals(Response.STATUS_SUCCESS, result1.status, 'Response statuses are not equal');
        System.assertEquals('Thank you for the report. Case is successfully created',
            result1.messages[0].message,
            'Response messsage does not equal expected result message'
        );
        System.assertEquals(Response.STATUS_SUCCESS, result2.status, 'Response statuses are not equal');
        System.assertEquals('is successfully created. Thank you for the report.',
            result2.messages[0].message,
            'Response messsage does not equal expected result message'
        );
        System.assertEquals(testResp.data, result2.data, 'Actual response data is not equal to expected');
        Test.stopTest();
    }

    @isTest
    private static void testCreateProblemCaseWithLead() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => testAccount.Id
                })
            .create()
            .getRecord();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .create()
            .getRecord();

        PartnerOperationsLog__c log = (PartnerOperationsLog__c) new SObjectBuilder(PartnerOperationsLog__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsLog__c.Account__c => testAccount.Id,
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isRejected__c => false,
                PartnerOperationsLog__c.isCompleted__c => false
            })
            .create()
            .getRecord();

        String testDescription = 'test description';

        Test.startTest();

        Response result = CaseHelper.createProblemCase(
            leadTest.Id,
            testAccount.Id,
            opp.Id,
            testDescription,
            'subject'
        );

        System.assertEquals(Response.STATUS_SUCCESS, result.status, 'Status should be successful');
        System.assertEquals('is successfully created. Thank you for the report.', result.messages[0].message, 'Messages should be equal');

        Test.stopTest();
    }

    @isTest
    static void testSyncCaseQueueable() {
        IValueProvider accountId = ValueProviderBuilder.provideGenericParent(Account.SObjectType);
        Id caseOwnerId = DealDeskCaseGenerator.DEAL_DESK_QUEUE.QueueId;

        new SObjectBuilder(DealDeskCaseDescription__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DealDeskCaseDescription__c.Account__c => accountId,
                DealDeskCaseDescription__c.CaseOwner__c => caseOwnerId,
                DealDeskCaseDescription__c.CaseDescription__c => 'Test Description'
            })
            .create();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => accountId,
                Opportunity.isUpsellStepCompleted__c => true,
                Opportunity.SyncInfo__c => '{"timeStampMap":{"SYNC_INVOICE":"2022-02-08T14:08:19.649Z","CONTRACT_SYNC":"2022-02-08T14:06:08.971Z", "UP_SELL": "2022-02-08T14:06:09.971Z"},"scenarioName":"WHOLESALE_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE"}'
            })
            .create()
            .getRecord();

        Test.startTest();
            List<DealDeskCaseDescription__c> existingDescs = (List<DealDeskCaseDescription__c>) new DealDeskCaseDescriptionSelector()
                .selectDealDeskCaseDescriptionsForAccounts(new List<Object> {new Set<Id> {testOpp.AccountId}})
                .executeQuery();
            if(!existingDescs.isEmpty()) {
                System.enqueueJob(new CaseQueueable(new Set<Id>(), existingDescs));
            }
        Test.stopTest();

        List<Case> caseList = (List<Case>) new CaseSelector()
            .selectCases()
            .executeQuery();
        System.assertEquals(caseList.size(), 1, 'SyncCaseQueueable should properly create cases');
    }

    @isTest
    static void testGetDealAndOrderSupportRecordTypeId() {
        Response result;
        Test.startTest();
            result = CaseHelper.getDealAndOrderSupportRecordTypeId();
        Test.stopTest();
        System.assertEquals('success', result.status, 'getDealAndOrderSupportRecordTypeId response should return success status');
        System.assertEquals(true, !String.isEmpty(String.valueOf(result.data.get('dealAndOrderSupportRecordTypeId'))), 'getDealAndOrderSupportRecordTypeId response should contain dealAndOrderSupportRecordTypeId');
    }
    
    @isTest
    private static void testIBSCaseDescription(){
        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'Unted States',
                Account.RC_User_ID__c => '123456789'
            })
            .create()
            .getRecords();

        List<Contact> contacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'firstname',
                    Contact.LastName => 'lastname',
                    Contact.Email => 'useremail@rc.com',
                    Contact.Phone => '77777777',
                    Contact.Phone_Ext__c => 777,
                    Contact.AccountId => accounts[0].Id
                }
            )
            .create()
            .getRecords();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES,
                    Case.Subject => 'test Subject',
                    Case.Case_Severity__c => 'Level 4 - Medium',
                    Case.Description => 'test Description',
                    Case.Status => 'Closed',
                    Case.Site__c => 'test site',
                    Case.ContactId => contacts[0].Id,
                    Case.AccountId => accounts[0].Id,
                    Case.Affected_User__c => UserInfo.getUserId(),
                    Case.Steps_to_Reproduce__c => 'Test steps',
                    Case.Actual_Result__c => 'Test actual result',
                    Case.Expected_Result__c => 'Test expected result',
                    Case.Error_Link__c => 'google.com'
                }
            )
            .create()
            .getRecord();
        
        Test.startTest();
        Case newCs = (Case) new CaseSelector()
            .selectCases()
            .selectField(Case.Description)
            .selectField(Case.Id)
            .executeQuery()[0];
        
        Assert.isTrue(!String.isBlank(newCs.Description));
        Test.stopTest();
    }
}