@IsTest
private class Test_OrderItemTriggerHelper {

    private static Pricebook2 testPricebook;
    private static Account testAccount;
    private static Product2 testProduct;
    private static Contact testContact;
    private static PricebookEntry testPrice;

    private static void prepareData(String productName, Decimal productFeature) {
        testAccount = new Account(Name='Opty test account',
                    Permitted_Brands__c='RingCentral');
        insert testAccount;

        testContact = new Contact();
        testContact.AccountId =  testAccount.id;
        testContact.Email = 'fake@email.com';
        testContact.LastName = 'TestLast';
        testContact.Phone='9910106804';
        insert testContact;

        Id pricebookId = Test.getStandardPricebookId();

        testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Line_Range_Max__c = 10,
            CurrencyIsoCode = 'USD');
        insert testPriceBook;

        testProduct = new Product2(
            Name = productName,
            IsActive = true,
            Feature__c = productFeature,
            Charge_Term__c = 'Annual');
        insert testProduct;

        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD');
        insert standardPrice;

        testPrice = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 2,
            Max_Quantity__c = 5,
            Max_DIscount__c = 10,
            CurrencyIsoCode = 'USD');
        insert testPrice;
    }

    @IsTest static void testInsertItemZeroQuantity() {
        prepareData('Connect Pro - Annual Fee', null);
        Order ord = new Order(
            AccountId = testAccount.Id,
            Pricebook2Id = testPricebook.Id,
            EffectiveDate = System.today(),
            Status = 'Requested');
        insert ord;

        OrderItem item;

        Test.startTest();
        item = new OrderItem(
            OrderId = ord.Id,
            PriceBookEntryId = testPrice.Id,
            Quantity = 0,
            UnitPrice = 200);
        insert item;
        Test.stopTest();

        item = [SELECT Id, Quantity, Zero_Quantity__c
                FROM OrderItem
                WHERE Id = :item.Id];

        System.assertEquals(true, item.Zero_Quantity__c);
        System.assertEquals(1, item.Quantity);
    }

    @IsTest static void testUpdateItemNonZeroQuantity() {
        prepareData('Connect Pro - Annual Fee', null);
        Order ord = new Order(
            AccountId = testAccount.Id,
            Pricebook2Id = testPricebook.Id,
            EffectiveDate = System.today(),
            Status = 'Requested');
        insert ord;

        OrderItem item;

        item = new OrderItem(
            OrderId = ord.Id,
            PriceBookEntryId = testPrice.Id,
            Quantity = 0,
            UnitPrice = 200);
        insert item;

        Test.startTest();
        item.Quantity = -1;
        update item;
        Test.stopTest();

        item = [SELECT Id, Quantity, Zero_Quantity__c
                FROM OrderItem
                WHERE Id = :item.Id];

        System.assertEquals(false, item.Zero_Quantity__c);
        System.assertEquals(-1, item.Quantity);
    }

    @IsTest
    static void testNotifyProserv() {
        Test.startTest();
        //Create test product with appropriate feature
        prepareData(Product2Helper.NAME_EXTENDED_ENTERPRISE_SUPPORT_GOLD, Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT);
        //Create Emails__c custom setting
        Emails__c cs = new Emails__c (Name = 'proservleaders', Email_Address__c = 'test@gmail.com');
        insert cs;
        //Insert basic test data
        Opportunity opp = new Opportunity(
            Name = 'testOpportunity',
            AccountId = testaccount.id,
            Type = 'New Business',
            CloseDate = System.today() + 90,
            StageName = 'Qualify'
        );
        insert opp;

        Order ord = new Order(
            AccountId = testAccount.Id,
            OpportunityId = opp.Id,
            Pricebook2Id = testPricebook.Id,
            EffectiveDate = System.today(),
           Status = 'Submitted');
        insert ord;

        OrderItem item = new OrderItem(
            OrderId = ord.Id,
            Product2Id= testProduct.Id,
            PriceBookEntryId = testPrice.Id,
            Quantity = 10,
            UnitPrice = 200);

        Integer emailInvocations = null;

        try{
            insert item;
            emailInvocations = Limits.getEmailInvocations();
            Test.stopTest();
        }catch(Exception ex) {
            ExceptionHelper.checkIsMassEmailException(ex);
            return;
        }

        //Check the number of email invocations (such as sendEmail) that have been called
        System.assertEquals(1, emailInvocations, 'An email has not been sent');
    }

    //B-2940 Estimated ProServ MRR field calculation
    private static final String ORDER_RC_RT_NAME = 'RingCentral';
    private static final String ORDER_PROF_SERVICE_RT_NAME = 'Professional Services';
    private static final map<String,schema.RecordTypeInfo> ORDER_RT_INFO_BY_NAME = Order.SObjectType.getDescribe().getRecordTypeInfosByName();
    private static final Id standardPricebookId = test.getStandardPricebookId();

    private static Order createOrder(String orderRecordTypeName){
        Order order = new Order(
            AccountId = testAccount.Id,
            Pricebook2Id = testPricebook.Id,
            EffectiveDate = system.today(),
            Status = 'Requested',
            RecordTypeId = ORDER_RT_INFO_BY_NAME.get(orderRecordTypeName).getRecordTypeId()
        );
        insert order;
        return order;
    }

    private static Product2 createProduct(String chargeTerm, String subCategory){
        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = true,
            Charge_Term__c = chargeTerm,
            Sub_Category__c = subCategory
        );
        return product;
    }

    private static PricebookEntry createPricebookEntry(Id productId, Boolean isStandard){
        PricebookEntry price = new PricebookEntry(
            Product2Id = productId,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );

        if(isStandard) {
            price.Pricebook2Id = standardPricebookId;
        } else{
            price.Pricebook2Id = testPricebook.Id;
            price.Per_Line__c = false;
            price.Min_Quantity__c = 2;
            price.Max_Quantity__c = 5;
            price.Max_DIscount__c = 10;
        }
        return price;
    }

    private static OrderItem createOrderItem(Id orderId, Id productId, Id priceEntryId, Integer qty, Decimal price){
        OrderItem orderItem = new OrderItem(
            Quantity = qty,
            OrderId = orderId,
            UnitPrice = price,
            Product2Id = productId,
            PriceBookEntryId = priceEntryId
        );
        return orderItem;
    }

    private static void checkOrderEstimatedProServMRR(Id orderId, Decimal estimatedProServMRR){
        list<Order> orders = [SELECT Estimated_ProServ_MRR__c FROM Order WHERE Id = :orderId];
        system.assertEquals(orders.size(), 1);
        system.assertEquals(orders[0].Estimated_ProServ_MRR__c, estimatedProServMRR);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest static void testCalcEstimatedProServMRR_OtherSubCategory(){
        prepareData('Connect Pro - Annual Fee', null);
        Order order = createOrder(ORDER_RC_RT_NAME);
        Product2 productAnnual = createProduct('Annual','Main');
        insert productAnnual;
        PricebookEntry standardPrice = createPricebookEntry(productAnnual.Id, true);
        insert standardPrice;
        PricebookEntry price = createPricebookEntry(productAnnual.Id, false);
        insert price;
        OrderItem orderItem = createOrderItem(order.Id, productAnnual.Id, price.Id, 12, 100);

        test.startTest();
            insert orderItem;
            // Estimated_ProServ_MRR__c is calculated on trigger isDelete, isUpdate
            update orderItem;
        test.stopTest();

        checkOrderEstimatedProServMRR(order.Id, 0);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest static void testCalcEstimatedProServMRR_ProperSubCategory(){
        prepareData('Connect Pro - Annual Fee', null);
        Order orderRC = createOrder(ORDER_RC_RT_NAME);

        list<Product2> products = new list<Product2>{
            createProduct('Annual','Professional Services'),
            createProduct('Monthly - Contract','CC Professional Services')
        };
        insert products;

        list<PricebookEntry> standardPrices = new list<PricebookEntry>{
            createPricebookEntry(products[0].Id, true),
            createPricebookEntry(products[1].Id, true)
        };
        insert standardPrices;

        list<PricebookEntry> prices = new list<PricebookEntry>{
            createPricebookEntry(products[0].Id, false),
            createPricebookEntry(products[1].Id, false)
        };
        insert prices;

        list<OrderItem> orderItems = new list<OrderItem>{
            createOrderItem(orderRC.Id, products[0].Id, prices[0].Id, 12, 100),
            createOrderItem(orderRC.Id, products[1].Id, prices[1].Id, 5, 5)
        };

        test.startTest();
            insert orderItems;
            // Estimated_ProServ_MRR__c is calculated on trigger isDelete, isUpdate
            update orderItems;
        test.stopTest();

        checkOrderEstimatedProServMRR(orderRC.Id, 125);
    }
    //Tests if OrderItem__c lookUp phase line item is correctly populated
    @IsTest
    public static void testUpdatePhaseLineItem() {
        //Insert basic test objects
        Account testAcc = new Account(
            Name = 'testAccount'
        );
        insert testAcc;

        Opportunity testOpp = new Opportunity(
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Professional',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert testOpp;

        Quote proservTestQuote = new Quote (Name='proservTestQuote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV,
            ProServ_Status__c = 'In Progress');
        insert (new List<Quote>{proservTestQuote});
        //Create a couple of products
        Product2 testProservProduct1 = new Product2(
                Name = 'TestProserv1',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'Professional Services'
        );
        Product2 testProservProduct2 = new Product2(
                Name = 'TestProserv2',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'Professional Services'
        );
        insert (new List<Product2>{testProservProduct1,testProservProduct2});
        //Create price book entries for products
        PricebookEntry testPrice1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct1.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        PricebookEntry testPrice2 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct2.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        insert (new List<PricebookEntry>{testPrice1, testPrice2});
        //Create quote line items
        QuoteLineItem qli1 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem1',
                Quantity = 3,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct1.Id,
                PricebookEntryId = testPrice1.Id
        );
        QuoteLineItem qli2 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem2',
                Quantity = 3,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct2.Id,
                PricebookEntryId = testPrice2.Id
        );

        Test.startTest();
        insert (new List<QuoteLineItem>{qli1, qli2});
        //Create test phases
        Phase__c testPhase1 = new Phase__c(
            Name = 'testPhase1',
            RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId()
        );
        Phase__c testPhase2 = new Phase__c(
            Name = 'testPhase2',
            RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId()
        );
        insert (new List<Phase__c>{testPhase1, testPhase2});
        //Distribute quote line items between phases
        Hardware_Line_Item__c testHLI1 = new Hardware_Line_Item__c(
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quote_Line_Item__c = qli1.Id,
                Quantity__c = 3
        );
        Hardware_Line_Item__c testHLI2 = new Hardware_Line_Item__c(
                RingCentral_Hardware_Phase__c = testPhase2.Id,
                Quote_Line_Item__c = qli2.Id,
                Quantity__c = 3
        );
        insert (new List<Hardware_Line_Item__c>{testHLI1, testHLI2});
        //Create test order
        Order testOrder = new Order(
            AccountId = testAcc.Id,
            QuoteId = proservTestQuote.Id,
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate = System.today(),
            Status = 'Requested');
        insert (new List<Order>{testOrder});
        //Create order items for every quote line item
        OrderItem testOrderItem1 = new OrderItem(
            OrderId = testOrder.Id,
            PriceBookEntryId = testPrice1.Id,
            Quantity = 3,
            UnitPrice = 50,
            QuoteLineItemId = qli1.Id
        );
        OrderItem testOrderItem2 = new OrderItem(
            OrderId = testOrder.Id,
            PriceBookEntryId = testPrice2.Id,
            Quantity = 3,
            UnitPrice = 50,
            QuoteLineItemId = qli2.Id
        );
        insert (new List<OrderItem>{testOrderItem1, testOrderItem2});
        Test.stopTest();
        //Check if Order__c and Order_Line_Item__c fields on phase line item object are populated with correct lookUp to order item and order
        Hardware_Line_Item__c updatedHli1 = [SELECT Id, Order_Line_Item__c, Order__c
                                            FROM Hardware_Line_Item__c WHERE RingCentral_Hardware_Phase__c =: testPhase1.Id];
        System.assertEquals(testOrderItem1.Id, updatedHli1.Order_Line_Item__c);
        System.assertEquals(testOrderItem1.Order.id, updatedHli1.Order__c);
    }

    @IsTest
    static void testCalculateTotalsOnOrder() {
        Triggers.switchOff();
        Triggers.except('OrderItemTriggerHelper.CalculateTotalsOnOrder');
        Account masterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Validate Account'),
                    Account.Partner_ID__c => '1234567',
                    Account.Payment_Method__c => 'Invoice',
                    Account.Payment_Plan__c => 'Monthly',
                    Account.RC_User_ID__c => '400389021062',
                    Account.Billing_ID__c => '5037002',
                    Account.BillingPostalCode => 'testCode',
                    Account.BillingCity => 'testCity',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingState => 'testState',
                    Account.BillingStreet => 'testStreet'
                }
            )
            .create()
            .getRecord();

        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.AccountId => masterAccount.Id,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                    Opportunity.CloseDate => System.today() + 90
                })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => masterOpp.Id,
                Quote.Account__c => masterAccount.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        List<Product2> prodMinuteBundle = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Inbound Toll Free 25K Bundle',
                Product2.Family => 'Family',
                Product2.Charge_Term__c => 'One - Time',
                Product2.IsActive => true,
                Product2.Sub_Category__c => 'Main',
                Product2.ExtId__c => Product2Helper.MINUTE_BUNDLE_EXT_ID
            })
            .quantity(1)
            .create()
            .getRecords();

        List<Product2> prodRecurring = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('Product'),
                Product2.Family => 'Family',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.IsActive => true,
                Product2.Sub_Category__c => 'Main',
                Product2.ExtID__c => ValueProviderBuilder.provideUniqueString('ExtID:')
            })
            .quantity(10)
            .create()
            .getRecords();


        List<Product2> prodSeat = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('Product Seat'),
                Product2.Family => 'Family',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.IsActive => true,
                Product2.Sub_Category__c => 'Main',
                Product2.ExtID__c => ValueProviderBuilder.provideUniqueString('ExtID1:')
            })
            .quantity(3)
            .create()
            .getRecords();

        List<Product2> prodOverage = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('Product Overage'),
                Product2.Family => 'Family',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.IsActive => true,
                Product2.Sub_Category__c => 'Main',
                Product2.ExtID__c => ValueProviderBuilder.provideUniqueString('ExtID2:'),
                Product2.Billing_Type__c => Product2Helper.BILLING_TYPE_USAGE
            })
            .quantity(1)
            .create()
            .getRecords();

        List<PricebookEntry> pbeMinuteBundle = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(prodMinuteBundle),
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .quantity(1)
            .create()
            .getRecords();

        List<PricebookEntry> pbeRecurring = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(prodRecurring),
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .quantity(10)
            .create()
            .getRecords();

        List<PricebookEntry> pbeSeat = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(prodSeat),
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .quantity(3)
            .create()
            .getRecords();

        List<PricebookEntry> pbeOverage = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(prodOverage),
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .quantity(1)
            .create()
            .getRecords();

        List<Package_Main_Licenses__c> mpl = (List<Package_Main_Licenses__c>) new SObjectBuilder(Package_Main_Licenses__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package_Main_Licenses__c.Name => ValueProviderBuilder.provideUniqueString('Office: Default'),
                Package_Main_Licenses__c.Main_License__c => ValueProviderBuilder.provideList(
                    (List<String>) AquivaHelper.collectFieldValues(
                        List<String>.class,
                        prodSeat,
                        'ExtID__c',
                        true
                    )
                ),
                Package_Main_Licenses__c.Package_Group__c => 'Office'
            })
            .quantity(3)
            .create()
            .getRecords();

        List<QuoteLineItem> qliMinuteBundle = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.ServiceDate => Date.today(),
                QuoteLineItem.Description => ValueProviderBuilder.provideUniqueString('Test Quote Line Item'),
                QuoteLineItem.Quantity => ValueProviderBuilder.providerRandomDecimal(1, 20, 0),
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.UnitPrice => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                QuoteLineItem.Discount => 5,
                QuoteLineItem.Discount_type__c => 'Percentage',
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(prodMinuteBundle),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeMinuteBundle),
                QuoteLineItem.TotalSummary__c => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2)
            })
            .quantity(1)
            .create()
            .getRecords();
        List<QuoteLineItem> qliRecurring = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.ServiceDate => Date.today(),
                QuoteLineItem.Description => ValueProviderBuilder.provideUniqueString('Test Quote Line Item'),
                QuoteLineItem.Quantity => ValueProviderBuilder.providerRandomDecimal(1, 20, 0),
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.UnitPrice => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                QuoteLineItem.Discount => 5,
                QuoteLineItem.Discount_type__c => 'Percentage',
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(prodRecurring),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeRecurring),
                QuoteLineItem.TotalSummary__c => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                QuoteLineItem.ChargeTerm__c => QuoteLineItemHelper.CHARGE_TERM_MONTHLY
            })
            .quantity(10)
            .create()
            .getRecords();
        List<QuoteLineItem> qliSeat = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.ServiceDate => Date.today(),
                QuoteLineItem.Description => ValueProviderBuilder.provideUniqueString('Test Quote Line Item'),
                QuoteLineItem.Quantity => ValueProviderBuilder.providerRandomDecimal(1, 20, 0),
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.UnitPrice => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                QuoteLineItem.Discount => 5,
                QuoteLineItem.Discount_type__c => 'Percentage',
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(prodSeat),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeSeat),
                QuoteLineItem.TotalSummary__c => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                QuoteLineItem.NewQuantity__c => ValueProviderBuilder.providerRandomDecimal(1, 20, 0),
                QuoteLineItem.ChargeTerm__c => QuoteLineItemHelper.CHARGE_TERM_MONTHLY
            })
            .quantity(3)
            .create()
            .getRecords();
        List<QuoteLineItem> qliOverage = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.ServiceDate => Date.today(),
                QuoteLineItem.Description => ValueProviderBuilder.provideUniqueString('Test Quote Line Item'),
                QuoteLineItem.Quantity => ValueProviderBuilder.providerRandomDecimal(1, 20, 0),
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.UnitPrice => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                QuoteLineItem.Discount => 5,
                QuoteLineItem.Discount_type__c => 'Percentage',
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(prodOverage),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeOverage),
                QuoteLineItem.TotalSummary__c => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                QuoteLineItem.ChargeTerm__c => QuoteLineItemHelper.CHARGE_TERM_MONTHLY
            })
            .quantity(1)
            .create()
            .getRecords();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.AccountId => masterAccount.Id,
                Order.QuoteId => qt.Id,
                Order.OpportunityId => masterOpp.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => System.today(),
                Order.Status => 'Requested'
            })
        .create()
        .getRecord();

        Test.startTest();
            List<PricebookEntry> pbeList = new List<PricebookEntry>(pbeMinuteBundle);
            pbeList.addAll(pbeRecurring);
            pbeList.addAll(pbeSeat);
            pbeList.addAll(pbeOverage);
            List<QuoteLineItem> qliList = new List<QuoteLineItem>(qliMinuteBundle);
            qliList.addAll(qliRecurring);
            qliList.addAll(qliSeat);
            qliList.addAll(qliOverage);

            List<OrderItem> oiList = (List<OrderItem>) new SObjectBuilder(OrderItem.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    OrderItem.OrderId => testOrder.Id,
                    OrderItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeList),
                    OrderItem.Quantity => ValueProviderBuilder.providerRandomDecimal(1, 10, 0),
                    OrderItem.UnitPrice => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                    OrderItem.QuoteLineItemId => ValueProviderBuilder.provideParents(qliList)
                })
                .quantity(14)
                .create()
                .getRecords();
        Test.stopTest();
        Triggers.switchOn();

            List<Order> updatedOrder = (List<Order>) new OrderSelector()
                .selectOrders()
                .subselect(
                    new OrderItemSelector()
                        .selectOrderItems()
                        .selectFields(new List<String> {
                            'Quantity',
                            'UnitPrice',
                            'TotalPrice',
                            'TotalSummary__c',
                            'NewQuantity__c',
                            'ChargeTerm__c',
                            'EffectivePrice__c',
                            'Product2Id',
                            'Product2.Id',
                            'Product2.ExtID__c',
                            'Product2.Billing_Type__c',
                            'QuoteLineItemId',
                            'QuoteLineItem.Id',
                            'QuoteLineItem.EffectivePrice__c',
                            'QuoteLineItem.TotalSummary__c',
                            'QuoteLineItem.NewQuantity__c',
                            'QuoteLineItem.ChargeTerm__c',
                            'QuoteLineItem.Product_Lic_Id__c'
                        })
                )
                .selectFields(new List<String> {
                    'Id',
                    'RecordTypeId',
                    'MinuteBundle__c',
                    'TransportMRR__c',
                    'Recurring_Total__c',
                    'SeatMRR__c',
                    'NumberOfMainLicenses__c'
                })
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{testOrder.Id})
                .executeQuery();

        for (Order ord : updatedOrder) {
            Decimal expectedTransportMRR = 0;
            Decimal expectedMinuteBundle = 0;
            Decimal expectedRecurringTotal = 0;
            Decimal expectedSeatMrr = 0;
            Decimal expectedNumOfLicenses = 0;

            for (OrderItem oi : ord.OrderItems) {

                if (QuoteLineItemHelper.RECURRING_CHARGE_TERM_VALUES.contains(oi.QuoteLineItem.ChargeTerm__c)
                    && oi.Product2.Billing_Type__c != Product2Helper.BILLING_TYPE_USAGE) {
                    expectedRecurringTotal += oi.EffectivePrice__c * oi.NewQuantity__c;
                }
                if (QuoteLineItemHelper.isSeatQli(oi.QuoteLineItem)) {
                    expectedSeatMrr += oi.QuoteLineItem.TotalSummary__c;
                    if (ord.RecordTypeId != OrderHelper.SERVICE_NAME_TO_RT_ID.get(QuoteHelper.NGBS_OFFICE_PRODUCT)) {
                        expectedNumOfLicenses += (Decimal) NumberHelper.getNumberNullSafe(oi.QuoteLineItem.NewQuantity__c);
                    }
                }
                if (oi.Product2.ExtID__c.contains(Product2Helper.MINUTE_BUNDLE_EXT_ID)) {
                    expectedMinuteBundle += oi.Quantity * Product2Helper.MINUTE_BUNDLE_CC_QUANTITY;
                    expectedTransportMRR += oi.EffectivePrice__c * oi.NewQuantity__c;
                }
            }

            System.assertEquals(expectedMinuteBundle, ord.MinuteBundle__c,
                'MinuteBundle__c on Order should be equal to Quantity on minute bundle order item');
            System.assertEquals(expectedTransportMRR, ord.TransportMRR__c,
                'TransportMRR__c on Order should be equal to sum of all order items');
            System.assertEquals(expectedRecurringTotal, ord.Recurring_total__c,
                'RecurringTotal__c on Order should be equal to sum of all order items');
            System.assertEquals(expectedNumOfLicenses, ord.NumberOfMainLicenses__c,
                'NumOfLicenses__c on Order should be equal to sum of all order items');
            System.assertEquals(expectedSeatMrr, ord.SeatMRR__c,
                'SeatMRR__c on Order should be equal to sum of all order items');
        }
    }
}