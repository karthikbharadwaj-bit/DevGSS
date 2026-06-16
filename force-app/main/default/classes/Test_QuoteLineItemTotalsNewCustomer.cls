@isTest
private class Test_QuoteLineItemTotalsNewCustomer {

    private static List<Product2> createProducts(Boolean isNeedInsert) {

        if(isNeedInsert == null) {
            isNeedInsert = false;
        }

        List<Product2> prodList = new List<Product2>();

        Product2 testProduct = new Product2(
            Name = 'test product',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
        );
        prodList.add(testProduct);

        Product2 testDiscountedPhoneProduct = new Product2(
            Name = 'test product1',
            IsActive = true,
            GOA_Group_V2__c = 'Device_Contract',
            Family = Product2Helper.FAMILY_DISCOUNTED_PHONES,
            Feature__c = 11,
            Sub_Feature__c = 56,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        prodList.add(testDiscountedPhoneProduct);

        Product2 testRentalPhone = new Product2(
            Name = 'test Rental Phone product',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Family = Product2Helper.FAMILY_RENTAL_PHONES,
            Feature__c = 34,
            Sub_Feature__c = 66,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        prodList.add(testRentalPhone);

        Product2 testAddOn = new Product2(
            Name = 'test Add-On product',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            GOA_Group_V2__c = 'GOA_Other_Products',
            Family = Product2Helper.FAMILY_ADDONS,
            Feature__c = 47,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT
        );
        prodList.add(testAddOn);

        Product2 testAnnualProduct = new Product2(
            Name = 'test Service product',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            GOA_Group_V2__c = 'GOA_Other_Products',
            Family = Product2Helper.FAMILY_ADDONS,
            Feature__c = 47,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ANNUAL
        );
        prodList.add(testAnnualProduct);

        if(isNeedInsert) {
            insert prodList;
        }

        return prodList;
    }

    @testSetup
    static void setup() {

        Triggers.switchOff();
        Account testAccnt = new Account(
            Name = 'test account'
        );
        insert testAccnt;
        Triggers.switchOn();

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            IsActive = true,
            Line_Range_Min__c = 5,
            Line_Range_Max__c = 10,
            CurrencyIsoCode = 'USD'
        );
        insert testPriceBook;

        Opportunity testOpp = new Opportunity(
            AccountId = testAccnt.Id,
            Name = 'Test Opportunity',
            Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Office',
            StageName = OpportunityHelper.STAGE_NAME_QUALIFY,
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert testOpp;

        Quote testSalesQuote = new Quote (
            Name = 'testSalesQuote',
            Auto_Renewal__c = true,
            OpportunityId = testOpp.Id,
            Pricebook2Id = testPriceBook.Id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Upsell_Status__c = QuoteHelper.STATUS_NEW_CUSTOMER,
            CurrencyIsoCode = 'USD'
        );
        insert testSalesQuote;


        List<Product2> prodList = createProducts(false);
        insert prodList;

        List<PricebookEntry> pbeList = new List<PricebookEntry>();

        for(Product2 item : prodList) {

            pbeList.add(
                new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                )
            );

            pbeList.add(
                new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                )
            );
        }
        insert pbeList;
    }

    @isTest
    static void testPopulateDiscountAndEffectivePriceMethodWithoutData() {

        QuoteLineItemTotals.PopulateDiscountAndEffectivePrice discountAndEffectivePricePopulator = new QuoteLineItemTotals.PopulateDiscountAndEffectivePrice();

        List<QuoteLineItem> result = discountAndEffectivePricePopulator.populateFields(null);

        System.assertNotEquals(result, null);
        System.assert(result.size() == 0);

        result = discountAndEffectivePricePopulator.populateFields(new List<QuoteLineItem>());

        System.assertNotEquals(result, null);
        System.assert(result.size() == 0);
    }

    @isTest
    static void testPopulateDiscountAndEffectivePriceMethodWithData() {

        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry];

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();

        for(PricebookEntry pbe : pbeList) {
            if(pbe.Pricebook2Id == testSalesQuote.Pricebook2Id) {
                QuoteLineItem qli = new QuoteLineItem(
                    Product2Id = pbe.Product2Id,
                    PricebookEntryId = pbe.Id,
                    QuoteId = testSalesQuote.Id,
                    Quantity = 5,
                    Zero_Quantity__c = false,
                    UnitPrice = pbe.UnitPrice,
                    Discount_number__c = 2,
                    Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                );

                qli.Discount = (qli.Discount_number__c / qli.UnitPrice) * 100; // value in this field stored as percent

                qliList.add(qli);
            }
        }

