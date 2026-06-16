@isTest
private class Test_ChangeOrder {

    private static Account testAccount;

    static void createTestData() {
        Id standardPriceBookId = Test.getStandardPricebookId();

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            LastName = 'TestLastName',
            FirstName = 'TestFirstName',
            Email = 'test@test.com');
        insert testContact;

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

        // Price Book
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

        // Products
        List<Product2> testProducts = new List<Product2>();

        Product2 testProduct = new Product2(
            Name = 'Connect Pro - Annual Fee',
            Family = 'Office',
            IsActive = true,
            Sub_Category__c = 'Main');
        testProducts.add(testProduct);

        Product2 testServiceProduct = new Product2(
            Name = 'Connect Pro - Annual Fee',
            Family = 'Service',
            IsActive = true,
            Sub_Category__c = 'Contact Center');
        testProducts.add(testServiceProduct);

        insert testProducts;

        // Price book Entry
        List<PricebookEntry> testPricebookEntrys = new List<PricebookEntry>();

        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false
        );
        testPricebookEntrys.add(standardPrice);

        PricebookEntry testPrice = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        testPricebookEntrys.add(testPrice);

        PricebookEntry standardServicePrice = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = testServiceProduct.Id,
            UnitPrice = 100, IsActive = true,
            UseStandardPrice = false
        );
        testPricebookEntrys.add(standardServicePrice);

        PricebookEntry testServicePrice = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id,
            Product2Id = testServiceProduct.Id,
            UnitPrice = 100, IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        testPricebookEntrys.add(testServicePrice);

        insert testPricebookEntrys;

        // Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            Type = 'Syndicated - New',
            StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
            CloseDate = System.today(),
            Brand_Name__c = 'RingCentral',
            PriceBook2Id = testPriceBook.Id,
            Primary_Opportunity_Contact__c = testContact.Id,
            Tier_Name__c = '999',
            AccountId = testAccount.Id
        );
        insert opp;

        // Quote
        Quote testQuote = new Quote (
            Name = 'Test Quote',
            OpportunityId = opp.id,
            Status = 'Draft',
            Pricebook2Id = testPriceBook.id,
            Total_Number_of_Digital_Lines__c = 5,
            FaxAreaCode__c = areaCode.Id,
            AreaCode__c = areaCode.Id
        );
        insert testQuote;

        // Quote line items
        List<QuoteLineItem> testQuoteLineItems = new List<QuoteLineItem>();

        QuoteLineItem testQuoteLineItem = new QuoteLineItem (
            ServiceDate = date.today(),
            Description = 'TestLineItem',
            UnitPrice = testPrice.UnitPrice,
            Quantity = 5,
            QuoteId = testQuote.Id,
            PriceBookEntryId = testPrice.Id,
            Product2Id = testProduct.Id
        );
        testQuoteLineItems.add(testQuoteLineItem);

        QuoteLineItem testServiceQuoteLineItem =  new QuoteLineItem (
            ServiceDate = date.today(),
            Description = 'TestServiceLineItem',
            UnitPrice = testServicePrice.UnitPrice,
            Quantity = 5,
            QuoteId = testQuote.Id,
            PriceBookEntryId = testServicePrice.Id,
            Product2Id = testProduct.Id
        );
        testQuoteLineItems.add(testServiceQuoteLineItem);

        insert testQuoteLineItems;


        Id proServOrderRTId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

        // Orders
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            OpportunityId = opp.Id,
            Status = 'Submitted',
            Pricebook2Id = standardPrice.Pricebook2Id,
            EffectiveDate = System.today(),
            RecordTypeId = proServOrderRTId
        );
        insert testOrder;

        // Order Items
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Quantity = testQuoteLineItem.Quantity,
            UnitPrice = testQuoteLineItem.UnitPrice,
            PriceBookEntryId = standardPrice.Id
        );
        insert testOrderItem;

        Id proServPhaseRTId =  Phase__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId();

        // Phases
        Phase__c ph1 = new Phase__c(
            Name = 'testPhase_1',
            Opportunity__c = opp.Id,
            Quote__c = testQuote.Id,
            Order__c = testOrder.Id,
            RecordTypeId = proServPhaseRTId
        );

        Phase__c ph2 = new Phase__c(
            Name = 'testPhase_2',
            Opportunity__c = opp.Id,
            Quote__c = testQuote.Id,
            Order__c = testOrder.Id,
            RecordTypeId = proServPhaseRTId
        );

        insert new List<Phase__c>{
            ph1, ph2
        };

        // Phase Line Items
        Hardware_Line_Item__c hli1 = new Hardware_Line_Item__c(
            Name = 'test PhaseLineItem for Phase1',
            Quantity__c = 3,
            Quote_Line_Item__c = testQuoteLineItem.Id,
            RingCentral_Hardware_Phase__c = ph1.Id
        );

        Hardware_Line_Item__c hli2 = new Hardware_Line_Item__c(
            Name = 'test PhaseLineItem for Phase2',
            Quantity__c = 2,
            Quote_Line_Item__c = testQuoteLineItem.Id,
            RingCentral_Hardware_Phase__c = ph2.Id
        );

        insert new List<Hardware_Line_Item__c>{
            hli1, hli2
        };
    }

    @isTest
    static void testChangeOrder() {
        Test.startTest();
            Triggers.switchOff();

            Feature_Toggle__c featureToogleSetting = Feature_Toggle__c.getInstance();
            featureToogleSetting.NewChangeOrderFlow__c = true;
            insert featureToogleSetting;

            testAccount = new Account(
                Name = 'Test Account',
                Number_of_DL_s__c = 10,
                BillingCity = 'TestCity',
                BillingStreet = 'TestStreet',
                Payment_Method__c = 'Invoice',
                SignupType__c = 'Direct');
            insert testAccount;

            Id standardPriceBookId = Test.getStandardPricebookId();

            Contact testContact = new Contact(
                AccountId = testAccount.Id,
                LastName = 'TestLastName',
                FirstName = 'TestFirstName',
                Email = 'test@test.com');
            insert testContact;

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

            // Price Book
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

            // Products
            List<Product2> testProducts = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'Connect Pro - Annual Fee',
                Family = 'Office',
                IsActive = true,
                Sub_Category__c = 'Main');
            testProducts.add(testProduct);

            Product2 testServiceProduct = new Product2(
                Name = 'Connect Pro - Annual Fee',
                Family = 'Service',
                IsActive = true,
                Sub_Category__c = 'Contact Center');
            testProducts.add(testServiceProduct);
            insert testProducts;

            // Price book Entry
            List<PricebookEntry> testPricebookEntrys = new List<PricebookEntry>();

            PricebookEntry standardPrice = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = testProduct.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false
            );
            testPricebookEntrys.add(standardPrice);

            PricebookEntry testPrice = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = testProduct.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
            );
            testPricebookEntrys.add(testPrice);

            PricebookEntry standardServicePrice = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = testServiceProduct.Id,
                UnitPrice = 100, IsActive = true,
                UseStandardPrice = false
            );
            testPricebookEntrys.add(standardServicePrice);

            PricebookEntry testServicePrice = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = testServiceProduct.Id,
                UnitPrice = 100, IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
            );
            testPricebookEntrys.add(testServicePrice);
            insert testPricebookEntrys;

            //Create test data
            // Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                Type = 'Syndicated - New',
                StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
                CloseDate = System.today(),
                Brand_Name__c = 'RingCentral',
                PriceBook2Id = testPriceBook.Id,
                Primary_Opportunity_Contact__c = testContact.Id,
                Tier_Name__c = '999',
                AccountId = testAccount.Id
            );
            insert opp;

            // Quote
            Quote testQuote = new Quote (
                Name = 'Test Quote',
                OpportunityId = opp.id,
                Status = 'Draft',
                Pricebook2Id = testPriceBook.id,
                Total_Number_of_Digital_Lines__c = 5,
                FaxAreaCode__c = areaCode.Id,
                AreaCode__c = areaCode.Id
            );
            insert testQuote;

            // Quote line items
            List<QuoteLineItem> testQuoteLineItems = new List<QuoteLineItem>();

            QuoteLineItem testQuoteLineItem = new QuoteLineItem (
                ServiceDate = date.today(),
                Description = 'TestLineItem',
                UnitPrice = testPrice.UnitPrice,
                Quantity = 5,
                QuoteId = testQuote.Id,
                PriceBookEntryId = testPrice.Id,
                Product2Id = testProduct.Id
            );
            testQuoteLineItems.add(testQuoteLineItem);

            QuoteLineItem testServiceQuoteLineItem =  new QuoteLineItem (
                ServiceDate = date.today(),
                Description = 'TestServiceLineItem',
                UnitPrice = testServicePrice.UnitPrice,
                Quantity = 5,
                QuoteId = testQuote.Id,
                PriceBookEntryId = testServicePrice.Id,
                Product2Id = testProduct.Id
            );
            testQuoteLineItems.add(testServiceQuoteLineItem);

            insert testQuoteLineItems;

            Id proServOrderRTId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

            // Orders
            Order testOrder = new Order(
                AccountId = testAccount.Id,
                OpportunityId = opp.Id,
                Status = 'Submitted',
                Pricebook2Id = standardPrice.Pricebook2Id,
                EffectiveDate = System.today(),
                RecordTypeId = proServOrderRTId
            );
            insert testOrder;

            // Order Items
            OrderItem testOrderItem = new OrderItem(
                OrderId = testOrder.Id,
                Quantity = testQuoteLineItem.Quantity,
                UnitPrice = testQuoteLineItem.UnitPrice,
                PriceBookEntryId = standardPrice.Id
            );
            insert testOrderItem;

            Id proServPhaseRTId =  Phase__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId();

            // Phases
            Phase__c ph1 = new Phase__c(
                Name = 'testPhase_1',
                Opportunity__c = opp.Id,
                Quote__c = testQuote.Id,
                Order__c = testOrder.Id,
                RecordTypeId = proServPhaseRTId,
                PhaseDescription__c = 'testDescription1'
            );

            Phase__c ph2 = new Phase__c(
                Name = 'testPhase_2',
                Opportunity__c = opp.Id,
                Quote__c = testQuote.Id,
                Order__c = testOrder.Id,
                RecordTypeId = proServPhaseRTId,
                PhaseDescription__c = 'testDescription2'
            );

            insert new List<Phase__c>{
                ph1, ph2
            };
            // Phase Line Items
            Hardware_Line_Item__c hli1 = new Hardware_Line_Item__c(
                Name = 'test PhaseLineItem for Phase1',
                Quantity__c = 3,
                Quote_Line_Item__c = testQuoteLineItem.Id,
                RingCentral_Hardware_Phase__c = ph1.Id
            );

            Hardware_Line_Item__c hli2 = new Hardware_Line_Item__c(
                Name = 'test PhaseLineItem for Phase2',
                Quantity__c = 2,
                Quote_Line_Item__c = testQuoteLineItem.Id,
                RingCentral_Hardware_Phase__c = ph2.Id
            );

            insert new List<Hardware_Line_Item__c>{
                hli1, hli2
            };

            System.assertEquals(false, ApexWebServices.checkOrderIsCompleted(null));

            List<OrderItem> oiList = [select Id, PriceBookEntry.Product2Id from OrderItem];
            Map<Id, Asset> orderItemIdToAssetMap = new Map<Id, Asset>();

            for(OrderItem oi : oiList) {
                Asset testAsset = new Asset(
                    AccountId = testAccount.Id,
                    Product2Id = oi.PriceBookEntry.Product2Id,
                    // OrderItem__c = oi.Id,
                    Name = 'testAsset',
                    Unit_Price__c = 200,
                    Quantity = 5,
                    Delivered_Quantity__c = 5,
                    Active__c = true
                );
                orderItemIdToAssetMap.put(oi.Id, testAsset);
            }
            insert orderItemIdToAssetMap.values();

            // fill lookup to asset on orderItem objects
            List<OrderItem> oiToUpdateList = new List<OrderItem>();
            for(Id oiId : orderItemIdToAssetMap.keySet()) {

                Asset asset = orderItemIdToAssetMap.get(oiId);

                if(asset != null && asset.Id != null) {
                    oiToUpdateList.add(
                        new OrderItem(
                            Id = oiId,
                            Asset__c = asset.Id
                        )
                    );
                }
            }

            if(!oiToUpdateList.isEmpty()) {
                update oiToUpdateList;
            }

            List<Order> orders = [select Id from Order];
            System.assertEquals(1, orders.size());

            Id orderId = orders[0].Id;

            List<Opportunity> oppList = [select Id from Opportunity];
            System.assertEquals(1, oppList.size());

            System.assertEquals(null, ApexWebServices.changeOrder(''));
            System.assertEquals(null, ApexWebServices.changeOrder(null));

            // Cause triggers lofic enable it again
            Triggers.switchOff();

            Map<String,Object> parsed = (Map<String,Object>)JSON.deserializeUntyped(ApexWebServices.changeOrder(orderId));
            Map<String,Object> dataMap = (Map<String,Object>)parsed.get('data');
            Id changeOrderOppId = (Id)dataMap.get('newOppId');
            System.assert(changeOrderOppId != null);

            Phase__c clonedPhase1 = [
                SELECT Id, RecordTypeId, PhaseDescription__c, Quote__c, IsCloned__c
                FROM Phase__c
                WHERE Name LIKE '%testPhase_1%' AND Opportunity__r.Name LIKE '%Change Order%'
                LIMIT 1
            ];

        Triggers.switchOn();
        Test.stopTest();

        System.assertEquals(ph1.RecordTypeId, clonedPhase1.RecordTypeId, 'cloned phase has wrong recordType');
        System.assertEquals(ph1.PhaseDescription__c, clonedPhase1.PhaseDescription__c, 'cloned phase has wrong description');
        System.assertEquals(TRUE, clonedPhase1.IsCloned__c, 'Cloned phase in NewChangeOrderFlow has not IsCloned__c true');

        List<Opportunity> reselectedOppList = [SELECT Id FROM Opportunity];
        System.assertEquals(2, reselectedOppList.size());

        List<Quote> reselectedQuotesList = [
            SELECT Id, RecordTypeId, Upsell_Status__c, OpportunityId, isPrimary__c,
                (SELECT Id, Quantity, OriginalOrderLineItem__c FROM QuoteLineItems)
            FROM Quote];
        System.assertEquals(2, reselectedQuotesList.size());

        for(Quote item : reselectedQuotesList) {

            // it is changeOrder Quote
            if(item.OpportunityId == changeOrderOppId) {

                System.assertEquals(item.RecordTypeId, QuoteHelper.RT_ID_PROSERV);
                // Can not check cause triggers are disabled
                // System.assert(item.isPrimary__c, 'Change order ProServ Quote should be Primary');
                System.assertEquals(item.Upsell_Status__c, QuoteHelper.STATUS_UPSELL);

                // verify QuoteLineItems for ChangeOrderQuote is created from Asset records
                System.assert(item.QuoteLineItems.size() > 0);
                System.assertEquals(item.QuoteLineItems.size(), orderItemIdToAssetMap.values().size());
                System.assertEquals(item.Id, clonedPhase1.Quote__c, 'cloned phase has wrong quote');

                for (QuoteLineItem quoteLineItem : item.QuoteLineItems) {
                    System.assertEquals(testOrderItem.Id, quoteLineItem.OriginalOrderLineItem__c,
                        'Original Order Line Item field was populated with wrong value');
                }
            }
        }

        List<Order> reselectedOrdersList = [SELECT Id, Status FROM Order];
        Order reselectedOrder = reselectedOrdersList[0];

        System.assertEquals(OrderHelper.STATUS_LOCKED, reselectedOrder.Status);
    }

    @isTest
    static void testBuildIdSet() {

        System.assertEquals(new Set<Id>(), ChangeOrder.buildIdSet(null));

        // try buildIdSet for Account
        List<Account> accsList = [select Id, Name from Account limit 100];

        Set<Id> accIdSet = new Set<Id>();
        for(Account acc : accsList) {
            accIdSet.add(acc.Id);
        }

        System.assertEquals(accIdSet, ChangeOrder.buildIdSet(accsList));


        // try buildIdSet for QuoteLineItem
        List<QuoteLineItem> qliList = [select Id, Quantity from QuoteLineItem limit 100];

        Set<Id> qliIdSet = new Set<Id>();
        for(QuoteLineItem qli : qliList) {
            qliIdSet.add(qli.Id);
        }

        System.assertEquals(qliIdSet, ChangeOrder.buildIdSet(qliList));
    }

    @isTest
    static void testBuildPhaseIdToHLIListMap() {

        // passing null or empty set as params in buildPhaseIdToHLIListMap should return new empty structure Map<Id, List<Hardware_Line_Item__c>>
        System.assertEquals(new Map<Id, List<Hardware_Line_Item__c>>(), ChangeOrder.buildPhaseIdToHLIListMap(null));
        System.assertEquals(new Map<Id, List<Hardware_Line_Item__c>>(), ChangeOrder.buildPhaseIdToHLIListMap(new Set<Id>()));

        testAccount = new Account(
            Name = 'Test Account',
            Number_of_DL_s__c = 10,
            BillingCity = 'TestCity',
            BillingStreet = 'TestStreet',
            Payment_Method__c = 'Invoice',
            SignupType__c = 'Direct');
        insert testAccount;

        // Price Book
        PriceBook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            Tier_ID__c = '999',
            Plan__c = 'Annual',
            IsActive = true,
            Line_Range_Min__c = 5,
            Line_Range_Max__c = 10,
            Service__c = 'Office'
        );
        insert testPriceBook;

        Product2 testProduct = new Product2(
            Name = 'Connect Pro - Annual Fee',
            Family = 'Office',
            IsActive = true,
            Sub_Category__c = 'Main');
        insert testProduct;

        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardPrice;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            Type = 'Syndicated - New',
            StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
            CloseDate = System.today(),
            Brand_Name__c = 'RingCentral',
            PriceBook2Id = testPriceBook.Id,
            Tier_Name__c = '999',
            AccountId = testAccount.Id
        );
        insert opp;


        Id proServOrderRTId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

        // Orders
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            OpportunityId = opp.Id,
            Status = 'Submitted',
            Pricebook2Id = standardPrice.Pricebook2Id,
            EffectiveDate = System.today(),
            RecordTypeId = proServOrderRTId
        );
        insert testOrder;

        // Order Items
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Quantity = 10,
            UnitPrice = 200,
            PriceBookEntryId = standardPrice.Id
        );
        insert testOrderItem;

        Id proServPhaseRTId =  Phase__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId();

        // Phases
        Phase__c ph1 = new Phase__c(
            Name = 'testPhase_1',
            Order__c = testOrder.Id,
            RecordTypeId = proServPhaseRTId
        );

        Phase__c ph2 = new Phase__c(
            Name = 'testPhase_2',
            Order__c = testOrder.Id,
            RecordTypeId = proServPhaseRTId
        );

        insert new List<Phase__c>{
            ph1, ph2
        };

        // Phase Line Items
        Hardware_Line_Item__c hli1 = new Hardware_Line_Item__c(
            Name = 'test PhaseLineItem for Phase1',
            Quantity__c = 3,
            Order__c = testOrder.Id,
            Order_Line_Item__c = testOrderItem.Id,
            RingCentral_Hardware_Phase__c = ph1.Id
        );

        Hardware_Line_Item__c hli2 = new Hardware_Line_Item__c(
            Name = 'test PhaseLineItem for Phase2',
            Quantity__c = 2,
            Order__c = testOrder.Id,
            Order_Line_Item__c = testOrderItem.Id,
            RingCentral_Hardware_Phase__c = ph2.Id
        );

        insert new List<Hardware_Line_Item__c>{
            hli1, hli2
        };

        Test.startTest();

            Map<Id, List<Hardware_Line_Item__c>> phaseIdToHLIListMapToCheck = new Map<Id, List<Hardware_Line_Item__c>>();

            for(Hardware_Line_Item__c hli : [select Id, Quote_Line_Item__c,
                                    Quote_Line_Item__r.Product2Id, RingCentral_Hardware_Phase__c,
                                    Address_Line__c, Address_Validated__c, City__c, Country__c,
                                    Location_ID__c, Location_Name__c, Name, Postal_Code__c,
                                    Quantity__c, State__c, Total_Price__c
                                from Hardware_Line_Item__c
                                where RingCentral_Hardware_Phase__c in (select Id from Phase__c)]) {

                if(phaseIdToHLIListMapToCheck.get(hli.RingCentral_Hardware_Phase__c) == null) {
                    phaseIdToHLIListMapToCheck.put(hli.RingCentral_Hardware_Phase__c, new List<Hardware_Line_Item__c>());
                }

                phaseIdToHLIListMapToCheck.get(hli.RingCentral_Hardware_Phase__c).add(hli);
            }

            Set<Id> phaseIdSet = phaseIdToHLIListMapToCheck.keySet();

            System.assertEquals(phaseIdToHLIListMapToCheck, ChangeOrder.buildPhaseIdToHLIListMap(phaseIdSet));

        Test.stopTest();
    }

    /*
    * verify that created "ChangeOrder" quote has same recordType as recordType on initial Order
    */
    @isTest
    static void testChangeOrderCCProServ() {

        testAccount = new Account(
            Name = 'Test Account',
            Number_of_DL_s__c = 10,
            BillingCity = 'TestCity',
            BillingStreet = 'TestStreet',
            Payment_Method__c = 'Invoice',
            SignupType__c = 'Direct');
        insert testAccount;

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

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            Type = 'Syndicated - New',
            StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
            CloseDate = System.today(),
            Brand_Name__c = 'RingCentral',
            PriceBook2Id = testPriceBook.Id,
            Tier_Name__c = '999',
            AccountId = testAccount.Id
        );
        insert opp;

        Id ccProServOrderRTId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('CC Professional Services').getRecordTypeId();

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            OpportunityId = opp.Id,
            Status = 'Submitted',
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate = System.today(),
            RecordTypeId = ccProServOrderRTId
        );
        insert testOrder;

        Product2 testProduct = new Product2(
            Name = 'Connect Pro - Annual Fee',
            Family = 'Office',
            IsActive = true,
            Sub_Category__c = 'Main'
        );
        insert testProduct;

        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardPrice;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Quantity = 1,
            UnitPrice = 50,
            PriceBookEntryId = standardPrice.Id
        );
        insert testOrderItem;

        Test.startTest();

            Map<String,Object> parsed = (Map<String,Object>)JSON.deserializeUntyped(ApexWebServices.changeOrder(testOrder.Id));
            Map<String,Object> dataMap = (Map<String,Object>)parsed.get('data');
            Id changeOrderOppId = (Id)dataMap.get('newOppId');
            System.assert(changeOrderOppId != null);

            List<Quote> quotesList = [SELECT Id, OpportunityId, RecordTypeId, isPrimary__c FROM Quote];

            for(Quote item : quotesList) {

                if(item.OpportunityId == changeOrderOppId) {

                    // verify that created quote has CCProServ recordType(becouse we run changeOrder on CCProServ order)
                    System.assertEquals(item.RecordTypeId, QuoteHelper.RT_ID_CC_PROSERV);
                    System.assert(item.isPrimary__c, 'Change order CCProServ Quote should be Primary');
                }
            }

        Test.stopTest();
    }

    @isTest
    static void testOriginalAndLastPhasePopulation() {
        Test.startTest();
            Triggers.switchOff();
            testAccount = new Account(
                Name = 'Test Account',
                Number_of_DL_s__c = 10,
                BillingCity = 'TestCity',
                BillingStreet = 'TestStreet',
                Payment_Method__c = 'Invoice',
                SignupType__c = 'Direct');
            insert testAccount;

            Id standardPriceBookId = Test.getStandardPricebookId();

            Contact testContact = new Contact(
                AccountId = testAccount.Id,
                LastName = 'TestLastName',
                FirstName = 'TestFirstName',
                Email = 'test@test.com');
            insert testContact;

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

            // Price Book
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

            // Products
            List<Product2> testProducts = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'Connect Pro - Annual Fee',
                Family = 'Office',
                IsActive = true,
                Sub_Category__c = 'Main');
            testProducts.add(testProduct);

            Product2 testServiceProduct = new Product2(
                Name = 'Connect Pro - Annual Fee',
                Family = 'Service',
                IsActive = true,
                Sub_Category__c = 'Contact Center');
            testProducts.add(testServiceProduct);
            insert testProducts;

            // Price book Entry
            List<PricebookEntry> testPricebookEntrys = new List<PricebookEntry>();

            PricebookEntry standardPrice = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = testProduct.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false
            );
            testPricebookEntrys.add(standardPrice);

            PricebookEntry testPrice = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = testProduct.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
            );
            testPricebookEntrys.add(testPrice);

            PricebookEntry standardServicePrice = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = testServiceProduct.Id,
                UnitPrice = 100, IsActive = true,
                UseStandardPrice = false
            );
            testPricebookEntrys.add(standardServicePrice);

            PricebookEntry testServicePrice = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = testServiceProduct.Id,
                UnitPrice = 100, IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
            );
            testPricebookEntrys.add(testServicePrice);
            insert testPricebookEntrys;

            //Create test data
            // Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                Type = 'Syndicated - New',
                StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
                CloseDate = System.today(),
                Brand_Name__c = 'RingCentral',
                PriceBook2Id = testPriceBook.Id,
                Primary_Opportunity_Contact__c = testContact.Id,
                Tier_Name__c = '999',
                AccountId = testAccount.Id
            );
            insert opp;

            // Quote
            Quote testQuote = new Quote (
                Name = 'Test Quote',
                OpportunityId = opp.id,
                Status = 'Draft',
                Pricebook2Id = testPriceBook.id,
                Total_Number_of_Digital_Lines__c = 5,
                FaxAreaCode__c = areaCode.Id,
                AreaCode__c = areaCode.Id
            );
            insert testQuote;
            // Quote line items
            List<QuoteLineItem> testQuoteLineItems = new List<QuoteLineItem>();

            QuoteLineItem testQuoteLineItem = new QuoteLineItem (
                ServiceDate = date.today(),
                Description = 'TestLineItem',
                UnitPrice = testPrice.UnitPrice,
                Quantity = 5,
                QuoteId = testQuote.Id,
                PriceBookEntryId = testPrice.Id,
                Product2Id = testProduct.Id
            );
            testQuoteLineItems.add(testQuoteLineItem);

            QuoteLineItem testServiceQuoteLineItem =  new QuoteLineItem (
                ServiceDate = date.today(),
                Description = 'TestServiceLineItem',
                UnitPrice = testServicePrice.UnitPrice,
                Quantity = 5,
                QuoteId = testQuote.Id,
                PriceBookEntryId = testServicePrice.Id,
                Product2Id = testProduct.Id
            );
            testQuoteLineItems.add(testServiceQuoteLineItem);

            insert testQuoteLineItems;

            Id proServOrderRTId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

            // Orders
            Order testOrder = new Order(
                AccountId = testAccount.Id,
                OpportunityId = opp.Id,
                Status = 'Submitted',
                Pricebook2Id = standardPrice.Pricebook2Id,
                EffectiveDate = System.today(),
                RecordTypeId = proServOrderRTId
            );
            insert testOrder;

            // Order Items
            OrderItem testOrderItem = new OrderItem(
                OrderId = testOrder.Id,
                Quantity = testQuoteLineItem.Quantity,
                UnitPrice = testQuoteLineItem.UnitPrice,
                PriceBookEntryId = standardPrice.Id
            );
            insert testOrderItem;

            Id proServPhaseRTId =  Phase__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId();

            // Phases
            Phase__c ph1 = new Phase__c(
                Name = 'testPhase_1',
                Opportunity__c = opp.Id,
                Quote__c = testQuote.Id,
                Order__c = testOrder.Id,
                RecordTypeId = proServPhaseRTId
            );

            Phase__c ph2 = new Phase__c(
                Name = 'testPhase_2',
                Opportunity__c = opp.Id,
                Quote__c = testQuote.Id,
                Order__c = testOrder.Id,
                RecordTypeId = proServPhaseRTId
            );

            insert new List<Phase__c>{
                ph1, ph2
            };
            // Phase Line Items
            Hardware_Line_Item__c hli1 = new Hardware_Line_Item__c(
                Name = 'test PhaseLineItem for Phase1',
                Quantity__c = 3,
                Quote_Line_Item__c = testQuoteLineItem.Id,
                RingCentral_Hardware_Phase__c = ph1.Id
            );

            Hardware_Line_Item__c hli2 = new Hardware_Line_Item__c(
                Name = 'test PhaseLineItem for Phase2',
                Quantity__c = 2,
                Quote_Line_Item__c = testQuoteLineItem.Id,
                RingCentral_Hardware_Phase__c = ph2.Id
            );

            insert new List<Hardware_Line_Item__c>{
                hli1, hli2
            };

            System.assertEquals(false, ApexWebServices.checkOrderIsCompleted(null));

            List<OrderItem> oiList = [select Id, PriceBookEntry.Product2Id from OrderItem];
            Map<Id, Asset> orderItemIdToAssetMap = new Map<Id, Asset>();

            for(OrderItem oi : oiList) {
                Asset testAsset = new Asset(
                    AccountId = testAccount.Id,
                    Product2Id = oi.PriceBookEntry.Product2Id,
                    // OrderItem__c = oi.Id,
                    Name = 'testAsset',
                    Unit_Price__c = 200,
                    Quantity = 5,
                    Delivered_Quantity__c = 5,
                    Active__c = true
                );
                orderItemIdToAssetMap.put(oi.Id, testAsset);
            }
            insert orderItemIdToAssetMap.values();

            // fill lookup to asset on orderItem objects
            List<OrderItem> oiToUpdateList = new List<OrderItem>();
            for(Id oiId : orderItemIdToAssetMap.keySet()) {

                Asset asset = orderItemIdToAssetMap.get(oiId);

                if(asset != null && asset.Id != null) {
                    oiToUpdateList.add(
                        new OrderItem(
                            Id = oiId,
                            Asset__c = asset.Id
                        )
                    );
                }
            }

            if(!oiToUpdateList.isEmpty()) {
                update oiToUpdateList;
            }

            List<Order> orders = [select Id from Order];
            System.assertEquals(1, orders.size());

            Id orderId = orders[0].Id;

            List<Opportunity> oppList = [select Id from Opportunity];
            System.assertEquals(1, oppList.size());

            Boolean orderIsCompleted = ApexWebServices.checkOrderIsCompleted(orderId);
            System.assertEquals(false, orderIsCompleted);

            System.assertEquals(null, ApexWebServices.changeOrder(''));
            System.assertEquals(null, ApexWebServices.changeOrder(null));

            Triggers.switchOff();

            Map<String,Object> parsed = (Map<String,Object>)JSON.deserializeUntyped(ApexWebServices.changeOrder(orderId));
            Map<String,Object> dataMap = (Map<String,Object>)parsed.get('data');
            Id changeOrderOppId = (Id)dataMap.get('newOppId');
            System.assert(changeOrderOppId != null);


            List<Opportunity> reselectedOppList = [select Id from Opportunity];
            System.assertEquals(2, reselectedOppList.size());

            Phase__c testPhase1_check = [SELECT Original_Phase__c, Original_Phase__r.Id,
                                                Last_Phase__c, Last_Phase__r.Id
                                            FROM Phase__c
                                            WHERE Name LIKE '%testPhase_1%'
                                            AND Opportunity__r.Name LIKE '%Change Order%'
                                            LIMIT 1];

        Triggers.switchOn();
        Test.stopTest();

        System.assertEquals(testPhase1_check.Original_Phase__r.Id, ph1.Id);
        System.assertEquals(testPhase1_check.Last_Phase__r.Id, ph1.Id);
    }

    @isTest
    static void testAssetsDontGetNullifiedOnChangeOrder() {
        Test.startTest();
            Triggers.switchOff();
            // Create an opportunity with order, change order and check that the Assets (items on the cart) are not deleted (CRM-1579)
            Id standardPriceBookId = Test.getStandardPricebookId();

            testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'Test Account',
                        Account.Number_of_DL_s__c => 10,
                        Account.BillingCity => 'TestCity',
                        Account.BillingStreet => 'TestStreet',
                        Account.Payment_Method__c => AccountHelper.PAYMENT_METHOD_INVOICE,
                        Account.SignupType__c => 'Direct'
                    }
                )
                .create()
                .getRecord();

            Contact testContact = (Contact) new SObjectBuilder(Contact.sObjectType)
                .setField(Contact.AccountId, testAccount.Id)
                .create()
                .getRecord();

            Area_Codes__c areaCode = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Area_Codes__c.Country__c => 'United States',
                        Area_Codes__c.State__c => 'Texas',
                        Area_Codes__c.Area_Code__c => 100
                    }
                )
                .create()
                .getRecord();

            schedulerConfiguration__c scc = (schedulerConfiguration__c) new SObjectBuilder(schedulerConfiguration__c.SObjectType)
                .setField(schedulerConfiguration__c.Name, 'RingCentral')
                .create()
                .getRecord();

            Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => 'Connect Pro - Annual Fee',
                        Product2.ExtID__c => Pricebook2Helper.SERVICE_OFFICE,
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL
                    }
                )
                .create()
                .getRecord();

            PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => standardPriceBookId,
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 50,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                })
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.Name => 'Test Opportunity',
                        Opportunity.Type => 'Syndicated - New',
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                        Opportunity.CloseDate => System.today(),
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.PriceBook2Id => standardPriceBookId,
                        Opportunity.Primary_Opportunity_Contact__c => testContact.Id,
                        Opportunity.Tier_Name__c => '999',
                        Opportunity.AccountId => testAccount.Id
                    })
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SOBjectBuilder(Quote.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => opp.id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.Pricebook2Id => standardPriceBookId,
                    Quote.Total_Number_of_Digital_Lines__c => 5,
                    Quote.FaxAreaCode__c => areaCode.Id,
                    Quote.AreaCode__c => areaCode.Id
                })
                .create()
                .getRecord();

            QuoteLineItem testQuoteLineItem = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.ServiceDate => date.today(),
                        QuoteLineItem.Description => 'TestLineItem',
                        QuoteLineItem.UnitPrice => standardPrice.UnitPrice,
                        QuoteLineItem.Quantity => 5,
                        QuoteLineItem.QuoteId => testQuote.Id,
                        QuoteLineItem.PriceBookEntryId => standardPrice.Id,
                        QuoteLineItem.Product2Id => testProduct.Id
                    })
                .create()
                .getRecord();

            Id proServOrderRTId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

            Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Order.AccountId => testAccount.Id,
                    Order.OpportunityId => opp.Id,
                    Order.Status => OrderHelper.STATUS_SUBMITTED,
                    Order.Pricebook2Id => standardPrice.Pricebook2Id,
                    Order.EffectiveDate => System.today(),
                    Order.RecordTypeId => proServOrderRTId
                })
                .create()
                .getRecord();

            OrderItem testOrderItem = (OrderItem) new SOBjectBuilder(OrderItem.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    OrderItem.OrderId => testOrder.Id,
                    OrderItem.Quantity => testQuoteLineItem.Quantity,
                    OrderItem.UnitPrice => testQuoteLineItem.UnitPrice,
                    OrderItem.PriceBookEntryId => standardPrice.Id
                })
                .create()
                .getRecord();

            Id proServPhaseRTId =  Phase__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId();

            Phase__c testPhase = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Phase__c.Name => 'testPhase',
                    Phase__c.Opportunity__c => opp.Id,
                    Phase__c.Quote__c => testQuote.Id,
                    Phase__c.Order__c => testOrder.Id,
                    Phase__c.RecordTypeId => proServPhaseRTId
                })
                .create()
                .getRecord();

            Hardware_Line_Item__c testHLI = (Hardware_Line_Item__c) new SOBjectBuilder(Hardware_Line_Item__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Hardware_Line_Item__c.Name => 'Test PhaseLineItem for Phase',
                    Hardware_Line_Item__c.Quantity__c => 3,
                    Hardware_Line_Item__c.Quote_Line_Item__c => testQuoteLineItem.Id,
                    Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase.Id
                })
                .create()
                .getRecord();

            System.assertEquals(false, ApexWebServices.checkOrderIsCompleted(null));

            Asset testAsset = (Asset) new SObjectBuilder(Asset.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Asset.AccountId => testAccount.Id,
                    Asset.Product2Id => testOrderItem.PriceBookEntry.Product2Id,
                    Asset.Name => 'testAsset',
                    Asset.Unit_Price__c => 200,
                    Asset.Quantity => 5,
                    Asset.Delivered_Quantity__c => 5,
                    Asset.Active__c => true
                })
                .create()
                .getRecord();

            testOrderItem.Asset__c = testAsset.Id;
            update testOrderItem;

            Boolean orderIsCompleted = ApexWebServices.checkOrderIsCompleted(testOrder.Id);
            System.assertEquals(false, orderIsCompleted);

            Triggers.switchOff();
            // We proceed with the Change Order (this should create a new opportunity)
            Map<String,Object> parsed = (Map<String,Object>)JSON.deserializeUntyped(ApexWebServices.changeOrder(testOrder.Id));
            Map<String,Object> dataMap = (Map<String,Object>)parsed.get('data');
            Id changeOrderOppId = (Id) dataMap.get('newOppId');
            System.assert(changeOrderOppId != null);

            // After the Change Order, the old order should keep having the original assets
            OrderItem oi = (OrderItem) new OrderItemSelector()
                .selectOrderItemsByOrderId(testOrder.Id)
                .selectField(OrderItem.Asset__c)
                .executeQuery()
                .get(0);
        Triggers.switchOn();
        Test.stopTest();

        System.assert(oi.Asset__c != null, 'At least one order item got its Asset__c field nullified');
    }

}