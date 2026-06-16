@isTest
private class Test_OpportunityTotals {

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
            isPrimary__c = true,
            OpportunityId = testOpp.Id,
            Pricebook2Id = testPriceBook.Id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
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
    static void testPopulateTotalsForOpportunityMethodWithoutData() {

        OpportunityTotals oppTotals = new OpportunityTotals();

        Integer usedQueriesNumber = System.Limits.getQueries();

        Opportunity processedOpp = oppTotals.populateTotalsForOpportunity(null, null, null, null);
        System.assertEquals(null, processedOpp);

        System.assertEquals(
            usedQueriesNumber,
            System.Limits.getQueries(),
            'OpportunityTotals.populateTotalsForOpportunity method should not use SOQL queries'
        );
    }

    @isTest
    static void testPopulateTotalsForOpportunityMethodWithData() {

        // test for opportuinty without any quotes

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Office',
            StageName = OpportunityHelper.STAGE_NAME_QUALIFY,
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD',
            OwnerId = getSalesUser().Id
        );

        OpportunityTotals oppTotals = new OpportunityTotals();
        Opportunity processedOpp = oppTotals.populateTotalsForOpportunity(testOpp, null, null, null);
        processedOpp.OwnerId = testOpp.OwnerId;

        System.assertNotEquals(null, processedOpp);

        System.assertEquals(0, processedOpp.EstimatedProfessionalServices12Month__c);
        System.assertEquals(0, processedOpp.Actual_Estimated_CC_12M_Bookings__c);
        System.assertEquals(0, processedOpp.Total_MRR__c);
        System.assertEquals(0, processedOpp.Deductible_Refunds_Penalty__c);
        System.assertEquals(0, processedOpp.Contact_Center_MRR__c);
        System.assertEquals(null, processedOpp.Initial_Contract_Term__c);
        System.assertEquals(0, processedOpp.CommissionableEstimated12MonthBooking__c);
        System.assertEquals(0, processedOpp.Total_Initial_Amount__c);
        System.assertEquals(0, processedOpp.Total_Contract_Value__c);


