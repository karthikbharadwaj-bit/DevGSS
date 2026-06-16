@isTest
private class Test_SubmitOrderPopUpController {
    private static Account testAcc;
    private static Order testOrder;
    private static OrderItem testOrderItem;
    private static User testUser = createUser('test'); // testUser with admin profile

    private static void createTestData() {
        Triggers.switchOff();
        testAcc = new Account(
                Name = 'testAcc',
                inContact_Account_Id__c = '1234',
                RC_User_Id__c = 'test',
                RC_Account_Number__c = 'test',
                Timezone__c = 'Asia/Calcutta'
            );
        insert testAcc;

        Contact testContact = new Contact(
                AccountId = testAcc.Id,
                LastName = 'Testerfield',
                FirstName = 'Tester',
                Email = 'fake@email.kek'
            );
        insert testContact;
        Triggers.switchOn();

        Opportunity testOpp = new Opportunity (
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Professional',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
        insert testOpp;

        //Create test product
        Product2 testProduct = new Product2(
                Name = 'testProduct3',
                IsActive = true,
                Family = 'Overage',
                Product_Type__c ='Port',
                catID__c = '309-11-171',
                Number_of_Minutes__c = 250000,
                Edition__c = 'Ultimate',
                Sub_Category__c = 'Contact Center',
                Charge_Term__c = 'Annual'
            );
        insert testProduct;

        //Create price book entry for product
        PricebookEntry testPrice = new PricebookEntry (
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
            );
        insert testPrice;

        Quote testQuote = new Quote (Name='testQuote',
                OpportunityId = testOpp.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                RecordTypeId = QuoteHelper.RT_ID_SALES
            );
        insert testQuote;

        //Create quote line item
        QuoteLineItem qli = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem1',
                Quantity = 3,
                QuoteId = testQuote.Id,
                UnitPrice = 50,
                Product2Id = testProduct.Id,
                PricebookEntryId = testPrice.Id
            );
        insert qli;

        testOrder = new Order(
                AccountId = testAcc.Id,
                OpportunityId = testOpp.Id,
                EffectiveDate = System.today(),
                Status = 'New',
                QuoteId = testQuote.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                RingCentral_Account_Number__c = 'testRCAccountNumber',
                RecordTypeId = OrderHelper.RT_ID_CC
            );
        insert testOrder;

        //Create test order item
        testOrderItem = new OrderItem (
                OrderId = testOrder.Id,
                PriceBookEntryId = testPrice.Id,
                Quantity = 3,
                UnitPrice = 50,
                QuoteLineItemId = qli.Id,
                Zero_Quantity__c = true,
                Active__c = true
            );
        insert testOrderItem;
    }

    private static User createUser(String name){
        User user = new User(
                Username = name+'!user@gmail.com',
                LastName = 'Test'+name,
                Email = name+'_user@gmail.com',
                Alias = 'test'+name,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                LanguageLocaleKey = 'en_US'
            );
        insert user;
        return user;
    }

