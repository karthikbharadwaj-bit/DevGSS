@isTest
private class Test_EntitlementsViewHelper {
    private static final String TEST_BILLING_ID = '123456789';
    private static final String TEST_PACKAGE_ID = '987654321';
    private static final String TEST_CATALOG_ID = 'TEST_CATALOG_001';

    @testSetup
    static void generateData() {
        insert new NGBS_Settings__c(
            BaseEndpoint__c = 'http://test',
            AccountManagerPath__c = '/account-manager/v1.0',
            Login__c = 'test',
            Password__c = 'test'
        );
    }

    @isTest
    static void testGetBillingInfoSummaryLicenses_Success() {
        String mockResponse = '[{"catalogId": "' + TEST_CATALOG_ID + '","billingCycleDuration": "Monthly","amount": 100.00,' +
            '"price": 50.00,"discountAmount": 0.00,"qty": 2,"discountValue": {"unit": "Percent","value": 20.00 },' +
            '"dateRangeStart": "2024-01-01","dateRangeEnd": "2024-01-31","description": "Test License",' +
            '"scheduledForRemoval": false}]';

        BillingHttpRequestMock mock = new BillingHttpRequestMock();
        mock.body = mockResponse;
        mock.code = 200;
        mock.status = 'OK';

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        List<EntitlementsViewHelper.BillingInfoSummaryLicenseResponse> result =
            EntitlementsViewHelper.getBillingInfoSummaryLicenses(TEST_BILLING_ID, TEST_PACKAGE_ID);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual(1, result.size(), 'Should have 1 license');
        Assert.areEqual(TEST_CATALOG_ID, result[0].catalogId, 'Catalog ID should match');
        Assert.areEqual(false, result[0].scheduledForRemoval, 'ScheduledForRemoval should match');
    }

