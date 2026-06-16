@isTest
private class Test_QuoteHelper {

    private static final String PACKAGE_INFO_WITH_CONTRACT =
        '[{"id":"18","contract":{"id":"a8f0S0000008cxHQAQ","extId":"Office","billingId":"2"}}]';
    private static final String PACKAGE_INFO_ENGAGE =
        '[{"id":"18","version":"1","productName":"Office","productId":"6"}]';
    private static final String PACKAGE_INFO_ENGAGE_OMNI =
        '[{"id":"18","version":"1","productName":"Engage","productId":"11"}]';
    private static final Id SYSTEM_ADMIN_PROFILE_ID =
        [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id;
    private static final String PACKAGE_NAME_OLD = 'Old package name';
    private static final String BILLING_ID = 'BILLING_ID';
    private static final String RC_USER_ID = 'RC_USER_ID';

    private static Quote putAccIntoQuote(Quote qt, Account acc) {
        return (Quote) Test_Utils.putIntoUnwritableField(qt, Quote.class, 'Account', acc);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_get_plan() {

        // For old Quote
        Opportunity testOpp1 = TestDataGenerator.createOpportunity(null);
        PriceBook2 testPB2 = TestDataGenerator.createPricebook2();
                   testPB2.Plan__c = 'Monthly';
        update testPB2;
        Quote testQuote1 = TestDataGenerator.createQuote(testOpp1, testPB2);
              testQuote1.RecordTypeId = TestDataGenerator.getQuoteRecordTypeIdByName('Sales_Quote');

        // For New Billing Quote
        Test.startTest();

        Opportunity testOpp2 = TestDataGenerator.createOpportunity(null);
        Quote testQuote2 = TestDataGenerator.createQuote(testOpp2);
              testQuote2.RecordTypeId = TestDataGenerator.getQuoteRecordTypeIdByName('Sales_Quote_v2');
              testQuote2.Package_Info__c = TestDataGenerator.getPackageInfoStr('1', '1', 'Annual');


        String plan1 = QuoteHelper.getPlan(testQuote1);
        String plan2 = QuoteHelper.getPlan(testQuote2);

        Test.stopTest();

        // System.assertEquals('Monthly', plan1);
        // System.assertEquals('Annual', plan2);
    }

    @isTest static void test_get_plan_withEmptyPlanOnPricebook() {

        // For old Quote
        Opportunity testOpp1 = TestDataGenerator.createOpportunity(null);
        PriceBook2 testPB2 = TestDataGenerator.createPricebook2();
        testPB2.Plan__c = null;
        update testPB2;

        Quote testQuote1 = TestDataGenerator.createQuote(testOpp1, testPB2);
        testQuote1.RecordTypeId = TestDataGenerator.getQuoteRecordTypeIdByName('Sales_Quote');
        testQuote1.Payment_Plan__c = 'Monthly';

        // For New Billing Quote
        test.startTest();

        Opportunity testOpp2 = TestDataGenerator.createOpportunity(null);
        Quote testQuote2 = TestDataGenerator.createQuote(testOpp2);
        testQuote2.RecordTypeId = TestDataGenerator.getQuoteRecordTypeIdByName('Sales_Quote_v2');
        testQuote2.Payment_Plan__c = 'Annual';

        // if Pricebook2.Plan__c is empty(or Package_Info__c is empty for Sales_Quote_v2) - QuoteHelper.getPlan
        // method should take value from Quote.Payment_Plan__c
        String plan1 = QuoteHelper.getPlan(testQuote1);
        String plan2 = QuoteHelper.getPlan(testQuote2);

        test.stopTest();

        System.assertEquals('Monthly', plan1);
        System.assertEquals('Annual', plan2);
    }

    @isTest static void test_isSamePrice_without_qli() {
        // Creating test data
        SObjectBuilder accBuilder = new SObjectBuilder(Account.SObjectType)
                                    .setField(Account.Name, 'Test Account 1')
                                    .create();
        SObjectBuilder oppBuilder = new SObjectBuilder(Opportunity.SObjectType)
                                    .setField(Opportunity.AccountId, accBuilder.getRecord().get(Account.Id))
                                    .setField(Opportunity.Name, 'Test Oppty 1')
                                    .setField(Opportunity.Type, 'New Business')
                                    .setField(Opportunity.Brand_Name__c, 'RingCentral')
                                    .setField(Opportunity.Tier_Name__c, 'Professional')
                                    .setField(Opportunity.StageName, '1. Qualify')
                                    .setField(Opportunity.CloseDate, System.today())
                                    .setField(Opportunity.CurrencyIsoCode, 'USD')
                                    .create();
        SObjectBuilder priceBook2Builder = new SObjectBuilder(Pricebook2.SObjectType)
                                    .setField(Pricebook2.Name, 'Test Price Book')
                                    .setField(Pricebook2.Description,'Test Price Book Products')
                                    .setField(Pricebook2.IsActive, true)
                                    .setField(Pricebook2.Line_Range_Min__c, 1)
                                    .setField(Pricebook2.Line_Range_Max__c, 50)
                                    .setField(Pricebook2.CurrencyIsoCode, 'USD')
                                    .setField(Pricebook2.Service__c, 'Office')
                                    .setField(Pricebook2.Plan__c, 'Annual')
                                    .create();
        SObjectBuilder quoteBuilder = new SObjectBuilder(Quote.SObjectType)
                                    .setField(Quote.Name, 'Test Quote 1')
                                    .setField(Quote.OpportunityId, oppBuilder.getRecord().get(Opportunity.Id))
                                    .setField(Quote.Status, 'Draft')
                                    .setField(Quote.Approved_Status__c, 'Approved')
                                    .setField(Quote.Start_Date__c, Date.today())
                                    .setField(Quote.End_Date__c, Date.today().addDays(2))
                                    .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
                                    .create();

        Boolean isSamePriceResult = QuoteHelper.isSamePrice((Quote)quoteBuilder.getRecord());

        System.assert(isSamePriceResult, 'Result of isSamePrice method should be true if Quote no have QLIs or Active Service Plan.');
    }

    @isTest static void test_is_new_billing_quote() {

        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        Quote testQuote1 = TestDataGenerator.createQuote(testOpp);
              testQuote1.RecordTypeId = TestDataGenerator.getQuoteRecordTypeIdByName('Sales_Quote');
        Quote testQuote2 = TestDataGenerator.createQuote(testOpp);
              testQuote2.RecordTypeId = TestDataGenerator.getQuoteRecordTypeIdByName('Sales_Quote_v2');

        Boolean result1 = QuoteHelper.isNewBillingQuote(testQuote1);
        Boolean result2 = QuoteHelper.isNewBillingQuote(testQuote2);

        System.assertEquals(false, result1);
        System.assertEquals(true, result2);
    }

    @isTest static void test_create_serviceInfo_with_empty_package() {
        Account testAcc = TestDataGenerator.createAccount('TestAcc', null);
        Opportunity testOpp = TestDataGenerator.createOpportunity(testAcc);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);
              testQuote.RecordTypeId = TestDataGenerator.getQuoteRecordTypeIdByName('Sales_Quote_v2');

        Test.startTest();
            QuoteHelper.syncServiceInfo(testQuote.Id, new Map<String, Boolean>());
            List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new ServiceInfoSelector()
                .selectServiceInfoForClone(new List<Object>{ testQuote.Id })
                .executeQuery();
            System.assertEquals(serviceInfos[0].BillingPackage__c, null);
        Test.stopTest();
    }

    @isTest static void test_get_duration_from_package_info() {
        String pInfoJson_check_null_2 = '[{"contract":{"id":"' + HardcodedIdsMapper.getMatchedObjectId('a8fc0000000MEYDAA4') + '"}}]';
        String pInfoJson_check_annual = '[{"duration":"Annual"}]';
        String pInfoJson_check_monthly = '[{"duration":"Monthly"}]';
        String pInfoJson_check_annual_contract = '[{"duration":"Annual","contract":{"id":"' + HardcodedIdsMapper.getMatchedObjectId('a8fc0000000MEYDAA4') + '"}}]';
        String pInfoJson_check_monthly_contract = '[{"duration":"Monthly","contract":{"id":"' + HardcodedIdsMapper.getMatchedObjectId('a8fc0000000MEYDAA4') + '"}}]';


        QuoteHelper.PackageInfo pInfo_check_null_1 = null;
        QuoteHelper.PackageInfo pInfo_check_null_2 = QuoteHelper.getPackageInfo(pInfoJson_check_null_2).get(0);
        QuoteHelper.PackageInfo pInfo_check_annual = QuoteHelper.getPackageInfo(pInfoJson_check_annual).get(0);
        QuoteHelper.PackageInfo pInfo_check_monthly = QuoteHelper.getPackageInfo(pInfoJson_check_monthly).get(0);
        QuoteHelper.PackageInfo pInfo_check_annual_contract = QuoteHelper.getPackageInfo(pInfoJson_check_annual_contract).get(0);
        QuoteHelper.PackageInfo pInfo_check_monthly_contract = QuoteHelper.getPackageInfo(pInfoJson_check_monthly_contract).get(0);


        String duration_check_null_1 = QuoteHelper.getDurationFromPackageInfo(pInfo_check_null_1);
        String duration_check_null_2 = QuoteHelper.getDurationFromPackageInfo(pInfo_check_null_2);
        String duration_check_annual = QuoteHelper.getDurationFromPackageInfo(pInfo_check_annual);
        String duration_check_monthly = QuoteHelper.getDurationFromPackageInfo(pInfo_check_monthly);
        String duration_check_annual_contract = QuoteHelper.getDurationFromPackageInfo(pInfo_check_annual_contract);
        String duration_check_monthly_contract = QuoteHelper.getDurationFromPackageInfo(pInfo_check_monthly_contract);


        System.assertEquals(null, duration_check_null_1);
        System.assertEquals(null, duration_check_null_2);
        System.assertEquals(Product2Helper.CHARGE_TERM_ANNUAL, duration_check_annual);
        System.assertEquals(Product2Helper.CHARGE_TERM_MONTHLY, duration_check_monthly);
        System.assertEquals(Product2Helper.CHARGE_TERM_ANNUAL_CONTRACT, duration_check_annual_contract);
        System.assertEquals(Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT, duration_check_monthly_contract);
    }

    @isTest static void test_getPrimaryQuote() {
        Opportunity testOpp = TestDataGenerator.createOpportunity(null);

        Quote testQuote1 = TestDataGenerator.createQuote(testOpp);
        Quote testQuote2 = TestDataGenerator.createQuote(testOpp);
        Quote testQuote3 = TestDataGenerator.createQuote(testOpp);
        Test.startTest();
        Quote testQuote4 = TestDataGenerator.createQuote(testOpp);
        Quote testQuote5 = TestDataGenerator.createQuote(testOpp);
        Quote testQuote6 = TestDataGenerator.createQuote(testOpp);

        Test.stopTest();

        testQuote1.Name = 'Test quote 1';
        testQuote1.RecordTypeId = QuoteHelper.RT_ID_BILLING;

        testQuote2.Name = 'Test quote 2';
        testQuote2.RecordTypeId = QuoteHelper.RT_ID_BILLING;

        testQuote3.Name = 'Test quote 3';
        testQuote3.RecordTypeId = QuoteHelper.RT_ID_BILLING;
        testQuote3.IsPrimary__c = true;

        testQuote4.Name = 'Test quote 4';

        testQuote5.Name = 'Test quote 5';
        //testQuote5.IsPrimary__c = true;

        testQuote6.Name = 'Test quote 6';

        List<Quote> qlis = new List<Quote>{
            testQuote1, testQuote2, testQuote3, testQuote4, testQuote5, testQuote6
        };

        Quote result1 = QuoteHelper.getPrimaryQuote(qlis, true);
        Quote result2 = QuoteHelper.getPrimaryQuote(qlis, false);

        System.assertEquals(testQuote3.Name, result1.Name);
    }

    @isTest
    static void test_calculateFreeValuesForNonNGBS() {
        SObjectFactory factory = new SObjectFactory();
        // Create Opportunity
        Opportunity opportunityRecord = (Opportunity) factory
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('Test Opportunity'),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            );
        // Create PriceBook
        PriceBook2 pricebookRecord = (PriceBook2) factory
            .create(
                PriceBook2.SObjectType,
                new Map<SObjectField, Object>{
                    PriceBook2.Name => ValueProviderBuilder.provideUniqueString('Test Price Book'),
                    PriceBook2.Description => ValueProviderBuilder.provideUniqueString('test price book products'),
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 2
                }
            );
        // Create Quote
        Quote quoteRecord = (Quote) factory
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                    Quote.Pricebook2Id => pricebookRecord.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                }
            );
        // Create Products
        List<Product2> productRecords = (List<Product2>) factory
            .build(
                Product2.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
                }
            );
        // set Family = 'Main' for Last one product
        productRecords.get(0).Family = Product2Helper.FAMILY_TAXES;
        insert productRecords;
        // Create PricebookEntries
        List<PricebookEntry> standardPricebookEntryRecords = (List<PricebookEntry>) factory
            .build(
                PricebookEntry.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            );
        List<PricebookEntry> pricebookEntryRecords = (List<PricebookEntry>) factory
            .build(
                PricebookEntry.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => pricebookRecord.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            );
        List<PricebookEntry> pbeToInsertList = new List<PricebookEntry>(standardPricebookEntryRecords);
        pbeToInsertList.addAll(pricebookEntryRecords);
        insert pbeToInsertList;
        // Create QuoteLineItems
        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) factory
            .build(
                QuoteLineItem.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pricebookEntryRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 4
                }
            );
        //Set different taxes amount
        qliRecords.get(0).Fixed_Taxes_Amount__c = 10;
        qliRecords.get(1).Fixed_Taxes_Amount__c = 20;

        Test.startTest();
            insert qliRecords;
            // Verify scenario when charge term is Monthly
            List<QuoteLineItem> qliList1 = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIds(quoteRecord.Id)
                .executeQuery();
            Map <String, Decimal> testMapMonthly =
                            QuoteHelper.calculateFreeValuesOnQuote(qliList1, 3);
            System.assertEquals((Double) 4 * 10 * 3, testMapMonthly.get('freeDiscount'));
            System.assertEquals((Double) 20 * 3, testMapMonthly.get('freeServiceTaxes'));
            //Verify scenario when charge term is Annual
            productRecords.get(0).Charge_Term__c = 'Annual';
            productRecords.get(1).Charge_Term__c = 'Annual';
            update productRecords;

            List<QuoteLineItem> qliList2 = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIds(quoteRecord.Id)
                .executeQuery();
            Map <String, Decimal> testMapAnnual =
                            QuoteHelper.calculateFreeValuesOnQuote(qliList2, 3);
            System.assertEquals((Double) 4 * 10 * 3 / 12, testMapAnnual.get('freeDiscount'));
            System.assertEquals((Double) 20 * 3 / 12, testMapAnnual.get('freeServiceTaxes'));
        Test.stopTest();
    }

    @isTest
    static void test_calculateFreeValuesOnSpecialTermsChangeForNonNGBS() {
        SObjectFactory factory = new SObjectFactory();
        // Create Opportunity
        Opportunity opportunityRecord = (Opportunity) factory
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('Test Opportunity'),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            );
        // Create PriceBook
        PriceBook2 pricebookRecord = (PriceBook2) factory
            .create(
                PriceBook2.SObjectType,
                new Map<SObjectField, Object>{
                    PriceBook2.Name => ValueProviderBuilder.provideUniqueString('Test Price Book'),
                    PriceBook2.Description => ValueProviderBuilder.provideUniqueString('test price book products'),
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 2
                }
            );
        // Create Quote
        Quote quoteRecord = (Quote) factory
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                    Quote.Pricebook2Id => pricebookRecord.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                }
            );
        // Create Products
        List<Product2> productRecords = (List<Product2>) factory
            .build(
                Product2.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
                }
            );
        // set Family = 'Main' for Last one product
        productRecords.get(0).Family = Product2Helper.FAMILY_TAXES;
        insert productRecords;
        // Create PricebookEntries
        List<PricebookEntry> standardPricebookEntryRecords = (List<PricebookEntry>) factory
            .build(
                PricebookEntry.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            );
        List<PricebookEntry> pricebookEntryRecords = (List<PricebookEntry>) factory
            .build(
                PricebookEntry.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => pricebookRecord.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            );
        List<PricebookEntry> pbeToInsertList = new List<PricebookEntry>(standardPricebookEntryRecords);
        pbeToInsertList.addAll(pricebookEntryRecords);
        insert pbeToInsertList;
        // Create QuoteLineItems
        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) factory
            .build(
                QuoteLineItem.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pricebookEntryRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 4
                }
            );
        // Set different taxes amount
        qliRecords.get(0).Fixed_Taxes_Amount__c = 10;
        qliRecords.get(1).Fixed_Taxes_Amount__c = 20;

        Test.startTest();
            insert qliRecords;
            Quote quoteToVerify1 = [
                SELECT Credit_Amount__c, Free_Service_Taxes__c
                FROM Quote
                WHERE Id = :quoteRecord.Id
            ];
            System.assertEquals(null, quoteToVerify1.Credit_Amount__c);
            System.assertEquals(null, quoteToVerify1.Free_Service_Taxes__c);
            // Populate quote Special terms with value suitable for FSC calculation
            quoteRecord.Special_Terms__c = QuoteHelper.FREE_MONTH_3;
            update quoteRecord;
            Quote quoteToVerify2 = [
                SELECT Credit_Amount__c, Free_Service_Taxes__c
                FROM Quote
                WHERE Id = :quoteRecord.Id
            ];
            System.assertEquals((Double) 4 * 10 * 3, quoteToVerify2.Credit_Amount__c);
            System.assertEquals((Double) 20 * 3, quoteToVerify2.Free_Service_Taxes__c);
        Test.stopTest();
    }

    @isTest
    static void test_calculateFreeValuesOnQLIUpdateForNonNGBS() {
        SObjectFactory factory = new SObjectFactory();
        // Create Opportunity
        Opportunity opportunityRecord = (Opportunity) factory
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('Test Opportunity'),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            );
        // Create PriceBook
        PriceBook2 pricebookRecord = (PriceBook2) factory
            .create(
                PriceBook2.SObjectType,
                new Map<SObjectField, Object>{
                    PriceBook2.Name => ValueProviderBuilder.provideUniqueString('Test Price Book'),
                    PriceBook2.Description => ValueProviderBuilder.provideUniqueString('test price book products'),
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 2
                }
            );
        // Create Quote
        Quote quoteRecord = (Quote) factory
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                    Quote.Pricebook2Id => pricebookRecord.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                }
            );
        // Create Products
        List<Product2> productRecords = (List<Product2>) factory
            .build(
                Product2.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
                }
            );
        // set Family = 'Main' for Last one product
        productRecords.get(0).Family = Product2Helper.FAMILY_TAXES;
        insert productRecords;
        // Create PricebookEntries
        List<PricebookEntry> standardPricebookEntryRecords = (List<PricebookEntry>) factory
            .build(
                PricebookEntry.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            );
        List<PricebookEntry> pricebookEntryRecords = (List<PricebookEntry>) factory
            .build(
                PricebookEntry.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => pricebookRecord.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            );
        List<PricebookEntry> pbeToInsertList = new List<PricebookEntry>(standardPricebookEntryRecords);
        pbeToInsertList.addAll(pricebookEntryRecords);
        insert pbeToInsertList;
        // Create QuoteLineItems
        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) factory
            .build(
                QuoteLineItem.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pricebookEntryRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 4
                }
            );
        // Set different taxes amount
        qliRecords.get(0).Fixed_Taxes_Amount__c = 10;
        qliRecords.get(1).Fixed_Taxes_Amount__c = 20;

        Test.startTest();
            insert qliRecords;
            Quote quoteToVerify1 = [
                SELECT Credit_Amount__c, Free_Service_Taxes__c
                FROM Quote
                WHERE Id = :quoteRecord.Id
            ];
            System.assertEquals(null, quoteToVerify1.Credit_Amount__c);
            System.assertEquals(null, quoteToVerify1.Free_Service_Taxes__c);
            // Populate quote Special terms with value suitable for FSC calculation
            quoteRecord.Special_Terms__c = QuoteHelper.FREE_MONTH_3;
            update quoteRecord;
            Quote quoteToVerify2 = [
                SELECT Credit_Amount__c, Free_Service_Taxes__c
                FROM Quote
                WHERE Id = :quoteRecord.Id
            ];
            System.assertEquals((Double) 2 * 20 * 3, quoteToVerify2.Credit_Amount__c);
            System.assertEquals((Double) 2 * 10 * 3, quoteToVerify2.Free_Service_Taxes__c);
        Test.stopTest();
    }

    @isTest
    public static void testGetFilteredPicklist() {

        Account testAcc = new Account(
            Name = 'testAcc'
        );

        insert testAcc;

        Opportunity testOpp = new Opportunity(
            AccountId = testAcc.Id,
            Name = 'MyTestOpportunity',
            Type = 'New Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Professional',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );

        insert testOpp;

        Quote testQuote = new Quote(
            Name = 'testQuote',
            OpportunityId = testOpp.Id,
            Status = 'Draft',
            Approved_Status__c = 'Approved',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(2),
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Upsell_Status__c = 'New'
        );

        insert testQuote;

        Test.startTest();

        Quote quote = [
            SELECT Id, Upsell_Status__c
            FROM Quote
            WHERE Name =:'testQuote'
        ];

        List<Schema.PicklistEntry> terms = QuoteHelper.quoteBasedSpecialTerms(quote.Upsell_Status__c);

        System.assertEquals(terms, QuoteHelper.specialTermsList);

        Test.stopTest();
    }

    private static Quote testQuote;
    private static Account testAccount;
    private static QuoteLineItem testQuoteLineItem;
    private static Opportunity testOpportunity;
    private static PriceBook2 testPriceBook;
    private static User salesrepUser;
    private static User salesmanagerUser;
    private static User salesmanagermanagerUser;
    private static User salesVPUser;

    @isTest
    public static void testRecallQuotesApprovals() {
        Triggers.switchOff();
        salesrepUser = createUser('sr', false, true); // salesrepUser
        salesmanagerUser = createUser('sm', false); //salesmanagerUser
        salesmanagermanagerUser = createUser('smm', false); //salesmanagermanagerUser
        salesVPUser = createUser('svp', false); //salesmanagermanagerUser
        User userSysAdmin = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testUser',
                    User.Username => 'testUser@ringcentral.com',
                    User.Email => 'testUser@gmail.com',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.CommunityNickname => 'Test052323'
                }
            )
            .create()
            .getRecord();

        insert new List<User> {salesrepUser, salesmanagerUser, salesmanagermanagerUser, salesVPUser};
        Triggers.switchOn();

        system.runAs(userSysAdmin){

            insert new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );

            salesrepUser.Hierarchy_Role__c = 'Direct Manager';
            salesmanagerUser.Hierarchy_Role__c = 'Segment Leader';
            salesmanagermanagerUser.Hierarchy_Role__c = 'SVP WWS Directs';
            update new List<User>{ salesrepUser, salesmanagerUser, salesmanagermanagerUser };

            Test.startTest();
                CreateTestData(Test.getStandardPricebookId(), 999, 'SalesVP', '1-9999999', '0-0', '0-0', '0-0', '0-0', '1234');
                System.debug('Limits::: ' + Limits.getQueries());
                testQuote = [SELECT Id, Approved_Status__c, Level_1_Approver__r.Name FROM Quote WHERE Id=:testQuote.Id];
                Map<String, String> params = new Map<String, String>();
                params.put('quoteId', String.valueOf(testQuote.Id));

            Test.stopTest();

                testQuote = QuotingToolQuoteApexController.submitApprovalRequest(params);
                params.put('comment', 'some comment');
                params.put('action', 'Approve');
                System.assertEquals(testQuote.Approved_Status__c, 'Pending L1 Approval');
                testQuote = QuotingToolQuoteApexController.setApprovalAction(params);
                QuoteHelper.recallQuotesApprovals(new List<Quote>{testQuote});
        }
    }

    @isTest
    public static void test_isHasContactCenterProductsInCart_nullPassed() {
        System.assert(!QuoteHelper.isHasContactCenterProductsInCart(new List<Quote>(), null));
    }

    @isTest
    public static void test_isHasContactCenterProductsInCart_ngbsWithCC() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => con.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10,
                    Opportunity.Is_Billing_Opportunity__c => true
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        Quote ngbsQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => opp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 12,
                    Quote.Account__c => opp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();

        Quote ngbsCcQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => opp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => opp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_CC
                }
            )
            .create()
            .getRecord();

        Product2 ccProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                            Product2.Name => 'Connect Pro - Annual Fee',
                            Product2.IsActive => true,
                            Product2.GOA_Group__c => 'DEVICES_B_STOCK',
                            Product2.Family => 'CC Service',
                            Product2.Charge_Term__c => 'Monthly',
                            Product2.Sub_Category__c => 'Contact Center',
                            Product2.Cart_Tab_Availability__c => 'Sales Quote;Contact Center Quote'
                    }
            )
            .create()
            .getRecord();

        PriceBookEntry priceEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.Product2Id => ccProduct.Id,
                    PriceBookEntry.UnitPrice => 10000,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.ServiceDate => date.today(),
                    QuoteLineItem.Description => 'TestLineItem',
                    QuoteLineItem.UnitPrice => priceEntry.UnitPrice,
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.QuoteId => ngbsCcQuote.Id,
                    QuoteLineItem.PriceBookEntryId => priceEntry.Id,
                    QuoteLineItem.Product2Id => ccProduct.Id,
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    QuoteLineItem.Discount_number__c => 0,
                    QuoteLineItem.NewQuantity__c => 5
                }
            )
            .create()
            .getRecord();
        Test.stopTest();
        ngbsCcQuote = [
            SELECT RecordTypeid, isPrimary__c, (SELECT Product2.Sub_Category__c FROM QuoteLineItems)
            FROM Quote
            WHERE Id = :ngbsCcQuote.Id
        ];

        System.assert(QuoteHelper.isHasContactCenterProductsInCart(new List<Quote>{ngbsQuote, ngbsCcQuote}, ngbsQuote));
    }

    @isTest
    public static void test_isHasContactCenterProductsInCart_ngbsWithNoCC() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => con.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10,
                    Opportunity.Is_Billing_Opportunity__c => true
                }
            )
            .create()
            .getRecord();

        Quote ngbsQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => opp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 12,
                    Quote.Account__c => opp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();

        System.assert(!QuoteHelper.isHasContactCenterProductsInCart(new List<Quote>{ngbsQuote}, ngbsQuote));
    }

    @isTest
    public static void test_isHasContactCenterProductsInCart_ngbsCCWithNoQLI() {
        Test.startTest();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => con.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10,
                    Opportunity.Is_Billing_Opportunity__c => true
                }
            )
            .create()
            .getRecord();

        Quote ngbsQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => opp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 12,
                    Quote.Account__c => opp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();
        Test.stopTest();

        Quote ngbsCcQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => opp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => opp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_CC
                }
            )
            .create()
            .getRecord();

        System.assert(!QuoteHelper.isHasContactCenterProductsInCart(new List<Quote>{ngbsQuote, ngbsCcQuote}, ngbsQuote));
    }

    @isTest
    public static void test_isHasContactCenterProductsInCart_legacyWithCC() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => con.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10,
                    Opportunity.Is_Billing_Opportunity__c => false
                }
            )
            .create()
            .getRecord();

        Quote legacyQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => opp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 12,
                    Quote.Account__c => opp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                }
            )
            .create()
            .getRecord();

        Product2 ccProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                            Product2.Name => 'Connect Pro - Annual Fee',
                            Product2.IsActive => true,
                            Product2.GOA_Group__c => 'DEVICES_B_STOCK',
                            Product2.Family => 'CC Service',
                            Product2.Charge_Term__c => 'Monthly',
                            Product2.Sub_Category__c => 'Contact Center',
                            Product2.Cart_Tab_Availability__c => 'Sales Quote;Contact Center Quote'
                    }
            )
            .create()
            .getRecord();

        Test.startTest();

        PriceBookEntry priceEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.Product2Id => ccProduct.Id,
                    PriceBookEntry.UnitPrice => 10000,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.ServiceDate => date.today(),
                    QuoteLineItem.Description => 'TestLineItem',
                    QuoteLineItem.UnitPrice => priceEntry.UnitPrice,
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.QuoteId => legacyQuote.Id,
                    QuoteLineItem.PriceBookEntryId => priceEntry.Id,
                    QuoteLineItem.Product2Id => ccProduct.Id,
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    QuoteLineItem.Discount_number__c => 0,
                    QuoteLineItem.NewQuantity__c => 5
                }
            )
            .create()
            .getRecord();

        Quote quoteWithQLI = [
            SELECT RecordTypeid, isPrimary__c, (SELECT Product2.Sub_Category__c FROM QuoteLineItems)
            FROM Quote
            WHERE Id = :legacyQuote.Id
        ];

        Test.stopTest();

        System.assert(QuoteHelper.isHasContactCenterProductsInCart(new List<Quote>{quoteWithQLI}, quoteWithQLI));
    }

    @isTest
    public static void test_isHasContactCenterProductsInCart_legacyWithoutQLI() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => con.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10,
                    Opportunity.Is_Billing_Opportunity__c => false
                }
            )
            .create()
            .getRecord();

        Quote legacyQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => opp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 12,
                    Quote.Account__c => opp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                }
            )
            .create()
            .getRecord();

        System.assert(!QuoteHelper.isHasContactCenterProductsInCart(new List<Quote>{legacyQuote}, legacyQuote));
    }

    @isTest
    public static void test_isHasContactCenterProductsInCart_legacyWithoutCC() {

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => con.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10,
                    Opportunity.Is_Billing_Opportunity__c => false
                }
            )
            .create()
            .getRecord();

        Quote legacyQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => opp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 12,
                    Quote.Account__c => opp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                }
            )
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                            Product2.Name => 'Connect Pro - Annual Fee',
                            Product2.IsActive => true,
                            Product2.GOA_Group__c => 'DEVICES_B_STOCK',
                            Product2.Family => 'RingCentral'
                    }
            )
            .create()
            .getRecord();
        update product;

        Test.startTest();

        PriceBookEntry priceEntry = (PricebookEntry) new SobjectBuilder(PricebookEntry.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                PriceBookEntry.Product2Id => product.Id,
                PriceBookEntry.UnitPrice => 10000,
                PriceBookEntry.IsActive => true,
                PriceBookEntry.UseStandardPrice => false,
                PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
            }
        )
        .create()
        .getRecord();

        Triggers.switchOn();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.ServiceDate => date.today(),
                    QuoteLineItem.Description => 'TestLineItem',
                    QuoteLineItem.UnitPrice => priceEntry.UnitPrice,
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.QuoteId => legacyQuote.Id,
                    QuoteLineItem.PriceBookEntryId => priceEntry.Id,
                    QuoteLineItem.Product2Id => product.Id,
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    QuoteLineItem.Discount_number__c => 0,
                    QuoteLineItem.NewQuantity__c => 5
                }
            )
            .create()
            .getRecord();

        Test.stopTest();

        System.assert(!QuoteHelper.isHasContactCenterProductsInCart(new List<Quote>{legacyQuote}, legacyQuote));
    }

    @isTest
    private static void test_getTemplates() {
        SObjectBuilder rcQuoteTemplatesBuilder = new SObjectBuilder(RC_Quote_Template__c.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                RC_Quote_Template__c.Name => ValueProviderBuilder.provideList(
                    new List<String>{
                        QuoteHelper.TOTAL_CHANGES_TEMPLATE,
                        QuoteHelper.CHANGED_DETAILS_TEMPLATE,
                        QuoteHelper.QUOTE_DETAILS_TEMPLATE
                    })
            })
            .create();
        List<RC_Quote_Template__c> rcTemplates = new RCQuoteTemplateSelector().selectRCQuoteTemplates().executeQuery();

        SObjectBuilder rcQuoteTemplateBuilder = new SObjectBuilder(RC_Quote_Templates__c.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                RC_Quote_Templates__c.Name => ValueProviderBuilder.provideList(
                    new List<String>{
                        QuoteHelper.TOTAL_CHANGES_TEMPLATE,
                        QuoteHelper.CHANGED_DETAILS_TEMPLATE,
                        QuoteHelper.QUOTE_DETAILS_TEMPLATE
                    }),
                RC_Quote_Templates__c.TemplateId__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        rcTemplates.get(0).Id,
                        rcTemplates.get(1).Id,
                        rcTemplates.get(2).Id
                    })
            })
            .create();
        List<RC_Quote_Templates__c> templates = RC_Quote_Templates__c.getAll().values();

        System.assertEquals(3, templates.size());
        System.assertEquals(rcTemplates[0].Id, QuoteHelper.getTemplate(QuoteHelper.TOTAL_CHANGES_TEMPLATE));
        System.assertEquals(rcTemplates[1].Id, QuoteHelper.getTemplate(QuoteHelper.CHANGED_DETAILS_TEMPLATE));
        System.assertEquals(rcTemplates[2].Id, QuoteHelper.getTemplate(QuoteHelper.QUOTE_DETAILS_TEMPLATE));
    }

    @isTest
    private static void test_isBillingQuoteHasErrors() {

        Triggers.switchOff();
        salesrepUser = createUser('sr', true, true);
        salesmanagerUser = createUser('sm', true);
        salesmanagermanagerUser = createUser('smm', true);
        salesVPUser = createUser('svp', true);
        Triggers.switchOn();
        CreateTestData(Test.getStandardPricebookId(), 999, 'SalesVP', '1-9999999', '0-0', '0-0', '0-0', '0-0', '1234');

        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities()
            .selectField(Opportunity.Id)
            .executeQuery()
            .get(0);

        Quote qt = (Quote) new SOBjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId         => opp.Id,
                Quote.RecordTypeId          => QuoteHelper.RT_ID_BILLING,
                Quote.IsQuoteHasErrors__c   => true
            })
            .create()
            .getRecord();

        Test.startTest();

        Boolean result = QuoteHelper.isBillingQuoteHasErrors(qt);

        Test.stopTest();

        System.assert(result, 'Billing Quote should have errors');
    }

    private static void CreateTestData(Id standardPriceBookId, Decimal discount, String other, String range, String srr, String smr, String smmr, String svpr, String rcUserId){

         //Assign approvers
        assignManager(salesrepUser, salesmanagerUser);
        assignManager(salesmanagerUser, salesmanagermanagerUser);

        //Insert Sales VP
        upsert new RingCentralVariousSettings__c(
            SVP_WWS_User_ID__c = salesVPUser.Id,
            SetupOwnerId = salesrepUser.Id
        );

        testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c = 'Office');
        insert testPriceBook;

        Product2 testProduct = new Product2(Name = 'Connect Pro - Annual Fee', IsActive = true, GOA_Group__c = 'DEVICES_B_STOCK', Family = 'RingCentral', Sub_Category__c = 'Main');
        insert testProduct;

        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPriceBookId, Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        insert standardPrice;

        PricebookEntry testPrice = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);
        insert testPrice;

        Triggers.switchOff();

        testAccount = new Account(Name='Opty test account',
                                    Partner_ID__c='testID',
                                    Permitted_Brands__c='RingCentral',
                                    RC_User_ID__c = rcUserId);
        insert testAccount;

        testOpportunity = new Opportunity(Name = 'Test Opportunity 2016', Type = 'Syndicated - New', StageName = 'Planning', CloseDate = system.today(), AccountId = testAccount.Id);
        insert testOpportunity;

        testQuote = new Quote (Name = 'qoutetest' , OpportunityId = testOpportunity.id , Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10, RecordTypeId = QuoteHelper.RT_ID_SALES);
        insert testQuote;
        Triggers.switchOn();

        testQuoteLineItem = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem', UnitPrice = testPrice.UnitPrice, Quantity = 5,
                                                QuoteId = testQuote.Id, PriceBookEntryId = testPrice.Id, Product2Id = testProduct.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = discount);
        OpportunityTotals.bypassOpportnuityUpdate = true;
        insert testQuoteLineItem;
        OpportunityTotals.bypassOpportnuityUpdate = false;

    }

    @isTest
    static void testIsNGBSQuoteWithBillingQuote() {

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType)
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => pb.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .build()
            .getRecord();

        Test.startTest();

        Boolean isNGBS = QuoteHelper.isNGBSQuote(billingQuote);

        Test.stopTest();

        System.assert(
            isNGBS,
            'Incorrect NGBS Quote'
        );
    }

    @isTest
    static void testIsNGBSQuoteWithoutBillingQuote() {

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType)
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => pb.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
            })
            .build()
            .getRecord();

        Test.startTest();

        Boolean isNGBS = QuoteHelper.isNGBSQuote(billingQuote);

        Test.stopTest();

        System.assert(
            !isNGBS,
            'Incorrect Sales Quote'
        );
    }

    @isTest
    static void testIsQuoteHasContractWithContract() {

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType)
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => pb.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => PACKAGE_INFO_WITH_CONTRACT
            })
            .build()
            .getRecord();

        Test.startTest();

        Boolean hasContract = QuoteHelper.isQuoteHasContract(billingQuote);

        Test.stopTest();

        System.assert(
            hasContract,
            'Incorrect NGBS Quote with Contract'
        );
    }

    @isTest
    static void testIsQuoteHasContractWithoutContract() {

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType)
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => pb.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .build()
            .getRecord();

        Test.startTest();

        Boolean hasContract = QuoteHelper.isQuoteHasContract(billingQuote);

        Test.stopTest();

        System.assert(
            !hasContract,
            'Incorrect NGBS Quote without Contract'
        );
    }

    @isTest
    static void testSelectedContractWithContract() {

        Quote oldQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .build()
            .getRecord();

        Quote newQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_WITH_CONTRACT)
            .build()
            .getRecord();

        Test.startTest();

        Boolean isContractSelected = QuoteHelper.isContractSelected(oldQuote, newQuote);

        Test.stopTest();

        System.assert(
            isContractSelected,
            'Contract should be selected on NGBS Quote'
        );
    }

    @isTest
    static void testSelectedContractWithUpgradeContract() {

        Quote oldQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_WITH_CONTRACT)
            .build()
            .getRecord();

        Quote newQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_WITH_CONTRACT)
            .build()
            .getRecord();

        Test.startTest();

        Boolean isContractSelected = QuoteHelper.isContractSelected(oldQuote, newQuote);

        Test.stopTest();

        System.assert(
            !isContractSelected,
            'Contract should be changed on NGBS Quote'
        );
    }

    @isTest
    static void testDeselectedContractWithoutContract() {

        Quote oldQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_WITH_CONTRACT)
            .build()
            .getRecord();

        Quote newQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, null)
            .build()
            .getRecord();

        Test.startTest();

        Boolean isContractDeselected = QuoteHelper.isContractDeselected(oldQuote, newQuote);

        Test.stopTest();

        System.assert(
            isContractDeselected,
            'Contract should be deselected on NGBS Quote'
        );
    }

    @isTest
    static void testDeselectedContractFromUpgradedContract() {

        Quote oldQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_WITH_CONTRACT)
            .build()
            .getRecord();

        Quote newQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_WITH_CONTRACT)
            .build()
            .getRecord();

        Test.startTest();

        Boolean isContractDeselected = QuoteHelper.isContractDeselected(oldQuote, newQuote);

        Test.stopTest();

        System.assert(
            !isContractDeselected,
            'Contract should not be deselected on NGBS Quote'
        );
    }

    @isTest
    static void testChangedContractWithContractChange() {

        Quote oldQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_WITH_CONTRACT.replace('Office','null'))
            .build()
            .getRecord();

        Quote newQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_WITH_CONTRACT)
            .build()
            .getRecord();

        Test.startTest();

        Boolean isContractChanged = QuoteHelper.isContractChanged(oldQuote, newQuote);

        Test.stopTest();

        System.assert(
            isContractChanged,
            'Contract should be changed on NGBS Quote'
        );
    }

    @isTest
    static void verifyDocuSignStatusNotCompletedOnQuoteWithoutEnvelopes() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'testAcc',
                    Account.BillingStreet => '443 Kearney Frontage',
                    Account.BillingCity => 'Fresno',
                    Account.BillingState => 'CA',
                    Account.BillingPostalCode => '93706',
                    Account.BillingCountry =>'United States'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => 'testOpp',
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Type => 'Existing Business',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SOBjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId         => testOpp.Id,
                Quote.RecordTypeId          => QuoteHelper.RT_ID_BILLING,
                Quote.IsQuoteHasErrors__c   => false
            })
            .create()
            .getRecord();

        Test.startTest();

        Boolean isDocuSignStatusCompleted = QuoteHelper.isDocuSignStatusCompleted(testQuote);

        Test.stopTest();

        System.assert(
            !isDocuSignStatusCompleted,
            'Should return false for Quote without envelops'
        );
    }

    @isTest
    static void verifyDocuSignStatusNotCompletedOnQuoteWithNotCompletedEnvelopes() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'testAcc',
                    Account.BillingStreet => '443 Kearney Frontage',
                    Account.BillingCity => 'Fresno',
                    Account.BillingState => 'CA',
                    Account.BillingPostalCode => '93706',
                    Account.BillingCountry =>'United States'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => 'testOpp',
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Type => 'Existing Business',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SOBjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId         => testOpp.Id,
                Quote.RecordTypeId          => QuoteHelper.RT_ID_BILLING,
                Quote.IsQuoteHasErrors__c   => false
            })
            .create()
            .getRecord();

        dsfs__DocuSign_Status__c testEnvelop = (dsfs__DocuSign_Status__c) new SOBjectBuilder(dsfs__DocuSign_Status__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                dsfs__DocuSign_Status__c.dfsq__Quote__c => testQuote.Id,
                dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => 'Sent'
            })
            .create()
            .getRecord();

        Test.startTest();

        Boolean isDocuSignStatusCompleted = QuoteHelper.isDocuSignStatusCompleted(testQuote);

        Test.stopTest();

        System.assert(
            !isDocuSignStatusCompleted,
            'Should return false for Quote with not completed envelops'
        );
    }

    @isTest
    static void verifyDocuSignStatusCompletedOnQuoteWithCompletedEnvelopes() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'testAcc',
                    Account.BillingStreet => '443 Kearney Frontage',
                    Account.BillingCity => 'Fresno',
                    Account.BillingState => 'CA',
                    Account.BillingPostalCode => '93706',
                    Account.BillingCountry =>'United States'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => 'testOpp',
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Type => 'Existing Business',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SOBjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId         => testOpp.Id,
                Quote.RecordTypeId          => QuoteHelper.RT_ID_BILLING,
                Quote.IsQuoteHasErrors__c   => false
            })
            .create()
            .getRecord();

        Triggers.switchOff();
        dsfs__DocuSign_Status__c testEnvelop = (dsfs__DocuSign_Status__c) new SOBjectBuilder(dsfs__DocuSign_Status__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                dsfs__DocuSign_Status__c.dfsq__Quote__c => testQuote.Id,
                dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => 'Completed'
            })
            .create()
            .getRecord();

        Test.startTest();

        Boolean isDocuSignStatusCompleted = QuoteHelper.isDocuSignStatusCompleted(testQuote);

        Test.stopTest();

        System.assert(
            isDocuSignStatusCompleted,
            'Should return true for Quote with completed envelop'
        );
    }

    @isTest
    static void testChangedContractWithoutContractChange() {

        Quote oldQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_WITH_CONTRACT)
            .build()
            .getRecord();

        Quote newQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_WITH_CONTRACT)
            .build()
            .getRecord();

        Test.startTest();

        Boolean isContractChanged = QuoteHelper.isContractChanged(oldQuote, newQuote);

        Test.stopTest();

        System.assert(
            !isContractChanged,
            'Contract should not be changed on NGBS Quote'
        );
    }

    @isTest
    private static void testNGBSPlanChangeWithoutEnt() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => System.today(),
                Opportunity.PriceBook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SOBjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Product2 prod = (Product2) new SOBjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Service',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.IsActive => true,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SOBjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SOBjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.PricebookEntryId => standardPrice.Id,
                QuoteLineItem.Quantity => 2,
                QuoteLineItem.UnitPrice => 50
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();

        try {
            Boolean isNGBSPlanChange = QuoteHelper.isNGBSPlanChange(qt, new List<QuoteLineItem>{qli});
        } catch(Exception e) {
            System.assertEquals(e.getMessage(), 'Can not get information for "isNGBSPlanChange" (QLI not found)');
        }

        Test.stopTest();
    }

    @isTest
    private static void testNGBSPackageChangeWithoutEnt() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => System.today(),
                Opportunity.PriceBook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SOBjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO_WITH_CONTRACT
            })
            .create()
            .getRecord();

        Product2 prod = (Product2) new SOBjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Service',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SOBjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SOBjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.PricebookEntryId => standardPrice.Id,
                QuoteLineItem.Quantity => 2,
                QuoteLineItem.UnitPrice => 50
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();

        try {
            Boolean isNGBSPackageChange = QuoteHelper.isNGBSPackageChange(qt, new List<QuoteLineItem>{qli});
        } catch(Exception e) {
            System.assertEquals(e.getMessage(), 'Can not get information for "isNGBSPackageChange" (QLI not found)');
        }

        Test.stopTest();
    }

    @IsTest
    private static void test_IsEngageServiceNullCheck() {
        Test.startTest();
            Boolean isEngageService = QuoteHelper.isEngageService(null);
            System.assertEquals(false, isEngageService, 'No Quote or empty package info - means not Engage');

            Boolean isEngageVService = QuoteHelper.isEngageVService(null);
            System.assertEquals(false, isEngageVService, 'No Quote or empty package info - means not Engage');


            Boolean isEngageDService = QuoteHelper.isEngageDService(null);
            System.assertEquals(false, isEngageDService, 'No Quote or empty package info - means not Engage');

            Boolean isEngageUService = QuoteHelper.isEngageUService(null);
            System.assertEquals(false, isEngageUService, 'No Quote or empty package info - means not Engage');
        Test.stopTest();
    }

    @IsTest
    private static void test_isVoiceEngageService() {
        Account engageAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Engage Account'
            })
            .create()
            .getRecord();

        Opportunity engageOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => engageAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Quote engageQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => engageOpportunity.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => PACKAGE_INFO_ENGAGE
            })
            .build()
            .getRecord();

        Test.startTest();
            String voicePackageInfo = '[{"id":"18","version":"1","productName":"Office","productId":"' +
                Product2Helper.PRODUCT_ID_ENGAGE_VOICE_LEGACY + '"}]';
            engageQuote.Package_Info__c = voicePackageInfo;
        Test.stopTest();
        System.assert(QuoteHelper.isEngageVService(engageQuote));
        System.assert(QuoteHelper.isEngageService(engageQuote));
    }

    @IsTest
    private static void test_isDigitalEngageService() {
        Account engageAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Engage Account'
            })
            .create()
            .getRecord();

        Opportunity engageOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => engageAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Quote engageQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => engageOpportunity.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => PACKAGE_INFO_ENGAGE
            })
            .build()
            .getRecord();

        Test.startTest();
            String digitalPackageInfo = '[{"id":"18","version":"1","productName":"Office","productId":"' +
                Product2Helper.PRODUCT_ID_ENGAGE_DIGITAL_LEGACY + '"}]';
            engageQuote.Package_Info__c = digitalPackageInfo;
        Test.stopTest();
        System.assert(QuoteHelper.isEngageDService(engageQuote));
    }

    @IsTest
    private static void test_isUnifiedEngageService() {
        Account engageAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Engage Account'
            })
            .create()
            .getRecord();

        Opportunity engageOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => engageAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Quote engageQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => engageOpportunity.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => PACKAGE_INFO_ENGAGE
            })
            .build()
            .getRecord();

        Test.startTest();
            String unifiedPackageInfo = '[{"id":"18","version":"1","productName":"Office","productId":"' +
                Product2Helper.PRODUCT_ID_ENGAGE_UNIFIED + '"}]';
            engageQuote.Package_Info__c = unifiedPackageInfo;
        Test.stopTest();
        System.assert(QuoteHelper.isEngageUService(engageQuote));
    }

    @IsTest
    static void testIsEngageOmnichannelService() {
        Quote engageQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => ValueProviderBuilder.provideDummyId(Opportunity.SObjectType),
                Quote.Package_Info__c => PACKAGE_INFO_ENGAGE_OMNI
            })
            .build()
            .getRecord();
        Assert.isTrue(QuoteHelper.isEngageOmnichannelService(engageQuote), 'Should be omnichannel quote');
    }

    @isTest
    static void testCreditAmountCalculationForTrialAcc() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<sObjectField, Object>{
                Account.RC_User_ID__c => '12345',
                Account.RC_Account_Status__c => 'Trial Account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<sObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('Test Opportunity'),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<sObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('Test Price Book'),
                PriceBook2.Description => ValueProviderBuilder.provideUniqueString('test price book products'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<sObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => '[{"id":"18","version":"1","packageInfo":{"id":1950464001,"catalogId":"18",'
                + '"version":"1","name":"Office Standard 1/2/100/1000+ Lines - 5100/5101/5102/5103"},"productName":'
                + '"Office","duration":"Annual","edition":{"id":1,"name":"Standard"},"contract":{"id":"a8f550000004G4tAAE"'
                + ',"extId":"Office","billingId":"45035001"},"offerType":"Regular","poc":null,"globalPackageLimits":'
                + '[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount",'
                + '"scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":'
                + '"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null}]'
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES})
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> standardPBEs = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(products),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'})
            .quantity(2)
            .create()
            .getRecords();

        OpportunityTotals.bypassOpportnuityUpdate = true;
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(products),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(standardPBEs),
                QuoteLineItem.QuoteId => q.Id,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.EffectivePriceNew__c => 10,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 4
                })
            .quantity(2)
            .create()
            .getRecords();
        OpportunityTotals.bypassOpportnuityUpdate = false;

        QuoteLineItemSelector selector = new QuoteLineItemSelector();
        List<QuoteLineItem> qlisWithRequiredFields = selector
            .selectQuoteLineItems()
            .selectFields(selector.getFieldsForQLIsByQuote())
            .executeQuery();

        Decimal expectedFreeDiscountResult = 0;
        Integer specialTerms = 2;

        Test.startTest();
            Map<String, Decimal> res = QuoteHelper.calculateFreeValuesOnQuote(qlisWithRequiredFields, specialTerms);
        Test.stopTest();

        for (QuoteLineItem qli : qlisWithRequiredFields) {
            expectedFreeDiscountResult += qli.EffectivePriceNew__c * qli.NewQuantity__c * specialTerms;
        }
        System.assertEquals(expectedFreeDiscountResult, res.get('freeDiscount'), 'Free Discount value calculated incorrectly');
    }

    @isTest
    private static void verifyIsEntitlementPackageOfferTypeReturnCorrectValues() {
        Entitlement__c entFree = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setField(Entitlement__c.PackageOfferType__c, 'Free')
            .build()
            .getRecord();
        Entitlement__c entTrial = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setField(Entitlement__c.PackageOfferType__c, 'Trial')
            .build()
            .getRecord();
        Entitlement__c entPoc = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setField(Entitlement__c.PackageOfferType__c, 'ProofOfConcept')
            .build()
            .getRecord();

        System.assertEquals(true, QuoteHelper.isEntitlementPackageOfferTypeFree(entFree), 'isEntitlementPackageOfferTypeFree return incorrect value');
        System.assertEquals(true, QuoteHelper.isEntitlementPackageOfferTypeTrial(entTrial), 'isEntitlementPackageOfferTypeTrial return incorrect value');
        System.assertEquals(true, QuoteHelper.isEntitlementPackageOfferTypePOC(entPoc), 'isEntitlementPackageOfferTypePOC return incorrect value');

        System.assertEquals(false, QuoteHelper.isEntitlementPackageOfferTypeFree(entPoc), 'isEntitlementPackageOfferTypeFree return incorrect value');
        System.assertEquals(false, QuoteHelper.isEntitlementPackageOfferTypeTrial(entFree), 'isEntitlementPackageOfferTypeTrial return incorrect value');
        System.assertEquals(false, QuoteHelper.isEntitlementPackageOfferTypePOC(entTrial), 'isEntitlementPackageOfferTypePOC return incorrect value');
    }

    @isTest
    private static void testGetApprovedBICountry() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            String res = QuoteHelper.getApprovedBICountryFromQuote(testQuote);
        Test.stopTest();

        System.assertEquals('USA', res, '"USA" should be returned as an Approved BI Country');
    }

    @isTest
    private static void testGetApprovedBICountry_PackageInfoEmpty() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

            Test.startTest();
                String res = QuoteHelper.getApprovedBICountryFromQuote(testQuote);
            Test.stopTest();

        System.assertEquals('', res, 'No Approved BI Country should be returned for a quote with empty Package_Info__c');
    }

    @isTest
    private static void testGetApprovedBICountry_PackageInfoHasNoBI() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .create()
            .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            NGBSTestDataGenerator.generateQuotePackageInfo(),
            List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities = null;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Package_Info__c => JSON.serialize(pInfo)
                }
            )
            .create()
            .getRecord();

            Test.startTest();
                String res = QuoteHelper.getApprovedBICountryFromQuote(testQuote);
            Test.stopTest();

        System.assertEquals('', res, 'No Approved BI Country should be returned for a quote no business identities on Package_Info__c');
    }

    @isTest
    private static void testCalcTotalProServSOWDiscount() {

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
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
                }
            )
            .create()
            .getRecord();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.ExtID__c => ValueProviderBuilder.provideUniqueString(),
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_PROSERV,
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        List<PricebookEntry> pbes = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    PricebookEntry.UnitPrice => 1,
                    PricebookEntry.IsActive => true
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PriceBookEntryId => ValueProviderBuilder.provideParents(pbes),
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.UnitPrice => 1,
                    QuoteLineItem.Discount_number__c => 1,
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        Test.startTest();

            List<QuoteLineItem> reselectedQlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .selectFields(
                    new Set<String>{
                        'Discount_number__c',
                        'Discount_type__c',
                        'UnitPrice',
                        'Quantity',
                        'Entitlement__c',
                        'Product2.Sub_Category__c',
                        'Product2.Charge_Term__c'
                    }
                )
                .executeQuery();

                System.assertEquals(
                    30,
                    QuoteHelper.calcTotalProServSOWDiscount(reselectedQlis),
                    'calcTotalProServSOWDiscount should return summ of discounts miltiplied by quantity for OneTime Proserv products'
                );

        Test.stopTest();
    }

    @isTest
    private static void testIsProServSyncRequired() {

        Quote testProservQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                    Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_CANCELLED
                }
            )
            .build()
            .getRecord();

        Test.startTest();

            System.assertEquals(
                false,
                QuoteHelper.isProServSyncRequired(null),
                'isProServSyncRequired should return false is passed parameter is null'
            );

            System.assertEquals(
                false,
                QuoteHelper.isProServSyncRequired(testProservQuote),
                'isProServSyncRequired should return false is passed Quote has ProServ_Status__c "Cancelled"'
            );

            testProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SYNCED;
            System.assertEquals(
                false,
                QuoteHelper.isProServSyncRequired(testProservQuote),
                'isProServSyncRequired should return false is passed Quote has ProServ_Status__c "Synced"'
            );

            testProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_OUT_FOR_SIGNATURE;
            System.assertEquals(
                false,
                QuoteHelper.isProServSyncRequired(testProservQuote),
                'isProServSyncRequired should return false is passed Quote has ProServ_Status__c "Out for Signature"'
            );

            testProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SOLD;
            System.assertEquals(
                false,
                QuoteHelper.isProServSyncRequired(testProservQuote),
                'isProServSyncRequired should return false is passed Quote has ProServ_Status__c "Sold"'
            );

            testProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_IN_PROGRESS;
            System.assertEquals(
                true,
                QuoteHelper.isProServSyncRequired(testProservQuote),
                'isProServSyncRequired should return true is passed Quote has ProServ_Status__c "In progress"'
            );

            testProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CREATED;
            System.assertEquals(
                true,
                QuoteHelper.isProServSyncRequired(testProservQuote),
                'isProServSyncRequired should return true is passed Quote has ProServ_Status__c "Created"'
            );
        Test.stopTest();
    }

    @isTest
    private static void testIsProservSoldRequired() {

        Quote testProservQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                    Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_CANCELLED
                }
            )
            .build()
            .getRecord();

        Quote testCCProservQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_CC_PROSERV,
                    Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_CANCELLED
                }
            )
            .build()
            .getRecord();

        Test.startTest();

            System.assertEquals(
                false,
                QuoteHelper.isProservSoldRequired(null),
                'isProservSoldRequired should return false is passed parameter is null'
            );

            // verify proserv quote
            System.assertEquals(
                false,
                QuoteHelper.isProservSoldRequired(testProservQuote),
                'isProservSoldRequired should return false is passed Quote has ProServ_Status__c "Cancelled"'
            );

            testProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SOLD;
            System.assertEquals(
                false,
                QuoteHelper.isProservSoldRequired(testProservQuote),
                'isProservSoldRequired should return false is passed Quote has ProServ_Status__c "Sold"'
            );

            testProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CREATED;
            System.assertEquals(
                true,
                QuoteHelper.isProservSoldRequired(testProservQuote),
                'isProservSoldRequired should return true is passed Quote has ProServ_Status__c "Created"'
            );

            testProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SYNCED;
            System.assertEquals(
                true,
                QuoteHelper.isProservSoldRequired(testProservQuote),
                'isProservSoldRequired should return true is passed Quote has ProServ_Status__c "Synced"'
            );

            testProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_OUT_FOR_SIGNATURE;
            System.assertEquals(
                true,
                QuoteHelper.isProservSoldRequired(testProservQuote),
                'isProservSoldRequired should return true is passed Quote has ProServ_Status__c "Out for Signature"'
            );

            testProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_IN_PROGRESS;
            System.assertEquals(
                true,
                QuoteHelper.isProservSoldRequired(testProservQuote),
                'isProservSoldRequired should return true is passed Quote has ProServ_Status__c "In progress"'
            );


            // verify cc proserv quote
            System.assertEquals(
                false,
                QuoteHelper.isProservSoldRequired(testCCProservQuote),
                'isProservSoldRequired should return false is passed Quote has ProServ_Status__c "Cancelled"'
            );

            testCCProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SOLD;
            System.assertEquals(
                false,
                QuoteHelper.isProservSoldRequired(testCCProservQuote),
                'isProservSoldRequired should return false is passed Quote has ProServ_Status__c "Sold"'
            );

            testCCProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CREATED;
            System.assertEquals(
                true,
                QuoteHelper.isProservSoldRequired(testCCProservQuote),
                'isProservSoldRequired should return true is passed Quote has ProServ_Status__c "Created"'
            );

            testCCProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SYNCED;
            System.assertEquals(
                true,
                QuoteHelper.isProservSoldRequired(testCCProservQuote),
                'isProservSoldRequired should return true is passed Quote has ProServ_Status__c "Synced"'
            );

            testCCProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_OUT_FOR_SIGNATURE;
            System.assertEquals(
                true,
                QuoteHelper.isProservSoldRequired(testCCProservQuote),
                'isProservSoldRequired should return true is passed Quote has ProServ_Status__c "Out for Signature"'
            );

            testCCProservQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_IN_PROGRESS;
            System.assertEquals(
                true,
                QuoteHelper.isProservSoldRequired(testCCProservQuote),
                'isProservSoldRequired should return true is passed Quote has ProServ_Status__c "In progress"'
            );
        Test.stopTest();
    }

    @isTest
    private static void testIsDownsell() {

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Quantity => -1
                }
            )
            .build()
            .getRecords();

        Test.startTest();
            System.assertEquals(
                true,
                QuoteHelper.isDownsell(qliList),
                'isDownsell should return true if QuoteLineItem.Quantity < 0'
            );

            for (QuoteLineItem qli : qliList) {
                qli.Quantity = 0;
            }
            System.assertEquals(
                false,
                QuoteHelper.isDownsell(qliList),
                'isDownsell should return false if QuoteLineItem.Quantity == 0'
            );

            for (QuoteLineItem qli : qliList) {
                qli.Quantity = 1;
            }
            System.assertEquals(
                false,
                QuoteHelper.isDownsell(qliList),
                'isDownsell should return false if QuoteLineItem.Quantity > 0'
            );
        Test.stopTest();
    }

    @isTest
    private static void testIsCCProServEngagementRequired() {

        Triggers.switchOff();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
                }
            )
            .create()
            .getRecord();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.ExtID__c => ValueProviderBuilder.provideUniqueString(),
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME
                }
            )
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbes = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    PricebookEntry.UnitPrice => 1,
                    PricebookEntry.IsActive => true
                }
            )
            .quantity(4)
            .create()
            .getRecords();

        List<Entitlement__c> entlsList = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Entitlement__c.Account__c => testOpp.AccountId,
                    Entitlement__c.Quote__c => testQuote.Id,
                    Entitlement__c.Product__c => ValueProviderBuilder.provideParents(testProducts)
                }
            )
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PriceBookEntryId => ValueProviderBuilder.provideParents(pbes),
                    QuoteLineItem.Entitlement__c => ValueProviderBuilder.provideParents(entlsList),
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.UnitPrice => 1,
                    QuoteLineItem.Discount_number__c => 1,
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                }
            )
            .quantity(4)
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();

            Quote primarySalesQuote = (Quote) new QuoteSelector()
                .selectQuotes()
                .selectFields(
                    new Set<String>{
                        'Id',
                        'RecordTypeId',
                        'Upsell_Status__c'
                    }
                )
                .subselect(
                    new QuoteLineItemSelector()
                        .selectQuoteLineItems()
                        .selectFields(
                            new Set<String>{
                                'Id',
                                'QuoteId',
                                'Quantity',
                                'Zero_Quantity__c',
                                'Deactivated__c',
                                'Entitlement__c',
                                'Product2.Family'
                            }
                        )
                )
                .executeQuery()
                .get(0);

            System.assertEquals(
                true,
                QuoteHelper.isCCProServEngagementRequired(primarySalesQuote, null),
                'isCCProServEngagementRequired should return true if SalesQuote has CCProducts With Entitlemtns'
            );

        Test.stopTest();
    }

    @isTest
    private static void testIsTermsLessYearMethod() {

        System.assertEquals(
            false,
            QuoteHelper.isTermsLessYear(null),
            'method should return "false" value if passed parameter is null'
        );

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Initial_Term_months__c => '10'
                }
            )
            .build()
            .getRecord();

        System.assertEquals(
            true,
            QuoteHelper.isTermsLessYear(testQuote),
            'method should return "true" value if Quote has Initial_Term_months__c less than 12'
        );


        testQuote.Initial_Term_months__c = null;
        testQuote.Term_months__c = '10';

        System.assertEquals(
            true,
            QuoteHelper.isTermsLessYear(testQuote),
            'method should return "true" value if Quote has Term_months__c less than 12'
        );


        testQuote.Initial_Term_months__c = '15';
        testQuote.Term_months__c = '15';

        System.assertEquals(
            false,
            QuoteHelper.isTermsLessYear(testQuote),
            'method should return "false" value if Quote has Term_months__c or Initial_Term_months__c more than 12'
        );


        testQuote.Initial_Term_months__c = null;
        testQuote.Term_months__c = null;

        System.assertEquals(
            false,
            QuoteHelper.isTermsLessYear(testQuote),
            'method should return "false" value if Quote has Term_months__c and Initial_Term_months__c has empty(null) values'
        );
    }

    @isTest
    private static void testisQuoteOutOfContract() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Account.Name => 'Test Account',
                                Account.Active_Sales_Agreement__c => '123778899'
                        }
                )
                .build()
                .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Opportunity.Name => 'Test Opportunity',
                                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                                Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                        }
                )
                .build()
                .getRecord();

        testOpportunity.Account = testAccount;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.Initial_Term_months__c => '24'
                        }
                )
                .build()
                .getRecord();

        testQuote.Opportunity = testOpportunity;

        System.assertEquals(
                false,
                QuoteHelper.isQuoteOutOfContract(null),
                'method should return "false" value if passed parameter is null'
        );

        System.assertEquals(
                false,
                QuoteHelper.isQuoteOutOfContract(testQuote),
                'method should return "false" value if Quote has no Package_Info__c'
        );

        testQuote.Package_Info__c = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
                'ContractId' => '5'
        });
        System.assertEquals(
                false,
                QuoteHelper.isQuoteOutOfContract(testQuote),
                'method should return "false" value if Quote has Package_Info__c contains "contract.Id"'
        );


        testQuote.Package_Info__c = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
                'ContractId' => null
        });
        testOpportunity.Type = OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS;
        System.assertEquals(
                false,
                QuoteHelper.isQuoteOutOfContract(testQuote),
                'method should return "false" value if Quote has Opportunity.Type != "Existing Business"'
        );

        testOpportunity.Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS;
        testAccount.Active_Sales_Agreement__c = null;
        System.assertEquals(
                false,
                QuoteHelper.isQuoteOutOfContract(testQuote),
                'method should return "false" value if Quote has no Opportunity.Account.Active_Sales_Agreement__c'
        );

        testAccount.Active_Sales_Agreement__c = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();
        System.assertEquals(
                true,
                QuoteHelper.isQuoteOutOfContract(testQuote),
                'method should return "true" value if Quote has Opportunity.Type = "Existing Business" ' +
                        'AND Opportunity.Account.Active_Sales_Agreement__c != null ' +
                        'AND Package_Info__c not contains "contract.Id"'
        );
    }

    @isTest
    private static void testIsPhoenix() {
        new SObjectBuilder(NGBS_Phoenix_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableBrands__c => OpportunityHelper.BRAND_RINGCENTRAL,
            NGBS_Phoenix_Settings__c.NGBSPhoenixAvailablePackageIDs__c => '100;200',
            NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableProducts__c => 'Meetings'
        })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Meetings',
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1)
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote 1'),
                Quote.OpportunityId => opp.Id,
                Quote.Package_Info__c => ValueProviderBuilder.provideList(new List<String>{'[{"id":"100","version":"1","packageInfo":{"catalogId":"100","version":"1"}}]', '[{"id":"101","version":"1","packageInfo":{"catalogId":"101","version":"1"}}]'}),
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => ValueProviderBuilder.provideList(new List<Boolean>{true,false})
            })
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();

        System.assert(!QuoteHelper.isPhoenix(new Quote()), 'verify isPhoenix is false if it calls without quote');

        System.assert(QuoteHelper.isPhoenix(quotes[0]), 'verify isPhoenix is true for phoenix quote');
        System.assert(!QuoteHelper.isPhoenix(quotes[1]), 'verify isPhoenix is false for non-phoenix quote');

        Test.stopTest();
    }

    @isTest
    private static void verifyThatCrossUpgradeShouldReturnFalseForCaseWithoutPreviousPackageInfo() {

        String packageInfo = '[{"productName":"Fax"}]';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Package_Info__c => packageInfo
                }
            )
            .build()
            .getRecord();

        System.assert(!QuoteHelper.isCrossUpgrade(testQuote), 'Method should return false due to previousPackageInfo not exist');
    }

    private static User createUser(String name, Boolean insertUser){
        return createUser(name, insertUser, false);
    }

    @isTest
    private static void verifyThatCrossUpgradeShouldReturnTrueForCrossUpgrade() {
        BillingWrappers.QuotePackageInfo qpi = new BillingWrappers.QuotePackageInfo();
        qpi.packageInfo.id = '18';
        qpi.existingPackageInfo = new BillingWrappers.ExistingPackageInfo();
        qpi.existingPackageInfo.productName = 'Fax';
        qpi.productName = 'Office';
        String packageInfo = JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{qpi});

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Package_Info__c => packageInfo
                }
            )
            .build()
            .getRecord();

        System.assert(QuoteHelper.isCrossUpgrade(testQuote), 'Method should return true due to cross upgrade');
    }

    @isTest
    private static void verifyThatCrossUpgradeShouldReturnFalseForNonCrossUpgrade() {

        String packageInfo = '[{"existingPackageInfo":{"productName":"Fax"},"productName":"Fax"}]';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Package_Info__c => packageInfo
                }
            )
            .build()
            .getRecord();

        System.assert(!QuoteHelper.isCrossUpgrade(testQuote), 'Method should return false due to NON cross upgrade');
    }

    @isTest
    private static void testIsPhoneLeasingEnabledMethod() {

        System.assertEquals(
            true,
            QuoteHelper.isPhoneLeasingEnabled(null, null, null),
            'method QuoteHelper.isPhoneLeasingEnabled should return true if passed parameters are null'
        );

        System.assertEquals(
            true,
            QuoteHelper.isPhoneLeasingEnabled(null, null, new List<QuoteLineItem>()),
            'method QuoteHelper.isPhoneLeasingEnabled should return true if ' +
            'it not Phoenx quote, not Indian opportunity and quoteLineItems list are empty'
        );

        System.assertEquals(
            false,
            QuoteHelper.isPhoneLeasingEnabled(true, false, null),
            'method QuoteHelper.isPhoneLeasingEnabled should return false if it is Phoenix quote(first param)'
        );

        System.assertEquals(
            false,
            QuoteHelper.isPhoneLeasingEnabled(false, true, null),
            'method QuoteHelper.isPhoneLeasingEnabled should return false if it is Indian Opportunity(second param)'
        );

        Test.startTest();
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
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
                }
            )
            .create()
            .getRecord();
        Test.stopTest();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.ExtID__c => Product2Helper.SUBSCRIPTION_LICENSE
                }
            )
            .create()
            .getRecord();

        PricebookEntry testPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 1,
                    PricebookEntry.IsActive => true
                }
            )
            .create()
            .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PriceBookEntryId => testPbe.Id,
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.UnitPrice => 1,
                    QuoteLineItem.PackageInfo__c => '{"isPhoneLeasingEnabled":1}'
                }
            )
            .create()
            .getRecord();

        List<QuoteLineItem> reselectedQlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(
                new Set<String>{
                    'PackageInfo__c',
                    'Product_Lic_Id__c'
                }
            )
            .executeQuery();

        System.assertEquals(
            true,
            QuoteHelper.isPhoneLeasingEnabled(null, null, reselectedQlis),
            'method QuoteHelper.isPhoneLeasingEnabled should return true if ' +
            'subscription license(LC_SC_29) has "isPhoneLeasingEnabled" equal to 1'
        );
    }

    @isTest
    private static void testGetSubscriptionMethod() {

        System.assertEquals(
            null,
            QuoteHelper.getSubscription(null),
            'method QuoteHelper.getSubscription should return null if passed param is null'
        );

        System.assertEquals(
            null,
            QuoteHelper.getSubscription(new List<QuoteLineItem>()),
            'method QuoteHelper.getSubscription should return null if passed param is empty list'
        );

        System.assertEquals(
            null,
            QuoteHelper.getSubscription(new List<QuoteLineItem>{ new QuoteLineItem() }),
            'method QuoteHelper.getSubscription should return null if passed list does not contain Subscription qli'
        );

        Test.startTest();
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
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
                }
            )
            .create()
            .getRecord();
        Test.stopTest();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.ExtID__c => Product2Helper.SUBSCRIPTION_LICENSE
                }
            )
            .create()
            .getRecord();

        PricebookEntry testPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 1,
                    PricebookEntry.IsActive => true
                }
            )
            .create()
            .getRecord();

        QuoteLineItem testSubscriptionQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PriceBookEntryId => testPbe.Id,
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.UnitPrice => 1,
                    QuoteLineItem.PackageInfo__c => '{"isPhoneLeasingEnabled":1}'
                }
            )
            .create()
            .getRecord();

        List<QuoteLineItem> reselectedQlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(
                new Set<String>{
                    'PackageInfo__c',
                    'Product_Lic_Id__c'
                }
            )
            .executeQuery();

        QuoteLineItem subscription = QuoteHelper.getSubscription(reselectedQlis);

        System.assertEquals(
            testSubscriptionQli.Id,
            subscription.Id,
            'method QuoteHelper.getSubscription should return null if passed list does not contain Subscription qli'
        );
    }

    @isTest
    private static void testFilterProservQuotes() {

        Quote testBillingQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .build()
            .getRecord();

        Quote testProServQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
                }
            )
            .build()
            .getRecord();

        List<Quote> proservQuotesList = QuoteHelper.filterProservQuotes(
            new List<Quote>{testBillingQuote, testProServQuote},
            true
        );
        System.assertEquals(1, proservQuotesList.size(), 'method should return List with proserv quotes');
        System.assertEquals(
            QuoteHelper.RT_ID_PROSERV,
            proservQuotesList.get(0).RecordTypeId,
            'method should return List with proserv quotes'
        );


        List<Quote> notProservQuotesList = QuoteHelper.filterProservQuotes(
            new List<Quote>{testBillingQuote, testProServQuote},
            false
        );
        System.assertEquals(1, notProservQuotesList.size(), 'method should return List with not proserv quotes');
        System.assertEquals(
            QuoteHelper.RT_ID_BILLING,
            notProservQuotesList.get(0).RecordTypeId,
            'method should return List with not proserv quotes'
        );
    }

    @isTest
    private static void testPullApproversFromMainQuote() {

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.IsPrimary__c => ValueProviderBuilder.provideList(new List<Boolean>{ true, false }),
                Quote.RecordTypeId => ValueProviderBuilder.provideList(
                    new List<String>{ QuoteHelper.RT_ID_BILLING, QuoteHelper.RT_ID_CC }
                ),
                Quote.Approved_Status__c => ValueProviderBuilder.provideList(
                    new List<String>{ QuoteHelper.APPROVAL_STATUS_APPROVED, QuoteHelper.APPROVAL_STATUS_REQUIRED }
                )
            })
            .quantity(2)
            .build()
            .getRecords();

        Quote primaryQuote = testQuotes.get(0);
        Quote nonPrimaryQuote = testQuotes.get(1);

        List<User> testApprovers = (List<User>) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.Id => ValueProviderBuilder.provideDummyId(User.SObjectType),
                User.FirstName => ValueProviderBuilder.provideUniqueString('FirstName_'),
                User.LastName => ValueProviderBuilder.provideUniqueString('LastName_')
            })
            .quantity(2)
            .build()
            .getRecords();

        primaryQuote.Level_1_Approver__r = testApprovers.get(0);
        primaryQuote.Level_2_Approver__r = testApprovers.get(0);
        primaryQuote.Level_3_Approver__r = testApprovers.get(0);
        primaryQuote.Level_4_Approver__r = testApprovers.get(0);
        primaryQuote.Level_5_Approver__r = testApprovers.get(0);

        nonPrimaryQuote.Level_1_Approver__r = testApprovers.get(1);
        nonPrimaryQuote.Level_2_Approver__r = testApprovers.get(1);
        nonPrimaryQuote.Level_3_Approver__r = testApprovers.get(1);
        nonPrimaryQuote.Level_4_Approver__r = testApprovers.get(1);
        nonPrimaryQuote.Level_5_Approver__r = testApprovers.get(1);

        QuoteHelper.pullApproversFromMainQuote(testQuotes);

        System.assertEquals(
            primaryQuote.Approved_Status__c,
            nonPrimaryQuote.Approved_Status__c,
            'Approved_Status__c field value should be copied from priamry quote'
        );

        System.assertEquals(
            primaryQuote.Level_1_Approver__r.Id,
            nonPrimaryQuote.Level_1_Approver__r.Id,
            'Level_1_Approver__c field value should be copied from priamry quote'
        );
        System.assertEquals(
            primaryQuote.Level_2_Approver__r.Id,
            nonPrimaryQuote.Level_2_Approver__r.Id,
            'Level_2_Approver__c field value should be copied from priamry quote'
        );
        System.assertEquals(
            primaryQuote.Level_3_Approver__r.Id,
            nonPrimaryQuote.Level_3_Approver__r.Id,
            'Level_3_Approver__c field value should be copied from priamry quote'
        );
        System.assertEquals(
            primaryQuote.Level_4_Approver__r.Id,
            nonPrimaryQuote.Level_4_Approver__r.Id,
            'Level_4_Approver__c field value should be copied from priamry quote'
        );
        System.assertEquals(
            primaryQuote.Level_5_Approver__r.Id,
            nonPrimaryQuote.Level_5_Approver__r.Id,
            'Level_5_Approver__c field value should be copied from priamry quote'
        );
    }

    @isTest
    private static void testGetBillingQuoteProductName() {

        Quote testBillingQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                }
            )
            .build()
            .getRecord();

        System.assertEquals(
            'Office',
            QuoteHelper.getBillingQuoteProductName(testBillingQuote),
            'method should return "productName" from Package_Info__c'
        );
    }

    @isTest
    private static void testIsQuotePackageInfoHasMultipleProducts() {

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                }
            )
            .build()
            .getRecord();

        System.assertEquals(
            false,
            QuoteHelper.isQuotePackageInfoHasMultipleProducts(testQuote),
            'Method should return false if Package_Info__c on Quote has only one "productId"'
        );

        testQuote.Package_Info__c = NGBSTestDataGenerator.generateMultiProductQuotePackageInfo();

        System.assertEquals(
            true,
            QuoteHelper.isQuotePackageInfoHasMultipleProducts(testQuote),
            'Method should return true if Package_Info__c on Quote has multiple "productId"'
        );
    }

    @isTest
    private static void testGetProductNames() {
        String pInfo = NGBSTestDataGenerator.generateMultiProductQuotePackageInfo();
        List<String> productNames = QuoteHelper.getProductNames(pInfo);

        System.assertEquals(4, productNames.size(), 'Method should return all 4 service names');
    }

    @isTest
    private static void testPopulateAddressOnQuote() {

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.BillingPostalCode => '44131',
                    Account.BillingCity => 'Independence',
                    Account.BillingCountry => 'United States',
                    Account.BillingState => 'Ohio',
                    Account.BillingStreet => '4053 Flynn Street'
                }
            )
            .build()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'test Quote'
                }
            )
            .build()
            .getRecord();

        QuoteHelper.populateAddressOnQuote(qt, acc);

        System.assertEquals(
            acc.BillingPostalCode,
            qt.Postal_Code__c,
            'Quote.Postal_Code__c field should be populated with Account.BillingPostalCode value'
        );
        System.assertEquals(
            acc.BillingCity,
            qt.City__c,
            'Quote.City__c field should be populated with Account.BillingCity value'
        );
        System.assertEquals(
            acc.BillingCountry,
            qt.Country__c,
            'Quote.Country__c field should be populated with Account.BillingCountry value'
        );
        System.assertEquals(
            acc.BillingState,
            qt.State__c,
            'Quote.State__c field should be populated with Account.BillingState value'
        );
        System.assertEquals(
            acc.BillingStreet,
            qt.Address_Line__c,
            'Quote.Address_Line__c field should be populated with Account.BillingStreet value'
        );
    }

    @isTest
    private static void testIsHasErrors() {

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'test Quote',
                    Quote.InvalidDiscountedPhonesQuantity__c => true,
                    Quote.InvalidGlobalOfficePhonesQuantity__c => true,
                    Quote.InvalidLimitedExtensionPhonesQuantity__c => true,
                    Quote.Invalid_Number_of_800_Setups__c => true,
                    Quote.Invalid_Number_of_Int_TF_Setups__c => true,
                    Quote.Invalid_Number_of_Vanity_Setups__c => true,
                    Quote.Required_Area_Codes_are_empty__c => true,
                    Quote.Invalid_GO_LE_Phones_Quantity__c => true
                }
            )
            .build()
            .getRecord();

        final String fieldsList = '(InvalidDiscountedPhonesQuantity__c, InvalidGlobalOfficePhonesQuantity__c, ' +
            'InvalidLimitedExtensionPhonesQuantity__c, Invalid_Number_of_800_Setups__c, ' +
            'Invalid_Number_of_Int_TF_Setups__c, Invalid_Number_of_Vanity_Setups__c, ' +
            'Required_Area_Codes_are_empty__c, Invalid_GO_LE_Phones_Quantity__c)';

        System.assertEquals(
            true,
            QuoteHelper.isHasErrors(qt),
            'method "QuoteHelper.isHasErrors" should return true if any of the fields' + fieldsList +' are true'
        );

        qt.InvalidDiscountedPhonesQuantity__c = false;
        System.assertEquals(
            true,
            QuoteHelper.isHasErrors(qt),
            'method "QuoteHelper.isHasErrors" should return true if any of the fields' + fieldsList +' are true'
        );

        qt.InvalidGlobalOfficePhonesQuantity__c = false;
        System.assertEquals(
            true,
            QuoteHelper.isHasErrors(qt),
            'method "QuoteHelper.isHasErrors" should return true if any of the fields' + fieldsList +' are true'
        );

        qt.InvalidLimitedExtensionPhonesQuantity__c = false;
        System.assertEquals(
            true,
            QuoteHelper.isHasErrors(qt),
            'method "QuoteHelper.isHasErrors" should return true if any of the fields' + fieldsList +' are true'
        );

        qt.Invalid_Number_of_800_Setups__c = false;
        System.assertEquals(
            true,
            QuoteHelper.isHasErrors(qt),
            'method "QuoteHelper.isHasErrors" should return true if any of the fields' + fieldsList +' are true'
        );

        qt.Invalid_Number_of_Int_TF_Setups__c = false;
        System.assertEquals(
            true,
            QuoteHelper.isHasErrors(qt),
            'method "QuoteHelper.isHasErrors" should return true if any of the fields' + fieldsList +' are true'
        );

        qt.Invalid_Number_of_Vanity_Setups__c = false;
        System.assertEquals(
            true,
            QuoteHelper.isHasErrors(qt),
            'method "QuoteHelper.isHasErrors" should return true if any of the fields' + fieldsList +' are true'
        );

        qt.Required_Area_Codes_are_empty__c = false;
        System.assertEquals(
            true,
            QuoteHelper.isHasErrors(qt),
            'method "QuoteHelper.isHasErrors" should return true if any of the fields' + fieldsList +' are true'
        );

        qt.Invalid_GO_LE_Phones_Quantity__c = false;
        System.assertEquals(
            false,
            QuoteHelper.isHasErrors(qt),
            'method "QuoteHelper.isHasErrors" should return true if any of the fields' + fieldsList +' are false'
        );
    }

    @isTest
    private static void testHasBillOnBehalfAccount() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'testAcc',
                    Account.BillingStreet => '443 Kearney Frontage',
                    Account.BillingCity => 'Fresno',
                    Account.BillingState => 'CA',
                    Account.BillingPostalCode => '93706',
                    Account.BillingCountry =>'United States',
                    Account.Partner_ID__c => '12345',
                    Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_ATOS_BILL_ON_BEHALF
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => 'testOpp',
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Type => 'Existing Business',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SOBjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId         => testOpp.Id,
                Quote.RecordTypeId          => QuoteHelper.RT_ID_BILLING,
                Quote.IsQuoteHasErrors__c   => false
            })
            .create()
            .getRecord();

        Quote quoteWithAcc = [
            SELECT Account.Partner_ID__c, Account.Partner_Type__c
            FROM Quote
            WHERE Id =:testQuote.Id
        ];

        System.assertEquals(true, QuoteHelper.hasBillOnBehalfAccount(quoteWithAcc),'Non Bill-on-Behalf Account was identified as Bill-on-Behalf');

        testAcc.Partner_ID__c = '12345';
        testAcc.Partner_Type__c = AccountHelper.ACCOUNT_PARTNER_ATOS_BILL_ON_BEHALF;
        update testAcc;

        Quote quoteWithAccUpdated = [
            SELECT Account.Partner_ID__c, Account.Partner_Type__c
            FROM Quote
            WHERE Id =:testQuote.Id
        ];

        System.assertEquals(true, QuoteHelper.hasBillOnBehalfAccount(quoteWithAccUpdated),'Bill-on-Behalf Account was identified as non Bill-on-Behalf');
    }

    private static User createUser(String name, Boolean insertUser, Boolean addManager){
        User user = new User(
            Username = name+'!user@gmail.com',
            LastName = 'Test'+name,
            Email = name+'_user@gmail.com',
            Alias = 'test'+name,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = SYSTEM_ADMIN_PROFILE_ID,
            LanguageLocaleKey = 'en_US'
        );
        if(addManager){
            user.ManagerId = UserInfo.getUserId();
        }
        if(insertUser) {
            insert user;
        }
        return user;
    }

    private static void assignManager(User u, User manager){
        u.ManagerId = manager.Id;
        update u;
    }

    private static Account createAccount(String name){
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    @isTest
    private static void testIsQuotingAvailableForBrand_noConfig() {
        System.assert(
            QuoteHelper.isQuotingAvailableForBrand('testBrand', true),
            'Should return true if no brand config is populated for the brand'
        );
    }

    @isTest
    private static void testIsQuotingAvailableForBrand_isEnabled() {
        new SObjectBuilder(LeadConversionConfiguration__c.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                LeadConversionConfiguration__c.Name => OpportunityHelper.BRAND_RINGCENTRAL,
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => true,
                LeadConversionConfiguration__c.IsQuotingAvailableExistingBusiness__c => true
            }
        )
        .create();

        System.assert(
            QuoteHelper.isQuotingAvailableForBrand(OpportunityHelper.BRAND_RINGCENTRAL, true),
            'Should return true for the brand with quoting enabled for new business'
        );
        System.assert(
            QuoteHelper.isQuotingAvailableForBrand(OpportunityHelper.BRAND_RINGCENTRAL, false),
            'Should return true for the brand with quoting enabled for existing business'
        );
    }

    @isTest
    private static void testIsQuotingAvailableForBrand_isDisabled() {
        new SObjectBuilder(LeadConversionConfiguration__c.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                LeadConversionConfiguration__c.Name => RingCentralHelper.BRAND_RINGCENTRAL,
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => false,
                LeadConversionConfiguration__c.IsQuotingAvailableExistingBusiness__c => false
            }
        )
        .create();

        System.assert(
            !QuoteHelper.isQuotingAvailableForBrand(OpportunityHelper.BRAND_RINGCENTRAL, true),
            'Should return false for the brand with quoting disabled for new business'
        );

        System.assert(
            !QuoteHelper.isQuotingAvailableForBrand(OpportunityHelper.BRAND_RINGCENTRAL, false),
            'Should return false for the brand with quoting disabled for existing business'
        );
    }

    @isTest
    static void testGetOldPackageName() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => RingCentralHelper.BRAND_VODAFONE,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Package_Info__c => '[{"version":"1","trial":null,"productName":"Office","productId":"2","poc":null,"permissions":null,"packageInfo":{"version":"1","oldPackageName":"RingCentral Office Premium","name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024","id":"62554005","displayName":"RingCentral Office Standard","catalogId":"65"},"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"defaultBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"approvedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}}},"offerType":"Regular","id":"65","globalPackageLimits":[{"value":"6000","transactionType":"Any","target":"Global","scope":"BillingCycle","name":"Monthly money amount limit","limitType":null,"isOverride":null,"code":"MONTHLY_AMOUNT_LIMIT"}],"existingPackageInfo":{"version":"1","productName":"Office","offerType":"ProofOfConcept","id":"162"},"edition":{"name":"Standard","id":"1"},"duration":"Annual","contract":{"status":"new","id":"a8f2H0000008XMHQA2","extId":"Office_Europe","billingId":"36061005"}}]'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            String res = QuoteHelper.getOldPackageNameFromQuote(testQuote);
        Test.stopTest();

        System.assertEquals('RingCentral Office Premium', res, 'Old package name is wrong');
    }

    @isTest
    static void testGetNewPackageName() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => RingCentralHelper.BRAND_VODAFONE,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Package_Info__c => '[{"version":"1","trial":null,"productName":"Office","productId":"2","poc":null,"permissions":null,"packageInfo":{"version":"1","oldPackageName":"RingCentral Office Premium","name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024","id":"62554005","displayName":"RingCentral Office Standard","catalogId":"65"},"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"defaultBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"approvedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}}},"offerType":"Regular","id":"65","globalPackageLimits":[{"value":"6000","transactionType":"Any","target":"Global","scope":"BillingCycle","name":"Monthly money amount limit","limitType":null,"isOverride":null,"code":"MONTHLY_AMOUNT_LIMIT"}],"existingPackageInfo":{"version":"1","productName":"Office","offerType":"ProofOfConcept","id":"162"},"edition":{"name":"Standard","id":"1"},"duration":"Annual","contract":{"status":"new","id":"a8f2H0000008XMHQA2","extId":"Office_Europe","billingId":"36061005"}}]'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            String res = QuoteHelper.getNewPackageNameFromQuote(testQuote);
        Test.stopTest();

        System.assertEquals('RingCentral Office Standard', res, 'New package name is wrong');
    }

    @isTest
    private static void testGetApprovedBiId() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .create()
                .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                        }
                )
                .create()
                .getRecord();

        Test.startTest();
        String res = QuoteHelper.getApprovedBiIdFromQuote(testQuote);
        Test.stopTest();

        System.assertEquals('20', res, '"20" should be returned as an Approved BI Id');
    }

    @isTest
    private static void testGetApprovedBiId_PackageInfoEmpty() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .create()
                .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId()
                        }
                )
                .create()
                .getRecord();

        Test.startTest();
        String res = QuoteHelper.getApprovedBiIdFromQuote(testQuote);
        Test.stopTest();

        System.assertEquals('', res, 'No Approved BI Id should be returned for a quote with empty Package_Info__c');
    }

    @isTest
    private static void testGetApprovedBiId_PackageInfoHasNoBI() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities = null;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Test.startTest();
        String res = QuoteHelper.getApprovedBiIdFromQuote(testQuote);
        Test.stopTest();

        System.assertEquals('', res, 'No Approved BI Id should be returned for a quote no business identities on Package_Info__c');
    }

    @isTest
    private static void testIsBillingCountryMatchRcEuBIForGermanyBiPositive() {
        Triggers.switchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'Germany'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '33';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Boolean res = QuoteHelper.isBillingCountryMatchBI(reselectedQuote);
        Test.stopTest();

        System.assertEquals(true, res, 'Billing country on account should be Germany or Austria for German business identity');
    }

    @isTest
    private static void testIsBillingCountryMatchRcEuBIForGermanyBiNegative() {
        Triggers.switchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'France'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '33';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Boolean res = QuoteHelper.isBillingCountryMatchBI(reselectedQuote);
        Test.stopTest();

        System.assertEquals(false, res, 'Billing country on account should be Germany or Austria for German business identity');
    }

    @isTest
    private static void testIsBillingCountryMatchRcEuBIForFranceBiPositive() {
        Triggers.switchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'France'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '1';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Boolean res = QuoteHelper.isBillingCountryMatchBI(reselectedQuote);
        Test.stopTest();

        System.assertEquals(true, res, 'Billing country on account can not be Germany or Austria for French business identity');
    }

    @isTest
    private static void testIsBillingCountryMatchRcEuBIForFranceBiNegative() {
        Triggers.switchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'Germany'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '1';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Boolean res = QuoteHelper.isBillingCountryMatchBI(reselectedQuote);
        Test.stopTest();

        System.assertEquals(false, res, 'Billing country on account can not be Germany or Austria for French business identity');
    }

    @isTest
    static void testIsInvoiceOnBehalf() {
        System.assert(
            QuoteHelper.isInvoiceOnBehalf(QuoteHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF),
            'Invoice on behalf payment method verification was expected'
        );
    }

    @isTest
    static void testIsAnnual() {
        Quote annualQt = new Quote(Payment_Plan__c = QuoteHelper.PAYMENT_PLAN_ANNUAL);
        Quote nonAnnual = new Quote(Payment_Plan__c = 'non annual');

        Test.startTest();
            Boolean whenAnnual = QuoteHelper.isAnnual(annualQt);
            Boolean whenNonAnnual = QuoteHelper.isAnnual(nonAnnual);
            Boolean whenNull = QuoteHelper.isAnnual(null);
        Test.stopTest();

        Assert.isTrue(whenAnnual, 'Annual payment plan should be recognized');
        Assert.isFalse(whenNonAnnual, 'Non-annual payment plan should not be treated as annual');
        Assert.isFalse(whenNull, 'When no Quote is provided, the method should return false');
    }

    @isTest
    private static void testIsNGBSPartnerPackageChanged() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => System.today(),
                Opportunity.PriceBook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.packageInfo.catalogId = '1';
        pInfo.packageInfo.version = '2';
        pInfo.duration = 'Monthly';
        pInfo.partnerPackage = new BillingWrappers.PartnerPackageInfo();
        pInfo.partnerPackage.id = '3';
        pInfo.partnerPackage.version = 4;

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfo})
            })
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Service',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Quote__c => qt.Id,
                Entitlement__c.Product__c => prod.Id
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.PricebookEntryId => standardPrice.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Entitlement__c => ent.Id
            })
            .create()
            .getRecord();

        PartnerOperationsLog__c partnerOperationsLog = (PartnerOperationsLog__c) new SObjectBuilder(PartnerOperationsLog__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isRejected__c => false,
                PartnerOperationsLog__c.isCompleted__c => false
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        Boolean resultFirst = QuoteHelper.isPartnerOperationsLogExists(qt);
        Boolean resultSecond = QuoteHelper.isNGBSPartnerPackageChange(qt, new List<QuoteLineItem>{qli});
        Test.stopTest();

        System.assertEquals(true, resultFirst);
        System.assertEquals(true, resultSecond);
    }

    @isTest
    private static void testIsBillingCountryMatchSwissBiMVPPositive() {
        Triggers.switchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'Switzerland'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '58';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Boolean res = QuoteHelper.isBillingCountryMatchBI(reselectedQuote);
        Test.stopTest();

        System.assertEquals(true, res, 'Billing country on account should be Switzerland for MVP Swiss business identity');
    }

    @isTest
    private static void testIsBillingCountryMatchSwissBiMVPNegative() {
        Triggers.switchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'Germany'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '58';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Boolean res = QuoteHelper.isBillingCountryMatchBI(reselectedQuote);
        Test.stopTest();

        System.assertEquals(false, res, 'Billing country on account should be Switzerland for MVP Swiss business identity');
    }

    @isTest
    private static void testIsDQGoaEnabled() {

        new SobjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c, true)
            .create();

        Account testAccPOC = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'testAcc',
                    Account.Offer_Type__c => 'POC',
                    Account.Billing_Id__c => '12345678'
                }
            )
            .create()
            .getRecord();

        Opportunity testOppPOCtoPaid = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => testAccPOC.Id
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
                }
            )
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => ValueProviderBuilder.provideList(new List<String>{
                        'Billing Quote',
                        'POC Quote',
                        'Contact Center Quote',
                        'Billing POC-to-Paid Quote'
                    }),
                    Quote.OpportunityId => ValueProviderBuilder.provideList(new List<Id>{
                        testOpp.Id,
                        testOpp.Id,
                        testOpp.Id,
                        testOppPOCtoPaid.Id
                    }),
                    Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id>{
                        QuoteHelper.RT_ID_BILLING, QuoteHelper.RT_ID_POC, QuoteHelper.RT_ID_CC, QuoteHelper.RT_ID_BILLING
                    })
                }
            )
            .quantity(4)
            .create()
            .getRecords();

        List<Quote> reselectedQuotes = (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<String>{
                'Name',
                'Account.RC_User_ID__c',
                'Account.Billing_ID__c',
                'Account.Offer_Type__c',
                'Account.RC_Account_Status__c',
                'IsPRMQuote__c'
            })
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{
                new Set<Id>{
                    testQuotes.get(0).Id,
                    testQuotes.get(1).Id,
                    testQuotes.get(2).Id,
                    testQuotes.get(3).Id
                }
            })
            .executeQuery();

        Quote billingQuoteNewBusiness;
        Quote billingQuotePOCtoPaid;
        Quote pocQuote;
        Quote contactCenterQuote;
        for (Quote qt : reselectedQuotes) {
            if (qt.Name == 'Billing Quote') {
                billingQuoteNewBusiness = qt;
                billingQuoteNewBusiness.Package_Info__c = NGBSTestDataGenerator.generateQuotePackageInfo();
            }
            if (qt.Name == 'POC Quote') {
                pocQuote = qt;
            }
            if (qt.Name == 'Contact Center Quote') {
                contactCenterQuote = qt;
            }
            if (qt.Name == 'Billing POC-to-Paid Quote') {
                billingQuotePOCtoPaid = qt;
            }
        }

        User testUserWithPermissionSet = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testUser',
                    User.Username => 'testUser@ringcentral.com',
                    User.Email => 'testUser@gmail.com',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.CommunityNickname => 'Test052323'
                }
            )
            .create()
            .getRecord();

        List<PermissionSet> permissionSet = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = 'AllowTargetPriceCalculationAndDQBasedGOA'
        ];

        Test.startTest();
        if(!permissionSet.isEmpty()) {
            insertPermissionSetAssignmentInFuture(permissionSet[0].Id, testUserWithPermissionSet.Id);
        }
        Test.stopTest();

        System.runAs(testUserWithPermissionSet) {
            System.assert(
                QuoteHelper.isDQGoaEnabled(billingQuoteNewBusiness),
                'method should return true if Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c is enabled and it is New Business Billing Quote'
            );

            System.assert(
                QuoteHelper.isDQGoaEnabled(billingQuotePOCtoPaid),
                'method should return true if Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c is enabled and it is POC-to-Paid scenario'
            );

            System.assert(
                QuoteHelper.isDQGoaEnabled(contactCenterQuote),
                'method should return false if Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c is enabled and it is New Business Contact Center Quote'
            );

            System.assert(
                !QuoteHelper.isDQGoaEnabled(pocQuote),
                'method should return true if Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c is enabled and it is New Business POC Quote'
            );
        }
    }

    @Future
    public static void insertPermissionSetAssignmentInFuture(Id permissionSetId, Id assigneeId){
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(PermissionSetId = permissionSetId, AssigneeId = assigneeId);
        insert permissionSetAssignment;
    }

    @IsTest
    public static void testIsMultiProductQuoteHasServicePackage() {
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Quote masterQuote = TestDataGenerator.createMasterQuote(masterOpp);

        Test.startTest();
        Boolean result = QuoteHelper.isMultiProductQuoteHasServicePackage(masterQuote, QuoteHelper.NGBS_RCCC_PRODUCT);
        Test.stopTest();
        System.assert(result, 'Service not found');
    }

    @IsTest
    public static void testCreateTechnicalQuotes() {
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Quote masterQuote = TestDataGenerator.createMasterQuote(masterOpp);

        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByService = new Map<String, BillingWrappers.QuoteWrapper> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => new BillingWrappers.QuoteWrapper(),
            QuoteHelper.NGBS_RCCC_PRODUCT => new BillingWrappers.QuoteWrapper(),
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => new BillingWrappers.QuoteWrapper(),
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => new BillingWrappers.QuoteWrapper()
        };

        for (String service : quoteInfoByService.keySet()) {
            BillingWrappers.QuoteWrapper quoteInfo = quoteInfoByService.get(service);
            quoteInfo.quoteType = QuoteHelper.QUOTE_TYPE_AGREEMENT;
            quoteInfo.name = String.format('Updated name (technical quote for service {0})', new List<Object> { service });
        }

        List<String> serviceList = new List<String>(quoteInfoByService.keySet());
        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceList);
        Map<String, Opportunity> serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(masterOpp.Id, serviceAccounts, serviceList);

        List<BillingWrappers.QuotePackageInfo> masterQuotePackageInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            masterQuote.Package_Info__c,
            List<BillingWrappers.QuotePackageInfo>.class
        );

        Test.startTest();
        Map<String, Quote> result = QuoteHelper.upsertTechnicalQuotes(masterQuote.Id, quoteInfoByService);
        Test.stopTest();

        System.assertNotEquals(true, result.isEmpty(), 'result should not be empty');
        System.assertEquals(4, result.size(), 'result should contain 4 entries');

        for(String service : result.keySet()) {
            Quote technicalQuote = result.get(service);
            Opportunity technicalOpp = serviceOpportunities.get(service);
            BillingWrappers.QuoteWrapper quoteInfo = quoteInfoByService.get(service);

            System.assertNotEquals(
                null, technicalQuote,
                'technical quote should be created'
            );
            System.assertEquals(
                service, technicalQuote.ServiceName__c,
                'technical quote service name should be filled'
            );
            System.assertEquals(
                masterQuote.Id, technicalQuote.MasterQuote__c,
                'technical quote should be linked to master quote'
            );
            System.assertEquals(
                true, technicalQuote.IsMultiProductTechnicalQuote__c,
                'technical quote multiproduct flag set'
            );
            System.assertEquals(
                quoteInfo.name, technicalQuote.Name,
                'updated technical quote name'
            );
            System.assertEquals(
                QuoteHelper.QUOTE_TYPE_AGREEMENT, technicalQuote.QuoteType__c,
                'updated technical quote type'
            );

            if (service == QuoteHelper.NGBS_OFFICE_PRODUCT) {
                System.assertNotEquals(
                    true, technicalQuote.isPrimary__c,
                    String.format('technical quote for {0} should be primary', new List<Object> { service })
                );
                System.assertEquals(
                    masterQuote.OpportunityId, technicalQuote.OpportunityId,
                    String.format('technical quote for {0} should be linked master Opportunity', new List<Object> { service })
                );
                System.assertEquals(
                    masterQuote.Enabled_LBO__c, technicalQuote.Enabled_LBO__c,
                    String.format('technical quote for {0} should be copied from master', new List<Object> { service })
                );
            } else {
                System.assertEquals(
                    true, technicalQuote.isPrimary__c,
                    String.format('technical quote for {0} should be primary', new List<Object> { service })
                );
                System.assertEquals(
                    technicalOpp.Id, technicalQuote.OpportunityId,
                    String.format('technical quote for {0} should be linked technical Opportunity', new List<Object> { service })
                );
                System.assertEquals(
                    false, technicalQuote.Enabled_LBO__c,
                    String.format('technical quote for {0} should always be false', new List<Object> { service })
                );
            }

            for (BillingWrappers.QuotePackageInfo pInfo : masterQuotePackageInfo) {
                if (pInfo.productName == service) {
                    System.assertEquals(
                        pInfo.packageInfo.displayName, technicalQuote.PackageNameNew__c,
                        'technical quote PackageNameNew__c should match the selected package'
                    );
                }
            }
        }
    }

    @IsTest
    private static void testCreateTechnicalQuotes_multipleMasterQuotes() {
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Quote masterQuote1 = TestDataGenerator.createMasterQuote(masterOpp);
        Quote masterQuote2 = TestDataGenerator.createMasterQuote(masterOpp);

        BillingWrappers.QuoteWrapper officeQuoteInfo = new BillingWrappers.QuoteWrapper();
        officeQuoteInfo.quoteType = QuoteHelper.QUOTE_TYPE_AGREEMENT;

        BillingWrappers.QuoteWrapper rccQuoteInfo = new BillingWrappers.QuoteWrapper();
        rccQuoteInfo.quoteType = QuoteHelper.QUOTE_TYPE_AGREEMENT;

        BillingWrappers.QuoteWrapper edQuoteInfo = new BillingWrappers.QuoteWrapper();
        edQuoteInfo.quoteType = QuoteHelper.QUOTE_TYPE_AGREEMENT;

        BillingWrappers.QuoteWrapper evQuoteInfo = new BillingWrappers.QuoteWrapper();
        evQuoteInfo.quoteType = QuoteHelper.QUOTE_TYPE_AGREEMENT;

        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByService = new Map<String, BillingWrappers.QuoteWrapper> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => officeQuoteInfo,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => edQuoteInfo
        };

        Test.startTest();

        List<String> serviceList = new List<String>(quoteInfoByService.keySet());
        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceList);
        Map<String, Opportunity> serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(masterOpp.Id, serviceAccounts, serviceList);


        Map<String, Quote> result1 = QuoteHelper.upsertTechnicalQuotes(masterQuote1, quoteInfoByService, serviceOpportunities);
        serviceOpportunities = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterOpp);
        Map<String, Quote> result2 = QuoteHelper.upsertTechnicalQuotes(masterQuote2, quoteInfoByService, serviceOpportunities);
        result1 = QuoteHelper.getTechnicalQuotesByMasterId(masterQuote1.Id, serviceList);
        result2 = QuoteHelper.getTechnicalQuotesByMasterId(masterQuote2.Id, serviceList);
        Test.stopTest();

        System.assertEquals(false, result1.get(QuoteHelper.NGBS_OFFICE_PRODUCT).isPrimary__c);
        System.assertEquals(false, result1.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).isPrimary__c);
        System.assertEquals(false, result2.get(QuoteHelper.NGBS_OFFICE_PRODUCT).isPrimary__c);
        System.assertEquals(false, result2.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).isPrimary__c);
    }

    @IsTest
    private static void testUpdateTechnicalQuotes()
    {
        Triggers.switchOff();
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Quote masterQuote = TestDataGenerator.createMasterQuote(masterOpp);
        Triggers.switchOn();

        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByService = new Map<String, BillingWrappers.QuoteWrapper> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => new BillingWrappers.QuoteWrapper(),
            QuoteHelper.NGBS_RCCC_PRODUCT => new BillingWrappers.QuoteWrapper(),
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => new BillingWrappers.QuoteWrapper(),
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => new BillingWrappers.QuoteWrapper()
        };

        List<String> serviceList = new List<String>(quoteInfoByService.keySet());
        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceList);
        Map<String, Opportunity> serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(masterOpp.Id, serviceAccounts, serviceList);
        Test.startTest();
        Map<String, Quote> result = QuoteHelper.upsertTechnicalQuotes(masterQuote, quoteInfoByService, serviceOpportunities);

        BillingWrappers.QuoteWrapper mvpQuoteWrapper = new BillingWrappers.QuoteWrapper();
        mvpQuoteWrapper.id = result.get(QuoteHelper.NGBS_OFFICE_PRODUCT).Id;
        mvpQuoteWrapper.quoteType = QuoteHelper.QUOTE_TYPE_AGREEMENT;
        mvpQuoteWrapper.enabledLBO = true;

        BillingWrappers.QuoteWrapper edQuoteWrapper = new BillingWrappers.QuoteWrapper();
        edQuoteWrapper.id = result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id;
        edQuoteWrapper.name = 'Updated ED quote name';
        edQuoteWrapper.quoteType = QuoteHelper.QUOTE_TYPE_AGREEMENT;
        edQuoteWrapper.enabledLBO = true;

        BillingWrappers.QuoteWrapper evQuoteWrapper = new BillingWrappers.QuoteWrapper();
        evQuoteWrapper.id = result.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Id;
        evQuoteWrapper.name = 'Updated EV quote name';
        evQuoteWrapper.quoteType = QuoteHelper.QUOTE_TYPE_AGREEMENT;
        evQuoteWrapper.enabledLBO = true;

        quoteInfoByService = new Map<String, BillingWrappers.QuoteWrapper> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => mvpQuoteWrapper,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => edQuoteWrapper,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => evQuoteWrapper
        };

        result = QuoteHelper.upsertTechnicalQuotes(masterQuote, quoteInfoByService, serviceOpportunities);
        result = QuoteHelper.getTechnicalQuotesByMasterId(masterQuote.Id, serviceList);
        Test.stopTest();

        System.assertEquals(4, result.size(), 'result should contain 4 entries, contains');

        Quote officeQuote = result.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        Quote rcQuote = result.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Quote edQuote = result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Quote evQuote = result.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        System.assertEquals(
            String.format('Quote For Tests [system: {0}]', new List<Object> { QuoteHelper.NGBS_OFFICE_PRODUCT }), officeQuote.Name,
            'name for office quote was not updated'
        );
        System.assertEquals(
            QuoteHelper.QUOTE_TYPE_AGREEMENT, officeQuote.QuoteType__c,
            'quote type for office quote was not updated'
        );
        System.assertEquals(
            true, officeQuote.Enabled_LBO__c,
            'enabledLBO for mvp quote set to true'
        );
        System.assertEquals(
            String.format('Quote For Tests [system: {0}]', new List<Object> { QuoteHelper.NGBS_RCCC_PRODUCT }), rcQuote.Name,
            'name for rc contact center quote was not updated'
        );
        System.assertEquals(
            edQuoteWrapper.name, edQuote.Name,
            'name for ed quote was updated'
        );
        System.assertEquals(
            QuoteHelper.QUOTE_TYPE_AGREEMENT, edQuote.QuoteType__c,
            'quote type for ed quote was updated'
        );
        System.assertEquals(
            evQuoteWrapper.name, evQuote.Name,
            'name for ev quote was updated'
        );
        System.assertEquals(
            QuoteHelper.QUOTE_TYPE_AGREEMENT, evQuote.QuoteType__c,
            'quote type for ev quote was updated'
        );
        System.assertEquals(
            false, evQuote.Enabled_LBO__c,
            'enabledLBO for ev quote set to false'
        );
        System.assertEquals(
            false, edQuote.Enabled_LBO__c,
            'enabledLBO for ed quote set to false'
        );
    }

    @isTest
    static void testmakePrimaryQuote() {
        List<Account> accList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .quantity(2)
            .setField(Account.Name,
                ValueProviderBuilder.provideList(new List<String>{
                    'Existing Business Account',
                    'Master Account'
                })
            )
            .create()
            .getRecords();
        Account existingBusinessAcc = accList.get(0);
        Account masterAccount = accList.get(1);

        Triggers.switchOff();
        List<Opportunity> optyList = (List<Opportunity>) new SOBjectBuilder(Opportunity.sObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .setField(Opportunity.Name,
                ValueProviderBuilder.provideList(new List<String>{
                    'New Business Oppty',
                    'Master Account Oppty'
                })
            )
            .setField(Opportunity.AccountId,
                ValueProviderBuilder.provideList(new List<Id>{
                    existingBusinessAcc.Id,
                    masterAccount.Id
                })
            )
            .create()
            .getRecords();
        Triggers.switchOn();

        Opportunity newBusinessOppty = optyList.get(0);
        Opportunity masterAccOppty = optyList.get(1);

        Quote parentQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => masterAccOppty.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId()
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .quantity(4)
            .setField(Quote.Name,
                ValueProviderBuilder.provideList(new List<String>{
                    'Initial Sales Primary Quote',
                    'Initial Sales Not Primary Quote',
                    'Initial POC Primary Quote',
                    'Initial POC Not Primary Quote'
                    }
                )
            )
            .setField(Quote.RecordTypeId,
                ValueProviderBuilder.provideList(new List<Id>{
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_POC,
                    QuoteHelper.RT_ID_POC
                    }
                )
            )
            .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_NEW_CUSTOMER)
            .setField(Quote.OpportunityId, newBusinessOppty.Id)
            .setField(Quote.ParentQuote__c,
                ValueProviderBuilder.provideList(new List<Id>{
                    parentQuote.Id,
                    null,
                    null,
                    null
                })
            )
            .setField(Quote.Start_Date__c, ValueProviderBuilder.provideUniqueDate())
            .setField(Quote.End_Date__c, ValueProviderBuilder.provideUniqueDate())
            .setField(Quote.IsPrimary__c,
                ValueProviderBuilder.provideList(new List<Boolean>{
                    true, false, true, false
                    }
                )
            )
            .setField(Quote.QuoteType__c, QuoteHelper.QUOTE_TYPE_QUOTE)
            .setField(Quote.PriceBook2Id, Test.getStandardPricebookId())
            .create()
            .getRecords();

        Quote quoteWillBeNotPrimary = quotes[0];
        Quote quoteWillBePrimary = quotes[1];
        Quote quotePocWillNotBePrimary = quotes[2];
        Quote quotePocWillBePrimary = quotes[3];

        List<Quote> quoteList = (List<Quote>) new QuoteSelector()
            .selectQuotesForPrimaryProcess(newBusinessOppty.Id, quoteWillBePrimary.Id)
            .executeQuery();

        Test.startTest();
            QuoteHelper.makePrimaryQuote(newBusinessOppty, quoteWillBePrimary.Id, quoteList);


            List<Quote> quoteListPoc = (List<Quote>) new QuoteSelector()
                .selectQuotesForPrimaryProcess(newBusinessOppty.Id, quotePocWillBePrimary.Id)
                 .executeQuery();

            QuoteHelper.makePrimaryQuote(newBusinessOppty, quotePocWillBePrimary.Id, quoteListPoc);
        Test.stopTest();

        Map<Id, Quote> quotesToVerify = new Map<Id, Quote>([
            SELECT Id, RecordTypeId, Name, IsPrimary__c, Upsell_Status__c, ParentQuote__c
            FROM Quote
            WHERE OpportunityId = :newBusinessOppty.Id
        ]);

        System.assertEquals(
            4,
            quotesToVerify.size(),
            'Quote List length should be 4'
        );
        System.assertEquals(
            false,
            quotesToVerify.get(quoteWillBeNotPrimary.Id).IsPrimary__c,
            'Initial primary Sales Quote should be not Primary'
        );
        System.assertEquals(
            true,
            quotesToVerify.get(quoteWillBePrimary.Id).IsPrimary__c,
            'Initial not Primary Sales Quote is now Primary'
        );
        System.assertEquals(
            false,
            quotesToVerify.get(quotePocWillNotBePrimary.Id).IsPrimary__c,
            'Initial primary POC Quote should be not Primary'
        );
        System.assertEquals(
            true,
            quotesToVerify.get(quotePocWillBePrimary.Id).IsPrimary__c,
            'Initial not Primary POC Quote is now Primary'
        );
        System.assertEquals(
            null,
            quotesToVerify.get(quoteWillBeNotPrimary.Id).ParentQuote__c,
            'Initial primary Sales Quote Parent lookUp should be cleared'
        );
        System.assertEquals(
            parentQuote.Id,
            quotesToVerify.get(quoteWillBePrimary.Id).ParentQuote__c,
            'Initial not Primary Sales Quote should get parent from initial Primary Sales Quote'
        );
    }

    @IsTest
    private static void testIsServiceTerminated() {

        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .quantity(3)
            .create()
            .getRecords();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, ValueProviderBuilder.provideList(new List<Id>{testAccounts.get(0).Id, testAccounts.get(1).Id, testAccounts.get(2).Id}))
            .setField(Opportunity.MasterOpportunity__c, testMasterOpportunity.Id)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, true)
            .quantity(3)
            .create()
            .getRecords();

        Test.startTest();
        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{testMasterOpportunity.Id, testOpportunities.get(0).Id, testOpportunities.get(1).Id, testOpportunities.get(2).Id }))
            .setField(Quote.MasterQuote__c, testMasterQuote.Id)
            .setField(Quote.ServiceName__c, ValueProviderBuilder.provideList(new List<String>{
                QuoteHelper.NGBS_RCCC_PRODUCT,
                QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
                QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
            }))
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.IsTermination__c, ValueProviderBuilder.provideList(new List<Boolean>{false, true, true}))
            .quantity(3)
            .create()
            .getRecords();

            Boolean resultCC = QuoteHelper.isServiceTerminated(testMasterQuote.Id, QuoteHelper.NGBS_RCCC_PRODUCT);
            Boolean resultEV = QuoteHelper.isServiceTerminated(testMasterQuote.Id, QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
            Boolean resultED = QuoteHelper.isServiceTerminated(testMasterQuote.Id, QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Test.stopTest();

        System.assertEquals(false, resultCC, 'Contact Center isTerminated has to be false');
        System.assertEquals(true, resultEV, 'Engage Voice isTerminated has to be true');
        System.assertEquals(true, resultED, 'Engage Digital isTerminated has to be true');
    }

    @IsTest
    private static void testClearQuotes() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        update new List<Quote>{
            new Quote(Id = mpStruct.masterQuote.Id, OverallDiscretion__c = 10, AverageDiscount__c = 10, IsDeselected__c = false),
            new Quote(Id = mpStruct.serviceQuotes.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id, OverallDiscretion__c = 10, AverageDiscount__c = 10, IsDeselected__c = false),
            new Quote(Id = mpStruct.serviceQuotes.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id, OverallDiscretion__c = 10, AverageDiscount__c = 10, IsDeselected__c = false)
        };
        Triggers.switchOn();

        Test.startTest();
            List<Quote> qts = QuoteHelper.clearQuotes(
                new Set<Id> { mpStruct.masterQuote.Id},
                new List<String> {QuoteHelper.NGBS_RCCC_PRODUCT }
            );
        Test.stopTest();

        for (Quote qt : qts) {
            System.assertEquals(0, qt.QuoteLineItems.size(), 'quote line items should be cleared');
            System.assertEquals(0, qt.OverallDiscretion__c, 'overall discretion should be cleared');
            System.assertEquals(0, qt.AverageDiscount__c, 'average discount should be cleared');

            if (qt.IsMultiProductTechnicalQuote__c) {
                System.assertEquals(QuoteHelper.NGBS_RCCC_PRODUCT, qt.ServiceName__c, 'contact center quote should be deselected');
                System.assertEquals(true, qt.IsDeselected__c, 'tech quote should be deselected');
            } else {
                System.assertEquals(false, qt.IsDeselected__c, 'master quote should not be deselected');
            }
        }
    }

    @isTest
    static void testIsPocToPaid() {

        Triggers.switchOff();

        Account testAccPoc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.Billing_ID__c => '43243423',
                    Account.Offer_Type__c => AccountHelper.OFFER_TYPE_POC
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccPoc.Id
            })
            .create()
            .getRecord();

        new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote POC-to-Paid',
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.CurrencyIsoCode => 'USD'
            })
            .create();

        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectFields(new List<String>{
                'Account.Billing_ID__c',
                'Account.Offer_Type__c',
                'Account.RC_Account_Status__c'
            })
            .setCondition('Name = \'Test Quote POC-to-Paid\'')
            .executeQuery()
            .get(0);

        Triggers.switchOn();

        Test.startTest();

        Boolean isPocToPaid = AccountHelper.isPocToPaid(reselectedQuote.Account);

        Test.stopTest();

        System.assertEquals(
            true,
            isPocToPaid,
            'Method should return true for POC-to-Paid Quote'
        );
    }

    @isTest
    private static void testIsNotAllDevicesShipped() {
        Triggers.switchOff();
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.Shipping_Tab_New_Business__c => true
            })
            .create()
            .getRecord();

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

        String packageInfoQLI = '{"categoryCode":"HD","discount":{"value":0,"type":"Money"},"duration":"One - Time","id":"18","version":"1","lbox":{"elementID":"LB_698","min":0,"max":99999},"categoryPath":"HD"}';

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
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
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

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.PackageInfo__c => packageInfoQLI,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false
            })
            .quantity(2)
            .create()
            .getRecords();

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '10 Avenue Jean Médecin',
                CustomAddress__c.City__c => 'Nice',
                CustomAddress__c.Country__c => 'France',
                CustomAddress__c.State__c => 'Nice',
                CustomAddress__c.PostalCode__c => '06000'
            })
            .create()
            .getRecord();

        CustomAddressAssignments__c caa = (CustomAddressAssignments__c) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.AttentionTo__c => 'Test France',
                CustomAddressAssignments__c.CustomAddress__c => ca.Id,
                CustomAddressAssignments__c.Quantity__c => 2,
                CustomAddressAssignments__c.QuoteLineItem__c => qlis[0].Id,
                CustomAddressAssignments__c.Type__c => 'Ground'})
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        List<QuoteLineItem> qlisWithCustomAddressAssignments = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsWithCustomAddressAssignments(new List<Object>{new Set<Id>{qt.Id}})
            .executeQuery();
        Boolean isNotAllDevicesShipped = QuoteHelper.isNotAllDevicesShipped(qt, qlisWithCustomAddressAssignments);
        Test.stopTest();

        System.assertEquals(true, isNotAllDevicesShipped, 'Not all devices are shipped');
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testIsQuoteServiceName() {

        Map<String, Boolean> resultMap = new Map<String, Boolean> {
            'isEngage' => QuoteHelper.isEngage(null),
            'isEngageOrInContact' => QuoteHelper.isEngageOrInContact(null),
            'containsOffice' => QuoteHelper.containsOffice(new List<Quote>()),
            'isInContact' => QuoteHelper.isRCCC(null)
        };

        assertQuoteServiceName_negative(resultMap);

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.ServiceName__c => ValueProviderBuilder.provideList(
                    new List<String> {
                        OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE,
                        OpportunityHelper.TIER_OFFICE,
                        OpportunityHelper.TIER_RC_CONTACT_CENTER
                    }),
                Quote.isMultiProductTechnicalQuote__c => true
            })
            .quantity(12)
            .build()
            .getRecords();

        resultMap = new Map<String, Boolean> {
            'isEngage' => QuoteHelper.isEngage(quotes[0]),
            'isEngageOrInContact' => QuoteHelper.isEngageOrInContact(quotes[0]),
            'containsOffice' => QuoteHelper.containsOffice(new List<Quote> { quotes[1] }),
            'isInContact' => QuoteHelper.isRCCC(quotes[2])
        };

        assertQuoteServiceName_positive(resultMap);
    }

    @isTest
    private static void testIsEngageTerminationQuote() {
        Assert.isFalse(
            QuoteHelper.isEngageTerminationQuote(null),
            'isEngageTerminationQuote should return false if passed argument is null'
        );

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(
                Quote.Package_Info__c,
                '[{"id":"5","version":"3","productName":"Office"}]'
            )
            .build()
            .getRecord();

        Assert.isFalse(
            QuoteHelper.isEngageTerminationQuote(qt),
            'isEngageTerminationQuote should return false if quote is not termination'
        );

        qt.isTermination__c = true;

        Assert.isFalse(
            QuoteHelper.isEngageTerminationQuote(qt),
            'isEngageTerminationQuote should return true if quote is not engage'
        );

        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE;
        qt.IsMultiProductTechnicalQuote__c = true;

        Assert.isTrue(
            QuoteHelper.isEngageTerminationQuote(qt),
            'isEngageTerminationQuote should return true if quote is engage termination'
        );
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testGetPaymentMethodFromNGBSAccount() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => '123',
                NGBS_Settings__c.Password__c => '456'
            })
            .create();
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.SelectPackagesByBusinessIdentity__c, true)
            .create();
        Account accountObj = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Payment_Method__c, QuoteHelper.PAYMENT_METHOD_INVOICE)
            .build()
            .getRecord();
        Opportunity oppObj = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.BusinessIdentity__c, '{"currency":"USD","biId":"30"}')
            .build()
            .getRecord();
        Quote quoteObj = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, '[{"id":"1","packageInfo":{"id":"123"}}]')
            .build()
            .getRecord();

        BillingWrappers.NGBSAccount ngbsAccount = (BillingWrappers.NGBSAccount) JSON.deserialize(
            '{"id":"1","packages":[{"id":"123","offerType":"Regular","product":"Office"}]}',
            BillingWrappers.NGBSAccount.class
        );

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);

        Test.startTest();
            String paymentMethod = QuoteHelper.getPaymentMethod(accountObj, oppObj, quoteObj, ngbsAccount);
        Test.stopTest();

        assertGetPaymentMethod(QuoteHelper.PAYMENT_METHOD_CREDIT_CARD, paymentMethod);
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testGetPaymentMethodFromAccount() {
        Account accountObj = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Payment_Method__c, QuoteHelper.PAYMENT_METHOD_INVOICE)
            .build()
            .getRecord();

        Test.startTest();
            String paymentMethod = QuoteHelper.getPaymentMethod(accountObj, null, null, null);
        Test.stopTest();

        assertGetPaymentMethod(accountObj.Payment_Method__c, paymentMethod);
    }

    private static void assertGetPaymentMethod(String paymentMethodActual, String paymentMethodExpected) {
        Assert.isNotNull(paymentMethodExpected, 'Payment method should not be empty');
        Assert.areEqual(paymentMethodExpected, paymentMethodActual, 'Payment method should be - ' + paymentMethodActual);
    }

    private static void assertQuoteServiceName_negative(Map<String, Boolean> resultMap) {
        for (String key : resultMap.keySet()) {
            Assert.isFalse(
                resultMap.get(key),
                String.format('{0} should return false if passed argument is null', new List<Object> { key })
            );
        }
    }

    private static void assertQuoteServiceName_positive(Map<String, Boolean> resultMap) {
        for (String key : resultMap.keySet()) {
            Assert.isTrue(
                resultMap.get(key),
                String.format('{0} should return true', new List<Object> { key })
            );
        }
    }

    @isTest
    private static void testIsNew() {

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER
            })
            .build()
            .getRecord();

        System.assertEquals(
            false,
            QuoteHelper.isNew((Quote)null),
            'method should return false if passed parameter is null'
        );

        System.assertEquals(
            true,
            QuoteHelper.isNew(qt),
            'method should return true if passed parameter is quote with Upsell Status new'
        );
    }

    @IsTest
    static void testUpdateServiceInfo() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => qt.Id,
                ServiceInfo__c.IsProcessOrderSent__c => true
            })
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Product2.Name => 'test'
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => prod.Id,
                        PricebookEntry.IsActive => true
                })
                .create()
                .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        QuoteLineItem.Product2Id => prod.Id,
                        QuoteLineItem.QuoteId => qt.Id,
                        QuoteLineItem.Quantity => 1,
                        QuoteLineItem.PricebookEntryId => standardPrice.Id,
                        QuoteLineItem.UnitPrice => 10
                })
                .create()
                .getRecord();
        Triggers.switchOff();

        List<Quote> quotesList = (List<Quote>) new QuoteSelector()
            .selectQuotesForQuoteLineItemTrigger(new Set<Id>{qt.Id})
            .executeQuery();
        Map<Id, Quote> quotesMapStatic = new Map<Id, Quote>();
        quotesMapStatic.putAll(quotesList);

        Test.startTest();
        QuoteHelper.updateServiceInfo(new Set<Id>{qt.Id}, quotesMapStatic);
        Test.stopTest();

        List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new ServiceInfoSelector()
            .newQueryFactory()
            .selectFields(new List<String>{ 'Id', 'IsProcessOrderSent__c' })
            .setCondition('Quote__c = :bind0')
            .setQueryBindings(new List<Object>{ qt.Id })
            .executeQuery();

        System.assertEquals(1, serviceInfos.size(), 'Only one service info should be created');
        System.assertEquals(false, serviceInfos[0].IsProcessOrderSent__c, 'IsProcessOrderSent__c should be reset to false');
    }

    @IsTest
    static void testUpdateServiceInfoAfterSync() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => qt.Id,
                ServiceInfo__c.IsProcessOrderSent__c => false
            })
            .create()
            .getRecord();

        Test.startTest();
        Triggers.switchOff();
        QuoteHelper.updateServiceInfoAfterSync(qt.Id);
        Triggers.switchOn();
        Test.stopTest();

        ServiceInfo__c serviceInfos = (ServiceInfo__c) new ServiceInfoSelector()
            .newQueryFactory()
            .selectFields(new List<String>{ 'Id', 'IsProcessOrderSent__c' })
            .setCondition('Quote__c = :bind0')
            .setQueryBindings(new List<Object>{ qt.Id })
            .executeQuery()
            .get(0);

        Assert.areEqual(true, serviceInfos.IsProcessOrderSent__c, 'IsProcessOrderSent__c should true');
    }

    @IsTest
    private static void testIsLBOEnabled() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();

        mpStruct.masterQuote.Status = 'Active';
        mpStruct.masterQuote.QuoteType__c = 'Agreement';
        mpStruct.masterQuote.Enabled_LBO__c = true;
        mpStruct.masterQuote.isPrimary__c = true;

        Quote technicalQuote = mpStruct.serviceQuotes.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        technicalQuote.MasterQuote__r = mpStruct.masterQuote;

        mpStruct.masterAccount.Active_Sales_Agreement__c = mpStruct.masterQuote.Id;

        System.assertEquals(
            mpStruct.masterQuote.Enabled_LBO__c,
            QuoteHelper.isLBOEnabled(mpStruct.masterQuote),
            'LBO value should be taken from the quote itself when the quote itself is not technical'
        );

        System.assertEquals(
            mpStruct.masterQuote.Enabled_LBO__c,
            QuoteHelper.isLBOEnabled(technicalQuote),
            'LBO value should be taken from the master quote when the quote itself is technical'
        );
    }

    @isTest
    static void testGetMasterQuoteIdToServiceInfosMap() {

        Triggers.switchOff();
        Account account = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.StageName => 'Prospecting',
                Opportunity.CloseDate => Date.today().addDays(30),
                Opportunity.AccountId => account.Id
            })
            .create()
            .getRecord();


        Quote masterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Master Quote',
                Quote.OpportunityId => opportunity.Id,
                Quote.Status => 'Draft'
            })
            .create()
            .getRecord();

        Quote technicalQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Technical Quote',
                Quote.OpportunityId => opportunity.Id,
                Quote.Status => 'Draft',
                Quote.MasterQuote__c => masterQuote.Id
            })
            .create()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                ServiceInfo__c.Quote__c => technicalQuote.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        Set<Id> masterQuoteIds = new Set<Id>{ masterQuote.Id };
        Map<Id, List<ServiceInfo__c>> result = QuoteHelper.getMasterQuoteIdToServiceInfosMap(masterQuoteIds);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Expected one master quote in the result');
        Assert.areEqual(1, result.get(masterQuote.Id).size(), 'Expected one service info for the master quote');
        Assert.areEqual(serviceInfo.Id, result.get(masterQuote.Id)[0].Id, 'Expected the service info to match the inserted one');
    }

    @IsTest
    static void testBuildTechnicalQuote() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();
        BillingWrappers.QuoteWrapper qw = new BillingWrappers.QuoteWrapper();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Total_First_Year_Cost__c => 1000,
                Quote.Delta_ARR__c => 555,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Id => new ValueProvider.DummyIdProvider(Quote.sObjectType)
            })
            .build()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => dummyAccId,
                Package__c.Account_Package_Id__c => '12345',
                Package__c.Id => new ValueProvider.DummyIdProvider(Package__c.sObjectType)
            })
            .build()
            .getRecord();

        Quote resultQuote = masterQuote.clone(false, true, false, false);
        Test.startTest();
            resultQuote = QuoteHelper.buildTechnicalQuote(
                qw,
                dummyOppId,
                QuoteHelper.NGBS_OFFICE_PRODUCT,
                masterQuote,
                resultQuote,
                new List<Package__c>{ pkg },
                null,
                true
            );

            Assert.areEqual(masterQuote.Total_First_Year_Cost__c, resultQuote.Total_First_Year_Cost__c, 'value should be copied from master quote');
            Assert.areEqual(masterQuote.Delta_ARR__c, resultQuote.Delta_ARR__c, 'value should be copied from master quote');

            qw.totalFirstYearCost = 10;
            qw.deltaARR = 55;
            resultQuote = QuoteHelper.buildTechnicalQuote(
                qw,
                dummyOppId,
                QuoteHelper.NGBS_OFFICE_PRODUCT,
                masterQuote,
                resultQuote,
                new List<Package__c>{ pkg },
                null,
                true
            );
            Assert.areEqual(qw.totalFirstYearCost, resultQuote.Total_First_Year_Cost__c, 'Value should be copied from quote wrapper');
            Assert.areEqual(qw.deltaARR, resultQuote.Delta_ARR__c, 'Value should be copied from quote wrapper');
        Test.stopTest();
    }

    @isTest
    static void testIsNewBusiness() {
        final Integer TEST_RECORDS_AMOUNT = 3;

        List<String> billingIds = new List<String> { null, BILLING_ID, null };
        List<String> rcUserIds = new List<String> { null, null, RC_USER_ID };
        List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.RC_User_ID__c => ValueProviderBuilder.provideList(rcUserIds),
                Account.Billing_ID__c => ValueProviderBuilder.provideList(billingIds)
            })
            .quantity(TEST_RECORDS_AMOUNT)
            .build()
            .getRecords();
        Account newBusinessAcc = testAccs[0];
        Account onlyBillingAcc = testAccs[1];
        Account onlyRcUserAcc = testAccs[2];

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.BillingPackage__c => null
            })
            .build()
            .getRecord();
        testQuote = putAccIntoQuote(testQuote, newBusinessAcc);

        Test.startTest();
            Boolean whenTechnicalQuoteAndPackageNameIsEmpty = QuoteHelper.isNewBusiness(testQuote);

            testQuote.BillingPackage__c = (String) ValueProviderBuilder.provideDummyId(Package__c.SObjectType).getValue();
            Boolean whenTechnicalQuoteAndPackageNameOld = QuoteHelper.isNewBusiness(testQuote);

            testQuote.IsMultiProductTechnicalQuote__c = false;
            Boolean whenSingleQuoteAndNewBusinessAcc = QuoteHelper.isNewBusiness(testQuote);

            testQuote = putAccIntoQuote(testQuote, onlyBillingAcc);
            Boolean whenSingleQuoteAndOnlyBillingAcc = QuoteHelper.isNewBusiness(testQuote);

            testQuote = putAccIntoQuote(testQuote, onlyRcUserAcc);
            Boolean whenSingleQuoteAndOnlyRcUserAcc = QuoteHelper.isNewBusiness(testQuote);

            Boolean whenNullQuote = QuoteHelper.isNewBusiness(null);
        Test.stopTest();

        Assert.isFalse(whenNullQuote, 'Method should return false if passed parameter is null');
        Assert.isTrue(whenTechnicalQuoteAndPackageNameIsEmpty, 'Method should return true if given a technical quote with an empty package name');
        Assert.isFalse(whenTechnicalQuoteAndPackageNameOld, 'Method should return false if given a technical quote with package name old');
        Assert.isTrue(whenSingleQuoteAndNewBusinessAcc, 'Method should return true if given a single quote and new account has no ids');
        Assert.isFalse(whenSingleQuoteAndOnlyBillingAcc, 'Method should return false if single quote and Account has Billing Id');
        Assert.isFalse(whenSingleQuoteAndOnlyRcUserAcc, 'Method should return false if single quote and Account has RC User Id');
    }

    @IsTest
    private static void testHasActiveProServQuotes() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                    Opportunity.Is_Billing_Opportunity__c => true
                })
                .create()
                .getRecord();

        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.ProductName = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id>{
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_PROSERV,
                    QuoteHelper.RT_ID_CC_PROSERV
                }),
                Quote.Package_Info__c => ValueProviderBuilder.provideList(new List<String>{
                    JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfo}),
                    '',
                    ''
                }),
                Quote.ProServ_Status__c => ValueProviderBuilder.provideList(new List<String>{
                    '',
                    QuoteHelper.PROSERVSTATUS_IN_PROGRESS,
                    QuoteHelper.PROSERVSTATUS_IN_PROGRESS
                }),
                Quote.IsPrimary__c => ValueProviderBuilder.provideList(new List<Boolean>{
                    true,
                    false,
                    false
                })
            })
            .quantity(3)
            .build()
            .getRecords();
        
        Test.startTest();
        
            // Case 1: ProServ in primary quote
            Assert.isTrue(QuoteHelper.hasNonCancelledProServ(new List<Quote>{quotes[0]}), 
                'Should return true when primary quote contains ProServ service');
            
            // Case 2: not cancelled ProServ quote
            Assert.isTrue(QuoteHelper.hasNonCancelledProServ(new List<Quote>{quotes[1]}), 
                'Should return true when ProServ quote is active');
            
            // Case 3: not cancelled ProServ quote
            Assert.isTrue(QuoteHelper.hasNonCancelledProServ(new List<Quote>{quotes[2]}), 
                'Should return true when ProServ quote is active');
            
            // Case 4: Cancelled ProServ quote
            quotes[1].ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
            Assert.isFalse(QuoteHelper.hasNonCancelledProServ(new List<Quote>{quotes[1]}), 
                'Should return false when ProServ quote is cancelled');
        
        Test.stopTest();
    }

    @isTest
    static void testQuotesStorage() {
        // Create test quotes with SObjectBuilder
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.CloseDate, System.today())
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Master Quote')
            .setField(Quote.OpportunityId, testOpp.Id)
            .create()
            .getRecord();

        Quote technicalQuote1 = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Technical Quote 1')
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.MasterQuote__c, masterQuote.Id)
            .create()
            .getRecord();

        Quote technicalQuote2 = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Technical Quote 2')
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.MasterQuote__c, masterQuote.Id)
            .create()
            .getRecord();

        List<Quote> quotes = new List<Quote>{masterQuote, technicalQuote1, technicalQuote2};

        Test.startTest();
            QuoteHelper.QuotesStorage storage = new QuoteHelper.QuotesStorage(quotes);
        Test.stopTest();

        // Verify the QuotesStorage correctly separates master quote from technical quotes
        System.assertEquals(masterQuote.Id, storage.masterQuote.Id, 'Master quote should be identified correctly');
        System.assertEquals(2, storage.technicalQuotes.size(), 'Should have 2 technical quotes');

        // Verify technical quotes contain the right quotes
        Set<Id> technicalQuoteIds = new Set<Id>();
        for(Quote qt : storage.technicalQuotes) {
            technicalQuoteIds.add(qt.Id);
        }
        System.assert(technicalQuoteIds.contains(technicalQuote1.Id), 'Technical quotes should include the first technical quote');
        System.assert(technicalQuoteIds.contains(technicalQuote2.Id), 'Technical quotes should include the second technical quote');
    }

    @isTest
    static void testGetNumberFromString() {
        Test.startTest();
            Integer result1 = QuoteHelper.getNumberFromString('Test123');
            Integer result2 = QuoteHelper.getNumberFromString('456Test');
            Integer result3 = QuoteHelper.getNumberFromString('Test 789 String');
            Integer result4 = QuoteHelper.getNumberFromString('NoNumbers');
            Integer result5 = QuoteHelper.getNumberFromString('');
        Test.stopTest();

        System.assertEquals(123, result1, 'Should extract numbers from the end of string');
        System.assertEquals(456, result2, 'Should extract numbers from the beginning of string');
        System.assertEquals(789, result3, 'Should extract numbers from the middle of string');
        System.assertEquals(null, result4, 'Should return null for string without numbers');
        System.assertEquals(null, result5, 'Should return null for empty string');
    }

    @isTest
    static void testGetTemplate() {
        // Create test templates
        String templateName1 = QuoteHelper.TOTAL_CHANGES_TEMPLATE;
        String templateName2 = QuoteHelper.CHANGED_DETAILS_TEMPLATE;

        RC_Quote_Templates__c template1 = new RC_Quote_Templates__c(
            Name = templateName1,
            TemplateId__c = 'template1Id'
        );

        RC_Quote_Templates__c template2 = new RC_Quote_Templates__c(
            Name = templateName2,
            TemplateId__c = 'template2Id'
        );

        // Insert custom settings
        insert new List<RC_Quote_Templates__c>{template1, template2};

        Test.startTest();
            String resultTemplate1 = QuoteHelper.getTemplate(templateName1);
            String resultTemplate2 = QuoteHelper.getTemplate(templateName2);
            String resultTemplateNonExistent = QuoteHelper.getTemplate('NonExistentTemplate');
            String resultTemplateNull = QuoteHelper.getTemplate(null);
        Test.stopTest();

        // Verify templates are retrieved correctly
        System.assertEquals('template1Id', resultTemplate1, 'Should return correct template ID for template1');
        System.assertEquals('template2Id', resultTemplate2, 'Should return correct template ID for template2');
        System.assertEquals(null, resultTemplateNonExistent, 'Should return null for non-existent template');
        System.assertEquals(null, resultTemplateNull, 'Should return null when templateName is null');
    }

    @isTest
    static void testGetQuoteById() {
        // Create test account and opportunity with SObjectBuilder
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.CloseDate, System.today())
            .create()
            .getRecord();

        // Create test quotes
        Quote quote1 = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Quote 1')
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .create()
            .getRecord();

        Quote quote2 = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Quote 2')
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .create()
            .getRecord();

        List<Quote> quoteList = new List<Quote>{quote1, quote2};

        Test.startTest();
            Quote result1 = QuoteHelper.getQuoteById(quoteList, quote1.Id);
            Quote result2 = QuoteHelper.getQuoteById(quoteList, quote2.Id);
            Quote resultNonExistent = QuoteHelper.getQuoteById(quoteList, UserInfo.getUserId()); // Using User ID as a non-existent Quote ID
            Quote resultNull = QuoteHelper.getQuoteById(quoteList, null);
            Quote resultEmptyList = QuoteHelper.getQuoteById(new List<Quote>(), quote1.Id);
            Quote resultNullList = QuoteHelper.getQuoteById(null, quote1.Id);
        Test.stopTest();

        // Verify quotes are retrieved correctly
        System.assertEquals(quote1.Id, result1.Id, 'Should return correct quote for quote1 ID');
        System.assertEquals(quote2.Id, result2.Id, 'Should return correct quote for quote2 ID');
        System.assertEquals(null, resultNonExistent, 'Should return null for non-existent quote ID');
        System.assertEquals(null, resultNull, 'Should return null for null quoteId');
        System.assertEquals(null, resultEmptyList, 'Should return null for empty quote list');
        System.assertEquals(null, resultNullList, 'Should return null for null quote list');
    }

    @isTest
    static void testIsRentalPhonesUpsellInCart() {
        
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.CloseDate, Date.today())
            .create()
            .getRecord();

        Entitlement__c entitlement = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setField(Entitlement__c.Quantity__c, 5)
            .setField(Entitlement__c.Account__c, testAccount.Id)
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, new ValueProvider.ListProvider(new List<String>{
                'Test Rental Phone',
                'Test Regular Product',
                'Test Rental Phone 2'
            }))
            .setField(Product2.Family, new ValueProvider.ListProvider(new List<String>{
                Product2Helper.FAMILY_RENTAL_PHONES,
                'Other',
                Product2Helper.FAMILY_RENTAL_PHONES
            }))
            .setField(Product2.IsActive, true)
            .quantity(3)
            .create()
            .getRecords();

        List<PricebookEntry> pbes = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(products),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .quantity(3)
            .create()
            .getRecords();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.Status, 'Draft')
            .quantity(3)
            .create()
            .getRecords();

        Quote quoteWithRentalUpsell = quotes[0];
        Quote quoteWithoutRental = quotes[1];
        Quote quoteWithRentalNoUpsell = quotes[2];

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, new ValueProvider.ListProvider(new List<Id>{
                quoteWithRentalUpsell.Id,
                quoteWithoutRental.Id,
                quoteWithRentalNoUpsell.Id
            }))
            .setField(QuoteLineItem.PricebookEntryId, new ValueProvider.ListProvider(new List<Id>{
                pbes[0].Id,
                pbes[1].Id,
                pbes[2].Id
            }))
            .setField(QuoteLineItem.Entitlement__c, new ValueProvider.ListProvider(new List<Object>{
                entitlement.Id,
                null,
                entitlement.Id
            }))
            .setField(QuoteLineItem.NewQuantity__c, new ValueProvider.ListProvider(new List<Integer>{
                10,  // Upsell: 10 > 5
                10,  // Regular product
                3    // No upsell: 3 < 5
            }))
            .setField(QuoteLineItem.Quantity, new ValueProvider.ListProvider(new List<Integer>{
                5,
                5,  
                5  
            }))
            .setField(QuoteLineItem.UnitPrice, 100)
            .quantity(3)
            .create();

        Map<Id, Quote> queriedQuotesMap = new Map<Id, Quote>(
            (List<Quote>) new QuoteSelector()
                .selectQuotes()
                .subselect(
                    new QuoteLineItemSelector()
                        .selectQuoteLineItems()
                        .selectFields(new Set<String>{
                            'Id',
                            'Product2Id',
                            'Product2.Family',
                            'Entitlement__c',
                            'Entitlement__r.Quantity__c',
                            'NewQuantity__c'
                        })
                )
                .setCondition('Id IN :bind0')
                .setQueryBindings(new List<Object>{
                    new List<Id>{ quoteWithRentalUpsell.Id, quoteWithoutRental.Id, quoteWithRentalNoUpsell.Id }
                })
                .executeQuery()
        );

        Triggers.switchOn();

        quoteWithRentalUpsell = queriedQuotesMap.get(quoteWithRentalUpsell.Id);
        quoteWithoutRental = queriedQuotesMap.get(quoteWithoutRental.Id);
        quoteWithRentalNoUpsell = queriedQuotesMap.get(quoteWithRentalNoUpsell.Id);

        Test.startTest();
            Boolean resultWithRentalUpsell = QuoteHelper.isRentalPhonesUpsellInCart(quoteWithRentalUpsell);
            Boolean resultWithoutRental = QuoteHelper.isRentalPhonesUpsellInCart(quoteWithoutRental);
            Boolean resultRentalNoUpsell = QuoteHelper.isRentalPhonesUpsellInCart(quoteWithRentalNoUpsell);
        Test.stopTest();

        Assert.isFalse(
            resultWithoutRental, 
            'Should return false when quote has only regular products'
            );
        Assert.isFalse(
            resultRentalNoUpsell, 
            'Should return false when rental phone has no upsell'
            );
        Assert.isTrue(
            resultWithRentalUpsell, 
            'Should return true when rental phone has upsell'
            );
    }
}