    @isTest
    public static void testCreateCase() {

        System.runAs(testUser) {

            createTestData();

            PageReference pageRef = Page.Submit_Order_PopUp;
            Test.setCurrentPage(pageRef);

            ApexPages.currentPage().getParameters().put('id', testOrder.Id);

            Id inContactOrderRtId = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND Name = 'inContact Order'].Id;

            Test.startTest();

            SubmitOrderPopUpController cntrlr = new SubmitOrderPopUpController();

            String subjectValue = 'test_Subject';
            cntrlr.isValidPopUpValues();
            cntrlr.validateFromVF();
            cntrlr.getGeoRegionValues();
            cntrlr.getCaseOriginValues();
            cntrlr.getProductOrServiceValues();
            cntrlr.getImplementationTeamValues();
            cntrlr.getOrder();

            cntrlr.subject = subjectValue;
            cntrlr.ccOrderType='New';
            cntrlr.contactCenterNumber='test';
            cntrlr.defaultTimeZone='Asia/Calcutta';
            cntrlr.geoRegion='US';
            cntrlr.description='test';
            cntrlr.subject='test_Subject';
            cntrlr.contactName='test@gmail123.com';
            cntrlr.implementationTeam='RingCentral';
            cntrlr.inContactSegment='1-50 Seats';
            cntrlr.inContactBuId=0;
            cntrlr.createCaseFromVF();

            Id createdCaseId = cntrlr.newCaseId;

            Case createdCase = [SELECT Id, AccountId, Order__c, Opportunity_Reference__c,
                                        CC_Order_Type__c, inContact_BU_ID__c, Contact_Center_Number__c,
                                        RingCentral_Account_Number__c, Default_Time_Zone__c, Geo_Region__c,
                                        description, subject, Origin, Product_or_Service__c, Contact_Name__c,
                                        Implementation_Team__c, Customer_Notification__c, RecordTypeId
                                FROM Case
                                WHERE Id = :createdCaseId];

            System.assert(createdCase.subject == subjectValue, createdCase.subject + ' != ' + subjectValue);
            System.assert(createdCase.Default_Time_Zone__c == testAcc.Timezone__c, createdCase.Default_Time_Zone__c + ' != ' + testAcc.Timezone__c);
            //System.assert(createdCase.Contact_Center_Number__c == testOrder.Contact_Center_Number__c, createdCase.Contact_Center_Number__c + ' != ' + testOrder.Contact_Center_Number__c);
            System.assert(createdCase.RingCentral_Account_Number__c == testOrder.RingCentral_Account_Number__c, createdCase.RingCentral_Account_Number__c + ' != ' + testOrder.RingCentral_Account_Number__c);
            System.assert(createdCase.Customer_Notification__c == false, createdCase.Customer_Notification__c + ' != ' + false);
            System.assert(createdCase.RecordTypeId == inContactOrderRtId, createdCase.RecordTypeId == inContactOrderRtId);

            Order reselectedOrder = [SELECT Id, AccountId, Status FROM Order WHERE Id = : testOrder.Id];

            System.assert(reselectedOrder.Status == 'Submitted', reselectedOrder.Status + ' != ' + 'Submitted');

            Test.stopTest();
        }
    }

    @isTest public static void testBillingStatusUpdate() {
        System.runAs(testUser) {

            createTestData();

            Order updOrder = new Order(
                Id = testOrder.Id,
                Status = OrderHelper.STATUS_SUBMITTED,
                inContact_Account_ID__c = '11111222',
                Contact_Center_Number__c = '56565656'
            );
            update updOrder;

            PageReference pageRef = Page.Submit_Order_PopUp;
            Test.setCurrentPage(pageRef);

            ApexPages.currentPage().getParameters().put('id', testOrder.Id);
            SubmitOrderPopUpController cntrlr = new SubmitOrderPopUpController();
            cntrlr.updateBillingStatus();
            System.assertEquals('Submitted', [SELECT BillingStatus__c FROM Quote LIMIT 1].BillingStatus__c);
            System.assertEquals('Submitted', [SELECT BillingStatus__c FROM Order LIMIT 1].BillingStatus__c);
        }
    }

    @isTest public static void testUpdateOrderItemsBillingStatus() {
        System.runAs(testUser) {

            createTestData();

            testOrderItem.BillingStatus__c = 'Replaced';
            update testOrderItem;

            testOrder.Status = OrderHelper.STATUS_SUBMITTED;
            testOrder.inContact_Account_ID__c = '11111222';
            testOrder.Contact_Center_Number__c = '56565656';
            update testOrder;

            testOrder.Submitted_Date__c = Datetime.newInstance(2022, 11, 17);
            update testOrder;

            Test.startTest();
            SubmitOrderPopUpController.updateOrderItemsBillingStatus(testOrder.Id);
            Test.stopTest();

            OrderItem updatedOrderItem = [SELECT BillingStatus__c FROM OrderItem WHERE Id =: testOrderItem.Id];

            System.assertEquals('Cancelled', updatedOrderItem.BillingStatus__c);
        }
    }

    @isTest public static void testSerializeOrderItem_bundle() {

        OrderItem item = new OrderItem();
        item.Quantity = -1;
        item.BillingStatus__c = 'Cancelled';
        item.PricebookEntry = new PricebookEntry();
        item.PricebookEntry.Product2 = new Product2(
            Name = 'Contact Center: Textel (Up to 2,000,000 Messages)',
            Family = Product2Helper.FAMILY_ADDONS,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_MESSAGES,
            CatID__c = '123-456-789',
            InContact_Name__c = 'Textel 2M Messages (per BU)',
            inContact_Price__c = 9999
        );
        System.runAs(testUser) {
            String result = SubmitOrderPopUpController.serializeOrderItem(item);
            System.assertEquals(
                '-1.00[123-456-000] Textel 2M Messages (per BU) $9999\n',
                result,
                'Incorrect transformation of a Textel bundle'
            );
        }
    }

    @isTest public static void testSerializeOrderItem_textelOverage() {

        OrderItem item = new OrderItem();
        item.Quantity = -1;
        item.BillingStatus__c = 'Cancelled';
        item.PricebookEntry = new PricebookEntry();
        item.PricebookEntry.Product2 = new Product2(
            Name = 'Contact Center: Textel (Up to 2,000,000 Messages) Overage',
            Family = Product2Helper.FAMILY_OVERAGE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_MESSAGES,
            CatID__c = '123-456-789',
            InContact_Name__c = 'test inContact Name',
            inContact_Price__c = 9999
        );
        System.runAs(testUser) {
            String result = SubmitOrderPopUpController.serializeOrderItem(item);
            System.assertEquals(
                '-0.00[123-456-789] Textel Overage Rate Beyond 2M (per Message) $9999\n',
                result,
                'Incorrect transformation of a Textel Overage'
            );
        }
    }
}