        QuoteLineItemTotals.PopulateDiscountAndEffectivePrice discountAndEffectivePricePopulator = new QuoteLineItemTotals.PopulateDiscountAndEffectivePrice();

        Test.startTest();

            Integer usedQueriesNumber = System.Limits.getQueries();

            List<QuoteLineItem> processedQliList = discountAndEffectivePricePopulator.populateFields(qliList);

            System.assertNotEquals(null, processedQliList);
            System.assert(processedQliList.size() > 0);

            for(QuoteLineItem qli : processedQliList) {

                System.assertNotEquals(null, qli.DiscountValueNew__c);
                System.assertNotEquals(null, qli.EffectivePriceNew__c);

                Decimal calculatedDiscountValueNew = (qli.UnitPrice * (qli.Discount / 100));
                Decimal calculatedEffectivePriceNew = (qli.UnitPrice * (1 - (qli.Discount / 100)));
                System.assertEquals(
                    calculatedDiscountValueNew,
                    qli.DiscountValueNew__c,
                    'QuoteLineItem.DiscountValueNew__c calculated incorrectly'
                );
                System.assertEquals(
                    calculatedEffectivePriceNew,
                    qli.EffectivePriceNew__c,
                    'QuoteLineItem.EffectivePriceNew__c calculated incorrectly'
                );
            }

            System.assertEquals(
                usedQueriesNumber,
                System.Limits.getQueries(),
                'QuoteLineItemTotals.PopulateDiscountAndEffectivePrice.populateFields method should not use SOQL queries'
            );

