@isTest
private class Test_EntitlementsViewController {

    @isTest static void test_getConstructor() {
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;

        ApexPages.StandardController sc = new ApexPages.standardController(testAccount);
        EntitlementsViewController controller = new EntitlementsViewController(sc);

        system.assertEquals(controller.acc.Id, testAccount.Id);

        ApexPages.currentPage().getParameters().put('id', testAccount.Id);
        EntitlementsViewController controller2 = new EntitlementsViewController();
        system.assertEquals(controller2.acc.Id, testAccount.Id);
    }

    @isTest static void test_getEntitlements() {
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;

        Entitlement__c testEntitlement = new Entitlement__c();
        testEntitlement.Account__c = testAccount.Id;
        testEntitlement.Name = 'Test Ent';
        testEntitlement.Active__c = true;
        insert testEntitlement;

        ProductDetail__c pd = new ProductDetail__c();
        pd.QuantityOrThreshold__c = 0;
        pd.Entitlement__c = testEntitlement.Id;
        pd.RampUp__c = '0';
        insert pd;

        Test.startTest();
        Response res = EntitlementsViewController.getEntitlements(testAccount.Id, '');
        List<Entitlement__c> data = (List<Entitlement__c>) res.data.get(EntitlementSync.ENTITLEMENT_RESPONSE_DATA_KEY);
        system.assertEquals(data.size(), 1);

        Response res2 = EntitlementsViewController.getEntitlements('', '');
        List<Entitlement__c> data2 = (List<Entitlement__c>) res2.data.get(EntitlementSync.ENTITLEMENT_RESPONSE_DATA_KEY);
        system.assertEquals(data2.isEmpty(), true);
        Test.stopTest();
    }

    @isTest static void test_getPackagesFormBilling() {

        insert new NGBS_Settings__c(
            BaseEndpoint__c = 'http://fake-billing-api',
            AccountManagerPath__c = '/account-manager/v1.0',
            Login__c = 'test',
            Password__c = 'test'
        );

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        String result = EntitlementsViewController.getPackagesFromBilling((Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue(), '123');

        String dataJson = '[{"id":"9710001","currency":"USD","billingId":"123"}]';
        system.assertEquals(dataJson, result);

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_getNGBSLicenseSettings() {
        try {
            EntitlementsViewController.getNGBSLicenseSettings();
        } catch (Exception e) {}
    }

    @isTest static void test_getAssets() {
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;

        Product2 testProduct = new Product2(
                Name = 'Test Product',
                Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        insert testProduct;

        Asset testAsset = new Asset(
                AccountId = testAccount.Id,
                Name = 'Test Asset',
                Active__c = true,
                Product2Id = testProduct.Id
        );
        insert testAsset;

        Test.startTest();
        Response res = EntitlementsViewController.getAssets(testAccount.Id);
        List<Asset> data = (List<Asset>) res.data.get(EntitlementsViewController.ASSETS_RESPONSE_DATA_KEY);
        system.assertEquals(data.size(), 1);
        Test.stopTest();
    }

    @isTest static void test_getAccount() {
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;

        Test.startTest();
        Account accountResult = EntitlementsViewController.getAccount(testAccount.Id);
        Test.stopTest();
        system.assertNotEquals(null, accountResult);
    }

    @isTest static void testGetActiveSalesAgreement() {
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = testAccount.Id;
        opp.StageName = '5. Agreement';
        insert opp;

        Quote testQuote = new Quote(
            Name = 'Test Quote',
            Status = 'Active',
            OpportunityId = opp.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(30)
        );
        insert testQuote;

        Test.startTest();
        Quote quote = EntitlementsViewController.getActiveSalesAgreement(testAccount.Id);
        Test.stopTest();
        Assert.areNotEqual(quote, null, 'There should be a quote');
    }

    @isTest
    static void test_getPackagesFromBilling() {
        
        insert new NGBS_Settings__c(
            BaseEndpoint__c = 'http://fake-billing-api',
            AccountManagerPath__c = '/account-manager/v1.0',
            Login__c = 'test',
            Password__c = 'test'
        );
        
        Account acc = new Account(
            Name          = 'Test Account',
            Billing_ID__c = '123'
        );
        insert acc;
        
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        
        Test.startTest();
        String result = EntitlementsViewController.getPackagesFromBilling(acc.Id, acc.Billing_ID__c);
        Test.stopTest();
        
        List<Object> packages = (List<Object>) JSON.deserializeUntyped(result);
        
        Map<String, Object> pkg = (Map<String, Object>) packages[0];
        
        Assert.areEqual('USD', (String) pkg.get('currency'));
        Assert.isNull(pkg.get('currencyCode'));
    }
}