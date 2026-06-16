@IsTest
private class Test_PhaseManagementController {

    @isTest
    static void getPhases() {
        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = '1. Qualify',
                CloseDate = system.today()
        );
        insert testOpportunity;

        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(Name = 'Test Price Book',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly');
        insert new List<Pricebook2>{
                testPriceBook1
        };

        // Create Quote
        Quote testPrimaryQuote = new Quote(Name = 'Test Primary Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, IsPrimary__c = true);
        Quote testProServQuote = new Quote(Name = 'Test ProServ Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, RecordTypeId = QuoteHelper.RT_ID_PROSERV);
        insert new List<Quote>{
                testPrimaryQuote, testProServQuote
        };

        // Create Products
        // ProServ
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV);
        insert new List<Product2>{
                testProduct1
        };

        // Create PricebookEntries
        // ProServ
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
                Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct1.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);
        insert new List<PricebookEntry>{
                standardPrice1,
                testPrice1
        };

        // Create Quote Line Items
        // ProServ Quote
        QuoteLineItem testProServQli1 = new QuoteLineItem(
                QuoteId = testProServQuote.Id,
                PricebookEntryId = testPrice1.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = testPrice1.UnitPrice,
                Quantity = 5
        );
        insert new List<QuoteLineItem>{
                testProServQli1
        };

        // Create Phase
        Phase__c testPhase = new Phase__c(
            Name = 'Test',
            Opportunity__c = testOpportunity.Id,
            Quote__c = testProServQuote.Id
        );
        insert new List<Phase__c>{
                testPhase
        };

        // Create Phase Line Item
        Hardware_Line_Item__c testHardwareLineItem = new Hardware_Line_Item__c(
                Name = 'Test',
                RingCentral_Hardware_Phase__c = testPhase.Id,
                Quote_Line_Item__c = testProServQli1.Id
        );
        insert new List<Hardware_Line_Item__c>{
                testHardwareLineItem
        };


        Test.startTest();
        List<Phase__c> phaseResult1 = PhaseManagementController.getPhases(testProServQuote.Id);
        Test.stopTest();

        System.assertEquals(1, phaseResult1.size());
        System.assertEquals(1, phaseResult1[0].Hardware_Line_Items__r.size());

    }

    @isTest
    static void upsertPhases() {
        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = '1. Qualify',
                CloseDate = system.today()
        );
        insert testOpportunity;

        Test.startTest();
        // Prepare Phases for test
        Phase__c testPhase1 = new Phase__c(
                Name = 'Test',
                Opportunity__c = testOpportunity.Id
        );
        Phase__c testPhase2 = new Phase__c(
                Name = 'Test 2',
                Opportunity__c = testOpportunity.Id
        );
        insert testPhase2;
        Map <String, Phase__c> testPhases = new Map <String, Phase__c> {
                'phase1-GUID' => testPhase1,
                'phase2-GUID' => testPhase2
        };

        Map <String, Phase__c> upsertPhasesResult1 = PhaseManagementController.upsertPhases(testPhases);
        Test.stopTest();

        System.assertEquals(2, upsertPhasesResult1.values().size());
        System.assert( upsertPhasesResult1.get('phase1-GUID').Id != null );
        System.assert( upsertPhasesResult1.get('phase2-GUID').Id != null );

        Phase__c insertPhasesSelectResult = [
                SELECT Id, Name, RecordTypeId
                FROM Phase__c
                WHERE Id = :upsertPhasesResult1.get('phase1-GUID').Id
        ];

