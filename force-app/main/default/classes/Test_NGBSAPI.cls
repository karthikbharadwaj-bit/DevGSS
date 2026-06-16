@isTest
private class Test_NGBSAPI {
    private static final String COMBINED_CATALOG_ID_0 = '0';
    private static final String COMBINED_CATALOG_ID_1 = '1';
    private static final String COMBINED_CATALOG_ID_2 = '2';
    private static final String COMBINED_CATALOG_ID_3 = '3';
    private static final String COMBINED_CATALOG_ID_4 = '4';
    private static final String COMBINED_CATALOG_ID_5 = '5';
    private static final String COMBINED_CATALOG_ID_6 = '6';
    private static final String CATEGORY_ID_0 = '0';
    private static final String CATEGORY_ID_1 = '1';
    private static final String CATEGORY_ID_2 = '2';
    private static final String CATEGORY_ID_3 = '3';

    private static final String ITEM_TYPE_CANCELLATION_CREDIT = NGBSAPI.ITEM_TYPE_CANCELLATION_CREDIT;
    private static final String ITEM_TYPE_SOMETHING = 'something';

    private static final String UNEXPECTED_NGBSAPI_RECALCULATE_RESULT =
        'Unexpected NGBSAPI.recalculateMaxRefunds(...) result';

    private static String PACKAGE_INFO = '[{"id":"18","version":"1","packageInfo":{'
        + '"id":116477002,"catalogId":"18","version":"1","name":"Office Standard 1/2/100/1000+ Lines - 5100/5101/5102/5103",'
        + '"displayName":"RingCentral Office Standard","oldPackageName":"RingCentral Office Standard"},'
        + '"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},'
        + '"contract":null,"offerType":"Regular","poc":null,"globalPackageLimits":[{'
        + '"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount",'
        + '"scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{'
        + '"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,'
        + '"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{'
        + '"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,'
        + '"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},'
        + '"defaultBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{'
        + '"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,'
        + '"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{'
        + '"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{'
        + '"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,'
        + '"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}},'
        + '"existingPackageInfo":{"id":"18","version":"1","offerType":"Regular","productName":"Office"}}]';

    private static final String WHOLESALE_PAYMENT_METHOD_RESPONSE = '[{"id":52269001,"accountId":59640001,"nickname":"InvoiceWholesale","addedAt":"2021-12-19T17:25:27.108355Z[UTC]","disabled":false,"invoiceWholesaleInfo":{"partnerId":12345,"partner":{"id":12345,"firstName":"Sasha Wholesale TEST SAME ID 1 Greater RCUS Partner FirstName","lastName":"Sasha Wholesale TEST SAME ID 1 Greater RCUS Partner LastName","companyName":"Sasha Wholesale TEST SAME ID 1 Greater RCUS  Partner Company","addresses":[{"label":"AccountsPayable","firstName":"Reseller name on address","lastName":"my last name","phone":"123 4546 67","email":"ttt@gmail.com","street1":"my street","street2":null,"city":"Belmont","county":null,"state":"CA","zip":"94506","country":"USA"}],"hierarchyType":"Reseller","externalPartnerAccountId":"ResellerSameIDGreater1","partnerType":"Wholesale","invoiceSettings":{"invoicingPartnerId":522001},"settlementSettings":{"settlementPartnerId":521001,"settlementRatePartnerId":521001,"settlementType":"RebateGreaterOfWholesale"},"status":"Active","created":"2021-12-17T10:15:17.113566Z[UTC]","updated":"2021-12-17T10:15:17.113566Z[UTC]","csn":1,"businessIdentityId":4,"taxExemption":true,"requiresBillingFeed":false,"parent":{"id":521001,"firstName":"Sasha Wholesale TEST SAME ID 1 MASTER RCUS Partner FirstName","lastName":"Sasha Wholesale TEST SAME ID 1 MASTER RCUS Partner LastName","companyName":"Sasha Wholesale TEST SAME ID 1 MASTER RCUS  Partner Company","addresses":[{"label":"AccountsPayable","firstName":"Reseller name on address","lastName":"my last name","phone":"123 4546 67","email":"ttt@gmail.com","street1":"my street","street2":null,"city":"Belmont","county":null,"state":"CA","zip":"94506","country":"USA"}],"hierarchyType":"Master","externalPartnerAccountId":"SameIdMaster1","partnerType":"Wholesale","settlementSettings":{"settlementType":"RebateDiffOfWholesale"},"status":"Active","created":"2021-12-17T10:04:26.719913Z[UTC]","updated":"2021-12-17T10:04:26.719913Z[UTC]","csn":1,"businessIdentityId":4,"parent":{"id":106001,"firstName":"Sasha testpdf Wh Partner FirstName","lastName":"Sasha testpdf Wh Partner LastName","companyName":"Sasha testpdf Wh Partner Company","addresses":[{"label":"AccountsPayable","firstName":"Reseller name on address","lastName":"my last name","phone":"123 4546 67","email":"ttt@gmail.com","street1":"my street","street2":null,"city":"Belmont","county":null,"state":"CA","zip":"94506","country":"USA"}],"hierarchyType":"Master","externalPartnerAccountId":"ResellerPartnerId324","partnerType":"Wholesale","status":"Active","created":"2021-11-03T13:48:51.838375Z[UTC]","updated":"2021-11-03T13:48:51.838375Z[UTC]","csn":1,"businessIdentityId":4},"parentId":106001},"parentId":521001},"address":{"label":null,"firstName":"FPSKWhoRCUS1712","lastName":"LPSKWhoRCUS1712","phone":null,"email":null,"street1":"1 Wall Street","street2":null,"city":"New York","county":null,"state":"NY","zip":"10005","country":"USA"},"partnerCatalogId":"440001.2","applicableCatalogPackage":"19.1"},"default":true}]';

    private static final String MONTHLY_AMOUNT_LIMIT_RESPONSE = '[{"id":20392013,"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":33333,"type":"Amount",' +
    '"scope":"BillingCycle","transactionType":"Any","target":"Global","targetId":null,"exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
    '"override":true,"paymentType":null,"startDate":null,"limitDuration":null,"overriddenLimitId":null,"limitOverride":{"id":20393013,' +
    '"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":7370,"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
    '"target":"Global","targetId":null,"exclusions":null,"override":true,"paymentType":"InvoiceWholesale","startDate":"2022-04-13T07:49Z[UTC]",' +
    '"limitDuration":{"unit":"Months","value":30},"overriddenLimitId":20392013,"limitOverride":null}}]';

