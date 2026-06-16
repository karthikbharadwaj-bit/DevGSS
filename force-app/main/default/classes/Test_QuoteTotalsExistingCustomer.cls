@isTest
private class Test_QuoteTotalsExistingCustomer {

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
            Name = 'test account',
            RC_User_ID__c = '665588994477222114'
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
            Upsell_Status__c = QuoteHelper.STATUS_UPSELL,
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

        List<Entitlement__c> entlsToInsert = new List<Entitlement__c>();

        for(PricebookEntry pbe : pbeList) {
            if(pbe.Pricebook2Id == testSalesQuote.Pricebook2Id) {
                entlsToInsert.add(
                    new Entitlement__c(
                        Account__c = testAccnt.Id,
                        Active__c = true,
                        Product__c = pbe.Product2Id,
                        Quantity__c = 5,
                        Discount__c = 2,
                        Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                        Price__c = pbe.UnitPrice
                    )
                );
            }
        }
        insert entlsToInsert;
    }

    @isTest
    static void testPopulateQuoteTotalsOnQLIInsert() {

        Quote testSalesQuote = [SELECT Id, AccountId, Pricebook2Id, Total_One_Time__c,
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
                Delta_ARR__c, Delta_CC_MRR__c, Delta_CC_ARR__c
            FROM Quote LIMIT 1];

        // quote totals without quoteLineItems should be 0
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
        System.assertEquals(0, testSalesQuote.Estimated_Hardware__c);
        System.assertEquals(0, testSalesQuote.Delta_MRR__c);
        System.assertEquals(0, testSalesQuote.Delta_ARR__c);
        System.assertEquals(0, testSalesQuote.Delta_CC_MRR__c);
        System.assertEquals(0, testSalesQuote.Delta_CC_ARR__c);

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c, EffectivePricePrecise__c, Price__c, Product__c, Product__r.Charge_Term__c FROM Entitlement__c WHERE Account__c = :testSalesQuote.AccountId];

        Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
        for(Entitlement__c entl : entlsList) {
            productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
        }

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        for(QuoteLineItem qli : qliList) {
            Id entlId = productIdToEntitlementIdMap.get(qli.Product2Id);
            qli.Entitlement__c = entlId;
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
                    Delta_ARR__c, Delta_CC_MRR__c, Delta_CC_ARR__c
                FROM Quote
                WHERE Id = :testSalesQuote.Id];

            // verify that Quote totals field values recomputes(differs with initial quoteTotal values) after inserting quoteLineItems
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
            System.assert(testSalesQuote.Estimated_Hardware__c < reselectedSalesQuote.Estimated_Hardware__c);
            System.assert(testSalesQuote.Delta_MRR__c < reselectedSalesQuote.Delta_MRR__c);
            System.assert(testSalesQuote.Delta_ARR__c < reselectedSalesQuote.Delta_ARR__c);
            System.assert(testSalesQuote.Delta_CC_MRR__c < reselectedSalesQuote.Delta_CC_MRR__c);
            System.assert(testSalesQuote.Delta_CC_ARR__c < reselectedSalesQuote.Delta_CC_ARR__c);

        Test.stopTest();
    }

    @isTest
    static void testComputeTotalMrrMethod() {
        Test.startTest();
            Quote testSalesQuote = [SELECT Id, AccountId, Pricebook2Id FROM Quote LIMIT 1];

            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                    Product2.Charge_Term__c, Product2.Family, UnitPrice
                FROM PricebookEntry];

            List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c, EffectivePricePrecise__c, Price__c, Product__c, Product__r.Charge_Term__c FROM Entitlement__c WHERE Account__c = :testSalesQuote.AccountId];

            Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
            for(Entitlement__c entl : entlsList) {
                productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
            }

            List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

            // assign entitlements to quotelineitems
            for(QuoteLineItem qli : qliList) {
                Id entlId = productIdToEntitlementIdMap.get(qli.Product2Id);
                qli.Entitlement__c = entlId;
            }

            insert qliList;

            Quote reselectedSalesQuote = [SELECT Id, AccountId, Pricebook2Id, Entitlement_Total_MRR__c FROM Quote LIMIT 1];
            List<QuoteLineItem> reselectedQliList = [SELECT Id, QuoteId, DiscountValueNew__c,
                    Quantity, NewQuantity__c, Product2.Family, Product2.Sub_Category__c,
                    Product2.Charge_Term__c, EffectivePriceNew__c, QuoteRecordType__c,
                    Zero_Quantity__c, Entitlement__r.DisplayQuantity__c,
                    Entitlement__r.EffectivePrice__c, Entitlement__r.EffectivePricePrecise__c, Entitlement__r.Product__r.Charge_Term__c,
                    Entitlement__r.Price__c, Quote.Entitlement_Total_MRR__c, Quote.Total_MRR_New__c
                FROM QuoteLineItem
                WHERE QuoteId = :testSalesQuote.Id];
        Test.stopTest();

        QuoteTotals totalsPopulator = new QuoteTotals();
        Decimal result = totalsPopulator.computeTotalMRR(reselectedQliList);
        System.assertNotEquals(null, result);
        // calculate totalMrr manually and compare with method result
        Decimal calculatedTotalMrr = 0;
        for(QuoteLineItem qli : reselectedQliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                calculatedTotalMrr += ((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) / 12;
            }else{
                calculatedTotalMrr += ((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c);
            }
        }
        calculatedTotalMrr -= reselectedSalesQuote.Entitlement_Total_MRR__c == null ? 0 : reselectedSalesQuote.Entitlement_Total_MRR__c;
        System.assertEquals(result, calculatedTotalMrr);


    }

    @isTest
    static void testComputeTotalArrMethod() {
		Test.startTest();
            Quote testSalesQuote = [SELECT Id, AccountId, Pricebook2Id FROM Quote LIMIT 1];

            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                    Product2.Charge_Term__c, Product2.Family, UnitPrice
                FROM PricebookEntry];

            List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c, EffectivePricePrecise__c, Price__c, Product__c, Product__r.Charge_Term__c FROM Entitlement__c WHERE Account__c = :testSalesQuote.AccountId];

            Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
            for(Entitlement__c entl : entlsList) {
                productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
            }

            List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

            // assign entitlements to quotelineitems
            for(QuoteLineItem qli : qliList) {
                Id entlId = productIdToEntitlementIdMap.get(qli.Product2Id);
                qli.Entitlement__c = entlId;
            }

            insert qliList;

            Quote reselectedSalesQuote = [SELECT Id, AccountId, Pricebook2Id, Entitlement_Total_ARR__c FROM Quote LIMIT 1];
            List<QuoteLineItem> reselectedQliList = [SELECT Id, QuoteId, DiscountValueNew__c,
                    Quantity, NewQuantity__c, Product2.Family, Product2.Sub_Category__c,
                    Product2.Charge_Term__c, EffectivePriceNew__c, QuoteRecordType__c,
                    Zero_Quantity__c, Entitlement__r.DisplayQuantity__c,
                    Entitlement__r.EffectivePrice__c, Entitlement__r.EffectivePricePrecise__c, Entitlement__r.Product__r.Charge_Term__c,
                    Entitlement__r.Price__c, Quote.Entitlement_Total_ARR__c, Quote.Total_ARR__c
                FROM QuoteLineItem
                WHERE QuoteId = :testSalesQuote.Id];
        Test.stopTest();

        QuoteTotals totalsPopulator = new QuoteTotals();
        Decimal result = totalsPopulator.computeTotalARR(reselectedQliList);
        System.assertNotEquals(null, result);
        // calculate totalMrr manually and compare with method result
        Decimal calculatedTotalArr = 0;
        for(QuoteLineItem qli : reselectedQliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY || qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                calculatedTotalArr += ((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) * 12;
            }else{
                calculatedTotalArr += ((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c);
            }
        }
        calculatedTotalArr -= reselectedSalesQuote.Entitlement_Total_ARR__c == null ? 0 : reselectedSalesQuote.Entitlement_Total_ARR__c;
        System.assertEquals(result, calculatedTotalArr);


    }

    @isTest
    static void testComputeTotalInitialPaymentMethod() {
        Test.startTest();
            Quote testSalesQuote = [SELECT Id, AccountId, Pricebook2Id FROM Quote LIMIT 1];

            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                    Product2.Charge_Term__c, Product2.Family, UnitPrice
                FROM PricebookEntry];

            List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c, EffectivePricePrecise__c, Price__c, Product__c, Product__r.Charge_Term__c FROM Entitlement__c WHERE Account__c = :testSalesQuote.AccountId];

            Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
            for(Entitlement__c entl : entlsList) {
                productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
            }

            List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

            // assign entitlements to quotelineitems
            for(QuoteLineItem qli : qliList) {
                Id entlId = productIdToEntitlementIdMap.get(qli.Product2Id);
                qli.Entitlement__c = entlId;
            }
            PricebookEntry pricebookEntryForProServQLI;
            for(PricebookEntry pbe : pbeList) {
                if(pbe.Pricebook2Id == testSalesQuote.Pricebook2Id) { 
                    pricebookEntryForProServQLI = pbe;
                }
            }
            QuoteLineItem testQuoteLineItemProServ = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.QuoteId => testSalesQuote.Id,
                        QuoteLineItem.ServiceName__c => QuoteLineItemHelper.SUBCATEGORY_PROSERV,
                        QuoteLineItem.UnitPrice => 200,
                        QuoteLineItem.DiscountValueNew__c => 0,
                        QuoteLineItem.Discount => 0,
                        QuoteLineItem.EffectivePriceNew__c => 200,
                        QuoteLineItem.Quantity => 5,
                        QuoteLineItem.Product2Id => pricebookEntryForProServQLI.Product2Id,
                        QuoteLineItem.PricebookEntryId => pricebookEntryForProServQLI.Id
                    }
                )
                .build()
                .getRecord();
        
            qliList.add(testQuoteLineItemProServ);

            insert qliList;

            List<QuoteLineItem> reselectedQliList = [SELECT Id, QuoteId, DiscountValueNew__c,
                    Quantity, NewQuantity__c, Product2.Family, Product2.Sub_Category__c,
                    Product2.Charge_Term__c, EffectivePriceNew__c, QuoteRecordType__c, ServiceName__c,
                    PackageInfo__c, Zero_Quantity__c, Entitlement__r.DisplayQuantity__c, Package_Info_QLI__c,
                    Entitlement__r.EffectivePrice__c, Entitlement__r.EffectivePricePrecise__c, Entitlement__r.Product__r.Charge_Term__c,
                    Entitlement__r.Price__c, Quote.Entitlement_Total_ARR__c, Quote.Total_Initial_Payment__c
                FROM QuoteLineItem
                WHERE QuoteId = :testSalesQuote.Id];
        Test.stopTest();

        QuoteTotals totalsPopulator = new QuoteTotals();
        Decimal result = totalsPopulator.computeTotalInitialPayment(reselectedQliList, false);
        Decimal resultWithoutProServ = totalsPopulator.computeTotalInitialPayment(reselectedQliList, true);
        Assert.areNotEqual(null, result,  'result should not be null');
        Assert.areNotEqual(null, resultWithoutProServ, 'resultWithoutProServ should not be null');
        
        // calculate Total Initial Payment manually and compare with method result
        Decimal calculatedTotalInitialPayment = 0;
        Decimal calculatedTotalInitialPaymentWithoutProServ = 0;
        
        for(QuoteLineItem qli : reselectedQliList) {
            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);
            Boolean isProServ = qli.ServiceName__c == Product2Helper.SUBCATEGORY_PROSERV || (QuoteLineItemHelper.isOfficeQli(qli) && Product2Helper.isProfessionalServiceProduct(qli.Product2));
            Boolean isEvents = QuoteLineItemHelper.isEventsQli(qli);
            
            // Skip taxes, ProServ (when isCalculateWithoutProServ = true), and Events
            if (isTaxes || isEvents) {
                continue;
            }
            
            // Skip ProServ only when calculating without ProServ
            if (isProServ) {
                calculatedTotalInitialPayment += (QuoteLineItemHelper.getQuantity(qli) * qli.EffectivePriceNew__c);
                continue; // Skip adding to resultWithoutProServ
            }
            
            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
            Decimal quantity = QuoteLineItemHelper.getQuantity(qli);
            Decimal qliEffectivePriceNewValue = qli.EffectivePriceNew__c == null ? 0 : qli.EffectivePriceNew__c;
            
            if (qli.Entitlement__c == null || qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                Decimal amount = (quantity * qliEffectivePriceNewValue);
                calculatedTotalInitialPayment += amount;
                calculatedTotalInitialPaymentWithoutProServ += amount;
            } else {
                String entlChargeTerm = (String) QuoteTotals.getRelatedData(qli.QuoteRecordType__c, qli, Product2.Charge_Term__c);
                Decimal entlDisplayQuantity = (Decimal) QuoteTotals.getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);
                Decimal entlEffectivePrice = NumberHelper.toNumber(qli.Entitlement__r.EffectivePricePrecise__c);
                
                Decimal amount = 0;
                if((qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) ||
                   (QuoteTotals.monthlyOrMonthlyContractSet.contains(qliChargeTerm) && QuoteTotals.monthlyOrMonthlyContractSet.contains(entlChargeTerm))) {
                       amount = ((quantity + entlDisplayQuantity) * qliEffectivePriceNewValue) - (entlDisplayQuantity * entlEffectivePrice);
                   }else if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && QuoteTotals.monthlyOrMonthlyContractSet.contains(entlChargeTerm)) {
                       amount = ((quantity + entlDisplayQuantity) * qliEffectivePriceNewValue) - ((entlDisplayQuantity * entlEffectivePrice) * 12);
                   }else if(QuoteTotals.monthlyOrMonthlyContractSet.contains(qliChargeTerm) && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                       amount = ((quantity + entlDisplayQuantity) * qliEffectivePriceNewValue) - ((entlDisplayQuantity * entlEffectivePrice) / 12);
                   }
                
                calculatedTotalInitialPayment += amount;
                calculatedTotalInitialPaymentWithoutProServ += amount;
            }
        }
        
        Assert.areEqual(calculatedTotalInitialPayment, result, 'Total Initial payment should be calculated correctly and include ProServ items');
        Assert.areEqual(calculatedTotalInitialPaymentWithoutProServ, resultWithoutProServ, 'Total Initial payment should be calculated correctly and exclude ProServ items');
    }

    @isTest
    static void testComputeTotalInitialPaymentDiscountMethod() {
		Test.startTest();
        Quote testSalesQuote = [SELECT Id, AccountId, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c, EffectivePricePrecise__c, Price__c, Product__c, Product__r.Charge_Term__c FROM Entitlement__c WHERE Account__c = :testSalesQuote.AccountId];

        Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
        for(Entitlement__c entl : entlsList) {
            productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
        }

        List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

        // assign entitlements to quotelineitems
        for(QuoteLineItem qli : qliList) {
            Id entlId = productIdToEntitlementIdMap.get(qli.Product2Id);
            qli.Entitlement__c = entlId;
        }

        insert qliList;

        Quote reselectedSalesQuote = [SELECT Id, AccountId, Pricebook2Id, Entitlement_Total_ARR__c, Total_One_Time_Discount__c FROM Quote LIMIT 1];
        List<QuoteLineItem> reselectedQliList = [SELECT Id, QuoteId, DiscountValueNew__c,
                Quantity, NewQuantity__c, Product2.Family, Product2.Sub_Category__c,
                Product2.Charge_Term__c, EffectivePriceNew__c, QuoteRecordType__c,
                Zero_Quantity__c, Entitlement__r.DisplayQuantity__c,
                Entitlement__r.EffectivePrice__c, Entitlement__r.EffectivePricePrecise__c, Entitlement__r.Product__r.Charge_Term__c,
                Entitlement__r.Price__c, Quote.Entitlement_Total_ARR__c, Quote.Total_ARR__c
            FROM QuoteLineItem
            WHERE QuoteId = :testSalesQuote.Id];
        QuoteTotals totalsPopulator = new QuoteTotals();
        Decimal result = totalsPopulator.computeTotalInitialPaymentDiscount(reselectedQliList, reselectedSalesQuote.Total_One_Time_Discount__c);
        System.assertNotEquals(null, result);
        // calculate totalTotalInitialPaymentDiscount manually and compare with method result
        Decimal calculatedTotalInitialPaymentDiscount = 0;
        for(QuoteLineItem qli : reselectedQliList) {
            String qliChargeTerm = qli.Product2.Charge_Term__c;
            String entlChargeTerm = qli.Entitlement__r.Product__r.Charge_Term__c;
            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }
            if((qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) ||
                QuoteTotals.monthlyOrMonthlyContractSet.contains(qliChargeTerm) && QuoteTotals.monthlyOrMonthlyContractSet.contains(entlChargeTerm)) {
                calculatedTotalInitialPaymentDiscount += ((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.DiscountValueNew__c) - ((qli.Entitlement__r.Price__c - qli.Entitlement__r.EffectivePrice__c) * qli.Entitlement__r.DisplayQuantity__c);
            }else if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && QuoteTotals.monthlyOrMonthlyContractSet.contains(entlChargeTerm)) {
                calculatedTotalInitialPaymentDiscount += ((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.DiscountValueNew__c) - (((qli.Entitlement__r.Price__c - qli.Entitlement__r.EffectivePrice__c) * qli.Entitlement__r.DisplayQuantity__c) * 12);
            }else if(QuoteTotals.monthlyOrMonthlyContractSet.contains(qliChargeTerm) && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                calculatedTotalInitialPaymentDiscount += ((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.DiscountValueNew__c) - (((qli.Entitlement__r.Price__c - qli.Entitlement__r.EffectivePrice__c) * qli.Entitlement__r.DisplayQuantity__c) / 12);
            }
        }
        calculatedTotalInitialPaymentDiscount += reselectedSalesQuote.Total_One_Time_Discount__c;
        System.assertEquals(result, calculatedTotalInitialPaymentDiscount);


    }

    @isTest
    static void testComputeTotalMrrWithTaxesMethod() {
        Test.startTest();
            Quote testSalesQuote = [SELECT Id, AccountId, Pricebook2Id FROM Quote LIMIT 1];

            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                    Product2.Charge_Term__c, Product2.Family, UnitPrice
                FROM PricebookEntry];

            List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c, EffectivePricePrecise__c, Price__c, Product__c, Product__r.Charge_Term__c FROM Entitlement__c WHERE Account__c = :testSalesQuote.AccountId];

            Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
            for(Entitlement__c entl : entlsList) {
                productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
            }

            List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

            // assign entitlements to quotelineitems
            for(QuoteLineItem qli : qliList) {
                Id entlId = productIdToEntitlementIdMap.get(qli.Product2Id);
                qli.Entitlement__c = entlId;
            }

            insert qliList;

            Quote reselectedSalesQuote = [SELECT Id, AccountId, Pricebook2Id, Total_MRR_New__c FROM Quote LIMIT 1];
            List<QuoteLineItem> reselectedQliList = [SELECT Id, QuoteId, DiscountValueNew__c,
                    Quantity, NewQuantity__c, Product2.Family, Product2.Sub_Category__c,
                    Product2.Charge_Term__c, EffectivePriceNew__c, QuoteRecordType__c,
                    Zero_Quantity__c, Entitlement__r.DisplayQuantity__c, Fixed_Taxes_Amount__c,
                    Variable_Taxes_Amount__c, Entitlement__r.EffectivePrice__c, Entitlement__r.EffectivePricePrecise__c,
                    Entitlement__r.Product__r.Charge_Term__c, Entitlement__r.Price__c,
                    Quote.Entitlement_Total_MRR__c, Quote.Total_MRR_New__c
                FROM QuoteLineItem
                WHERE QuoteId = :testSalesQuote.Id];
        Test.stopTest();

        QuoteTotals totalsPopulator = new QuoteTotals();
        Decimal result = totalsPopulator.computeTotalMRRWithTaxes(reselectedQliList, reselectedSalesQuote.Total_MRR_New__c);
        System.assertNotEquals(null, result);
        // calculate totalMrr manually and compare with method result
        Decimal calculatedTotalMrrWithTaxes = 0;
        for(QuoteLineItem qli : reselectedQliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }
            Decimal fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
            Decimal variableTaxesAmount = qli.Variable_Taxes_Amount__c == null ? 0 : qli.Variable_Taxes_Amount__c;
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                calculatedTotalMrrWithTaxes += (fixedTaxesAmount + variableTaxesAmount) / 12;
            }else{
                calculatedTotalMrrWithTaxes += (fixedTaxesAmount + variableTaxesAmount);
            }
        }
        calculatedTotalMrrWithTaxes += reselectedSalesQuote.Total_MRR_New__c;
        System.assertEquals(result, calculatedTotalMrrWithTaxes);


    }

    @isTest
    static void testComputeTotalArrWithTaxesMethod() {
		Test.startTest();
            Quote testSalesQuote = [SELECT Id, AccountId, Pricebook2Id FROM Quote LIMIT 1];

            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                    Product2.Charge_Term__c, Product2.Family, UnitPrice
                FROM PricebookEntry];

            List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c, EffectivePricePrecise__c, Price__c, Product__c, Product__r.Charge_Term__c FROM Entitlement__c WHERE Account__c = :testSalesQuote.AccountId];

            Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
            for(Entitlement__c entl : entlsList) {
                productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
            }

            List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

            // assign entitlements to quotelineitems
            for(QuoteLineItem qli : qliList) {
                Id entlId = productIdToEntitlementIdMap.get(qli.Product2Id);
                qli.Entitlement__c = entlId;
            }

            insert qliList;

            Quote reselectedSalesQuote = [SELECT Id, AccountId, Pricebook2Id, Total_ARR__c FROM Quote LIMIT 1];
            List<QuoteLineItem> reselectedQliList = [SELECT Id, QuoteId, DiscountValueNew__c,
                    Quantity, NewQuantity__c, Product2.Family, Product2.Sub_Category__c,
                    Product2.Charge_Term__c, EffectivePriceNew__c, QuoteRecordType__c,
                    Zero_Quantity__c, Entitlement__r.DisplayQuantity__c, Fixed_Taxes_Amount__c,
                    Variable_Taxes_Amount__c, Entitlement__r.EffectivePrice__c, Entitlement__r.EffectivePricePrecise__c,
                    Entitlement__r.Product__r.Charge_Term__c, Entitlement__r.Price__c,
                    Quote.Entitlement_Total_MRR__c, Quote.Total_ARR__c
                FROM QuoteLineItem
                WHERE QuoteId = :testSalesQuote.Id];
        Test.stopTest();

        QuoteTotals totalsPopulator = new QuoteTotals();
        Decimal result = totalsPopulator.computeTotalARRWithTaxes(reselectedQliList, reselectedSalesQuote.Total_ARR__c);
        System.assertNotEquals(null, result);
        // calculate totalMrr manually and compare with method result
        Decimal calculatedTotalArrWithTaxes = 0;
        for(QuoteLineItem qli : reselectedQliList) {
            if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }
            Decimal fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
            Decimal variableTaxesAmount = qli.Variable_Taxes_Amount__c == null ? 0 : qli.Variable_Taxes_Amount__c;
            if(QuoteTotals.monthlyOrMonthlyContractSet.contains(qli.Product2.Charge_Term__c)) {
                calculatedTotalArrWithTaxes += (fixedTaxesAmount + variableTaxesAmount) * 12;
            }else{
                calculatedTotalArrWithTaxes += (fixedTaxesAmount + variableTaxesAmount);
            }
        }
        calculatedTotalArrWithTaxes += reselectedSalesQuote.Total_ARR__c;
        System.assertEquals(result, calculatedTotalArrWithTaxes);


    }

    @isTest
    static void testComputeTotalInitialPaymentWithTaxesMethod() {
        Test.startTest();
            Quote testSalesQuote = [SELECT Id, AccountId, Pricebook2Id FROM Quote LIMIT 1];

            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                    Product2.Charge_Term__c, Product2.Family, UnitPrice
                FROM PricebookEntry];

            List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c, EffectivePricePrecise__c, Price__c, Product__c, Product__r.Charge_Term__c FROM Entitlement__c WHERE Account__c = :testSalesQuote.AccountId];

            Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
            for(Entitlement__c entl : entlsList) {
                productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
            }

            List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

            // assign entitlements to quotelineitems
            for(QuoteLineItem qli : qliList) {
                Id entlId = productIdToEntitlementIdMap.get(qli.Product2Id);
                qli.Entitlement__c = entlId;
            }

            insert qliList;

            Quote reselectedSalesQuote = [SELECT Id, AccountId, Pricebook2Id, Total_Initial_Payment__c FROM Quote LIMIT 1];
            List<QuoteLineItem> reselectedQliList = [SELECT Id, QuoteId, DiscountValueNew__c,
                    Quantity, NewQuantity__c, Product2.Family, Product2.Sub_Category__c,
                    Product2.Charge_Term__c, EffectivePriceNew__c, QuoteRecordType__c,
                    Zero_Quantity__c, Entitlement__r.DisplayQuantity__c, Fixed_Taxes_Amount__c,
                    Variable_Taxes_Amount__c, Entitlement__r.EffectivePrice__c, Entitlement__r.EffectivePricePrecise__c,
                    Entitlement__r.Product__r.Charge_Term__c, Entitlement__r.Price__c,
                    Quote.Entitlement_Total_MRR__c, Quote.Total_Initial_Payment__c
                FROM QuoteLineItem
                WHERE QuoteId = :testSalesQuote.Id];
        Test.stopTest();

        QuoteTotals totalsPopulator = new QuoteTotals();
        Decimal result = totalsPopulator.computeTotalInitialPaymentWithTaxes(reselectedQliList, reselectedSalesQuote.Total_Initial_Payment__c);
        System.assertNotEquals(null, result);
        // calculate totalMrr manually and compare with method result
        Decimal calculatedTotalInitialPaymentWithTaxes = 0;
        for(QuoteLineItem qli : reselectedQliList) {
            Decimal fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
            Decimal variableTaxesAmount = qli.Variable_Taxes_Amount__c == null ? 0 : qli.Variable_Taxes_Amount__c;
            calculatedTotalInitialPaymentWithTaxes += (fixedTaxesAmount + variableTaxesAmount);
        }
        calculatedTotalInitialPaymentWithTaxes += reselectedSalesQuote.Total_Initial_Payment__c;
        System.assertEquals(result, calculatedTotalInitialPaymentWithTaxes);


    }

    @isTest
    static void testComputeContactCenterTotalMrr() {
		Test.startTest();
            Quote testSalesQuote = [SELECT Id, AccountId, Pricebook2Id FROM Quote LIMIT 1];

            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                    Product2.Charge_Term__c, Product2.Family, UnitPrice
                FROM PricebookEntry];

            List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c, EffectivePricePrecise__c, Price__c, Product__c, Product__r.Charge_Term__c FROM Entitlement__c WHERE Account__c = :testSalesQuote.AccountId];

            Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
            for(Entitlement__c entl : entlsList) {
                productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
            }

            List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

            // assign entitlements to quotelineitems
            for(QuoteLineItem qli : qliList) {
                Id entlId = productIdToEntitlementIdMap.get(qli.Product2Id);
                qli.Entitlement__c = entlId;
            }

            insert qliList;

            Quote reselectedSalesQuote = [SELECT Id, AccountId, Pricebook2Id, Contact_Center_Entitlement_Total_MRR__c FROM Quote LIMIT 1];
            List<QuoteLineItem> reselectedQliList = [SELECT Id, QuoteId, DiscountValueNew__c,
                    Quantity, NewQuantity__c, Product2.Family, Product2.Sub_Category__c,
                    Product2.Charge_Term__c, EffectivePriceNew__c, QuoteRecordType__c,
                    Zero_Quantity__c, Entitlement__r.DisplayQuantity__c, Fixed_Taxes_Amount__c,
                    Variable_Taxes_Amount__c, Entitlement__r.EffectivePrice__c, Entitlement__r.EffectivePricePrecise__c,
                    Entitlement__r.Product__r.Charge_Term__c, Entitlement__r.Price__c,
                    Quote.Entitlement_Total_MRR__c, Quote.Contact_Center_Entitlement_Total_MRR__c
                FROM QuoteLineItem
                WHERE QuoteId = :testSalesQuote.Id];
        Test.stopTest();
        System.debug('Limits: ' + Limits.getQueries());

        QuoteTotals totalsPopulator = new QuoteTotals();
        Decimal result = totalsPopulator.computeContactCenterTotalMRR(reselectedQliList);
        System.assertNotEquals(null, result);
        // calculate totalMrr manually and compare with method result
        Decimal calculatedCCTotalMrr = 0;
        for(QuoteLineItem qli : reselectedQliList) {
            String qliChargeTerm = qli.Product2.Charge_Term__c;
            String entlChargeTerm = qli.Entitlement__r.Product__r.Charge_Term__c;
            if(qliChargeTerm != Product2Helper.CHARGE_TERM_ONE_TIME && qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                    calculatedCCTotalMrr += ((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) / 12;
                }else{
                    calculatedCCTotalMrr += ((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c);
                }
            }
        }
        calculatedCCTotalMrr -= reselectedSalesQuote.Contact_Center_Entitlement_Total_MRR__c;
		System.debug('Limits: ' + Limits.getQueries());
        System.assertEquals(result, calculatedCCTotalMrr);


    }

    @isTest
    static void testComputeContactCenterTotalArr() {
		Test.startTest();
            Quote testSalesQuote = [SELECT Id, AccountId, Pricebook2Id FROM Quote LIMIT 1];

            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                    Product2.Charge_Term__c, Product2.Family, UnitPrice
                FROM PricebookEntry];

            List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c, EffectivePricePrecise__c, Price__c, Product__c, Product__r.Charge_Term__c FROM Entitlement__c WHERE Account__c = :testSalesQuote.AccountId];

            Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
            for(Entitlement__c entl : entlsList) {
                productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
            }

            List<QuoteLineItem> qliList = createQuoteLineItems(testSalesQuote.Id, testSalesQuote.Pricebook2Id, pbeList);

            // assign entitlements to quotelineitems
            for(QuoteLineItem qli : qliList) {
                Id entlId = productIdToEntitlementIdMap.get(qli.Product2Id);
                qli.Entitlement__c = entlId;
            }

            insert qliList;

            Quote reselectedSalesQuote = [SELECT Id, AccountId, Pricebook2Id, Contact_Center_Entitlement_Total_ARR__c FROM Quote LIMIT 1];
            List<QuoteLineItem> reselectedQliList = [SELECT Id, QuoteId, DiscountValueNew__c,
                    Quantity, NewQuantity__c, Product2.Family, Product2.Sub_Category__c,
                    Product2.Charge_Term__c, EffectivePriceNew__c, QuoteRecordType__c,
                    Zero_Quantity__c, Entitlement__r.DisplayQuantity__c, Fixed_Taxes_Amount__c,
                    Variable_Taxes_Amount__c, Entitlement__r.EffectivePrice__c, Entitlement__r.EffectivePricePrecise__c,
                    Entitlement__r.Product__r.Charge_Term__c, Entitlement__r.Price__c,
                    Quote.Entitlement_Total_MRR__c, Quote.Contact_Center_Entitlement_Total_ARR__c
                FROM QuoteLineItem
                WHERE QuoteId = :testSalesQuote.Id];

        Test.stopTest();

        QuoteTotals totalsPopulator = new QuoteTotals();
        Decimal result = totalsPopulator.computeContactCenterTotalARR(reselectedQliList);
        System.assertNotEquals(null, result);
        // calculate totalMrr manually and compare with method result
        Decimal calculatedCCTotalArr = 0;
        for(QuoteLineItem qli : reselectedQliList) {
            String qliChargeTerm = qli.Product2.Charge_Term__c;
            String entlChargeTerm = qli.Entitlement__r.Product__r.Charge_Term__c;
            if(qliChargeTerm != Product2Helper.CHARGE_TERM_ONE_TIME && qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                if(QuoteTotals.monthlyOrMonthlyContractSet.contains(qliChargeTerm)) {
                    calculatedCCTotalArr += ((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) * 12;
                }else{
                    calculatedCCTotalArr += ((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c);
                }
            }
        }
        calculatedCCTotalArr -= reselectedSalesQuote.Contact_Center_Entitlement_Total_ARR__c;
        System.assertEquals(result, calculatedCCTotalArr);


    }

    @isTest
    static void testEntitlementTotals() {

        Quote testSalesQuote = [SELECT Id, AccountId, OpportunityId, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id,
                Product2.Charge_Term__c, Product2.Family, UnitPrice
            FROM PricebookEntry];

        List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c, EffectivePricePrecise__c, Product__c, Product__r.Charge_Term__c, Product__r.Sub_Category__c FROM Entitlement__c WHERE Account__c = :testSalesQuote.AccountId AND Product__r.Charge_Term__c != :Product2Helper.CHARGE_TERM_ONE_TIME];

        Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
        for(Entitlement__c entl : entlsList) {
            productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
        }

        // entitlement totals populated only on quote insert
        Quote newSalesQuote = new Quote(
            Name = 'newSalesQuote',
            Auto_Renewal__c = true,
            OpportunityId = testSalesQuote.OpportunityId,
            Pricebook2Id = testSalesQuote.Pricebook2Id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Upsell_Status__c = QuoteHelper.STATUS_UPSELL,
            CurrencyIsoCode = 'USD'
        );

        Test.startTest();

            insert newSalesQuote;

            Quote reselectedQuote = [SELECT Id, Upsell_Status__c, Entitlement_Total_ARR__c,
                    Entitlement_Total_MRR__c, Contact_Center_Entitlement_Total_ARR__c,
                    Contact_Center_Entitlement_Total_MRR__c
                FROM Quote WHERE Id = :newSalesQuote.Id];

            Decimal calculatedEntlTotalArr = 0;
            Decimal calculatedEntlTotalMrr = 0;
            Decimal calculatedEntlCCTotalArr = 0;
            Decimal calculatedEntlCCTotalMrr = 0;
            for(Entitlement__c entl : entlsList) {

                if(entl.Product__r.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                    calculatedEntlTotalMrr += ((entl.DisplayQuantity__c * entl.EffectivePrice__c) / 12);
                }else{
                    calculatedEntlTotalMrr += (entl.DisplayQuantity__c * entl.EffectivePrice__c);
                }

                if(QuoteTotals.monthlyOrMonthlyContractSet.contains(entl.Product__r.Charge_Term__c)) {
                    calculatedEntlTotalArr += ((entl.DisplayQuantity__c * entl.EffectivePrice__c) * 12);
                }else{
                    calculatedEntlTotalArr += (entl.DisplayQuantity__c * entl.EffectivePrice__c);
                }

                if(entl.Product__r.Sub_Category__c != Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                    continue;
                }

                if(entl.Product__r.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                    calculatedEntlCCTotalMrr += ((entl.DisplayQuantity__c * entl.EffectivePrice__c) / 12);
                }else{
                    calculatedEntlCCTotalMrr += (entl.DisplayQuantity__c * entl.EffectivePrice__c);
                }

                if(QuoteTotals.monthlyOrMonthlyContractSet.contains(entl.Product__r.Charge_Term__c)) {
                    calculatedEntlCCTotalArr += ((entl.DisplayQuantity__c * entl.EffectivePrice__c) * 12);
                }else{
                    calculatedEntlCCTotalArr += (entl.DisplayQuantity__c * entl.EffectivePrice__c);
                }
            }

            System.assertEquals(calculatedEntlTotalArr, reselectedQuote.Entitlement_Total_ARR__c);
            System.assertEquals(calculatedEntlTotalMrr, reselectedQuote.Entitlement_Total_MRR__c);
            System.assertEquals(calculatedEntlCCTotalArr, reselectedQuote.Contact_Center_Entitlement_Total_ARR__c);
            System.assertEquals(calculatedEntlCCTotalMrr, reselectedQuote.Contact_Center_Entitlement_Total_MRR__c);

        Test.stopTest();
    }

    @isTest
    static void testGetRelatedDataForNGBSQuotes() {

        Entitlement__c testEntl = [SELECT Id, DisplayQuantity__c, EffectivePrice__c FROM Entitlement__c LIMIT 1];

        Decimal displayQuantityValue = (Decimal) QuoteTotals.getRelatedData(
            QuoteHelper.RT_NAME_BILLING,
            testEntl,
            Entitlement__c.DisplayQuantity__c
        );
        Decimal effectivePriceValue = (Decimal) QuoteTotals.getRelatedData(
            QuoteHelper.RT_NAME_BILLING,
            testEntl,
            Entitlement__c.EffectivePrice__c
        );

        System.assertEquals(
            testEntl.DisplayQuantity__c,
            displayQuantityValue,
            'QuoteTotals.getRelatedData method should return value from specified field'
        );
        System.assertEquals(
            testEntl.EffectivePrice__c,
            effectivePriceValue,
            'QuoteTotals.getRelatedData method should return value from specified field'
        );
    }

    @isTest
    static void testComputeProServListPrice() {
        QuoteTotals testQuoteTotals = new QuoteTotals();
        Quote testSalesQuote = (Quote) new QuoteSelector()
            .selectQuoteByName('testSalesQuote')
            .selectFields(new List<String>{'Opportunity.Parent_Order__c', 'Opportunity.Tier_Name__c'})
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
        Decimal resultNewBusiness = 0;
        for (QuoteLineItem qli: qliList) {
            qli.ServiceName__c = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
            qli.NewQuantity__c = 5;
            resultNewBusiness += qli.NewQuantity__c * qli.UnitPrice;
        }
        testSalesQuote.ProServListPrice__c = resultNewBusiness;
        update testSalesQuote;
        Test.startTest();
            Triggers.switchOff();
            insert qliList;
            Triggers.switchOn();

            Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Order.AccountId => testSalesQuote.AccountId,
                        Order.Name => 'test',
                        Order.Status => OrderHelper.STATUS_NEW,
                        Order.OpportunityId => testSalesQuote.OpportunityId,
                        Order.EffectiveDate => System.today().addDays(100),
                        Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                        Order.Pricebook2Id => Test.getStandardPricebookId(),
                        Order.QuoteId => testSalesQuote.Id
                    }
                )
                .create()
                .getRecord();

            Opportunity testChangeOrderOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => testSalesQuote.AccountId,
                        Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                        Opportunity.CloseDate => System.today().addMonths(1),
                        Opportunity.Parent_Order__c => testOrder.Id
                    }
                )
                .create()
                .getRecord();

            Quote testChangeOrderQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'testQuote',
                        Quote.OpportunityId => testChangeOrderOpp.Id,
                        Quote.Account__c => testChangeOrderOpp.AccountId,
                        Quote.isPrimary__c => true,
                        Quote.Pricebook2Id => testSalesQuote.Pricebook2Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                    }
                )
                .create()
                .getRecord();

            Quote reselectedChangeOrderQuote = (Quote) new ListOptional(new QuoteSelector()
                .selectQuoteById(new List<Object> {testChangeOrderQuote.Id})
                .executeQuery()
            ).getFirst();

            testQuoteTotals.quoteIdToQuoteMap = new Map<Id, Quote> {reselectedChangeOrderQuote.Id => reselectedChangeOrderQuote};
            List<QuoteLineItem> qliListExistingBusiness = createQuoteLineItems(testChangeOrderQuote.Id, testChangeOrderQuote.Pricebook2Id, pbeList);
            Decimal resultExistingBusiness = 0;
            for (QuoteLineItem qli: qliListExistingBusiness) {
                qli.ServiceName__c = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
                qli.NewQuantity__c = 10;
                resultExistingBusiness += qli.NewQuantity__c * qli.UnitPrice;
            }
            Decimal expectedResult = resultExistingBusiness - resultNewBusiness;
            Decimal result = testQuoteTotals.computeProServListPrice(qliListExistingBusiness, reselectedChangeOrderQuote.Id);
        Test.stopTest();

        Assert.areEqual(expectedResult, result, 'proServListPrice calculation is incorrect');
    }

    @isTest
    static void testComputeProServDiscount() {
        QuoteTotals testQuoteTotals = new QuoteTotals();
        Quote testSalesQuote = (Quote) new QuoteSelector()
            .selectQuoteByName('testSalesQuote')
            .selectFields(new List<String>{'Opportunity.Parent_Order__c', 'Opportunity.Tier_Name__c'})
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
        Decimal resultNewBusiness = 0;
        for (QuoteLineItem qli: qliList) {
            qli.ServiceName__c = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
            qli.NewQuantity__c = 5;
            qli.Discount = 2;
            resultNewBusiness += qli.NewQuantity__c * (qli.UnitPrice * 0.02);
        }
        testSalesQuote.ProServDiscount__c = resultNewBusiness;
        update testSalesQuote;
        Test.startTest();
            Triggers.switchOff();
            insert qliList;
            Triggers.switchOn();

            Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Order.AccountId => testSalesQuote.AccountId,
                        Order.Name => 'test',
                        Order.Status => OrderHelper.STATUS_NEW,
                        Order.OpportunityId => testSalesQuote.OpportunityId,
                        Order.EffectiveDate => System.today().addDays(100),
                        Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                        Order.Pricebook2Id => Test.getStandardPricebookId(),
                        Order.QuoteId => testSalesQuote.Id
                    }
                )
                .create()
                .getRecord();

            Opportunity testChangeOrderOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => testSalesQuote.AccountId,
                        Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                        Opportunity.CloseDate => System.today().addMonths(1),
                        Opportunity.Parent_Order__c => testOrder.Id
                    }
                )
                .create()
                .getRecord();

            Quote testChangeOrderQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'testQuote',
                        Quote.OpportunityId => testChangeOrderOpp.Id,
                        Quote.Account__c => testChangeOrderOpp.AccountId,
                        Quote.isPrimary__c => true,
                        Quote.Pricebook2Id => testSalesQuote.Pricebook2Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                    }
                )
                .create()
                .getRecord();

            Quote reselectedChangeOrderQuote = (Quote) new ListOptional(new QuoteSelector()
                .selectQuoteById(new List<Object> {testChangeOrderQuote.Id})
                .executeQuery()
            ).getFirst();

            testQuoteTotals.quoteIdToQuoteMap = new Map<Id, Quote> {reselectedChangeOrderQuote.Id => reselectedChangeOrderQuote};
            List<QuoteLineItem> qliListExistingBusiness = createQuoteLineItems(testChangeOrderQuote.Id, testChangeOrderQuote.Pricebook2Id, pbeList);
            Decimal resultExistingBusiness = 0;
            for (QuoteLineItem qli: qliListExistingBusiness) {
                qli.ServiceName__c = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
                qli.NewQuantity__c = 5;
                qli.Discount = 4;
                resultExistingBusiness += qli.NewQuantity__c * (qli.UnitPrice * 0.04);
            }
            Triggers.switchOff();
            insert qliListExistingBusiness;
            Triggers.switchOn();
            Decimal expectedResult = resultExistingBusiness - resultNewBusiness;
            List<QuoteLineItem> reselectedQlisExistingBusiness = new QuoteLineItemSelector()
                .selectQuoteLineItemsForQLITrigger(new Set<Id>{testChangeOrderQuote.Id})
                .executeQuery();
            Decimal result = testQuoteTotals.computeProServDiscount(reselectedQlisExistingBusiness, reselectedChangeOrderQuote.Id);
        Test.stopTest();

        Assert.areEqual(expectedResult, result, 'proServDiscount calculation is incorrect');
    }

}