        System.assertEquals(PhaseHelper.RT_ID_PROSERV_PHASE, insertPhasesSelectResult.RecordTypeId);
    }

    @isTest
    static void upsertPhaseLineItems() {
        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = '1. Qualify',
                CloseDate = system.today()
        );
        insert testOpportunity;

        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(Name = 'Test Price Book',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly');
        insert new List<Pricebook2>{
                testPriceBook1
        };

        // Create Quote
        Quote testPrimaryQuote = new Quote(Name = 'Test Primary Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, IsPrimary__c = true);
        Quote testProServQuote = new Quote(Name = 'Test ProServ Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, RecordTypeId = QuoteHelper.RT_ID_PROSERV);
        insert new List<Quote>{
                testPrimaryQuote, testProServQuote
        };

        // Create Products
        // ProServ
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV);
        insert new List<Product2>{
                testProduct1
        };

        // Create PricebookEntries
        // ProServ
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
                Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct1.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);
        insert new List<PricebookEntry>{
                standardPrice1,
                testPrice1
        };

        // Create Quote Line Items
        // ProServ Quote
        QuoteLineItem testProServQli1 = new QuoteLineItem(
                QuoteId = testProServQuote.Id,
                PricebookEntryId = testPrice1.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = testPrice1.UnitPrice,
                Quantity = 10
        );
        insert new List<QuoteLineItem>{
                testProServQli1
        };

        // Create Phases
        Phase__c testPhase1 = new Phase__c(
                Name = 'Test',
                Opportunity__c = testOpportunity.Id
        );
        Phase__c testPhase2 = new Phase__c(
                Name = 'Test 2',
                Opportunity__c = testOpportunity.Id
        );
        insert new List<Phase__c>{
                testPhase1, testPhase2
        };

        Test.startTest();
        // Prepare Phase Line Items for test
        Hardware_Line_Item__c testPhaseLineItem1 = new Hardware_Line_Item__c(
                Name = 'PLI to Insert',
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quantity__c = 5,
                Quote_Line_Item__c = testProServQli1.Id
        );
        Hardware_Line_Item__c testPhaseLineItem2 = new Hardware_Line_Item__c(
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quantity__c = 4,
                Quote_Line_Item__c = testProServQli1.Id
        );
        insert testPhaseLineItem2;
        testPhaseLineItem2.Quantity__c = 5;
        List<Hardware_Line_Item__c> testPhaseLineItems = new List<Hardware_Line_Item__c>{
                testPhaseLineItem1, testPhaseLineItem2
        };

        PhaseManagementController.upsertPhaseLineItems(testPhaseLineItems);
        Test.stopTest();

        List<Hardware_Line_Item__c> phaseLineItemsResult = [SELECT Id, Name, Quantity__c, RecordTypeId FROM Hardware_Line_Item__c];

        System.assertEquals(2, phaseLineItemsResult.size());
        System.assertEquals(5, phaseLineItemsResult[0].Quantity__c);
        System.assertEquals(5, phaseLineItemsResult[1].Quantity__c);

        for (Hardware_Line_Item__c phaseLineItem : phaseLineItemsResult) {
            if (testPhaseLineItem1.Name == phaseLineItem.Name){
                System.assertEquals(HardwareLineItemHelper.RT_ID_PROSERV_LINE_ITEM, phaseLineItem.RecordTypeId);
            }
        }
    }

    @isTest
    static void deletePhases() {
        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = '1. Qualify',
                CloseDate = system.today()
        );
        insert testOpportunity;

        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(Name = 'Test Price Book',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly');
        insert new List<Pricebook2>{
                testPriceBook1
        };

        // Create Quote
        Quote testPrimaryQuote = new Quote(Name = 'Test Primary Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, IsPrimary__c = true);
        Quote testProServQuote = new Quote(Name = 'Test ProServ Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, RecordTypeId = QuoteHelper.RT_ID_PROSERV);
        insert new List<Quote>{
                testPrimaryQuote, testProServQuote
        };

        // Create Products
        // ProServ
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV);
        insert new List<Product2>{
                testProduct1
        };

        // Create PricebookEntries
        // ProServ
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
                Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct1.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);
        insert new List<PricebookEntry>{
                standardPrice1,
                testPrice1
        };

        // Create Quote Line Items
        // ProServ Quote
        QuoteLineItem testProServQli1 = new QuoteLineItem(
                QuoteId = testProServQuote.Id,
                PricebookEntryId = testPrice1.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = testPrice1.UnitPrice,
                Quantity = 5
        );
        insert new List<QuoteLineItem>{
                testProServQli1
        };

        // Create Phase
        Phase__c testPhase1 = new Phase__c(
                Name = 'Test',
                Opportunity__c = testOpportunity.Id
        );
        Phase__c testPhase2 = new Phase__c(
                Name = 'Test 2',
                Opportunity__c = testOpportunity.Id
        );
        List<Phase__c> testPhases = new List<Phase__c>{
                testPhase1, testPhase2
        };
        insert testPhases;

        // Create Phase Line Item
        Hardware_Line_Item__c testHardwareLineItem1 = new Hardware_Line_Item__c(
                Name = 'Test',
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quote_Line_Item__c = testProServQli1.Id
        );
        Hardware_Line_Item__c testHardwareLineItem2 = new Hardware_Line_Item__c(
                Name = 'Test 2',
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quote_Line_Item__c = testProServQli1.Id
        );
        insert new List<Hardware_Line_Item__c>{
                testHardwareLineItem1, testHardwareLineItem2
        };

        Test.startTest();
        PhaseManagementController.deletePhases(new List<Id>{
                testPhase1.Id, testPhase2.Id
        });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Phase__c]);

        // There should be trigger logic to delete all related Phase Line Items?
        // System.assertEquals(0, [SELECT COUNT() FROM Hardware_Line_Item__c]);

    }

    @isTest
    static void deletePhaseLineItems() {
        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = '1. Qualify',
                CloseDate = system.today()
        );
        insert testOpportunity;

        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(Name = 'Test Price Book',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly');
        insert new List<Pricebook2>{
                testPriceBook1
        };

        // Create Quote
        Quote testPrimaryQuote = new Quote(Name = 'Test Primary Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, IsPrimary__c = true);
        Quote testProServQuote = new Quote(Name = 'Test ProServ Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, RecordTypeId = QuoteHelper.RT_ID_PROSERV);
        insert new List<Quote>{
                testPrimaryQuote, testProServQuote
        };

        // Create Products
        // ProServ
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV);
        insert new List<Product2>{
                testProduct1
        };

        // Create PricebookEntries
        // ProServ
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
                Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct1.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);
        insert new List<PricebookEntry>{
                standardPrice1,
                testPrice1
        };

        // Create Quote Line Items
        // ProServ Quote
        QuoteLineItem testProServQli1 = new QuoteLineItem(
                QuoteId = testProServQuote.Id,
                PricebookEntryId = testPrice1.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = testPrice1.UnitPrice,
                Quantity = 5
        );
        insert new List<QuoteLineItem>{
                testProServQli1
        };

        // Create Phase
        Phase__c testPhase1 = new Phase__c(
                Name = 'Test',
                Opportunity__c = testOpportunity.Id
        );
        Phase__c testPhase2 = new Phase__c(
                Name = 'Test 2',
                Opportunity__c = testOpportunity.Id
        );

        insert new List<Phase__c>{
                testPhase1, testPhase2
        };

        // Create Phase Line Item
        Hardware_Line_Item__c testHardwareLineItem1 = new Hardware_Line_Item__c(
                Name = 'Test',
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quote_Line_Item__c = testProServQli1.Id
        );
        Hardware_Line_Item__c testHardwareLineItem2 = new Hardware_Line_Item__c(
                Name = 'Test 2',
                RingCentral_Hardware_Phase__c = testPhase2.Id,
                Quote_Line_Item__c = testProServQli1.Id
        );
        List<Hardware_Line_Item__c> testHardwareLineItems = new List<Hardware_Line_Item__c>{
                testHardwareLineItem1, testHardwareLineItem2
        };
        insert testHardwareLineItems;

        Test.startTest();
        PhaseManagementController.deletePhaseLineItems(new List<Id>{
                testHardwareLineItem1.Id, testHardwareLineItem2.Id
        });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Hardware_Line_Item__c]);

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void completePhase() {
        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = '1. Qualify',
                CloseDate = system.today()
        );
        insert testOpportunity;

        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(Name = 'Test Price Book',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly');
        insert new List<Pricebook2>{
                testPriceBook1
        };

        // Create Quote
        Quote testPrimaryQuote = new Quote(Name = 'Test Primary Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, IsPrimary__c = true);
        Quote testProServQuote = new Quote(Name = 'Test ProServ Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, RecordTypeId = QuoteHelper.RT_ID_PROSERV);
        insert new List<Quote>{
                testPrimaryQuote, testProServQuote
        };

        // Create Products
        // ProServ
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV);
        insert new List<Product2>{
                testProduct1
        };

        // Create PricebookEntries
        // ProServ
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
                Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct1.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);
        insert new List<PricebookEntry>{
                standardPrice1,
                testPrice1
        };

        // Create Quote Line Items
        // ProServ Quote
        QuoteLineItem testProServQli1 = new QuoteLineItem(
                QuoteId = testProServQuote.Id,
                PricebookEntryId = testPrice1.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = testPrice1.UnitPrice,
                Quantity = 5
        );
        insert new List<QuoteLineItem>{
                testProServQli1
        };

        // Create Phase
        Phase__c testPhase1 = new Phase__c(
                Name = 'Test',
                Opportunity__c = testOpportunity.Id
        );
        Phase__c testPhase2 = new Phase__c(
                Name = 'Test 2',
                Opportunity__c = testOpportunity.Id
        );

        insert new List<Phase__c>{
                testPhase1, testPhase2
        };

        // Create Phase Line Item
        Hardware_Line_Item__c testHardwareLineItem1 = new Hardware_Line_Item__c(
                Name = 'Test',
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quote_Line_Item__c = testProServQli1.Id,
                Address_Validated__c = true
        );
        Hardware_Line_Item__c testHardwareLineItem2 = new Hardware_Line_Item__c(
                Name = 'Test 2',
                RingCentral_Hardware_Phase__c = testPhase2.Id,
                Quote_Line_Item__c = testProServQli1.Id,
                Address_Validated__c = true
        );
        List<Hardware_Line_Item__c> testHardwareLineItems = new List<Hardware_Line_Item__c>{
                testHardwareLineItem1, testHardwareLineItem2
        };
        insert testHardwareLineItems;

        Test.startTest();
        PhaseManagementController.completePhase(
            testPhase1.Id,
            'Automated',
            Datetime.newInstance(2018, 08, 10, 00, 00, 00));
        Test.stopTest();

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void getOrder() {

        Account testAccount = new Account(
                Name='Test Account'
        );
        insert testAccount;

        Order newOrder = new Order(
                Name = 'Test',
                AccountId = testAccount.Id,
                EffectiveDate = System.today(),
                Status = 'Submitted'
        );
        insert newOrder;

        Test.startTest();
        PhaseManagementController.getOrder(newOrder.Id);
        Test.stopTest();

    }

    @isTest
    static void getChangeOrderPhases() {
        Account testAcc = new Account (
            Name = 'testAcc');
        insert testAcc;

        Contact testContact = new Contact (
            Account = testAcc,
            LastName = 'Test');
        insert testContact;
        //Create opportunity for which parent order will be created
        Opportunity opp = new Opportunity (
            Name = 'testOpportunity',
            Type = 'Existing Business',
            StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
            CloseDate = System.today());
        insert opp;

        Id proServRecTypeId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        Id proservPhaseRecordType = Phase__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId();

        Quote testQuote = new Quote (
            Name = 'testQuote',
            OpportunityId = opp.id,
            Pricebook2Id = Test.getStandardPricebookId());
        insert testQuote;

        Order testOrder = new Order (
            AccountId = testAcc.Id,
            Status = 'New',
            Pricebook2Id = Test.getStandardPricebookId(),
            QuoteId = testQuote.Id,
            OpportunityId = opp.Id,
            EffectiveDate = System.today(),
            RecordTypeId = proServRecTypeId);
        insert testOrder;
        //Create phases for opportun
        Phase__c testPhase1 = new Phase__c(
            Name = 'Test 1',
            Opportunity__c = opp.Id,
            Order__c = testOrder.Id,
            RecordTypeId = proservPhaseRecordType,
            Completed_Date__c = System.today()
        );
        Phase__c testPhase2 = new Phase__c(
            Name = 'Test 2',
            Opportunity__c = opp.Id,
            Order__c = testOrder.Id,
            RecordTypeId = proservPhaseRecordType
        );
        insert (new List<Phase__c>{testPhase1, testPhase2});
        //Create opportunity which is created by "Change order" button
        Opportunity opptyWithChangeOrder = new Opportunity (
            Name = 'testChangeOrderOpportunity',
            Type = 'Existing Business',
            StageName = '1. Qualify',
            Parent_Order__c = testOrder.Id,
            CloseDate = System.today());
        insert opptyWithChangeOrder;

        //Run aura method
        List <Phase__c> phaseList = PhaseManagementController.getPhasesBeforeChangeOrder(opptyWithChangeOrder.Id);
        //Check if phases from parent order are obtained
        System.assertEquals(1, phaseList.size());
    }

    @isTest
    static void testValidateAdressesWrapper() {
        // Update Custom setting
        insert new RingCentralVariousSettings__c (Address_Validation_API_Endpoint__c = 'https://testapi/');

        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = '1. Qualify',
                CloseDate = system.today()
        );
        insert testOpportunity;

        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(Name = 'Test Price Book',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly');
        insert new List<Pricebook2>{
                testPriceBook1
        };

        // Create Quote
        Quote testPrimaryQuote = new Quote(Name = 'Test Primary Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, IsPrimary__c = true);
        Quote testProServQuote = new Quote(Name = 'Test ProServ Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, RecordTypeId = QuoteHelper.RT_ID_PROSERV);
        insert new List<Quote>{
                testPrimaryQuote, testProServQuote
        };

        // Create Products
        // ProServ
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV);
        insert new List<Product2>{
                testProduct1
        };

        // Create PricebookEntries
        // ProServ
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
                Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct1.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);
        insert new List<PricebookEntry>{
                standardPrice1,
                testPrice1
        };

        // Create Quote Line Items
        // ProServ Quote
        QuoteLineItem testProServQli1 = new QuoteLineItem(
                QuoteId = testProServQuote.Id,
                PricebookEntryId = testPrice1.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = testPrice1.UnitPrice,
                Quantity = 5
        );
        insert new List<QuoteLineItem>{
                testProServQli1
        };

        // Create Phase
        Phase__c testPhase1 = new Phase__c(
                Name = 'Test',
                Opportunity__c = testOpportunity.Id
        );

        insert new List<Phase__c>{
                testPhase1
        };

        // Create Phase Line Item
        Hardware_Line_Item__c testHardwareLineItem1 = new Hardware_Line_Item__c(
                Name = 'Test',
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quote_Line_Item__c = testProServQli1.Id,
                Address_Validated__c = false
        );
        List<Hardware_Line_Item__c> testHardwareLineItems = new List<Hardware_Line_Item__c>{
                testHardwareLineItem1
        };
        insert testHardwareLineItems;

        Test.startTest();
        String testStr = '[' +
                '{"itemToValidate":{"seqId":"1","addressLine1":"Address 1","city":"City 1","state":"ST 1","zip":"12345","country":"Country 1"},"pliId":"' + testHardwareLineItem1.Id + '"},' +
                '{"itemToValidate":{"seqId":"2","addressLine1":"Address 2","city":"City 2","state":"ST 2","zip":"54321","country":"Country 2"}}]';
        AddressValidationApi.mockJsonResponce = '{"response":{"addressStandardizationResponse":[' +
                '{"seqId":"1","address":"Address 1","adressLine":"Address LINE 1","addressQualityFlags":"S4","carrierRoute":"C007","city":"HOLBROOK","cityStateZip":"HOLBROOK,NY11741-4433","countyCode":"103","deliveryPointValidation":"3","enhancedLineOfTravel":"0","reliability":"100","state":"NY","pcode":"2664600","zip":"11741","zip4":"4433","addressFault":null},' +
                '{"seqId":"2","address":null,"adressLine":null,"addressQualityFlags":null,"carrierRoute":null,"city":null,"cityStateZip":null,"countyCode":"0","deliveryPointValidation":null,"enhancedLineOfTravel":null,"reliability":null,"state":null,"pcode":"5082200","zip":null,"zip4":null,"addressFault":null}]}}';
        Test.setMock(HttpCalloutMock.class, new AddressValidationApi());

        Map<String, PhaseManagementController.AddressResponseItemWrapper> result = PhaseManagementController.validateAdressesWrapper(testStr);
        Test.stopTest();

        System.assertEquals(2, result.size());
        System.assert(result.containsKey('1'));
        System.assert(result.containsKey('2'));
        System.assertNotEquals(null, result.get('1'));
        System.assertNotEquals(null, result.get('2'));

        // Check updated Hardware_Line_Item__c
        Hardware_Line_Item__c resultHardwareLineItem1 = [
                SELECT Id, Address_Validated__c, Address_Line__c, City__c, State__c, Postal_Code__c, Country__c
                FROM Hardware_Line_Item__c
                WHERE Id = :testHardwareLineItem1.Id
        ];
        System.assertEquals(true,        resultHardwareLineItem1.Address_Validated__c);
        System.assertEquals('Address LINE 1', resultHardwareLineItem1.Address_Line__c);
        System.assertEquals('HOLBROOK',    resultHardwareLineItem1.City__c);
        System.assertEquals('ST 1',      resultHardwareLineItem1.State__c);
        System.assertEquals('12345',     resultHardwareLineItem1.Postal_Code__c);
        System.assertEquals('Country 1', resultHardwareLineItem1.Country__c);
    }

    @isTest
    static void testUpdateDeletedPhases() {
        Map<String, Schema.RecordTypeInfo> PHASE_RECORD_TYPE_MAP =
            Schema.SObjectType.Phase__c.getRecordTypeInfosByName();

        Account testAcc = (Account) new SObjectFactory()
            .create(
                Account.SObjectType,
                new Map<SObjectField, Object> {Account.Name => ValueProviderBuilder.provideUniqueString()}
            );

        Contact testCon = (Contact) new SObjectFactory()
            .create(
                Contact.SObjectType,
                new Map<SObjectField, Object> {
                    Contact.LastName => ValueProviderBuilder.provideUniqueString(),
                    Contact.AccountId => testAcc.Id
                }
            );

        Opportunity testOpp = (Opportunity) new SObjectFactory()
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object> {
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => testCon.Id
                }
            );


        Quote testQuote = (Quote) new SObjectFactory()
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object> {
                    Quote.Name => ValueProviderBuilder.provideUniqueString(),
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                    Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_IN_PROGRESS
                }
            );

        Phase__c testPhase = (Phase__c) new SObjectFactory()
            .create(
                Phase__c.SObjectType,
                new Map<SObjectField, Object> {
                    Phase__c.Status__c => PhaseHelper.STATUS_NEW,
                    Phase__c.RecordTypeId => PHASE_RECORD_TYPE_MAP.get(PhaseHelper.RT_NAME_PROSERV_PHASE).getRecordTypeId()
                }
            );

        Test.startTest();
        Map<String, Phase__c> mapPhases = new Map<String, Phase__c>();
        String mapKey = 'Test Phase 1';
        mapPhases.put(mapKey,testPhase);
        PhaseManagementController.lockDeletedPhases(mapPhases);
        Test.stopTest();

        System.assertEquals(PhaseHelper.STATUS_DELETED,
                            mapPhases.get(mapKey).Status__c,
                            'Phase status did not update to Deleted');

        System.assert(Approval.isLocked(mapPhases.get(mapKey).Id),
                      'Phase record did not lock correctly');

    }

    @isTest
    static void test_getIsNewChangeOrder() {
        insert new Feature_Toggle__c (NewChangeOrderFlow__c = true);
        Test.startTest();
        Boolean isNewChangeOrder = PhaseManagementController.getIsNewChangeOrder();
        Test.stopTest();

        System.assertEquals(true, isNewChangeOrder, 'Could not get new change order feature toggle value');

    }

    @isTest
    private static void testGetRcVariousSettings() {
        insert new RingCentralVariousSettings__c (Address_Validation_API_Endpoint__c = 'https://testapi/');

        RingCentralVariousSettings__c result;

        Test.startTest();
        result = (RingCentralVariousSettings__c) PhaseManagementController.getRcVariousSettings(null, null, null);
        Test.stopTest();

        System.assertEquals(
            'https://testapi/',
            result.Address_Validation_API_Endpoint__c,
            'RC Various Settings retrieved incorrectly'
        );
    }

    @isTest
    private static void testFindMaxPhaseNumberOnOrder() {

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

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.Status => OrderHelper.STATUS_NEW,
                Order.PriceBook2Id => Test.getStandardPricebookId(),
                Order.QuoteId => q.Id,
                Order.OpportunityId => opp.Id,
                Order.EffectiveDate => System.today(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Phase__c.Name => 'Test',
                Phase__c.Opportunity__c => opp.Id,
                Phase__c.Quote__c => q.Id,
                Phase__c.Phase_Number__c => 1,
                Phase__c.Order__c => testOrder.Id
            })
            .create()
            .getRecord();

        Integer result;

        Test.startTest();
        result = PhaseManagementController.findMaxPhaseNumberOnOrder(testOrder.Id);
        Test.stopTest();

        System.assertEquals(
            1,
            result,
            'Method should return correct Max Phase Number on Order'
        );
    }

    @isTest
    private static void testFindMaxPhaseNumberOnOrderShouldThrowException() {

        Boolean isExceptionThrown = false;
        try {
            Test.startTest();
            PhaseManagementController.findMaxPhaseNumberOnOrder(null);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
        }

        System.assert(
            isExceptionThrown,
            'Method should throw exception for case with null order Id'
        );
    }

    @isTest
    private static void testGetPhasesShouldThrowException() {

        Boolean isExceptionThrown = false;
        try {
            Test.startTest();
            PhaseManagementController.getPhases(null);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
        }

        System.assert(
            isExceptionThrown,
            'Method should throw exception for case with null Id'
        );
    }

    @isTest
    private static void testGetUserAccessInfo() {
        Map<String, Boolean> result;

        Test.startTest();
        result = PhaseManagementController.getUserAccessInfo();
        Test.stopTest();

        System.assertEquals(
            2,
            result.size(),
            'Result map should contain 2 pairs of key value'
        );
    }

    @isTest
    private static void testGetOrderShouldThrowException() {

        Boolean isExceptionThrown = false;
        try {
            Test.startTest();
            PhaseManagementController.getOrder(null);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
        }

        System.assert(
            isExceptionThrown,
            'Method should throw exception for case with null order Id'
        );
    }

    @isTest
    private static void testUpsertPhasesShouldThrowException() {

        Boolean isExceptionThrown = false;
        try {
            Test.startTest();
            PhaseManagementController.upsertPhases(null);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
        }

        System.assert(
            isExceptionThrown,
            'Method should throw exception for case with null map'
        );
    }

    @isTest
    private static void testUpsertPhaseLineItemsShouldThrowException() {

        Boolean isExceptionThrown = false;
        try {
            Test.startTest();
            PhaseManagementController.upsertPhaseLineItems(null);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
        }

        System.assert(
            isExceptionThrown,
            'Method should throw exception for case with null list'
        );
    }

    @isTest
    private static void testDeletePhasesShouldThrowException() {

        Boolean isExceptionThrown = false;
        try {
            Test.startTest();
            PhaseManagementController.deletePhases(null);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
        }

        System.assert(
            isExceptionThrown,
            'Method should throw exception for case with null list'
        );
    }

    @isTest
    private static void testDeletePhaseLineItemsThrowException() {

        Boolean isExceptionThrown = false;
        try {
            Test.startTest();
            PhaseManagementController.deletePhaseLineItems(null);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
        }

        System.assert(
            isExceptionThrown,
            'Method should throw exception for case with null list'
        );
    }

    @isTest
    private static void testLockDeletedPhasesThrowException() {

        Boolean isExceptionThrown = false;
        try {
            Test.startTest();
            PhaseManagementController.lockDeletedPhases(null);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
        }

        System.assert(
            isExceptionThrown,
            'Method should throw exception for case with null map'
        );
    }

    @isTest
    private static void testFindParentOrderThrowException() {

        Boolean isExceptionThrown = false;
        try {
            Test.startTest();
            PhaseManagementController.FindParentOrder(null);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
        }

        System.assert(
            isExceptionThrown,
            'Method should throw exception for case with null Id'
        );
    }

    @isTest
    private static void testFindParentOrderOppWithoutParrent() {

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

        Order result;

        Test.startTest();
        result = PhaseManagementController.FindParentOrder(opp.Id);
        Test.stopTest();

        System.assertEquals(
            null,
            result,
            'Method should return null for Opportunity without Parent Order'
        );
    }

    @isTest
    static void testGetIsNewProservFlow() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null,
                    Quote.Pricebook2Id => pb.Id
                }
            )
            .create()
            .getRecord();

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{OpportunityHelper.TIER_OFFICE, OpportunityHelper.TIER_PROFESSIONAL_SERVICES})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Order testProservOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV ,
                    Order.AccountId => testAccount.Id,
                    Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.OpportunityId => opp.Id,
                    Order.QuoteId => masterQuote.Id
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
            Boolean isProservNewFlow = PhaseManagementController.getIsNewProservFlow(testProservOrder.Id);
        Test.stopTest();
        Assert.areEqual(true, isProservNewFlow, 'Method should return true');
    }

    @isTest
    static void testRTInfoById() {
        Map<Id, Schema.RecordTypeInfo> recordTypeInfoMap = HardwareLineItemHelper.RT_INFO_BY_ID;
        
        System.assertNotEquals(null, recordTypeInfoMap, 'RecordTypeInfo map should not be null');
        
        System.assert(recordTypeInfoMap.size() > 0, 'RecordTypeInfo map should contain entries');
        
        for(Id key : recordTypeInfoMap.keySet()) {
            Schema.RecordTypeInfo recordTypeInfo = recordTypeInfoMap.get(key);
            System.assertNotEquals(null, recordTypeInfo, 'RecordTypeInfo should not be null for key ' + key);
        }

        Map<Id, Schema.RecordTypeInfo> recordTypeInfoMap2 = HardwareLineItemHelper.RT_INFO_BY_ID;
        System.assertEquals(recordTypeInfoMap, recordTypeInfoMap2, 'Cached value should be returned');
    }

    @isTest
    static void upsertPhases_ShouldPreserveCustomName() {
        Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = '1. Qualify',
                CloseDate = system.today()
        );
        insert testOpportunity;

        Test.startTest();
        
        Phase__c newPhase = new Phase__c(
                Name = 'Temporary Name',
                Opportunity__c = testOpportunity.Id,
                Phase_Number__c = 1
        );
        
        Phase__c existingPhase = new Phase__c(
                Name = 'My Custom Phase Name',
                Opportunity__c = testOpportunity.Id,
                Phase_Number__c = 2
        );
        insert existingPhase;
        
        Map <String, Phase__c> testPhases = new Map <String, Phase__c> {
                'newPhase' => newPhase,
                'existingPhase' => existingPhase
        };

        Map <String, Phase__c> upsertPhasesResult = PhaseManagementController.upsertPhases(testPhases);
        Test.stopTest();

        Phase__c resultNewPhase = [SELECT Name FROM Phase__c WHERE Id = :upsertPhasesResult.get('newPhase').Id];
        Assert.areEqual('Phase 1', resultNewPhase.Name, 'New phase should get standard name');
        
        Phase__c resultExistingPhase = [SELECT Name FROM Phase__c WHERE Id = :upsertPhasesResult.get('existingPhase').Id];
        Assert.areEqual('My Custom Phase Name', resultExistingPhase.Name, 'Existing phase name should be preserved');
    }
}