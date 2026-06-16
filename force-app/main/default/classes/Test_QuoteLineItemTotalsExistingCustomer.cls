@isTest
private class Test_QuoteLineItemTotalsExistingCustomer {

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

    @testSetup
    static void setup() {

        Account testAccnt = new Account(
            Name = 'test account',
            RC_User_ID__c = '665588994477222114'
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
    static void testPopulateQLITotalsOnQLIInsert() {

        Quote testSalesQuote = [SELECT Id, AccountId, Pricebook2Id FROM Quote LIMIT 1];

        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry];

        List<Entitlement__c> entlsList = [SELECT Id, DisplayQuantity__c, EffectivePrice__c,
                Price__c, Product__c, Product__r.Charge_Term__c
            FROM Entitlement__c
            WHERE Account__c = :testSalesQuote.AccountId];

        Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
        for(Entitlement__c entl : entlsList) {
            productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
        }

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
                    Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c = productIdToEntitlementIdMap.get(pbe.Product2Id)
                );

                qliList.add(qli);
            }
        }

        Test.startTest();

            insert qliList;

        Test.stopTest();

        List<QuoteLineItem> reselectedQliList = [SELECT Id, Total_Annual__c,
                Total_Monthly__c, Total_One_Time__c, Delta_MRR__c, Delta_ARR__c,
                Zero_Quantity__c, Quantity, NewQuantity__c, Entitlement__c, EffectivePriceNew__c,
                Product2Id, Product2.Charge_Term__c, QuoteRecordType__c, Product2.Name,
                Entitlement__r.DisplayQuantity__c, Entitlement__r.EffectivePrice__c,
                Entitlement__r.Product__c, Entitlement__r.Product__r.Charge_Term__c
            FROM QuoteLineItem
            WHERE QuoteId = :testSalesQuote.Id];

        for(QuoteLineItem qli : reselectedQliList) {

            Decimal calculatedDeltaMrr = 0;
            Decimal calculatedDeltaArr = 0;
            Decimal totalOneTime = 0;

            String qliChargeTerm = qli.Product2.Charge_Term__c;
            String entlChargeTerm = qli.Entitlement__r.Product__r.Charge_Term__c;

            if(qliChargeTerm != Product2Helper.CHARGE_TERM_ANNUAL && entlChargeTerm != Product2Helper.CHARGE_TERM_ANNUAL) {

                calculatedDeltaMrr += (((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) -
                    (qli.Entitlement__r.DisplayQuantity__c * qli.Entitlement__r.EffectivePrice__c));

                calculatedDeltaArr += ((((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) * 12) -
                    ((qli.Entitlement__r.DisplayQuantity__c * qli.Entitlement__r.EffectivePrice__c) * 12));

            }else if(qliChargeTerm != Product2Helper.CHARGE_TERM_ANNUAL && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {

                calculatedDeltaMrr += (((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) -
                    ((qli.Entitlement__r.DisplayQuantity__c * qli.Entitlement__r.EffectivePrice__c) / 12));

                calculatedDeltaArr += ((((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) * 12) -
                    (qli.Entitlement__r.DisplayQuantity__c * qli.Entitlement__r.EffectivePrice__c));

            }else if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {

                calculatedDeltaMrr += ((((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) / 12) -
                    ((qli.Entitlement__r.DisplayQuantity__c * qli.Entitlement__r.EffectivePrice__c) / 12));

                calculatedDeltaArr += (((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) -
                    (qli.Entitlement__r.DisplayQuantity__c * qli.Entitlement__r.EffectivePrice__c));

            }else if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {

                calculatedDeltaMrr += ((((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) / 12) -
                    (qli.Entitlement__r.DisplayQuantity__c * qli.Entitlement__r.EffectivePrice__c));

                calculatedDeltaArr += (((qli.Quantity + qli.Entitlement__r.DisplayQuantity__c) * qli.EffectivePriceNew__c) -
                    ((qli.Entitlement__r.DisplayQuantity__c * qli.Entitlement__r.EffectivePrice__c) * 12));
            }

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                calculatedDeltaMrr = 0;
                calculatedDeltaArr = 0;
                totalOneTime = QuoteLineItemHelper.getQuantity(qli) * qli.EffectivePriceNew__c;
            }

            System.assertNotEquals(null, qli.Total_Annual__c);
            System.assertNotEquals(null, qli.Total_Monthly__c);
            System.assertNotEquals(null, qli.Total_One_Time__c);
            System.assertEquals(totalOneTime, qli.Total_One_Time__c);
            System.assertNotEquals(null, qli.Delta_MRR__c);
            System.assertEquals(calculatedDeltaMrr, qli.Delta_MRR__c);
            System.assertNotEquals(null, qli.Delta_ARR__c);
            System.assertEquals(calculatedDeltaArr, qli.Delta_ARR__c);
        }
    }

    @isTest
    static void testPopulateQLITotalOneTimeOnTrialAcc() {

        Quote testSalesQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectFields(new List<String>{'Id', 'AccountId', 'Pricebook2Id'})
            .executeQuery()
            .get(0);

        update new Account(
            Id = testSalesQuote.AccountId,
            RC_Account_Status__c = AccountHelper.ACCOUNT_STATUS_TRIAL
        );

        List<String> pbeFieldsToQuery = new List<String> {
            'Id',
            'Pricebook2Id',
            'Product2Id',
            'Product2.Charge_Term__c',
            'UnitPrice'
        };

        List<PricebookEntry> pbeList = new PricebookEntrySelector()
            .getAllPBEs()
            .selectFields(pbeFieldsToQuery)
            .executeQuery();

        List<String> entFieldsToQuery = new List<String> {
            'Id',
            'DisplayQuantity__c',
            'EffectivePrice__c',
            'Price__c',
            'Product__c',
            'Product__r.Charge_Term__c'
        };

        List<Entitlement__c> entlsList = new EntitlementSelector()
            .selectActiveEntitlementsForAccount(new List<Object>{new List<Id>{testSalesQuote.AccountId}})
            .selectFields(entFieldsToQuery)
            .executeQuery();

        Map<Id, Id> productIdToEntitlementIdMap = new Map<Id, Id>();
        for(Entitlement__c entl : entlsList) {
            productIdToEntitlementIdMap.put(entl.Product__c, entl.Id);
        }

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();

        for(PricebookEntry pbe : pbeList) {
            if(
                pbe.Pricebook2Id == testSalesQuote.Pricebook2Id
                && Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(pbe.Product2.Charge_Term__c)
            ) {
                qliList.add((QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                            .setFields(
                                new Map<SObjectField, Object> {
                                    QuoteLineItem.Product2Id => pbe.Product2Id,
                                    QuoteLineItem.PricebookEntryId => pbe.Id,
                                    QuoteLineItem.QuoteId => testSalesQuote.Id,
                                    QuoteLineItem.Quantity => 5,
                                    QuoteLineItem.Zero_Quantity__c => false,
                                    QuoteLineItem.UnitPrice => pbe.UnitPrice,
                                    QuoteLineItem.Discount_number__c => 2,
                                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                                    QuoteLineItem.Entitlement__c => productIdToEntitlementIdMap.get(pbe.Product2Id)
                                })
                            .build()
                            .getRecord());
            }
        }

        Test.startTest();
            insert qliList;
        Test.stopTest();

        List<QuoteLineItem> reselectedQliList = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(testSalesQuote.Id)
            .executeQuery();

        for(QuoteLineItem qli : reselectedQliList) {
            Decimal totalOneTime = 0;
            String qliChargeTerm = qli.Product2.Charge_Term__c;

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                totalOneTime = qli.NewQuantity__c * qli.EffectivePriceNew__c;
            }

            System.assertNotEquals(null, qli.Total_One_Time__c);
            System.assertEquals(totalOneTime, qli.Total_One_Time__c);
        }
    }
}