        Opportunity processedOpp2 = oppTotals.populateTotalsForOpportunity(processedOpp, null, null, null);
        System.assertEquals(null, processedOpp2, 'if opportunity totals is not changed it should return null');
    }

    @isTest
    static void testPopulateTotalsForOpportunityMethodWithData2() {

        // test for opportuinty with quote

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Office',
            StageName = OpportunityHelper.STAGE_NAME_QUALIFY,
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD',
            OwnerId = getSalesUser().Id
        );

        Quote testSalesQuote = new Quote (
            Name = 'testSalesQuote',
            Auto_Renewal__c = true,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            CurrencyIsoCode = 'USD',
            Contact_Center_Total_First_Year_Cost__c = 0,
            Total_MRR_New__c = 0,
            Contact_Center_Total_MRR__c = 0,
            Initial_Term_months__c = '12',
            Estimated_Hardware__c = 0,
            Total_ARR__c = 0,
            Total_First_Year_Cost__c = 0
        );

        // cancelled CC/ProServ quotes should be passed in opportunity totals calculations
        Quote testProservQuote = new Quote (
            Name = 'cancelled ProservQuote',
            Auto_Renewal__c = true,
            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
            CurrencyIsoCode = 'USD',
            ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED
        );

        List<Quote> quotesList = new List<Quote>();
        quotesList.add(testSalesQuote);
        quotesList.add(testProservQuote);

        OpportunityTotals oppTotals = new OpportunityTotals();
        Opportunity processedOpp = oppTotals.populateTotalsForOpportunity(testOpp, quotesList, null, null);

        System.assertNotEquals(null, processedOpp);

        System.assertEquals(0, processedOpp.EstimatedProfessionalServices12Month__c);
        System.assertEquals(0, processedOpp.Actual_Estimated_CC_12M_Bookings__c);
        System.assertEquals(0, processedOpp.Total_MRR__c);
        System.assertEquals(0, processedOpp.Deductible_Refunds_Penalty__c);
        System.assertEquals(0, processedOpp.Contact_Center_MRR__c);
        System.assertEquals(Integer.valueOf(testSalesQuote.Initial_Term_months__c), processedOpp.Initial_Contract_Term__c);
        System.assertEquals(0, processedOpp.CommissionableEstimated12MonthBooking__c);
        System.assertEquals(0, processedOpp.Total_Initial_Amount__c);
        System.assertEquals(0, processedOpp.Total_Contract_Value__c);
    }


    @isTest
    static void testPopulateTotalsMethodWithoutData() {

        OpportunityTotals oppTotals = new OpportunityTotals();

        List<Opportunity> processedOppList = oppTotals.populateTotals(null, null);
        System.assertNotEquals(null, processedOppList);
        System.assertEquals(0, processedOppList.size());
    }

    @isTest
    static void testPopulateTotalsMethodUserDocusign() {
        Opportunity testOpp = [SELECT Id, StageName FROM Opportunity LIMIT 1];

        User docusignUser = new User(
                Username = 'Docusig@gmail.com',
                FirstName = 'DocuSign',
                LastName = 'Integration',
                Email = 'ds_user@gmail.com',
                Alias = 'dinte',
                TimeZoneSidKey = 'America/Los_Angeles',
                ManagerId = UserInfo.getUserId(),
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                LanguageLocaleKey = 'en_US',
                Hierarchy_Role__c = 'Sales Rep'
        );
        insert docusignUser;

        System.runAs(docusignUser) {
            OpportunityTotals oppTotals = new OpportunityTotals();
            List<Opportunity> processedOppList = oppTotals.populateTotals(new Set<Id>{testOpp.Id}, new Set<Id>());
            System.assertEquals(false, processedOppList.contains(testOpp));
        }
    }


    @isTest
    static void testPopulateTotalsMethodWithData() {

        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Quote testSalesQuote = [SELECT Id, Pricebook2Id, Initial_Term_months__c FROM Quote LIMIT 1];

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

                qliList.add(qli);
            }
        }

        // bypass totals calculation on opportunity on QuoteLineItem insert to make
        // shure that is calculated through direct call
        // (totals on Opportunity will not be updated if "new" totals values not differs with old total values)
        OpportunityTotals.bypassOpportnuityUpdate = true;
        insert qliList;
        OpportunityTotals.bypassOpportnuityUpdate = false;

        Test.startTest();
            Set<Id> oppIdSet = new Set<Id>();
            oppIdSet.add(testOpp.Id);

            OpportunityTotals oppTotals = new OpportunityTotals();

            List<Opportunity> processedOppList = oppTotals.populateTotals(oppIdSet, new Set<Id>());

            System.assertNotEquals(null, processedOppList);
            System.assertEquals(oppIdSet.size(), processedOppList.size());

            for(Opportunity opp : processedOppList) {
                if(opp.Id == testOpp.Id) {
                    System.assertNotEquals(null, opp.Total_MRR__c);
                    System.assertNotEquals(null, opp.CommissionableEstimated12MonthBooking__c);
                    System.assertNotEquals(null, opp.Total_Initial_Amount__c);

                    Integer quoteInitialTermMonthsValue = null;
                    if(testSalesQuote.Initial_Term_months__c != null) {
                        quoteInitialTermMonthsValue = Integer.valueOf(testSalesQuote.Initial_Term_months__c);
                    }

                    // Initial_Contract_Term__c should be equal to primary Quote.Initial_Term_months__c
                    System.assertEquals(quoteInitialTermMonthsValue, opp.Initial_Contract_Term__c);
                }
            }
        Test.stopTest();
    }


    @isTest
    static void testComputeEstimated12MBookingsMethod() {

        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Quote testProServQuote = new Quote(
            Name = 'testProServ quote',
            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
            OpportunityId = testOpp.Id,
            ProServ_Status__c = '',
            Total_First_Year_Cost__c = 5
        );
        insert testProServQuote;

        List<Quote> quotesList = [SELECT Id, RecordTypeId,
                Total_First_Year_Cost__c, isPrimary__c, ProServ_Status__c
            FROM Quote
            WHERE RecordTypeId = :QuoteHelper.RT_ID_SALES OR
                RecordTypeId = :QuoteHelper.RT_ID_PROSERV];

        Test.startTest();

            OpportunityTotals oppTotals = new OpportunityTotals();

            Integer usedQueriesNumber = System.Limits.getQueries();

            Decimal result = oppTotals.computeEstimated12MBookings(null, null);
            System.assertNotEquals(null, result);
            System.assertEquals(0, result);

            result = oppTotals.computeEstimated12MBookings(new List<Quote>(), null);
            System.assertNotEquals(null, result);
            System.assertEquals(0, result);


            result = oppTotals.computeEstimated12MBookings(quotesList, null);
            Decimal calculatedEst12MonthsBookingValue = 0;
            for(Quote qt : quotesList) {
                calculatedEst12MonthsBookingValue += qt.Total_First_Year_Cost__c;
            }
            System.assertNotEquals(null, result);
            System.assertEquals(calculatedEst12MonthsBookingValue, result);

            System.assertEquals(
                usedQueriesNumber,
                System.Limits.getQueries(),
                'OpportunityTotals.computeEstimated12MBookings method should not use SOQL queries'
            );

        Test.stopTest();
    }

    @isTest
    static void testComputeEstimated12MCommissionableBookingsMethod() {
        Opportunity testOpp = [SELECT Id, Is_Billing_Opportunity__c FROM Opportunity LIMIT 1];
        testOpp.Is_Billing_Opportunity__c = true;
        List<Quote> quotesList = new List<Quote>();

        Quote testSalesQuote = new Quote(
            isPrimary__c = true,
            Name = 'testSales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Total_ARR__c = 12

        );
        quotesList.add(testSalesQuote);

        Quote testCCQuote = new Quote(
            Name = 'testCC quote',
            RecordTypeId = QuoteHelper.RT_ID_CC,
            OpportunityId = testOpp.Id,
            Contact_Center_Total_ARR__c = 15
        );
        quotesList.add(testCCQuote);
        OpportunityTotals oppTotals = new OpportunityTotals();
        Integer usedQueriesNumber = System.Limits.getQueries();

        Decimal result = oppTotals.computeEstimated12MCommissionableBookings(testOpp.Is_Billing_Opportunity__c, null, null, null, null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeEstimated12MCommissionableBookings(testOpp.Is_Billing_Opportunity__c, new List<Quote>(), null, null, null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        // if estimatedHardware, estimatedProServAmount, deductibleRefunds values is null - they should be treated as 0
        Decimal estimatedHardware = null;
        Decimal estimatedProServAmount = null;
        Decimal deductibleRefunds = null;
        result = oppTotals.computeEstimated12MCommissionableBookings(
            testOpp.Is_Billing_Opportunity__c,
            quotesList,
            estimatedHardware,
            estimatedProServAmount,
            deductibleRefunds
        );
        Decimal calculatedEst12MonthsCommissionableBookingValue = 0;

        for(Quote qt : quotesList) {
            if (qt.isPrimary__c) {
                calculatedEst12MonthsCommissionableBookingValue += qt.Total_ARR__c;
            } else if (qt.RecordTypeId == QuoteHelper.RT_ID_CC) {
                calculatedEst12MonthsCommissionableBookingValue += qt.Contact_Center_Total_ARR__c;
            }
        }
        if (estimatedHardware != null && estimatedProServAmount != null && deductibleRefunds != null) {
            calculatedEst12MonthsCommissionableBookingValue += ((estimatedHardware * 0.5) + (estimatedProServAmount * 0.5) - deductibleRefunds);
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedEst12MonthsCommissionableBookingValue, result);

        estimatedHardware = 10;
        estimatedProServAmount = 10;
        deductibleRefunds = 2;
        result = oppTotals.computeEstimated12MCommissionableBookings(
            testOpp.Is_Billing_Opportunity__c,
            quotesList,
            estimatedHardware,
            estimatedProServAmount,
            deductibleRefunds
        );
        calculatedEst12MonthsCommissionableBookingValue = 0;

        for(Quote qt : quotesList) {
            if (qt.isPrimary__c) {
                calculatedEst12MonthsCommissionableBookingValue += qt.Total_ARR__c;
            } else if (qt.RecordTypeId == QuoteHelper.RT_ID_CC) {
                calculatedEst12MonthsCommissionableBookingValue += qt.Contact_Center_Total_ARR__c;
            }
        }
        if (estimatedHardware != null && estimatedProServAmount != null && deductibleRefunds != null) {
            calculatedEst12MonthsCommissionableBookingValue += ((estimatedHardware * 0.5) + (estimatedProServAmount * 0.5) - deductibleRefunds);
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedEst12MonthsCommissionableBookingValue, result);

        // Old logic is not changed
        testOpp.Is_Billing_Opportunity__c = false;
        estimatedHardware = 10;
        estimatedProServAmount = 10;
        deductibleRefunds = 2;
        result = oppTotals.computeEstimated12MCommissionableBookings(
            testOpp.Is_Billing_Opportunity__c,
            quotesList,
            estimatedHardware,
            estimatedProServAmount,
            deductibleRefunds
        );
        calculatedEst12MonthsCommissionableBookingValue = 0;

        for(Quote qt : quotesList) {
            if (qt.isPrimary__c) {
                calculatedEst12MonthsCommissionableBookingValue += qt.Total_ARR__c;
            }
        }
        if (estimatedHardware != null && estimatedProServAmount != null && deductibleRefunds != null) {
            calculatedEst12MonthsCommissionableBookingValue += ((estimatedHardware * 0.5) + (estimatedProServAmount * 0.5) - deductibleRefunds);
        }

        System.assertNotEquals(null, result);
        System.assertEquals(calculatedEst12MonthsCommissionableBookingValue, result);

        System.assertEquals(
            usedQueriesNumber,
            System.Limits.getQueries(),
            'OpportunityTotals.computeEstimated12MCommissionableBookings method should not use SOQL queries'
        );
    }

    @isTest
    static void testComputeEstimatedProServicesAmount() {

        Opportunity testOpp = [SELECT Id, Is_Billing_Opportunity__c FROM Opportunity LIMIT 1];
        testOpp.Is_Billing_Opportunity__c = false;
        List<Quote> quotesList = new List<Quote>();

        Quote testSalesQuote = new Quote(
            isPrimary__c = true,
            Name = 'testSales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Total_First_Year_Cost__c = 7
        );
        quotesList.add(testSalesQuote);

        Quote testProservQuote = new Quote(
            Name = 'testProserv quote',
            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
            ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CREATED,
            OpportunityId = testOpp.Id,
            Total_First_Year_Cost__c = 12
        );
        quotesList.add(testProservQuote);

        Quote testCCProservQuote = new Quote(
            Name = 'testProserv quote',
            RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV,
            ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED,
            OpportunityId = testOpp.Id,
            Total_First_Year_Cost__c = 17
        );
        quotesList.add(testProservQuote);

        OpportunityTotals oppTotals = new OpportunityTotals();

        Integer usedQueriesNumber = System.Limits.getQueries();

        Decimal result = oppTotals.computeEstimatedProServicesAmount(null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeEstimatedProServicesAmount(new List<Quote>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeEstimatedProServicesAmount(quotesList);
        Decimal calculatedEstimatedProServAmount = 0;
        for(Quote qt : quotesList) {
            // in calculation used not cancelled cc/Proserv quotes only
            Boolean isCCOrProserv = qt.RecordTypeId == QuoteHelper.RT_ID_PROSERV || qt.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV;
            if(isCCOrProserv && qt.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_CANCELLED) {
                calculatedEstimatedProServAmount += qt.Total_First_Year_Cost__c;
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedEstimatedProServAmount, result);

        System.assertEquals(
            usedQueriesNumber,
            System.Limits.getQueries(),
            'OpportunityTotals.computeEstimatedProServicesAmount method should not use SOQL queries'
        );
    }

    @isTest
    static void testComputeEstimatedCCBookings() {

        Opportunity testOpp = [SELECT Id, Is_Billing_Opportunity__c FROM Opportunity LIMIT 1];
        testOpp.Is_Billing_Opportunity__c = false;
        List<Quote> quotesList = new List<Quote>();

        Quote testPrimarySalesQuote = new Quote(
            isPrimary__c = true,
            Name = 'test primary Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Contact_Center_Total_First_Year_Cost__c = 7
        );
        quotesList.add(testPrimarySalesQuote);

        Quote testSalesQuote = new Quote(
            isPrimary__c = false,
            Name = 'test second Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Contact_Center_Total_First_Year_Cost__c = 12
        );
        quotesList.add(testSalesQuote);

        OpportunityTotals oppTotals = new OpportunityTotals();

        Integer usedQueriesNumber = System.Limits.getQueries();

        Decimal result = oppTotals.computeEstimatedCCBookings(testOpp.Is_Billing_Opportunity__c, null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeEstimatedCCBookings(testOpp.Is_Billing_Opportunity__c, new List<Quote>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeEstimatedCCBookings(testOpp.Is_Billing_Opportunity__c, quotesList);
        Decimal calculatedEstimatedCCBookings = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                calculatedEstimatedCCBookings += qt.Contact_Center_Total_First_Year_Cost__c;
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedEstimatedCCBookings, result);

        System.assertEquals(
            usedQueriesNumber,
            System.Limits.getQueries(),
            'OpportunityTotals.computeEstimatedCCBookings method should not use SOQL queries'
        );
    }

    @isTest
    static void testComputeEstimatedHardware() {

        Opportunity testOpp = [SELECT Id, Is_Billing_Opportunity__c FROM Opportunity LIMIT 1];
        testOpp.Is_Billing_Opportunity__c = false;
        List<Quote> quotesList = new List<Quote>();

        Quote testPrimarySalesQuote = new Quote(
            isPrimary__c = true,
            Name = 'test primary Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Estimated_Hardware__c = 7
        );
        quotesList.add(testPrimarySalesQuote);

        Quote testSalesQuote = new Quote(
            isPrimary__c = false,
            Name = 'test second Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Estimated_Hardware__c = 12
        );
        quotesList.add(testSalesQuote);

        OpportunityTotals oppTotals = new OpportunityTotals();

        Integer usedQueriesNumber = System.Limits.getQueries();

        Decimal result = oppTotals.computeEstimatedHardware(testOpp.Is_Billing_Opportunity__c, null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeEstimatedHardware(testOpp.Is_Billing_Opportunity__c, new List<Quote>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeEstimatedHardware(testOpp.Is_Billing_Opportunity__c, quotesList);
        Decimal calculatedEstimatedHardware = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                calculatedEstimatedHardware += qt.Estimated_Hardware__c;
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedEstimatedHardware, result);

        System.assertEquals(
            usedQueriesNumber,
            System.Limits.getQueries(),
            'OpportunityTotals.computeEstimatedHardware method should not use SOQL queries'
        );
    }

    @isTest
    static void testComputeDeductibleRefunds() {

        Opportunity testOpp = [SELECT Id, Is_Billing_Opportunity__c FROM Opportunity LIMIT 1];
        testOpp.Is_Billing_Opportunity__c = false;
        List<Quote> quotesList = new List<Quote>();

        Quote testPrimarySalesQuote = new Quote(
            isPrimary__c = true,
            Name = 'test primary Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Credit_Amount__c = 39.99,
            Special_Terms__c = QuoteHelper.FREE_MONTH_1
        );
        quotesList.add(testPrimarySalesQuote);

        // Quote testSalesQuote = new Quote(
        //     isPrimary__c = false,
        //     Name = 'test second Sales quote',
        //     RecordTypeId = QuoteHelper.RT_ID_SALES,
        //     OpportunityId = testOpp.Id,
        //     Special_Terms__c = QuoteHelper.FREE_MONTH_3
        // );
        // quotesList.add(testSalesQuote);

        OpportunityTotals oppTotals = new OpportunityTotals();

        Integer usedQueriesNumber = System.Limits.getQueries();

        Decimal result = oppTotals.computeDeductibleRefunds(testOpp.Is_Billing_Opportunity__c, null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeDeductibleRefunds(testOpp.Is_Billing_Opportunity__c, new List<Quote>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeDeductibleRefunds(testOpp.Is_Billing_Opportunity__c, quotesList);
        Decimal calculatedDeductibleRefunds = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                Decimal creditAmountValue = qt.Credit_Amount__c == null ? 0 : qt.Credit_Amount__c;
                calculatedDeductibleRefunds += creditAmountValue;
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedDeductibleRefunds, result);


        // set 2 months in Special_Terms__c
        testPrimarySalesQuote.Special_Terms__c = QuoteHelper.FREE_MONTH_2;

        result = oppTotals.computeDeductibleRefunds(testOpp.Is_Billing_Opportunity__c, quotesList);
        calculatedDeductibleRefunds = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                Decimal creditAmountValue = qt.Credit_Amount__c == null ? 0 : qt.Credit_Amount__c;
                calculatedDeductibleRefunds += (creditAmountValue * 0.625);
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedDeductibleRefunds, result);


        // set 3 months in Special_Terms__c
        testPrimarySalesQuote.Special_Terms__c = QuoteHelper.FREE_MONTH_3;

        result = oppTotals.computeDeductibleRefunds(testOpp.Is_Billing_Opportunity__c, quotesList);
        calculatedDeductibleRefunds = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                Decimal creditAmountValue = qt.Credit_Amount__c == null ? 0 : qt.Credit_Amount__c;
                calculatedDeductibleRefunds += (creditAmountValue * 0.5);
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedDeductibleRefunds, result);

        // set 4 months in Special_Terms__c
        testPrimarySalesQuote.Special_Terms__c = QuoteHelper.FREE_MONTH_4;

        result = oppTotals.computeDeductibleRefunds(testOpp.Is_Billing_Opportunity__c, quotesList);
        calculatedDeductibleRefunds = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                Decimal creditAmountValue = qt.Credit_Amount__c == null ? 0 : qt.Credit_Amount__c;
                calculatedDeductibleRefunds += (creditAmountValue / 4 * 3 * 0.5) + (creditAmountValue / 4);
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedDeductibleRefunds, result);

        // set 5 months in Special_Terms__c
        testPrimarySalesQuote.Special_Terms__c = QuoteHelper.FREE_MONTH_5;

        result = oppTotals.computeDeductibleRefunds(testOpp.Is_Billing_Opportunity__c, quotesList);
        calculatedDeductibleRefunds = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                Decimal creditAmountValue = qt.Credit_Amount__c == null ? 0 : qt.Credit_Amount__c;
                calculatedDeductibleRefunds += (creditAmountValue / 5 * 3 * 0.5) + (creditAmountValue / 5 * 2);
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedDeductibleRefunds, result);

        // set 6 months in Special_Terms__c
        testPrimarySalesQuote.Special_Terms__c = QuoteHelper.FREE_MONTH_6;

        result = oppTotals.computeDeductibleRefunds(testOpp.Is_Billing_Opportunity__c, quotesList);
        calculatedDeductibleRefunds = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                Decimal creditAmountValue = qt.Credit_Amount__c == null ? 0 : qt.Credit_Amount__c;
                calculatedDeductibleRefunds += (creditAmountValue / 6 * 3 * 0.5) + (creditAmountValue / 6 * 3);
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedDeductibleRefunds, result);



        System.assertEquals(
            usedQueriesNumber,
            System.Limits.getQueries(),
            'OpportunityTotals.computeDeductibleRefunds method should not use SOQL queries'
        );
    }

    @isTest
    static void testComputeTotalMrr() {

        Opportunity testOpp = [SELECT Id, Is_Billing_Opportunity__c FROM Opportunity LIMIT 1];
        testOpp.Is_Billing_Opportunity__c = false;
        List<Quote> quotesList = new List<Quote>();

        Quote testPrimarySalesQuote = new Quote(
            isPrimary__c = true,
            Name = 'test primary Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Total_MRR_New__c = 42
        );
        quotesList.add(testPrimarySalesQuote);

        Quote testSalesQuote = new Quote(
            isPrimary__c = false,
            Name = 'test second Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Total_MRR_New__c = 36
        );
        quotesList.add(testSalesQuote);

        OpportunityTotals oppTotals = new OpportunityTotals();

        Integer usedQueriesNumber = System.Limits.getQueries();

        Decimal result = oppTotals.computeTotalMRR(testOpp.Is_Billing_Opportunity__c, null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeTotalMRR(testOpp.Is_Billing_Opportunity__c, new List<Quote>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeTotalMRR(testOpp.Is_Billing_Opportunity__c, quotesList);
        Decimal calculatedTotalMrr = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                calculatedTotalMrr += qt.Total_MRR_New__c;
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalMrr, result);

        testOpp.Is_Billing_Opportunity__c = true;
        Quote testCCQuote = new Quote(
            isPrimary__c = false,
            Name = 'testCC quote',
            RecordTypeId = QuoteHelper.RT_ID_CC,
            OpportunityId = testOpp.Id,
            Contact_Center_Total_MRR__c = 1
        );
        quotesList.add(testCCQuote);
        result = oppTotals.computeTotalMRR(testOpp.Is_Billing_Opportunity__c, quotesList);
        Decimal calculatedTotalMrrForBillingOpp = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                calculatedTotalMrrForBillingOpp += qt.Total_MRR_New__c;
            }
            if(qt.RecordTypeId == QuoteHelper.RT_ID_CC) {
                calculatedTotalMrrForBillingOpp += qt.Contact_Center_Total_MRR__c;
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalMrrForBillingOpp, result);
        System.assertEquals(
            usedQueriesNumber,
            System.Limits.getQueries(),
            'OpportunityTotals.computeTotalMRR method should not use SOQL queries'
        );
    }

    @isTest
    static void testComputeCCMRR() {

        Opportunity testOpp = [SELECT Id, Is_Billing_Opportunity__c FROM Opportunity LIMIT 1];
        testOpp.Is_Billing_Opportunity__c = false;
        List<Quote> quotesList = new List<Quote>();

        Quote testPrimarySalesQuote = new Quote(
            isPrimary__c = true,
            Name = 'test primary Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Contact_Center_Total_MRR__c = 7
        );
        quotesList.add(testPrimarySalesQuote);

        Quote testSalesQuote = new Quote(
            isPrimary__c = false,
            Name = 'test second Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Contact_Center_Total_MRR__c = 1
        );
        quotesList.add(testSalesQuote);

        OpportunityTotals oppTotals = new OpportunityTotals();

        Integer usedQueriesNumber = System.Limits.getQueries();

        Decimal result = oppTotals.computeCCMRR(testOpp.Is_Billing_Opportunity__c, null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeCCMRR(testOpp.Is_Billing_Opportunity__c, new List<Quote>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeCCMRR(testOpp.Is_Billing_Opportunity__c, quotesList);
        Decimal calculatedCCMrr = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                calculatedCCMrr += qt.Contact_Center_Total_MRR__c == null ? 0 : qt.Contact_Center_Total_MRR__c;
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedCCMrr, result);

        testOpp.Is_Billing_Opportunity__c = true;
        Quote testCCQuote = new Quote(
            isPrimary__c = false,
            Name = 'testCC quote',
            RecordTypeId = QuoteHelper.RT_ID_CC,
            OpportunityId = testOpp.Id,
            Contact_Center_Total_MRR__c = 1
        );
        quotesList.add(testCCQuote);
        result = oppTotals.computeCCMRR(testOpp.Is_Billing_Opportunity__c, quotesList);
        Decimal calculatedCCMrrForBillingOpp = 0;
        for(Quote qt : quotesList) {
            if(qt.RecordTypeId == QuoteHelper.RT_ID_CC) {
                calculatedCCMrrForBillingOpp += qt.Contact_Center_Total_MRR__c == null ? 0 : qt.Contact_Center_Total_MRR__c;
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedCCMrrForBillingOpp, result);
        System.assertEquals(
            usedQueriesNumber,
            System.Limits.getQueries(),
            'OpportunityTotals.computeCCMRR method should not use SOQL queries'
        );
    }

    @isTest
    static void testComputeInitialContractTerm() {

        Opportunity testOpp = [SELECT Id, Is_Billing_Opportunity__c FROM Opportunity LIMIT 1];
        testOpp.Is_Billing_Opportunity__c = false;
        List<Quote> quotesList = new List<Quote>();

        Quote testPrimarySalesQuote = new Quote(
            isPrimary__c = true,
            Name = 'test primary Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Initial_Term_months__c = '24',
            Payment_Plan__c = Pricebook2Helper.PLAN_MONTHLY
        );
        testPrimarySalesQuote.Pricebook2 = new Pricebook2(
            Plan__c = Pricebook2Helper.PLAN_MONTHLY_CONTRACT
        );
        quotesList.add(testPrimarySalesQuote);

        Quote testSalesQuote = new Quote(
            isPrimary__c = false,
            Name = 'test second Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Initial_Term_months__c = '12'
        );
        quotesList.add(testSalesQuote);

        OpportunityTotals oppTotals = new OpportunityTotals();

        Integer usedQueriesNumber = System.Limits.getQueries();

        Decimal result = oppTotals.computeInitialContractTerm(testOpp.Is_Billing_Opportunity__c, null, null, null);
        System.assertEquals(null, result);

        result = oppTotals.computeInitialContractTerm(testOpp.Is_Billing_Opportunity__c, new List<Quote>(), null, null);
        System.assertEquals(null, result);

        result = oppTotals.computeInitialContractTerm(testOpp.Is_Billing_Opportunity__c, quotesList, null, null);
        Integer calculatedInitialContractTerm = 0;
        for(Quote qt : quotesList) {
            Boolean hasMonthlyPlan = qt.Payment_Plan__c == Pricebook2Helper.PLAN_MONTHLY;
            if(qt.isPrimary__c) {
                calculatedInitialContractTerm +=
                    hasMonthlyPlan
                        ? 1
                        : Integer.valueOf(qt.Initial_Term_months__c);
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedInitialContractTerm, result);

        // possible spaces in Quote.Initial_Term_months__c field should trimmed
        testPrimarySalesQuote.Initial_Term_months__c = '   24   ';

        result = oppTotals.computeInitialContractTerm(testOpp.Is_Billing_Opportunity__c, quotesList, null, null);
        calculatedInitialContractTerm = 0;
        for(Quote qt : quotesList) {
            Boolean hasMonthlyPlan = qt.Payment_Plan__c == Pricebook2Helper.PLAN_MONTHLY;
            if(qt.isPrimary__c) {
                calculatedInitialContractTerm +=
                    hasMonthlyPlan
                        ? 1
                        : Integer.valueOf(qt.Initial_Term_months__c);
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedInitialContractTerm, result);


        // in case if primaryQuote.Pricebook2.Plan__c is Monthly - initial contract term value always will be 1
        testPrimarySalesQuote.Pricebook2 = new Pricebook2(
            Plan__c = Pricebook2Helper.PLAN_MONTHLY
        );
        result = oppTotals.computeInitialContractTerm(testOpp.Is_Billing_Opportunity__c, quotesList, null, null);
        System.assertNotEquals(null, result);
        System.assertEquals(1, result);

        System.assertEquals(
            usedQueriesNumber,
            System.Limits.getQueries(),
            'OpportunityTotals.computeInitialContractTerm method should not use SOQL queries'
        );
    }

   

    @isTest
    static void testComputeTotalInitialAmount() {

        Opportunity testOpp = [SELECT Id, Is_Billing_Opportunity__c FROM Opportunity LIMIT 1];
        testOpp.Is_Billing_Opportunity__c = false;
        List<Quote> quotesList = new List<Quote>();

        Quote testPrimarySalesQuote = new Quote(
            isPrimary__c = true,
            Name = 'test primary Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Total_First_Year_Cost__c = 12
        );
        quotesList.add(testPrimarySalesQuote);

        Quote testSalesQuote = new Quote(
            isPrimary__c = false,
            Name = 'test second Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Total_First_Year_Cost__c = 11
        );
        quotesList.add(testSalesQuote);

        OpportunityTotals oppTotals = new OpportunityTotals();

        Integer usedQueriesNumber = System.Limits.getQueries();

        Decimal result = oppTotals.computeTotalInitialAmount(testOpp.Is_Billing_Opportunity__c, null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeTotalInitialAmount(testOpp.Is_Billing_Opportunity__c, new List<Quote>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeTotalInitialAmount(testOpp.Is_Billing_Opportunity__c, quotesList);
        Decimal calculatedTotalInitialAmount = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                calculatedTotalInitialAmount += qt.Total_First_Year_Cost__c;
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalInitialAmount, result);

        System.assertEquals(
            usedQueriesNumber,
            System.Limits.getQueries(),
            'OpportunityTotals.computeTotalInitialAmount method should not use SOQL queries'
        );
    }

    @isTest
    static void testComputeTotalContract() {

        Opportunity testOpp = [SELECT Id, Is_Billing_Opportunity__c FROM Opportunity LIMIT 1];
        testOpp.Is_Billing_Opportunity__c = false;
        List<Quote> quotesList = new List<Quote>();

        Quote testPrimarySalesQuote = new Quote(
            isPrimary__c = true,
            Name = 'test primary Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Total_First_Year_Cost__c = 12,
            Initial_Term_months__c = '12'
        );
        quotesList.add(testPrimarySalesQuote);

        Quote testSalesQuote = new Quote(
            isPrimary__c = false,
            Name = 'test second Sales quote',
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            OpportunityId = testOpp.Id,
            Total_First_Year_Cost__c = 11,
            Initial_Term_months__c = '24'
        );
        quotesList.add(testSalesQuote);

        OpportunityTotals oppTotals = new OpportunityTotals();

        Integer usedQueriesNumber = System.Limits.getQueries();

        Decimal result = oppTotals.computeTotalContractValue(testOpp.Is_Billing_Opportunity__c, null);
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeTotalContractValue(testOpp.Is_Billing_Opportunity__c, new List<Quote>());
        System.assertNotEquals(null, result);
        System.assertEquals(0, result);

        result = oppTotals.computeTotalContractValue(testOpp.Is_Billing_Opportunity__c, quotesList);
        Decimal calculatedTotalInitialAmount = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                calculatedTotalInitialAmount += qt.Total_First_Year_Cost__c;
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalInitialAmount, result);


        // set Quote.Initial_Term_months__c more thann 12 months
        testPrimarySalesQuote.Initial_Term_months__c = '24';
        testPrimarySalesQuote.Total_MRR_New__c = 54.99;

        result = oppTotals.computeTotalContractValue(testOpp.Is_Billing_Opportunity__c, quotesList);
        calculatedTotalInitialAmount = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                Decimal totalFirstYearCost = qt.Total_First_Year_Cost__c == null ? 0 : qt.Total_First_Year_Cost__c;
                Decimal totalMrr = qt.Total_MRR_New__c == null ? 0 : qt.Total_MRR_New__c;
                Integer initialTermMonths = qt.Initial_Term_months__c == null ? 0 : Integer.valueOf(qt.Initial_Term_months__c);
                calculatedTotalInitialAmount += (totalFirstYearCost + (totalMrr * (initialTermMonths - 12)));
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalInitialAmount, result);

        testOpp.Is_Billing_Opportunity__c = true;
        Quote testContactCenterQuote = new Quote(
            isPrimary__c = false,
            Name = 'test Contact Center quote',
            RecordTypeId = QuoteHelper.RT_ID_CC,
            OpportunityId = testOpp.Id,
            Contact_Center_Total_First_Year_Cost__c = 11,
            Initial_Term_months__c = '12'
        );
        testPrimarySalesQuote.Initial_Term_months__c = '12';
        testPrimarySalesQuote.Total_MRR_New__c = 0;
        quotesList.add(testContactCenterQuote);
        result = oppTotals.computeTotalContractValue(testOpp.Is_Billing_Opportunity__c, quotesList);
        calculatedTotalInitialAmount = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                calculatedTotalInitialAmount += qt.Total_First_Year_Cost__c;
            }
            if(qt.RecordTypeId == QuoteHelper.RT_ID_CC) {
                calculatedTotalInitialAmount += (Decimal) NumberHelper.getNumberNullSafe(
                                                qt.Contact_Center_Total_First_Year_Cost__c);
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalInitialAmount, result);

        // set Quote.Initial_Term_months__c more thann 12 months
        testPrimarySalesQuote.Initial_Term_months__c = '24';
        testPrimarySalesQuote.Total_MRR_New__c = 54.99;
        testContactCenterQuote.Initial_Term_months__c = '24';
        testContactCenterQuote.Contact_Center_Total_MRR__c = 24.99;

        result = oppTotals.computeTotalContractValue(testOpp.Is_Billing_Opportunity__c, quotesList);
        calculatedTotalInitialAmount = 0;
        for(Quote qt : quotesList) {
            if(qt.isPrimary__c) {
                Decimal totalFirstYearCost = qt.Total_First_Year_Cost__c == null ? 0 : qt.Total_First_Year_Cost__c;
                Decimal totalMrr = qt.Total_MRR_New__c == null ? 0 : qt.Total_MRR_New__c;
                Integer initialTermMonths = qt.Initial_Term_months__c == null ? 0 : Integer.valueOf(qt.Initial_Term_months__c);
                calculatedTotalInitialAmount += (totalFirstYearCost + (totalMrr * (initialTermMonths - 12)));
            }
            if(qt.RecordTypeId == QuoteHelper.RT_ID_CC) {
                Decimal totalFirstYearCost = qt.Contact_Center_Total_First_Year_Cost__c == null ? 0 : qt.Contact_Center_Total_First_Year_Cost__c;
                Decimal totalMrr = qt.Contact_Center_Total_MRR__c == null ? 0 : qt.Contact_Center_Total_MRR__c;
                Integer initialTermMonths = testPrimarySalesQuote.Initial_Term_months__c == null ? 0 : Integer.valueOf(testPrimarySalesQuote.Initial_Term_months__c);
                calculatedTotalInitialAmount += (totalFirstYearCost + (totalMrr * (initialTermMonths - 12)));
            }
        }
        System.assertNotEquals(null, result);
        System.assertEquals(calculatedTotalInitialAmount, result);

        System.assertEquals(
            usedQueriesNumber,
            System.Limits.getQueries(),
            'OpportunityTotals.computeTotalContractValue method should not use SOQL queries'
        );
    }

    private static User getSalesUser() {
        return [SELECT Id FROM User WHERE Profile.Name LIKE '%sales%' LIMIT 1];
    }
}