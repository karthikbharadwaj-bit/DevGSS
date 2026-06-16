@isTest
private class Test_BatchJobCheckCCEntls {

    private static List<Product2> createProducts() {

        SObjectFactory factory = new SObjectFactory();

        Product2 seatProduct = (Product2) factory
            .create(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testSeatProduct',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.ExtId__c => 'test_ExtId Overage',
                    Product2.Family => Product2Helper.FAMILY_CCSERVICE,
                    Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_SEAT
                }
            );

        Product2 seatOverageProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testSeatOverageProduct',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.ExtId__c => 'test_ExtId',
                    Product2.Family => Product2Helper.FAMILY_OVERAGE,
                    Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_SEAT,
                    Product2.Parent__c => seatProduct.Id
                }
            );


        Product2 minutesBundleProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testMinutesBundleProduct',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.ExtId__c => 'test_ExtId1',
                    Product2.Family => Product2Helper.FAMILY_MINUTES_BUNDLE,
                    Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_TRANSPORT,
                    Product2.Number_of_Minutes__c => 4
                }
            );

        Product2 minutesBundleOverageProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testMinutesBundleOverageProduct',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.ExtId__c => 'test_ExtId1 Overage',
                    Product2.Family => Product2Helper.FAMILY_OVERAGE,
                    Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_TRANSPORT,
                    Product2.Parent__c => seatProduct.Id
                }
            );


        Product2 inboundCallsProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testInboundCallsProduct',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.ExtId__c => 'test_ExtId2',
                    Product2.Family => Product2Helper.FAMILY_MINUTES_BUNDLE,
                    Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_INBOUND_CALLS
                }
            );

        Product2 inboundCallsOverageProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testInboundCallsOverageProduct',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.ExtId__c => 'test_ExtId2 Overage',
                    Product2.Family => Product2Helper.FAMILY_OVERAGE,
                    Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_INBOUND_CALLS,
                    Product2.Parent__c => seatProduct.Id
                }
            );


        Product2 outboundCallsProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testOutboundCallsProduct',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.ExtId__c => 'test_ExtId3',
                    Product2.Family => Product2Helper.FAMILY_MINUTES_BUNDLE,
                    Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_OUTBOUND_CALLS
                }
            );

        Product2 outboundCallsOverageProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testOutboundCallsOverageProduct',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.ExtId__c => 'test_ExtId3 Overage',
                    Product2.Family => Product2Helper.FAMILY_OVERAGE,
                    Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_OUTBOUND_CALLS,
                    Product2.Parent__c => seatProduct.Id
                }
            );


        Product2 portProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testPortProduct',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.ExtId__c => 'test_ExtId4',
                    Product2.Family => Product2Helper.FAMILY_ADDONS,
                    Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_PORT
                }
            );

        Product2 portOverageProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testPortOverageProduct',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.ExtId__c => 'test_ExtId4 Overage',
                    Product2.Family => Product2Helper.FAMILY_OVERAGE,
                    Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_PORT,
                    Product2.Parent__c => seatProduct.Id
                }
            );

        Product2 testCCProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testCCProduct',
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.Product_Type__c => null,
                    Product2.ExtId__c => 'test_ExtId5',
                    Product2.Family => Product2Helper.FAMILY_ADDONS
                }
            );

        Product2 testCCOverageProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object>{
                    Product2.Name => 'testCCOverageProduct',
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.Product_Type__c => null,
                    Product2.ExtId__c => 'test_ExtId5 Overage',
                    Product2.Family => Product2Helper.FAMILY_OVERAGE
                }
            );

        insert new List<Product2>{
            seatOverageProduct, minutesBundleProduct, minutesBundleOverageProduct,
            inboundCallsProduct, inboundCallsOverageProduct, outboundCallsProduct,
            outboundCallsOverageProduct, portProduct, portOverageProduct,
            testCCProduct, testCCOverageProduct
        };

        return new List<Product2>{
            seatProduct,
            seatOverageProduct,

            minutesBundleProduct,
            minutesBundleOverageProduct,

            inboundCallsProduct,
            inboundCallsOverageProduct,

            outboundCallsProduct,
            outboundCallsOverageProduct,

            portProduct,
            portOverageProduct,

            testCCProduct,
            testCCOverageProduct
        };
    }

    @testSetup
    private static void setup() {

        SObjectFactory factory = new SObjectFactory();

        List<Account> accountRecords = (List<Account>) factory
            .create(
                Account.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('testAccount'),
                    Account.RC_User_Id__c => ValueProviderBuilder.provideUniqueString('testRcUserId')
                }
            );

        List<Product2> productRecords = createProducts();
    }

    @isTest
    static void testBatchJobWithErrorsInData() {

        AccountSelector accSelector = new AccountSelector();
        List<Account> accList = accSelector.selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Id
            })
            .executeQuery();

        List<Product2> productList = new Product2Selector().selectProducts().executeQuery();

        SObjectFactory factory = new SObjectFactory();

        // create Entitlement__c records with incorrect Quantities and verify email is send
        List<Entitlement__c> entitlementRecords = (List<Entitlement__c>) factory
            .create(
                Entitlement__c.SObjectType,
                productList.size(),
                new Map<SObjectField, Object>{
                    Entitlement__c.Product__c => ValueProviderBuilder.provideParents(productList),
                    Entitlement__c.Account__c => ValueProviderBuilder.provideParents(accList),
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Quantity__c => ValueProviderBuilder.provideUniqueNumber(2)
                }
            );

        try{

            Test.startTest();
                BatchJob_CheckCCEntls ccEntlCheckerBatch = new BatchJob_CheckCCEntls();
                Database.executeBatch(ccEntlCheckerBatch);
            Test.stopTest();

            System.assertEquals(1, BatchJob_CheckCCEntls.emailLimits, 'An email has not been sent');

        }catch(Exception ex) {
            ExceptionHelper.checkIsMassEmailException(ex);
        }
    }

    @isTest
    static void testBatchJobWithoutErrorsInData() {

        AccountSelector accSelector = new AccountSelector();
        List<Account> accList = accSelector.selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Id
            })
            .executeQuery();

        List<Product2> productList = new Product2Selector().selectProducts().executeQuery();

        SObjectFactory factory = new SObjectFactory();

        // create Entitlement__c records with correct(equal) Quantities and verify email is not send
        List<Entitlement__c> entitlementRecords = (List<Entitlement__c>) factory
            .create(
                Entitlement__c.SObjectType,
                productList.size(),
                new Map<SObjectField, Object>{
                    Entitlement__c.Product__c => ValueProviderBuilder.provideParents(productList),
                    Entitlement__c.Account__c => ValueProviderBuilder.provideParents(accList),
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Quantity__c => 4
                }
            );

        Test.startTest();

            BatchJob_CheckCCEntls ccEntlCheckerBatch = new BatchJob_CheckCCEntls();

            Database.executeBatch(ccEntlCheckerBatch);
        Test.stopTest();

        System.assertEquals(0, BatchJob_CheckCCEntls.emailLimits, 'An email has been sent');
    }

    @isTest
    static void testBatchJobWithCustomQuery() {

        SObjectFactory factory = new SObjectFactory();

        Account testAccount = (Account) factory
            .create(
                Account.SObjectType,
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('testAccount2'),
                    Account.RC_User_Id__c => ValueProviderBuilder.provideUniqueString('someRcUserId')
                }
            );

        Test.startTest();

            String customQuery = 'SELECT Account__r.RC_User_Id__c ' +
                'FROM Entitlement__c WHERE Account__c = \'' + testAccount.Id + '\'';

            BatchJob_CheckCCEntls ccEntlCheckerBatch = new BatchJob_CheckCCEntls(customQuery);

            Database.executeBatch(ccEntlCheckerBatch);
        Test.stopTest();

        System.assertEquals(0, BatchJob_CheckCCEntls.emailLimits, 'An email has been sent');

    }

    @isTest
    static void testScheduleBatch() {

        Datetime dt = Datetime.now().addMinutes(1);

        String cronExpression = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();

        Test.startTest();

            Integer cronTriggerCountBeforeSchedule = [SELECT count() FROM CronTrigger];

            String jobId = System.schedule('Test check', cronExpression, new CheckCCEntlsScheduler());

            Integer cronTriggerCountAfterSchedule = [SELECT count() FROM CronTrigger];

            System.assertNotEquals(
                cronTriggerCountBeforeSchedule,
                cronTriggerCountAfterSchedule,
                'A job should be scheduled'
            );

        Test.stopTest();
    }
}