        Test.stopTest();
    }

    @isTest
    static void testPopulateDiscountAndEffectivePriceOnQLIInsert() {

        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry];

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();

        for(PricebookEntry pbe : pbeList) {
            if(pbe.Pricebook2Id == testSalesQuote.Pricebook2Id) {
                QuoteLineItem qli = new QuoteLineItem(
                    Product2Id = pbe.Product2Id,
                    PricebookEntryId = pbe.Id,
                    QuoteId = testSalesQuote.Id,
                    Quantity = 5,
                    Zero_Quantity__c = false,
                    UnitPrice = pbe.UnitPrice,
                    Discount_number__c = 2,
                    Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                );

                qliList.add(qli);
            }
        }

        Test.startTest();

            insert qliList;

        Test.stopTest();

        List<QuoteLineItem> reselectedQliList = [SELECT Id, UnitPrice,
                Discount, DiscountValueNew__c, EffectivePriceNew__c
            FROM QuoteLineItem
            WHERE QuoteId = :testSalesQuote.Id];

        for(QuoteLineItem qli : reselectedQliList) {

            System.assertNotEquals(null, qli.DiscountValueNew__c);
            System.assertNotEquals(null, qli.EffectivePriceNew__c);

            Decimal calculatedDiscountValueNew = (qli.UnitPrice * (qli.Discount / 100));
            Decimal calculatedEffectivePriceNew = (qli.UnitPrice * (1 - (qli.Discount / 100)));
            System.assertEquals(
                calculatedDiscountValueNew,
                qli.DiscountValueNew__c,
                'QuoteLineItem.DiscountValueNew__c calculated incorrectly'
            );
            System.assertEquals(
                calculatedEffectivePriceNew,
                qli.EffectivePriceNew__c,
                'QuoteLineItem.EffectivePriceNew__c calculated incorrectly'
            );
        }
    }

    @isTest
    static void testPopulateDiscountAndEffectivePriceOnQLIUpdate() {

        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry];

        Test.startTest();
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry pbe : pbeList) {
                if(pbe.Pricebook2Id == testSalesQuote.Pricebook2Id) {
                    QuoteLineItem qli = new QuoteLineItem(
                        Product2Id = pbe.Product2Id,
                        PricebookEntryId = pbe.Id,
                        QuoteId = testSalesQuote.Id,
                        Quantity = 5,
                        Zero_Quantity__c = false,
                        UnitPrice = pbe.UnitPrice,
                        Discount_number__c = 2,
                        Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                    );

                    qliList.add(qli);
                }
            }
            insert qliList;

            // update quoteLineItems(increase discount number)
            for(QuoteLineItem qli : qliList) {
                qli.Discount_number__c += 1;
            }

            // update should trigger DiscountValueNew__c and EffectivePriceNew__c recalculation
            update qliList;

        Test.stopTest();

        List<QuoteLineItem> reselectedQliList = [SELECT Id, UnitPrice,
                Discount, DiscountValueNew__c, EffectivePriceNew__c
            FROM QuoteLineItem
            WHERE QuoteId = :testSalesQuote.Id];

        for(QuoteLineItem qli : reselectedQliList) {

            System.assertNotEquals(null, qli.DiscountValueNew__c);
            System.assertNotEquals(null, qli.EffectivePriceNew__c);

            Decimal calculatedDiscountValueNew = (qli.UnitPrice * (qli.Discount / 100));
            Decimal calculatedEffectivePriceNew = (qli.UnitPrice * (1 - (qli.Discount / 100)));
            System.assertEquals(
                calculatedDiscountValueNew,
                qli.DiscountValueNew__c,
                'QuoteLineItem.DiscountValueNew__c calculated incorrectly'
            );
            System.assertEquals(
                calculatedEffectivePriceNew,
                qli.EffectivePriceNew__c,
                'QuoteLineItem.EffectivePriceNew__c calculated incorrectly'
            );
        }
    }


    @isTest
    static void testPopulateQLITotalsMethodWithoutData() {

        QuoteLineItemTotals.PopulateQLITotals qliTotalsPopulator = new QuoteLineItemTotals.PopulateQLITotals();

        List<QuoteLineItem> result = qliTotalsPopulator.populateTotalFields(null, null, null);

        System.assertNotEquals(result, null);
        System.assert(result.size() == 0);

        result = qliTotalsPopulator.populateTotalFields(new List<QuoteLineItem>(), null, null);

        System.assertNotEquals(result, null);
        System.assert(result.size() == 0);
    }

    @isTest
    static void testPopulateQLITotalsMethodWithData() {

        Quote testSalesQuote = [SELECT Id, Pricebook2Id, Account.RC_Account_Status__c FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry];

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();

        for(PricebookEntry pbe : pbeList) {
            if(pbe.Pricebook2Id == testSalesQuote.Pricebook2Id) {
                QuoteLineItem qli = new QuoteLineItem(
                    Product2Id = pbe.Product2Id,
                    PricebookEntryId = pbe.Id,
                    QuoteId = testSalesQuote.Id,
                    Quantity = 5,
                    Zero_Quantity__c = false,
                    UnitPrice = pbe.UnitPrice,
                    Discount_number__c = 2,
                    Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                );

                qli.Discount = (qli.Discount_number__c / qli.UnitPrice) * 100; // value in this field stored as percent

                // EffectivePriceNew__c field used in PopulateQLITotals functionality - so it should be selected or calculated
                qli.EffectivePriceNew__c = qli.UnitPrice * (1 - (qli.Discount / 100));

                qliList.add(qli);
            }
        }

        Test.startTest();
            insert qliList;

            Map<Id, Product2> productsMap = new Map<Id, Product2>([SELECT Id, Charge_Term__c, Family FROM Product2]);
            Map<Id, Entitlement__c> entitilementsMap = new Map<Id, Entitlement__c>([SELECT Id, DisplayQuantity__c, EffectivePrice__c, Product__c, Product__r.Charge_Term__c FROM Entitlement__c]);

            QuoteLineItemTotals.PopulateQLITotals qliTotalsPopulator = new QuoteLineItemTotals.PopulateQLITotals();


            Integer usedQueriesNumber = System.Limits.getQueries();

            List<QuoteLineItem> result = qliTotalsPopulator.populateTotalFields(qliList, productsMap, entitilementsMap);

            System.assertNotEquals(result, null);

            for(QuoteLineItem qli : result) {
                System.assertNotEquals(null, qli.Total_Annual__c, 'Total_Annual__c should not be null');
                System.assertNotEquals(null, qli.Total_Monthly__c, 'Total_Monthly__c should not be null');
                System.assertNotEquals(null, qli.Total_One_Time__c, 'Total_One_Time__c should not be null');
                System.assertNotEquals(null, qli.Delta_MRR__c, 'Delta_MRR__c should not be null');
                System.assertNotEquals(null, qli.Delta_ARR__c, 'Delta_ARR__c should not be null');
            }

            System.assertEquals(
                usedQueriesNumber,
                System.Limits.getQueries(),
                'QuoteLineItemTotals.PopulateQLITotals.populateTotalFields method should not use SOQL queries'
            );

        Test.stopTest();
    }

    @isTest
    static void testPopulateQLITotalsOnQLIInsert() {

        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry];

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();

        for(PricebookEntry pbe : pbeList) {
            if(pbe.Pricebook2Id == testSalesQuote.Pricebook2Id) {
                QuoteLineItem qli = new QuoteLineItem(
                    Product2Id = pbe.Product2Id,
                    PricebookEntryId = pbe.Id,
                    QuoteId = testSalesQuote.Id,
                    Quantity = 5,
                    Zero_Quantity__c = false,
                    UnitPrice = pbe.UnitPrice,
                    Discount_number__c = 2,
                    Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                );

                qliList.add(qli);
            }
        }

        Test.startTest();

            insert qliList;

        Test.stopTest();

        List<QuoteLineItem> reselectedQliList = [SELECT Id, Total_Annual__c,
                Total_Monthly__c, Total_One_Time__c, Delta_MRR__c, Delta_ARR__c
            FROM QuoteLineItem
            WHERE QuoteId = :testSalesQuote.Id];

        for(QuoteLineItem qli : reselectedQliList) {
            System.assertNotEquals(null, qli.Total_Annual__c);
            System.assertNotEquals(null, qli.Total_Monthly__c);
            System.assertNotEquals(null, qli.Total_One_Time__c);
            System.assertNotEquals(null, qli.Delta_MRR__c);
            System.assertNotEquals(null, qli.Delta_ARR__c);
        }
    }

    @isTest
    static void testPopulateQLITotalsOnQLIUpdate() {

        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry];

        Test.startTest();
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry pbe : pbeList) {
                if(pbe.Pricebook2Id == testSalesQuote.Pricebook2Id) {
                    QuoteLineItem qli = new QuoteLineItem(
                        Product2Id = pbe.Product2Id,
                        PricebookEntryId = pbe.Id,
                        QuoteId = testSalesQuote.Id,
                        Quantity = 5,
                        Zero_Quantity__c = false,
                        UnitPrice = pbe.UnitPrice,
                        Discount_number__c = 2,
                        Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                    );

                    qliList.add(qli);
                }
            }
            insert qliList;

            Map<Id, QuoteLineItem> qliMap = new Map<Id, QuoteLineItem>([SELECT Id, Total_Annual__c,
                Total_Monthly__c, Total_One_Time__c, Delta_MRR__c, Delta_ARR__c
            FROM QuoteLineItem
            WHERE QuoteId = :testSalesQuote.Id]);

            // update quoteLineItems(increase discount number)
            for(QuoteLineItem qli : qliList) {
                qli.Discount_number__c += 1;
            }

            // update should trigger Total_Annual__c, Total_Monthly__c, Total_One_Time__c, Delta_MRR__c, Delta_ARR__c recalculation
            update qliList;

            List<QuoteLineItem> reselectedQliList = [SELECT Id, Total_Annual__c,
                    Total_Monthly__c, Total_One_Time__c, Delta_MRR__c, Delta_ARR__c
                FROM QuoteLineItem
                WHERE QuoteId = :testSalesQuote.Id];

            // verify that QuoteLineItem totals fields are calculated and its values differs with values calculated after initial insert
            for(QuoteLineItem qli : reselectedQliList) {

                System.assertNotEquals(null, qli.Total_Annual__c);
                System.assertNotEquals(null, qli.Total_Monthly__c);
                System.assertNotEquals(null, qli.Total_One_Time__c);
                System.assertNotEquals(null, qli.Delta_MRR__c);
                System.assertNotEquals(null, qli.Delta_ARR__c);

                QuoteLineItem qliAfterInsert = qliMap.get(qli.Id);

                // quoteLineItem total fields values after update should differ with quoteLineItem total fields values after insert
                // or these values should be 0 after insert and after update
                System.assert(
                    ((qliAfterInsert.Total_Annual__c != qli.Total_Annual__c) ||
                    (qliAfterInsert.Total_Annual__c == 0 && qli.Total_Annual__c == 0)),
                    'QuoteLineItem.Total_Annual__c calculated incorrectly'
                );

                System.assert(
                    ((qliAfterInsert.Total_Monthly__c != qli.Total_Monthly__c) ||
                    (qliAfterInsert.Total_Monthly__c == 0 && qli.Total_Monthly__c == 0)),
                    'QuoteLineItem.Total_Monthly__c calculated incorrectly'
                );

                System.assert(
                    ((qliAfterInsert.Total_One_Time__c != qli.Total_One_Time__c) ||
                    (qliAfterInsert.Total_One_Time__c == 0 && qli.Total_One_Time__c == 0)),
                    'QuoteLineItem.Total_One_Time__c calculated incorrectly'
                );

                System.assert(
                    ((qliAfterInsert.Delta_MRR__c != qli.Delta_MRR__c) ||
                    (qliAfterInsert.Delta_MRR__c == 0 && qli.Delta_MRR__c == 0)),
                    'QuoteLineItem.Delta_MRR__c calculated incorrectly'
                );

                System.assert(
                    ((qliAfterInsert.Delta_ARR__c != qli.Delta_ARR__c) ||
                    (qliAfterInsert.Delta_ARR__c == 0 && qli.Delta_ARR__c == 0)),
                    'QuoteLineItem.Delta_ARR__c calculated incorrectly'
                );
            }
        Test.stopTest();
    }


    @isTest
    static void testComputeTotalOneTimeMethod() {

        QuoteLineItemTotals.PopulateQLITotals qliTotalsPopulator = new QuoteLineItemTotals.PopulateQLITotals();

        // it should return 0 if passed arguments is null
        Decimal computedTotalOneTime = qliTotalsPopulator.computeTotalOneTime(null, null, null);
        System.assertNotEquals(null, computedTotalOneTime);
        System.assertEquals(0, computedTotalOneTime);

        // it should return 0 if first argument(product chargeTerm) is null
        computedTotalOneTime = qliTotalsPopulator.computeTotalOneTime(null, 0, 0);
        System.assertNotEquals(null, computedTotalOneTime);
        System.assertEquals(0, computedTotalOneTime);

        // it should return 0 if first argument(product chargeTerm) is empty string
        computedTotalOneTime = qliTotalsPopulator.computeTotalOneTime('', 0, 0);
        System.assertNotEquals(null, computedTotalOneTime);
        System.assertEquals(0, computedTotalOneTime);

        // it should return 0 if first argument(product chargeTerm) is not One - Time
        String productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        computedTotalOneTime = qliTotalsPopulator.computeTotalOneTime(productChargeTerm, 0, 0);
        System.assertNotEquals(null, computedTotalOneTime);
        System.assertEquals(0, computedTotalOneTime);

        productChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
        computedTotalOneTime = qliTotalsPopulator.computeTotalOneTime(productChargeTerm, 0, 0);
        System.assertNotEquals(null, computedTotalOneTime);
        System.assertEquals(0, computedTotalOneTime);

        productChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT;
        computedTotalOneTime = qliTotalsPopulator.computeTotalOneTime(productChargeTerm, 0, 0);
        System.assertNotEquals(null, computedTotalOneTime);
        System.assertEquals(0, computedTotalOneTime);


        // it should multiply second(quantity) and third(effectivePrice) arguments if first argument(product chargeTerm) is One - Time
        productChargeTerm = Product2Helper.CHARGE_TERM_ONE_TIME;
        Decimal quantity = 2;
        Decimal effectivePrice = 2;
        computedTotalOneTime = qliTotalsPopulator.computeTotalOneTime(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalOneTime);
        System.assertEquals((quantity * effectivePrice), computedTotalOneTime);

        // it should threat second(quantity) and third(effectivePrice) arguments as 0 if its null
        quantity = null;
        effectivePrice = null;
        computedTotalOneTime = qliTotalsPopulator.computeTotalOneTime(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalOneTime);
        System.assertEquals(0, computedTotalOneTime);
    }

    @isTest
    static void testComputeTotalMonthlyMethod() {

        QuoteLineItemTotals.PopulateQLITotals qliTotalsPopulator = new QuoteLineItemTotals.PopulateQLITotals();

        // it should return 0 if passed arguments is null
        Decimal computedTotalMonthly = qliTotalsPopulator.computeTotalMonthly(null, null, null);
        System.assertNotEquals(null, computedTotalMonthly);
        System.assertEquals(0, computedTotalMonthly);

        // it should return 0 if first argument(product chargeTerm) is null
        computedTotalMonthly = qliTotalsPopulator.computeTotalMonthly(null, 0, 0);
        System.assertNotEquals(null, computedTotalMonthly);
        System.assertEquals(0, computedTotalMonthly);

        // it should return 0 if first argument(product chargeTerm) is empty string
        computedTotalMonthly = qliTotalsPopulator.computeTotalMonthly('', 0, 0);
        System.assertNotEquals(null, computedTotalMonthly);
        System.assertEquals(0, computedTotalMonthly);

        // it should return 0 if first argument(product chargeTerm) is One - Time
        String productChargeTerm = Product2Helper.CHARGE_TERM_ONE_TIME;
        Decimal quantity = 2;
        Decimal effectivePrice = 2;
        computedTotalMonthly = qliTotalsPopulator.computeTotalMonthly(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalMonthly);
        System.assertEquals(0, computedTotalMonthly);


        // it should multiply second(quantity) and third(effectivePrice) arguments if first
        // argument(product chargeTerm) is Monthly or Monthly - Contract
        productChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
        quantity = 2;
        effectivePrice = 2;
        computedTotalMonthly = qliTotalsPopulator.computeTotalMonthly(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalMonthly);
        System.assertEquals((quantity * effectivePrice), computedTotalMonthly);

        productChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT;
        quantity = 2;
        effectivePrice = 2;
        computedTotalMonthly = qliTotalsPopulator.computeTotalMonthly(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalMonthly);
        System.assertEquals((quantity * effectivePrice), computedTotalMonthly);


        // it should multiply second(quantity) and third(effectivePrice) arguments and divide by 12 if first
        // argument(product chargeTerm) is Annual
        productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        quantity = 2;
        effectivePrice = 2;
        computedTotalMonthly = qliTotalsPopulator.computeTotalMonthly(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalMonthly);
        System.assertEquals(((quantity * effectivePrice) / 12), computedTotalMonthly);

        // it should threat second(quantity) and third(effectivePrice) arguments as 0 if its null
        productChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT;
        quantity = null;
        effectivePrice = null;
        computedTotalMonthly = qliTotalsPopulator.computeTotalMonthly(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalMonthly);
        System.assertEquals(0, computedTotalMonthly);
    }

    @isTest
    static void testComputeTotalAnnualMethod() {

        QuoteLineItemTotals.PopulateQLITotals qliTotalsPopulator = new QuoteLineItemTotals.PopulateQLITotals();

        // it should return 0 if passed arguments is null
        Decimal computedTotalAnnual = qliTotalsPopulator.computeTotalAnnual(null, null, null);
        System.assertNotEquals(null, computedTotalAnnual);
        System.assertEquals(0, computedTotalAnnual);

        // it should return 0 if first argument(product chargeTerm) is null
        computedTotalAnnual = qliTotalsPopulator.computeTotalAnnual(null, 0, 0);
        System.assertNotEquals(null, computedTotalAnnual);
        System.assertEquals(0, computedTotalAnnual);

        // it should return 0 if first argument(product chargeTerm) is empty string
        computedTotalAnnual = qliTotalsPopulator.computeTotalAnnual('', 0, 0);
        System.assertNotEquals(null, computedTotalAnnual);
        System.assertEquals(0, computedTotalAnnual);

        // it should return 0 if first argument(product chargeTerm) is One - Time
        String productChargeTerm = Product2Helper.CHARGE_TERM_ONE_TIME;
        Decimal quantity = 2;
        Decimal effectivePrice = 2;
        computedTotalAnnual = qliTotalsPopulator.computeTotalAnnual(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalAnnual);
        System.assertEquals(0, computedTotalAnnual);


        // it should multiply second(quantity) and third(effectivePrice) arguments if first
        // argument(product chargeTerm) is Annual
        productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        quantity = 2;
        effectivePrice = 2;
        computedTotalAnnual = qliTotalsPopulator.computeTotalAnnual(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalAnnual);
        System.assertEquals((quantity * effectivePrice), computedTotalAnnual);


        // it should multiply second(quantity) and third(effectivePrice) arguments and multiply by 12 if first
        // argument(product chargeTerm) is Monthly or Monthly - Contract
        productChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
        quantity = 2;
        effectivePrice = 2;
        computedTotalAnnual = qliTotalsPopulator.computeTotalAnnual(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalAnnual);
        System.assertEquals(((quantity * effectivePrice) * 12), computedTotalAnnual);

        productChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT;
        quantity = 2;
        effectivePrice = 2;
        computedTotalAnnual = qliTotalsPopulator.computeTotalAnnual(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalAnnual);
        System.assertEquals(((quantity * effectivePrice) * 12), computedTotalAnnual);

        // it should threat second(quantity) and third(effectivePrice) arguments as 0 if its null
        productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        quantity = null;
        effectivePrice = null;
        computedTotalAnnual = qliTotalsPopulator.computeTotalAnnual(productChargeTerm, quantity, effectivePrice);
        System.assertNotEquals(null, computedTotalAnnual);
        System.assertEquals(0, computedTotalAnnual);
    }

    @isTest
    static void testComputeDeltaMrrMethod() {

        QuoteLineItemTotals.PopulateQLITotals qliTotalsPopulator = new QuoteLineItemTotals.PopulateQLITotals();

        // it should return 0 if passed arguments is null
        Decimal computedDeltaMrr = qliTotalsPopulator.computeDeltaMrr(null, null, null, null, null, null, null);
        System.assertNotEquals(null, computedDeltaMrr);
        System.assertEquals(0, computedDeltaMrr);

        // it should return 0 if first argument(product chargeTerm) is One - Time
        String productChargeTerm = Product2Helper.CHARGE_TERM_ONE_TIME;
        Decimal quantity = null;
        Decimal effectivePrice = null;
        Decimal entlDisplayQuantity = null;
        Decimal entlEffectivePrice = null;
        String entitlementChargeTerm = null;
        computedDeltaMrr = qliTotalsPopulator.computeDeltaMrr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaMrr);
        System.assertEquals(0, computedDeltaMrr);


        // it should threat numeric type arguments as 0 if its null
        productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        quantity = null;
        effectivePrice = null;
        entlDisplayQuantity = null;
        entlEffectivePrice = null;
        computedDeltaMrr = qliTotalsPopulator.computeDeltaMrr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaMrr);
        System.assertEquals(0, computedDeltaMrr);

        // if QuoteLineItem has no Entitlements - it should compute value anyway, but treat entitlements values as 0
        productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        quantity = 2;
        effectivePrice = 2;
        entlDisplayQuantity = null;
        entlEffectivePrice = null;
        computedDeltaMrr = qliTotalsPopulator.computeDeltaMrr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaMrr);

        Decimal computedDeltaMrrToCheck = ((quantity * effectivePrice) / 12);
        System.assertEquals(computedDeltaMrrToCheck, computedDeltaMrr);


        // formula that used for deltaMrr computation can differ depending on QuoteLineItem and Entitlement products chargeTerm

        // chargeTerm is Annual for QuoteLineItem and Entitlement products
        productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        quantity = 2;
        effectivePrice = 2;
        entlDisplayQuantity = 2;
        entlEffectivePrice = 2;
        computedDeltaMrr = qliTotalsPopulator.computeDeltaMrr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaMrr);

        computedDeltaMrrToCheck = (((quantity + entlDisplayQuantity) * effectivePrice) / 12) -
            ((entlDisplayQuantity * entlEffectivePrice) / 12);
        System.assertEquals(computedDeltaMrrToCheck, computedDeltaMrr);


        // chargeTerm is NOT Annual for QuoteLineItem and Entitlement products
        productChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
        quantity = 2;
        effectivePrice = 2;
        entlDisplayQuantity = 2;
        entlEffectivePrice = 2;
        computedDeltaMrr = qliTotalsPopulator.computeDeltaMrr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaMrr);

        computedDeltaMrrToCheck = ((quantity + entlDisplayQuantity) * effectivePrice) -
            (entlDisplayQuantity * entlEffectivePrice);
        System.assertEquals(computedDeltaMrrToCheck, computedDeltaMrr);


        // chargeTerm is NOT Annual for QuoteLineItem product and Annual for Entitlement product
        productChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        quantity = 2;
        effectivePrice = 2;
        entlDisplayQuantity = 2;
        entlEffectivePrice = 2;
        computedDeltaMrr = qliTotalsPopulator.computeDeltaMrr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaMrr);

        computedDeltaMrrToCheck = ((quantity + entlDisplayQuantity) * effectivePrice) -
            ((entlDisplayQuantity * entlEffectivePrice) / 12);
        System.assertEquals(computedDeltaMrrToCheck, computedDeltaMrr);



        // chargeTerm is Annual for QuoteLineItem product and NOT Annual for Entitlement product
        productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
        quantity = 2;
        effectivePrice = 2;
        entlDisplayQuantity = 2;
        entlEffectivePrice = 2;
        computedDeltaMrr = qliTotalsPopulator.computeDeltaMrr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaMrr);

        computedDeltaMrrToCheck = (((quantity + entlDisplayQuantity) * effectivePrice) / 12) -
            (entlDisplayQuantity * entlEffectivePrice);
        System.assertEquals(computedDeltaMrrToCheck, computedDeltaMrr);
    }

    @isTest
    static void testComputeDeltaArrMethod() {

        QuoteLineItemTotals.PopulateQLITotals qliTotalsPopulator = new QuoteLineItemTotals.PopulateQLITotals();

        // it should return 0 if passed arguments is null
        Decimal computedDeltaArr = qliTotalsPopulator.computeDeltaArr(null, null, null, null, null, null, null);
        System.assertNotEquals(null, computedDeltaArr);
        System.assertEquals(0, computedDeltaArr);

        // it should return 0 if first argument(product chargeTerm) is One - Time
        String productChargeTerm = Product2Helper.CHARGE_TERM_ONE_TIME;
        Decimal quantity = null;
        Decimal effectivePrice = null;
        Decimal entlDisplayQuantity = null;
        Decimal entlEffectivePrice = null;
        String entitlementChargeTerm = null;
        computedDeltaArr = qliTotalsPopulator.computeDeltaArr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaArr);
        System.assertEquals(0, computedDeltaArr);


        // it should threat numeric type arguments as 0 if its null
        productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        quantity = null;
        effectivePrice = null;
        entlDisplayQuantity = null;
        entlEffectivePrice = null;
        computedDeltaArr = qliTotalsPopulator.computeDeltaArr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaArr);
        System.assertEquals(0, computedDeltaArr);

        // if QuoteLineItem has no Entitlements - it should compute value anyway, but treat entitlements values as 0
        productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        quantity = 2;
        effectivePrice = 2;
        entlDisplayQuantity = null;
        entlEffectivePrice = null;
        computedDeltaArr = qliTotalsPopulator.computeDeltaArr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaArr);

        Decimal computedDeltaArrToCheck = (quantity * effectivePrice);
        System.assertEquals(computedDeltaArrToCheck, computedDeltaArr);


        // formula that used for deltaMrr computation can differ depending on QuoteLineItem and Entitlement products chargeTerm

        // chargeTerm is Annual for QuoteLineItem and Entitlement products
        productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        quantity = 2;
        effectivePrice = 2;
        entlDisplayQuantity = 2;
        entlEffectivePrice = 2;
        computedDeltaArr = qliTotalsPopulator.computeDeltaArr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaArr);

        computedDeltaArrToCheck = (((quantity + entlDisplayQuantity) * effectivePrice)) -
            ((entlDisplayQuantity * entlEffectivePrice));
        System.assertEquals(computedDeltaArrToCheck, computedDeltaArr);


        // chargeTerm is NOT Annual for QuoteLineItem and Entitlement products
        productChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
        quantity = 2;
        effectivePrice = 2;
        entlDisplayQuantity = 2;
        entlEffectivePrice = 2;
        computedDeltaArr = qliTotalsPopulator.computeDeltaArr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaArr);

        computedDeltaArrToCheck = (((quantity + entlDisplayQuantity) * effectivePrice) * 12) -
            ((entlDisplayQuantity * entlEffectivePrice) * 12);
        System.assertEquals(computedDeltaArrToCheck, computedDeltaArr);


        // chargeTerm is NOT Annual for QuoteLineItem product and Annual for Entitlement product
        productChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        quantity = 2;
        effectivePrice = 2;
        entlDisplayQuantity = 2;
        entlEffectivePrice = 2;
        computedDeltaArr = qliTotalsPopulator.computeDeltaArr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaArr);

        computedDeltaArrToCheck = (((quantity + entlDisplayQuantity) * effectivePrice) * 12) -
            (entlDisplayQuantity * entlEffectivePrice);
        System.assertEquals(computedDeltaArrToCheck, computedDeltaArr);



        // chargeTerm is Annual for QuoteLineItem product and NOT Annual for Entitlement product
        productChargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
        entitlementChargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
        quantity = 2;
        effectivePrice = 2;
        entlDisplayQuantity = 2;
        entlEffectivePrice = 2;
        computedDeltaArr = qliTotalsPopulator.computeDeltaArr(
            productChargeTerm,
            quantity,
            effectivePrice,
            entlDisplayQuantity,
            entlEffectivePrice,
            entitlementChargeTerm,
            null
        );
        System.assertNotEquals(null, computedDeltaArr);

        computedDeltaArrToCheck = ((quantity + entlDisplayQuantity) * effectivePrice) -
            ((entlDisplayQuantity * entlEffectivePrice) * 12);
        System.assertEquals(computedDeltaArrToCheck, computedDeltaArr);
    }
}