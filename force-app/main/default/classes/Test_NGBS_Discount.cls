@isTest
private class Test_NGBS_Discount {

    public static final String TEST_QUOTE_NAME = 'Test_NGBS_Discount';
    private static String SHIPPING_LICENSE_RESPONSE = '[{"elementID":"LC_SHIPT_81","name":"Test Shipping Name - Ground", "displayName":"Test DisplayName","billingType":"testBillingType","searchCategories":[{"key":"ShippingCode","value":"GROUND"}]}, {"elementID":"LC_SHIPT_82","name":"Test Shipping Name - Overnight", "displayName":"Test DisplayName","billingType":"testBillingType","searchCategories":[{"key":"ShippingCode","value":"OVERNIGHT"}]}, {"elementID":"LC_SHIPT_83","name":"Test Shipping Name - 2 Day", "displayName":"Test DisplayName","billingType":"testBillingType","searchCategories":[{"key":"ShippingCode","value":"2DAY"}]}]';
    public static final String TEST_OPP_NAME = 'Test Opportunity';

    @testSetup static void setup() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType) //createEngOppty
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => TEST_OPP_NAME,
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                    Opportunity.Tier_Name__c => 'Engage Voice Standalone'
                }
            )
            .create()
            .getRecord();

        List<Product2> p2List = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideList(new List<String> {
                        'DigitalLine Unlimited',
                        'Mobile User',
                        'True 800 Number Setup',
                        'Polycom IP 6000 Conference Phone - Rental',
                        'Polycom VVX501 - Rental',
                        'Cisco SPA-514G Desk Phone Refurbished',
                        'Yealink T46S Gigabit Color Business Phone Refurbished',
                        'Live Reports License'
                    }),
                    Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String> {'LC_DL-UNL_50', 'LC_MU_281', 'LC_T800F_34', 'LC_HDR_619', 'LC_HDR_113', 'LC_HDRF_101', 'LC_HDRF_569', 'LC_LR_398'}),
                    Product2.Billing_Type__c => ValueProviderBuilder.provideList(new List<String> {'Recurring', 'Usage', 'OneTime', 'Recurring', 'Recurring', 'Recurring', 'Recurring', 'Usage'})
                }
            )
            .quantity(8)
            .create()
            .getRecords();

        PriceBook2 pb2 = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBook2.Name => 'Test Price Book',
                    PriceBook2.Description => 'Test Price Book Products',
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Service__c => 'Office'
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => TEST_QUOTE_NAME,
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.Pricebook2Id => pb2.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.isPrimary__c => true,
                    Quote.Package_Info__c => '[{"id":"18","version":"1","packageInfo":{"id":1389379001,"catalogId":"18","version":"1"},"productName":"Office","duration":"Monthly","edition":{"id":1,"name":"Standard"},"contract":{"id":"a8fM000000008pvIAA","extId":"Office","billingId":34118001},"offerType":"Regular","globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null}]'
                }
            )
            .create()
            .getRecord();

        Promotion__c promo = (Promotion__c) new SObjectBuilder(Promotion__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Promotion__c.Name => 'Test promo',
                Promotion__c.Quote__c => qt.Id
            })
            .create()
            .getRecord();

        List<PriceBookEntry> standardPriceEntryList = (List<PriceBookEntry>) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id> {p2List[0].Id, p2List[1].Id, p2List[2].Id, p2List[3].Id, p2List[4].Id, p2List[5].Id, p2List[6].Id, p2List[7].Id}),
                    PriceBookEntry.UnitPrice => 10000,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .quantity(8)
            .create()
            .getRecords();

        List<PriceBookEntry> priceEntryList = (List<PriceBookEntry>) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id> {p2List[0].Id, p2List[1].Id, p2List[2].Id, p2List[3].Id, p2List[4].Id, p2List[5].Id, p2List[6].Id, p2List[7].Id}),
                    PriceBookEntry.UnitPrice => 10000,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false,
                    PriceBookEntry.Pricebook2Id => pb2.Id
                }
            )
            .quantity(8)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.ServiceDate => date.today(),
                    QuoteLineItem.Description => 'TestLineItem',
                    QuoteLineItem.UnitPrice => ValueProviderBuilder.provideList(new List<Decimal> {299.88, 24.99, 30.00, 40.00, 30.00, 30.00, 30.00, 299.88}),
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.QuoteId => qt.Id,
                    QuoteLineItem.Promotion__c => ValueProviderBuilder.provideList(new List<Id> { null, null, null, null, null, null, null, promo.Id }),
                    QuoteLineItem.PriceBookEntryId => ValueProviderBuilder.provideList(new List<Id> {priceEntryList[0].Id, priceEntryList[1].Id, priceEntryList[2].Id, priceEntryList[3].Id, priceEntryList[4].Id, priceEntryList[5].Id, priceEntryList[6].Id, priceEntryList[7].Id}),
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id> {p2List[0].Id, p2List[1].Id, p2List[2].Id, p2List[3].Id, p2List[4].Id, p2List[5].Id, p2List[6].Id, p2List[7].Id}),
                    QuoteLineItem.Discount_type__c => ValueProviderBuilder.provideList(
                            new List<String> {
                                QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                                QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                                QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                                QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                                QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                                QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                                QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                                QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
                            }
                        ),
                    QuoteLineItem.Discount_number__c => ValueProviderBuilder.provideList(new List<Integer> {60, 10, 13, 10, 0, 0, 11, 30}),
                    QuoteLineItem.NewQuantity__c => 5,
                    QuoteLineItem.Display_Name__c => ValueProviderBuilder.provideList(new List<String> {
                        'DigitalLine Unlimited',
                        'Mobile User',
                        'True 800 Number Setup',
                        'Polycom IP 6000 Conference Phone - Rental',
                        'Polycom VVX501 - Rental',
                        'Cisco SPA-514G Desk Phone Refurbished',
                        'Yealink T46S Gigabit Color Business Phone Refurbished',
                        'Live Reports License'
                    }),
                    QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(
                        new List<String> {
                            '{"categoryCode":"DL-UNL","id":"18","version":"1","parent":"LC_DL_75","q":7,"price":0}',
                            '{"categoryCode":"MU","id":"18","version":"1","parent":null,"q":0,"price":0}',
                            '{"categoryCode":"T800F","id":"18","price":30,"version":"1"}',
                            '{"categoryCode":"HDR","id":"18","price":30,"version":"1"}',
                            '{"categoryCode":"HDR","id":"18","price":30,"version":"1"}',
                            '{"categoryCode":"HDRF","id":"18","price":30,"version":"1"}',
                            '{"categoryCode":"HDRF","id":"18","price":30,"version":"1"}',
                            '{"categoryCode":"LR","id":"18","price":30,"version":"1"}'
                        }
                    ),
                    QuoteLineItem.ChargeTerm__c => ValueProviderBuilder.provideList(new List<String> { 'Monthly', 'Monthly', 'One - Time', 'Monthly', 'Monthly', 'Monthly', 'Monthly', 'Monthly' })
                }
            )
            .quantity(8)
            .create()
            .getRecords();

        Triggers.switchOn();
    }

    private static List<NGBS_Discount.DiscountTemplateGroup> getNGBSDiscountTemplateGroups(Integer quantity, String firstPriority) {
        Integer firstPriorityIdx = NGBS_Discount.PRIORITY_KEY.indexOfChar(firstPriority.charAt(0));
        Quote qt = queryQuote(TEST_OPP_NAME);

        // pInfo
        BillingWrappers.QuotePackageInfo quotePackageInfo = new BillingWrappers.QuotePackageInfo();
        quotePackageInfo.packageInfo = new BillingWrappers.PackageInfo();
        quotePackageInfo.packageInfo.catalogId = '1';
        quotePackageInfo.packageInfo.version = '1';

        List<NGBS_Discount.DiscountItemWrapper> discountItemsList = new List<NGBS_Discount.DiscountItemWrapper>{
            new NGBS_Discount.DiscountItemWrapper(
                'LC_HDR_619 name',
                'LC_HDR_619',
                Product2Helper.CHARGE_TERM_MONTHLY,
                new NGBS_Discount.DiscountValue(11.0, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, true)
            ),
            new NGBS_Discount.DiscountItemWrapper(
                'LC_HDR_113 name',
                'LC_HDR_113',
                Product2Helper.CHARGE_TERM_MONTHLY,
                new NGBS_Discount.DiscountValue(11.0, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, true)
            ),
            new NGBS_Discount.DiscountItemWrapper(
                'HDRF name',
                'HDRF',
                Product2Helper.CHARGE_TERM_MONTHLY,
                new NGBS_Discount.DiscountValue(11.0, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, true)
            ),
            new NGBS_Discount.DiscountItemWrapper(
                'LC_DL-UNL_50 name',
                'LC_DL-UNL_50',
                Product2Helper.CHARGE_TERM_ANNUAL,
                new NGBS_Discount.DiscountValue(11.0, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, true)
            ),
            new NGBS_Discount.DiscountItemWrapper(
                'LC_MU_281 name',
                'LC_MU_281',
                Product2Helper.CHARGE_TERM_MONTHLY,
                new NGBS_Discount.DiscountValue(11.0, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, true)
            )
        };

        List<BillingWrappers.BillingContract> billingContracts = null;

        List<NGBS_Discount.DiscountTemplateGroup> tempGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
        for (Integer i = 0; i < quantity; i++) {
            String priority = NGBS_Discount.PRIORITY_KEY.substring(firstPriorityIdx + i, firstPriorityIdx + i + 1);
            tempGroups.add(
                new NGBS_Discount.DiscountTemplateGroup(
                    qt.QuoteNumber,
                    quotePackageInfo,
                    discountItemsList,
                    priority,
                    billingContracts,
                    new Map<String, String>()
                )
            );
        }

        for (NGBS_Discount.DiscountTemplateGroup dtg : tempGroups) {
            for (NGBS_Discount.DiscountTemplate dt : dtg.discountTemplates) {
                if (dt.applicableTo.id == 'HDRF') {
                    dt.applicableTo.type = NGBS_Discount.BILLING_CATEGORY_ID_TYPE;
                }
            }
        }

        return tempGroups;
    }

    private static NGBS_Discount.DiscountTemplate getDiscountTemplateById(String extId, List<NGBS_Discount.DiscountTemplate> discounts) {
        NGBS_Discount.DiscountTemplate result;
        for (NGBS_Discount.DiscountTemplate disc : discounts) {
            if (disc.applicableTo.id == extId) {
                result = disc;
                break;
            }
        }
        return result;
    }

    private static NGBS_Discount.OldDiscountTemplate getOldDiscountTemplateById(String extId, List<NGBS_Discount.OldDiscountTemplate> discounts) {
        NGBS_Discount.OldDiscountTemplate result;
        for (NGBS_Discount.OldDiscountTemplate disc : discounts) {
            if (disc.applicableTo.id == extId) {
                result = disc;
                break;
            }
        }
        return result;
    }

    private static Quote queryQuote(String oppName) {
        return (Quote) new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(oppName)
            .executeQuery()
            .get(0);
    }

    private static String getMessageForComment(String expected) {
        return 'Method should return \'' + expected + '\' value';
    }

    @isTest
    static void test_getDiscountTemplateGroupWithCurrent() {
        Test.startTest();
            Quote qt = queryQuote(TEST_OPP_NAME);

            List<BillingWrappers.QuotePackageInfo> pInfos =
                (List<BillingWrappers.QuotePackageInfo>)
                    JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);

            BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

            Contract__c accountContract;
            List<NGBS_Discount.DiscountTemplateGroup> currentGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
            currentGroups = getNGBSDiscountTemplateGroups(1, 'A');

            NGBS_Discount.DiscountTemplateGroup discountTemplateGroup = NGBS_Discount.getMostPriorityDiscountTemplateGroup(qt, pInfo, accountContract, null, null, currentGroups, false);
        Test.stopTest();

        /* discount template group */
        System.assertEquals(true, discountTemplateGroup != null, 'DiscountTemplateGroup should be exist');
        System.assertEquals('A', discountTemplateGroup.priority, 'Priority should be equals A');
        System.assertEquals(qt.QuoteNumber, discountTemplateGroup.description, 'wrong description');

        System.assertEquals('18', discountTemplateGroup.target.catalogId, 'Wrong target package catalog id');
        System.assertEquals('1', discountTemplateGroup.target.version, 'Wrong target package version');

        /* dlUnlimited */
        NGBS_Discount.DiscountTemplate dlUnlimited = getDiscountTemplateById('LC_DL-UNL_50', discountTemplateGroup.discountTemplates);
        System.assertNotEquals(null, dlUnlimited, 'no discount for DL found');
        System.assertEquals('DigitalLine Unlimited', dlUnlimited.description, 'wrong description');

        System.assertEquals('CatalogId', dlUnlimited.applicableTo.type, 'wrong applicableTo type');

        System.assertEquals(null, dlUnlimited.applicationTerms.endDate, 'wrong endDate');
        System.assertEquals('All', dlUnlimited.applicationTerms.licenseScope, 'wrong licenseScope');

        NGBS_Discount.DiscountValue dlUnlimitedDV = dlUnlimited.values.get(Product2Helper.CHARGE_TERM_MONTHLY);
        System.assertEquals(true, dlUnlimitedDV != null, 'discount should be exist');
        System.assertEquals('Money', dlUnlimitedDV.unit, 'wrong discount type');
        System.assertEquals(60, dlUnlimitedDV.value, 'wrong discount value');
        System.assertEquals(null, dlUnlimitedDV.recurringTerms, 'wrong discount recurringTerms');

        /* mobileUser */
        NGBS_Discount.DiscountTemplate mobileUser = getDiscountTemplateById('LC_MU_281', discountTemplateGroup.discountTemplates);
        System.assertNotEquals(null, mobileUser, 'no discount for MU found');
        System.assertEquals('Mobile User', mobileUser.description, 'wrong description');

        System.assertEquals('CatalogId', mobileUser.applicableTo.type, 'wrong applicableTo type');

        System.assertEquals(null, mobileUser.applicationTerms.endDate, 'wrong endDate');
        System.assertEquals('All', mobileUser.applicationTerms.licenseScope, 'wrong licenseScope');

        NGBS_Discount.DiscountValue mobileUserDV = mobileUser.values.get(Product2Helper.CHARGE_TERM_MONTHLY);
        System.assertEquals(true, mobileUserDV != null, 'discount should be exist');
        System.assertEquals('Money', mobileUserDV.unit, 'wrong discount type');
        System.assertEquals(60, mobileUserDV.value, 'wrong discount value');
        System.assertEquals(null, mobileUserDV.recurringTerms, 'wrong discount recurringTerms');

        /* true800 */
        NGBS_Discount.DiscountTemplate true800 = getDiscountTemplateById('LC_T800F_34', discountTemplateGroup.discountTemplates);
        System.assertNotEquals(null, true800, 'no discount for T800F found');
        System.assertEquals('True 800 Number Setup', true800.description, 'wrong description');
        System.assertEquals('CatalogId', true800.applicableTo.type, 'wrong applicableTo type');
        System.assertEquals(null, true800.applicationTerms.endDate, 'wrong endDate');
        System.assertEquals('All', true800.applicationTerms.licenseScope, 'wrong licenseScope');
        NGBS_Discount.DiscountValue true800DV = true800.values.get('OneTime');
        System.assertEquals(true, true800DV != null, 'discount should be exist');
        System.assertEquals('Percent', true800DV.unit, 'wrong discount type');
        System.assertEquals(13, true800DV.value, 'wrong discount value');
        System.assertEquals(null, true800DV.recurringTerms, 'wrong discount recurringTerms');

        /* LC_HDR_619 - with updated discount*/
        NGBS_Discount.DiscountTemplate hd_619 = getDiscountTemplateById('LC_HDR_619', discountTemplateGroup.discountTemplates);
        System.assertNotEquals(null, hd_619, 'TemplateGroup must contains current discounts');
        NGBS_Discount.DiscountValue hd_619_DV = hd_619.values.get(Product2Helper.CHARGE_TERM_MONTHLY);
        System.assertEquals(true, hd_619_DV != null, 'discount should be exist');
        System.assertEquals('Percent', hd_619_DV.unit, 'wrong discount type');
        System.assertEquals(10, hd_619_DV.value, 'wrong discount value');

        /* LC_LR_398 - QLI with Promotion */
        NGBS_Discount.DiscountTemplate lr_398 = getDiscountTemplateById('LC_LR_398', discountTemplateGroup.discountTemplates);
        System.assertEquals(null, lr_398, 'QLI with Promotion must be skipped');

        /* LC_HDR_113 - QLI with current discount for catalog where discount removed */
        NGBS_Discount.DiscountTemplate hd_113 = getDiscountTemplateById('LC_HDR_113', discountTemplateGroup.discountTemplates);
        System.assertEquals(null, hd_113, 'current discount for catalog should be removed');

        /* LC_HDRF_101 - QLI with current discount for category where discount removed */
        NGBS_Discount.DiscountTemplate hdrf_101 = getDiscountTemplateById('LC_HDRF_101', discountTemplateGroup.discountTemplates);
        System.assertEquals(null, hdrf_101, 'should not be DT for removed discount');

        /* LC_HDRF_569 - QLI with current discount for category where discounts is equal */
        NGBS_Discount.DiscountTemplate hdrf_569 = getDiscountTemplateById('LC_HDRF_569', discountTemplateGroup.discountTemplates);
        System.assertNotEquals(null, hdrf_569, 'no discount for LC_HDRF_569 found');
    }

    @isTest
    static void test_getNewDiscountTemplateGroup() {
        Test.startTest();
            Quote qt = queryQuote(TEST_OPP_NAME);

            List<BillingWrappers.QuotePackageInfo> pInfos =
                (List<BillingWrappers.QuotePackageInfo>)
                    JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);

            BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

            Contract__c accountContract;
            List<NGBS_Discount.DiscountTemplateGroup> currentGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
            currentGroups = getNGBSDiscountTemplateGroups(1, 'A');

            NGBS_Discount.DiscountTemplateGroup newDiscountTemplateGroup = NGBS_Discount.getMostPriorityDiscountTemplateGroup(qt, pInfo, accountContract, null, null, currentGroups, true);
        Test.stopTest();

        /* discount for QLI from HDRF category was removed */
        NGBS_Discount.DiscountTemplate hdrf = getDiscountTemplateById('HDRF', currentGroups[0].discountTemplates);
        System.assertEquals(null, hdrf, 'current discount for HDRF category should be removed');

        /* LC_HDR_113 - QLI with current discount for catalog where discount removed */
        NGBS_Discount.DiscountTemplate hd_113 = getDiscountTemplateById('LC_HDR_113', currentGroups[0].discountTemplates);
        System.assertEquals(null, hd_113, 'current discount for catalog should be removed');
    }

    @isTest
    static void verifyThatQliCorrect() {
        Quote qt = queryQuote(TEST_OPP_NAME);
        qt.QuoteLineItems.get(0).ChargeTerm__c = null;

        List<BillingWrappers.QuotePackageInfo> pInfos =
            (List<BillingWrappers.QuotePackageInfo>)
                JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);

        BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

        Test.startTest();
            Boolean isExpectedExceptionThrown = false;
            try {
                List<NGBS_Discount.DiscountTemplateGroup> currentGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
                currentGroups = getNGBSDiscountTemplateGroups(1, 'A');
                NGBS_Discount.DiscountTemplateGroup discountTemplateGroup = NGBS_Discount.getMostPriorityDiscountTemplateGroup(qt, pInfo, null, null, null, currentGroups, false);
            } catch (AquivaHelper.AquivaException ex) {
                isExpectedExceptionThrown = true;
            }
        Test.stopTest();

        System.assert(
            isExpectedExceptionThrown,
            'Expected Exception should be thrown for the incorrect qli'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_createDiscountAboveCurrent() {

    }

    @isTest
    static void testCreateRootDiscountTemplateGroupWithoutValueTerms() {
        Test.startTest();
            Opportunity opp = (Opportunity) new OpportunitySelector()
                .selectOpportunities()
                .executeQuery()
                .get(0);

            Quote qt = (Quote) new QuoteSelector().selectQuoteForSignUp(opp.Id).executeQuery().get(0);

            List<BillingWrappers.QuotePackageInfo> pInfos =
                (List<BillingWrappers.QuotePackageInfo>)
                    JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);

            BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

            Contract__c accountContract;
            NGBS_Discount.RootDiscountTemplateGroup discountTemplateGroup
                = NGBS_Discount.createRootDiscountTemplateGroup(qt, pInfo, accountContract, 'A');
        Test.stopTest();

        System.assertEquals(discountTemplateGroup.name, TEST_QUOTE_NAME);

        /* mobileUser */
        NGBS_Discount.OldDiscountTemplate mobileUser = getOldDiscountTemplateById('LC_MU_281', discountTemplateGroup.discountTemplates);
        System.assertNotEquals(null, mobileUser, 'no discount for LC_MU_281 found');
        System.assertEquals('Mobile User', mobileUser.description, 'wrong description');
        System.assertEquals('CatalogId', mobileUser.applicableTo.type, 'wrong applicableTo type');
        System.assertEquals(null, mobileUser.applicationTerms.endDate, 'wrong endDate');
        System.assertEquals('All', mobileUser.applicationTerms.licenseScope, 'wrong licenseScope');

        NGBS_Discount.DiscountValue mobileUserDV = mobileUser.values.get('Monthly');
        System.assertEquals(true, mobileUserDV != null, 'discount should be exist');
        System.assertEquals('Money', mobileUserDV.unit, 'wrong discount type');
        System.assertEquals(60, mobileUserDV.value, 'wrong discount value');
        System.assertEquals(null, mobileUserDV.recurringTerms, 'wrong discount recurringTerms');
    }

    @isTest
    static void testCreateDiscountApplicationTermsWithCurrentContract() {

        Date testQuoteStartDate = Date.valueOf('2019-10-21');

        BillingWrappers.BillingContract pastBillingContract = new BillingWrappers.BillingContract();
        pastBillingContract.id = '0';
        pastBillingContract.startBillingCycleNumber = 0;
        pastBillingContract.term = 2;
        pastBillingContract.startDate = Date.valueOf('2019-08-20');

        BillingWrappers.BillingContract currentBillingContract = new BillingWrappers.BillingContract();
        currentBillingContract.id = '1';
        currentBillingContract.startBillingCycleNumber = 0;
        currentBillingContract.term = 2;
        currentBillingContract.startDate = Date.valueOf('2019-10-20');

        BillingWrappers.BillingContract futureBillingContract = new BillingWrappers.BillingContract();
        futureBillingContract.id = '2';
        futureBillingContract.startBillingCycleNumber = 0;
        futureBillingContract.term = 2;
        futureBillingContract.startDate = Date.valueOf('2019-12-20');

        List<BillingWrappers.BillingContract> testBillingContracts = new List<BillingWrappers.BillingContract>();
        testBillingContracts.add(pastBillingContract);
        testBillingContracts.add(currentBillingContract);
        testBillingContracts.add(futureBillingContract);

        NGBS_Discount.DiscountApplicationTerms testDiscountApplicationTerms = new NGBS_Discount.DiscountApplicationTerms(
            testQuoteStartDate,
            testBillingContracts
        );

        System.assertEquals(
            String.valueOf(testQuoteStartDate),
            testDiscountApplicationTerms.startDate.substring(0, 10),
            'start date should be populated with startDate of Quote if Quote.StartDate__c fits in billing contract dates'
        );
    }

    @isTest
    static void testCreateDiscountApplicationTermsWithFutureContract() {

        Date testQuoteStartDate = Date.valueOf('2019-10-21');

        BillingWrappers.BillingContract pastBillingContract = new BillingWrappers.BillingContract();
        pastBillingContract.id = '0';
        pastBillingContract.startBillingCycleNumber = 0;
        pastBillingContract.term = 2;
        pastBillingContract.startDate = Date.valueOf('2019-08-20');

        BillingWrappers.BillingContract futureBillingContract = new BillingWrappers.BillingContract();
        futureBillingContract.id = '2';
        futureBillingContract.startBillingCycleNumber = 0;
        futureBillingContract.term = 2;
        futureBillingContract.startDate = Date.valueOf('2019-12-20');

        List<BillingWrappers.BillingContract> testBillingContracts = new List<BillingWrappers.BillingContract>();
        testBillingContracts.add(pastBillingContract);
        testBillingContracts.add(futureBillingContract);

        NGBS_Discount.DiscountApplicationTerms testDiscountApplicationTerms = new NGBS_Discount.DiscountApplicationTerms(
            testQuoteStartDate,
            testBillingContracts
        );

        System.assertEquals(
            String.valueOf(futureBillingContract.startDate),
            testDiscountApplicationTerms.startDate.substring(0, 10),
            'start date should be populated with startDate of Next(closer active) billing contract'
        );
    }

    @isTest
    static void testCreateDiscountApplicationTermsWithoutFutureContract() {

        Date testQuoteStartDate = Date.valueOf('2019-10-21');

        BillingWrappers.BillingContract pastBillingContract = new BillingWrappers.BillingContract();
        pastBillingContract.id = '0';
        pastBillingContract.startBillingCycleNumber = 0;
        pastBillingContract.term = 2;
        pastBillingContract.startDate = Date.valueOf('2019-08-20');

        List<BillingWrappers.BillingContract> testBillingContracts = new List<BillingWrappers.BillingContract>();
        testBillingContracts.add(pastBillingContract);

        NGBS_Discount.DiscountApplicationTerms testDiscountApplicationTerms = new NGBS_Discount.DiscountApplicationTerms(
            testQuoteStartDate,
            testBillingContracts
        );

        System.assertEquals(
            System.now().addDays(BillingWrappers.DISCOUNT_START_DATE_OFFSET).formatGmt(NGBS_Discount.NGBS_UTC_FORMAT).substring(0, 10),
            testDiscountApplicationTerms.startDate.substring(0, 10),
            'start date should be populated with startDate of Quote if future active billing contract does not exist'
        );
    }

    @isTest
    static void testCreateDiscountApplicationTermsWithoutAnyContracts() {

        Date testQuoteStartDate = Date.valueOf('2019-10-21');

        NGBS_Discount.DiscountApplicationTerms testDiscountApplicationTerms = new NGBS_Discount.DiscountApplicationTerms(
            testQuoteStartDate,
            null
        );

        System.assertEquals(
            System.now().addDays(BillingWrappers.DISCOUNT_START_DATE_OFFSET).formatGmt(NGBS_Discount.NGBS_UTC_FORMAT).substring(0, 10),
            testDiscountApplicationTerms.startDate.substring(0, 10),
            'start date should be populated with startDate of Quote if billing contracts does not exist'
        );
    }

    @isTest
    static void verifyThatGetExternalIdToBillingTypeMapReturnCorrectMap() {
        Test.startTest();
            Quote qt = queryQuote(TEST_OPP_NAME);

            Map<String, String> resultMap = NGBS_Discount.getExternalIdToBillingTypeMap(qt);
        Test.stopTest();

        System.assertEquals(
            8,
            resultMap.size(),
            'Wrong Result Map size'
        );
        System.assertEquals(
            'Recurring',
            resultMap.get('LC_DL-UNL_50'),
            'Value for key LC_DL-UNL_50 should be Recurring'
        );
        System.assertEquals(
            'Usage',
            resultMap.get('LC_MU_281'),
            'Value for key LC_MU_281 should be Usage'
        );
        System.assertEquals(
            'OneTime',
            resultMap.get('LC_T800F_34'),
            'Value for key LC_T800F_34 should be OneTime'
        );
    }

    @isTest
    static void verifyThatIsItemRemovedByUpgradeReturnCorrectValue() {
        Quote qt = queryQuote(TEST_OPP_NAME);
        qt.QuoteLineItems[0].NewQuantity__c = 0;
        qt.QuoteLineItems[0].Quantity = -1;
        Test.startTest();
            Boolean isItemRemovedByUpgrade = NGBS_Discount.isItemRemovedByUpgrade(qt.QuoteLineItems[0], QuoteHelper.STATUS_UPGRADE);
        Test.stopTest();

        System.assertEquals(true, isItemRemovedByUpgrade, 'isItemRemovedByUpgrade should return correct value');
    }

    @isTest
    static void testCreationRootDiscountTemplatesWithFreeShippingDiscounts() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Triggers.switchOff();
        NGBS_Settings__c settings = (NGBS_Settings__c) new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://test.com',
                NGBS_Settings__c.AccountManagerPath__c => 'http://test.com/test_manager',
                NGBS_Settings__c.CatalogPath__c => 'http://test.com/test_catalog',
                NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery()
            .get(0);

        Quote qt = (Quote) new QuoteSelector().selectQuoteForSignUp(opp.Id).executeQuery().get(0);
        qt.FreeShippingTerms__c = QuoteHelper.FREESHIPPING;
        qt.Shipping_Option__c = QuoteHelper.SHIPPING_OPTION_OVERNIGHT;

        update qt;
        Triggers.switchOn();
        Test.startTest();
        List<BillingWrappers.QuotePackageInfo> pInfos =
                (List<BillingWrappers.QuotePackageInfo>)
                        JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);

        BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

        Contract__c accountContract;
        NGBS_Discount.RootDiscountTemplateGroup discountTemplateGroup
                = NGBS_Discount.createRootDiscountTemplateGroup(qt, pInfo, accountContract, 'A');

        Test.stopTest();

        System.assertEquals(true, discountTemplateGroup != null, 'DiscountTemplateGroup should be exist');
        System.assertEquals('A', discountTemplateGroup.priority, 'Priority should be equals A');
        System.assertEquals(TEST_QUOTE_NAME, discountTemplateGroup.description, 'wrong description');

        System.assertEquals(6, discountTemplateGroup.discountTemplates.size(), 'wrong discountTemplates size');

        NGBS_Discount.OldDiscountTemplate shipt_82 = getOldDiscountTemplateById('LC_SHIPT_82', discountTemplateGroup.discountTemplates);
        System.assertNotEquals(null, shipt_82, 'no discount for LC_SHIPT_82 found');
        System.assertEquals('Test DisplayName', shipt_82.description, 'wrong description');
        System.assertEquals('CatalogId', shipt_82.applicableTo.type, 'wrong applicableTo type');
        System.assertNotEquals(null, shipt_82.applicationTerms.endDate, 'wrong endDate');
        System.assertNotEquals(null, shipt_82.applicationTerms.startDate, 'wrong startDate');
        System.assertEquals('All', shipt_82.applicationTerms.licenseScope, 'wrong licenseScope');
        System.assertEquals(true, shipt_82.values.get('OneTime') != null, 'discount should be exist');
        System.assertEquals('Percent', shipt_82.values.get('OneTime').unit, 'wrong discount type');
        System.assertEquals(100, shipt_82.values.get('OneTime').value, 'wrong discount value');
        System.assertEquals(null, shipt_82.values.get('OneTime').recurringTerms, 'wrong discount recurringTerms');
    }

    @isTest
    static void testCreationDiscountTemplatesWithFreeShippingDiscountsNonLBO() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Triggers.switchOff();
        NGBS_Settings__c settings = (NGBS_Settings__c) new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://test.com',
                NGBS_Settings__c.AccountManagerPath__c => 'http://test.com/test_manager',
                NGBS_Settings__c.CatalogPath__c => 'http://test.com/test_catalog',
                NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Quote qt = queryQuote(TEST_OPP_NAME);
        qt.FreeShippingTerms__c = QuoteHelper.FREESHIPPING;
        qt.Shipping_Option__c = QuoteHelper.SHIPPING_OPTION_OVERNIGHT;

        update qt;
        Triggers.switchOn();
        Test.startTest();
        List<BillingWrappers.QuotePackageInfo> pInfos =
                (List<BillingWrappers.QuotePackageInfo>)
                        JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);

        BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

        Contract__c accountContract;
        List<NGBS_Discount.DiscountTemplateGroup> currentGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
        currentGroups = getNGBSDiscountTemplateGroups(1, 'A');

        NGBS_Discount.DiscountTemplateGroup discountTemplateGroup = NGBS_Discount.getMostPriorityDiscountTemplateGroup(qt, pInfo, accountContract, null, null, currentGroups, false);

        Test.stopTest();

        System.assertEquals(true, discountTemplateGroup != null, 'DiscountTemplateGroup should be exist');
        System.assertEquals('A', discountTemplateGroup.priority, 'Priority should be equals A');
        System.assertEquals(qt.QuoteNumber, discountTemplateGroup.description, 'wrong description');

        NGBS_Discount.DiscountTemplate shipt_82 = getDiscountTemplateById('LC_SHIPT_82', discountTemplateGroup.discountTemplates);
        System.assertNotEquals(null, shipt_82, 'no discount for LC_SHIPT_82 found');
        System.assertEquals('Test DisplayName', shipt_82.description, 'wrong description');
        System.assertEquals('CatalogId', shipt_82.applicableTo.type, 'wrong applicableTo type');
        System.assertNotEquals(null, shipt_82.applicationTerms.endDate, 'wrong endDate');
        System.assertNotEquals(null, shipt_82.applicationTerms.startDate, 'wrong startDate');
        System.assertEquals('All', shipt_82.applicationTerms.licenseScope, 'wrong licenseScope');
        System.assertEquals(true, shipt_82.values.get('OneTime') != null, 'discount should be exist');
        System.assertEquals('Percent', shipt_82.values.get('OneTime').unit, 'wrong discount type');
        System.assertEquals(100, shipt_82.values.get('OneTime').value, 'wrong discount value');
        System.assertEquals(null, shipt_82.values.get('OneTime').recurringTerms, 'wrong discount recurringTerms');
    }

    @isTest
    static void testCreationDiscountTemplatesWithFreeShippingDiscountsLBO() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Triggers.switchOff();
        NGBS_Settings__c settings = (NGBS_Settings__c) new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://test.com',
                NGBS_Settings__c.AccountManagerPath__c => 'http://test.com/test_manager',
                NGBS_Settings__c.CatalogPath__c => 'http://test.com/test_catalog',
                NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Quote qt = queryQuote(TEST_OPP_NAME);
        qt.Enabled_LBO__c = true;
        qt.Upsell_Status__c = QuoteHelper.STATUS_UPSELL;
        qt.FreeShippingTerms__c = QuoteHelper.FREESHIPPING;

        update qt;

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '2078 Adamsville Road',
                CustomAddress__c.City__c => 'Laredo',
                CustomAddress__c.PostalCode__c => '78040',
                CustomAddress__c.State__c => 'Texas',
                CustomAddress__c.Country__c => 'United States'
            })
            .create()
            .getRecord();
        String qliId;
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            if (qli.Product_Lic_Id__c == 'LC_HDR_619') {
                qliId = qli.Id;
                break;
            }
        }

        List<CustomAddressAssignments__c> addresses = (List<CustomAddressAssignments__c>) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.CustomAddress__c => ca.Id,
                CustomAddressAssignments__c.AttentionTo__c => 'test',
                CustomAddressAssignments__c.Quantity__c => 1,
                CustomAddressAssignments__c.QuoteLineItem__c => qliId,
                CustomAddressAssignments__c.Type__c => ValueProviderBuilder.provideList(new List<String> {QuoteHelper.SHIPPING_OPTION_GROUND, QuoteHelper.SHIPPING_OPTION_OVERNIGHT, QuoteHelper.SHIPPING_OPTION_2_DAY}),
                CustomAddressAssignments__c.ShippingLicenseTree__c => ValueProviderBuilder.provideList(new List<String> {'LC_SHP_86:LC_SHIP_82:LC_SHIPT_81', 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_82', 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_83'})
            })
            .quantity(3)
            .create()
            .getRecords();
        Triggers.switchOn();
        Test.startTest();
        List<BillingWrappers.QuotePackageInfo> pInfos =
                (List<BillingWrappers.QuotePackageInfo>)
                        JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);

        BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

        Contract__c accountContract;
        List<NGBS_Discount.DiscountTemplateGroup> currentGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
        currentGroups = getNGBSDiscountTemplateGroups(1, 'A');

        NGBS_Discount.DiscountTemplateGroup discountTemplateGroup = NGBS_Discount.getMostPriorityDiscountTemplateGroup(qt, pInfo, accountContract, null, null, currentGroups, false);

        Test.stopTest();

        System.assertEquals(true, discountTemplateGroup != null, 'DiscountTemplateGroup should be exist');
        System.assertEquals('A', discountTemplateGroup.priority, 'Priority should be equals A');
        System.assertEquals(qt.QuoteNumber, discountTemplateGroup.description, 'wrong description');

        System.assertEquals(8, discountTemplateGroup.discountTemplates.size(), 'wrong discountTemplates size');

        NGBS_Discount.DiscountTemplate shipt_81 = getDiscountTemplateById('LC_SHIPT_81', discountTemplateGroup.discountTemplates);
        System.assertNotEquals(null, shipt_81, 'no discount for LC_SHIPT_81 found');
        System.assertEquals('Test DisplayName', shipt_81.description, 'wrong description');
        System.assertEquals('CatalogId', shipt_81.applicableTo.type, 'wrong applicableTo type');
        System.assertNotEquals(null, shipt_81.applicationTerms.endDate, 'wrong endDate');
        System.assertNotEquals(null, shipt_81.applicationTerms.startDate, 'wrong startDate');
        System.assertEquals('All', shipt_81.applicationTerms.licenseScope, 'wrong licenseScope');
        System.assertEquals(true, shipt_81.values.get('OneTime') != null, 'discount should be exist');
        System.assertEquals('Percent', shipt_81.values.get('OneTime').unit, 'wrong discount type');
        System.assertEquals(100, shipt_81.values.get('OneTime').value, 'wrong discount value');
        System.assertEquals(null, shipt_81.values.get('OneTime').recurringTerms, 'wrong discount recurringTerms');

        NGBS_Discount.DiscountTemplate shipt_82 = getDiscountTemplateById('LC_SHIPT_82', discountTemplateGroup.discountTemplates);
        System.assertNotEquals(null, shipt_82, 'no discount for LC_SHIPT_82 found');
        System.assertEquals('Test DisplayName', shipt_82.description, 'wrong description');
        System.assertEquals('CatalogId', shipt_82.applicableTo.type, 'wrong applicableTo type');
        System.assertNotEquals(null, shipt_82.applicationTerms.endDate, 'wrong endDate');
        System.assertNotEquals(null, shipt_82.applicationTerms.startDate, 'wrong startDate');
        System.assertEquals('All', shipt_82.applicationTerms.licenseScope, 'wrong licenseScope');
        System.assertEquals(true, shipt_82.values.get('OneTime') != null, 'discount should be exist');
        System.assertEquals('Percent', shipt_82.values.get('OneTime').unit, 'wrong discount type');
        System.assertEquals(100, shipt_82.values.get('OneTime').value, 'wrong discount value');
        System.assertEquals(null, shipt_82.values.get('OneTime').recurringTerms, 'wrong discount recurringTerms');

        NGBS_Discount.DiscountTemplate shipt_83 = getDiscountTemplateById('LC_SHIPT_83', discountTemplateGroup.discountTemplates);
        System.assertNotEquals(null, shipt_83, 'no discount for LC_SHIPT_83 found');
        System.assertEquals('Test DisplayName', shipt_83.description, 'wrong description');
        System.assertEquals('CatalogId', shipt_83.applicableTo.type, 'wrong applicableTo type');
        System.assertNotEquals(null, shipt_83.applicationTerms.endDate, 'wrong endDate');
        System.assertNotEquals(null, shipt_83.applicationTerms.startDate, 'wrong startDate');
        System.assertEquals('All', shipt_83.applicationTerms.licenseScope, 'wrong licenseScope');
        System.assertEquals(true, shipt_83.values.get('OneTime') != null, 'discount should be exist');
        System.assertEquals('Percent', shipt_83.values.get('OneTime').unit, 'wrong discount type');
        System.assertEquals(100, shipt_83.values.get('OneTime').value, 'wrong discount value');
        System.assertEquals(null, shipt_83.values.get('OneTime').recurringTerms, 'wrong discount recurringTerms');
    }

    private class Mock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(SHIPPING_LICENSE_RESPONSE);

            return res;
        }
    }

    @isTest
    private static void test_getNextPrioritiesWithEmptyDtgList() {
        List<NGBS_Discount.DiscountTemplateGroup> groups = new List<NGBS_Discount.DiscountTemplateGroup>();

        Test.startTest();
        List<String> result = NGBS_Discount.getNextPriorities(groups, 2);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Method should return 2 priorities');
        System.assertEquals(result[0], 'A', 'Method returned incorrect priority');
    }

    @isTest
    private static void test_getNextPrioritiesWithTooLargeDtgList() {
        List<NGBS_Discount.DiscountTemplateGroup> groups = getNGBSDiscountTemplateGroups(20, 'A');

        Test.startTest();
        Boolean isExpectedExceptionThrown = false;
        try {
            List<String> result = NGBS_Discount.getNextPriorities(groups, groups.size());
        } catch (AquivaHelper.AquivaException ex) {
            isExpectedExceptionThrown = ex.getMessage().contains('Discount Template Groups');
        }
        Test.stopTest();

        System.assert(
            isExpectedExceptionThrown,
            'Expected Exception should be thrown'
        );
    }

    @isTest
    private static void test_getNextPrioritiesWithHigherPriorities() {
        Integer dtgsQuantity = 10;
        List<NGBS_Discount.DiscountTemplateGroup> groups = getNGBSDiscountTemplateGroups(dtgsQuantity, 'A');

        Test.startTest();
        List<String> result = NGBS_Discount.getNextPriorities(groups, groups.size());
        Test.stopTest();

        for (Integer i = 0; i < result.size(); i++) {
            System.assertEquals(
                NGBS_Discount.PRIORITY_KEY.substring(i + dtgsQuantity, i + dtgsQuantity + 1),
                result[i],
                'Method returned incorrect discount value for ' + i + ' DTG'
            );
        }
    }

    @isTest
    private static void test_getNextPrioritiesWithMinVacantPriorities() {
        Integer dtgsQuantity = 10;
        List<NGBS_Discount.DiscountTemplateGroup> groups = getNGBSDiscountTemplateGroups(dtgsQuantity, 'M');

        Test.startTest();
        List<String> result = NGBS_Discount.getNextPriorities(groups, groups.size());
        Test.stopTest();

        for (Integer i = 0; i < result.size(); i++) {
            System.assertEquals(
                NGBS_Discount.PRIORITY_KEY.substring(i, i + 1),
                result[i],
                'Method returned incorrect discount value for ' + i + ' DTG'
            );
        }
    }

    @isTest
    static void test_getUpdatedDtgList() {
        Test.startTest();
            Quote qt = queryQuote(TEST_OPP_NAME);

            List<BillingWrappers.QuotePackageInfo> pInfos =
                (List<BillingWrappers.QuotePackageInfo>)
                    JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);

            BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

            Contract__c accountContract;
            List<NGBS_Discount.DiscountTemplateGroup> currentGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
            currentGroups = getNGBSDiscountTemplateGroups(1, 'A');

            List<NGBS_Discount.DiscountTemplateGroup> dGroups = NGBS_Discount.getUpdatedDtgList(qt, pInfo, accountContract, null, currentGroups, currentGroups);

        Test.stopTest();

        System.assertEquals(2, dGroups.size(), 'should be created additional DTG due to current has category discount');
    }

    @isTest
    static void testRemoveCatalogEntry() {

        NGBS_Discount.DiscountItemWrapper dlDiscount = new NGBS_Discount.DiscountItemWrapper(
            'LC_DL-UNL_50 name',
            'LC_DL-UNL_50',
            Product2Helper.CHARGE_TERM_ANNUAL,
            new NGBS_Discount.DiscountValue(11.0, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, true)
        );
        NGBS_Discount.DiscountItemWrapper muDiscount = new NGBS_Discount.DiscountItemWrapper(
            'LC_MU_281 name',
            'LC_MU_281',
            Product2Helper.CHARGE_TERM_MONTHLY,
            new NGBS_Discount.DiscountValue(11.0, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, true)
        );

        Map<String, NGBS_Discount.DiscountItemWrapper> catalogToDiscountValueMap = new Map<String, NGBS_Discount.DiscountItemWrapper>();
        Map<String, String> removingDiscountsCatalogToCategoryMap = new Map<String, String>();
        catalogToDiscountValueMap.put(NGBS_Discount.DIGITAL_LINE_UNLIMITED, dlDiscount);
        catalogToDiscountValueMap.put(Product2Helper.MOBILE_USER_ELEMENT_ID, muDiscount);

        NGBS_Discount.removeCatalogEntry(catalogToDiscountValueMap, removingDiscountsCatalogToCategoryMap, NGBS_Discount.DIGITAL_LINE_UNLIMITED, NGBS_Discount.DIGITAL_LINE_UNLIMITED_CATEGORY);

        System.assertEquals(null, catalogToDiscountValueMap.get(NGBS_Discount.DIGITAL_LINE_UNLIMITED), 'DL catalog should be removed from the map');
        System.assertEquals(NGBS_Discount.DIGITAL_LINE_UNLIMITED_CATEGORY, removingDiscountsCatalogToCategoryMap.get(NGBS_Discount.DIGITAL_LINE_UNLIMITED), 'DL category should be added to the removing map');
        System.assertEquals(null, catalogToDiscountValueMap.get(Product2Helper.MOBILE_USER_ELEMENT_ID), 'MU catalog should be removed from the map');
        System.assertEquals(NGBS_Discount.MOBILE_USER_CATEGORY, removingDiscountsCatalogToCategoryMap.get(Product2Helper.MOBILE_USER_ELEMENT_ID), 'MU category should be added to the removing map');
    }

}