    @isTest
    static void testGetBillingInfoSummaryLicenses_Failure() {
        BillingHttpRequestMock mock = new BillingHttpRequestMock();
        mock.body = 'Bad Request';
        mock.code = 400;
        mock.status = 'Bad Request';

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        try {
            EntitlementsViewHelper.getBillingInfoSummaryLicenses(TEST_BILLING_ID, TEST_PACKAGE_ID);
            Assert.fail('Should have thrown exception');
        } catch (NGBSAPI.NGBSAPIException ex) {
            Assert.isTrue(String.isNotBlank(ex.toString()), 'Should contain error message');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetBillingInfoForPackage_Success() {
        String mockResponse = '[{"catalogId": "' + TEST_CATALOG_ID + '","billingCycleDuration": "Monthly","amount": 100.00,' +
            '"price": 50.00,"discountAmount": 0.00,"qty": 2,"billingType": "Recurring","dateRangeStart": "2024-01-01",' +
            '"dateRangeEnd": "2024-01-31","description": "Test License","scheduledForRemoval": false}]';

        BillingHttpRequestMock mock = new BillingHttpRequestMock();
        mock.body = mockResponse;
        mock.code = 200;
        mock.status = 'OK';

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        List<EntitlementsViewHelper.GroupedLicense> result =
            EntitlementsViewHelper.getBillingInfoForPackage(TEST_BILLING_ID, TEST_PACKAGE_ID);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(1, result.size(), 'Should have 1 grouped license');
        Assert.areEqual(TEST_PACKAGE_ID, result[0].packageId, 'Package ID should match');
        Assert.isFalse(result[0].isGrouped, 'Should not be grouped (single license)');
        Assert.areEqual(0, result[0].childLicenses.size(), 'Should have 0 child license');
    }

    @isTest
    static void testGetBillingInfoForPackage_GroupedLicenses() {
        String mockResponse = '[{"catalogId": "' + TEST_CATALOG_ID + '","billingCycleDuration": "Monthly",' +
            '"amount": 200.00,"price": 50.00,"discountAmount": 0.00,"qty": 2,"billingType": "Recurring",' +
            '"dateRangeStart": "2024-01-01","dateRangeEnd": "2024-01-31","description": "Test License 1"' +
            '},{"catalogId": "' + TEST_CATALOG_ID + '","billingCycleDuration": "Monthly","amount": 200.00,' +
            '"price": 50.00,"discountAmount": 0.00,"qty": 4,"billingType": "Recurring","dateRangeStart": "2024-01-01",' +
            '"dateRangeEnd": "2024-01-31","description": "Test License 1"}]';

        BillingHttpRequestMock mock = new BillingHttpRequestMock();
        mock.body = mockResponse;
        mock.code = 200;
        mock.status = 'OK';

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        List<EntitlementsViewHelper.GroupedLicense> result =
            EntitlementsViewHelper.getBillingInfoForPackage(TEST_BILLING_ID, TEST_PACKAGE_ID);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(1, result.size(), 'Should have 1 grouped license');
        Assert.isTrue(result[0].isGrouped, 'Should be grouped (multiple licenses)');
        Assert.areEqual(2, result[0].childLicenses.size(), 'Should have 2 child licenses');
        Assert.isNull(result[0].qty, 'Quantity should be null (different values)');
    }

    @isTest
    static void testGetBillingInfoForPackage_WithScheduledForRemoval() {
        String mockResponse = '[{"catalogId": "' + TEST_CATALOG_ID + '","billingCycleDuration": "Monthly",' +
            '"amount": 100.00,"price": 50.00,"discountAmount": 0.00,"qty": 2,"billingType": "Recurring",' +
            '"dateRangeStart": "2024-01-01","dateRangeEnd": "2024-01-31","description": "Test License",' +
            '"scheduledForRemoval": true}]';

        BillingHttpRequestMock mock = new BillingHttpRequestMock();
        mock.body = mockResponse;
        mock.code = 200;
        mock.status = 'OK';

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        List<EntitlementsViewHelper.GroupedLicense> result =
            EntitlementsViewHelper.getBillingInfoForPackage(TEST_BILLING_ID, TEST_PACKAGE_ID);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(0, result.size(), 'Should have 0 licenses (scheduledForRemoval filtered out)');
    }

    @isTest
    static void testGroupedLicense_Constructor() {
        Test.startTest();
        EntitlementsViewHelper.GroupedLicense groupedLicense = new EntitlementsViewHelper.GroupedLicense();
        Test.stopTest();

        Assert.isNotNull(groupedLicense, 'GroupedLicense should not be null');
        Assert.isNotNull(groupedLicense.childLicenses, 'ChildLicenses list should not be null');
        Assert.areEqual(0, groupedLicense.childLicenses.size(), 'ChildLicenses should be empty');
        Assert.isFalse(groupedLicense.isGrouped, 'isGrouped should be false by default');
    }

    @isTest
    static void testBillingInfoRequestBody_Constructor() {
        Test.startTest();
        EntitlementsViewHelper.BillingInfoRequestBody requestBody = new EntitlementsViewHelper.BillingInfoRequestBody();
        Test.stopTest();

        Assert.isNotNull(requestBody, 'RequestBody should not be null');
        Assert.isNotNull(requestBody.fields, 'Fields should not be null');
        Assert.isTrue(requestBody.fields.scheduledForRemoval, 'scheduledForRemoval should be true');
        Assert.isTrue(requestBody.fields.price, 'price should be true');
        Assert.isTrue(requestBody.fields.dateRange, 'dateRange should be true');
        Assert.isNotNull(requestBody.fields.discountValue, 'discountValue should not be null');
        Assert.areEqual(2, requestBody.fields.discountValue.size(), 'discountValue should have 2 elements');
        Assert.areEqual('Unit', requestBody.fields.discountValue[0], 'First discountValue should be Unit');
        Assert.areEqual('Value', requestBody.fields.discountValue[1], 'Second discountValue should be Value');
    }
}