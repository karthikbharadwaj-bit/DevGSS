@isTest
private class Test_ApexWebServices {
    private static final String SANDBOX_NAME = 'box50';
    private static final String USER_NAME = 'asuser@aquivalabs.com';

    private static final String SUCESS_STATUS = 'success';
    private static final String DESCRIPTION = 'Test Description.';
    private static final String SALES_OPS_TEAM = 'Sales Ops Team';
    private static final String SALES_ORDER_QUEUE = 'Sales Order Except Desk Queue';

    static Id createTestData() {
        Triggers.switchOff();
        new SObjectBuilder(ByPassTrigger__c.SObjectType)
            .setField(ByPassTrigger__c.Bypass_Account_Trigger__c, true)
            .create();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Number_of_DL_s__c => 10,
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.Payment_Method__c => 'Invoice',
                Account.SignupType__c => 'Direct'
            })
            .create()
            .getRecord();

        Id standardPriceBookId = Test.getStandardPricebookId();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'TestFirstName',
                Contact.LastName => 'TestLastName',
                Contact.AccountId => testAccount.Id,
                Contact.Email => 'test@test.com'
            })
            .create()
            .getRecord();

        Area_Codes__c areaCode = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => '999',
                Area_Codes__c.Area_Code__c => 999,
                Area_Codes__c.City__c => 'TestCity',
                Area_Codes__c.State_Abbreviation__c => 'ST',
                Area_Codes__c.StateID__c => 99
            })
            .create()
            .getRecord();

        schedulerConfiguration__c scc = (schedulerConfiguration__c) new SObjectBuilder(schedulerConfiguration__c.SObjectType)
            .setField(schedulerConfiguration__c.Name,  OpportunityHelper.BRAND_RINGCENTRAL)
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('Test Price Book'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Line_Range_Max__c => 10,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Description => 'Test Price Book Products',
                PriceBook2.Tier_ID__c => '999',
                PriceBook2.Brand__c => scc.Id,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
            })
            .create()
            .getRecord();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Connect Pro - Annual Fee',
                Product2.IsActive => true,
                Product2.Sub_Category__c => ValueProviderBuilder.provideList(new List<String> { 'Main', 'Contact Center' }),
                Product2.Family => ValueProviderBuilder.provideList(new List<String> { 'Office', 'Service' })
            })
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> testPricebookEntrys = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id> {
                    testProducts[0].Id,
                    testProducts[0].Id,
                    testProducts[1].Id,
                    testProducts[1].Id
                }),
                PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(new List<Id> {
                    Test.getStandardPricebookId(),
                    testPriceBook.Id,
                    Test.getStandardPricebookId(),
                    testPriceBook.Id
                }),
                PricebookEntry.UnitPrice => ValueProviderBuilder.provideList(new List<Integer> { 50, 50, 100, 100 }),
                PricebookEntry.Min_Quantity__c => ValueProviderBuilder.provideList(new List<Integer> { null, 1, null, 1 }),
                PricebookEntry.Max_Quantity__c => ValueProviderBuilder.provideList(new List<Integer> { null, 100, null, 100 }),
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .quantity(4)
            .create()
            .getRecords();

       Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Type => 'Syndicated - New',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.PriceBook2Id => testPriceBook.Id,
                Opportunity.Primary_Opportunity_Contact__c => testContact.Id,
                Opportunity.Tier_Name__c => '999',
                Opportunity.AccountId => testAccount.Id
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.id,
                Quote.Status => 'Draft',
                Quote.Pricebook2Id => testPriceBook.id,
                Quote.Total_Number_of_Digital_Lines__c => 0,
                Quote.FaxAreaCode__c => areaCode.Id,
                Quote.AreaCode__c => areaCode.Id
            })
            .create()
            .getRecord();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.ServiceDate => date.today(),
                QuoteLineItem.Description => ValueProviderBuilder.provideList(new List<String> {
                    'TestLineItem',
                    'TestServiceLineItem'
                }),
                QuoteLineItem.UnitPrice => ValueProviderBuilder.provideList(new List<Decimal> {
                    testPricebookEntrys[1].UnitPrice,
                    testPricebookEntrys[3].UnitPrice
                }),
                QuoteLineItem.Product2Id => testProducts[0].Id,
                QuoteLineItem.PriceBookEntryId => ValueProviderBuilder.provideList(new List<Id> {
                    testPricebookEntrys[1].Id,
                    testPricebookEntrys[3].Id
                }),
                QuoteLineItem.Quantity => 5
            })
            .quantity(2)
            .build();

        Triggers.switchOff();
        return testPricebookEntrys[0].Id;
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

    @isTest
    static void test_orderWrappers(){
        ApexWebServices.OrderDetail od = new ApexWebServices.OrderDetail();
        od.order = null;
        od.hasPermission = false;
        ApexWebServices.OrderDetailforDeactivate odd = new ApexWebServices.OrderDetailforDeactivate();
        odd.order = null;
        odd.profileName = 'System Administrator';
        System.assertEquals(od.hasPermission,false,
           'Wrapper class value fail.');
    }

    @isTest
    static void test_havePermissionByProfile() {
        Test.startTest();
            createTestData();
        Test.stopTest();

        Profile p = [SELECT Id, PermissionsActivateOrder FROM Profile WHERE Name = 'System Administrator'];
        System.assertEquals( p.PermissionsActivateOrder, ApexWebServices.havePermissionByProfile( p.Id, 'PermissionsActivateOrder') );
    }


    @isTest
    static void test_activateOrderWithChildren_lock() {
        Id stdPbeId = createTestData();
        Test.startTest();
            Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

            Order testOrder = new Order(
                AccountId = opp.AccountId,
                OpportunityId = opp.Id,
                Status = 'New',
                Pricebook2Id = Test.getStandardPricebookId(),
                EffectiveDate = System.today()
            );
            insert testOrder;

        Test.stopTest();

            OrderItem testOrderItem = new OrderItem(
                OrderId = testOrder.Id,
                Quantity = 5,
                UnitPrice = 50,
                PriceBookEntryId = stdPbeId
            );
            insert testOrderItem;

        System.assertEquals(true, ApexWebServices.activateOrderWithChildren(testOrder.Id, true));
    }

    @isTest
    static void test_activateOrderWithChildren_unlock() {
        Id stdPbeId = createTestData();
        Test.startTest();
            Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

            Order testOrder = new Order(
                AccountId = opp.AccountId,
                OpportunityId = opp.Id,
                Status = 'New',
                Pricebook2Id = Test.getStandardPricebookId(),
                EffectiveDate = System.today()
            );
            insert testOrder;

            Test.stopTest();

            OrderItem testOrderItem = new OrderItem(
                OrderId = testOrder.Id,
                Quantity = 5,
                UnitPrice = 50,
                PriceBookEntryId = stdPbeId
            );
            insert testOrderItem;


        Order o = [SELECT Id FROM Order LIMIT 1];
        System.assertEquals(true, ApexWebServices.activateOrderWithChildren(testOrder.Id, false));
    }

    @isTest
    static void test_validateOnCloseOpportunity() {
        Id stdPbeId = createTestData();

        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        ApexWebServices.CloseOpportunityParams closeOptyParams = new ApexWebServices.CloseOpportunityParams();
        closeOptyParams.opportunityId = opp.Id;
        String jsonOptyParams = JSON.serialize(closeOptyParams);

        Test.startTest();
            Order testOrder = new Order(
                AccountId = opp.AccountId,
                OpportunityId = opp.Id,
                Status = 'New',
                Pricebook2Id = Test.getStandardPricebookId(),
                EffectiveDate = System.today()
            );
            insert testOrder;

            OrderItem testOrderItem = new OrderItem(
                OrderId = testOrder.Id,
                Quantity = 5,
                UnitPrice = 50,
                PriceBookEntryId = stdPbeId
            );
            insert testOrderItem;


        String response = ApexWebServices.validateOnCloseOpportunity(jsonOptyParams);

        Test.stopTest();

        System.assert(!String.isBlank(response));
        // Check case when there are no close parameters
        String emptyParamsResponse = ApexWebServices.validateOnCloseOpportunity('');
        System.assert(emptyParamsResponse.contains('Close opportunity parameters are not specified'));
    }

    @isTest
    static void test_validateOnCloseOpportunityWithPrevaliActions() {
        Id stdPbeId = createTestData();
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Approval__c testApproval = new Approval__c(Status__c = 'New', Account__c = opp.AccountId);
        insert testApproval;

        ApexWebServices.CloseOpportunityParams closeOptyParams = new ApexWebServices.CloseOpportunityParams();
        closeOptyParams.opportunityId = opp.Id;
        closeOptyParams.rcNumber = '1234567';
        closeOptyParams.ccNumber = '1234567';
        closeOptyParams.approvalId = testApproval.Id;

        String jsonOptyParams = JSON.serialize(closeOptyParams);
        Test.startTest();
        String response = ApexWebServices.validateOnCloseOpportunity(jsonOptyParams);
        Test.stopTest();

        System.assert(!String.isBlank(response));
    }

    @isTest
    static void test_validateOpportunityWithELsOnClose() {
        Opportunity testOpp = new Opportunity(
                Name = 'test opp (Change order)',
                StageName = '1. Qualify'
        );
        insert testOpp;

        Quote testQuote = new Quote (
                Name = 'Test Quote',
                OpportunityId = testOpp.id,
                Status = 'Draft',
                Pricebook2Id = null,
                Total_Number_of_Digital_Lines__c = 5,
                FaxAreaCode__c = null,
                AreaCode__c = null
        );
        insert testQuote;

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Quote__c => testQuote.Id,
                    Approval__c.Opportunity__c => testQuote.OpportunityId,
                    Approval__c.Type__c => ApprovalHelperCls.LEGAL_REQUEST_TYPE_AMENDMENT,
                    Approval__c.Account__c => testQuote.Account__c,
                    Approval__c.RecordTypeId => ApprovalHelperCls.RT_ID_ENGAGE_LEGAL
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        Response res1 = ApexWebServices.validateELOpportunity(testOpp.Id, 'Close');
        System.assertEquals(approval.Id, res1.data.get('approvalId'), 'Wrong approval id');

        User testUser = createUser(ProfileHelper.PROFILE_NAME_DEAL_DESK_LIGHTNING);
        System.runAs(testUser) {
            Response res3 = ApexWebServices.validateELOpportunity(testOpp.Id, 'Close');
            System.assertNotEquals(approval.Id, res3.data.get('approvalId'));
        }

        approval.Status__c = 'PendingL1Approval';
        update approval;

        Response res2 = ApexWebServices.validateELOpportunity(testOpp.Id, 'Send with DocuSign');
        System.assertEquals(approval.Id, res1.data.get('approvalId'), 'Wrong approval id');
        Test.stopTest();
    }


    @isTest
    static void testCheckPhasesIsPendingApproval() {

        System.assertEquals(false, ApexWebServices.checkPhasesIsPendingApproval(null));

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('Test Price Book'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Line_Range_Max__c => 10,
                PriceBook2.Tier_ID__c => '999',
                PriceBook2.Description => 'Test Price Book Products',
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Connect Pro - Annual Fee',
                Product2.Family => 'Office',
                Product2.IsActive => true,
                Product2.Sub_Category__c => 'Main'
            })
            .create()
            .getRecord();

        PriceBookEntry standardPrice = (PriceBookEntry) new SOBjectBuilder(PriceBookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PriceBookEntry.Product2Id => testProduct.Id,
                PriceBookEntry.UnitPrice => 50,
                PriceBookEntry.IsActive => true,
                PriceBookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.Name, 'TestAcc')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Type => 'Syndicated - New',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.PriceBook2Id => testPriceBook.Id,
                Opportunity.Tier_Name__c => '999',
                Opportunity.AccountId => testAccount.Id
            })
            .create()
            .getRecord();

        Test.startTest();

            Order testOrder = new Order(
                AccountId = opp.AccountId,
                OpportunityId = opp.Id,
                Status = 'New',
                Pricebook2Id = Test.getStandardPricebookId(),
                EffectiveDate = System.today(),
                RecordTypeId = OrderHelper.RT_ID_PROSERV
            );
            insert testOrder;

            OrderItem testOrderItem = new OrderItem(
                OrderId = testOrder.Id,
                Quantity = 5,
                UnitPrice = 50,
                PriceBookEntryId = standardPrice.Id
            );
            insert testOrderItem;

            Phase__c ph = new Phase__c(
                Order__c = testOrder.Id,
                Account__c = testOrder.AccountId,
                Status__c = PhaseHelper.STATUS_NEW,
                RecordTypeId = PhaseHelper.RT_ID_PROSERV_PHASE
            );
            insert ph;

            System.assertEquals(false, ApexWebServices.checkPhasesIsPendingApproval(testOrder.Id));

            ph.Status__c = PhaseHelper.STATUS_PENDING_APPROVAL;
            update ph;

            System.assertEquals(true, ApexWebServices.checkPhasesIsPendingApproval(testOrder.Id));

        Test.stopTest();
    }

    private static Opportunity createDataForButtonTest() {
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
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        User us = [
                    SELECT Id, UserRoleId, ContactId
                    FROM User
                    WHERE IsActive = true
                    AND UserRoleId != null
                    LIMIT 1
                    ];
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.OwnerId => us.Id
                }
            )
            .create()
            .getRecord();
        return oppty;
    }
    @isTest
    static void testCreateCaseFromOppContact() {
        Opportunity opp = createDataForButtonTest();

        Test.startTest();
            String resultJson = ApexWebServices.createCaseFromOpp(
                                                                String.valueOf(opp.Id),
                                                                'Sales Order Except Desk',
                                                                '---Select---',
                                                                DESCRIPTION,
                                                                'Ideas/Suggestions/Feedback',
                                                                'Low Priority (5+ Business Days turnaround)',
                                                                'Sales Order Except Desk');
        Test.stopTest();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resultJson);
        System.assertEquals(String.valueOf(response.get('status')),
                            SUCESS_STATUS,
                            'Response from Engage Ops Buttons is incorrect.');
        Case cs = [
                    SELECT OwnerId
                    FROM Case
                    WHERE Opportunity_Reference__c =: opp.Id
                    LIMIT 1
                    ];
        Group gr = [
                    SELECT Id
                    FROM Group
                    WHERE Type = 'Queue'
                    AND Name =: SALES_ORDER_QUEUE
                    LIMIT 1
                    ];
        System.assertEquals(cs.OwnerId,
                            gr.Id,
                            'Case Owner was not assigned from related Opportunity.');
    }

    @isTest
    static void testGetPicklistValues() {

        String categoryResult = ApexWebServices.getPicklistValues('category');

        System.assertNotEquals( 0,
                                categoryResult.length(),
                                'Case Category picklist values was not retrieved correctly.');

        String typeResult = ApexWebServices.getPicklistValues('type');

        System.assertNotEquals( 0,
                                typeResult.length(),
                                'Case Type picklist values was not retrieved correctly.');
    }

    @isTest
    static void test_ValidateAreaCodesOnOptyClose() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c (Area_Codes_Check_On_Opportunity_Close__c = true);
        insert featureToggle;

        // Check when opportunity Id is not provided
        String response = CloseOpportunity.processData(null);
        List<CloseOpportunity.ErrorWrapper> result = (List<CloseOpportunity.ErrorWrapper>) JSON.deserialize(response,List<CloseOpportunity.ErrorWrapper>.class);
        System.assertEquals('Please provide opportunity Id', result[0].message);
        // Check when there is no primary quote
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(Name = 'Test Oppty',
            AccountId = testAccount.Id,
            StageName = '1. Qualify'
        );
        insert testOpportunity;

        String response1 = CloseOpportunity.processData(testOpportunity.Id);

        List<CloseOpportunity.ErrorWrapper> result1 = (List<CloseOpportunity.ErrorWrapper>) JSON.deserialize(response1,List<CloseOpportunity.ErrorWrapper>.class);
        System.assertEquals('To close the opportunity, you must have at least 1 primary quote', result1[0].message);

        // Check when there are no quote line items in the cart
        Quote testQuote = new Quote (
            Name = 'testQuote',
            IsPrimary__c = true,
            OpportunityId = testOpportunity.id,
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = QuoteHelper.RT_ID_SALES
        );
        insert testQuote;

        String response2 = CloseOpportunity.processData(testOpportunity.Id);

        List<CloseOpportunity.ErrorWrapper> result2 = (List<CloseOpportunity.ErrorWrapper>) JSON.deserialize(response2,List<CloseOpportunity.ErrorWrapper>.class);
        System.assertEquals('To close the opportunity, you must have at least 1 item in the cart', result2[0].message);

        Test.startTest();

        // Check when area code line items are missed
        Product2 testProduct = new Product2(
            Name = 'TestProduct',
            Charge_Term__c = 'One - Time',
            IsActive = true,
            Feature__c = 17,
            Family = Product2Helper.FAMILY_DISCOUNTED_PHONES
        );
        insert (new List<Product2>{testProduct});

        PricebookEntry testPrice1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        insert testPrice1;

        QuoteLineItem qli = new QuoteLineItem (
            Quantity = 3,
            QuoteId = testQuote.Id,
            UnitPrice = testPrice1.UnitPrice,
            Product2Id = testProduct.Id,
            PricebookEntryId = testPrice1.Id,
            Zero_Quantity__c = false
        );
        insert qli;

        String response3 = CloseOpportunity.processData(testOpportunity.Id);

        List<CloseOpportunity.ErrorWrapper> result3 = (List<CloseOpportunity.ErrorWrapper>) JSON.deserialize(response3,List<CloseOpportunity.ErrorWrapper>.class);
        System.assertEquals('Area Codes are missing. Please select Area Codes for all Discounted or Refurbished Phones and all Additional Numbers on the Primary Quote', result3[0].message);

        // Check when there are no errors
        Area_Codes__c testCode = new Area_Codes__c(
            Name = 'testCode',
            State__c = 'CA',
            Country__c = 'United States');
        insert testCode;

        Area_Code_Line_Item__c acli = new Area_Code_Line_Item__c(
            Quote_Line_Item__c = qli.Id,
            Area_Code__c = testCode.Id);
        insert acli;

        String response4 = CloseOpportunity.processData(testOpportunity.Id);

        List<CloseOpportunity.ErrorWrapper> result4 = (List<CloseOpportunity.ErrorWrapper>) JSON.deserialize(response4,List<CloseOpportunity.ErrorWrapper>.class);
        System.assertEquals(true, result4.isEmpty());

        Test.stopTest();
    }

    @isTest
    static void testCompletePhase() {

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Order.EffectiveDate => System.today(),
                Order.Status => 'New'
            })
            .create()
            .getRecord();

        PriceBookEntry pbe = (PriceBookEntry) new SOBjectBuilder(PriceBookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PriceBookEntry.Product2Id => ValueProviderBuilder.provideGenericParent(Product2.SObjectType)
            })
            .create()
            .getRecord();

        OrderItem testOrderItem = (OrderItem) new SOBjectBuilder(OrderItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                OrderItem.OrderId => testOrder.Id,
                OrderItem.PricebookEntryId => pbe.Id,
                OrderItem.Quantity => 1,
                OrderItem.UnitPrice => 1
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Phase__c.Name => ValueProviderBuilder.provideUniqueString('test phase'),
                Phase__c.Order__c => testOrder.Id
            })
            .create()
            .getRecord();

        Hardware_Line_Item__c testHLI = (Hardware_Line_Item__c) new SOBjectBuilder(Hardware_Line_Item__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase.Id,
                Hardware_Line_Item__c.Quantity__c => 1,
                Hardware_Line_Item__c.Order_Line_Item__c => testOrderItem.Id
            })
            .create()
            .getRecord();

        Test.startTest();
            Boolean isNeedToLock = false;
            Boolean result = ApexWebServices.completePhase(testPhase.Id, isNeedToLock);

            Map<Id, Boolean> lockResult = Approval.isLocked(new List<Id>{testPhase.Id, testHLI.Id});
            for (Id sobjId : lockResult.keySet()) {
                System.assertEquals(false, lockResult.get(sobjId), 'records should not be locked');
            }

            isNeedToLock = true;
            result = ApexWebServices.completePhase(testPhase.Id, isNeedToLock);
            System.assert(result, 'ApexWebServices.completePhase should return true');

            lockResult = Approval.isLocked(new List<Id>{testPhase.Id, testHLI.Id});
            for (Id sobjId : lockResult.keySet()) {
                System.assertEquals(true, lockResult.get(sobjId), 'records should be locked');
            }
        Test.stopTest();
    }

    @isTest
    static void testCheckOrderIsCompletedMethod() {

        System.assertEquals(
            false,
            ApexWebServices.checkOrderIsCompleted(null),
            'checkOrderIsCompleted method should return false if passed OrderId is null'
        );

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Order.EffectiveDate => System.today(),
                Order.Status => 'New'
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Phase__c.Name => ValueProviderBuilder.provideUniqueString('test phase'),
                Phase__c.Order__c => testOrder.Id
            })
            .create()
            .getRecord();

        Test.startTest();

            Boolean result = ApexWebServices.checkOrderIsCompleted(testOrder.Id);
            System.assertEquals(
                false,
                result,
                'checkOrderIsCompleted method should return false if order has no any related Phase__c ' +
                'records with populated Completed_Date__c'
            );

            testPhase.Completed_Date__c = System.today();
            update testPhase;

            result = ApexWebServices.checkOrderIsCompleted(testOrder.Id);
            System.assertEquals(
                true,
                result,
                'checkOrderIsCompleted method should return true if order has any related Phase__c ' +
                'record with populated Completed_Date__c'
            );

        Test.stopTest();
    }

    @isTest
    static void testChangeOrderMethod() {

        System.assertEquals(
            null,
            ApexWebServices.changeOrder(null),
            'method should return false if passed OrderId is null'
        );

        System.assertEquals(
            null,
            ApexWebServices.changeOrder(''),
            'method should return false if passed OrderId is empty string'
        );

        System.assertEquals(
            null,
            ApexWebServices.changeOrder('     '),
            'method should return false if passed OrderId is blank string'
        );


        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Order.EffectiveDate => System.today(),
                Order.Status => 'New'
            })
            .create()
            .getRecord();

        PriceBookEntry pbe = (PriceBookEntry) new SOBjectBuilder(PriceBookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PriceBookEntry.Product2Id => ValueProviderBuilder.provideGenericParent(Product2.SObjectType)
            })
            .create()
            .getRecord();

        OrderItem testOrderItem = (OrderItem) new SOBjectBuilder(OrderItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                OrderItem.OrderId => testOrder.Id,
                OrderItem.PricebookEntryId => pbe.Id,
                OrderItem.Quantity => 1,
                OrderItem.UnitPrice => 1
            })
            .create()
            .getRecord();

        Test.startTest();

            Map<String,Object> parsed = (Map<String,Object>)JSON.deserializeUntyped(ApexWebServices.changeOrder(testOrder.Id));
            Map<String,Object> dataMap = (Map<String,Object>)parsed.get('data');
            Id result = (Id)dataMap.get('newOppId');

            System.assertEquals(
                Opportunity.SObjectType,
                result.getSObjectType(),
                'returned Id should be Id of created Opportunity record'
            );

            Opportunity reselectedOpp = (Opportunity) new OpportunitySelector()
                .selectOpportunities()
                .selectFields(new List<SObjectField>{
                    Opportunity.Name,
                    Opportunity.Type,
                    Opportunity.StageName,
                    Opportunity.RecordTypeId,
                    Opportunity.Parent_Order__c
                })
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{ result })
                .executeQuery()
                .get(0);

            System.assertEquals(
                OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                reselectedOpp.Type,
                'Created Opporunity should have Type "Existing Business"'
            );
            System.assertEquals(
                OpportunityHelper.STAGE_NAME_QUALIFY,
                reselectedOpp.StageName,
                'Created Opporunity should have StageName "1. Qualify"'
            );
            System.assertEquals(
                testOrder.Id,
                reselectedOpp.Parent_Order__c,
                'Opporunity.Parent_Order__c field should not be empty'
            );
            System.assertEquals(
                reselectedOpp.RecordTypeId,
                OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
            );

            Order reselectedOrder = (Order) new OrderSelector()
                .selectOrders()
                .selectField(Order.Status)
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{ testOrder.Id })
                .executeQuery()
                .get(0);

            System.assertEquals(
                'Completed',
                reselectedOrder.Status,
                'Order should have Status "Completed"'
            );

        Test.stopTest();
    }

    @isTest
    static void testValidateOpptyBeforeSalesOPsEngagementMethod() {

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Payment_Method__c => 'Invoice'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'TestFirst',
                    Contact.LastName => 'TestLast',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@email.com',
                    Contact.Phone => '9910106804',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        AccountContactRole payableContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test opp',
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => '1. Qualify',
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD',
                Opportunity.Total_MRR__c => 550
            })
            .create()
            .getRecord();

        Test.startTest();

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Account__c => acc.Id,
                Approval__c.Opportunity__c => opp.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.AccountPayableContact__c => testContact.Id,
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();

            String result = ApexWebServices.validateOpptyBeforeSalesOPsEngagement(
                acc.Id,
                OpportunityHelper.STAGE_NAME_QUALIFY
            );
            System.assert(
                result.containsIgnoreCase('You are not able to engage salesOps'),
                'error message should returned'
            );

            result = ApexWebServices.validateOpptyBeforeSalesOPsEngagement(
                acc.Id,
                OpportunityHelper.STAGE_NAME_CLOSED_WON
            );
            System.assert(
                result.containsIgnoreCase('You are not able to engage salesOps'),
                'error message should returned'
            );

        Test.stopTest();
    }

    @isTest
    static void testSavePhoneNumbersForOrdersMethod() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test opp',
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.StageName => '1. Qualify',
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Test.startTest();

            String rcNumber = '111';
            String ccNumber = '222';

            ApexWebServices.savePhoneNumbersForOrders(opp.Id, rcNumber, ccNumber);

            Opportunity reselectedOpp = (Opportunity) new OpportunitySelector()
                .selectOpportunities()
                .selectFields(new List<SObjectField>{
                    Opportunity.NumberToBeRCMainNumber__c,
                    Opportunity.NumberToBeCCNumber__c
                })
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{ opp.Id })
                .executeQuery()
                .get(0);

            System.assertEquals(
                rcNumber,
                reselectedOpp.NumberToBeRCMainNumber__c,
                'passed "rcNumver" should be saved in Opportunity.NumberToBeRCMainNumber__c'
            );
            System.assertEquals(
                ccNumber,
                reselectedOpp.NumberToBeCCNumber__c,
                'passed "rcNumver" should be saved in Opportunity.NumberToBeCCNumber__c'
            );

        Test.stopTest();
    }

    @isTest
    static void testGetFeatureToogleMethod() {

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.NewChangeOrderFlow__c, true)
            .create();

        Test.startTest();

            Boolean result = ApexWebServices.getFeatureToogle();
            System.assertEquals(
                true,
                result,
                'getFeatureToogle method should return Feature_Toggle__c.NewChangeOrderFlow__c field value'
            );

        Test.stopTest();
    }

    @isTest
    static void testDnbiValidationForQueueAndCompanyNameMethod() {

        Group billingCreditCheckGroup = (Group) new GroupSelector()
            .selectGroupBasedOnDeveloperNames(new List<Object>{new List<String>{'Billing_Credit_Check'}})
            .executeQuery()
            .get(0);

        GroupMember billingCreditCheckQueueMember = (GroupMember) new SObjectBuilder(GroupMember.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                GroupMember.GroupId => billingCreditCheckGroup.Id,
                GroupMember.UserOrGroupId => UserInfo.getUserId()
            })
            .create()
            .getRecord();

        Test.startTest();

            User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

            System.runAs(thisUser) {

                D_B_Credit_Check__c testDbCreditCheck = (D_B_Credit_Check__c) new SObjectBuilder(D_B_Credit_Check__c.sObjectType)
                    .setFields(new Map<SObjectField, Object>{
                        D_B_Credit_Check__c.Approval__c => ValueProviderBuilder.provideGenericParent(Approval__c.SObjectType)
                    })
                    .create()
                    .getRecord();

                List<String> result = ApexWebServices.dnbiValidationForQueueAndCompanyName(testDbCreditCheck.Approval__c);
                System.assert(result.contains('Cannot run Credit Check. Invoice Request has no approval'));
                System.assert(result.contains('A Company name is required in order to submit for credit approval'));
            }

        Test.stopTest();
    }
    //adading new testGetOrderDetail start

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetOrderDetail()
    {
         Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Order.EffectiveDate => System.today(),
                Order.Status => 'New'
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Phase__c.Name => ValueProviderBuilder.provideUniqueString('test phase'),
                Phase__c.Order__c => testOrder.Id
            })
            .create()
            .getRecord();
        Test.startTest();
        ApexWebServices.getOrderDetail(testOrder.Id);
        // System.assertEquals(false,ApexWebServices.getOrderDetail(testOrder.Id).hasPermission);
        Test.stopTest();
    }
    //adading new testGetOrderDetail End
   //adading new test method for GetOrderDetailforDeactivate start
     @isTest
    static void testGetOrderDetailforDeactivate()
    {
         Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Order.EffectiveDate => System.today(),
                Order.Status => 'New'
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Phase__c.Name => ValueProviderBuilder.provideUniqueString('test phase'),
                Phase__c.Order__c => testOrder.Id
            })
            .create()
            .getRecord();
         Id profileId=userinfo.getProfileId();
			Profile profile = [Select Id,Name from Profile where Id=:profileId];
            String profileName = profile.Name;
        Test.startTest();
        ApexWebServices.getOrderDetailforDeactivate(testOrder.Id);
         System.assertEquals(profileName,ApexWebServices.getOrderDetailforDeactivate(testOrder.Id).profileName);
        Test.stopTest();
    }
    //adading new test method for GetOrderDetailforDeactivate end

    @isTest
    static void testSkipValidationForTerminationOpp() {
        Test.startTest();

        Area_Codes__c areaCode = new Area_Codes__c(
            Name = '999',
            Area_Code__c = 999,
            City__c = 'TestCity',
            State_Abbreviation__c = 'ST',
            StateID__c = 99);
        insert areaCode;

        schedulerConfiguration__c scc = new schedulerConfiguration__c(
            Name = 'RingCentral'
        );
        insert scc;

        PriceBook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            Tier_ID__c = '999',
            Plan__c = 'Annual',
            IsActive = true,
            Line_Range_Min__c = 5,
            Line_Range_Max__c = 10,
            Service__c = 'Office',
            Brand__c = scc.Id
        );
        insert testPriceBook;

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Name')
            .create()
            .getRecord();

        Opportunity terminatedOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD',
                    Opportunity.isTermination__c => true,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE
                })
            .create()
            .getRecord();

        Quote testQuote = new Quote (
            Name = 'Test Quote',
            OpportunityId = terminatedOpportunity.id,
            Status = 'Draft',
            Pricebook2Id = testPriceBook.id,
            Total_Number_of_Digital_Lines__c = 5,
            FaxAreaCode__c = areaCode.Id,
            AreaCode__c = areaCode.Id
        );
        insert testQuote;

        ApexWebServices.CloseOpportunityParams closeOptyParams = new ApexWebServices.CloseOpportunityParams();
        closeOptyParams.opportunityId = terminatedOpportunity.Id;

        ApexWebServices.validateOnCloseOpportunity(JSON.serialize(closeOptyParams));

        terminatedOpportunity = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id>{terminatedOpportunity.Id})
            .selectFields(new List<SObjectField>{
                Opportunity.Probability,
                Opportunity.StageName
            })
            .executeQuery()
            .get(0);
        System.assertnotEquals(100, terminatedOpportunity.Probability, 'Opportunity should be closed');
        System.assertnotEquals(OpportunityHelper.STAGE_NAME_CLOSED_WON, terminatedOpportunity.StageName,
            'Opportunity should be closed');

        Test.stopTest();
    }

    @isTest
    private static void testCloseOpportunityForEngageTermination() {
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity terminatedOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAcc.Id,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.CurrencyIsoCode => 'USD',
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                Opportunity.isTermination__c => true
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAcc.Id,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.IsActive => true,
                PriceBook2.Tier_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();
        Test.startTest();
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

        
            ApexWebServices.CloseOpportunityParams closeOptyParams = new ApexWebServices.CloseOpportunityParams();
            closeOptyParams.opportunityId = terminatedOpportunity.Id;

            ApexWebServices.validateOnCloseOpportunity(JSON.serialize(closeOptyParams));
        

        Quote updatedQuote = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Id>{qt.Id})
            .selectField(Quote.Quote_is_Invalid__c)
            .executeQuery()
            .get(0);
        Test.stopTest();
        System.assertnotEquals(true, updatedQuote.Quote_is_Invalid__c);
    }

    @isTest
    static void testFunnelSignUpRequest() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test acc',
                    Account.Internal_Enterprise_Account_ID__c => '12345'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD',
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE
                })
            .create()
            .getRecord();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        FunnelAPI.FunnelResponse request = new FunnelAPI.FunnelResponse();
        request.error = new FunnelAPI.FunnelError();
        request.error.data = new FunnelAPI.ErrorData();
        request.error.message = 'Test Error';
        request.error.data.OPPID = testOpp.Id;

        req.requestURI = '/services/apexrest/SignUpAccountWsBilling/';
        req.httpMethod = 'PUT';
        req.requestBody = Blob.valueOf(JSON.serializePretty(request));

        RestContext.request = req;
   	    RestContext.response = res;

        Test.startTest();
        SignUpAccountWsBilling.handleFunnelSignUpResponse();
        Test.stopTest();

        Account updAcc = (Account) new AccountSelector()
            .selectAccountById(testAcc.Id)
            .selectField(Account.Internal_Enterprise_Account_ID__c)
            .executeQuery()
            .get(0);

        System.assertEquals(updAcc.Internal_Enterprise_Account_ID__c, null);
    }

    @isTest
    static void testGetLastCreatedChangeOrder() {
        Triggers.switchOff();
        new SObjectBuilder(ByPassTrigger__c.sObjectType)
            .setField(ByPassTrigger__c.Bypass_Order_Trigger__c, true)
            .create()
            .getRecord();
        IValueProvider accountId =  ValueProviderBuilder.provideGenericParent(Account.SObjectType);

        Proserv_Project__c proservProjectForInitialCCProserv = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => accountId
            })
            .create()
            .getRecord();

        Order firstCCProservOrder = (Order) new SObjectBuilder(Order.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV ,
                Order.AccountId => accountId,
                Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                Order.EffectiveDate => System.today(),
                Order.Status => OrderHelper.STATUS_NEW,
                Order.ProServProject__c => proservProjectForInitialCCProserv.Id
            }
        )
        .create()
        .getRecord();

        Test.setCreatedDate(firstCCProservOrder.Id, DateTime.now().addDays(-5));

        Test.startTest();

        Order secondCCProservOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV ,
                    Order.AccountId => accountId,
                    Order.Type => OrderHelper.TYPE_CHANGE_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.ProServProject__c => proservProjectForInitialCCProserv.Id
                }
            )
            .create()
            .getRecord();

        Test.stopTest();

        Id lastCreatedChangeOrderId = ApexWebServices.getLastCreatedChangeOrderId(proservProjectForInitialCCProserv.Id);
        Assert.areEqual(lastCreatedChangeOrderId, secondCCProservOrder.Id);
    }
    @isTest
    static void testValidFunnelSignUpRequest() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test acc',
                    Account.Internal_Enterprise_Account_ID__c => '12345'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD',
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE
                })
            .create()
            .getRecord();
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Quote testQuote2 = TestDataGenerator.createQuote(testOpp);
        FunnelAPI.signupResult signupRes = new FunnelAPI.signupResult();
        signupRes.status = 'COMPLETED';
        FunnelAPI.UnifiedCallbackFunnel request = new FunnelAPI.UnifiedCallbackFunnel();
        request.salesAgentId = testOpp.Id;
        request.salesOrderId = testOpp.Id;
        request.serviceOrderId = testQuote2.Id;
        request.signupResult = signupRes;
        
        req.requestURI = '/services/apexrest/SignUpAccountWsBilling/';
        req.httpMethod = 'PUT';
        req.requestBody = Blob.valueOf(JSON.serializePretty(request));

        RestContext.request = req;
   	    RestContext.response = res;

        Test.startTest();
        SignUpAccountWsBilling.handleFunnelSignUpResponse();
        Test.stopTest();

        Account updAcc = (Account) new AccountSelector()
            .selectAccountById(testAcc.Id)
            .selectField(Account.Internal_Enterprise_Account_ID__c)
            .executeQuery()
            .get(0);

        System.assertEquals(updAcc.Internal_Enterprise_Account_ID__c, null);
    }
}