    @testSetup
    static void generateData() {
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi',
            CatalogPath__c = '/restapi/v1.0/catalog',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
        upsert new NGBS_Settings_FedRamp__c(
            BaseEndpoint__c = 'https://testfedrampapi',
            CatalogPath__c = '/restapi/v1.0/catalog',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
    }

    @isTest
    static void realDataWithExceedAdditionalCancellation() {
        List<TransactionsRefundsAPI.ProductItemDTO> productItems = new List<TransactionsRefundsAPI.ProductItemDTO>();
        productItems.add(createProduct('P:7.1,L:LC_LM_406', 'LM', 'FeatureCharge', 90, 2.9, '1'));
        productItems.add(createProduct('P:7.1,L:LC_LM_406', 'LM', 'CancellationCredit', -456.16, 0, '2'));
        productItems.add(createProduct('P:7.1,L:LC_LM_406', 'LM', 'FeatureCharge', 900, 456.16, '3'));
        productItems.add(createProduct('P:7.1,L:LC_LM_406', 'LM', 'CancellationCredit', -2.9, 0, '4'));
        productItems.add(createProduct('P:7.1,L:LC_WB_409', 'WB', 'FeatureCharge', 40, 1.29, '5'));
        productItems.add(createProduct('P:7.1,L:LC_WB_409', 'WB', 'CancellationCredit', -202.74, 0, '6'));
        productItems.add(createProduct('P:7.1,L:LC_WB_409', 'WB', 'FeatureCharge', 400, 202.74, '7'));
        productItems.add(createProduct('P:7.1,L:LC_WB_409', 'WB', 'CancellationCredit', -1.29, 0, '8'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'FeatureCharge', 12.99, 0, '9'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'FeatureCharge', 64.95, 0, '10'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'FeatureCharge', 1299.00, 42.0, '11'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'AdjustmentCredit', -0.48, 0, '12'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'AdjustmentCredit', -2.40, 0, '13'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'CancellationCredit', -65.84, 0, '14'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'CancellationCredit', -329.20, 0, '15'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'CancellationCredit', -6584.00, 0, '16'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'FeatureCharge', 74.95, 48.35, '17'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'FeatureCharge', 129.9, 65.84, '18'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'FeatureCharge', 649.5, 329.2, '19'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'FeatureCharge', 12990.0, 6584.0, '20'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'CancellationCredit', -0.42, 0, '21'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'CancellationCredit', -2.10, 0, '22'));
        productItems.add(createProduct('P:7.1,L:LC_SM_405', 'SM', 'CancellationCredit', -42.00, 0, '23'));
        productItems.add(createProduct('P:7.1,L:LC_SC_404', 'SC', 'CancellationCredit', 0, 0, '24'));
        productItems.add(createProduct('P:7.1,L:LC_SC_404', 'SC', 'FeatureCharge', 0, 0, '25'));
        productItems.add(createProduct('P:7.1,L:LC_SC_404', 'SC', 'CancellationCredit', 0, 0, '26'));
        productItems.add(createProduct('P:8.1,L:LC_SC_404', 'SC', 'FeatureCharge', 0, 0, '27'));
        productItems.add(createProduct('P:8.1,L:LC_SM_405', 'SM', 'FeatureCharge', 179.9, 91.18, '28'));
        productItems.add(createProduct('P:8.1,L:LC_SM_405', 'SM', 'FeatureCharge', 899.5, 455.9, '29'));
        productItems.add(createProduct('P:8.1,L:LC_SM_405', 'SM', 'FeatureCharge', 17990.0, 9118.0, '30'));
        productItems.add(createProduct('P:8.1,L:LC_LM_406', 'LM', 'FeatureCharge', 900, 456.16, '31'));
        productItems.add(createProduct('P:8.1,L:LC_LM_407', 'LM', 'FeatureCharge', 1400, 709.59, '32'));
        productItems.add(createProduct('P:8.1,L:LC_WB_409', 'WB', 'FeatureCharge', 400, 202.74, '33'));
        productItems.add(createProduct('P:8.1,L:LC_RCON_417', 'RCON', 'FeatureCharge', 468, 237.21, '34'));
        productItems.add(createProduct(null, 'Remote Software', 'Tax Charge', 0.26, 0, '35'));
        productItems.add(createProduct(null, 'Remote Software', 'Tax Charge', 2.6, 0, '36'));
        productItems.add(createProduct(null, 'Remote Software', 'Tax Charge', 227.05, 0, '37'));
        productItems.add(createProduct(null, 'Remote Software', 'Tax Charge', 3.02, 0, '38'));
        productItems.add(createProduct(null, 'Remote Software', 'Tax Charge', 474.33, 0, '39'));
        productItems.add(createProduct('P:7.1,L:LC_SM_499', 'SM', 'CancellationCredit', -1000000, 0, '40'));

        List<TransactionsRefundsAPI.ProductItemDTO> resultProductItems = NGBSAPI.recalculateMaxRefunds(productItems);
        Map<String, TransactionsRefundsAPI.ProductItemDTO> productIdToItem = getMapProductIdToItem(productItems);
        System.assertEquals(resultProductItems.size(), 27);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('1')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('3')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('5')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('7')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('9')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('10')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('11')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('17')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('18')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('19')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('20')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('25')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('27')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('28')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('29')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('30')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('31')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('32')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('33')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('34')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('35')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('36')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('37')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('38')), 0);
        System.assertEquals(getRoundedMaxRefund(productIdToItem.get('39')), 0);
    }


    @isTest
    static void testCombinedCatalogIdOnly() {
        List<TransactionsRefundsAPI.ProductItemDTO> productItems = new List<TransactionsRefundsAPI.ProductItemDTO>();
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_0, ITEM_TYPE_SOMETHING, 100));
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_1, ITEM_TYPE_CANCELLATION_CREDIT, -50));
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_2, ITEM_TYPE_SOMETHING, 20));
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_3, ITEM_TYPE_CANCELLATION_CREDIT, -35));
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_2, ITEM_TYPE_SOMETHING, 50));
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_3, ITEM_TYPE_CANCELLATION_CREDIT, -25));
        List<TransactionsRefundsAPI.ProductItemDTO> resultProductItems = NGBSAPI.recalculateMaxRefunds(productItems);
        System.debug('productItems =>> ' + productItems);

        System.assertEquals(3, resultProductItems.size(), 'All negative items should be removed and only positive left');
        System.assertEquals(35.29, getRoundedMaxRefund(resultProductItems[0]),
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
        System.assertEquals(7.06, getRoundedMaxRefund(resultProductItems[1]),
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
        System.assertEquals(17.65, getRoundedMaxRefund(resultProductItems[2]),
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
    }

    @isTest
    static void testMultipleCombinedCatalogIdOnly() {
        List<TransactionsRefundsAPI.ProductItemDTO> productItems = new List<TransactionsRefundsAPI.ProductItemDTO>();
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_0, ITEM_TYPE_SOMETHING, 80));
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_1, ITEM_TYPE_CANCELLATION_CREDIT, -50));
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_2, ITEM_TYPE_SOMETHING, 20));
        productItems.add(createProduct(COMBINED_CATALOG_ID_1, CATEGORY_ID_3, ITEM_TYPE_CANCELLATION_CREDIT, -35));
        productItems.add(createProduct(COMBINED_CATALOG_ID_1, CATEGORY_ID_2, ITEM_TYPE_SOMETHING, 50));
        productItems.add(createProduct(COMBINED_CATALOG_ID_1, CATEGORY_ID_3, ITEM_TYPE_CANCELLATION_CREDIT, -25));
        List<TransactionsRefundsAPI.ProductItemDTO> resultProductItems = NGBSAPI.recalculateMaxRefunds(productItems);
        System.debug('productItems =>> ' + productItems);

        System.assertEquals(3, resultProductItems.size(), 'All negative items should be removed and only positive left');
        System.assertEquals(32, resultProductItems[0].items[0].maxRefundAmount,
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
        System.assertEquals(8, resultProductItems[1].items[0].maxRefundAmount,
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
        System.assertEquals(0, resultProductItems[2].items[0].maxRefundAmount,
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
    }

    @isTest
    static void testBoundaryConditions() {
        List<TransactionsRefundsAPI.ProductItemDTO> productItems = new List<TransactionsRefundsAPI.ProductItemDTO>();
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_0, ITEM_TYPE_SOMETHING, 0.01));
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_1, ITEM_TYPE_CANCELLATION_CREDIT, -0.01));
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_2, ITEM_TYPE_SOMETHING, 0.01));
        List<TransactionsRefundsAPI.ProductItemDTO> resultProductItems = NGBSAPI.recalculateMaxRefunds(productItems);
        //0.12/0.1 = 0. 0.12/0.02 ==
        //0.075 = 0.08
        //0.015 = 0.01
        //for first first item maxRefund is expected to be 0.075, for second item maxRefund is expected to be 0.015.
        //Since we're rounding it to 2 digits, rounded values will be 0.08 and 0.02, which is not right.
        //In such cases, all items except of last should be rounded as usual, butlast item should be calculated as:
        //0.1+0.02-0.03 - 0.08 = 0.01
        //0.1+0.01-0.01-refundedAlready
        System.debug('productItems =>> ' + productItems);

        System.assertEquals(2, resultProductItems.size(), 'All negative items should be removed and only positive left');
        System.assertEquals(0, getRoundedMaxRefund(resultProductItems[0]),
            'both items should be nullified because of rounding');
        System.assertEquals(0, getRoundedMaxRefund(resultProductItems[1]),
            'both items should be nullified because of rounding');
    }

    @isTest
    static void testSingleItemPerLicense() {
        List<TransactionsRefundsAPI.ProductItemDTO> productItems = new List<TransactionsRefundsAPI.ProductItemDTO>();
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_0, ITEM_TYPE_SOMETHING, 0.01));
        productItems.add(createProduct(COMBINED_CATALOG_ID_1, CATEGORY_ID_1, ITEM_TYPE_CANCELLATION_CREDIT, -0.01));
        productItems.add(createProduct(COMBINED_CATALOG_ID_2, CATEGORY_ID_2, ITEM_TYPE_SOMETHING, 0.01));
        List<TransactionsRefundsAPI.ProductItemDTO> resultProductItems = NGBSAPI.recalculateMaxRefunds(productItems);
        System.debug('productItems =>> ' + productItems);

        System.assertEquals(3, resultProductItems.size(),
            'All items should be in the list, because negative items that were not a part of calculation ' +
                'should remain in the list');
        System.assertEquals(0.01, resultProductItems[0].items[0].maxRefundAmount,
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
        System.assertEquals(-0.01, resultProductItems[1].items[0].maxRefundAmount,
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
        System.assertEquals(0.01, resultProductItems[2].items[0].maxRefundAmount,
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
    }

    @isTest
    static void testCategoryIdOnly() {
        List<TransactionsRefundsAPI.ProductItemDTO> productItems = new List<TransactionsRefundsAPI.ProductItemDTO>();
        productItems.add(createProduct(COMBINED_CATALOG_ID_0, CATEGORY_ID_0, ITEM_TYPE_SOMETHING, 100));
        productItems.add(createProduct(COMBINED_CATALOG_ID_1, CATEGORY_ID_0, ITEM_TYPE_CANCELLATION_CREDIT, -50));
        productItems.add(createProduct(COMBINED_CATALOG_ID_2, CATEGORY_ID_0, ITEM_TYPE_SOMETHING, 20));
        productItems.add(createProduct(COMBINED_CATALOG_ID_3, CATEGORY_ID_0, ITEM_TYPE_CANCELLATION_CREDIT, -35));
        productItems.add(createProduct(COMBINED_CATALOG_ID_4, CATEGORY_ID_0, ITEM_TYPE_SOMETHING, 50));
        productItems.add(createProduct(COMBINED_CATALOG_ID_5, CATEGORY_ID_0, ITEM_TYPE_CANCELLATION_CREDIT, -25));
        List<TransactionsRefundsAPI.ProductItemDTO> resultProductItems = NGBSAPI.recalculateMaxRefunds(productItems);

        System.assertEquals(3, resultProductItems.size(), 'All negative items should be removed and only positive left');
        System.assertEquals(35.29, getRoundedMaxRefund(resultProductItems[0]),
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
        System.assertEquals(7.06, getRoundedMaxRefund(resultProductItems[1]),
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
        System.assertEquals(17.65, getRoundedMaxRefund(resultProductItems[2]),
            UNEXPECTED_NGBSAPI_RECALCULATE_RESULT);
    }

//    private static TransactionsRefundsAPI.ItemsDTO createProductItem(
//        String combinedCatalogId,
//        String categoryId,
//        String itemType,
//        Decimal amount
//    ) {
//        TransactionsRefundsAPI.ItemsDTO item = new TransactionsRefundsAPI.ItemsDTO();
//        item.combinedCatalogId = combinedCatalogId;
//        item.categoryId = categoryId;
//        item.itemType = itemType;
//        item.transactionAmount = amount;
//        item.maxRefundAmount = amount;
//        return item;
//    }

    private static TransactionsRefundsAPI.ProductItemDTO createProduct(
        TransactionsRefundsAPI.ItemsDTO item1,
        TransactionsRefundsAPI.ItemsDTO item2,
        String productId
    ) {
        TransactionsRefundsAPI.ProductItemDTO pi = new TransactionsRefundsAPI.ProductItemDTO();
        pi.productId = productId;
        pi.items = new List<TransactionsRefundsAPI.ItemsDTO>();
        if (item1 != null) {
            pi.items.add(item1);
        }
        if (item2 != null) {
            pi.items.add(item2);
        }
        return pi;
    }

    private static TransactionsRefundsAPI.ProductItemDTO createProduct(
        String combinedCatalogId,
        String categoryId,
        String itemType,
        Decimal amount
    ) {
        return createProduct(combinedCatalogId, categoryId, itemType, amount, amount, null);
    }

    private static TransactionsRefundsAPI.ProductItemDTO createProduct(
        String combinedCatalogId,
        String categoryId,
        String itemType,
        Decimal amount,
        String productId
    ) {
        return createProduct(combinedCatalogId, categoryId, itemType, amount, amount, productId);
    }


    private static TransactionsRefundsAPI.ProductItemDTO createProduct(
        String combinedCatalogId,
        String categoryId,
        String itemType,
        Decimal amount,
        Decimal maxRefundAmount,
        String productId
    ) {
        TransactionsRefundsAPI.ProductItemDTO pi = new TransactionsRefundsAPI.ProductItemDTO();
        pi.transactionAmount = amount;
        if (String.isNotBlank(productId)) {
            pi.productId = productId;
        }

        TransactionsRefundsAPI.ItemsDTO item = new TransactionsRefundsAPI.ItemsDTO(pi);
        item.combinedCatalogId = combinedCatalogId;
        item.maxRefundAmount = maxRefundAmount;
        item.categoryId = categoryId;
        item.itemType = itemType;
        item.maxRefundAmount = maxRefundAmount;

        pi.items = new List<TransactionsRefundsAPI.ItemsDTO>();
        pi.items.add(item);
        return pi;
    }

    private static Map<String, TransactionsRefundsAPI.ProductItemDTO> getMapProductIdToItem(
        List<TransactionsRefundsAPI.ProductItemDTO> products
    ) {
        Map<String, TransactionsRefundsAPI.ProductItemDTO> productIdToItem =
            new Map<String, TransactionsRefundsAPI.ProductItemDTO>();
        for (TransactionsRefundsAPI.ProductItemDTO item : products) {
            productIdToItem.put(item.productId, item);
        }
        return productIdToItem;
    }

    private static Decimal getRoundedMaxRefund(TransactionsRefundsAPI.ProductItemDTO product) {
        return product.items[0].maxRefundAmount.setScale(2, RoundingMode.HALF_DOWN);
    }

    @isTest
    static void normalizeTransactionDate() {
        String dateStr1 = '2018-07-23T08:01:51.177Z[UTC]';
        String dateStr2 = '2018-07-23T08:01:51.177Z';

        String result1 = NGBSAPI.normalizeTransactionDate(dateStr1);
        String result2 = NGBSAPI.normalizeTransactionDate(dateStr2);

        System.assertEquals('2018-07-23T08:01:51.177Z', result1);
        System.assertEquals('2018-07-23T08:01:51.177Z', result2);
    }

    @isTest
    static void ConvertToLocal() {
        String dateStr = '2018-07-23T08:01:51.177Z';
        String result = NGBSAPI.convertToLocal(dateStr);

        Organization org = [select TimeZoneSidKey from Organization];

        Datetime dt = (Datetime) JSON.deserialize('"'+dateStr+'"', Datetime.class);
        String formatted = dt.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'', org.TimeZoneSidKey);

        System.assertEquals(formatted, result);
    }

    @isTest
    static void convertLocalDateToUTC() {
        String result = NGBSAPI.convertLocalDateToUTC(
            Date.valueOf('2019-01-10'),
            'yyyy-MM-dd HH:mm'
        );

        DateTime dtUTC = DateTime.newInstanceGmt(2019, 1, 10);
        Organization org = [select TimeZoneSidKey from Organization];
        TimeZone tz = TimeZone.getTimeZone(org.TimeZoneSidKey);
        Integer offsetToUtc = tz.getOffset(dtUTC);

        dtUTC = dtUTC.addSeconds(-offsetToUtc/1000);

        String formatted = dtUTC.formatGMT('yyyy-MM-dd HH:mm');

        System.assertEquals(formatted, result);
    }

    // @isTest
    // static void testGetExpirationTypeAboutToExpire() {

    //     final String catalogId = '5';
    //     final String catalogVersion = '3';

    //     Test.startTest();

    //         BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
    //         tstMock.body = '{"labels":{"Brand":["RingCentral"],"UpgradeWizardExpiration":["' + BillingWrappers.EXPIRATION_TYPE_ABOUT_TO_EXPIRE +  '"]},' +
    //             '"version":"' + catalogVersion + '","id":"' + catalogId + '"}';
    //         tstMock.code = 200;
    //         tstMock.status = 'Complete';

    //         Test.setMock(HttpCalloutMock.class, tstMock);
    //         System.debug('catalogId' + catalogId);

    //         String expirationType = NGBSAPI.getPackageExpirationInfo(catalogId, catalogVersion);

    //         System.assertEquals(
    //             BillingWrappers.EXPIRATION_TYPE_ABOUT_TO_EXPIRE,
    //             expirationType,
    //             'extracted package expiration type is not equal to expiration type passed in json'
    //         );

    //     Test.stopTest();
    // }

    // @isTest
    // static void testGetExpirationTypeExpired() {

    //     final String catalogId = '5';
    //     final String catalogVersion = '3';

    //     Test.startTest();

    //         BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
    //         tstMock.body = '{"labels":{"Brand":["RingCentral"],"UpgradeWizardExpiration":["Expired"]},' +
    //             '"version":"' + catalogVersion + '","id":"' + catalogId + '"}';
    //         tstMock.code = 200;
    //         tstMock.status = 'Complete';

    //         Test.setMock(HttpCalloutMock.class, tstMock);

    //         String expirationType = NGBSAPI.getPackageExpirationInfo(catalogId, catalogVersion);

    //         System.assertEquals(
    //             BillingWrappers.EXPIRATION_TYPE_EXPIRED,
    //             expirationType,
    //             'extracted package expiration type is not equal to expiration type passed in json'
    //         );

    //     Test.stopTest();
    // }


    @isTest
    static void testExtractExpirationInfoMethod() {
        BillingWrappers.NGBSPackage pkg = new BillingWrappers.NGBSPackage();
        pkg.labels = new BillingWrappers.BillingLabels();
        pkg.labels.upgradeWizardExpiration = new List<String>{'Expired'};
        String expirationType = NGBSAPI.extractExpirationInfo(pkg);
        System.assertEquals(
            BillingWrappers.EXPIRATION_TYPE_EXPIRED,
            expirationType,
            'extracted expirationType should have value "Expired"'
        );

        pkg.labels.upgradeWizardExpiration = new List<String>{'AboutToExpire'};
        expirationType = NGBSAPI.extractExpirationInfo(pkg);
        System.assertEquals(
            'AboutToExpire',
            expirationType,
            'extracted expirationType should have value "AboutToExpire"'
        );

        pkg.labels.upgradeWizardExpiration = new List<String>{BillingWrappers.EXPIRATION_TYPE_ABOUT_TO_EXPIRE};
        expirationType = NGBSAPI.extractExpirationInfo(pkg);
        System.assertEquals(
            BillingWrappers.EXPIRATION_TYPE_ABOUT_TO_EXPIRE,
            expirationType,
            'extracted expirationType should have value "About To Expire"'
        );

        // test expected exceptions is thrown
        final String exMessage = 'An exception should have been thrown by the NGBSAPI.extractExpirationInfo method but was not.';

        // if extractExpirationInfo method was invoked with empty parameters(null or '') - an exception should be thrown
        try{
            BillingWrappers.NGBSPackage pkgNull;
            NGBSAPI.extractExpirationInfo(pkgNull);
            throw new AquivaHelper.AquivaException(exMessage);
        }catch(Exception ex) {
            Boolean isExpectedExceptionThrown = ex.getMessage().contains(NGBSAPI.NOT_FOUND_LABELS_JSON_PROPERTY_EXCEPTION_MESSAGE);
            System.assert(isExpectedExceptionThrown, 'an unexpected exception was thrown by the NGBSAPI.extractExpirationInfo method');
        }
    }

    @isTest
    private static void testGetBillingInfoSummary() {
        String accountId = '3120888001';
        String packageId = '3104295001';

        String bodyForMock = '{"accountId":3120888001,"packageId":3104295001,' +
        '"packageDescription":"RingCentral Office Ultimate","product":"Office","productLine":"RC",' +
        '"previousBillingDate":"2019-12-23T13:19Z[UTC]","nextBillingDate":"2020-01-23T08:00Z[UTC]",' +
        '"nextMasterBillDate":"2020-01-23T08:00Z[UTC]","masterDuration":"Monthly",' +
        '"mixedLicenseDurations":false,"packageProps":{"base tier":"4999","rateplan":"RBS:RCOFFICE:21,54,58"},' +
        '"creditBalance":-422.75,"unappliedCredit":0,"freeServiceCredit":{"amount":100},' +
        '"packageDescriptionKey":"FC65800080D8806490E4BCD31BB363FD"}';

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        tstMock.body = bodyForMock;
        tstMock.code = 200;
        tstMock.status = 'Complete';

        Test.setMock(HttpCalloutMock.class, tstMock);

        Test.startTest();
        String result = NGBSAPI.getBillingInfoSummary(accountId, packageId);
        Test.stopTest();

        System.assertEquals(
            bodyForMock,
            result,
            'Response should return correct body'
        );
    }

    @isTest
    private static void testGetBillingInfoSummaryNullAccountIdAndPackageId() {
        Boolean isExceptionThrown = false;
        try {
            NGBSAPI.getBillingInfoSummary(null, null);
        } catch (AquivaHelper.AquivaException ex) {
            isExceptionThrown = ex.getMessage().contains(NGBSAPI.BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }

        System.assert(
            isExceptionThrown,
            'Exception should be thrown'
        );
    }

    @isTest
    private static void testGetBillingInfoSummaryShouldThrowException() {
        String accountId = '3120888001';
        String packageId = '3104295001';

        Boolean isExceptionThrown = false;
        try {
            NGBSAPI.getBillingInfoSummary(accountId, packageId);
        } catch (AquivaHelper.AquivaException ex) {
            isExceptionThrown = ex.getMessage().contains(NGBSAPI.REQUEST_BILLING_INFO_SUMMARY_NGBS_EXCEPTION_MESSAGE);
        }

        System.assert(
            isExceptionThrown,
            'Exception should be thrown'
        );
    }

    @isTest
    private static void testGetBillingInfoSummaryLicense() {
        String accountId = '3120888001';
        String packageId = '3104295001';

        String bodyForMock = '[{' +
            '"amount": 120009.99,' +
            '"catalogId": "LC_DL-UNL_50",' +
            '"discountAmount": -36012,' +
            '"discountValue": {"unit": "Percent","value": 30},' +
            '"qty": 3001,' +
            '"billingType": "Recurring",' +
            '"billingCycleDuration": "Monthly",' +
            '"dateRangeStart": "2020-06-17",' +
            '"dateRangeEnd": "2020-07-16",' +
            '"description": "DigitalLine Unlimited",' +
            '"descriptionKey": "C42D89795912155D0609ADF07491A640"' +
        '}]';

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        tstMock.body = bodyForMock;
        tstMock.code = 200;
        tstMock.status = 'Complete';

        Test.setMock(HttpCalloutMock.class, tstMock);

        Test.startTest();
        List<BillingWrappers.BillingInfoSummaryLicense> result = NGBSAPI.getNGBSBillingInfoSummaryLicenses(
            accountId,
            packageId
        );
        Test.stopTest();

        System.assertEquals(
            1,
            result.size(),
            'Response should return with 1 license'
        );
    }

    @isTest
    private static void testGetBillingInfoSummaryLicenseNullAccountIdAndPackageId() {
        Boolean isExceptionThrown = false;
        try {
            NGBSAPI.getNGBSBillingInfoSummaryLicenses(null, null);
        } catch (AquivaHelper.AquivaException ex) {
            isExceptionThrown = ex.getMessage().contains(NGBSAPI.BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }

        System.assert(
            isExceptionThrown,
            'Exception should be thrown'
        );
    }

    @isTest
    private static void testConvertToListOfTransactions() {
        NGBSAPI.AccountHistoryBill historyBill1 = new NGBSAPI.AccountHistoryBill(
            null, null, 'Unpaid', null
        );
        NGBSAPI.AccountHistoryBill historyBill2 = new NGBSAPI.AccountHistoryBill(
            null, null, null, -10
        );
        NGBSAPI.AccountHistoryBill historyBill3 = new NGBSAPI.AccountHistoryBill(
            123, '2020-02-20', null, 10
        );

        List<NGBSAPI.AccountHistoryBill> bills = new List<NGBSAPI.AccountHistoryBill> {
            historyBill1, historyBill2, historyBill3
        };

        NGBSAPI.PendingInvoice pendingInvoice1 = new NGBSAPI.PendingInvoice(
            null, null, -10
        );
        NGBSAPI.PendingInvoice pendingInvoice2 = new NGBSAPI.PendingInvoice(
            456, '2020-02-20', 10
        );

        List<NGBSAPI.PendingInvoice> pendingInvoices = new List<NGBSAPI.PendingInvoice> {
            pendingInvoice1, pendingInvoice2
        };

        Test.startTest();
        List<TransactionsRefundsAPI.TransactionsDTO> result = new NGBSAPI.AccountHistoryResponse(
            pendingInvoices, bills
        ).convertToListOfTransactions();
        Test.stopTest();

        System.assertEquals(
            2,
            result.size(),
            'Result list should contain 2 elements'
        );
        System.assertEquals(
            '123',
            result[0].transactionId,
            'transactionId field populated incorrectly for 1st element'
        );
        System.assertEquals(
            TransactionsRefundsAPI.TRANSACTION_NGBS_TYPE_BILL,
            result[0].ngbsType,
            'ngbsType field populated incorrectly for 1st element'
        );
        System.assertEquals(
            '456',
            result[1].transactionId,
            'transactionId field populated incorrectly for 2nd element'
        );
        System.assertEquals(
            TransactionsRefundsAPI.TRANSACTION_NGBS_TYPE_INVOICE,
            result[1].ngbsType,
            'ngbsType field populated incorrectly for 2nd element'
        );
    }

    @isTest
    private static void testConvertToListOfTransactionsWithNullArguments() {
        Test.startTest();
        List<TransactionsRefundsAPI.TransactionsDTO> result = new NGBSAPI.AccountHistoryResponse(
            null, null
        ).convertToListOfTransactions();
        Test.stopTest();

        System.assert(
            result.isEmpty(),
            'Result list should be empty'
        );
    }

    @isTest
    private static void testConvertToProductItem() {
        List<TransactionsRefundsAPI.ProductItemDTO> result = new NGBSAPI.BillDetail (
            null, null
        ).convertToProductItem('some type');

        System.assertEquals(
            0,
            result.size(),
            'Method should return empty array for null bill'
        );
    }

    @isTest
    private static void testGetPaymentType() {
        List<NGBSAPI.DetailPayments> payments = new List<NGBSAPI.DetailPayments> {
            new NGBSAPI.DetailPayments(new NGBSAPI.DetailPaymentMethod('123', 'some type'))
        };

        String result = new NGBSAPI.BillDetail (
            null, payments
        ).getPaymentType();

        System.assertEquals(
            'some type',
            result,
            'Method should return correct payment type'
        );
    }

    @isTest
    private static void testGetPaymentTypeWithNullPayment() {
        String result = new NGBSAPI.BillDetail (
            null, null
        ).getPaymentType();

        System.assertEquals(
            null,
            result,
            'Method should return null value'
        );
    }

    @isTest
    private static void testGetContractsBillingEndpoint() {
        String resultEndpoint = NGBSAPI.getContractsBillingEndpoint('123', '456');
        System.assertEquals(
            'https://testapi/restapi/account-manager/v1.0/account/123/contract',
            resultEndpoint,
            'Result Endpoing created incorrectly'
        );
    }

    @isTest
    private static void testTaxExemption() {
        NGBSAPI.TaxExemption taxExemption = new NGBSAPI.TaxExemption();

        System.assert(
            !taxExemption.getFederalTaxExemption(),
            'Field federalTaxExemption should be false'
        );
        System.assert(
            !taxExemption.getStateTaxExemption(),
            'Field stateTaxExemption should be false'
        );
        System.assert(
            !taxExemption.getCountyTaxExemption(),
            'Field countyTaxExemption should be false'
        );
        System.assert(
            !taxExemption.getLocalTaxExemption(),
            'Field localTaxExemption should be false'
        );

        System.assert(
            !taxExemption.getSalesTaxExemption(),
            'Field salesTaxExemption should be false'
        );

        System.assert(
            taxExemption.getVatNumber() == null,
            'Field VAT Number should be null'
        );

        System.assert(
            !taxExemption.getVatExemption(),
            'Field VATExemption should be false'
        );

        System.assert(
            taxExemption.getVatCountry() == null,
            'Field VAT Country should be null'
        );

        taxExemption.setFederalTaxExemption(true);
        taxExemption.setStateTaxExemption(true);
        taxExemption.setCountyTaxExemption(true);
        taxExemption.setLocalTaxExemption(true);
        taxExemption.setSalesTaxExemption(true);
        taxExemption.setVatExemption(true);
        taxExemption.setVatCountry('testCountry');
        taxExemption.setVatNumber('testVATNumber');

        System.assert(
            taxExemption.getFederalTaxExemption(),
            'Field federalTaxExemption should be true'
        );
        System.assert(
            taxExemption.getStateTaxExemption(),
            'Field stateTaxExemption should be true'
        );
        System.assert(
            taxExemption.getCountyTaxExemption(),
            'Field countyTaxExemption should be true'
        );
        System.assert(
            taxExemption.getLocalTaxExemption(),
            'Field localTaxExemption should be true'
        );

        System.assert(
            taxExemption.getSalesTaxExemption(),
            'Field salesTaxExemption should be true'
        );

        System.assert(
            taxExemption.getVatExemption(),
            'Field VATExemption should be true'
        );

        System.assert(
            taxExemption.getVatNumber() == 'testVATNumber',
            'Field VATExemption should be "testVATNumber"'
        );

        System.assert(
            taxExemption.getVatCountry() == 'testCountry',
            'Field VATExemption should be "testCountry"'
        );
    }

    @isTest
    private static void testBillDetailBillInvoiceItemConstructor() {
        NGBSAPI.BillDetailBillInvoiceItem billDetailBillInvoiceItem = new NGBSAPI.BillDetailBillInvoiceItem(
            'lineNo', 'licenseId', 'description', 'categoryId', 'billingCodeId',
            'combinedCatalogId', 'itemType', 'itemGroupId', 100, null
        );

        System.assertEquals(
            'lineNo',
            billDetailBillInvoiceItem.lineNo,
            'Field lineNo populated incorrectly'
        );
        System.assertEquals(
            'licenseId',
            billDetailBillInvoiceItem.licenseId,
            'Field licenseId populated incorrectly'
        );
        System.assertEquals(
            'description',
            billDetailBillInvoiceItem.description,
            'Field description populated incorrectly'
        );
        System.assertEquals(
            'categoryId',
            billDetailBillInvoiceItem.categoryId,
            'Field categoryId populated incorrectly'
        );
        System.assertEquals(
            'billingCodeId',
            billDetailBillInvoiceItem.billingCodeId,
            'Field billingCodeId populated incorrectly'
        );
        System.assertEquals(
            'combinedCatalogId',
            billDetailBillInvoiceItem.combinedCatalogId,
            'Field combinedCatalogId populated incorrectly'
        );
        System.assertEquals(
            'itemType',
            billDetailBillInvoiceItem.itemType,
            'Field itemType populated incorrectly'
        );
        System.assertEquals(
            'itemGroupId',
            billDetailBillInvoiceItem.itemGroupId,
            'Field itemGroupId populated incorrectly'
        );
        System.assertEquals(
            100,
            billDetailBillInvoiceItem.amount,
            'Field amount populated incorrectly'
        );
        System.assertEquals(
            null,
            billDetailBillInvoiceItem.properties,
            'Field properties populated incorrectly'
        );
    }

    @isTest
    private static void testBillDetailBillInvoiceItemDefaultConstructor() {
        NGBSAPI.BillDetailBillInvoiceItem billDetailBillInvoiceItem = new NGBSAPI.BillDetailBillInvoiceItem();

        System.assertEquals(
            null,
            billDetailBillInvoiceItem.lineNo,
            'Field lineNo populated incorrectly'
        );
        System.assertEquals(
            null,
            billDetailBillInvoiceItem.licenseId,
            'Field licenseId populated incorrectly'
        );
        System.assertEquals(
            null,
            billDetailBillInvoiceItem.description,
            'Field description populated incorrectly'
        );
        System.assertEquals(
            null,
            billDetailBillInvoiceItem.categoryId,
            'Field categoryId populated incorrectly'
        );
        System.assertEquals(
            null,
            billDetailBillInvoiceItem.billingCodeId,
            'Field billingCodeId populated incorrectly'
        );
        System.assertEquals(
            null,
            billDetailBillInvoiceItem.combinedCatalogId,
            'Field combinedCatalogId populated incorrectly'
        );
        System.assertEquals(
            null,
            billDetailBillInvoiceItem.itemType,
            'Field itemType populated incorrectly'
        );
        System.assertEquals(
            null,
            billDetailBillInvoiceItem.itemGroupId,
            'Field itemGroupId populated incorrectly'
        );
        System.assertEquals(
            null,
            billDetailBillInvoiceItem.amount,
            'Field amount populated incorrectly'
        );
        System.assertEquals(
            null,
            billDetailBillInvoiceItem.properties,
            'Field properties populated incorrectly'
        );
    }

    @isTest
    private static void testBillDetailBillInvoiceItemPropertiesConstructor() {
        NGBSAPI.BillDetailBillInvoiceItemProperties prop = new NGBSAPI.BillDetailBillInvoiceItemProperties(
            'taxItemId', 'taxLevel'
        );

        System.assertEquals(
            'taxItemId',
            prop.taxItemId,
            'Field taxItemId populated incorrectly'
        );
        System.assertEquals(
            'taxLevel',
            prop.taxLevel,
            'Field taxLevel populated incorrectly'
        );
    }

    @isTest
    private static void testFreeServiceCreditApplicationInfoConstructor() {
        NGBSAPI.FreeServiceCreditApplicationInfo fscAppInfo = new NGBSAPI.FreeServiceCreditApplicationInfo(1);
        System.assertEquals(
            1,
            fscAppInfo.appliedCredit,
            'Field appliedCredit populated incorrectly'
        );
    }

    @isTest
    private static void testRefundApplicationMapWrapperConstructor() {
        NGBSAPI.RefundApplicationMapWrapper ref = new NGBSAPI.RefundApplicationMapWrapper();

        System.assertEquals(
            null,
            ref.refundItemGroups,
            'Field refundItemGroups populated incorrectly'
        );
        System.assertEquals(
            null,
            ref.refundTaxItems,
            'Field refundTaxItems populated incorrectly'
        );
        System.assertEquals(
            null,
            ref.transactionId,
            'Field transactionId populated incorrectly'
        );
    }

    @isTest
    private static void testCalculatedRefundItemGroupConstructor() {
        NGBSAPI.CalculatedRefundItemGroup ref = new NGBSAPI.CalculatedRefundItemGroup();

        System.assertEquals(
            null,
            ref.refundItems,
            'Field refundItems populated incorrectly'
        );
    }

    @isTest
    private static void testCalculatedRefundItemConstructor() {
        NGBSAPI.CalculatedRefundItem ref = new NGBSAPI.CalculatedRefundItem();

        System.assertEquals(
            null,
            ref.invoiceId,
            'Field invoiceId populated incorrectly'
        );
        System.assertEquals(
            null,
            ref.itemGroupId,
            'Field itemGroupId populated incorrectly'
        );
        System.assertEquals(
            null,
            ref.amount,
            'Field amount populated incorrectly'
        );
    }

    @isTest
    private static void testCalculatedRefundTaxItemConstructor() {
        NGBSAPI.CalculatedRefundTaxItem calc = new NGBSAPI.CalculatedRefundTaxItem();

        System.assertEquals(
            null,
            calc.itemGroupId,
            'Field itemGroupId should be null'
        );
        System.assertEquals(
            null,
            calc.invoiceId,
            'Field invoiceId should be null'
        );
        System.assertEquals(
            null,
            calc.taxItemId,
            'Field taxItemId should be null'
        );
        System.assertEquals(
            null,
            calc.description,
            'Field description should be null'
        );
        System.assertEquals(
            null,
            calc.amount,
            'Field amount should be null'
        );
        System.assertEquals(
            null,
            calc.initialAmount,
            'Field initialAmount should be null'
        );
    }

    @isTest
    private static void testNGBSResponseConstructor() {
        NGBSAPI.NGBSResponse resp = new NGBSAPI.NGBSResponse('status', 'message');

        System.assertEquals(
            'status',
            resp.status,
            'Field status populated incorrectly'
        );
        System.assertEquals(
            'message',
            resp.message,
            'Field message populated incorrectly'
        );
    }

    @isTest
    private static void testTransactionRefundConstructor() {
        NGBSAPI.TransactionRefund ref = new NGBSAPI.TransactionRefund(null, 'id');

        System.assertEquals(
            null,
            ref.applicationsByInvoice,
            'Field applicationsByInvoice populated incorrectly'
        );
        System.assertEquals(
            'id',
            ref.id,
            'Field id populated incorrectly'
        );
    }

    @isTest
    private static void testRefundInvoiceApplicationConstructor() {
        NGBSAPI.RefundInvoiceApplication ref = new NGBSAPI.RefundInvoiceApplication('groupId', 'itemId', 10);

        System.assertEquals(
            'groupId',
            ref.invoiceItemGroupId,
            'Field invoiceItemGroupId populated incorrectly'
        );
        System.assertEquals(
            'itemId',
            ref.invoiceItemId,
            'Field invoiceItemId populated incorrectly'
        );
        System.assertEquals(
            10,
            ref.amount,
            'Field amount populated incorrectly'
        );
    }

    @isTest
    private static void testRefundTaxInfoPropertiesConstructor() {
        NGBSAPI.RefundTaxInfoProperties ref = new NGBSAPI.RefundTaxInfoProperties('id', 'level');

        System.assertEquals(
            'id',
            ref.taxItemId,
            'Field taxItemId populated incorrectly'
        );
        System.assertEquals(
            'level',
            ref.taxLevel,
            'Field taxLevel populated incorrectly'
        );
    }

    @isTest
    private static void testTaxRefundConstructor() {
        NGBSAPI.NGBSItem item = new NGBSAPI.NGBSItem();
        item.id = 'id';
        item.amount = 10;
        item.description = 'description';
        NGBSAPI.TaxRefund ref = new NGBSAPI.TaxRefund(item);

        System.assertEquals(
            'id',
            ref.taxItemId,
            'Field taxItemId populated incorrectly'
        );
        System.assertEquals(
            'description',
            ref.description,
            'Field description populated incorrectly'
        );
        System.assertEquals(
            10,
            ref.amount,
            'Field amount populated incorrectly'
        );
    }

    @isTest
    private static void testPackageLimitOverrideConstructor() {
        NGBSAPI.PackageLimitOverride over = new NGBSAPI.PackageLimitOverride('code', 10);

        System.assertEquals(
            'code',
            over.code,
            'Field code populated incorrectly'
        );
        System.assertEquals(
            10,
            over.value,
            'Field value populated incorrectly'
        );
    }

    @isTest
    private static void testPackageLimitUpdateConstructor() {
        NGBSAPI.PackageLimitUpdate packLimitUpd = new NGBSAPI.PackageLimitUpdate('code', 10, 5);

        System.assertEquals(
            'code',
            packLimitUpd.packageLimitCode,
            'Field packageLimitCode populated incorrectly'
        );
        System.assertEquals(
            10,
            packLimitUpd.value,
            'Field value populated incorrectly'
        );
        System.assertEquals(
            5,
            packLimitUpd.overrideParam,
            'Field overrideParam populated incorrectly'
        );
    }

    @isTest
    private static void testLBoxLimitOverrideConstructor() {
        NGBSAPI.LBoxLimitOverride over = new NGBSAPI.LBoxLimitOverride(123, null);

        System.assertEquals(
            123,
            over.id,
            'Field id populated incorrectly'
        );
        System.assertEquals(
            null,
            over.lboxLimits,
            'Field lboxLimits populated incorrectly'
        );
    }

    @isTest
    private static void testLBoxLimitBriefConstructor() {
        NGBSAPI.LBoxLimitBrief over = new NGBSAPI.LBoxLimitBrief('type', 10);

        System.assertEquals(
            'type',
            over.type,
            'Field type populated incorrectly'
        );
        System.assertEquals(
            10,
            over.value,
            'Field value populated incorrectly'
        );
    }

    @isTest
    private static void testLBoxLimitConstructor() {
        NGBSAPI.LBoxLimit lim = new NGBSAPI.LBoxLimit('type', 10, true);

        System.assertEquals(
            'type',
            lim.type,
            'Field type populated incorrectly'
        );
        System.assertEquals(
            10,
            lim.value,
            'Field value populated incorrectly'
        );
        System.assert(
            lim.defaultLimit,
            'Field defaultLimit populated incorrectly'
        );
    }

    @isTest
    private static void testLBoxItemConstructor() {
        NGBSAPI.LBoxItem item = new NGBSAPI.LBoxItem(123, 'catalogId', 'description');

        System.assertEquals(
            123,
            item.id,
            'Field id populated incorrectly'
        );
        System.assertEquals(
            'catalogId',
            item.catalogId,
            'Field catalogId populated incorrectly'
        );
        System.assertEquals(
            'description',
            item.description,
            'Field description populated incorrectly'
        );
    }

    @isTest
    private static void testConvertToProductType() {
        NGBSAPI.BillDetailBillInvoiceItemProperties prop = new NGBSAPI.BillDetailBillInvoiceItemProperties(
            'taxItemId', 'taxLevel'
        );
        NGBSAPI.BillDetailBillInvoiceItem billDetailBillInvoiceItem = new NGBSAPI.BillDetailBillInvoiceItem(
            'lineNo', 'licenseId', 'description', 'categoryId', 'billingCodeId',
            'combinedCatalogId', 'itemType', 'itemGroupId', 100, prop
        );

        NGBSAPI.BillDetailBillInvoice billDetailBillInvoice = new NGBSAPI.BillDetailBillInvoice(
            new List<NGBSAPI.BillDetailBillInvoiceItem>{billDetailBillInvoiceItem},
            10, 'type', 'id', null
        );

        Test.startTest();
        List<TransactionsRefundsAPI.ProductItemDTO> result = billDetailBillInvoice.convertToProductItem('ngbsType');
        Test.stopTest();

        System.assertEquals(
            1,
            result.size(),
            'Result list should contain 1 element'
        );
        System.assertEquals(
            'id',
            result[0].billId,
            'Field billId populated incorrectly'
        );
        System.assertEquals(
            'billingCodeId',
            result[0].billingCodeId,
            'Field billingCodeId populated incorrectly'
        );
        System.assertEquals(
            'categoryId',
            result[0].categoryId,
            'Field categoryId populated incorrectly'
        );
        System.assertEquals(
            'type',
            result[0].currencyType,
            'Field currencyType populated incorrectly'
        );
        System.assertEquals(
            'itemGroupId',
            result[0].itemGroupId,
            'Field itemGroupId populated incorrectly'
        );
        System.assertEquals(
            'description',
            result[0].productDescription,
            'Field productDescription populated incorrectly'
        );
        System.assertEquals(
            100,
            result[0].transactionAmount,
            'Field transactionAmount populated incorrectly'
        );
        System.assertEquals(
            'ngbsType',
            result[0].transactionType,
            'Field transactionType populated incorrectly'
        );
        System.assertEquals(
            'categoryId',
            result[0].items[0].categoryId,
            'Field categoryId populated incorrectly'
        );
        System.assertEquals(
            'itemType',
            result[0].items[0].itemType,
            'Field itemType populated incorrectly'
        );
        System.assertEquals(
            100,
            result[0].items[0].transactionAmount,
            'Field transactionAmount populated incorrectly'
        );
        System.assertEquals(
            'ngbsType',
            result[0].items[0].transactionType,
            'Field transactionType populated incorrectly'
        );
    }

    @isTest
    private static void testApplicationsByInvoice() {
        List<NGBSAPI.RefundInvoiceApplication> refAppList = new List<NGBSAPI.RefundInvoiceApplication>{
            new NGBSAPI.RefundInvoiceApplication('invoiceItemGroupId', 'invoiceItemId', 10)
        };

        NGBSAPI.RefundTaxInfoProperties ref = new NGBSAPI.RefundTaxInfoProperties('id', 'level');

        List<NGBSAPI.RefundTaxInfo> refTaxInfoList = new List<NGBSAPI.RefundTaxInfo>{
            new NGBSAPI.RefundTaxInfo('itemGroupId', ref, 15, 'description')
        };

        NGBSAPI.ApplicationsByInvoice appl = new NGBSAPI.ApplicationsByInvoice(
            'invoiceId', refAppList, refTaxInfoList
        );

        Map<String, Decimal> refundsMap = new Map<String, Decimal> {
            'invoiceId:invoiceItemGroupId::' => 1,
            'invoiceId:itemGroupId:description:' => 2
        };
        Test.startTest();
        Map<String, Decimal> resultMap = appl.updateRefundsMap(refundsMap);
        Test.stopTest();

        System.assertEquals(
            1,
            resultMap.get('invoiceId:invoiceItemGroupId::'),
            'Result map populated incorrectly'
        );
        System.assertEquals(
            10,
            resultMap.get('invoiceId:invoiceItemGroupId:null:null'),
            'Result map populated incorrectly'
        );
        System.assertEquals(
            2,
            resultMap.get('invoiceId:itemGroupId:description:'),
            'Result map populated incorrectly'
        );
        System.assertEquals(
            15,
            resultMap.get('invoiceId:itemGroupId:description:null'),
            'Result map populated incorrectly'
        );
    }

    @isTest
    private static void testTransactionRefundResponse() {
        List<NGBSAPI.RefundInvoiceApplication> refAppList = new List<NGBSAPI.RefundInvoiceApplication>{
            new NGBSAPI.RefundInvoiceApplication('invoiceItemGroupId', 'invoiceItemId', 10)
        };

        NGBSAPI.RefundTaxInfoProperties ref = new NGBSAPI.RefundTaxInfoProperties('id', 'level');

        List<NGBSAPI.RefundTaxInfo> refTaxInfoList = new List<NGBSAPI.RefundTaxInfo>{
            new NGBSAPI.RefundTaxInfo('itemGroupId', ref, 15, 'description')
        };

        NGBSAPI.ApplicationsByInvoice appl = new NGBSAPI.ApplicationsByInvoice(
            'invoiceId', refAppList, refTaxInfoList
        );

        NGBSAPI.TransactionRefund trRef = new NGBSAPI.TransactionRefund(
            new List<NGBSAPI.ApplicationsByInvoice>{appl}, 'id'
        );

        NGBSAPI.TransactionRefundResponse trRefundResp = new NGBSAPI.TransactionRefundResponse(
            new List<NGBSAPI.TransactionRefund>{trRef}
        );

        Test.startTest();
        Map<String, Decimal> resultMap = trRefundResp.getNGBSRefundsMap();
        Test.stopTest();

        System.assertEquals(
            10,
            resultMap.get('invoiceId:invoiceItemGroupId:null:null'),
            'Result map populated incorrectly'
        );
        System.assertEquals(
            15,
            resultMap.get('invoiceId:itemGroupId:description:null'),
            'Result map populated incorrectly'
        );
    }

    @isTest
    private static void testRefundTaxInfo() {
        NGBSAPI.RefundTaxInfoProperties ref = new NGBSAPI.RefundTaxInfoProperties('id', 'level');

        NGBSAPI.RefundTaxInfo refTaxInfo = new NGBSAPI.RefundTaxInfo('itemGroupId', ref, 15, 'description');

        System.assertEquals(
            'id',
            refTaxInfo.getTaxItemId(),
            'Method should return correct value'
        );
        System.assertEquals(
            'level',
            refTaxInfo.getTaxLevel(),
            'Method should return correct value'
        );
    }

    @isTest
    private static void testRefundApplicationMap() {
        NGBSAPI.RefundApplicationMap ref = new NGBSAPI.RefundApplicationMap();

        System.assert(
            ref.applications.isEmpty(),
            'Map applications should be empty'
        );
        System.assert(
            ref.taxes.isEmpty(),
            'Map taxes should be empty'
        );
    }

    @isTest
    private static void testRefundDestinationDefaultConstructor() {
        NGBSAPI.RefundDestination ref = new NGBSAPI.RefundDestination();

        System.assertEquals(
            'AccountCredit',
            ref.type,
            'Field type populated incorrectly'
        );
    }

    @isTest
    private static void testRefundDestinationConstructor() {
        NGBSAPI.RefundDestination ref = new NGBSAPI.RefundDestination('CreditCard');

        System.assertEquals(
            'OriginalPaymentMethod',
            ref.type,
            'Field type populated incorrectly'
        );
    }

    @isTest
    private static void testInvoicePaymentMethodDefaultConstructor() {
        NGBSAPI.Address add = new NGBSAPI.Address();
        NGBSAPI.CreditCardPaymentMethod ccPayment = new NGBSAPI.CreditCardPaymentMethod();

        NGBSAPI.InvoicePaymentMethod paymentMethod = new NGBSAPI.InvoicePaymentMethod(ccPayment);

        System.assertEquals(
            0,
            paymentMethod.terms,
            'Field terms populated incorrectly'
        );
    }

    @isTest
    private static void testInvoicePaymentMethodConstructor() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'testAcc',
                    Account.BillingStreet => '443 Kearney Frontage',
                    Account.BillingCity => 'Fresno',
                    Account.BillingState => 'usa',
                    Account.BillingPostalCode => '93706',
                    Account.BillingCountry =>'United States'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();
        AccountContactRole primaryAcc = (AccountContactRole) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRolesByAccountIds(new List<Object>{testAcc.Id})
            .executeQuery()
            .get(0);

        List<Object> bindings = new List<Object>{new Set<Id>{testAcc.Id}};
        testAcc = (Account) new AccountSelector()
            .selectAccountsForApproval(bindings)
            .executeQuery()
            .get(0);

        Test.startTest();
        NGBSAPI.InvoicePaymentMethod paymentMethod = new NGBSAPI.InvoicePaymentMethod(testAcc, primaryAcc);
        Test.stopTest();

        System.assertEquals(
            'Fresno',
            paymentMethod.address.city,
            'Field city populate incorrectly'
        );
        System.assertEquals(
            'United States',
            paymentMethod.address.country,
            'Field country populate incorrectly'
        );
        System.assertEquals(
            'Test1',
            paymentMethod.address.firstName,
            'Field firstName populate incorrectly'
        );
        System.assertEquals(
            'Test1',
            paymentMethod.address.lastName,
            'Field lastName populate incorrectly'
        );
        System.assertEquals(
            null,
            paymentMethod.address.phone,
            'Field phone populate incorrectly'
        );
        System.assertEquals(
            'usa',
            paymentMethod.address.state,
            'Field state populate incorrectly'
        );
        System.assertEquals(
            '443 Kearney Frontage',
            paymentMethod.address.street1,
            'Field street1 populate incorrectly'
        );
        System.assertEquals(
            '93706',
            paymentMethod.address.zip,
            'Field zip populate incorrectly'
        );
        System.assert(
            paymentMethod.isValid(),
            'Method should return true'
        );
    }

    @isTest
    private static void testGetRefundApplicationMapShouldThrowException() {
        Map<String, Object> jsonMapping = new Map<String, Object>();
        Boolean res = false;
        try {
            NGBSAPI.getRefundApplicationMap(jsonMapping);
        } catch (AuraHandledException ex) {
            res = ex.getMessage().contains('unexpected JSON received, cannot parse refunds map.');
        }

        System.assert(
            res,
            'Exception should be thrown'
        );
    }

    @isTest
    private static void testGetPaymentMethodFromBillingAccount() {
        String accountIdString = '123';

        Test.startTest();
        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[{"invoiceInfo":{"terms":0,"address":' + BillingHttpRequestMock.ADDRESS_STRING.replace('"lastName":"Murrey"', '"lastName":"AnyOtherName"') + '},"creditCardInfo":{"terms":0,"address":' + BillingHttpRequestMock.ADDRESS_STRING + '}, "default":true}]';
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        NGBSAPI.PaymentMethod paymentMethod = NGBSAPI.getDefaultPaymentMethodFromBillingAccount(accountIdString);

        Test.stopTest();

        System.assertNotEquals(paymentMethod, null, 'Payment method not loaded');
        System.assertNotEquals(paymentMethod.invoiceInfo, null, 'invoiceInfo not loaded in payment method');
        System.assertEquals(paymentMethod.invoiceInfo.terms, 0, 'invoiceInfo loaded incorrect');
        System.assertNotEquals(paymentMethod.creditCardInfo, null, 'creditCardInfo not loaded in payment method');
        System.assertNotEquals(paymentMethod.creditCardInfo.address, null, 'creditCardInfo loaded incorrect');
    }

    @isTest
    private static void testGetPaymentMethodFromBillingAccountDefault() {
        String accountIdString = '123';
        Test.startTest();
        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[{"id":"1","default":false,"creditCardInfo":{"cardType":"Visa"}},{"id":"2","default":true,"invoiceInfo":{"terms":1}}]';
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);
        NGBSAPI.PaymentMethod paymentMethod = NGBSAPI.getDefaultPaymentMethodFromBillingAccount(accountIdString);
        Test.stopTest();

        System.assertNotEquals(null, paymentMethod.invoiceInfo, 'should return only default payment method');
    }

    @isTest
    static void testReroutingToCommercialEndpoints() {

        Test.startTest();
        NGBSAPI.initNgbsEndpoints(false);
        Test.stopTest();

        String commercialAccountManagerEndpoint = NGBS_Settings__c.getInstance().BaseEndpoint__c
            + NGBS_Settings__c.getInstance().AccountManagerPath__c + '/account';

        System.assertEquals(
            NGBSAPI.NGBS_ACCOUNT_MANAGER,
            commercialAccountManagerEndpoint,
            'Init endpoints for Commercial Settings'
        );
    }

    @isTest
    static void testReroutingToFedRampEndpoints() {

        Test.startTest();
        NGBSAPI.initNgbsEndpoints(true);
        Test.stopTest();

        String fedRampAccountManagerEndpoint = NGBS_Settings_FedRamp__c.getInstance().BaseEndpoint__c
            + NGBS_Settings_FedRamp__c.getInstance().AccountManagerPath__c + '/account';

        System.assertEquals(
            NGBSAPI.NGBS_ACCOUNT_MANAGER,
            fedRampAccountManagerEndpoint,
            'Re-init endpoints for FedRamp Settings'
        );
    }

    @isTest
    private static void testGetAllLicensesFromBillingAccount() {
        String accountIdString = '123';
        String packageIdString = '456';

        Test.startTest();

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        BillingWrappers.BillingInfoLicenses allLicenses = NGBSAPI.getAllLicenses(accountIdString, packageIdString, 'LC_EES_489');

        Test.stopTest();

        System.assertNotEquals(allLicenses, null, 'Licenses must be returned');
    }

    @isTest
    private static void testRequestContractsFromBilling() {
        String accountIdString = '123';
        String packageIdString = '456';

        Test.startTest();

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        List<BillingWrappers.BillingContract> contracts = NGBSAPI.requestContractsFromBilling(accountIdString, packageIdString);

        Test.stopTest();

        System.assertEquals(true, !contracts.isEmpty(), 'Contract must be returned');
    }

    @isTest
    private static void testGetNGBSAccountFromBilling() {
        String accountIdString = '123';

        Test.startTest();
            BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
            Test.setMock(HttpCalloutMock.class, tstMock);
            BillingWrappers.NGBSAccount ngbsAcc = NGBSAPI.getNGBSAccount(accountIdString);
            BillingWrappers.NGBSAccountPackage ngbsPackage = ngbsAcc.getPackageById('9710001');
        Test.stopTest();

        System.assertEquals('9710001', ngbsPackage.id, 'NGBS Package id must be 9710001');
        System.assertEquals('1', ngbsPackage.version, 'NGBS Package version must be 1');
        System.assertEquals('2', ngbsPackage.catalogId, 'NGBS Package catalogId must be 2');
    }

    @isTest
    private static void testGetLicensesCountersFromAccount() {
        String accountIdString = '123';
        String packageIdString = '456';

        BillingWrappers.LicensesRequestBody body1 = new BillingWrappers.LicensesRequestBody('LC_DL_75');
        BillingWrappers.LicensesRequestBody body2 = new BillingWrappers.LicensesRequestBody('LC_DL-UNL_50');

        Test.startTest();

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        Response res = NGBSAPI.getLicenseCounters(accountIdString,packageIdString,new BillingWrappers.LicensesRequestBody[]{body1, body2});
        Test.stopTest();
        System.assertEquals(true, res.isSuccess(), 'Response must be with success status');
        System.assertEquals(true, res.data.get('licenseCounter') != null, 'License counter response must have values');
    }

    @isTest
    private static void testGetSearchPackages() {
        BillingWrappers.SearchPackagesParams params = new BillingWrappers.SearchPackagesParams();
        params.businessIdentityIds = new List<Integer>{4};
        params.currencyIds = new List<String>{'USD'};
        params.isVersioned = true;
        params.productName = OpportunityHelper.TIER_RC_CONTACT_CENTER;

        Test.startTest();

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        List<BillingWrappers.NGBSPackage> bPackages = NGBSAPI.getSearchPackages(params);
        Test.stopTest();
        Assert.isTrue(!bPackages.isEmpty(), 'There are no Conctact Center packages for RingCentral bi in NGBS');
    }

    @isTest
    private static void testGetNGBSAccountLicenseInfoCategories() {
        String accountIdString = '123';
        String packageIdString = '456';

        List<String> categories = new List<String>{'DL', 'DL-UNL'};

        Test.startTest();

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        List<BillingWrappers.NGBSLicense> ngbsLicenses = NGBSAPI.getNGBSAccountLicenseInfoCategories(accountIdString,packageIdString,categories);
        Test.stopTest();

        System.assertEquals(true, !ngbsLicenses.isEmpty(), 'List must have values');
    }

    @isTest
    private static void testUpdateAccountPaymentMethodInvoice() {

        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.BillingStreet => 'street',
                Account.BillingState => 'state',
                Account.BillingPostalCode => '123',
                Account.BillingCountry => 'USA',
                Account.BillingCity => 'City',
                Account.Phone => '123467445'
            })
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => billingAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => billingAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();
        Test.startTest();

        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[{"creditCardInfo":{"terms":0,"address":' + BillingHttpRequestMock.ADDRESS_STRING + '}, "invoiceInfo":null, "default":true}]';
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        HttpResponse paymentMethodResp = NGBSAPI.updateAccountPaymentMethod(billingAcc, testAccountContactRole, null, null, null);
        Boolean isSuccessResponse = paymentMethodResp != null && paymentMethodResp.getStatusCode() == 200;
        Test.stopTest();

        System.assertEquals(true, isSuccessResponse, 'Invoice payment method has been updated');
    }


    @isTest
    private static void testUpdateAccountPaymentMethodInvoiceWhenNoPaymentMethodInNGBS() {
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.BillingStreet => 'street',
                Account.BillingState => 'state',
                Account.BillingPostalCode => '123',
                Account.BillingCountry => 'USA',
                Account.BillingCity => 'City',
                Account.Phone => '123467445'
            })
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => billingAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => billingAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();
        AccountContactRole primaryAcc = (AccountContactRole) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRolesByAccountIds(new List<Object>{billingAcc.Id})
            .executeQuery()
            .get(0);

        Test.startTest();
        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[]';
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        HttpResponse paymentMethodResp = NGBSAPI.updateAccountPaymentMethod(billingAcc, primaryAcc, null, null, null);
        Boolean isSuccessResponse = paymentMethodResp != null && paymentMethodResp.getStatusCode() == 200;
        Test.stopTest();

        System.assertEquals(true, isSuccessResponse, 'Invoice payment method has been updated');
    }

    @isTest
    private static void testUpdateAccountPaymentMethodInvoiceOnBehalf() {
        Account parentPartnerAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '123',
                Account.NGBS_Partner_ID__c => ValueProviderBuilder.provideUniqueNumber(),
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
            })
            .create()
            .getRecord();
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '123',
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF,
                Account.Partner_Account__c => parentPartnerAcc.Id,
                Account.BillingStreet => 'street',
                Account.BillingState => 'state',
                Account.BillingPostalCode => '123',
                Account.BillingCountry => 'USA',
                Account.BillingCity => 'City',
                Account.Phone => '123467445'
            })
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => billingAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => billingAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();
        AccountContactRole primaryAcr = (AccountContactRole) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRolesByAccountIds(new List<Object>{billingAcc.Id})
            .executeQuery()
            .get(0);
        Test.startTest();

        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[]';
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        HttpResponse paymentMethodResp = NGBSAPI.updateAccountPaymentMethod(billingAcc, primaryAcr, parentPartnerAcc, null, null);
        Boolean isSuccessResponse = paymentMethodResp != null && paymentMethodResp.getStatusCode() == 200;
        Test.stopTest();

        System.assertEquals(true, isSuccessResponse, 'Invoice On Behalf payment method has been updated');
    }

    @isTest
    private static void testUpdateAccountPaymentMethodWholesaleWithSamePartnerId() {
        Account parentPartnerAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '123',
                Account.NGBS_Partner_ID__c => 12345,
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_WHOLESALE
            })
            .create()
            .getRecord();
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '123',
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_WHOLESALE,
                Account.NGBS_Partner_ID__c => ValueProviderBuilder.provideUniqueNumber(),
                Account.Partner_Account__c => parentPartnerAcc.Id,
                Account.BillingStreet => 'street',
                Account.BillingState => 'state',
                Account.BillingPostalCode => '123',
                Account.BillingCountry => 'USA',
                Account.BillingCity => 'City',
                Account.Phone => '123467445'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test1',
                Contact.LastName => 'Test1',
                Contact.AccountId => billingAcc.Id,
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test11',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => testContact.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote primaryQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_WHOLESALE
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
                Entitlement__c.Account__c => billingAcc.Id,
                Entitlement__c.Quote__c => primaryQuote.Id,
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
                QuoteLineItem.QuoteId => primaryQuote.Id,
                QuoteLineItem.PricebookEntryId => standardPrice.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Entitlement__c => ent.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => billingAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();

        AccountContactRole primaryAcr = (AccountContactRole) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRolesByAccountIds(new List<Object>{billingAcc.Id})
            .executeQuery()
            .get(0);

            Test.startTest();

            BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = WHOLESALE_PAYMENT_METHOD_RESPONSE;
            BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
            Test.setMock(HttpCalloutMock.class, tstMock);
            HttpResponse paymentMethodResp = NGBSAPI.updateAccountPaymentMethod(billingAcc, primaryAcr, parentPartnerAcc, primaryQuote, null);
            Boolean isSuccessResponse = paymentMethodResp != null && paymentMethodResp.getStatusCode() == 200;

            Test.stopTest();

            System.assertEquals(true, isSuccessResponse, 'Wholesale payment method has been updated');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testUpdateAccountPaymentMethodNoNeedToUpdate() {
        Account parentPartnerAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '123',
                Account.NGBS_Partner_ID__c => 12345,
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
            })
            .create()
            .getRecord();
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '123',
                Account.NGBS_Partner_ID__c => ValueProviderBuilder.provideUniqueNumber(),
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF,
                Account.Partner_Account__c => parentPartnerAcc.Id,
                Account.BillingStreet => 'street',
                Account.BillingState => 'state',
                Account.BillingPostalCode => '123',
                Account.BillingCountry => 'USA',
                Account.BillingCity => 'City',
                Account.Phone => '123467445'
            })
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => billingAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => billingAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();
        AccountContactRole primaryAcr = (AccountContactRole) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRolesByAccountIds(new List<Object>{billingAcc.Id})
            .executeQuery()
            .get(0);
        /*
        // TODO: Figure out why JSON.serialize doesn't work
        Test.startTest();
        PaymentMethod currentSalesforcePaymentMethod = NGBSAPI.getInvoiceOnBehalfPaymentInfo(billingAcc, primaryAcr);
        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = JSON.serialize(currentSalesforcePaymentMethod);
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        HttpResponse paymentMethodResp = NGBSAPI.updateAccountPaymentMethod(billingAcc, primaryAcr, parentPartnerAcc, null, null);
        Boolean isSuccessResponse = paymentMethodResp == null;
        Test.stopTest();

        System.assertEquals(true, isSuccessResponse, 'Should not update NGBS when there are no changes in salesforce');
        */
    }


    @isTest
    private static void testUpdateAccountPaymentMethodNoNeedToUpdateInvoice() {

        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.BillingStreet => 'street',
                Account.BillingState => 'state',
                Account.BillingPostalCode => '123',
                Account.BillingCountry => 'USA',
                Account.BillingCity => 'City',
                Account.Phone => '123467445'
            })
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => billingAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => billingAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();
        Test.startTest();
        AccountContactRole primaryAcr = (AccountContactRole) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRolesByAccountIds(new List<Object>{billingAcc.Id})
            .executeQuery()
            .get(0);

        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[{"invoiceInfo":{"terms":999,"address":' + BillingHttpRequestMock.ADDRESS_STRING.replace('"lastName":"Murrey"', '"lastName":"AnyOtherName"') + '}, "creditCardInfo":null, "default":true}]';
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        HttpResponse paymentMethodResp = NGBSAPI.updateAccountPaymentMethod(billingAcc, primaryAcr, null, null, null);
        Boolean isSuccessResponse = paymentMethodResp == null;
        Test.stopTest();

        System.assertEquals(true, isSuccessResponse, 'Should not update NGBS when there are ANY info in invoiceInfo attribute');
    }

    @isTest
    private static void testUpdateAccountPaymentMethodInvoiceOnBehalfNewPartnerID() {
        Account parentPartnerAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '123',
                Account.NGBS_Partner_ID__c => 12345,
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
            })
            .create()
            .getRecord();
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '123',
                Account.NGBS_Partner_ID__c => ValueProviderBuilder.provideUniqueNumber(),
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF,
                Account.Partner_Account__c => parentPartnerAcc.Id,
                Account.BillingStreet => 'street',
                Account.BillingState => 'state',
                Account.BillingPostalCode => '123',
                Account.BillingCountry => 'USA',
                Account.BillingCity => 'City',
                Account.Phone => '123467445'
            })
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => billingAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => billingAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();
        AccountContactRole primaryAcr = (AccountContactRole) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRolesByAccountIds(new List<Object>{billingAcc.Id})
            .executeQuery()
            .get(0);
        Test.startTest();

        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[{"nickname":"InvoiceOnBehalf","isDefault":true,"invoiceOnBehalfInfo":{"partnerId":88888,"address":{"zip":"123","street2":null,"street1":"street","state":"state","phone":"123467445","lastName":"Test1","label":null,"firstName":"Test1","county":null,"country":"USA","city":"City"}},"invoiceInfo":null,"id":null,"creditCardInfo":null}]';
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        HttpResponse paymentMethodResp = NGBSAPI.updateAccountPaymentMethod(billingAcc, primaryAcr, parentPartnerAcc, null, null);
        Boolean isSuccessResponse = paymentMethodResp != null && paymentMethodResp.getStatusCode() == 200;
        Test.stopTest();

        System.assertEquals(true, isSuccessResponse, 'Partner ID was updated in existing IoB account');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testUpdateAccountPackageLimitsFromAccount() {

        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Monthly_Credit_Limit__c => 15000
            })
            .build()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => billingAcc.Id,
                Package__c.Account_Package_Id__c => billingAcc.Billing_ID__c
            })
            .build()
            .getRecord();

        Test.startTest();

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        HttpResponse limitOverrideResp = NGBSAPI.updateAccountPackageLimits(billingAcc, pack);
        Boolean isSuccessResponse = limitOverrideResp != null && limitOverrideResp.getStatusCode() == 200;
        Test.stopTest();

        Assert.isTrue(isSuccessResponse, 'Package limits have been updated');
    }

    @isTest
    private static void testUpdateAccountPackageLimits() {

        Decimal monthlyCreditLimit = 50000;
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .build()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => billingAcc.Id,
                Package__c.Account_Package_Id__c => billingAcc.Billing_ID__c
            })
            .build()
            .getRecord();

        Test.startTest();

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        HttpResponse limitOverrideResp = NGBSAPI.updateAccountPackageLimits(billingAcc, pack, monthlyCreditLimit);
        Boolean isSuccessResponse = limitOverrideResp != null && limitOverrideResp.getStatusCode() == 200;
        Test.stopTest();

        Assert.isTrue(isSuccessResponse, 'Package limits have been updated');
    }

    @isTest
    private static void testCreateTransactionHistory() {

        NGBSAPI.NGBSTransaction ngbsTr = new NGBSAPI.NGBSTransaction();
        ngbsTr.id = 'testTr';
        ngbsTr.paymentType = 'Invoice';

        NGBSAPI.NGBSItemGroup ngbsIG = new NGBSAPI.NGBSItemGroup();
        ngbsIG.id = 'testIG';
        ngbsIG.invoiceId = 'testInvoiceId';

        ngbsTr.itemGroups = new NGBSAPI.NGBSItemGroup[]{ngbsIG};

        NGBSAPI.NGBSItem ngbsItem = new NGBSAPI.NGBSItem();
        ngbsItem.id = 'testItemId';
        ngbsItem.amount = 64.36;

        ngbsIG.items = new NGBSAPI.NGBSItem[]{ngbsItem};

        Test.startTest();

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType).build().getRecord();
        Transaction_History__c trHistory = NGBSAPI.createTransactionHistory(ngbsTr, new Response(), testApproval.Id);

        Test.stopTest();

        System.assertEquals(64.36, trHistory.RefundAmount__c, 'Transaction history refund amount must be equals 64.36');
        System.assertEquals(null, trHistory.Id, 'Transaction history Id must be returned');
        System.assertEquals(ngbsTr.id, trHistory.TransactionId__c, 'Transaction history Id must be equals NGBSTransaction Id');
        System.assertEquals(ngbsTr.id, trHistory.Name, 'Transaction history name must be equals NGBSTransaction Id');
        System.assertEquals('success', trHistory.Status__c, 'Transaction history status must be equals "success"');
        System.assertEquals(NGBSAPI.TRANSACTION_TYPE_NGBS, trHistory.Type__c, 'Transaction history Status must be equals "success"');
    }

    @isTest
    private static void testGetShippingLicenses() {

        Test.startTest();
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        Map<String,BillingWrappers.NGBSShippingLicense> shippingLicenseMap = NGBSAPI.getShippingLicenses('18', '1');
        Test.stopTest();

        System.assertEquals(3, shippingLicenseMap.size(), 'Map must have three records');
    }

    private static void testUpdateAccountPaymentContact() {

        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .build()
            .getRecord();

        Contact payableContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => billingAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Test.startTest();

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        HttpResponse paymentContactResp = NGBSAPI.updateAccountPaymentContact(billingAcc, payableContact);
        Boolean ngbsSuccess = paymentContactResp != null && paymentContactResp.getStatusCode() == 200;
        Test.stopTest();

        System.assertEquals(true, ngbsSuccess, 'Payment Contact has been updated');
    }

    @isTest
    private static void testGetIntendedPaymentMethodWithEmptyBillingId() {
        Boolean exceptionThrown = false;
        try {
            String intendedPaymentMethod = NGBSAPI.getIntendedPaymentMethod(null);
            System.assert(false);
        } catch (Exception ex) {
            exceptionThrown = true;

            Boolean expectedExceptionThrown = ex.getMessage().contains('BillingId is required');
            System.AssertEquals(true, expectedExceptionThrown, ex.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'expected exception should be thrown');
    }

    @isTest
    private static void testGetIntendedPaymentMethod() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.body = '{"intendedPaymentMethod":"CreditCard"}';
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            String intendedPaymentMethod = NGBSAPI.getIntendedPaymentMethod('12345');
            System.assertEquals(
                'CreditCard',
                intendedPaymentMethod,
                'should return intended payment method from API as String'
            );
        Test.stopTest();
    }

    @isTest
    private static void testGetAccountPackageLimits() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.body = MONTHLY_AMOUNT_LIMIT_RESPONSE;
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        Account accountInvoiceWholesaleEB = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.Partner_ID__c => 'anyPartnerId',
                Account.Billing_ID__c => '123456789',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_WHOLESALE
            })
            .create()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => accountInvoiceWholesaleEB.Id,
                Package__c.Enterprise_Account_ID__c => accountInvoiceWholesaleEB.Id,
                Package__c.Account_Package_Id__c => accountInvoiceWholesaleEB.Billing_ID__c
            })
            .create()
            .getRecord();

        Test.startTest();
            Decimal accountPackageLimits = NGBSAPI.getAccountPackageLimits(accountInvoiceWholesaleEB.Id, pack.Id)[0].value;
            System.assertEquals(33333, accountPackageLimits);
        Test.stopTest();
    }


    // @isTest
    // private static void testGetAccountPackageLimitsWithInvalidParameters() {
    //     Boolean exceptionThrown = false;

    //     Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             Account.Name => 'Test account',
    //             Account.Partner_ID__c => 'anyPartnerId',
    //             Account.Billing_ID__c => '',
    //             Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_WHOLESALE
    //         })
    //         .create()
    //         .getRecord();

    //     Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
    //         .setFields(new Map<SObjectField, Object> {
    //             Package__c.Account__c => testAcc.Id,
    //             Package__c.Account_Package_Id__c => ''
    //         })
    //         .create()
    //         .getRecord();

    //     try {
    //         Decimal accountPackageLimits = NGBSAPI.getAccountPackageLimits(testAcc.Id, pack.Id)[0].value;
    //         System.assert(false);
    //     } catch (Exception ex) {
    //         exceptionThrown = true;

    //         Boolean expectedExceptionThrown = ex.getMessage().contains('Billing Id is missed on the Acount');
    //         System.AssertEquals(true, expectedExceptionThrown, ex.getMessage());
    //     }
    //     System.assertEquals(true, exceptionThrown, 'expected exception should be thrown');

    //     testAcc.Billing_ID__c = '12345';
    //     update testAcc;

    //     try {
    //         Decimal accountPackageLimits = NGBSAPI.getAccountPackageLimits(testAcc.Id, pack.Id)[0].value;
    //         System.assert(false);
    //     } catch (Exception ex) {
    //         exceptionThrown = true;

    //         Boolean expectedExceptionThrown = ex.getMessage().contains('No packages exists for Account');
    //         System.AssertEquals(true, expectedExceptionThrown, ex.getMessage());
    //     }
    //     System.assertEquals(true, exceptionThrown, 'expected exception should be thrown');
    // }

    @isTest
    private static void testSetIntendedPaymentMethodWithInvalidParameters() {
        Boolean exceptionThrown = false;
        try {
            NGBSAPI.setIntendedPaymentMethod(null, null);
            System.assert(false);
        } catch (Exception ex) {
            exceptionThrown = true;

            Boolean expectedExceptionThrown = ex.getMessage().contains('BillingId is required');
            System.AssertEquals(true, expectedExceptionThrown, ex.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'expected exception should be thrown');


        try {
            NGBSAPI.setIntendedPaymentMethod('12345', 'some_invalid_payment_method');
            System.assert(false);
        } catch (Exception ex) {
            exceptionThrown = true;

            Boolean expectedExceptionThrown = ex.getMessage().contains('Intended payment method "some_invalid_payment_method" is not available');
            System.AssertEquals(true, expectedExceptionThrown, ex.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'expected exception should be thrown');
    }

    @isTest
    private static void testSetIntendedPaymentMethod() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.body = '';
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            System.assertEquals(
                true,
                NGBSAPI.setIntendedPaymentMethod('12345', 'DirectDebit'),
                'should return true if intended payment method successfully set on billing account'
            );
        Test.stopTest();
    }

    @isTest
    private static void testUpdatePaymentLimitsWithInvalidParams() {
        Boolean exceptionThrown = false;
        try {
            NGBSAPI.updatePaymentLimits(null, null, null);
            System.assert(false);
        } catch (Exception ex) {
            exceptionThrown = true;

            Boolean expectedExceptionThrown = ex.getMessage().contains('BillingId is required');
            System.AssertEquals(true, expectedExceptionThrown, ex.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'expected exception should be thrown');


        try {
            NGBSAPI.updatePaymentLimits('12345', null, null);
            System.assert(false);
        } catch (Exception ex) {
            exceptionThrown = true;

            Boolean expectedExceptionThrown = ex.getMessage().contains('PackageId is required');
            System.AssertEquals(true, expectedExceptionThrown, ex.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'expected exception should be thrown');
    }

    @isTest
    private static void testUpdatePaymentLimits() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.body = '';
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            System.assertEquals(
                true,
                NGBSAPI.updatePaymentLimits('12345', '1', 10),
                'should return true if payment limits successfully updated on billing account'
            );
        Test.stopTest();
    }

    @isTest
    private static void testGetBillingAccountPaymentMethodWithEmptyBillingId() {
        Boolean exceptionThrown = false;
        try {
            String intendedPaymentMethod = NGBSAPI.getBillingAccountPaymentMethod(null);
            System.assert(false);
        } catch (Exception ex) {
            exceptionThrown = true;

            Boolean expectedExceptionThrown = ex.getMessage().contains('BillingId is required');
            System.AssertEquals(true, expectedExceptionThrown, ex.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'expected exception should be thrown');
    }

    @isTest
    private static void testGetBillingAccountPaymentMethodDirectDebit() {
        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[{"id":"1","default":false,"creditCardInfo":{"cardType":"Visa"}},{"id":"2","default":true,"directDebitInfo":{"token":"testToken"}}]';
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            System.assertEquals(
                QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT,
                NGBSAPI.getBillingAccountPaymentMethod('12345'),
                'should return default(with property "default":true) payment method from billing'
            );
        Test.stopTest();
    }

    @isTest
    private static void testGetBillingAccountPaymentMethodCreditCard() {
        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[{"id":"1","default":true,"creditCardInfo":{"cardType":"Visa"}},{"id":"2","default":false,"directDebitInfo":{"token":"testToken"}}]';
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            System.assertEquals(
                QuoteHelper.PAYMENT_METHOD_CREDIT_CARD,
                NGBSAPI.getBillingAccountPaymentMethod('12345'),
                'should return default(with property "default":true) payment method from billing'
            );
        Test.stopTest();
    }

    @isTest
    private static void testGetBillingAccountPaymentMethodInvoice() {
        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[{"id":"1","default":false,"creditCardInfo":{"cardType":"Visa"}},{"id":"2","default":true,"invoiceInfo":{"terms":1}}]';
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            System.assertEquals(
                QuoteHelper.PAYMENT_METHOD_INVOICE,
                NGBSAPI.getBillingAccountPaymentMethod('12345'),
                'should return default(with property "default":true) payment method from billing'
            );
        Test.stopTest();
    }

    @isTest
    private static void testGetPackageLimits() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            Response resp = NGBSAPI.getPackageLimits('123', '456');
        Test.stopTest();

        List<BillingWrappers.GlobalPackageLimits> limits = (List<BillingWrappers.GlobalPackageLimits>) resp.data.get('packageLimits');
        System.assertEquals(1, limits.size(), 'Failed to get package limits');
        System.assertEquals('300000', limits[0].value, 'Wrong limit value was retrieved');
    }

    @isTest
    private static void testGetPaymentMethodTypeForBillingAccount() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
        System.assertEquals(
            QuoteHelper.PAYMENT_METHOD_INVOICE,
            NGBSAPI.getPaymentMethodType('12345'),
            'should return current payment method type Invoice'
        );
        Test.stopTest();
    }

    @IsTest
    private static void testUpdatePackageConsolidationSettings() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);
        String settings = '{"billingAlignmentEnabled":true,"invoiceConsolidationEnabled":true}';
        Test.startTest();
            HttpResponse resp = NGBSAPI.updatePackageConsolidationSettings('123', settings);
        Test.stopTest();
        System.assertEquals(200, resp.getStatusCode(), 'should return 200 if package consolidation settings successfully updated');
        System.assertEquals(true, resp.getBody().contains('"billingAlignmentEnabled":true'), 'should return true if billing alignment is enabled');
        System.assertEquals(true, resp.getBody().contains('"invoiceConsolidationEnabled":true'), 'should return true if invoice consolidation is enabled');
    }

    @IsTest
    private static void testGetPackageConsolidationSettings() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);
        Test.startTest();
            BillingWrappers.PackageConsolidationSettings result = NGBSAPI.getPackageConsolidationSettings('123');
        Test.stopTest();
        System.assertEquals(false, result.billingAlignmentEnabled, 'should return false if billing alignment is disabled');
        System.assertEquals(false, result.invoiceConsolidationEnabled, 'should return false if invoice consolidation is disabled');
    }

    @isTest
    private static void testGetDiscountTemplateGroupEndpointError() {
        Test.startTest();
            try {
                NGBSAPI.settings.BaseEndpoint = null;
                NGBSAPI.settings.AccountManagerPath = null;
                System.debug('SETTINGS: ' + NGBSAPI.settings.BaseEndpoint + NGBSAPI.settings.AccountManagerPath);
                NGBSAPI.getDiscountTemplateGroupEndpoint('test', 'test');
                Assert.fail('An error was thrown');
            } catch (Exception ex) {
                Assert.areEqual('Endpoint for Billing in NGBS_Settings__c is not set', ex.getMessage(), 'Messages should be similar');
            }
        Test.stopTest();
    }

    @isTest
    private static void testGetDiscountTemplateGroupEndpoint() {
        Test.startTest();
            String endpoint = NGBSAPI.getDiscountTemplateGroupEndpoint('test', 'test');
        Test.stopTest();

        Assert.areEqual('https://testapi/restapi/account-manager/v1.0/account/test/package/test/discountTemplateGroup', endpoint, 'Endpoints should be similar');
    }

    @isTest
    static void testGetContractCancellationEndpointMPLite() {
        final String BILLING_ID = 'billingId';
        final String PACKAGE_ID = 'packageId';
        final String CONTRACT_ID = 'contractId';

        Test.startTest();
            String result = NGBSAPI.getContractCancellationEndpointMPLite(BILLING_ID, PACKAGE_ID, CONTRACT_ID);
        Test.stopTest();

        String expectedEndpoint = String.format(
            NGBSAPI.NGBS_CONTRACT_CANCELLATION,
            new List<String> {BILLING_ID, PACKAGE_ID, CONTRACT_ID}
        );
        Assert.areEqual(expectedEndpoint, result, 'Wrong endpoint was returned');
    }

    @isTest
    static void testGetContractCancellationEndpointMPUB() {
        final String BILLING_ID = 'billingId';
        final String CONTRACT_ID = 'contractId';

        Test.startTest();
            String result = NGBSAPI.getContractCancellationEndpointMPUB(BILLING_ID, CONTRACT_ID);
        Test.stopTest();

        String expectedEndpoint = String.format(
            NGBSAPI.NGBS_CONTRACT_CANCELLATION_MPUB,
            new List<String> {BILLING_ID, CONTRACT_ID}
        );
        Assert.areEqual(expectedEndpoint, result, 'Wrong endpoint was returned');
    }

    @IsTest
    private static void testCheckCostCenterRequest() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);
        Test.startTest();
        HttpResponse resp = NGBSAPI.checkCostCenterRequest('123');
        Test.stopTest();
        Assert.areEqual(200, resp.getStatusCode(), 'should return 200 status code');
        Assert.areEqual(true, resp.getBody().contains('"name":"Main"'), 'should return true if main cost center exists');
    }

    @IsTest
    private static void testCreateMainCostCenterRequest() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        String settings = '{"name": "Main","defaultPackageStatus": "Disabled"}';
        Test.setMock(HttpCalloutMock.class, testMock);
        Test.startTest();
        HttpResponse resp = NGBSAPI.createMainCostCenterRequest('123', settings);
        Test.stopTest();
        Assert.areEqual(201, resp.getStatusCode(), 'should return 201 status code');
    }

    @isTest
    static void testCreateNGBSContract() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);

        Map<String, Object> contractParams = new Map<String, Object>{
            'term' => 12,
            'renewalTerm' => 12,
            'autoRenewal' => true,
            'description' => 'Test contract',
            'packages' => new List<Object>{
                new Map<String, Object>{
                    'packageId' => 'test-package-id',
                    'packageVersion' => '1.0',
                    'description' => 'Test package',
                    'licenses' => new List<Object>(),
                    'target' => new Map<String, Object>{
                        'value' => 'TestProduct'
                    }
                }
            }
        };

        Test.startTest();
        Response result = NGBSAPI.createNGBSContract('test-account-id', contractParams);
        Test.stopTest();

        Assert.isNotNull(result, 'Response should not be null');
        Assert.isTrue(result.isSuccess(), 'Response should be successful');
    }

    @isTest
    static void testCreateNGBSContractWithBlankAccountId() {
        Test.startTest();
        try {
            NGBSAPI.createNGBSContract('', new Map<String, Object>());
            Assert.fail('Should throw exception for blank account ID');
        } catch (AquivaHelper.AquivaException ex) {
            Assert.isTrue(ex.getMessage().contains('Account ID is required'), 'Wrong exception message');
        }
        Test.stopTest();
    }
    
    @isTest
    private static void getNGBSBillingInfoSummaryLicenses_withRequestBody_returnsLicensesViaPost() {
        // Given
        String accountId = '3120888001';
        String packageId = '3104295001';
        String requestBody = '{"fields":{"scheduledForRemoval":true}}';
    
        String bodyForMock = '[{' +
            '"amount": 120009.99,' +
            '"catalogId": "LC_DL-UNL_50",' +
            '"discountAmount": -36012,' +
            '"discountValue": {"unit": "Percent","value": 30},' +
            '"qty": 3001,' +
            '"billingType": "Recurring",' +
            '"billingCycleDuration": "Monthly",' +
            '"dateRangeStart": "2020-06-17",' +
            '"dateRangeEnd": "2020-07-16",' +
            '"description": "DigitalLine Unlimited",' +
            '"descriptionKey": "C42D89795912155D0609ADF07491A640",' +
            '"scheduledForRemoval": false' +
        '}]';
    
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo>{
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Complete', bodyForMock, 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);
    
        // When
        Test.startTest();
        List<BillingWrappers.BillingInfoSummaryLicense> result = NGBSAPI.getNGBSBillingInfoSummaryLicenses(
            accountId,
            packageId,
            null,
            requestBody
        );
        Test.stopTest();
    
        // Then
        Assert.areEqual(1, result.size(), 'Response should return with 1 license');
        Assert.areEqual('LC_DL-UNL_50', result[0].catalogId, 'CatalogId should match');
        Assert.areEqual(120009.99, result[0].amount, 'Amount should match');
        Assert.areEqual(3001, result[0].qty, 'Quantity should match');
    }
    
    @isTest
    private static void getNGBSBillingInfoSummaryLicenses_withBlankRequestBody_returnsLicensesViaGet() {
        // Given
        String accountId = '3120888001';
        String packageId = '3104295001';
        Boolean mergeDiscountsParam = false;
    
        String bodyForMock = '[{' +
            '"amount": 50.00,' +
            '"catalogId": "LC_HD_4",' +
            '"discountAmount": 0,' +
            '"qty": 100,' +
            '"billingType": "Recurring",' +
            '"billingCycleDuration": "Monthly",' +
            '"dateRangeStart": "2020-06-17",' +
            '"dateRangeEnd": "2020-07-16",' +
            '"description": "Test License"' +
        '}]';
    
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo>{
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license?mergeDiscounts=false', 'Complete', bodyForMock, 200, HttpHelper.METHOD_GET)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);
    
        // When
        Test.startTest();
        List<BillingWrappers.BillingInfoSummaryLicense> result = NGBSAPI.getNGBSBillingInfoSummaryLicenses(
            accountId,
            packageId,
            mergeDiscountsParam,
            ''
        );
        Test.stopTest();
    
        // Then
        Assert.areEqual(1, result.size(), 'Response should return with 1 license');
        Assert.areEqual('LC_HD_4', result[0].catalogId, 'CatalogId should match');
    }
    
    @isTest
    private static void getNGBSBillingInfoSummaryLicenses_withNullRequestBody_returnsLicensesViaGet() {
        // Given
        String accountId = '3120888001';
        String packageId = '3104295001';
    
        String bodyForMock = '[{' +
            '"amount": 75.00,' +
            '"catalogId": "LC_SC_1",' +
            '"discountAmount": 0,' +
            '"qty": 50,' +
            '"billingType": "Recurring",' +
            '"billingCycleDuration": "Monthly"' +
        '}]';
    
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo>{
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Complete', bodyForMock, 200, HttpHelper.METHOD_GET)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);
    
        // When
        Test.startTest();
        List<BillingWrappers.BillingInfoSummaryLicense> result = NGBSAPI.getNGBSBillingInfoSummaryLicenses(
            accountId,
            packageId,
            null,
            null
        );
        Test.stopTest();
    
        // Then
        Assert.areEqual(1, result.size(), 'Response should return with 1 license');
    }
    
    @isTest
    private static void getNGBSBillingInfoSummaryLicenses_withBlankAccountId_throwsException() {
        // Given
        String accountId = '';
        String packageId = '3104295001';
        String requestBody = '{"test": true}';
        Boolean isExceptionThrown = false;
    
        // When
        try {
            NGBSAPI.getNGBSBillingInfoSummaryLicenses(accountId, packageId, null, requestBody);
        } catch (AquivaHelper.AquivaException ex) {
            isExceptionThrown = ex.getMessage().contains(NGBSAPI.BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }
    
        // Then
        Assert.isTrue(isExceptionThrown, 'Exception should be thrown for blank accountId');
    }
    
    @isTest
    private static void getNGBSBillingInfoSummaryLicenses_withBlankPackageId_throwsException() {
        // Given
        String accountId = '3120888001';
        String packageId = '';
        String requestBody = '{"test": true}';
        Boolean isExceptionThrown = false;
    
        // When
        try {
            NGBSAPI.getNGBSBillingInfoSummaryLicenses(accountId, packageId, null, requestBody);
        } catch (AquivaHelper.AquivaException ex) {
            isExceptionThrown = ex.getMessage().contains(NGBSAPI.BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }
    
        // Then
        Assert.isTrue(isExceptionThrown, 'Exception should be thrown for blank packageId');
    }
    
    @isTest
    private static void getNGBSBillingInfoSummaryLicenses_withNullAccountIdAndPackageId_throwsException() {
        // Given
        Boolean isExceptionThrown = false;
    
        // When
        try {
            NGBSAPI.getNGBSBillingInfoSummaryLicenses(null, null, null, '{"test": true}');
        } catch (AquivaHelper.AquivaException ex) {
            isExceptionThrown = ex.getMessage().contains(NGBSAPI.BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }
    
        // Then
        Assert.isTrue(isExceptionThrown, 'Exception should be thrown for null accountId and packageId');
    }
    
    @isTest
    private static void getNGBSBillingInfoSummaryLicenses_withInvalidJsonResponse_throwsException() {
        // Given
        String accountId = '3120888001';
        String packageId = '3104295001';
        String requestBody = '{"fields":{"scheduledForRemoval":true}}';
    
        String invalidJsonBody = 'invalid json response';
    
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo>{
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Complete', invalidJsonBody, 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);
    
        Boolean isExceptionThrown = false;
    
        // When
        Test.startTest();
        try {
            NGBSAPI.getNGBSBillingInfoSummaryLicenses(accountId, packageId, null, requestBody);
        } catch (AquivaHelper.AquivaException ex) {
            isExceptionThrown = ex.getMessage().contains('Unexpected error occurred while retrieving billing info from NGBS');
        }
        Test.stopTest();
    
        // Then
        Assert.isTrue(isExceptionThrown, 'Exception should be thrown for invalid JSON response');
    }
    
    @isTest
    private static void getNGBSBillingInfoSummaryLicenses_withEmptyArrayResponse_returnsEmptyList() {
        // Given
        String accountId = '3120888001';
        String packageId = '3104295001';
        String requestBody = '{"fields":{"scheduledForRemoval":true}}';
    
        String emptyArrayBody = '[]';
    
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo>{
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Complete', emptyArrayBody, 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);
    
        // When
        Test.startTest();
        List<BillingWrappers.BillingInfoSummaryLicense> result = NGBSAPI.getNGBSBillingInfoSummaryLicenses(
            accountId,
            packageId,
            null,
            requestBody
        );
        Test.stopTest();
    
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(0, result.size(), 'Result should be empty list');
    }
}