@isTest
private class Test_QuoteTotalsNewCustomer {

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

        Product2 testCCOneTimeProduct = new Product2(
            Name = 'test CC one time product',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            Family = Product2Helper.FAMILY_ADDONS,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        prodList.add(testCCOneTimeProduct);

        Product2 testCCMonthlyContractProduct = new Product2(
            Name = 'test CC Monthly Contract product',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            Family = Product2Helper.FAMILY_WFO,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT
        );
        prodList.add(testCCMonthlyContractProduct);

        Product2 testTaxProduct = new Product2(
            Name = 'test Tax product',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Family = Product2Helper.FAMILY_TAXES,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        prodList.add(testTaxProduct);

        if(isNeedInsert) {
            insert prodList;
        }

        return prodList;
    }

    private static List<QuoteLineItem> createQuoteLineItems(Id quoteId, Id quotePBId, List<PricebookEntry> pbeList) {

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();

        // create QuoteLineItems
        for(PricebookEntry pbe : pbeList) {
            if(pbe.Pricebook2Id == quotePBId) {
                QuoteLineItem qli = new QuoteLineItem(
                    Product2Id = pbe.Product2Id,
                    PricebookEntryId = pbe.Id,
                    QuoteId = quoteId,
                    Quantity = 5,
                    Zero_Quantity__c = false,
                    UnitPrice = pbe.UnitPrice,
                    Discount_number__c = 2,
                    Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                );

                qli.Discount = (qli.Discount_number__c / qli.UnitPrice) * 100; // value in this field stored as percent

                // EffectivePriceNew__c field used in totals computation functionality - so it should be selected or calculated
                qli.EffectivePriceNew__c = qli.UnitPrice * (1 - (qli.Discount / 100));

                qli.DiscountValueNew__c = qli.UnitPrice * (qli.Discount / 100);

                qli.TotalSummary__c = qli.EffectivePriceNew__c * QuoteLineItemHelper.getQuantity(qli);

                // add Fixed_Taxes_Amount__c and Variable_Taxes_Amount__c? this value used in testComputeTotalOneTimeWithTaxes????

                // add Delta_MRR__c, Delta_ARR__c this value used in testComputeDeltaMrr???

                // set Product2 chargeTerm
                qli.Product2 = new Product2(
                    Id = pbe.Product2Id,
                    Family = pbe.Product2.Family,
                    Charge_Term__c = pbe.Product2.Charge_Term__c
                );

                qliList.add(qli);
            }
        }

        return qliList;
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
            ServiceName__c = OpportunityHelper.TIER_RC_CONTACT_CENTER,
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
    static void testPopulateTotalsWithoutData() {

        List<Quote> result = QuoteTotals.populateTotals(null);
        System.assertNotEquals(null, result);
        System.assertEquals(new List<Quote>(), result);

        result = QuoteTotals.populateTotals(new Map<Id, List<QuoteLineITem>>());
        System.assertNotEquals(null, result);
        System.assertEquals(new List<Quote>(), result);
    }

    @isTest
    static void testComputeTotalOneTime() {

        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeTotalOneTime(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalOneTime(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalOneTime(qliList);

        Decimal calculatedTotalOneTime = 0;
        for(QuoteLineItem qli : qliList) {
            if(
                !Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(qli.Product2.Charge_Term__c)
                || Product2Helper.isTaxes(qli.Product2)
            ) {
                continue;
            }
            calculatedTotalOneTime += (qli.Quantity * qli.EffectivePriceNew__c);
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalOneTime, result);
    }

    @isTest
    static void testComputeEstimatedHardware() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeEstimatedHardware(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeEstimatedHardware(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeEstimatedHardware(qliList);

        Decimal calculatedEstimatedHardware = 0;
        for(QuoteLineItem qli : qliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME &&
                    qli.Product2.Family.containsIgnoreCase('phone')) {

                calculatedEstimatedHardware += (qli.Quantity * qli.EffectivePriceNew__c);
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedEstimatedHardware, result);
    }

    @isTest
    static void testComputeTotalMRR() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeTotalMRR(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalMRR(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalMRR(qliList);

        Decimal calculatedTotalMrr = 0;
        for(QuoteLineItem qli : qliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                calculatedTotalMrr += ((qli.Quantity * qli.EffectivePriceNew__c) / 12);
            }else{
                calculatedTotalMrr += (qli.Quantity * qli.EffectivePriceNew__c);
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalMrr, result);
    }

    private static QuoteLineItem[] prepareTestData() {
        List<Decimal> newQtyList = new List<Decimal>{1,2,3,4,5,6,7};
        Integer size = newQtyList.size();
        List<String> families = new List<String>{
            null,
            null,
            null,
            Product2Helper.FAMILY_SERVICE,
            Product2Helper.FAMILY_TAXES,
            Product2Helper.FAMILY_TAXES,
            Product2Helper.FAMILY_TAXES
        };
        List<String> prodNames = new List<String> {
            'Product Annual',
            'Product Monthly',
            'Product One Time',
            'Service Monthly',
            'Tax 1 Monthly',
            'Tax 2 Monthly',
            'Tax One Time'
        };

        List<String> durations = new List<String> {
            Product2Helper.CHARGE_TERM_ANNUAL,
            Product2Helper.CHARGE_TERM_MONTHLY,
            Product2Helper.CHARGE_TERM_ONE_TIME,
            Product2Helper.CHARGE_TERM_MONTHLY,
            Product2Helper.CHARGE_TERM_MONTHLY,
            Product2Helper.CHARGE_TERM_MONTHLY,
            Product2Helper.CHARGE_TERM_ONE_TIME
        };

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .quantity(size)
            .setFields(new Map<SObjectField, Object> {
                    Product2.Name => ValueProviderBuilder.provideList(prodNames),
                    Product2.Charge_Term__c => ValueProviderBuilder.provideList(durations),
                    Product2.IsActive => true,
                    Product2.Family => ValueProviderBuilder.provideList(families)
            })
            .create()
            .getRecords();

        List<Id> prodIds = new List<Id>(new Map<Id, SObject>(products).keySet());

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(size)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(prodIds),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecords();

        List<Id> pbeIds = new List<Id>(new Map<Id, SObject>(pbeList).keySet());

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => ValueProviderBuilder.provideGenericParent(Opportunity.sObjectType),
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        QuoteLineItem[] qlis = new SObjectBuilder(QuoteLineItem.SObjectType)
            .quantity(size)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.NewQuantity__c => ValueProviderBuilder.provideList(newQtyList),
                    QuoteLineItem.QuoteId => qt.Id,
                    QuoteLineItem.Quantity => ValueProviderBuilder.provideList(newQtyList),
                    QuoteLineItem.Zero_Quantity__c => false,
                    QuoteLineItem.UnitPrice => 105,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(prodIds),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(pbeIds)
                }
            )
            .create()
            .getRecords();

        qlis = new QuoteLineItemSelector()
            .selectQuoteLineItemsForQLITrigger(new Set<Id>{qt.Id})
            .executeQuery();

        return qlis;
    }

    @isTest
    static void verifyComputeTotalMRRReturnTotalWithTaxes() {
        Test.startTest();
        QuoteLineItem[] qlis = prepareTestData();
        QuoteTotals totalsPopulator = new QuoteTotals();
        Test.stopTest();
        System.assertEquals(638.75, totalsPopulator.computeTotalMRR(qlis, false));
        System.assertEquals(1793.75, totalsPopulator.computeTotalMRR(qlis, true));
    }

    @isTest
    static void verifyComputeTotalARRReturnTotalWithTaxes() {
        Test.startTest();
        QuoteLineItem[] qlis = prepareTestData();
        QuoteTotals totalsPopulator = new QuoteTotals();
        Test.stopTest();
        System.assertEquals(7665, totalsPopulator.computeTotalARR(qlis, false));
        System.assertEquals(21525, totalsPopulator.computeTotalARR(qlis, true));
    }

    @isTest
    static void verifyComputeTotalOneTimeReturnTotalWithTaxes() {
        Test.startTest();
        QuoteLineItem[] qlis = prepareTestData();
        QuoteTotals totalsPopulator = new QuoteTotals();
        Test.stopTest();
        System.assertEquals(315, totalsPopulator.computeTotalOneTime(qlis, false));
        System.assertEquals(1050, totalsPopulator.computeTotalOneTime(qlis, true));
    }

    @isTest
    static void verifyComputeTotalInitialPaymentReturnTotalWithTaxes() {
        Test.startTest();
        QuoteLineItem[] qlis = prepareTestData();
        QuoteTotals totalsPopulator = new QuoteTotals();
        Test.stopTest();
        Assert.areEqual(1050, totalsPopulator.computeTotalInitialPayment(qlis, false, false), 'Total Initial Payment should be calculated correctly without Taxes and without ProServ Items');
        Assert.areEqual(2940, totalsPopulator.computeTotalInitialPayment(qlis, true, false), 'Total Initial Payment should be calculated correctly with Taxes and without ProServ Items');
    }

    @isTest
    static void testComputeTotalARR() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeTotalARR(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalARR(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalARR(qliList);

        Decimal calculatedTotalArr = 0;
        for(QuoteLineItem qli : qliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY || qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                calculatedTotalArr += ((qli.Quantity * qli.EffectivePriceNew__c) * 12);
            }else{
                calculatedTotalArr += (qli.Quantity * qli.EffectivePriceNew__c);
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalArr, result);
    }

    @isTest
    static void testComputeTotalInitialPayment() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeTotalInitialPayment(null, false);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalInitialPayment(new List<QuoteLineItem>(), false);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalInitialPayment(qliList, false);

        Decimal calculatedTotalInitialPayment = 0;
        for(QuoteLineItem qli : qliList) {
            if (Product2Helper.isTaxes(qli.Product2)) {
                continue;
            }

            calculatedTotalInitialPayment += (qli.Quantity * qli.EffectivePriceNew__c);
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalInitialPayment, result);
    }

    @isTest
    static void testComputeTotalOneTimeDiscount() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeTotalOneTimeDiscount(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalOneTimeDiscount(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalOneTimeDiscount(qliList);

        Decimal calculatedTotalOneTimeDiscount = 0;
        for(QuoteLineItem qli : qliList) {
            if(
                qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME
                || Product2Helper.isTaxes(qli.Product2)
            ) {
                continue;
            }
            calculatedTotalOneTimeDiscount += (qli.Quantity * qli.DiscountValueNew__c);
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalOneTimeDiscount, result);
    }

    @isTest
    static void testComputeTotalMRRDiscount() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeTotalMRRDiscount(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalMRRDiscount(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalMRRDiscount(qliList);

        Decimal calculatedTotalMrrDiscount = 0;
        for(QuoteLineItem qli : qliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                calculatedTotalMrrDiscount += ((qli.Quantity * qli.DiscountValueNew__c) / 12);
            }else{
                calculatedTotalMrrDiscount += qli.Quantity * qli.DiscountValueNew__c;
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalMrrDiscount, result);
    }

    @isTest
    static void testComputeTotalARRDiscount() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeTotalARRDiscount(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalARRDiscount(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalARRDiscount(qliList);

        Decimal calculatedTotalArrDiscount = 0;
        for(QuoteLineItem qli : qliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY || qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                calculatedTotalArrDiscount += ((qli.Quantity * qli.DiscountValueNew__c) * 12);
            }else{
                calculatedTotalArrDiscount += qli.Quantity * qli.DiscountValueNew__c;
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalArrDiscount, result);
    }

    @isTest
    static void testComputeTotalInitialPaymentDiscount() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal totalOneTimeDiscount = 0;

        Decimal result = totalsPopulator.computeTotalInitialPaymentDiscount(null, totalOneTimeDiscount);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalInitialPaymentDiscount(new List<QuoteLineItem>(), totalOneTimeDiscount);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalInitialPaymentDiscount(qliList, totalOneTimeDiscount);

        Decimal calculatedTotalInitialPaymentDiscount = 0;
        for(QuoteLineItem qli : qliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            calculatedTotalInitialPaymentDiscount += qli.Quantity * qli.DiscountValueNew__c;
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalInitialPaymentDiscount, result);
    }

    @isTest
    static void testComputeTotalOneTimeWithTaxes() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal quoteTotalOneTimeValue = 0;

        Decimal result = totalsPopulator.computeTotalOneTimeWithTaxes(null, quoteTotalOneTimeValue);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalOneTimeWithTaxes(new List<QuoteLineItem>(), quoteTotalOneTimeValue);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalOneTimeWithTaxes(qliList, quoteTotalOneTimeValue);

        Decimal calculatedTotalInitialPaymentDiscount = 0;
        for(QuoteLineItem qli : qliList) {
            if(qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            Decimal fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
            Decimal variableTaxesAmount = qli.Variable_Taxes_Amount__c == null ? 0 : qli.Variable_Taxes_Amount__c;

            calculatedTotalInitialPaymentDiscount += fixedTaxesAmount + variableTaxesAmount;
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalInitialPaymentDiscount, result);
    }

    @isTest
    static void testComputeTotalMRRWithTaxes() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal quoteTotalMrrValue = 0;

        Decimal result = totalsPopulator.computeTotalMRRWithTaxes(null, quoteTotalMrrValue);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalMRRWithTaxes(new List<QuoteLineItem>(), quoteTotalMrrValue);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalMRRWithTaxes(qliList, quoteTotalMrrValue);

        Decimal calculatedTotalMrrWithTaxes = 0;
        for(QuoteLineItem qli : qliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            Decimal fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
            Decimal variableTaxesAmount = qli.Variable_Taxes_Amount__c == null ? 0 : qli.Variable_Taxes_Amount__c;

            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                calculatedTotalMrrWithTaxes += (fixedTaxesAmount + variableTaxesAmount) / 12;
            }else{
                calculatedTotalMrrWithTaxes += fixedTaxesAmount + variableTaxesAmount;
            }

        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalMrrWithTaxes, result);
    }

    @isTest
    static void testComputeTotalARRWithTaxes() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal quoteTotalArrValue = 0;

        Decimal result = totalsPopulator.computeTotalARRWithTaxes(null, quoteTotalArrValue);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalARRWithTaxes(new List<QuoteLineItem>(), quoteTotalArrValue);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalARRWithTaxes(qliList, quoteTotalArrValue);

        Decimal calculatedTotalArrWithTaxes = 0;
        for(QuoteLineItem qli : qliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            Decimal fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
            Decimal variableTaxesAmount = qli.Variable_Taxes_Amount__c == null ? 0 : qli.Variable_Taxes_Amount__c;

            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY || qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                calculatedTotalArrWithTaxes += (fixedTaxesAmount + variableTaxesAmount) * 12;
            }else{
                calculatedTotalArrWithTaxes += fixedTaxesAmount + variableTaxesAmount;
            }

        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalArrWithTaxes, result);
    }

    @isTest
    static void testComputeTotalInitialPaymentWithTaxes() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal quoteTotalInitialPayment = 0;

        Decimal result = totalsPopulator.computeTotalInitialPaymentWithTaxes(null, quoteTotalInitialPayment);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalInitialPaymentWithTaxes(new List<QuoteLineItem>(), quoteTotalInitialPayment);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalInitialPaymentWithTaxes(qliList, quoteTotalInitialPayment);

        Decimal calculatedTotalInitialPaymentWithTaxes = 0;
        for(QuoteLineItem qli : qliList) {

            Decimal fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
            Decimal variableTaxesAmount = qli.Variable_Taxes_Amount__c == null ? 0 : qli.Variable_Taxes_Amount__c;

            calculatedTotalInitialPaymentWithTaxes += fixedTaxesAmount + variableTaxesAmount;
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalInitialPaymentWithTaxes, result);
    }

    @isTest
    static void testComputeContactCenterTotalOneTime() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeContactCenterTotalOneTime(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeContactCenterTotalOneTime(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeContactCenterTotalOneTime(qliList);

        Decimal calculatedContactCenterTotalOneTime = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME && qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                calculatedContactCenterTotalOneTime += qli.Quantity * qli.EffectivePriceNew__c;
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedContactCenterTotalOneTime, result);
    }

    @isTest
    static void testComputeContactCenterTotalMRR() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeContactCenterTotalMRR(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeContactCenterTotalMRR(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeContactCenterTotalMRR(qliList);

        Decimal calculatedContactCenterTotalMrr = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME && qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                    calculatedContactCenterTotalMrr += (qli.Quantity * qli.EffectivePriceNew__c) / 12;
                }else{
                    calculatedContactCenterTotalMrr += (qli.Quantity * qli.EffectivePriceNew__c);
                }
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedContactCenterTotalMrr, result);
    }

