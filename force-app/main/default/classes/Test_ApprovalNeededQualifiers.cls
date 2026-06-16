@isTest
private class Test_ApprovalNeededQualifiers {

    @testSetup
    static void setup(){

        Triggers.switchOff();
        Account testAccount = new Account(
            Name = 'Opty test account',
            Permitted_Brands__c = 'RingCentral'
        );
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Office',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert testOpp;

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Line_Range_Max__c = 10,
            CurrencyIsoCode = 'USD'
        );
        insert testPriceBook;

        Quote testSalesQuote = new Quote (
            Name = 'testSalesQuote',
            Auto_Renewal__c = true,
            OpportunityId = testOpp.Id,
            Pricebook2Id = testPriceBook.Id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            CurrencyIsoCode = 'USD'
        );
        insert testSalesQuote;

        List<Product2> prodList = new List<Product2>();

        Product2 testProduct = new Product2(
            Name = 'test product',
            IsActive = true,
            Sub_Category__c = 'Main',
            GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
        );
        prodList.add(testProduct);
        insert prodList;


        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pbe;

        for(Product2 item : prodList) {

            pbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = item.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
            pbeList.add(pbe);

            pbe = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = item.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                CurrencyIsoCode = 'USD'
            );
            pbeList.add(pbe);
        }
        insert pbeList;

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();

        for(PricebookEntry item : pbeList) {

            if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                QuoteLineItem qli = new QuoteLineItem(
                    QuoteId = testSalesQuote.Id,
                    Product2Id = item.Product2Id,
                    Quantity = 20,
                    UnitPrice = item.UnitPrice,
                    Discount = 1,
                    Discount_number__c = 1,
                    PricebookEntryId = item.Id
                );
                qliList.add(qli);
            }
        }
        insert qliList;
        Triggers.switchOn();
        GOA_V2__c goaItem = new GOA_V2__c(
            Name = '1',
            Quantity_Range__c = '1-99',
            Contract_Initial_Term_Range__c = '',
            Sales_Rep__c = '0-0',
            Direct_Manager__c = '0.01-2.00',
            Segment_Leader__c = '2.01-3.00',
            SVP_WWS_Directs__c = '3.01-5.00',
            SVP_WWS__c = '5.01-99999999',
            Group__c = 'RC_Office_Standard_Monthly_Contract',
            Currency__c = 'USD',
            Allowed_Percentage_Quantity_Change__c = 10
        );

        insert new List<GOA_V2__c>{
            goaItem
        };
    }

    @isTest
    static void testApprovedFieldsOnQliPopulation() {

        List<QuoteLineItem> qliList = [SELECT Id, Quantity, NewQuantity__c,
                Approved_Quantity__c, Approved_Discount__c, Approved_Discount_Type__c,
                Discount_type__c, Discount, Discount_Value__c, Product2.GOA_Group_V2__c
            FROM QuoteLineItem];

        for(QuoteLineItem qli : qliList) {

            System.assertEquals(null, qli.Approved_Quantity__c);
            System.assertEquals(null, qli.Approved_Discount__c);
            System.assertEquals(null, qli.Approved_Discount_Type__c);
        }

        List<Quote> quotes = [SELECT Id, Approved_Status__c FROM Quote];
        // approve quote and verify approved discount, discountType and Quantity is saved
        if(quotes[0] != null) {
            Quote q = quotes[0];
            q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            update q;
        }

        qliList = [SELECT Id, Quantity, NewQuantity__c,
                Approved_Quantity__c, Approved_Discount__c, Approved_Discount_Type__c,
                Discount_type__c, Discount, Discount_Value__c, Product2.GOA_Group_V2__c
            FROM QuoteLineItem];

        Test.startTest();
            for(QuoteLineItem qli : qliList) {

                System.assertEquals(qli.Quantity, qli.Approved_Quantity__c);
                System.assertEquals(qli.Discount_Value__c, qli.Approved_Discount__c);
                System.assertEquals(qli.Discount_type__c, qli.Approved_Discount_Type__c);
            }

            // set quote approved status as "required" and verify that approved... fields is cleared
            quotes = [SELECT Id, Approved_Status__c FROM Quote];
            // approve quote and verify approved discount, discountType and Quantity is saved
            if(quotes[0] != null) {
                Quote q = quotes[0];
                q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                update q;
            }

            qliList = [SELECT Id, Quantity, NewQuantity__c,
                    Approved_Quantity__c, Approved_Discount__c, Approved_Discount_Type__c,
                    Discount_type__c, Discount, Discount_Value__c, Product2.GOA_Group_V2__c
                FROM QuoteLineItem];

            for(QuoteLineItem qli : qliList) {

                System.assertEquals(null, qli.Approved_Quantity__c);
                System.assertEquals(null, qli.Approved_Discount__c);
                System.assertEquals(null, qli.Approved_Discount_Type__c);
            }
        Test.stopTest();
    }

    @isTest
    static void testApprovedFieldsOnQliPopulationWithEntitlemnts() {

        List<QuoteLineItem> qliList = [SELECT Id, Quantity, NewQuantity__c, UnitPrice,
                Approved_Quantity__c, Approved_Discount__c, Approved_Discount_Type__c,
                Discount_type__c, Discount, Discount_Value__c, Product2Id,
                Product2.GOA_Group_V2__c, Quote.AccountId
            FROM QuoteLineItem];

        List<Entitlement__c> entlList = new List<Entitlement__c>();
        for(QuoteLineItem qli : qliList) {
            entlList.add(
                new Entitlement__c(
                    Active__c = true,
                    Account__c = qli.Quote.AccountId,
                    Product__c = qli.Product2Id,
                    Discount__c = qli.Discount,
                    Discount_Type__c = qli.Discount_type__c,
                    Quantity__c = 1,
                    Price__c = qli.UnitPrice
                )
            );
        }
        insert entlList;

        for(Entitlement__c entl : entlList) {
            for(QuoteLineItem qli : qliList) {
                if(entl.Product__c == qli.Product2Id) {
                    qli.Entitlement__c = entl.Id;
                }
            }
        }

        update qliList;

        for(QuoteLineItem qli : qliList) {

            System.assertEquals(null, qli.Approved_Quantity__c);
            System.assertEquals(null, qli.Approved_Discount__c);
            System.assertEquals(null, qli.Approved_Discount_Type__c);
        }

        List<Quote> quotes = [SELECT Id, Approved_Status__c FROM Quote];
        // approve quote and verify approved discount, discountType and Quantity is saved
        if(quotes[0] != null) {
            Quote q = quotes[0];
            q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            update q;
        }

        qliList = [SELECT Id, Quantity, NewQuantity__c,
                Approved_Quantity__c, Approved_Discount__c, Approved_Discount_Type__c,
                Discount_type__c, Discount, Discount_Value__c, Product2Id,
                Product2.GOA_Group_V2__c, Quote.AccountId
            FROM QuoteLineItem];

        Test.startTest();
            for(QuoteLineItem qli : qliList) {
                System.assertEquals(qli.NewQuantity__c, qli.Approved_Quantity__c);
                System.assertEquals(qli.Discount_Value__c, qli.Approved_Discount__c);
                System.assertEquals(qli.Discount_type__c, qli.Approved_Discount_Type__c);
            }

            // set quote approved status as "required" and verify that approved... fields is cleared
            quotes = [SELECT Id, Approved_Status__c FROM Quote];
            // approve quote and verify approved discount, discountType and Quantity is saved
            if(quotes[0] != null) {
                Quote q = quotes[0];
                q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                update q;
            }

            qliList = [SELECT Id, Quantity, NewQuantity__c,
                    Approved_Quantity__c, Approved_Discount__c, Approved_Discount_Type__c,
                    Discount_type__c, Discount, Discount_Value__c, Product2.GOA_Group_V2__c
                FROM QuoteLineItem];

            for(QuoteLineItem qli : qliList) {

                System.assertEquals(null, qli.Approved_Quantity__c);
                System.assertEquals(null, qli.Approved_Discount__c);
                System.assertEquals(null, qli.Approved_Discount_Type__c);
            }
        Test.stopTest();
    }

    @isTest
    static void testQLIQuantityChange() {

        ApprovalNeededQualifiers anq = new ApprovalNeededQualifiers();

        ApprovalNeededQualifiers.ApprovalNeededChecker myChecker = new ApprovalNeededQualifiers.ApprovalNeededChecker();
        myChecker.addQualifier(null);


        ApprovalNeededQualifiers.QLIQuantityChangeQualifier quantityChangeQualifier = new ApprovalNeededQualifiers.QLIQuantityChangeQualifier();

        Map<Id, Boolean> quantityChangeResult = quantityChangeQualifier.checkNeedForApproval(null);
        System.assertNotEquals(null, quantityChangeResult);

        quantityChangeResult = quantityChangeQualifier.checkNeedForApproval(
            new List<QuoteLineItem>()
        );
        System.assertNotEquals(null, quantityChangeResult);


        // approve quote
        List<Quote> quotes = [SELECT Id, Approved_Status__c FROM Quote];
        if(quotes[0] != null) {
            Quote q = quotes[0];
            q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            update q;
        }

        List<QuoteLineItem> qliList = [SELECT Id, Quantity, NewQuantity__c, Approved_Quantity__c,
                Discount_type__c, Discount, Discount_Value__c, Entitlement__c, Product2.Name, Product2.GOA_Group_V2__c,
                Quote.Approved_Status__c
            FROM QuoteLineItem];

        // prepare localOldMap for testing
        Map<Id, QuoteLineItem> myOldMap = new Map<Id, QuoteLineItem>();

        for(QuoteLineItem item : qliList) {
            QuoteLineItem clonedItem = item.clone(true);
            myOldMap.put(clonedItem.Id, clonedItem);
        }

        Test.startTest();
            // set localOldMap for testing(available in tests only)
            quantityChangeQualifier.setLocalOldMap(myOldMap);

            for(QuoteLineItem item : qliList) {
                // change quantity on Allowed_Percentage_Quantity_Change__c(this should not require approval)
                item.Quantity += 1;
            }

            // perform test
            quantityChangeResult = quantityChangeQualifier.checkNeedForApproval(qliList);
            System.assertNotEquals(null, quantityChangeResult);

            // verify that approval not neede for this case(changes in Quantity <= Allowed Allowed_Percentage_Quantity_Change__c)
            for(Id qliId : quantityChangeResult.keySet()) {
                Boolean isApprovalNeeded = quantityChangeResult.get(qliId);
                System.assertEquals(false, isApprovalNeeded);
            }


            for(QuoteLineItem item : qliList) {
                // change quantity on more than Allowed_Percentage_Quantity_Change__c(this should require approval)
                item.Quantity += 2;
            }

            // perform test
            quantityChangeResult = quantityChangeQualifier.checkNeedForApproval(qliList);
            System.assertNotEquals(null, quantityChangeResult);

            // verify that approval not neede for this case(changes in Quantity <= Allowed Allowed_Percentage_Quantity_Change__c)
            for(Id qliId : quantityChangeResult.keySet()) {
                Boolean isApprovalNeeded = quantityChangeResult.get(qliId);
                System.assertEquals(true, isApprovalNeeded);
            }
        Test.stopTest();
    }

    @isTest
    static void testQLIQuantityChangeWithEntitlements() {

        ApprovalNeededQualifiers anq = new ApprovalNeededQualifiers();

        ApprovalNeededQualifiers.ApprovalNeededChecker myChecker = new ApprovalNeededQualifiers.ApprovalNeededChecker();
        myChecker.addQualifier(null);


        ApprovalNeededQualifiers.QLIQuantityChangeQualifier quantityChangeQualifier = new ApprovalNeededQualifiers.QLIQuantityChangeQualifier();

        Map<Id, Boolean> quantityChangeResult = quantityChangeQualifier.checkNeedForApproval(null);
        System.assertNotEquals(null, quantityChangeResult);

        quantityChangeResult = quantityChangeQualifier.checkNeedForApproval(
            new List<QuoteLineItem>()
        );
        System.assertNotEquals(null, quantityChangeResult);


        // approve quote
        List<Quote> quotes = [SELECT Id, Approved_Status__c FROM Quote];
        if(quotes[0] != null) {
            Quote q = quotes[0];
            q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            update q;
        }

        List<QuoteLineItem> qliList = [SELECT Id, Quantity, NewQuantity__c, UnitPrice,
                Approved_Quantity__c, Quote.AccountId, Discount_type__c, Discount,
                Discount_Value__c, Product2Id, Product2.Name, Product2.GOA_Group_V2__c, Quote.Approved_Status__c
            FROM QuoteLineItem];

        // add entitlements
        List<Entitlement__c> entlsList = new List<Entitlement__c>();
        for(QuoteLineItem item : qliList) {
            entlsList.add(
                new Entitlement__c(
                    Active__c = true,
                    Account__c = item.Quote.AccountId,
                    Product__c = item.Product2Id,
                    Discount__c = item.Discount,
                    Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Quantity__c = item.Quantity,
                    Price__c = item.UnitPrice
                )
            );
        }
        insert entlsList;

        for(QuoteLineItem item : qliList) {
            for(Entitlement__c entl : entlsList) {
                if(item.Product2Id == entl.Product__c) {
                    item.Entitlement__c = entl.Id;
                }
            }
        }
        update qliList;

        // prepare localOldMap for testing
        Map<Id, QuoteLineItem> myOldMap = new Map<Id, QuoteLineItem>();

        for(QuoteLineItem item : qliList) {
            QuoteLineItem clonedItem = item.clone(true);
            myOldMap.put(clonedItem.Id, clonedItem);
        }

        Test.startTest();
            // set localOldMap for testing(available in tests only)
            quantityChangeQualifier.setLocalOldMap(myOldMap);

            for(QuoteLineItem item : qliList) {
                // change quantity on Allowed_Percentage_Quantity_Change__c(this should not require approval)
                item.NewQuantity__c += 1;
            }

            // perform test
            quantityChangeResult = quantityChangeQualifier.checkNeedForApproval(qliList);
            System.assertNotEquals(null, quantityChangeResult);

            // verify that approval not neede for this case(changes in Quantity <= Allowed Allowed_Percentage_Quantity_Change__c)
            for(Id qliId : quantityChangeResult.keySet()) {
                Boolean isApprovalNeeded = quantityChangeResult.get(qliId);
                System.assertEquals(false, isApprovalNeeded);
            }


            for(QuoteLineItem item : qliList) {
                // change quantity on more than Allowed_Percentage_Quantity_Change__c(this should require approval)
                item.NewQuantity__c += 2;
            }

            // perform test
            quantityChangeResult = quantityChangeQualifier.checkNeedForApproval(qliList);
            System.assertNotEquals(null, quantityChangeResult);

            // verify that approval not neede for this case(changes in Quantity <= Allowed Allowed_Percentage_Quantity_Change__c)
            for(Id qliId : quantityChangeResult.keySet()) {
                Boolean isApprovalNeeded = quantityChangeResult.get(qliId);
                System.assertEquals(true, isApprovalNeeded);
            }
        Test.stopTest();
    }

    @isTest
    static void testQLIPercentageDiscountChangeWithEntitlements() {
        // currency on Entitlement, but Percentage on QLI

        ApprovalNeededQualifiers.CurrentDiscountsQualifier currentDiscountsQualifier = new ApprovalNeededQualifiers.CurrentDiscountsQualifier();

        Map<Id, Boolean> currentDiscountsResult = currentDiscountsQualifier.checkNeedForApproval(null);
        System.assertNotEquals(null, currentDiscountsResult);

        currentDiscountsResult = currentDiscountsQualifier.checkNeedForApproval(
            new List<QuoteLineItem>()
        );
        System.assertNotEquals(null, currentDiscountsResult);

        // approve quote
        List<Quote> quotes = [SELECT Id, Approved_Status__c FROM Quote];
        if(quotes[0] != null) {
            Quote q = quotes[0];
            q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            update q;
        }

        List<QuoteLineItem> qliList = [SELECT Id, Quantity, NewQuantity__c,
                Approved_Quantity__c, Quote.AccountId, Discount_type__c, Discount,
                Discount_Value__c, Product2Id, Product2.Name, Product2.GOA_Group_V2__c,
                UnitPrice, Entitlement__r.Discount_Type__c, Entitlement__r.Discount__c,
                Entitlement__r.Price__c
            FROM QuoteLineItem];

        // add entitlements(Discount type on entitlement should be differ with discount type on QLI)
        List<Entitlement__c> entlsList = new List<Entitlement__c>();
        for(QuoteLineItem item : qliList) {
            entlsList.add(
                new Entitlement__c(
                    Active__c = true,
                    Account__c = item.Quote.AccountId,
                    Product__c = item.Product2Id,
                    Discount__c = 60,
                    Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Quantity__c = item.Quantity,
                    Price__c = item.UnitPrice
                )
            );
        }
        insert entlsList;

        for(QuoteLineItem item : qliList) {
            for(Entitlement__c entl : entlsList) {
                if(item.Product2Id == entl.Product__c) {
                    item.Entitlement__c = entl.Id;
                }
            }
        }
        update qliList;

        Test.startTest();
            qliList = [SELECT Id, Quantity, NewQuantity__c, Product_Lic_Id__c, Quote.Package_Info__c,
                    Approved_Quantity__c, Quote.AccountId, Discount_type__c, Discount,
                    Discount_Value__c, Product2Id, Product2.Name, Product2.GOA_Group_V2__c,
                    UnitPrice, PackageCatalogId__c, PackageVersion__c, ChargeTerm__c, Charge_Term__c,
                    Entitlement__r.Discount_Type__c, Entitlement__r.Discount__c, Entitlement__r.Price__c,
                    Entitlement__r.PackageCatalogId__c, Entitlement__r.PackageVersion__c, Entitlement__r.ChargeTerm__c
                FROM QuoteLineItem];

            for(QuoteLineItem item : qliList) {
                // change DiscountType and Discount(set smaller than on Entitlement(we have 10% (or 10 USD price and 1 USD Disocunt)))
                item.Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
                item.Discount = 8;
            }

            // perform test
            currentDiscountsResult = currentDiscountsQualifier.checkNeedForApproval(qliList);
            System.assertNotEquals(null, currentDiscountsResult);

            // verify that approval not needed for this case(Discount value smaller than on Entitlement)
            for(Id qliId : currentDiscountsResult.keySet()) {
                Boolean isApprovalNeeded = currentDiscountsResult.get(qliId);
                System.assertEquals(false, isApprovalNeeded);
            }


            for(QuoteLineItem item : qliList) {
                // change DiscountType and Disocunt
                item.Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
                item.Discount = 110;
            }

            // perform test
            currentDiscountsResult = currentDiscountsQualifier.checkNeedForApproval(qliList);
            System.assertNotEquals(null, currentDiscountsResult);

            // verify that approval is needed for this case(Discount value bigger than on Entitlement)
            for(Id qliId : currentDiscountsResult.keySet()) {
                Boolean isApprovalNeeded = currentDiscountsResult.get(qliId);
                System.assertEquals(true, isApprovalNeeded);
            }

        Test.stopTest();
    }

    @isTest
    static void testQLICurrencyDiscountChangeWithEntitlements() {
        // Percentage on Entitlement, but Currency on QLI

        ApprovalNeededQualifiers.CurrentDiscountsQualifier currentDiscountsQualifier = new ApprovalNeededQualifiers.CurrentDiscountsQualifier();

        Map<Id, Boolean> currentDiscountsResult = currentDiscountsQualifier.checkNeedForApproval(null);
        System.assertNotEquals(null, currentDiscountsResult);

        currentDiscountsResult = currentDiscountsQualifier.checkNeedForApproval(
            new List<QuoteLineItem>()
        );
        System.assertNotEquals(null, currentDiscountsResult);

        // approve quote
        List<Quote> quotes = [SELECT Id, Approved_Status__c FROM Quote];
        if(quotes[0] != null) {
            Quote q = quotes[0];
            q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            update q;
        }

        List<QuoteLineItem> qliList = [SELECT Id, Quantity, NewQuantity__c,
                Approved_Quantity__c, Quote.AccountId, Discount_type__c, Discount,
                Discount_Value__c, Product2Id, Product2.Name, Product2.GOA_Group_V2__c,
                UnitPrice, Entitlement__r.Discount_Type__c, Entitlement__r.Discount__c,
                Entitlement__r.Price__c
            FROM QuoteLineItem];

        // add entitlements(Discount type on entitlement should be differ with discount type on QLI)
        List<Entitlement__c> entlsList = new List<Entitlement__c>();
        for(QuoteLineItem item : qliList) {
            entlsList.add(
                new Entitlement__c(
                    Active__c = true,
                    Account__c = item.Quote.AccountId,
                    Product__c = item.Product2Id,
                    Discount__c = 20,
                    Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                    Quantity__c = item.Quantity,
                    Price__c = item.UnitPrice
                )
            );
        }
        insert entlsList;

        for(QuoteLineItem item : qliList) {
            for(Entitlement__c entl : entlsList) {
                if(item.Product2Id == entl.Product__c) {
                    item.Entitlement__c = entl.Id;

                    // change DiscountType and Discount(set smaller than on Entitlement(we have 20% (or 10 USD price and 2 USD Disocunt)))
                    item.Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
                    item.Discount_number__c = 2;
                }
            }
        }

        Test.startTest();

            update qliList;

            qliList = [SELECT Id, Quantity, NewQuantity__c,
                    Approved_Quantity__c, Quote.AccountId, Discount_type__c, Discount, Product_Lic_Id__c,
                    Discount_Value__c, Product2Id, Product2.Name, Product2.GOA_Group_V2__c, Quote.Package_Info__c,
                    UnitPrice, PackageCatalogId__c, PackageVersion__c, ChargeTerm__c, Charge_Term__c,
                    Entitlement__r.Discount_Type__c, Entitlement__r.Discount__c, Entitlement__r.ChargeTerm__c,
                    Entitlement__r.Price__c, Entitlement__r.PackageCatalogId__c, Entitlement__r.PackageVersion__c
                FROM QuoteLineItem];

            // perform test
            currentDiscountsResult = currentDiscountsQualifier.checkNeedForApproval(qliList);
            System.assertNotEquals(null, currentDiscountsResult);

            // verify that approval not needed for this case(Discount value smaller than on Entitlement)
            for(Id qliId : currentDiscountsResult.keySet()) {
                Boolean isApprovalNeeded = currentDiscountsResult.get(qliId);
                System.assertEquals(false, isApprovalNeeded);
            }


            for(QuoteLineItem item : qliList) {
                // change DiscountType and Disocunt
                item.Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
                item.Discount_number__c = 400;
                item.Discount =  Math.abs((((item.UnitPrice - item.Discount_number__c) - item.UnitPrice) / item.UnitPrice) * 100);
            }

            // perform test
            currentDiscountsResult = currentDiscountsQualifier.checkNeedForApproval(qliList);
            System.assertNotEquals(null, currentDiscountsResult);

            // verify that approval is needed for this case(Discount value bigger than on Entitlement)
            for(Id qliId : currentDiscountsResult.keySet()) {
                Boolean isApprovalNeeded = currentDiscountsResult.get(qliId);
                System.assertEquals(true, isApprovalNeeded);
            }

        Test.stopTest();
    }

    @isTest
    static void testProServCurrentDiscountsQualifierBasic() {
        // ProServCurrentDiscountsQualifier should instantiate without errors and correct process nulls and empty lists

        ApprovalNeededQualifiers.ProServCurrentDiscountsQualifier proServCurrentDiscountsQualifier = new ApprovalNeededQualifiers.ProServCurrentDiscountsQualifier();

        Map<Id, Boolean> proServCurrentDiscountsResult = proServCurrentDiscountsQualifier.checkNeedForApproval(null);
        System.assertNotEquals(null, proServCurrentDiscountsResult);

        proServCurrentDiscountsResult = proServCurrentDiscountsQualifier.checkNeedForApproval(
            new List<QuoteLineItem>()
        );
        System.assertNotEquals(null, proServCurrentDiscountsResult);

        // test inner method(filterQLIToProcess)
        System.assertEquals(new List<QuoteLineItem>(), proServCurrentDiscountsQualifier.filterQLIToProcess(null));
        System.assertEquals(new List<QuoteLineItem>(), proServCurrentDiscountsQualifier.filterQLIToProcess(new List<QuoteLineItem>()));

        List<QuoteLineItem> qliList = [SELECT Id, Quantity,
                NewQuantity__c, Approved_Quantity__c, Approved_Discount__c,
                Approved_Discount_Type__c, Discount, Discount_Value__c,
                Discount_type__c, Quote.RecordTypeId, Product2.Name,
                Entitlement__c, Entitlement__r.Discount_Type__c,
                Entitlement__r.Discount__c, Entitlement__r.Price__c,
                Asset__c, Asset__r.Unit_Price__c, Asset__r.Discount_Type__c,
                Asset__r.Discount_Number__c
            FROM QuoteLineItem];

        System.assertEquals(
            new List<QuoteLineItem>(),
            proServCurrentDiscountsQualifier.filterQLIToProcess(qliList),
            'filterQLIToProcess should return qlis from ProServ or CCProServ quotes'
        );
    }

    @isTest
    static void testProServCurrentDiscountQualifierWithAsset() {

        // current discounts for changeOrder opportuinty stored as assets

        // prepare ChangeOrder Opportunity and Quote
        GOA_V2__c goaProServItem = new GOA_V2__c(
            Name = '2',
            Quantity_Range__c = '1-99999999',
            Contract_Initial_Term_Range__c = '',
            Sales_Rep__c = '0-10',
            Direct_Manager__c = '10.01-20.00',
            Segment_Leader__c = '20.01-30.00',
            SVP_WWS_Directs__c = '30.01-100.00',
            SVP_WWS__c = '0-0',
            Group__c = 'ProServ_Directs',
            Currency__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
            Allowed_Percentage_Quantity_Change__c = 10
        );
        insert new List<GOA_V2__c>{
            goaProServItem
        };

        Account testAccount = new Account(
            Name = 'Opty test account'
        );
        insert testAccount;

        Opportunity changeOrderOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'MyTest changeOrder Opportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Office',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert changeOrderOpp;

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Line_Range_Max__c = 10,
            CurrencyIsoCode = 'USD'
        );
        insert testPriceBook;

        Quote proServQuote = new Quote(
            Name = 'test ProServ Quote',
            Auto_Renewal__c = true,
            OpportunityId = changeOrderOpp.Id,
            Upsell_Status__c = QuoteHelper.STATUS_UPSELL,
            Pricebook2Id = testPriceBook.Id,
            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
            CurrencyIsoCode = 'USD'
        );
        insert proServQuote;

        List<Product2> prodList = new List<Product2>();

        Product2 testProduct = new Product2(
            Name = 'test proserv product',
            IsActive = true,
            Family = 'ProServ',
            Sub_Category__c = 'Professional Services',
            GOA_Group_V2__c = 'ProServ_Directs'
        );
        prodList.add(testProduct);
        insert prodList;

        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pbe;

        for(Product2 item : prodList) {

            pbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = item.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
            pbeList.add(pbe);

            pbe = new PricebookEntry(
                Pricebook2Id = proServQuote.Pricebook2Id,
                Product2Id = item.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                CurrencyIsoCode = 'USD'
            );
            pbeList.add(pbe);
        }
        insert pbeList;

        List<QuoteLineItem> proServQliList = new List<QuoteLineItem>();

        for(PricebookEntry item : pbeList) {

            if(item.PriceBook2Id == proServQuote.Pricebook2Id) {

                QuoteLineItem qli = new QuoteLineItem(
                    QuoteId = proServQuote.Id,
                    Product2Id = item.Product2Id,
                    Quantity = 20,
                    UnitPrice = item.UnitPrice,
                    Discount = 1,
                    Discount_number__c = 25,
                    Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                    PricebookEntryId = item.Id
                );
                proServQliList.add(qli);
            }
        }

        // prepare assets for proserv qli(set discount on asset equal to discount on qli)
        List<Asset> assetList = new List<Asset>();
        for(QuoteLineItem qli : proServQliList) {

            Asset assetRecord = new Asset(
                Name = qli.Product2Id + ' proserv asset',
                SOW_Type__c = 'ProServ',
                Discount_Type__c = qli.Discount_type__c,
                Discount_Number__c = qli.Discount_number__c,
                Unit_Price__c = qli.UnitPrice,
                Quantity = qli.Quantity,
                AccountId = testAccount.Id,
                Product2Id = qli.Product2Id,
                Total_Price__c = (qli.UnitPrice == null ? 0 : qli.UnitPrice) * qli.Quantity,
                Start_Date__c = Date.today(),
                Delivered_Quantity__c = qli.Quantity,
                Active__c = true
            );
            assetList.add(assetRecord);
        }
        insert assetList;

        for(Asset item : assetList) {
            for(QuoteLineItem qli : proServQliList) {
                if(qli.Product2Id == item.Product2Id) {
                    qli.Asset__c = item.Id;
                }
            }
        }

        Test.startTest();

            insert proServQliList;

            Set<Id> proservQliIdSet = new Set<Id>();
            for(QuoteLineItem qli : proServQliList) {
                proservQliIdSet.add(qli.Id);
            }

            ApprovalNeededQualifiers.ProServCurrentDiscountsQualifier proServCurrentDiscountsQualifier = new ApprovalNeededQualifiers.ProServCurrentDiscountsQualifier();

            List<QuoteLineItem> qliList = [SELECT Id, Quantity,
                    NewQuantity__c, Approved_Quantity__c, Approved_Discount__c,
                    Approved_Discount_Type__c, Discount, Discount_Value__c,
                    Discount_type__c, Quote.RecordTypeId, Product2.Name,
                    Entitlement__c, Entitlement__r.Discount_Type__c,
                    Entitlement__r.Discount__c, Entitlement__r.Price__c,
                    Asset__c, Asset__r.Unit_Price__c, Asset__r.Discount_Type__c,
                    Asset__r.Discount_Number__c
                FROM QuoteLineItem];

            System.assertEquals(
                proServQliList.size(),
                proServCurrentDiscountsQualifier.filterQLIToProcess(qliList).size(),
                'filterQLIToProcess should return qlis from ProServ or CCProServ quotes'
            );

            Map<Id, Boolean> proServCurrentDiscountsResult = proServCurrentDiscountsQualifier.checkNeedForApproval(qliList);

            System.assertEquals(
                proservQliIdSet,
                proServCurrentDiscountsResult.keySet(),
                'checkNeedForApproval should return results only for ProServ/CCProServ qlis'
            );

            for(Id proServQliId : proServCurrentDiscountsResult.keySet()) {
                // discount on asset equal to discount on qli - result should be false(do not use this qli to determine approvers)
                System.assertEquals(false, proServCurrentDiscountsResult.get(proServQliId));
            }

            // set discount on qli bigger than on asset
            for(QuoteLineItem proservQli : proServQliList) {
                proservQli.Discount_number__c = 50;
            }
            proServCurrentDiscountsResult = proServCurrentDiscountsQualifier.checkNeedForApproval(proServQliList);

            for(Id proServQliId : proServCurrentDiscountsResult.keySet()) {
                // discount on qli bigger than discount on asset - result should be true(use this qli to determine approvers)
                System.assertEquals(true, proServCurrentDiscountsResult.get(proServQliId));
            }
        Test.stopTest();
    }

    @isTest
    static void testApprovedFieldsOnContactCenterQliPopulation() {

        Quote salesQuote = [SELECT Id, AccountId, OpportunityId, Pricebook2Id FROM Quote LIMIT 1];
        Triggers.switchOff();
        update new Account(
            Id = salesQuote.AccountId,
            Billing_ID__c = '111',
            RC_User_ID__c = '111'
        );

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Package__c.Account__c => salesQuote.AccountId,
                    Package__c.Account_Package_Id__c => '1231231231'
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();
        // prepare contact center quote with quote line items
        Quote contactCenterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'testContactCenterQuote',
                Quote.OpportunityId => salesQuote.OpportunityId,
                Quote.RecordTypeId => QuoteHelper.RT_ID_CC,
                Quote.Pricebook2Id => salesQuote.Pricebook2Id,
                Quote.BillingPackage__c => pkg.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Auto_Renewal__c => true
            })
            .create()
            .getRecord();

        List<PricebookEntry> pbeList = [SELECT Id, Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2Id = :salesQuote.Pricebook2Id];

        List<QuoteLineItem> ccQliList = new List<QuoteLineItem>();

        for(PricebookEntry pbe : pbeList) {
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = contactCenterQuote.Id,
                Product2Id = pbe.Product2Id,
                Quantity = 20,
                UnitPrice = pbe.UnitPrice,
                Discount = 1,
                Discount_number__c = 1,
                PricebookEntryId = pbe.Id
            );
            ccQliList.add(qli);
        }
        Triggers.switchOff();
        insert ccQliList;
        Triggers.switchOn();


        Test.startTest();

            List<QuoteLineItem> qliList = [SELECT Id, Quantity, NewQuantity__c,
                    Approved_Quantity__c, Approved_Discount__c, Approved_Discount_Type__c,
                    Discount_type__c, Discount, Discount_Value__c, Product2.GOA_Group_V2__c
                FROM QuoteLineItem
                WHERE QuoteId = :contactCenterQuote.Id];

            for(QuoteLineItem qli : qliList) {
                Assert.isNull(qli.Approved_Quantity__c, 'Should be null');
                Assert.isNull(qli.Approved_Discount__c, 'Should be null');
                Assert.isNull(qli.Approved_Discount_Type__c, 'Should be null');
            }

            // approve quote and verify approved discount, discountType and Quantity is saved
            contactCenterQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            update contactCenterQuote;

            qliList = [SELECT Id, Quantity, NewQuantity__c, Approved_Quantity__c,
                    Approved_Discount__c, Approved_Discount_Type__c, Discount_type__c,
                    Discount, Discount_Value__c, Product2.GOA_Group_V2__c
                FROM QuoteLineItem
                WHERE QuoteId = :contactCenterQuote.Id];

            for(QuoteLineItem qli : qliList) {
                Assert.areEqual(
                    qli.Quantity,
                    qli.Approved_Quantity__c,
                    'Approved_Quantity__c field should hold value from Quantity field if Quote got status Approved'
                );
                Assert.areEqual(
                    qli.Discount_Value__c,
                    qli.Approved_Discount__c,
                    'Approved_Discount__c field should hold value from Discount_Value__c field if Quote got status Approved'
                );
                Assert.areEqual(
                    qli.Discount_type__c,
                    qli.Approved_Discount_Type__c,
                    'Approved_Discount_Type__c field should hold value from Discount_type__c field if Quote got status Approved'
                );
            }
        Test.stopTest();
    }

    @isTest
    static void testLastApprovedFieldsOnQliPopulation() {

        List<QuoteLineItem> qliList = [SELECT Id, Quantity, NewQuantity__c,
                Last_Approved_Quantity__c, Last_Approved_Discount__c, Last_Approved_Discount_Type__c,
                Discount_type__c, Discount, Discount_Value__c, Product2.GOA_Group_V2__c
            FROM QuoteLineItem];

        for(QuoteLineItem qli : qliList) {

            System.assertEquals(null, qli.Last_Approved_Quantity__c);
            System.assertEquals(null, qli.Last_Approved_Discount__c);
            System.assertEquals(null, qli.Last_Approved_Discount_Type__c);
        }

        List<Quote> quotes = [SELECT Id, Approved_Status__c FROM Quote];
        // approve quote and verify approved discount, discountType and Quantity is saved
        if(quotes[0] != null) {
            Quote q = quotes[0];
            q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            update q;
        }

        qliList = [SELECT Id, Quantity, NewQuantity__c,
                Last_Approved_Quantity__c, Last_Approved_Discount__c, Last_Approved_Discount_Type__c,
                Discount_type__c, Discount, Discount_Value__c, Product2.GOA_Group_V2__c
            FROM QuoteLineItem];

        Test.startTest();
            for(QuoteLineItem qli : qliList) {

                System.assertEquals(qli.Quantity, qli.Last_Approved_Quantity__c);
                System.assertEquals(qli.Discount_Value__c, qli.Last_Approved_Discount__c);
                System.assertEquals(qli.Discount_type__c, qli.Last_Approved_Discount_Type__c);
            }
        Test.stopTest();
    }


    private static Quote createTestBillingQuote() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        acc.Billing_ID__c = '111';
        acc.RC_User_ID__c = '111';
        update acc;
        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Is_Billing_Opportunity__c => true,
                    Opportunity.Name => 'TestBillingOpportunity',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                })
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Package__c.Account__c => acc.Id,
                    Package__c.Account_Package_Id__c => '1231231231'
                }
            )
            .create()
            .getRecord();

        Quote testBillingQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.BillingPackage__c => pkg.Id,
                    Quote.Package_Info__c => '[{"id":"5","version":"3","packageInfo":{"catalogId":"5","version":"3","name":"Office Standard 1/2/20/100+ Lines - 4500/4480/4511/4512/4461/4462/4463/4464/4800/4780/4811/4812"},"productName":"Office","duration":"Monthly","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null}]'
                })
            .create()
            .getRecord();

        return testBillingQuote;
    }

    @isTest
    static void testApprovedFieldsOnQliPopulationBilling() {

        Quote testBillingQuote = createTestBillingQuote();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'test product for billing',
                Product2.IsActive => true,
                Product2.Sub_Category__c => 'Main',
                Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Test.startTest();
            Triggers.switchOff();
            QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    QuoteLineItem.QuoteId => testBillingQuote.Id,
                    QuoteLineItem.Product2Id => pbe.Product2Id,
                    QuoteLineItem.Quantity => 20,
                    QuoteLineItem.UnitPrice => 200,
                    QuoteLineItem.Discount_number__c => 5,
                    QuoteLineItem.PricebookEntryId => pbe.Id
                })
                .create()
                .getRecord();
            Triggers.switchOn();

            List<QuoteLineItem> qliList = new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .selectFields(new List<Schema.SObjectField> {
                    QuoteLineItem.Approved_Quantity__c,
                    QuoteLineItem.Approved_Discount__c,
                    QuoteLineItem.Approved_Discount_Type__c
                })
                .setCondition('QuoteId = \'' + testBillingQuote.Id + '\'')
                .executeQuery();

            for (QuoteLineItem item : qliList) {
                Assert.isNull(
                    item.Approved_Quantity__c,
                    'Approved_Quantity__c field should be emtpy on fresh created Quote'
                );
                Assert.isNull(
                    item.Approved_Discount__c,
                    'Approved_Discount__c field should be emtpy on fresh created Quote'
                );
                Assert.isNull(
                    item.Approved_Discount_Type__c,
                    'Approved_Discount_Type__c field should be emtpy on fresh created Quote'
                );
            }

            // approve quote
            testBillingQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            update testBillingQuote;

            qliList = new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .selectFields(new List<Schema.SObjectField> {
                    QuoteLineItem.Approved_Quantity__c,
                    QuoteLineItem.Approved_Discount__c,
                    QuoteLineItem.Approved_Discount_Type__c,
                    QuoteLineItem.Quantity,
                    QuoteLineItem.Discount_Value__c,
                    QuoteLineItem.Discount_type__c
                })
                .setCondition('QuoteId = \'' + testBillingQuote.Id + '\'')
                .executeQuery();

            for(QuoteLineItem item : qliList) {
                Assert.areEqual(
                    item.Quantity,
                    item.Approved_Quantity__c,
                    'Approved_Quantity__c field should hold value from Quantity field if Quote got status Approved'
                );
                Assert.areEqual(
                    item.Discount_Value__c,
                    item.Approved_Discount__c,
                    'Approved_Discount__c field should hold value from Discount_Value__c field if Quote got status Approved'
                );
                Assert.areEqual(
                    item.Discount_type__c,
                    item.Approved_Discount_Type__c,
                    'Approved_Discount_Type__c field should hold value from Discount_type__c field if Quote got status Approved'
                );
            }

            // make Quote required
            testBillingQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
            update testBillingQuote;

            qliList = new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .selectFields(new List<Schema.SObjectField> {
                    QuoteLineItem.Approved_Quantity__c,
                    QuoteLineItem.Approved_Discount__c,
                    QuoteLineItem.Approved_Discount_Type__c
                })
                .setCondition('QuoteId = \'' + testBillingQuote.Id + '\'')
                .executeQuery();

            for(QuoteLineItem item : qliList) {
                Assert.isNull(
                    item.Approved_Quantity__c,
                    'Approved_Quantity__c field should be empty if Quote got status Required'
                );
                Assert.isNull(
                    item.Approved_Discount__c,
                    'Approved_Discount__c field should be empty if Quote got status Required'
                );
                Assert.isNull(
                    item.Approved_Discount_Type__c,
                    'Approved_Discount_Type__c field should be empty if Quote got status Required'
                );
            }
        Test.stopTest();
    }


    @isTest
    static void testQLIQuantityChangeBilling() {

        Quote testBillingQuote = createTestBillingQuote();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => 'test product for billing',
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => 'Main',
                    Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                }
            )
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 200,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.Per_Line__c => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                })
            .create()
            .getRecord();

        Test.startTest();

            QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.QuoteId => testBillingQuote.Id,
                        QuoteLineItem.Product2Id => pbe.Product2Id,
                        QuoteLineItem.Quantity => 20,
                        QuoteLineItem.UnitPrice => 200,
                        QuoteLineItem.Discount_number__c => 5,
                        QuoteLineItem.PricebookEntryId => pbe.Id
                    })
                .create()
                .getRecord();

            ApprovalNeededQualifiers.QLIQuantityChangeQualifier quantityChangeQualifier = new ApprovalNeededQualifiers.QLIQuantityChangeQualifier();

            // approve quote
            testBillingQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            update testBillingQuote;

            List<QuoteLineItem> qliList = new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .selectFields(new List<Schema.SObjectField> {
                    QuoteLineItem.Quantity,
                    QuoteLineItem.NewQuantity__c,
                    QuoteLineItem.Discount_type__c,
                    QuoteLineItem.Discount_Value__c,
                    QuoteLineItem.Approved_Quantity__c,
                    QuoteLineItem.Approved_Discount__c,
                    QuoteLineItem.Approved_Discount_Type__c
                })
                .selectFields(new List<String>{
                    'Product2.Name',
                    'Product2.GOA_Group_V2__c',
                    'Quote.Approved_Status__c'
                })
                .setCondition('QuoteId = \'' + testBillingQuote.Id + '\'')
                .executeQuery();

            // prepare localOldMap for testing
            Map<Id, QuoteLineItem> myOldMap = new Map<Id, QuoteLineItem>();

            for(QuoteLineItem item : qliList) {
                QuoteLineItem clonedItem = item.clone(true);
                myOldMap.put(clonedItem.Id, clonedItem);
            }

            // set localOldMap for testing(available in tests only)
            quantityChangeQualifier.setLocalOldMap(myOldMap);

            for(QuoteLineItem item : qliList) {
                // change quantity on GOA_V2__c.Allowed_Percentage_Quantity_Change__c(this should not require approval)
                item.Quantity += 1;
            }

            // perform test
            Map<Id, Boolean> quantityChangeResult = quantityChangeQualifier.checkNeedForApproval(qliList);
            System.assertNotEquals(
                null,
                quantityChangeResult,
                'ApprovalNeededQualifiers.QLIQuantityChangeQualifier.checkNeedForApproval method should not return null'
            );

            for(Id qliId : quantityChangeResult.keySet()) {
                Boolean isApprovalNeeded = quantityChangeResult.get(qliId);
                System.assertEquals(
                    false,
                    isApprovalNeeded,
                    'Approval not needed for this case ' +
                    '(changes in Quantity <= Allowed Allowed_Percentage_Quantity_Change__c)'
                );
            }


            for(QuoteLineItem item : qliList) {
                // change quantity on more than Allowed_Percentage_Quantity_Change__c(this should require approval)
                item.Quantity += 2;
            }

            // perform test
            quantityChangeResult = quantityChangeQualifier.checkNeedForApproval(qliList);
            System.assertNotEquals(
                null,
                quantityChangeResult,
                'ApprovalNeededQualifiers.QLIQuantityChangeQualifier.checkNeedForApproval method should not return null'
            );

            for(Id qliId : quantityChangeResult.keySet()) {
                Boolean isApprovalNeeded = quantityChangeResult.get(qliId);
                System.assertEquals(
                    true,
                    isApprovalNeeded,
                    'Approval needed for this case' +
                    '(changes in Quantity <= Allowed Allowed_Percentage_Quantity_Change__c)'
                );
            }
        Test.stopTest();
    }

    @isTest
    static void testCheckOfficeEESQliMovedToCC() {
        String quotePackageInfo = '[{"id":"1956","version":"2","packageInfo":{"id":81591013,"catalogId":"1956","version":"2","name":"RingCentral MVP Premium - Global Unlimited",'
            + '"displayName":"RingCentral MVP Premium - Global Unlimited","oldPackageName":"RingCentral MVP Premium - Global Unlimited"},"productName":"Office",'
            + '"existingPackageInfo":{"id":"1956","version":"2","offerType":"Regular","productName":"Office"}},{"id":"803","version":"2","packageInfo":{"id":84421013,"catalogId":"803",'
            + '"version":"2","name":"Premium Edition (3 ports) Named Seat (USD)","displayName":"Premium Edition (3 ports) Named Seat (USD)","oldPackageName":"Migrated Legacy (USD)"},'
            + '"productName":"RingCentral Contact Center","productId":"22","existingPackageInfo":{"id":"880","version":"1","productName":"RingCentral Contact Center"}}]';

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Package_Info__c => quotePackageInfo
                }
            )
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String> {
                        QuoteLineItemHelper.RCCC_EES_BRONZE,
                        QuoteLineItemHelper.CC_EES_BRONZE
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbes = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(products),
                    PricebookEntry.UnitPrice => 100,
                    PricebookEntry.IsActive => true
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.UnitPrice => 100,
                    QuoteLineItem.ServiceName__c => ValueProviderBuilder.provideList(new List<String> {QuoteHelper.NGBS_RCCC_PRODUCT, QuoteHelper.NGBS_OFFICE_PRODUCT}),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbes),
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.Discount_number__c => 50
                }
            )
            .quantity(2)
            .create()
            .getRecords();


        List<QuoteLineItem> officeQlis = [
            SELECT Id, Product2Id, Product_Lic_Id__c, Discount_number__c, UnitPrice, Quote.AccountId, Quantity
            FROM QuoteLineItem
            WHERE ServiceName__c =:QuoteHelper.NGBS_OFFICE_PRODUCT
        ];

        Entitlement__c entl = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Account__c => officeQlis.get(0).Quote.AccountId,
                    Entitlement__c.Product__c => officeQlis.get(0).Product2Id,
                    Entitlement__c.Discount__c => officeQlis.get(0).Discount_number__c,
                    Entitlement__c.Quantity__c => officeQlis.get(0).Quantity,
                    Entitlement__c.Price__c => officeQlis.get(0).UnitPrice
                }
            )
            .create()
            .getRecord();

        for(QuoteLineItem qli : officeQlis) {
            qli.Entitlement__c = entl.Id;
        }

        update officeQlis;

        List<QuoteLineItem> reselectedQlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(
                new Set<String>{
                    'Quote.Package_Info__c',
                    'ServiceName__c',
                    'Product_Lic_Id__c',
                    'Discount_number__c',
                    'Entitlement__r.Discount__c'
                }
            )
            .executeQuery();
        for (QuoteLineItem item : reselectedQlis) {
            item.Quote.Package_Info__c = quotePackageInfo;
        }

        List<QuoteLineItem> rcccQlis = [SELECT Id FROM QuoteLineItem WHERE ServiceName__c =:QuoteHelper.NGBS_RCCC_PRODUCT];
        Map<Id, Boolean> qliIdToNeededToApprove = new Map<Id, Boolean>();
        qliIdToNeededToApprove.put(rcccQlis.get(0).Id, true);

        ApprovalNeededQualifiers.CurrentDiscountsQualifier currentDiscountsQualifier = new ApprovalNeededQualifiers.CurrentDiscountsQualifier();

        Map<Id, Boolean> qliIdNeededToApproval = currentDiscountsQualifier.checkOfficeEESQliMovedToCC(reselectedQlis, qliIdToNeededToApprove);
        Test.stopTest();

        Assert.areEqual(qliIdNeededToApproval.get(rcccQlis.get(0).Id), false, 'Qli was not skipped from approval');
    }
}