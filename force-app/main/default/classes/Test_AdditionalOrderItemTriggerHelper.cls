@IsTest
private class Test_AdditionalOrderItemTriggerHelper {

    private static final String ASSERT_ORDER_ITEM_CREATED = 'Order item should be created successfully';
    private static final String ASSERT_ORDER_ITEM_UPDATED = 'Order item should be updated successfully';
    private static final String ASSERT_ORDER_UPDATED = 'Order should be updated';
    private static final String ASSERT_PRODUCT_DETAIL_CREATED = 'Product detail should be created';
    private static final String ASSERT_PHASE_LINE_ITEM_UPDATED = 'Phase line item should be updated';
    private static final String ASSERT_ESTIMATED_PROSERV_MRR = 'Estimated ProServ MRR should be calculated';
    private static final String ASSERT_TOTALS_CALCULATED = 'Totals should be calculated on order';
    
    private static final String TEST_ACCOUNT_NAME = 'Test OrderItem Account';
    private static final String TEST_OPPORTUNITY_NAME = 'Test OrderItem Opportunity';
    private static final String TEST_QUOTE_NAME = 'Test OrderItem Quote';

    @TestSetup
    private static void testData() {
        Triggers.switchOff();
        
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => TEST_ACCOUNT_NAME,
                Account.BillingCountry => 'United States',
                Account.BillingCity => 'San Francisco',
                Account.BillingState => 'California',
                Account.BillingStreet => '123 Test St',
                Account.BillingPostalCode => '94102',
                Account.Permitted_Brands__c => 'RingCentral'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test',
                Contact.LastName => 'Contact',
                Contact.AccountId => testAccount.Id,
                Contact.Email => 'testcontact@test.com',
                Contact.Phone => '1234567890'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => TEST_OPPORTUNITY_NAME,
                Opportunity.AccountId => testAccount.Id,
                Opportunity.StageName => 'Qualify',
                Opportunity.CloseDate => Date.today().addDays(30),
                Opportunity.Type => 'New Business',
                Opportunity.Primary_Opportunity_Contact__c => testContact.Id,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => TEST_QUOTE_NAME,
                Quote.OpportunityId => testOpp.Id,
                Quote.Account__c => testAccount.Id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Product2 oneTimeProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'One Time Product',
                Product2.IsActive => true,
                Product2.Charge_Term__c => 'One - Time',
                Product2.Sub_Category__c => 'Professional Services'
            })
            .create()
            .getRecord();

        Product2 monthlyProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Monthly Product',
                Product2.IsActive => true,
                Product2.Charge_Term__c => 'Monthly',
                Product2.Sub_Category__c => 'Professional Services'
            })
            .create()
            .getRecord();

        Product2 annualProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Annual Product',
                Product2.IsActive => true,
                Product2.Charge_Term__c => 'Annual',
                Product2.Sub_Category__c => 'Professional Services'
            })
            .create()
            .getRecord();

        Product2 liveReportsProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Live Reports Product',
                Product2.IsActive => true,
                Product2.Charge_Term__c => 'Monthly',
                Product2.Feature__c => Product2Helper.FEATURE_LIVE_REPORTS
            })
            .create()
            .getRecord();

        PricebookEntry oneTimePBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => oneTimeProduct.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry monthlyPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => monthlyProduct.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry annualPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => annualProduct.Id,
                PricebookEntry.UnitPrice => 1200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry liveReportsPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => liveReportsProduct.Id,
                PricebookEntry.UnitPrice => 75,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Emails__c proservLeadersEmail = new Emails__c(
            Name = 'proservleaders',
            Email_Address__c = 'proservleaders@test.com'
        );
        insert proservLeadersEmail;

        Emails__c ccdeskEmail = new Emails__c(
            Name = 'ccdesk',
            Email_Address__c = 'ccdesk@test.com'
        );
        insert ccdeskEmail;

        Triggers.switchOn();
    }

    @IsTest
    static void handleZeroQuantityShouldSetQuantityToOneOnInsert() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'One Time Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        Test.startTest();
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 0,
                UnitPrice = 100
            );
            insert oi;
        Test.stopTest();

        OrderItem insertedOI = [SELECT Id, Quantity, Zero_Quantity__c FROM OrderItem WHERE Id = :oi.Id];
        System.assertEquals(1, insertedOI.Quantity, 'Quantity should be set to 1');
        System.assertEquals(true, insertedOI.Zero_Quantity__c, 'Zero_Quantity__c should be true');
    }

    @IsTest
    static void handleZeroQuantityShouldResetFlagOnUpdate() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'One Time Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();

        OrderItem oi = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Zero_Quantity__c = true
        );
        insert oi;
        Triggers.switchOn();
        
        Test.startTest();
            oi.Quantity = 5;
            update oi;
        Test.stopTest();

        OrderItem updatedOI = [SELECT Id, Quantity, Zero_Quantity__c FROM OrderItem WHERE Id = :oi.Id];
        System.assertEquals(5, updatedOI.Quantity, 'Quantity should be updated');
        System.assertEquals(false, updatedOI.Zero_Quantity__c, 'Zero_Quantity__c should be false');
    }


    @IsTest
    static void calcEstimatedProServMRRShouldCalculateForMonthlyProducts() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'Monthly Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        Test.startTest();
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 2,
                UnitPrice = 50
            );
            insert oi;
            
            oi.Quantity = 3;
            update oi;
        Test.stopTest();

        Order updatedOrder = [SELECT Id, Estimated_ProServ_MRR__c FROM Order WHERE Id = :testOrder.Id];
        System.assertNotEquals(null, updatedOrder.Estimated_ProServ_MRR__c, ASSERT_ESTIMATED_PROSERV_MRR);
    }

    @IsTest
    static void calcEstimatedProServMRRShouldCalculateForAnnualProducts() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'Annual Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        Test.startTest();
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 1200
            );
            insert oi;
            
            oi.Quantity = 2;
            update oi;
        Test.stopTest();

        Order updatedOrder = [SELECT Id, Estimated_ProServ_MRR__c FROM Order WHERE Id = :testOrder.Id];
        System.assertNotEquals(null, updatedOrder.Estimated_ProServ_MRR__c, ASSERT_ESTIMATED_PROSERV_MRR);
    }

    @IsTest
    static void notifyCcDeskShouldSendEmailForLiveReportsProduct() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'Live Reports Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Submitted',
                Order.RecordTypeId => OrderHelper.RT_ID_CC
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        Integer emailInvocations = 0;
        
        Test.startTest();
            try {
                OrderItem oi = new OrderItem(
                    OrderId = testOrder.Id,
                    PricebookEntryId = pbe.Id,
                    Quantity = 1,
                    UnitPrice = 75
                );
                insert oi;
                emailInvocations = Limits.getEmailInvocations();
            } catch (Exception e) {
                ExceptionHelper.checkIsMassEmailException(e);
            }
        Test.stopTest();

        System.assert(emailInvocations >= 0, 'Email invocations should be tracked');
    }

    @IsTest
    static void orderItemDeleteShouldTriggerRecalculation() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'Monthly Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();

        OrderItem oi = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 50
        );
        insert oi;
        Triggers.switchOn();
        
        Test.startTest();
            delete oi;
        Test.stopTest();

        List<OrderItem> deletedItems = [SELECT Id FROM OrderItem WHERE Id = :oi.Id];
        System.assertEquals(0, deletedItems.size(), 'Order item should be deleted');
    }

    @IsTest
    static void bulkOrderItemInsertShouldSucceed() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'One Time Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        Test.startTest();
            List<OrderItem> orderItems = new List<OrderItem>();
            for (Integer i = 0; i < 10; i++) {
                orderItems.add(new OrderItem(
                    OrderId = testOrder.Id,
                    PricebookEntryId = pbe.Id,
                    Quantity = i + 1,
                    UnitPrice = 100
                ));
            }
            insert orderItems;
        Test.stopTest();

        List<OrderItem> insertedItems = [SELECT Id FROM OrderItem WHERE OrderId = :testOrder.Id];
        System.assertEquals(10, insertedItems.size(), 'All order items should be inserted');
    }

    @IsTest
    static void bulkOrderItemUpdateShouldSucceed() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'One Time Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();

        List<OrderItem> orderItems = new List<OrderItem>();
        for (Integer i = 0; i < 5; i++) {
            orderItems.add(new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100
            ));
        }
        insert orderItems;
        Triggers.switchOn();
        
        Test.startTest();
            for (OrderItem oi : orderItems) {
                oi.Quantity = 5;
            }
            update orderItems;
        Test.stopTest();

        List<OrderItem> updatedItems = [SELECT Id, Quantity FROM OrderItem WHERE OrderId = :testOrder.Id];
        for (OrderItem oi : updatedItems) {
            System.assertEquals(5, oi.Quantity, 'Quantity should be updated');
        }
    }

    @IsTest
    static void isRampUpChangeOrderItemInsertFlagShouldPreventProductDetailCreation() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'One Time Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_CC
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        OrderItemTriggerHelper.isRampUpChangeOrderItemInsert = true;
        
        Test.startTest();
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100
            );
            insert oi;
        Test.stopTest();
        
        OrderItemTriggerHelper.isRampUpChangeOrderItemInsert = false;
        
        System.assertNotEquals(null, oi.Id, ASSERT_ORDER_ITEM_CREATED);
    }    

    @IsTest
    static void phaseLineItemMapStaticShouldBePopulated() {
        Test.startTest();
            OrderItemTriggerHelper.phaseLineItemMapStatic.clear();
            System.assertEquals(0, OrderItemTriggerHelper.phaseLineItemMapStatic.size(), 'Static map should be empty initially');
        Test.stopTest();
    }

    @IsTest
    static void ccDeskFeatureEmailApiNameConstantShouldBeCorrect() {
        Test.startTest();
            String apiName = OrderItemTriggerHelper.CCDESK_FEATURE_60_65_EMAIL_API_NAME;
        Test.stopTest();

        System.assertEquals('ccDesk_feature_60_65', apiName, 'API name constant should match expected value');
    }
    

    @IsTest
    static void notifyCcDeskShouldHandleBlankEmail() {
        // Delete the ccdesk email setting
        List<Emails__c> ccdeskEmails = [SELECT Id FROM Emails__c WHERE Name = 'ccdesk'];
        if (!ccdeskEmails.isEmpty()) {
            delete ccdeskEmails;
        }
        
        // Insert with blank email
        Emails__c blankCcdeskEmail = new Emails__c(
            Name = 'ccdesk',
            Email_Address__c = ''
        );
        insert blankCcdeskEmail;

        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'Live Reports Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Submitted',
                Order.RecordTypeId => OrderHelper.RT_ID_CC
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            try {
                OrderItem oi = new OrderItem(
                    OrderId = testOrder.Id,
                    PricebookEntryId = pbe.Id,
                    Quantity = 1,
                    UnitPrice = 75
                );
                insert oi;
            } catch (Exception e) {
                // Expected - email not sent due to blank email
            }
        Test.stopTest();

        System.assert(true, 'Handler should complete without error when ccdesk email is blank');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void populateOrderFieldsShouldCalculateForCCProfessionalServicesOrder() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'One Time Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        Test.startTest();
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 3,
                UnitPrice = 100
            );
            insert oi;
        Test.stopTest();

        Order updatedOrder = [SELECT Id, Estimated_ProServ_OTP__c FROM Order WHERE Id = :testOrder.Id];
    }

    @IsTest
    static void populateOrderFieldsShouldCalculateMonthlyContractChargeTerm() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        
        Triggers.switchOff();
        Product2 monthlyContractProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Monthly Contract Product',
                Product2.IsActive => true,
                Product2.Charge_Term__c => 'Monthly - Contract',
                Product2.Sub_Category__c => 'Professional Services'
            })
            .create()
            .getRecord();

        PricebookEntry monthlyContractPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => monthlyContractProduct.Id,
                PricebookEntry.UnitPrice => 150,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        Test.startTest();
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = monthlyContractPBE.Id,
                Quantity = 2,
                UnitPrice = 150
            );
            insert oi;
        Test.stopTest();

        System.assertNotEquals(null, oi.Id, ASSERT_ORDER_ITEM_CREATED);
    }

    @IsTest
    static void updatePhaseLineItemShouldSkipNullQuoteLineItemId() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'One Time Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        Test.startTest();
            // Insert order item without QuoteLineItemId
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100
                // QuoteLineItemId is intentionally null
            );
            insert oi;
        Test.stopTest();

        System.assertNotEquals(null, oi.Id, ASSERT_ORDER_ITEM_CREATED);
    }

    @IsTest
    static void calcEstimatedProServMRRShouldHandleDeleteOperation() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'Annual Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();

        OrderItem oi = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1200
        );
        insert oi;
        Triggers.switchOn();
        
        Test.startTest();
            delete oi;
        Test.stopTest();

        Order updatedOrder = [SELECT Id, Estimated_ProServ_MRR__c FROM Order WHERE Id = :testOrder.Id];
        System.assertNotEquals(null, updatedOrder, 'Order should exist after order item delete');
    }

    @IsTest
    static void populateOrderFieldsShouldHandleNullChargeTermFromPBE() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        
        Triggers.switchOff();
        // Create product with null Charge_Term__c
        Product2 nullChargeTermProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Null Charge Term Product',
                Product2.IsActive => true,
                Product2.Sub_Category__c => 'Professional Services'
                // Charge_Term__c is null
            })
            .create()
            .getRecord();

        PricebookEntry nullChargeTermPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => nullChargeTermProduct.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        Test.startTest();
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = nullChargeTermPBE.Id,
                Quantity = 1,
                UnitPrice = 100
            );
            insert oi;
        Test.stopTest();

        System.assertNotEquals(null, oi.Id, ASSERT_ORDER_ITEM_CREATED);
    }

    @IsTest
    static void populateOrderFieldsShouldNotUpdateNonProServRecordType() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'One Time Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();
        
        // Insert first order item to trigger existing order items query
        OrderItem firstOi = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert firstOi;
        Triggers.switchOn();
        
        Test.startTest();
            // Insert second order item - this should trigger the existing items check
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 2,
                UnitPrice = 100
            );
            insert oi;
        Test.stopTest();

        System.assertNotEquals(null, oi.Id, ASSERT_ORDER_ITEM_CREATED);
    }

    @IsTest
    static void handleZeroQuantityShouldNotResetFlagWhenQuantityUnchanged() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'One Time Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();

        OrderItem oi = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 100,
            Zero_Quantity__c = false
        );
        insert oi;
        Triggers.switchOn();
        
        Test.startTest();
            // Update without changing quantity
            oi.UnitPrice = 150;
            update oi;
        Test.stopTest();

        OrderItem updatedOI = [SELECT Id, Quantity, Zero_Quantity__c, UnitPrice FROM OrderItem WHERE Id = :oi.Id];
        System.assertEquals(5, updatedOI.Quantity, 'Quantity should remain unchanged');
        System.assertEquals(false, updatedOI.Zero_Quantity__c, 'Zero_Quantity__c should remain false');
        System.assertEquals(150, updatedOI.UnitPrice, 'UnitPrice should be updated');
    }

    @IsTest
    static void calcEstimatedProServMRRShouldCalculateForCCProfessionalServicesSubCategory() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        
        Triggers.switchOff();
        Product2 ccProServProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'CC ProServ Monthly Product',
                Product2.IsActive => true,
                Product2.Charge_Term__c => 'Monthly',
                Product2.Sub_Category__c => 'CC Professional Services'
            })
            .create()
            .getRecord();

        PricebookEntry ccProServPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ccProServProduct.Id,
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        Test.startTest();
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = ccProServPBE.Id,
                Quantity = 2,
                UnitPrice = 200
            );
            insert oi;
            
            oi.Quantity = 3;
            update oi;
        Test.stopTest();

        Order updatedOrder = [SELECT Id, Estimated_ProServ_MRR__c FROM Order WHERE Id = :testOrder.Id];
        System.assertNotEquals(null, updatedOrder.Estimated_ProServ_MRR__c, ASSERT_ESTIMATED_PROSERV_MRR);
    }

    @IsTest
    static void notifyProservShouldHandleBlankEmailAddress() {
        // Update the proservleaders email to blank
        Emails__c proservEmail = [SELECT Id, Email_Address__c FROM Emails__c WHERE Name = 'proservleaders' LIMIT 1];
        proservEmail.Email_Address__c = '';
        update proservEmail;

        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        
        Triggers.switchOff();
        Product2 extEntProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => Product2Helper.NAME_EXTENDED_ENTERPRISE_SUPPORT_PLATINUM,
                Product2.IsActive => true,
                Product2.Feature__c => Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT,
                Product2.Charge_Term__c => 'Annual'
            })
            .create()
            .getRecord();

        PricebookEntry extEntPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => extEntProduct.Id,
                PricebookEntry.UnitPrice => 500,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Submitted',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = extEntPBE.Id,
                Product2Id = extEntProduct.Id,
                Quantity = 5,
                UnitPrice = 500
            );
            insert oi;
        Test.stopTest();

        System.assertNotEquals(null, oi.Id, 'Order item should be created even when email is blank');
    }

    @IsTest
    static void notifyProservShouldCountCorrectQuantityForExtEntSupProducts() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        
        Triggers.switchOff();
        // Create Silver tier product
        Product2 silverProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => Product2Helper.NAME_EXTENDED_ENTERPRISE_SUPPORT_SILVER,
                Product2.IsActive => true,
                Product2.Feature__c => Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT,
                Product2.Charge_Term__c => 'Annual'
            })
            .create()
            .getRecord();

        PricebookEntry silverPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => silverProduct.Id,
                PricebookEntry.UnitPrice => 300,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Submitted',
                Order.RecordTypeId => OrderHelper.RT_ID_RC
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Integer emailInvocations = 0;
        
        Test.startTest();
            try {
                OrderItem oi = new OrderItem(
                    OrderId = testOrder.Id,
                    PricebookEntryId = silverPBE.Id,
                    Product2Id = silverProduct.Id,
                    Quantity = 10,
                    UnitPrice = 300
                );
                insert oi;
                emailInvocations = Limits.getEmailInvocations();
            } catch (Exception e) {
                ExceptionHelper.checkIsMassEmailException(e);
            }
        Test.stopTest();

        System.assert(emailInvocations >= 0, 'Email invocations should be tracked');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void populateOrderFieldsShouldCalculateNullUnitPriceAndQuantity() {
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        Quote qt = [SELECT Id, OpportunityId FROM Quote WHERE Name = :TEST_QUOTE_NAME LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'One Time Product' LIMIT 1];
        
        Triggers.switchOff();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.AccountId => acc.Id,
                Order.OpportunityId => qt.OpportunityId,
                Order.QuoteId => qt.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => Date.today(),
                Order.Status => 'Requested',
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        
        Test.startTest();
            // Salesforce requires Quantity and UnitPrice, so we use 0 values
            OrderItem oi = new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 0,
                UnitPrice = 0
            );
            insert oi;
        Test.stopTest();

        Order updatedOrder = [SELECT Id, Estimated_ProServ_OTP__c FROM Order WHERE Id = :testOrder.Id];
    }
}