    @isTest
    static void testComputeContactCenterTotalARR() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeContactCenterTotalARR(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeContactCenterTotalARR(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeContactCenterTotalARR(qliList);

        Decimal calculatedContactCenterTotalArr = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME && qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY || qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                    calculatedContactCenterTotalArr += (qli.Quantity * qli.EffectivePriceNew__c) * 12;
                }else{
                    calculatedContactCenterTotalArr += (qli.Quantity * qli.EffectivePriceNew__c);
                }
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedContactCenterTotalArr, result);
    }

    @isTest
    static void testComputeContactCenterTotalInitialPayment() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeContactCenterTotalInitialPayment(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeContactCenterTotalInitialPayment(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeContactCenterTotalInitialPayment(qliList);

        Decimal calculatedContactCenterTotalInitialPayment = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                calculatedContactCenterTotalInitialPayment += (qli.Quantity * qli.EffectivePriceNew__c);
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedContactCenterTotalInitialPayment, result);
    }

    @isTest
    static void testComputeContactCenterTotalOneTimeDiscount() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeContactCenterTotalOneTimeDiscount(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeContactCenterTotalOneTimeDiscount(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeContactCenterTotalOneTimeDiscount(qliList);

        Decimal calculatedContactCenterTotalOneTimeDiscount = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER && qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                calculatedContactCenterTotalOneTimeDiscount += (qli.Quantity * qli.DiscountValueNew__c);
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedContactCenterTotalOneTimeDiscount, result);
    }

    @isTest
    static void testComputeContactCenterTotalMRRDiscount() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeContactCenterTotalMRRDiscount(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeContactCenterTotalMRRDiscount(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeContactCenterTotalMRRDiscount(qliList);

        Decimal calculatedContactCenterTotalMrrDiscount = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER && qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME) {
                if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                    calculatedContactCenterTotalMrrDiscount += ((qli.Quantity * qli.DiscountValueNew__c) / 12);
                }else{
                    calculatedContactCenterTotalMrrDiscount += (qli.Quantity * qli.DiscountValueNew__c);
                }
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedContactCenterTotalMrrDiscount, result);
    }

    @isTest
    static void testComputeContactCenterTotalARRDiscount() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeContactCenterTotalARRDiscount(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeContactCenterTotalARRDiscount(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeContactCenterTotalARRDiscount(qliList);

        Decimal calculatedContactCenterTotalArrDiscount = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER && qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME) {
                if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY || qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                    calculatedContactCenterTotalArrDiscount += ((qli.Quantity * qli.DiscountValueNew__c) * 12);
                }else{
                    calculatedContactCenterTotalArrDiscount += (qli.Quantity * qli.DiscountValueNew__c);
                }
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedContactCenterTotalArrDiscount, result);
    }

    @isTest
    static void testComputeContactCenterTotalInitialPaymentDiscount() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal contactCenterTotalOneTimeDiscount = 0;

        Decimal result = totalsPopulator.computeContactCenterTotalInitialPaymentDiscount(null, contactCenterTotalOneTimeDiscount);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeContactCenterTotalInitialPaymentDiscount(new List<QuoteLineItem>(), contactCenterTotalOneTimeDiscount);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeContactCenterTotalInitialPaymentDiscount(qliList, contactCenterTotalOneTimeDiscount);

        Decimal calculatedContactCenterTotalInitialPaymentDiscount = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER && qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME) {
                calculatedContactCenterTotalInitialPaymentDiscount += (qli.Quantity * qli.DiscountValueNew__c);
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedContactCenterTotalInitialPaymentDiscount, result);
    }

    @isTest
    static void testComputeDeltaMrr() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeDeltaMrr(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeDeltaMrr(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeDeltaMrr(qliList);

        Decimal calculatedDeltaMrr = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }
            Decimal deltaMrrValue = qli.Delta_MRR__c == null ? 0 : qli.Delta_MRR__c;
            calculatedDeltaMrr += deltaMrrValue;
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedDeltaMrr, result);
    }

    @isTest
    static void testComputeDeltaArr() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeDeltaArr(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeDeltaArr(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeDeltaArr(qliList);

        Decimal calculatedDeltaArr = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }
            Decimal deltaArrValue = qli.Delta_ARR__c == null ? 0 : qli.Delta_ARR__c;
            calculatedDeltaArr += deltaArrValue;
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedDeltaArr, result);
    }

    @isTest
    static void testComputeDeltaCCMrr() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeDeltaCCMrr(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeDeltaCCMrr(new List<QuoteLineItem>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeDeltaCCMrr(qliList);

        Decimal calculatedDeltaCCMrr = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            if(qli.Product2.Sub_Category__c != Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                continue;
            }

            calculatedDeltaCCMrr += qli.Delta_MRR__c;
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedDeltaCCMrr, result);
    }

    @isTest
    static void testComputeDeltaCCArr() {
        QuoteTotals totalsPopulator = new QuoteTotals();
        QuoteSelector quoteSelectorInstance = new QuoteSelector();
        Quote testSalesQuote = (Quote) quoteSelectorInstance
            .selectQuoteByName('testSalesQuote')
            .selectFields(new Set<SObjectField> {
                Quote.Id,
                Quote.Pricebook2Id,
                Quote.OpportunityId
            })
            .selectFields(quoteSelectorInstance.getFieldList())
            .executeQuery()
            .get(0);
        Opportunity testOp = [SELECT Id, Tier_Name__c FROM Opportunity WHERE Id =: testSalesQuote.OpportunityId LIMIT 1];
        testOp.Tier_Name__c = 'RingCentral Contact Center';
        update testOp;

        totalsPopulator.quoteIdToQuoteMap = new Map<Id, Quote> {testSalesQuote.Id => testSalesQuote};
        Decimal result = totalsPopulator.computeDeltaCCArr(null, testSalesQuote.id);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = totalsPopulator.computeDeltaCCArr(new List<QuoteLineItem>(), testSalesQuote.id);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);


        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeDeltaCCArr(qliList, testSalesQuote.id);

        Decimal calculatedDeltaCCArr = 0;
        for(QuoteLineItem qli : qliList) {

            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            if (qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER || QuoteHelper.isRCCC(testSalesQuote)) {
                Decimal deltaArrValue = qli.Delta_ARR__c == null ? 0 : qli.Delta_ARR__c;
                calculatedDeltaCCArr += deltaArrValue;
            } else {
                continue;
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedDeltaCCArr, result);
    }


    @isTest
    static void testPopulateQuoteTotalsOnQLIInsert() {

        Quote testSalesQuote = [SELECT Id, Pricebook2Id, Total_One_Time__c,
                Total_MRR_New__c, Total_ARR__c, Total_Initial_Payment__c, Total_First_Year_Cost__c,
                Total_One_Time_Discount__c, Total_MRR_Discount__c, Total_ARR_Discount__c,
                Total_Initial_Payment_Discount__c, Total_First_Year_Discount__c,
                Total_One_Time_with_Taxes__c, Total_MRR_with_Taxes__c, Total_ARR_with_Taxes__c,
                Total_Initial_Payment_with_Taxes__c, Total_First_Year_Cost_with_Taxes__c,
                Contact_Center_Total_One_Time__c, Contact_Center_Total_MRR__c, Contact_Center_Total_ARR__c,
                Contact_Center_Total_Initial_Payment__c, Contact_Center_Total_First_Year_Cost__c,
                Contact_Center_Total_One_Time_Discount__c, Contact_Center_Total_MRR_Discount__c,
                Contact_Center_Total_ARR_Discount__c, ContactCenterTotalInitialPaymentDiscount__c,
                Contact_Center_Total_First_Year_Discount__c, Estimated_Hardware__c, Delta_MRR__c,
                Delta_ARR__c, Delta_CC_MRR__c, Delta_CC_ARR__c, TotalQuoteSummary__c
            FROM Quote LIMIT 1];

        // all quote totals should be 0 if quote has no quoteLineItems
        System.assertEquals(0, testSalesQuote.Total_One_Time__c);
        System.assertEquals(0, testSalesQuote.Total_MRR_New__c);
        System.assertEquals(0, testSalesQuote.Total_ARR__c);
        System.assertEquals(0, testSalesQuote.Total_Initial_Payment__c);
        System.assertEquals(0, testSalesQuote.Total_First_Year_Cost__c);
        System.assertEquals(0, testSalesQuote.Total_One_Time_Discount__c);
        System.assertEquals(0, testSalesQuote.Total_MRR_Discount__c);
        System.assertEquals(0, testSalesQuote.Total_ARR_Discount__c);
        System.assertEquals(0, testSalesQuote.Total_Initial_Payment_Discount__c);
        System.assertEquals(0, testSalesQuote.Total_First_Year_Discount__c);
        System.assertEquals(0, testSalesQuote.Total_One_Time_with_Taxes__c);
        System.assertEquals(0, testSalesQuote.Total_MRR_with_Taxes__c);
        System.assertEquals(0, testSalesQuote.Total_ARR_with_Taxes__c);
        System.assertEquals(0, testSalesQuote.Total_Initial_Payment_with_Taxes__c);
        System.assertEquals(0, testSalesQuote.Total_First_Year_Cost_with_Taxes__c);
        System.assertEquals(0, testSalesQuote.Contact_Center_Total_One_Time__c);
        System.assertEquals(0, testSalesQuote.Contact_Center_Total_MRR__c);
        System.assertEquals(0, testSalesQuote.Contact_Center_Total_ARR__c);
        System.assertEquals(0, testSalesQuote.Contact_Center_Total_Initial_Payment__c);
        System.assertEquals(0, testSalesQuote.Contact_Center_Total_First_Year_Cost__c);
        System.assertEquals(0, testSalesQuote.Contact_Center_Total_One_Time_Discount__c);
        System.assertEquals(0, testSalesQuote.Contact_Center_Total_MRR_Discount__c);
        System.assertEquals(0, testSalesQuote.Contact_Center_Total_ARR_Discount__c);
        System.assertEquals(0, testSalesQuote.ContactCenterTotalInitialPaymentDiscount__c);
        System.assertEquals(0, testSalesQuote.Contact_Center_Total_First_Year_Discount__c);
        System.assertEquals(0, testSalesQuote.TotalQuoteSummary__c);
        System.assertEquals(0, testSalesQuote.Estimated_Hardware__c);
        System.assertEquals(0, testSalesQuote.Delta_MRR__c);
        System.assertEquals(0, testSalesQuote.Delta_ARR__c);
        System.assertEquals(0, testSalesQuote.Delta_CC_MRR__c);
        System.assertEquals(0, testSalesQuote.Delta_CC_ARR__c);

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry];

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();

        // create QuoteLineItems
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

                qli.Discount = (qli.Discount_number__c / qli.UnitPrice) * 100;
                qli.EffectivePriceNew__c = qli.UnitPrice * (1 - (qli.Discount / 100));
                qli.TotalSummary__c = qli.EffectivePriceNew__c * QuoteLineItemHelper.getQuantity(qli);

                qliList.add(qli);
            }
        }

        Test.startTest();

            insert qliList;

            Quote reselectedSalesQuote = [SELECT Id, Pricebook2Id, Total_One_Time__c,
                    Total_MRR_New__c, Total_ARR__c, Total_Initial_Payment__c, Total_First_Year_Cost__c,
                    Total_One_Time_Discount__c, Total_MRR_Discount__c, Total_ARR_Discount__c,
                    Total_Initial_Payment_Discount__c, Total_First_Year_Discount__c,
                    Total_One_Time_with_Taxes__c, Total_MRR_with_Taxes__c, Total_ARR_with_Taxes__c,
                    Total_Initial_Payment_with_Taxes__c, Total_First_Year_Cost_with_Taxes__c,
                    Contact_Center_Total_One_Time__c, Contact_Center_Total_MRR__c, Contact_Center_Total_ARR__c,
                    Contact_Center_Total_Initial_Payment__c, Contact_Center_Total_First_Year_Cost__c,
                    Contact_Center_Total_One_Time_Discount__c, Contact_Center_Total_MRR_Discount__c,
                    Contact_Center_Total_ARR_Discount__c, ContactCenterTotalInitialPaymentDiscount__c,
                    Contact_Center_Total_First_Year_Discount__c, Estimated_Hardware__c, Delta_MRR__c,
                    Delta_ARR__c, Delta_CC_MRR__c, Delta_CC_ARR__c, TotalQuoteSummary__c
                FROM Quote
                WHERE Id = :testSalesQuote.Id];

            System.assert(testSalesQuote.Total_One_Time__c < reselectedSalesQuote.Total_One_Time__c);
            System.assert(testSalesQuote.Total_MRR_New__c < reselectedSalesQuote.Total_MRR_New__c);
            System.assert(testSalesQuote.Total_ARR__c < reselectedSalesQuote.Total_ARR__c);
            System.assert(testSalesQuote.Total_Initial_Payment__c < reselectedSalesQuote.Total_Initial_Payment__c);
            System.assert(testSalesQuote.Total_First_Year_Cost__c < reselectedSalesQuote.Total_First_Year_Cost__c);
            System.assert(testSalesQuote.Total_One_Time_Discount__c < reselectedSalesQuote.Total_One_Time_Discount__c);
            System.assert(testSalesQuote.Total_MRR_Discount__c < reselectedSalesQuote.Total_MRR_Discount__c);
            System.assert(testSalesQuote.Total_ARR_Discount__c < reselectedSalesQuote.Total_ARR_Discount__c);
            System.assert(testSalesQuote.Total_Initial_Payment_Discount__c < reselectedSalesQuote.Total_Initial_Payment_Discount__c);
            System.assert(testSalesQuote.Total_First_Year_Discount__c < reselectedSalesQuote.Total_First_Year_Discount__c);
            System.assert(testSalesQuote.Total_One_Time_with_Taxes__c < reselectedSalesQuote.Total_One_Time_with_Taxes__c);
            System.assert(testSalesQuote.Total_MRR_with_Taxes__c < reselectedSalesQuote.Total_MRR_with_Taxes__c);
            System.assert(testSalesQuote.Total_ARR_with_Taxes__c < reselectedSalesQuote.Total_ARR_with_Taxes__c);
            System.assert(testSalesQuote.Total_Initial_Payment_with_Taxes__c < reselectedSalesQuote.Total_Initial_Payment_with_Taxes__c);
            System.assert(testSalesQuote.Total_First_Year_Cost_with_Taxes__c < reselectedSalesQuote.Total_First_Year_Cost_with_Taxes__c);
            System.assert(testSalesQuote.Contact_Center_Total_One_Time__c < reselectedSalesQuote.Contact_Center_Total_One_Time__c);
            System.assert(testSalesQuote.Contact_Center_Total_MRR__c < reselectedSalesQuote.Contact_Center_Total_MRR__c);
            System.assert(testSalesQuote.Contact_Center_Total_ARR__c < reselectedSalesQuote.Contact_Center_Total_ARR__c);
            System.assert(testSalesQuote.Contact_Center_Total_Initial_Payment__c < reselectedSalesQuote.Contact_Center_Total_Initial_Payment__c);
            System.assert(testSalesQuote.Contact_Center_Total_First_Year_Cost__c < reselectedSalesQuote.Contact_Center_Total_First_Year_Cost__c);
            System.assert(testSalesQuote.Contact_Center_Total_One_Time_Discount__c < reselectedSalesQuote.Contact_Center_Total_One_Time_Discount__c);
            System.assert(testSalesQuote.Contact_Center_Total_MRR_Discount__c < reselectedSalesQuote.Contact_Center_Total_MRR_Discount__c);
            System.assert(testSalesQuote.Contact_Center_Total_ARR_Discount__c < reselectedSalesQuote.Contact_Center_Total_ARR_Discount__c);
            System.assert(testSalesQuote.ContactCenterTotalInitialPaymentDiscount__c < reselectedSalesQuote.ContactCenterTotalInitialPaymentDiscount__c);
            System.assert(testSalesQuote.Contact_Center_Total_First_Year_Discount__c < reselectedSalesQuote.Contact_Center_Total_First_Year_Discount__c);
            System.assert(testSalesQuote.TotalQuoteSummary__c < reselectedSalesQuote.TotalQuoteSummary__c);
            System.assert(testSalesQuote.Estimated_Hardware__c < reselectedSalesQuote.Estimated_Hardware__c);
            System.assert(testSalesQuote.Delta_MRR__c < reselectedSalesQuote.Delta_MRR__c);
            System.assert(testSalesQuote.Delta_ARR__c < reselectedSalesQuote.Delta_ARR__c);
            System.assert(testSalesQuote.Delta_CC_MRR__c < reselectedSalesQuote.Delta_CC_MRR__c);
            System.assert(testSalesQuote.Delta_CC_ARR__c < reselectedSalesQuote.Delta_CC_ARR__c);

        Test.stopTest();
    }

    @isTest
    static void testPopulateQuoteTotalsOnQLIUpdate() {

        Quote testSalesQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2Id =: testSalesQuote.Pricebook2Id];

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();

        // create QuoteLineItems
        for(PricebookEntry pbe : pbeList) {
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

        Test.startTest();

        insert qliList;

        Quote reselectedQuoteAfterInsert = [SELECT Id, Pricebook2Id, Total_One_Time__c,
                Total_MRR_New__c, Total_ARR__c, Total_Initial_Payment__c, Total_First_Year_Cost__c,
                Total_One_Time_Discount__c, Total_MRR_Discount__c, Total_ARR_Discount__c,
                Total_Initial_Payment_Discount__c, Total_First_Year_Discount__c,
                Total_One_Time_with_Taxes__c, Total_MRR_with_Taxes__c, Total_ARR_with_Taxes__c,
                Total_Initial_Payment_with_Taxes__c, Total_First_Year_Cost_with_Taxes__c,
                Contact_Center_Total_One_Time__c, Contact_Center_Total_MRR__c, Contact_Center_Total_ARR__c,
                Contact_Center_Total_Initial_Payment__c, Contact_Center_Total_First_Year_Cost__c,
                Contact_Center_Total_One_Time_Discount__c, Contact_Center_Total_MRR_Discount__c,
                Contact_Center_Total_ARR_Discount__c, ContactCenterTotalInitialPaymentDiscount__c,
                Contact_Center_Total_First_Year_Discount__c, Estimated_Hardware__c, Delta_MRR__c,
                Delta_ARR__c, Delta_CC_MRR__c, Delta_CC_ARR__c, TotalQuoteSummary__c
            FROM Quote LIMIT 1];


            // change discount and update QuoteLineItems to recalculate total values
            for(QuoteLineItem qli : qliList) {
                qli.Discount_number__c += 1;
            }

            update qliList;

            Quote reselectedQuoteAfterUpdate = [SELECT Id, Pricebook2Id, Total_One_Time__c,
                    Total_MRR_New__c, Total_ARR__c, Total_Initial_Payment__c, Total_First_Year_Cost__c,
                    Total_One_Time_Discount__c, Total_MRR_Discount__c, Total_ARR_Discount__c,
                    Total_Initial_Payment_Discount__c, Total_First_Year_Discount__c,
                    Total_One_Time_with_Taxes__c, Total_MRR_with_Taxes__c, Total_ARR_with_Taxes__c,
                    Total_Initial_Payment_with_Taxes__c, Total_First_Year_Cost_with_Taxes__c,
                    Contact_Center_Total_One_Time__c, Contact_Center_Total_MRR__c, Contact_Center_Total_ARR__c,
                    Contact_Center_Total_Initial_Payment__c, Contact_Center_Total_First_Year_Cost__c,
                    Contact_Center_Total_One_Time_Discount__c, Contact_Center_Total_MRR_Discount__c,
                    Contact_Center_Total_ARR_Discount__c, ContactCenterTotalInitialPaymentDiscount__c,
                    Contact_Center_Total_First_Year_Discount__c, Estimated_Hardware__c, Delta_MRR__c,
                    Delta_ARR__c, Delta_CC_MRR__c, Delta_CC_ARR__c, TotalQuoteSummary__c
                FROM Quote
                WHERE Id = :testSalesQuote.Id];

            // verify that quote total values has nonzero values and differs with quote totals after insert
            System.assert(reselectedQuoteAfterUpdate.Total_One_Time__c > 0 && reselectedQuoteAfterInsert.Total_One_Time__c != reselectedQuoteAfterUpdate.Total_One_Time__c);
            System.assert(reselectedQuoteAfterUpdate.Total_MRR_New__c > 0 && reselectedQuoteAfterInsert.Total_MRR_New__c != reselectedQuoteAfterUpdate.Total_MRR_New__c);
            System.assert(reselectedQuoteAfterUpdate.Total_ARR__c > 0 && reselectedQuoteAfterInsert.Total_ARR__c != reselectedQuoteAfterUpdate.Total_ARR__c);
            System.assert(reselectedQuoteAfterUpdate.Total_Initial_Payment__c > 0 && reselectedQuoteAfterInsert.Total_Initial_Payment__c != reselectedQuoteAfterUpdate.Total_Initial_Payment__c);
            System.assert(reselectedQuoteAfterUpdate.Total_First_Year_Cost__c > 0 && reselectedQuoteAfterInsert.Total_First_Year_Cost__c != reselectedQuoteAfterUpdate.Total_First_Year_Cost__c);
            System.assert(reselectedQuoteAfterUpdate.Total_One_Time_Discount__c > 0 && reselectedQuoteAfterInsert.Total_One_Time_Discount__c != reselectedQuoteAfterUpdate.Total_One_Time_Discount__c);
            System.assert(reselectedQuoteAfterUpdate.Total_MRR_Discount__c > 0 && reselectedQuoteAfterInsert.Total_MRR_Discount__c != reselectedQuoteAfterUpdate.Total_MRR_Discount__c);
            System.assert(reselectedQuoteAfterUpdate.Total_ARR_Discount__c > 0 && reselectedQuoteAfterInsert.Total_ARR_Discount__c != reselectedQuoteAfterUpdate.Total_ARR_Discount__c);
            System.assert(reselectedQuoteAfterUpdate.Total_Initial_Payment_Discount__c > 0 && reselectedQuoteAfterInsert.Total_Initial_Payment_Discount__c != reselectedQuoteAfterUpdate.Total_Initial_Payment_Discount__c);
            System.assert(reselectedQuoteAfterUpdate.Total_First_Year_Discount__c > 0 && reselectedQuoteAfterInsert.Total_First_Year_Discount__c != reselectedQuoteAfterUpdate.Total_First_Year_Discount__c);
            System.assert(reselectedQuoteAfterUpdate.Total_One_Time_with_Taxes__c > 0 && reselectedQuoteAfterInsert.Total_One_Time_with_Taxes__c != reselectedQuoteAfterUpdate.Total_One_Time_with_Taxes__c);
            System.assert(reselectedQuoteAfterUpdate.Total_MRR_with_Taxes__c > 0 && reselectedQuoteAfterInsert.Total_MRR_with_Taxes__c != reselectedQuoteAfterUpdate.Total_MRR_with_Taxes__c);
            System.assert(reselectedQuoteAfterUpdate.Total_ARR_with_Taxes__c > 0 && reselectedQuoteAfterInsert.Total_ARR_with_Taxes__c != reselectedQuoteAfterUpdate.Total_ARR_with_Taxes__c);
            System.assert(reselectedQuoteAfterUpdate.Total_Initial_Payment_with_Taxes__c > 0 && reselectedQuoteAfterInsert.Total_Initial_Payment_with_Taxes__c != reselectedQuoteAfterUpdate.Total_Initial_Payment_with_Taxes__c);
            System.assert(reselectedQuoteAfterUpdate.Total_First_Year_Cost_with_Taxes__c > 0 && reselectedQuoteAfterInsert.Total_First_Year_Cost_with_Taxes__c != reselectedQuoteAfterUpdate.Total_First_Year_Cost_with_Taxes__c);
            System.assert(reselectedQuoteAfterUpdate.Contact_Center_Total_One_Time__c > 0 && reselectedQuoteAfterInsert.Contact_Center_Total_One_Time__c != reselectedQuoteAfterUpdate.Contact_Center_Total_One_Time__c);
            System.assert(reselectedQuoteAfterUpdate.Contact_Center_Total_MRR__c > 0 && reselectedQuoteAfterInsert.Contact_Center_Total_MRR__c != reselectedQuoteAfterUpdate.Contact_Center_Total_MRR__c);
            System.assert(reselectedQuoteAfterUpdate.Contact_Center_Total_ARR__c > 0 && reselectedQuoteAfterInsert.Contact_Center_Total_ARR__c != reselectedQuoteAfterUpdate.Contact_Center_Total_ARR__c);
            System.assert(reselectedQuoteAfterUpdate.Contact_Center_Total_Initial_Payment__c > 0 && reselectedQuoteAfterInsert.Contact_Center_Total_Initial_Payment__c != reselectedQuoteAfterUpdate.Contact_Center_Total_Initial_Payment__c);
            System.assert(reselectedQuoteAfterUpdate.Contact_Center_Total_First_Year_Cost__c > 0 && reselectedQuoteAfterInsert.Contact_Center_Total_First_Year_Cost__c != reselectedQuoteAfterUpdate.Contact_Center_Total_First_Year_Cost__c);
            System.assert(reselectedQuoteAfterUpdate.Contact_Center_Total_One_Time_Discount__c > 0 && reselectedQuoteAfterInsert.Contact_Center_Total_One_Time_Discount__c != reselectedQuoteAfterUpdate.Contact_Center_Total_One_Time_Discount__c);
            System.assert(reselectedQuoteAfterUpdate.Contact_Center_Total_MRR_Discount__c > 0 && reselectedQuoteAfterInsert.Contact_Center_Total_MRR_Discount__c != reselectedQuoteAfterUpdate.Contact_Center_Total_MRR_Discount__c);
            System.assert(reselectedQuoteAfterUpdate.Contact_Center_Total_ARR_Discount__c > 0 && reselectedQuoteAfterInsert.Contact_Center_Total_ARR_Discount__c != reselectedQuoteAfterUpdate.Contact_Center_Total_ARR_Discount__c);
            System.assert(reselectedQuoteAfterUpdate.ContactCenterTotalInitialPaymentDiscount__c > 0 && reselectedQuoteAfterInsert.ContactCenterTotalInitialPaymentDiscount__c != reselectedQuoteAfterUpdate.ContactCenterTotalInitialPaymentDiscount__c);
            System.assert(reselectedQuoteAfterUpdate.Contact_Center_Total_First_Year_Discount__c > 0 && reselectedQuoteAfterInsert.Contact_Center_Total_First_Year_Discount__c != reselectedQuoteAfterUpdate.Contact_Center_Total_First_Year_Discount__c);
            System.assert(reselectedQuoteAfterUpdate.TotalQuoteSummary__c > 0 && reselectedQuoteAfterInsert.TotalQuoteSummary__c != reselectedQuoteAfterUpdate.TotalQuoteSummary__c);
            System.assert(reselectedQuoteAfterUpdate.Estimated_Hardware__c > 0 && reselectedQuoteAfterInsert.Estimated_Hardware__c != reselectedQuoteAfterUpdate.Estimated_Hardware__c);
            System.assert(reselectedQuoteAfterUpdate.Delta_MRR__c > 0 && reselectedQuoteAfterInsert.Delta_MRR__c != reselectedQuoteAfterUpdate.Delta_MRR__c);
            System.assert(reselectedQuoteAfterUpdate.Delta_ARR__c > 0 && reselectedQuoteAfterInsert.Delta_ARR__c != reselectedQuoteAfterUpdate.Delta_ARR__c);
            System.assert(reselectedQuoteAfterUpdate.Delta_CC_MRR__c > 0 && reselectedQuoteAfterInsert.Delta_CC_MRR__c != reselectedQuoteAfterUpdate.Delta_CC_MRR__c);
            System.assert(reselectedQuoteAfterUpdate.Delta_CC_ARR__c > 0 && reselectedQuoteAfterInsert.Delta_CC_ARR__c != reselectedQuoteAfterUpdate.Delta_CC_ARR__c);

        Test.stopTest();
    }

    @isTest
    static void testEntitlementTotalsNewCustomer() {

        // entitlement totals for quotes should be empty(0) in 2 cases:
        // if it is quote with Upsell_Status__c = New
        // or if it is quote with RecordType Proserv/CCProserv

        Account testAccnt = new Account(
            Name = 'test account'
        );
        insert testAccnt;

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
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Office',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert testOpp;

        Quote testSalesQuote = new Quote (
            Name = 'testSalesQuote',
            Upsell_Status__c = QuoteHelper.STATUS_NEW_CUSTOMER,
            Auto_Renewal__c = true,
            OpportunityId = testOpp.Id,
            Pricebook2Id = testPriceBook.Id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            CurrencyIsoCode = 'USD'
        );

        Quote testBillingQuote = new Quote (
            Name = 'testBillingQuote',
            Upsell_Status__c = QuoteHelper.STATUS_NEW_CUSTOMER,
            Auto_Renewal__c = true,
            OpportunityId = testOpp.Id,
            Pricebook2Id = testPriceBook.Id,
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            CurrencyIsoCode = 'USD'
        );

        Quote testProServQuote = new Quote (
            Name = 'testProServQuote',
            Auto_Renewal__c = true,
            OpportunityId = testOpp.Id,
            Pricebook2Id = testPriceBook.Id,
            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
            CurrencyIsoCode = 'USD'
        );

        Test.startTest();

        insert new List<Quote>{
            testSalesQuote,
            testProServQuote,
            testBillingQuote
        };

            List<Quote> reselectedQuotesList = [SELECT Id, Upsell_Status__c, Entitlement_Total_ARR__c,
                    Entitlement_Total_MRR__c, Contact_Center_Entitlement_Total_ARR__c,
                    Contact_Center_Entitlement_Total_MRR__c
                FROM Quote Where Id IN :new Set<Id>{testSalesQuote.Id, testProServQuote.Id, testBillingQuote.Id}];

            for(Quote reselectedQuote : reselectedQuotesList) {
                System.assertEquals(reselectedQuote.Entitlement_Total_ARR__c, 0);
                System.assertEquals(reselectedQuote.Entitlement_Total_MRR__c, 0);
                System.assertEquals(reselectedQuote.Contact_Center_Entitlement_Total_ARR__c, 0);
                System.assertEquals(reselectedQuote.Contact_Center_Entitlement_Total_MRR__c, 0);
            }
        Test.stopTest();
    }

    @isTest
    static void testX12MonthBookingEnterprise() {
        // if opp.Owner.Division = 'Sales - Enterprise' - calculation X12_Month_Booking__c should be bypassed

        Emails__c email = new Emails__c(
            Name = 'rcsfsyncuser',
            Email_Address__c = 'fakeemail@emailvendor.com'
        );
        insert email;

        Opportunity opp = [SELECT Id, X12_Month_Booking__c, OwnerId, Owner.Division FROM Opportunity LIMIT 1];

        // create and set owner for opportunity
        User oppOwner = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestoppOwner',
                    User.Username => 'oppOwner!user@gmail.com',
                    User.Email => 'oppOwner_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();

        opp.OwnerId = oppOwner.Id;
        update opp;

        Quote testQuote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry];

        List<QuoteLineItem> qlisToInsert = new List<QuoteLineItem>();

        for(PricebookEntry pbe : pbeList) {
            if(pbe.Pricebook2Id == testQuote.Pricebook2Id) {
                qlisToInsert.add(
                    new QuoteLineItem(
                        Product2Id = pbe.Product2Id,
                        PricebookEntryId = pbe.Id,
                        QuoteId = testQuote.Id,
                        Quantity = 6,
                        Zero_Quantity__c = false,
                        UnitPrice = pbe.UnitPrice,
                        Discount_number__c = 2
                    )
                );
            }
        }

        Test.startTest();

            insert qlisToInsert;

            Opportunity reselectedOpp = [SELECT Id, X12_Month_Booking__c FROM Opportunity WHERE Id = :opp.Id];

            System.assertEquals(opp.X12_Month_Booking__c, reselectedOpp.X12_Month_Booking__c);

        Test.stopTest();
    }

    @isTest
    static void testComputeTotalQuoteSummary() {
        QuoteTotals totalsPopulator = new QuoteTotals();

        Decimal result = totalsPopulator.computeTotalQuoteSummary(null);
        System.assertEquals(0, result);

        result = totalsPopulator.computeTotalQuoteSummary(new List<QuoteLineItem>());
        System.assertEquals(0, result);

        Quote testSalesQuote = (Quote) new QuoteSelector()
            .selectQuoteByName('testSalesQuote')
            .executeQuery()
            .get(0);

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new PricebookEntrySelector()
            .getAllPBEs()
            .selectFields(new Set<String>{
                'Id',
                'Pricebook2Id',
                'Product2Id',
                'Product2.Charge_Term__c',
                'Product2.Family',
                'UnitPrice'
            })
            .executeQuery();

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        result = totalsPopulator.computeTotalQuoteSummary(qliList);

        Decimal calculatedTotalQuoteSummary = 0;
        for (QuoteLineItem qli : qliList) {
            if (
                qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME
                && qli.Product2.Family != Product2Helper.FAMILY_TAXES
            ) {
                calculatedTotalQuoteSummary += (QuoteLineItemHelper.getQuantity(qli) * qli.EffectivePriceNew__c);
            }
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalQuoteSummary, result);
    }

    @isTest
    static void testComputeProServListPrice() {
        QuoteTotals testQuoteTotals = new QuoteTotals();
        Quote testSalesQuote = (Quote) new QuoteSelector()
            .selectQuoteByName('testSalesQuote')
            .selectFields(new List<String>{'Opportunity.Parent_Order__c', 'Opportunity.Tier_Name__c'})
            .executeQuery()
            .get(0);

        testQuoteTotals.quoteIdToQuoteMap = new Map<Id, Quote> {testSalesQuote.Id => testSalesQuote};

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new PricebookEntrySelector()
            .getAllPBEs()
            .selectFields(new Set<String>{
                'Id',
                'Pricebook2Id',
                'Product2Id',
                'Product2.Charge_Term__c',
                'Product2.Family',
                'UnitPrice'
            })
            .executeQuery();

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);
        Decimal expectedResult = 0;
        for (QuoteLineItem qli: qliList) {
            qli.ServiceName__c = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
            qli.NewQuantity__c = 5;
            if (!Product2Helper.isTaxes(qli.Product2)) {
                expectedResult += qli.NewQuantity__c * qli.UnitPrice;
            }
        }

        Test.startTest();
            Decimal result = testQuoteTotals.computeProServListPrice(qliList, testSalesQuote.Id);
            Decimal nullResult = testQuoteTotals.computeProServListPrice(new List<QuoteLineItem>(), testSalesQuote.Id);
        Test.stopTest();

        Assert.areEqual(expectedResult, result, 'proServListPrice calculation is incorrect');
        Assert.areEqual(0, nullResult, 'proServListPrice should be 0');
    }

    @isTest
    static void testComputeProServDiscount() {
        QuoteTotals testQuoteTotals = new QuoteTotals();
        Quote testSalesQuote = (Quote) new QuoteSelector()
            .selectQuoteByName('testSalesQuote')
            .selectFields(new List<String>{'Opportunity.Parent_Order__c', 'Opportunity.Tier_Name__c'})
            .executeQuery()
            .get(0);

        testQuoteTotals.quoteIdToQuoteMap = new Map<Id, Quote> {testSalesQuote.Id => testSalesQuote};

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new PricebookEntrySelector()
            .getAllPBEs()
            .selectFields(new Set<String>{
                'Id',
                'Pricebook2Id',
                'Product2Id',
                'Product2.Charge_Term__c',
                'Product2.Family',
                'UnitPrice'
            })
            .executeQuery();

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);
        Decimal expectedResult = 0;
        for (QuoteLineItem qli: qliList) {
            qli.ServiceName__c = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
            qli.NewQuantity__c = 5;
            qli.Discount = 2;
            if (!Product2Helper.isTaxes(qli.Product2)) {
                expectedResult += qli.NewQuantity__c * (qli.UnitPrice * 0.02);
            }
        }
        Triggers.switchOff();
        insert qliList;
        Triggers.switchOn();

        Test.startTest();
            List<QuoteLineItem> reselectedQlis = new QuoteLineItemSelector()
                .selectQuoteLineItemsForQLITrigger(new Set<Id>{testSalesQuote.Id})
                .executeQuery();
            Decimal result = testQuoteTotals.computeProServDiscount(reselectedQlis, testSalesQuote.Id);
            Decimal nullResult = testQuoteTotals.computeProServDiscount(new List<QuoteLineItem>(), testSalesQuote.Id);
        Test.stopTest();

        Assert.areEqual(expectedResult, result, 'proServDiscount calculation is incorrect');
        Assert.areEqual(0, nullResult, 'proServDiscount should be 0');
    }

    @isTest
    static void testComputeTotalInitialPaymentProServ() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test_Product',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES,
                Product2.Group__c => '[800] Professional Services'
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.EffectivePriceNew__c => 30
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            QuoteTotals totalsPopulator = new QuoteTotals();
            List<QuoteLineItem> reselectedQlis = new QuoteLineItemSelector()
                .selectQuoteLineItemsForQLITrigger(new Set<Id>{qt.Id})
                .executeQuery();
            Decimal totalInitialPaymentWithoutProServ = totalsPopulator.computeTotalInitialPayment(reselectedQlis, false, true);
            Decimal totalInitialPaymentWithProServ = totalsPopulator.computeTotalInitialPayment(reselectedQlis, false, false);
        Test.stopTest();

        Assert.areEqual(0, totalInitialPaymentWithoutProServ, 'Total Initial Payment should be calculated correctly without ProServ Items');
        Assert.areEqual(qli.NewQuantity__c * qli.EffectivePriceNew__c, totalInitialPaymentWithProServ, 'Total Initial Payment should be calculated correctly with ProServ Items');
    }

    @isTest
    static void testComputeCLMTotalInitialPaymentWithoutProServ() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test_Product',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES,
                Product2.Group__c => '[800] Professional Services'
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.EffectivePriceNew__c => 30
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            QuoteTotals totalsPopulator = new QuoteTotals();
            List<QuoteLineItem> reselectedQlis = new QuoteLineItemSelector()
                .selectQuoteLineItemsForQLITrigger(new Set<Id>{qt.Id})
                .executeQuery();
            Decimal clmTotalInitialPayment = totalsPopulator.computeCLMTotalInitialPayment(reselectedQlis, false);
        Test.stopTest();

        Assert.areEqual(90.0000, clmTotalInitialPayment, 'CLM Total Initial Payment should be calculated correctly without ProServ Items');
    }
}