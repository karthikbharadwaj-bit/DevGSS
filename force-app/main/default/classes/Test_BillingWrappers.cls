@isTest
private class Test_BillingWrappers {

    private static String PACKAGE_INFO =
        '[{"id":"18","version":"1","status":"test","packageInfo":{"id":1389379001,"catalogId":"' +
            '18","version":"1"},"productName":"Office"' +
            ',"duration":"Monthly","edition":{"id":1,"name":"Standard"},"contract":' +
            '{"id":"a8f0S0000008cxHQAQ","extId":"nib","billingId":1239' +
            '},"offerType":"Regular","globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":' +
            '"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":' +
            '"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
            '"override":false}],"permissions":null,"discountTemplates":[{"id":123,"values":{}}]}]';
    private static String NGBS_ACCOUNT_RESPONSE = '{"id":"1","packages":[{"catalogId":"18",' +
        '"version":"1","offerType":"Regular","id":"2","labels":{"upgradeWizardExpiration":null},"licenses":[{"id":"3","qty":5,"catalogId": "' + Product2Helper.SUBSCRIPTION_LICENSE + '", "subLicenses":[]}],"masterDuration": "Monthly"}]}';
    private static String NGBS_ACCOUNT_WITH_MULTIPLE_PACKAGES = '{"packages":[{"id":"12345","offerType":"Regular","product":"Engage Voice Standalone"},{"id":"123456","offerType":"Regular","product":"Office"}]}';
    private static String NGBS_PACKAGE = '{"catalogId":"18",' +
        '"version":"1","offerType":"Regular","id":"2","licenses":[{"id":"3","qty":5,"catalogId": "' + Product2Helper.SUBSCRIPTION_LICENSE + '", "subLicenses":[]}],"masterDuration": "Monthly"}';

    private static String LICENSES_COUNTER_RESPONSE = '[{"instanceQty" : 1,"categoryId" : "DID","catalogId" : "LC_DID_53","billingCodeId" : null,"batchQty" : 12}, ' +
    '{"instanceQty" : 1,"categoryId" : "DL-UNL","catalogId" : "LC_DL-UNL_50","billingCodeId" : null,"batchQty" : 12}, ' +
    '{"instanceQty" : 1,"categoryId" : "DL","catalogId" : "LC_DL_75","billingCodeId" : null,"batchQty" : 12}, ' +
    '{"instanceQty" : 1,"categoryId" : "E911","catalogId" : "LC_E911_52","billingCodeId" : null,"batchQty" : 12}, ' +
    '{"instanceQty" : 1,"categoryId" : "CRF","catalogId" : "LC_CRF_51","billingCodeId" : null,"batchQty" : 12}]';

    private static String BILLING_INFO_ALL_LICENSE_RESPONSE = '{"productLine" : "RC","packageId" : "25309001","packageExpirationDate" : null,"packageDuration" : null,"packageDescription" : "RingCentral Office Standard","nextBillingDate" : "2021-04-03T07:00Z[UTC]","licenses" : ['
        + '{"topLicenseId" : "369246001","scheduledForRemoval" : false,"replacement" : null,"qty" : 12,"price" : 4.99,"licenseTypeId" : null,"licenseId" : "369246001","discount" : null,"description" : "Additional Local Number","categoryId" : "ALN","catalogId" : "LC_ALN_38","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : true,"props" : {"LicenseTypeId":"27"}}],"creditBalance" : 0,"accountId" : "25309001"}';
    private static String PACKAGE_INFO_QLI_WITH_LBOX = '{"categoryCode":"DL-UNL", "categoryPath":"DL-UNL", "discount"' +
        ':{},"duration":"Monthly","id":"18","price":0,"version":"1","parent":"LC_DL_75","q":33,' +
            '"lboxes":[{"elementID":"LB_702","min":1,"max":100}], "originalDiscount":{"applicableTo":' +
            '{"type":"test","id":"testId"},"values":{"testVal" :{"value":2.00,"type":"testType"}}},"isPhoneLeasingEnabled":22}';
    private static final String BILLING_PRODUCT_RESPONSE = '{"catalogId":"LC_DL_75","currencyIsoCode":"USD","goa":"test","name":"TestProduct","categoryCode":"DL", "itemType":"TestType", "billingType":"Invoice"}';
    private static final String BILLING_CARTITEM = '{"catalogId":"LC_DL_75","currencyIsoCode":"USD","goa":"test","name":"TestCartItem","itemType":"TestType", "billingType":"Invoice", "billingCycleDuration":"' + Product2Helper.CHARGE_TERM_MONTHLY + '", "quantity":12,"unitPrice":12.12,"discount":5.00,"discountType":"' + QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE + '", "packageInfo":"testPackageInfo", "id":"18","isDeleted":false,"guid":"testGUID","displayName":"testCartItem","sortOrder":2,"salesEndDate":null,"sfPromoCodeId":"testSfPromoCodeId"}';
    private static String PARAMS_SHIPPING = '{"action":"testAction","selectedQuoteId":"testSelectedQuoteId","shippingItemsMap":{"testKey1":[{"locationID":"testLocId","junctionID":"testJuncId","quantity":12,"isDeleted":false,"quoteLineItemId":"testQliId",'
        + '"location":{ "attentionTo":"testContact", "id":"testId","shippingMethod":"Ground","shippingLicensesTree":"testTree","shippingBillingCodeId":"testBillingCodeId",'
        + '"address":{"additionalAddressLine":null,"addressLine":"testAddress","city":"testCity","country":"testCountry","state":"testState","zipCode":"12345","id":"testAddressId"}}}]}}';
    private static String TAX_LOCATIONS_RESPONSE = '{"addresses":[{"id":"testId", "externalId":"testExtId", "address":{ "id":"testAddId", "label":"testLabel", "firstName":"testFirstName", "lastName":"testLastName", "phone":"123456789", "street1":"testStreet1", "street2":"testStreet2", "county":null, "city":"testCity", "state":"testState", "zip":"1234", "country":"testCountry"}}]}';
    private static String GW_CONTRACT = '{"name":"test_gw_Contract","startDate":"2019-12-26", "term":1.00, "duration":"' + Product2Helper.CHARGE_TERM_MONTHLY + '","description":"testDescr","packageVersion":"1", "licences":["'+ Product2Helper.DL_UNL_ELEMENT_ID + '"], "discounts":[{"id":"testDiscId","description":"testDiscDescr","priority":"1","promoCode":"testPromo","visible":true,"addedAt":"2019-12-26", "discountTemplates":[{"id":2.00,"description":"testTempl","applicableTo":{"type":"testType","id":"testId"}, "applicationTerms":{"startDate":"2019-12-26","endDate": null, "licenseScope":"All","maxLicenses":"1000"},"values":{"test":{"unit":"Money","value":5.00,"recurringTerms":{"unit":"Month","value":1.00}}}}],"target":{"catalogId":"18","version":"1"}}],"availableInPackages":["18"],"billingCountries":["USA"],"businessIdentitiesCountries":["USA","Canada"],"id":"testContractId","extId":"testContractExtId","isActive":true}';
    private static String BILLING_CONTRACT = '{"id":"testBillingContractId","startBillingCycleNumber":1,"term":2,"startDate":"2019-12-26"}';
    private static String PARAMS_DATA = '{"action":"testAction","opportunityId":"testOppId","selectedQuoteId":"quoteId",' +
            '"recordType":"testRecordType","quoteId":"testQuoteId","templateId":"tempId","templateParameters":{"testKey":"testValue"},' +
            '"initialTerm":"12","specialTerms":"1 Free Month of Service","freeShippingTerms":"Free shipping","accountId":"testAccountId","packageInfo":"testPackageInfo",' +
            '"subAction":"testSubAction","actionComment":"comment","status":"' + QuoteHelper.STATUS_UPGRADE + '","subBrand":"testSubBrand","brand":"RingCentral",' +
            '"quote":{"id":"testQuoteId","packageInfo":"[{\\"id\\":\\"18\\",\\"version\\":\\"1\\"}]","name":"testQuote","expirationDate":"2021-12-06",' +
            '"quoteType":"Quote","status":"Draft","initialTerm":"12","initialTermPOC":"1","renewalTerm":"24","autoRenewal":true,' +
            '"startDate":"2021-12-29","endDate":"2023-12-29","specialTerms":"1 Free Month of Service","freeShippingTerms":"Free shipping",' +
            '"upsellStatus":"New","isTaxesAdded":false,"enabledLBO":true,"isLBODealDeskProvision":false,"doNotSendOrderToNGBS":false,' +
            '"justification":"testJustification","mainAreaCodeId":"testMainAreaCodeId","faxAreaCodeId":"testFaxAreaCodeId",' +
            '"opportunityProvisioningDetails":"test","shippingShipAttentionTo":"test contact","shippingCountry":"USA","shippingCity":"Belmont",' +
            '"shippingState":"CA","shippingAddressLine":"testStreet","shippingPostalCode":"1233","shippingAdditionalAddressLine":null,"shippingCustomerName":"testCompany",' +
            '"shippingShippingOption":"Ground","shippingMultipleLocations":false,"opportunitySelfProvisioned":false,' +
            '"faxAreaCodeInfo":{"country":"USA","state":"CA","city":"Belmont","type":"Local","areaCode":12},"mainAreaCodeInfo":{"country":"USA","state":"CA","city":"Belmont","type":"Local","areaCode":12},' +
            '"creditAmount":12000.00,"freeServiceTaxes":12.00,"isFullCalculationFSC":false,"parentQuoteId":null,' +
            '"paymentMethod":"Invoice","rcAccountNumber":null,"ccAccountNumber":null,"isTerminationOpportunity":false},' +
            '"items":['+ BILLING_CARTITEM + '],"areaCodeLineItems":[{"id":"testareacodeId","cartItemCatalogId":"LC_DL-UNL_50","quantity":12,"areaCodeId":"testAreaCodeId","isDeleted":false,"areaCodeInfo":{"country":"USA","state":"CA","city":"Belmont","type":"Local","areaCode":12}}],' +
            '"entitlements":[{"elementId":"LC_SC_29","name":"testEntName","quantity":1,"unitPrice":3.50,"effectivePrice":3.50,"duration":"' + Product2Helper.CHARGE_TERM_MONTHLY + '","discount": {"type":"Currency","value":5},"billingPackage":{"catalogId":"18","version":"1","currencyCode":"USD"},"displayName":"testEnt","sortOrder":1}],' +
            '"products":[' + BILLING_PRODUCT_RESPONSE + '],"qliMap":{"testQliKey":"testQliValue"},"data":{"testDataKey":"testDataValue"},"stepUps":[{"stepUpDate":"2019-12-26","stepDLs":10.00}],' +
            '"isUserCanApprove":true,"isWizardHasErrors":false,"enabledLBO":true,"isPrimaryQuote":true,"isRemoveAreaCodes":false,"billingCodes":[{"guid":"testGuid","Id":"testId","parentId":null,"parentXid":null,"billingId":"123","name":"testBillingCode","depth":12.00,"parentBillingId":null,"addressId":"testAddrId",' +
            '"location":null,"bundles":null,"child":null,"billingCodePath":null}],"selectedDocsIds":[],"taxLocations":null,"areaCodeItem":{"country":"USA","state":"CA","city":"Belmont","type":"Local","areaCode":12},' +
            '"envelopeId":null,"quoteIdSet":null,"promotionList":[{"id":"testPromId","startDate":"2019-12-26","endDate":"2020-12-26","priority":"Z","promoCodeId":"testPromocodeId","promoCode":"testPromoCode","name":"testPromo","discountTemplates":"testDiscountTempl","description":"testDescr","quoteId":"testQtId"}],' +
            '"paymentMethod":"Invoice","approvalParams":{"accountId":"testAccId","action":"move to invoice","recordType":"' + ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME + '","accountPartnerId":null}}';

    private static String BILLING_CODES_DATA = '{"Data":[{"guid":"testGuid","Id":"testId","parentId":null,"parentXid":null,"billingId":"123","name":"testBillingCode","depth":12.00,"parentBillingId":null,"addressId":"testAddrId","location":null,"bundles":null,"child":null,"billingCodePath":null}]}';
    private static String STEP_UP = '{"stepUpDate":"2019-12-26","stepDLs":10.00}';
    private static String SHIPPING_LICENSE_RESPONSE = '{"elementID":"LC_SHIPT_81","name":"Test Shipping Name - Ground", "displayName":"Test DisplayName","billingType":"testBillingType","searchCategories":[{"key":"ShippingCode","value":"GROUND"}]}';
    private static String PROSERV_PARAM = '{"isSignUpCompleted":true,"accountPackageId":"12345"}';

    @isTest
    private static void testCreateBundle() {

        BillingWrappers.Bundle testBundle = new BillingWrappers.Bundle();
        testBundle.elementID = 'some_elementId';
        testBundle.qty = 1;
        testBundle.sortOrder = 1;

        System.assertNotEquals(
            null,
            testBundle.buildBundleElementId(null),
            'created bundleElementId should not be null'
        );

        Cost_Center_Line_Item__c ccli = testBundle.buildCostCenterLineItem(null, null, null);
        System.assertEquals(
            testBundle.qty,
            ccli.Quantity__c,
            'Quantity__c of created Cost_Center_Line_Item__c should be equal to Bundle.qty'
        );
        System.assertEquals(
            testBundle.elementID,
            ccli.ElementId__c,
            'ElementId__c of created Cost_Center_Line_Item__c should be equal to Bundle.elementID'
        );
        System.assertEquals(
            testBundle.sortOrder,
            ccli.SortOrder__c,
            'SortOrder__c of created Cost_Center_Line_Item__c should be equal to Bundle.sortOrder'
        );
        System.assertEquals(
            testBundle.elementID,
            ccli.Name,
            'if QuoteLineItem is not passed as parameter - Name should be equal to Bundle.elementID'
        );
        System.assertNotEquals(
            null,
            ccli.BundleElementId__c,
            'BundleElementId__c of created Cost_Center_Line_Item__c should not be empty'
        );
    }

    @isTest
    private static void testCreateBundleItem() {

        BillingWrappers.BundleItem testBundleItem = new BillingWrappers.BundleItem();
        testBundleItem.elementID = 'some_elementId';

        Cost_Center_Line_Item__c ccli = testBundleItem.buildCostCenterLineItem(null, null, null, null);
        System.assertEquals(
            testBundleItem.elementID,
            ccli.ElementId__c,
            'ElementId__c of created Cost_Center_Line_Item__c should be equal to BundleItem.elementID'
        );
        System.assertEquals(
            testBundleItem.elementID,
            ccli.Name,
            'if QuoteLineItem is not passed as parameter - Name should be equal to BundleItem.elementID'
        );
    }

    @isTest
    private static void testCreateBundleAndBundlItemFromCostCenterLineItem() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc'
            })
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Type => 'Syndicated - New',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Test.startTest();
            Quote q = NGBSTestDataGenerator.createQuote(opp.Id);

            String testElementId = 'LC_DL_75';
            QuoteLineItem qli = NGBSTestDataGenerator.createQLI('testProduct', testElementId, 'USD', acc, q);

            Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Cost_Center__c.Name => 'test cost center',
                    Cost_Center__c.Quote__c => q.Id,
                    Cost_Center__c.BillingId__c => 'test billing id'
                })
                .create()
                .getRecord();

            Cost_Center_Line_Item__c ccli = (Cost_Center_Line_Item__c) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Cost_Center_Line_Item__c.Name => 'testCostCenterLineItem',
                    Cost_Center_Line_Item__c.Quote_Line_Item__c => qli.Id,
                    Cost_Center_Line_Item__c.Cost_Center__c => costCenter.Id,
                    Cost_Center_Line_Item__c.Quantity__c => 1,
                    Cost_Center_Line_Item__c.ElementId__c => testElementId
                })
                .create()
                .getRecord();
        Test.stopTest();

        BillingWrappers.Bundle testBundle = new BillingWrappers.Bundle(ccli);
        System.assertEquals(ccli.Id, testBundle.id, 'id value should be copied from Cost_Center_Line_Item__c object');
        System.assertEquals(
            testElementId,
            testBundle.elementID,
            'elementID value should be copied from Cost_Center_Line_Item__c.ElementId__c'
        );
        System.assertEquals(
            ccli.Quantity__c,
            testBundle.qty,
            'qty value should be copied from Cost_Center_Line_Item__c.Quantity__c'
        );
        System.assertEquals(
            ccli.Cost_Center__c,
            testBundle.costCenterId,
            'costCenterId value should be copied from Cost_Center_Line_Item__c.Cost_Center__c'
        );

        String bundleElementId = testBundle.buildBundleElementId(ccli.Cost_Center__c);
        System.assert(
            bundleElementId.contains(testBundle.elementID),
            'generated bundleElementId should contain elementID'
        );
        System.assert(
            bundleElementId.contains(ccli.Cost_Center__c),
            'generated bundleElementId should contain Cost_Center__c id'
        );

        BillingWrappers.BundleItem testBundleItem = new BillingWrappers.BundleItem(ccli);
        System.assertEquals(ccli.Id, testBundleItem.id, 'id value should be copied from Cost_Center_Line_Item__c object');
        System.assertEquals(
            testElementId,
            testBundleItem.elementID,
            'elementID value should be copied from Cost_Center_Line_Item__c.ElementId__c'
        );
    }

    @isTest
    private static void verifyQuotePackageInfoWrapper() {
        BillingWrappers.QuotePackageInfoWrapper pinfoEmpty = new BillingWrappers.QuotePackageInfoWrapper();
        BillingWrappers.QuotePackageInfoWrapper pinfoNotEmpty = new BillingWrappers.QuotePackageInfoWrapper(PACKAGE_INFO);
        String pkgInfoPOC = PACKAGE_INFO.replace(QuoteHelper.OFFER_TYPE_REGULAR, QuoteHelper.OFFER_TYPE_POC);
        BillingWrappers.QuotePackageInfoWrapper pinfoForPOC = new BillingWrappers.QuotePackageInfoWrapper(pkgInfoPOC);

        BillingWrappers.QuotePackageInfo getPinfo = pinfoNotEmpty.getPackageInfo();
        System.assertNotEquals(null, pinfoNotEmpty, 'Package info must be filled up');
        System.assertNotEquals(null, getPinfo, 'Get package info must return value');
        System.assertEquals(AccountHelper.SERVICE_TYPE_OFFICE, getPinfo.productName, 'Get package info product name must be "Office"');
        System.assertEquals(false, getPinfo.isPOC(), 'Offer type should be empty');
        getPinfo.productName = 'Test';
        pinfoNotEmpty.setPackageInfo(getPinfo);

        BillingWrappers.QuotePackageInfo getPinfoUpd = pinfoNotEmpty.getPackageInfo();
        System.assertEquals('Test', getPinfoUpd.productName, 'Package info product name must be "Test"');
        System.assertEquals('18', getPinfo.id, 'Get package info id must be 18');
        System.assertEquals(false, getPinfo.isPOC(), 'Offer type should be - ' + QuoteHelper.OFFER_TYPE_REGULAR);

        BillingWrappers.QuotePackageInfo pkgInfoForPOC = pinfoForPOC.getPackageInfo();
        System.assertEquals(AccountHelper.SERVICE_TYPE_OFFICE, pkgInfoForPOC.productName, 'Package info product name must be Office');
        System.assertEquals(true, pkgInfoForPOC.isPOC(), 'Offer type should be - ' + QuoteHelper.OFFER_TYPE_POC);

        List<BillingWrappers.QuotePackageInfo> getPinfoList = pinfoEmpty.parseQuotePackageInfo(NGBSTestDataGenerator.generateMultiProductQuotePackageInfo());
        System.assertEquals(4, getPinfoList.size(), 'Get package info list must be a list with size of 4');
    }

    @isTest
    private static void verifyQuotePackageInfoWrapperWithError() {

        PACKAGE_INFO = PACKAGE_INFO.replace('{','');
        try {
            BillingWrappers.QuotePackageInfoWrapper pinfoNotEmpty = new BillingWrappers.QuotePackageInfoWrapper(PACKAGE_INFO);
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage(), 'Parse exception must be returned');
            System.assertEquals(true, e.getMessage().contains('Failed to parse packagesInfo'), 'Exception message must contains "Failed to parse packagesInfo"');
        }
    }

    @isTest
    private static void verifyNGBSAccountPackageParse() {
        BillingWrappers.NGBSAccount ngbsAcc = (BillingWrappers.NGBSAccount) JSON.deserialize(NGBS_ACCOUNT_RESPONSE, BillingWrappers.NGBSAccount.class);

        BillingWrappers.NGBSAccountPackage ngbsAccPackage = ngbsAcc.getPackage();
        BillingWrappers.NGBSPackage ngbsPackage = (BillingWrappers.NGBSPackage) JSON.deserialize(NGBS_PACKAGE, BillingWrappers.NGBSPackage.class);
        System.assertNotEquals(null, ngbsAcc, 'NGBS Account must be returned');
        System.assertEquals('1', ngbsAcc.id, 'NGBS Account id must be "1"');
        System.assertNotEquals(null, ngbsAccPackage, 'NGBS Account package must be returned');
        System.assertNotEquals(null, ngbsPackage, 'NGBS package must be returned');
        System.assertEquals('2', ngbsPackage.id, 'NGBS package id must be "2"');
        System.assertEquals(true, ngbsPackage.isRegular(), 'NGBS package must be regular');
        System.assertEquals(false, ngbsPackage.isPOC(), 'NGBS package must not be PoC');
        System.assertEquals('2', ngbsAccPackage.id, 'NGBS Account package id must be "2"');
        System.assertEquals(true, ngbsAccPackage.isRegular(), 'NGBS Account package must be regular');
        System.assertEquals(false, ngbsAccPackage.isPOC(), 'NGBS Account package must not be PoC');

        ngbsAccPackage.offerType = 'ProofOfConcept';
        ngbsPackage.offerType = 'ProofOfConcept';

        System.assertEquals(false, ngbsPackage.isRegular(), 'NGBS package must not be regular');
        System.assertEquals(true, ngbsPackage.isPOC(), 'NGBS package must be PoC');
        System.assertEquals(false, ngbsAccPackage.isRegular(), 'NGBS Account package must not be regular');
        System.assertEquals(true, ngbsAccPackage.isPOC(), 'NGBS Account package must be PoC');

    }

    @isTest
    private static void testGetNGBSAccountPackageById() {
        BillingWrappers.NGBSAccount ngbsAcc = (BillingWrappers.NGBSAccount) JSON.deserialize(NGBS_ACCOUNT_WITH_MULTIPLE_PACKAGES, BillingWrappers.NGBSAccount.class);
        List<String> packageIds = new List<String> {
            '12345',
            '123456'
        };
        Assert.areEqual(2, ngbsAcc.packages.size(), 'NGBS Account should have 3 packages');
        for (String packageId : packageIds) {
            BillingWrappers.NGBSAccountPackage ngbsAccPackage = ngbsAcc.getPackageById(packageId);
            Assert.areNotEqual(null, ngbsAccPackage, 'NGBS Account package should be returned');
            Assert.areEqual(packageId, ngbsAccPackage.id, 'NGBS Account package id should be equal to packageInfo id');
        }
    }

    @isTest
    private static void testGetNGBSAccountPackageByIdNegative() {
        BillingWrappers.NGBSAccount ngbsAcc = (BillingWrappers.NGBSAccount) JSON.deserialize(NGBS_ACCOUNT_WITH_MULTIPLE_PACKAGES, BillingWrappers.NGBSAccount.class);
        BillingWrappers.NGBSAccountPackage ngbsAccPackage = ngbsAcc.getPackageById(null);
        Assert.areEqual(null, ngbsAccPackage, 'NGBS Account package should be returned');
    }

    // EB
    @isTest
    private static void verifyPackageIsActiveForEB() {
        String packageJson = '{"labels":{}}';
        BillingWrappers.NGBSPackage ngbsPackage = (BillingWrappers.NGBSPackage) JSON.deserialize(packageJson, BillingWrappers.NGBSPackage.class);
        System.assertEquals(false, ngbsPackage.isExpired(false, false), 'should be active based on upgradeWizardExpiration');
        System.assertEquals(false, ngbsPackage.isAboutToExpire(false, false), 'should be active based on upgradeWizardExpiration');
    }

    @isTest
    private static void verifyPackageIsAboutToExpireForEB() {
        String packageJson = '{"labels":{"UpgradeWizardExpiration":["AboutToExpire"]}}';
        BillingWrappers.NGBSPackage ngbsPackage = (BillingWrappers.NGBSPackage) JSON.deserialize(packageJson, BillingWrappers.NGBSPackage.class);
        System.assertEquals(false, ngbsPackage.isExpired(false, false), 'should not be expired based on upgradeWizardExpiration');
        System.assertEquals(true, ngbsPackage.isAboutToExpire(false, false), 'should be about to expire based on upgradeWizardExpiration');
    }

    @isTest
    private static void verifyPackageIsExpiredForEB() {
        String packageJson = '{"labels":{"UpgradeWizardExpiration":["Expired"]}}';
        BillingWrappers.NGBSPackage ngbsPackage = (BillingWrappers.NGBSPackage) JSON.deserialize(packageJson, BillingWrappers.NGBSPackage.class);
        System.assertEquals(true, ngbsPackage.isExpired(false, false), 'should be expired based on upgradeWizardExpiration');
        System.assertEquals(false, ngbsPackage.isAboutToExpire(false, false), 'should not be about to expire based on upgradeWizardExpiration');
    }

    // NB
    @isTest
    private static void verifyPackageIsActiveForNB() {
        String packageJson = '{"labels":{"SIGNUP_SFDC":["Active"],"SIGNUP_SFDCVAR":["Active"]}}';
        BillingWrappers.NGBSPackage ngbsPackage = (BillingWrappers.NGBSPackage) JSON.deserialize(packageJson, BillingWrappers.NGBSPackage.class);
        System.assertEquals(false, ngbsPackage.isExpired(true, true), 'should not be expired based on SIGNUP_SFDCVAR');
        System.assertEquals(false, ngbsPackage.isExpired(true, false), 'should not be expired based on SIGNUP_SFDC');
        System.assertEquals(false, ngbsPackage.isAboutToExpire(true, true), 'should not be about to expire based on SIGNUP_SFDCVAR');
        System.assertEquals(false, ngbsPackage.isAboutToExpire(true, false), 'should not be about to expire based on SIGNUP_SFDC');
    }

    @isTest
    private static void verifyPackageIsAboutToExpireForNB() {
        String packageJson = '{"labels":{"SIGNUP_SFDC":["About to Expire"],"SIGNUP_SFDCVAR":["About to Expire"]}}';
        BillingWrappers.NGBSPackage ngbsPackage = (BillingWrappers.NGBSPackage) JSON.deserialize(packageJson, BillingWrappers.NGBSPackage.class);
        System.assertEquals(false, ngbsPackage.isExpired(true, true), 'should not be expired based on SIGNUP_SFDCVAR');
        System.assertEquals(false, ngbsPackage.isExpired(true, false), 'should not be expired based on SIGNUP_SFDC');
        System.assertEquals(true, ngbsPackage.isAboutToExpire(true, true), 'should be about to expire based on SIGNUP_SFDCVAR');
        System.assertEquals(true, ngbsPackage.isAboutToExpire(true, false), 'should be about to expire based on SIGNUP_SFDC');
    }

    @isTest
    private static void verifyPackageIsExpiredForNB() {
        String packageJson = '{"labels":{"UpgradeWizardExpiration":["Expired"]}}';
        BillingWrappers.NGBSPackage ngbsPackage = (BillingWrappers.NGBSPackage) JSON.deserialize(packageJson, BillingWrappers.NGBSPackage.class);
        System.assertEquals(true, ngbsPackage.isExpired(true, true), 'should be expired based on SIGNUP_SFDCVAR');
        System.assertEquals(true, ngbsPackage.isExpired(true, false), 'should be expired based on SIGNUP_SFDC');
        System.assertEquals(false, ngbsPackage.isAboutToExpire(true, true), 'should not be about to expire based on SIGNUP_SFDCVAR');
        System.assertEquals(false, ngbsPackage.isAboutToExpire(true, false), 'should not be about to expire based on SIGNUP_SFDC');
    }

    @isTest
    private static void verifyLicensesRequestBodyParse() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Type => 'Syndicated - New',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Quote q = NGBSTestDataGenerator.createQuote(opp.Id);

        String testElementId = 'LC_DL_75';
        Test.startTest();
        QuoteLineItem qli = NGBSTestDataGenerator.createQLI('testProduct', testElementId, 'USD', acc, q);
        QuoteLineItem reselectQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectField('Product_Lic_Id__c')
            .executeQuery()
            .get(0);
        BillingWrappers.LicensesRequestBody licenseReqBody = new BillingWrappers.LicensesRequestBody(reselectQli.Product_Lic_Id__c);
        System.assertEquals(licenseReqBody.catalogId, testElementId, 'CatalogId must have value "LC_DL_75"');
        Test.stopTest();
    }

    @isTest
    private static void verifyLicensesCounterResponseParse() {
        List<BillingWrappers.LicensesCounterResponse> licensesList = (List<BillingWrappers.LicensesCounterResponse>) JSON.deserialize(LICENSES_COUNTER_RESPONSE, List<BillingWrappers.LicensesCounterResponse>.class);
        System.assertEquals(true, !licensesList.isEmpty(), 'Licenses list must return values');
        System.assertEquals(1, licensesList[0].instanceQty, 'InstanceQty must be 1');
        System.assertEquals(12, licensesList[0].batchQty, 'BatchQty must be 12');
        System.assertEquals(null, licensesList[0].billingCodeId, 'BillingCodeId must be null');
        System.assertEquals('DID', licensesList[0].categoryId, 'CategoryId must be "DID"');
        System.assertEquals('LC_DID_53', licensesList[0].catalogId, 'CatalogId must be "LC_DID_53"');
    }

    @isTest
    private static void verifyBillingInfoLicensesParseAndLicenseRequestedParse() {
        Map<String, Object> deserializedData = (Map<String, Object>) JSON.deserializeUntyped(BILLING_INFO_ALL_LICENSE_RESPONSE);
        BillingWrappers.BillingInfoLicenses bInfo = new BillingWrappers.BillingInfoLicenses(deserializedData);
        System.assertNotEquals(null, binfo, 'Binfo must be filled up');
        System.assertEquals(true, !binfo.licenses.isEmpty(), 'Licenses must be in the list');
        System.assertEquals('25309001', binfo.packageId, 'PackageId must have value "25309001"');
        System.assertEquals('369246001', binfo.licenses[0].topLicenseId, 'TopLicenseId must have value "369246001"');
        System.assertEquals('369246001', binfo.licenses[0].licenseId, 'LicenseId must have value "369246001"');
        System.assertEquals('27', binfo.licenses[0].licenseTypeId, 'LicenseTypeId must have value "27"');
    }

    @isTest
    private static void verifyQLIPackageInfoParse() {
        BillingWrappers.QLIPackageInfo qliPackageEmpty = new BillingWrappers.QLIPackageInfo();
        PACKAGE_INFO_QLI_WITH_LBOX = PACKAGE_INFO_QLI_WITH_LBOX.replace(Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_ONE_TIME);
        BillingWrappers.QLIPackageInfo qliPackage = new BillingWrappers.QLIPackageInfo(PACKAGE_INFO_QLI_WITH_LBOX);
        System.assertNotEquals(null, qliPackage, 'qliPackage must not be null');
        System.assertEquals(Product2Helper.CHARGE_TERM_ONE_TIME, qliPackage.duration, 'qliPackage duration must be "One - Time"');
        System.assertEquals('OneTime', qliPackage.getBillingDuration(), 'qliPackage duration must be "One - Time"');
        System.assertEquals('LC_DL_75', qliPackage.parent, 'qliPackage parent must be "LC_DL_75"');
        System.assertEquals('18', qliPackage.Id, 'qliPackage id must be "18"');
        qliPackage.duration = Product2Helper.CHARGE_TERM_MONTHLY;
        System.assertEquals(Product2Helper.CHARGE_TERM_MONTHLY, qliPackage.duration, 'qliPackage duration must be "Monthly"');
        System.assertEquals(Product2Helper.CHARGE_TERM_MONTHLY, qliPackage.getBillingDuration(), 'qliPackage duration must be "Monthly"');
    }

    @isTest
    private static void verifyQLIPackageInfoParseErrors() {
        PACKAGE_INFO_QLI_WITH_LBOX = PACKAGE_INFO_QLI_WITH_LBOX.replace('{','');
        try {
            BillingWrappers.QLIPackageInfo qliPackage = new BillingWrappers.QLIPackageInfo(PACKAGE_INFO_QLI_WITH_LBOX);
        } catch(Exception e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception must be thrown');
        }
    }

    @isTest
    private static void verifyBillingProductParse() {
        BillingWrappers.BillingProduct billProduct = (BillingWrappers.BillingProduct) JSON.deserialize(BILLING_PRODUCT_RESPONSE, BillingWrappers.BillingProduct.class);
        System.assertEquals('TestProduct', billProduct.name, 'Name must be "TestProduct"');
        System.assertEquals('LC_DL_75', billProduct.catalogId, 'CatalogId must be "LC_DL_75"');
        System.assertEquals('USD', billProduct.currencyIsoCode, 'currencyIsoCode must be "USD"');
        System.assertEquals('test', billProduct.goa, 'GOA must be "test"');
        System.assertEquals('DL', billProduct.categoryCode, 'CategoryCode must be "DL"');
        System.assertEquals('TestType', billProduct.itemType, 'ItemType must be "TestType"');
        System.assertEquals('Invoice', billProduct.billingType, 'BillingType must be "Invoice"');
    }

    @isTest
    private static void verifyCartItemParse() {
        BillingWrappers.CartItem cartItem = new BillingWrappers.CartItem();
        cartItem = (BillingWrappers.CartItem) JSON.deserialize(BILLING_CARTITEM, BillingWrappers.CartItem.class);

        System.assertEquals(12.12, cartItem.unitPrice, 'UnitPrice must be "12.12"');
        System.assertEquals(2, cartItem.sortOrder, 'SortOrder must be "2"');
        System.assertEquals(null, cartItem.salesEndDate, 'SalesEndDate must be null');
        System.assertEquals(12, cartItem.quantity, 'Quantity must be 12');
        System.assertEquals('testPackageInfo', cartItem.packageInfo, 'PackageInfo must be "testPackageInfo"');
        System.assertEquals('TestCartItem', cartItem.name, 'Name must be "TestCartItem"');
        System.assertEquals('TestType', cartItem.itemType, 'ItemType must be "TestType"');
        System.assertEquals(false, cartItem.isDeleted, 'IsDeleted must be false');
        System.assertEquals('18', cartItem.id, 'Id must be "18"');
        System.assertEquals('testGUID', cartItem.guid, 'GUID must be "testGUID"');
        System.assertEquals('test', cartItem.goa, 'GOA must be "test"');
        System.assertEquals('testCartItem', cartItem.displayName, 'Display Name must be "testCartItem"');
        System.assertEquals('Percentage', cartItem.discountType, 'Discount type must be "Percentage"');
        System.assertEquals(5.00, cartItem.discount, 'Discount must be 5.00');
        System.assertEquals('USD', cartItem.currencyIsoCode, 'currencyIsoCode must be "USD"');
        System.assertEquals('LC_DL_75', cartItem.catalogId, 'CatalogId must be "LC_DL_75"');
        System.assertEquals('Invoice', cartItem.billingType, 'BillingType must be "Invoice"');
        System.assertEquals(null, cartItem.billingPackage, 'Billing package must be null');
        System.assertEquals(Product2Helper.CHARGE_TERM_MONTHLY, cartItem.billingCycleDuration, 'Billing package must be "Monthly"');
        System.assertEquals('testSfPromoCodeId', cartItem.sfPromoCodeId, 'sfPromoCodeId must be "testSfPromoCodeId"');
    }

    @isTest
    private static void verifyParamsShippingParse() {
        BillingWrappers.ParamsShipping paramsShipping = new BillingWrappers.ParamsShipping();
        paramsShipping = (BillingWrappers.ParamsShipping) JSON.deserialize(PARAMS_SHIPPING, BillingWrappers.ParamsShipping.class);

        System.assertEquals('testAction', paramsShipping.action);
        System.assertEquals('testSelectedQuoteId', paramsShipping.selectedQuoteId);
        System.assertNotEquals(null, paramsShipping.shippingItemsMap.get('testKey1'));
        System.assertEquals('testQliId', paramsShipping.shippingItemsMap.get('testKey1')[0].quoteLineItemId);
        System.assertEquals(12, paramsShipping.shippingItemsMap.get('testKey1')[0].quantity);
        System.assertEquals('testLocId', paramsShipping.shippingItemsMap.get('testKey1')[0].locationID);
        System.assertEquals('testJuncId', paramsShipping.shippingItemsMap.get('testKey1')[0].junctionID);
        System.assertEquals(false, paramsShipping.shippingItemsMap.get('testKey1')[0].isDeleted);
        System.assertEquals('Ground', paramsShipping.shippingItemsMap.get('testKey1')[0].location.shippingMethod);
        System.assertEquals('testTree', paramsShipping.shippingItemsMap.get('testKey1')[0].location.shippingLicensesTree);
        System.assertEquals('testBillingCodeId', paramsShipping.shippingItemsMap.get('testKey1')[0].location.shippingBillingCodeId);
        System.assertEquals('testId', paramsShipping.shippingItemsMap.get('testKey1')[0].location.id);
        System.assertEquals('testContact', paramsShipping.shippingItemsMap.get('testKey1')[0].location.attentionTo);
        System.assertEquals('12345', paramsShipping.shippingItemsMap.get('testKey1')[0].location.address.zipCode);
        System.assertEquals('testState', paramsShipping.shippingItemsMap.get('testKey1')[0].location.address.state);
        System.assertEquals('testAddressId', paramsShipping.shippingItemsMap.get('testKey1')[0].location.address.id);
        System.assertEquals('testCountry', paramsShipping.shippingItemsMap.get('testKey1')[0].location.address.country);
        System.assertEquals('testCity', paramsShipping.shippingItemsMap.get('testKey1')[0].location.address.city);
        System.assertEquals('testAddress', paramsShipping.shippingItemsMap.get('testKey1')[0].location.address.addressLine);
        System.assertEquals(null, paramsShipping.shippingItemsMap.get('testKey1')[0].location.address.additionalAddressLine);
    }

    @isTest
    private static void verifyTaxLocationsResponseParse() {
        BillingWrappers.TaxLocationsResponse taxLocationResponse = new BillingWrappers.TaxLocationsResponse();
        taxLocationResponse = (BillingWrappers.TaxLocationsResponse) JSON.deserialize(TAX_LOCATIONS_RESPONSE, BillingWrappers.TaxLocationsResponse.class);

        System.assertEquals(true, !taxLocationResponse.addresses.isEmpty());
        System.assertEquals('testId', taxLocationResponse.addresses[0].id);
        System.assertEquals('testExtId', taxLocationResponse.addresses[0].externalId);
        System.assertEquals('1234', taxLocationResponse.addresses[0].address.zip);
        System.assertEquals('testStreet2', taxLocationResponse.addresses[0].address.street2);
        System.assertEquals('testStreet1', taxLocationResponse.addresses[0].address.street1);
        System.assertEquals('testState', taxLocationResponse.addresses[0].address.state);
        System.assertEquals('123456789', taxLocationResponse.addresses[0].address.phone);
        System.assertEquals('testLastName', taxLocationResponse.addresses[0].address.lastName);
        System.assertEquals('testLabel', taxLocationResponse.addresses[0].address.label);
        System.assertEquals('testAddId', taxLocationResponse.addresses[0].address.id);
        System.assertEquals('testFirstName', taxLocationResponse.addresses[0].address.firstName);
        System.assertEquals(null, taxLocationResponse.addresses[0].address.county);
        System.assertEquals('testCountry', taxLocationResponse.addresses[0].address.country);
        System.assertEquals('testCity', taxLocationResponse.addresses[0].address.city);
    }

    @isTest
    private static void verifyStepUpParse() {
        BillingWrappers.StepUp stepUp = new BillingWrappers.StepUp();
        stepUp = (BillingWrappers.StepUp) JSON.deserialize(STEP_UP, BillingWrappers.StepUp.class);
        System.assertEquals('2019-12-26', stepUp.stepUpDate, 'Step Up date must be "2019-12-26"');
        System.assertEquals(10, stepUp.stepDLs, 'Step Up DLs must be 10');
    }

    @isTest
    private static void verifyDeviceAvailabilityBody() {
        BillingWrappers.DeviceAvailabilityBody deviceAvailabilityBody = new BillingWrappers.DeviceAvailabilityBody('18', '3', new List<String>{'LC_HD_523'}, new List<String>{'AUT', 'USA'});
        System.assertEquals('licenseAvailabilityQualifier.getDevicesAllocationOnShippingCountriesEx', deviceAvailabilityBody.method, 'Method must be "licenseAvailabilityQualifier.getDevicesAllocationOnShippingCountriesEx"');
        System.assertEquals(1, deviceAvailabilityBody.params.deviceLicenseIds.size(), 'Device license Ids list must have 1 record');
        System.assertEquals(2, deviceAvailabilityBody.params.countriesAlpha3.size(), 'Countries list must have 2 records');
        System.assertEquals('18', deviceAvailabilityBody.params.brandContext.funnelPackage.packageId, 'Package Id must be "18"');
        System.assertEquals('3', deviceAvailabilityBody.params.brandContext.funnelPackage.packageVersion, 'Package version must be "3"');
    }

    @isTest
    private static void verifyDeviceAvailabilityResponse() {
        String responseBody = '{"result":{"devices":{"LC_HD_523":{"AUT":{"ruleType":2,"endOfSalesDate":"11\\/20\\/2021"},"USA":null}},"countries":{"AUT":{"name":"Austria","hasStates":false,"shippingLicenseIds":["LC_SHIPT_245"]},"USA":{"name":"United States","hasStates":true,"shippingLicenseIds":["LC_SHIPT_80","LC_SHIPT_81","LC_SHIPT_84"]}}},"SAFAS_SID":"606adf5dda75c5fdad4da91d966dd1ec24a43d8d7e3953222fc741cf75cc46eb","id":null}';
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        BillingWrappers.DeviceAvailabilityResponse deviceAvailability = new BillingWrappers.DeviceAvailabilityResponse((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(responseMap.get('result'))));
        System.assertEquals(true, deviceAvailability != null, 'Response must contains data about device availability');
        System.assertEquals(1, deviceAvailability.devices.size(), 'Devices must have 1 record');
        System.assertEquals(2, deviceAvailability.devices.get('LC_HD_523').size(), 'Device must have 2 countries');
        System.assertEquals(2, deviceAvailability.devices.get('LC_HD_523').get('AUT').ruleType, 'Device country AUT must have ruleType "2"');
        System.assertEquals('11/20/2021', deviceAvailability.devices.get('LC_HD_523').get('AUT').endOfSalesDate, 'Device country AUT must have end sales date "11/20/2021"');
        System.assertEquals(null, deviceAvailability.devices.get('LC_HD_523').get('USA'), 'Device country USA must have no rules');

        System.assertEquals(2, deviceAvailability.countries.size(), 'Countries must have 2 records');
        System.assertEquals(true, deviceAvailability.countries.containsKey('AUT'), 'Countries must have "AUT" key');
        System.assertEquals(1, deviceAvailability.countries.get('AUT').shippingLicenseIds.size(), '"AUT" must have 1 shipping license');
        System.assertEquals('Austria', deviceAvailability.countries.get('AUT').name, '"AUT" must have name "Austria"');
        System.assertEquals(false, deviceAvailability.countries.get('AUT').hasStates, '"AUT" must have false in hasStates param');
        System.assertEquals(true, deviceAvailability.countries.containsKey('USA'), 'Countries must have "USA" key');
        System.assertEquals(3, deviceAvailability.countries.get('USA').shippingLicenseIds.size(), '"USA" must have 3 shipping licenses');
        System.assertEquals('United States', deviceAvailability.countries.get('USA').name, '"USA" must have name "United States"');
        System.assertEquals(true, deviceAvailability.countries.get('USA').hasStates, '"USA" must have true in hasStates param');
    }

    @isTest
    private static void verifyNGBSShippingLicenseParse() {
        BillingWrappers.NGBSShippingLicense shippingLicense = new BillingWrappers.NGBSShippingLicense();
        shippingLicense = (BillingWrappers.NGBSShippingLicense) JSON.deserialize(SHIPPING_LICENSE_RESPONSE, BillingWrappers.NGBSShippingLicense.class);
        System.assertEquals('LC_SHIPT_81', shippingLicense.elementID, 'Element Id must be "LC_SHIPT_81"');
        System.assertEquals('Test Shipping Name - Ground', shippingLicense.name, 'Name must be "Test Shipping Name - Ground"');
        System.assertEquals('Test DisplayName', shippingLicense.displayName, 'Display name must be "Test DisplayName"');
        System.assertEquals('testBillingType', shippingLicense.billingType, 'Billing type must be "testBillingType"');
        System.assertNotEquals(null, shippingLicense.searchCategories, 'Search categories must have value');
        System.assertEquals(1, shippingLicense.searchCategories.size(), 'Search categories must have one element');
        System.assertEquals('GROUND', shippingLicense.searchCategories[0].value, 'Search category value must be "GROUND"');
        System.assertEquals('ShippingCode', shippingLicense.searchCategories[0].key, 'Search category key must be "ShippingCode"');
    }

    @isTest
    private static void verifyQuoteBusinessIdentity() {
        BillingWrappers.QuoteBusinessIdentity testBI = new BillingWrappers.QuoteBusinessIdentity('testId', 'USD');
        System.assertEquals('testId', testBI.biId, 'BI Id must be "testId"');
        System.assertEquals(RingCentralHelper.USD, testBI.biCurrency, 'BI Currence must be "USD"');
    }

    @isTest
    private static void verifyGWContractParse() {
        BillingWrappers.GWContract testGwContract = new BillingWrappers.GWContract();
        System.assertEquals(true, testGwContract.licences.isEmpty(), 'Licenses list must be empty');
        System.assertEquals(true, testGwContract.discounts.isEmpty(), 'Discounts list must be empty');

        BillingWrappers.GWContract testGwContractParse = (BillingWrappers.GWContract) JSON.deserialize(GW_CONTRACT, BillingWrappers.GWContract.class);

        System.assertEquals('testContractExtId', testGwContractParse.extId, 'Contract external id must be "testContractExtId"');
        System.assertEquals('testContractId', testGwContractParse.id, 'Contract id must be "testContractId"');
        System.assertEquals('test_gw_Contract', testGwContractParse.name, 'Contract name must be "test_gw_Contract"');
        System.assertEquals('1', testGwContractParse.packageVersion, 'Contract package version must be "1"');
        System.assertEquals(Date.valueOf('2019-12-26'), testGwContractParse.startDate, 'Contract start date must be "2019-12-26"');
        System.assertEquals(1.00, testGwContractParse.term, 'Contract term must be "1.00"');
        System.assertEquals(true, testGwContractParse.isActive, 'Contract term must be active');
        System.assertEquals(1, testGwContractParse.discounts.size(), 'Discounts must have 1 record');
        System.assertEquals(1, testGwContractParse.availableInPackages.size(), 'AvailableInPackages must have 1 record');
        System.assertEquals('18', testGwContractParse.availableInPackages[0], 'AvailableInPackages record must be "18"');
        System.assertEquals(1, testGwContractParse.billingCountries.size(), 'Billing Countries must have 1 record');
        System.assertEquals('USA', testGwContractParse.billingCountries[0], 'Billing Countries record must be "USA"');
        System.assertEquals(2, testGwContractParse.businessIdentitiesCountries.size(), 'BusinessIdentitiesCountries must have 2 records');
        System.assertEquals('USA', testGwContractParse.businessIdentitiesCountries[0], 'BusinessIdentitiesCountries record must be "USA"');
        System.assertEquals('Canada', testGwContractParse.businessIdentitiesCountries[1], 'BusinessIdentitiesCountries record must be "Canada"');
        System.assertEquals(1, testGwContractParse.licences.size(), 'Licenses list must have 1 record');
        System.assertEquals(Product2Helper.DL_UNL_ELEMENT_ID, testGwContractParse.licences[0], 'License must be "LC_DL-UNL_50"');
        System.assertEquals('testDiscId', testGwContractParse.discounts[0].id, 'Discount id must be "testDiscId"');
        System.assertEquals('testDiscDescr', testGwContractParse.discounts[0].description, 'Discount description must be "testTempl"');
        System.assertEquals('1', testGwContractParse.discounts[0].priority, 'Discount priority must be "1"');
        System.assertEquals('testPromo', testGwContractParse.discounts[0].promoCode, 'Discount promo code must "testPromo"');
        System.assertEquals(true, testGwContractParse.discounts[0].visible, 'Discount must be visible');
        System.assertEquals('18', testGwContractParse.discounts[0].target.catalogId, 'Discount target catalogId must be "18"');
        System.assertEquals('1', testGwContractParse.discounts[0].target.version, 'Discount target version must be "1"');
        System.assertEquals(1, testGwContractParse.discounts[0].discountTemplates.size(), 'Discounts must have 1 record');
        System.assertEquals(2.00, testGwContractParse.discounts[0].discountTemplates[0].id, 'Discount template id must be "2.00"');
        System.assertEquals('testTempl', testGwContractParse.discounts[0].discountTemplates[0].description, 'Discount template description must be "testTempl"');
        System.assertEquals('testId', testGwContractParse.discounts[0].discountTemplates[0].applicableTo.id, 'Discount template applicableTo id must be "testId"');
        System.assertEquals('testType', testGwContractParse.discounts[0].discountTemplates[0].applicableTo.type, 'Discount template applicableTo type must be "testType"');
        System.assertEquals(null, testGwContractParse.discounts[0].discountTemplates[0].applicationTerms.endDate, 'Discount template applicationTerms end date must be null');
        System.assertEquals('All', testGwContractParse.discounts[0].discountTemplates[0].applicationTerms.licenseScope, 'Discount template applicationTerms licenseScope must be "All"');
        System.assertEquals('1000', testGwContractParse.discounts[0].discountTemplates[0].applicationTerms.maxLicenses, 'Discount template applicationTerms maxLicenses must be "1000"');
        System.assertEquals(5.00, testGwContractParse.discounts[0].discountTemplates[0].values.get('test').value, 'Discount template values value must be "5.00"');
        System.assertEquals('Money', testGwContractParse.discounts[0].discountTemplates[0].values.get('test').unit, 'Discount template values unit must be "Money"');
        System.assertEquals(1.00, testGwContractParse.discounts[0].discountTemplates[0].values.get('test').recurringTerms.value, 'Discount template recurringTerms value must be "1.00"');
        System.assertEquals('Month', testGwContractParse.discounts[0].discountTemplates[0].values.get('test').recurringTerms.unit, 'Discount template recurringTerms unit must be "Month"');
    }

    @isTest
    private static void verifyGWDiscountCreation() {
        BillingWrappers.GWDiscount testDiscount = new BillingWrappers.GWDiscount();
        System.assertEquals('discount description', testDiscount.description, 'Discount description must be "discount description"');
        System.assertEquals('A', testDiscount.priority, 'Discount priority must be "A"');
        System.assertEquals(true, testDiscount.visible, 'Discount must be visible');
        System.assertEquals(true, testDiscount.discountTemplates.isEmpty(), 'Discount templates must be empty');
        System.assertNotEquals(null, testDiscount.target, 'Discount target must be not null but with empty values');
    }

    @isTest
    private static void verifyBillingContractLogic() {
        BillingWrappers.BillingContract testBillingContract = (BillingWrappers.BillingContract) JSON.deserialize(BILLING_CONTRACT, BillingWrappers.BillingContract.class);
        System.assertEquals('testBillingContractId', testBillingContract.id, 'Contract id must be "testBillingContractId"');
        System.assertEquals(1, testBillingContract.startBillingCycleNumber, 'Contract startBillingCycleNumber must be "1"');
        System.assertEquals(2, testBillingContract.term, 'Contract term must be "2"');
        System.assertEquals(Date.valueOf('2019-12-26'), testBillingContract.startDate, 'Contract startDate must be "2019-12-26"');

        // Test find contracts logic
        System.assertEquals(1, BillingWrappers.findActiveContracts(new List<BillingWrappers.BillingContract>{testBillingContract}).size(), 'Method must return one contract');
        System.assertEquals(null, BillingWrappers.findActiveContracts(new List<BillingWrappers.BillingContract>()), 'Method must return null');

        System.assertNotEquals(null, BillingWrappers.findClosestContractToDate(new List<BillingWrappers.BillingContract>{testBillingContract}, Date.valueOf('2019-12-28')), 'Method must return one contract because we in range active contract');
        System.assertNotEquals(null, BillingWrappers.findClosestContractToDate(new List<BillingWrappers.BillingContract>{testBillingContract}, Date.valueOf('2019-12-24')), 'Method must return one contract because contract start date is closer');
        testBillingContract.term = null;
        System.assertEquals(null, BillingWrappers.findClosestContractToDate(new List<BillingWrappers.BillingContract>{testBillingContract}, Date.valueOf('2019-12-28')), 'Method must return null, because term on contract equals null');
        System.assertEquals(null, BillingWrappers.findClosestContractToDate(null, null), 'Method must return null because we have no params for search');

        testBillingContract.startBillingCycleNumber = null;
        System.assertEquals(false, testBillingContract.isActiveContract(), 'Method must return false because we have startBillingCycleNumber null');

        testBillingContract.startBillingCycleNumber = -1;
        System.assertEquals(false, testBillingContract.isActiveContract(), 'Method must return false because we have startBillingCycleNumber less then 0');
    }

    @isTest
    private static void verifyGetShortQLIPackageInfoLogic() {
        BillingWrappers.QLIPackageInfo testQliPackageInfo = BillingWrappers.parseQLIPackageInfo(PACKAGE_INFO_QLI_WITH_LBOX);
        System.assertEquals(true, !testQliPackageInfo.lboxes.isEmpty(), 'Qli package info must have lboxes');
        System.assertEquals(22, testQliPackageInfo.isPhoneLeasingEnabled, 'Qli package info isPhoneLeasingEnabled must have value "22"');
        System.assertNotEquals(null, testQliPackageInfo.originalDiscount, 'Qli package info must have original discount');

        String packageInfo = BillingWrappers.getShortQLIPackageInfo(PACKAGE_INFO_QLI_WITH_LBOX);
        BillingWrappers.QLIPackageInfo testQliPackageInfo2 = BillingWrappers.parseQLIPackageInfo(packageInfo);
        System.assertEquals(null, testQliPackageInfo2.originalDiscount, 'Original discount must be null');
        System.assertEquals(null, testQliPackageInfo2.isPhoneLeasingEnabled, 'isPhoneLeasingEnabled must be null');
        System.assertEquals(null, testQliPackageInfo2.targetPriceCalculations, 'targetPriceCalculations must be null');
        System.assertEquals(null, testQliPackageInfo2.lboxes, 'Lboxes must be null');

        packageInfo = BillingWrappers.getShortQLIPackageInfo('');

        System.assertEquals('', packageInfo, 'Package info string must be blank');
    }

    @isTest
    private static void verifyDiscountTemplateGroupCreation() {
        BillingWrappers.DiscountTemplateGroup testDiscountTemplateGroup = new BillingWrappers.DiscountTemplateGroup('testOppId');
        System.assertNotEquals(null, testDiscountTemplateGroup.target, 'Target must be not null in discount template group');
        System.assertNotEquals(null, testDiscountTemplateGroup.startDate, 'Start date must be not null in discount template group');
        System.assertNotEquals(null, testDiscountTemplateGroup.endDate, 'End date must be not null in discount template group');
        System.assertEquals(true, testDiscountTemplateGroup.promoCode.contains('testOppId'), 'Promocode must contains "testOppId" value');
        System.assertEquals('Z', testDiscountTemplateGroup.priority, 'Priority must have "Z" value');
        System.assertEquals(2, testDiscountTemplateGroup.promoType.id, 'Promocode type id must have "2" value');
        System.assertEquals('Opportunity', testDiscountTemplateGroup.availability[0].type, 'Availability type must be "Opportunity"');
        System.assertEquals('testOppId', testDiscountTemplateGroup.availability[0].availableTo, 'Availability availableTo must be "testOppId"');
    }

    @isTest
    private static void verifyDiscountTemplateCreation() {
        BillingWrappers.DiscountTemplate testDiscountTemplate = new BillingWrappers.DiscountTemplate();
        System.assertNotEquals(null, testDiscountTemplate.applicableTo, 'ApplicableTo must be an empty DiscountApplication');
        System.assertNotEquals(null, testDiscountTemplate.applicationTerms, 'ApplicationTerms must be an empty DiscountApplicationTerms');
        System.assertNotEquals(null, testDiscountTemplate.values, 'Values must be an empty map');

        testDiscountTemplate.values.put('test', new BillingWrappers.DiscountValue());
        System.assertNotEquals(null, testDiscountTemplate.values.get('test').recurringTerms, 'Discount values map must be with empty recurringTerms');
    }

    @isTest
    private static void verifyGWDiscountTemplateCreation() {
        BillingWrappers.GWDiscountTemplate testGWDiscountTemplate = new BillingWrappers.GWDiscountTemplate();
        System.assertEquals('discount template', testGWDiscountTemplate.description, 'description must be "discount template"');
        System.assertEquals(null, testGWDiscountTemplate.applicableTo.id, 'applicableTo id must be null');
        System.assertEquals('CatalogId', testGWDiscountTemplate.applicableTo.type, 'applicableTo type must be "CatalogId"');
        System.assertNotEquals(null, testGWDiscountTemplate.applicationTerms.startDate, 'applicationTerms start date must be not null');
        System.assertEquals(null, testGWDiscountTemplate.applicationTerms.endDate, 'applicationTerms end date must be null');
        System.assertEquals('All', testGWDiscountTemplate.applicationTerms.licenseScope, 'applicationTerms licenseScope must be "All"');
        System.assertEquals(true, testGWDiscountTemplate.values.isEmpty(), 'values map must be empty');

        BillingWrappers.GWDiscountValue testGWDiscountValue = new BillingWrappers.GWDiscountValue();
        System.assertEquals('Money', testGWDiscountValue.unit, 'Unit must be "Money"');
        testGWDiscountValue.recurringTerms = new BillingWrappers.GWRecurringTerms();

        System.assertEquals('Months', testGWDiscountValue.recurringTerms.unit, 'Unit must be "Months"');
        System.assertEquals(1, testGWDiscountValue.recurringTerms.value, 'Value must be "1"');

        testGWDiscountTemplate.values.put('test',testGWDiscountValue);

        System.assertEquals(true, !testGWDiscountTemplate.values.isEmpty(), 'values map must be not empty');
    }

    @isTest
    private static void verifyDataParse() {
        BillingWrappers.Data testBillingCodesData = (BillingWrappers.Data) JSON.deserialize(BILLING_CODES_DATA, BillingWrappers.Data.class);
        System.assertEquals(true, !testBillingCodesData.Data.isEmpty(), 'Data list must have records');
    }

    @isTest
    private static void verifyParamsParsing() {
        BillingWrappers.Params testParams = (BillingWrappers.Params) JSON.deserialize(PARAMS_DATA, BillingWrappers.Params.class);
        System.assertEquals('testAction', testParams.action, 'Action must be "testAction"');
        System.assertEquals('testOppId', testParams.opportunityId, 'OpportunityId must be "testOppId"');
        System.assertEquals('quoteId', testParams.selectedQuoteId, 'selectedQuoteId must be "quoteId"');
        System.assertEquals('testRecordType', testParams.recordType, 'recordType must be "testRecordType"');
        System.assertEquals('testQuoteId', testParams.quoteId, 'quoteId must be "testQuoteId"');
        System.assertEquals('tempId', testParams.templateId, 'templateId must be "tempId"');
        System.assertEquals('testValue', testParams.templateParameters.get('testKey'), 'templateParameters must have "testValue" for key "testKey"');
        System.assertEquals('12', testParams.initialTerm, 'initialTerm must be "12"');
        System.assertEquals('1 Free Month of Service', testParams.specialTerms, 'specialTerms must be "1 Free Month of Service"');
        System.assertEquals('Free shipping', testParams.freeShippingTerms, 'freeShippingTerms must be "Free shipping"');
        System.assertEquals('testAccountId', testParams.accountId, 'accountId must be "testAccountId"');
        System.assertEquals('testPackageInfo', testParams.packageInfo, 'packageInfo must be "testPackageInfo"');
        System.assertEquals('testSubAction', testParams.subAction, 'subAction must be "testSubAction"');
        System.assertEquals('comment', testParams.actionComment, 'actionComment must be "comment"');
        System.assertEquals(QuoteHelper.STATUS_UPGRADE, testParams.status, 'status must be "Upgrade"');
        System.assertEquals('RingCentral', testParams.brand, 'brand must be "RingCentral"');
        System.assertEquals('testSubBrand', testParams.subBrand, 'subBrand must be "testSubBrand"');
        System.assertEquals('testQliValue', testParams.qliMap.get('testQliKey'), 'qliMap must have "testQliValue" for key "testQliKey"');
        System.assertEquals('testDataValue', testParams.data.get('testDataKey'), 'data must have "testDataValue" for key "testDataKey"');
        System.assertEquals(true, testParams.isUserCanApprove, 'isUserCanApprove must be true');
        System.assertEquals(false, testParams.isWizardHasErrors, 'isWizardHasErrors must be false');
        System.assertEquals(true, testParams.enabledLBO, 'enabledLBO must be true');
        System.assertEquals(true, testParams.isPrimaryQuote, 'isPrimaryQuote must be true');
        System.assertEquals(false, testParams.isRemoveAreaCodes, 'isRemoveAreaCodes must be false');
        System.assertEquals(true, testParams.selectedDocsIds.isEmpty(), 'selectedDocsIds must be empty');
        System.assertEquals(null, testParams.taxLocations, 'taxLocations must be null');
        System.assertEquals(null, testParams.envelopeId, 'envelopeId must be null');
        System.assertEquals(null, testParams.quoteIdSet, 'taxLocations must be quoteIdSet');
        System.assertEquals('Invoice', testParams.paymentMethod, 'paymentMethod must be "Invoice"');

        System.assertNotEquals(null, testParams.quote, 'quote must be not null');
        System.assertEquals('testQuoteId', testParams.quote.id, 'quote id must be "testQuoteId"');
        System.assertEquals('[{"id":"18","version":"1"}]', testParams.quote.packageInfo, 'quote packageInfo must be "[{"id":"18","version":"1"}]"');
        System.assertEquals('testQuote', testParams.quote.name, 'quote name must be "testQuote"');
        System.assertEquals('2021-12-06', testParams.quote.expirationDate, 'quote expirationDate must be "2021-12-06"');
        System.assertEquals('Quote', testParams.quote.quoteType, 'quote type must be "Quote"');
        System.assertEquals('Draft', testParams.quote.status, 'quote status must be "Draft"');
        System.assertEquals('12', testParams.quote.initialTerm, 'quote initialTerm must be "12"');
        System.assertEquals('1', testParams.quote.initialTermPOC, 'quote initialTermPOC must be "1"');
        System.assertEquals('24', testParams.quote.renewalTerm, 'quote renewalTerm must be "24"');
        System.assertEquals(true, testParams.quote.autoRenewal, 'quote autoRenewal must be true');
        System.assertEquals('2021-12-29', testParams.quote.startDate, 'quote startDate must be "2021-12-29"');
        System.assertEquals('2023-12-29', testParams.quote.endDate, 'quote endDate must be "2023-12-29"');
        System.assertEquals('1 Free Month of Service', testParams.quote.specialTerms, 'quote specialTerms must be "1 Free Month of Service"');
        System.assertEquals('Free shipping', testParams.quote.freeShippingTerms, 'quote freeShippingTerms must be "Free shipping"');
        System.assertEquals('New', testParams.quote.upsellStatus, 'quote upsellStatus must be "New"');
        System.assertEquals(false, testParams.quote.isTaxesAdded, 'quote isTaxesAdded must be false');
        System.assertEquals(true, testParams.quote.enabledLBO, 'quote enabledLBO must be true');
        System.assertEquals(false, testParams.quote.isLBODealDeskProvision, 'quote isLBODealDeskProvision must be false');
        System.assertEquals(false, testParams.quote.doNotSendOrderToNGBS, 'quote doNotSendOrderToNGBS must be false');
        System.assertEquals('testJustification', testParams.quote.justification, 'quote justification must be "testJustification"');
        System.assertEquals('testMainAreaCodeId', testParams.quote.mainAreaCodeId, 'quote mainAreaCodeId must be "testMainAreaCodeId"');
        System.assertEquals('testFaxAreaCodeId', testParams.quote.faxAreaCodeId, 'quote faxAreaCodeId must be "testFaxAreaCodeId"');
        System.assertEquals('test', testParams.quote.opportunityProvisioningDetails, 'quote opportunityProvisioningDetails must be "test"');
        System.assertEquals('testFaxAreaCodeId', testParams.quote.faxAreaCodeId, 'quote faxAreaCodeId must be "testFaxAreaCodeId"');
        System.assertEquals('test contact', testParams.quote.shippingShipAttentionTo, 'quote shippingShipAttentionTo must be "test contact"');
        System.assertEquals('USA', testParams.quote.shippingCountry, 'quote shippingCountry must be "USA"');
        System.assertEquals('Belmont', testParams.quote.shippingCity, 'quote shippingCity must be "Belmont"');
        System.assertEquals('CA', testParams.quote.shippingState, 'quote shippingState must be "CA"');
        System.assertEquals('testStreet', testParams.quote.shippingAddressLine, 'quote shippingAddressLine must be "testStreet"');
        System.assertEquals('1233', testParams.quote.shippingPostalCode, 'quote shippingPostalCode must be "1233"');
        System.assertEquals(null, testParams.quote.shippingAdditionalAddressLine, 'quote shippingAdditionalAddressLine must be null');
        System.assertEquals('testCompany', testParams.quote.shippingCustomerName, 'quote shippingCustomerName must be "testCompany"');
        System.assertEquals('Ground', testParams.quote.shippingShippingOption, 'quote shippingShippingOption must be "Ground"');
        System.assertEquals(false, testParams.quote.shippingMultipleLocations, 'quote shippingMultipleLocations must be false');
        System.assertEquals(false, testParams.quote.opportunitySelfProvisioned, 'quote opportunitySelfProvisioned must be false');
        System.assertNotEquals(null, testParams.quote.faxAreaCodeInfo, 'quote faxAreaCodeInfo must be not null');
        System.assertEquals('USA', testParams.quote.faxAreaCodeInfo.country, 'quote faxAreaCodeInfo country must be "USA"');
        System.assertEquals('CA', testParams.quote.faxAreaCodeInfo.state, 'quote faxAreaCodeInfo state must be "CA"');
        System.assertEquals('Belmont', testParams.quote.faxAreaCodeInfo.city, 'quote faxAreaCodeInfo city must be "Belmont"');
        System.assertEquals('Local', testParams.quote.faxAreaCodeInfo.type, 'quote faxAreaCodeInfo type must be "Local"');
        System.assertEquals(12, testParams.quote.faxAreaCodeInfo.areaCode, 'quote faxAreaCodeInfo type must be "12"');
        System.assertNotEquals(null, testParams.quote.mainAreaCodeInfo, 'quote mainAreaCodeInfo must be not null');
        System.assertEquals('USA', testParams.quote.mainAreaCodeInfo.country, 'quote mainAreaCodeInfo country must be "USA"');
        System.assertEquals('CA', testParams.quote.mainAreaCodeInfo.state, 'quote mainAreaCodeInfo state must be "CA"');
        System.assertEquals('Belmont', testParams.quote.mainAreaCodeInfo.city, 'quote mainAreaCodeInfo city must be "Belmont"');
        System.assertEquals('Local', testParams.quote.mainAreaCodeInfo.type, 'quote mainAreaCodeInfo type must be "Local"');
        System.assertEquals(12, testParams.quote.mainAreaCodeInfo.areaCode, 'quote mainAreaCodeInfo type must be "12"');
        System.assertEquals(12000.00, testParams.quote.creditAmount, 'quote creditAmount must be "12000"');
        System.assertEquals(12.00, testParams.quote.freeServiceTaxes, 'quote creditAmount must be "12"');
        System.assertEquals(false, testParams.quote.isFullCalculationFSC, 'quote isFullCalculationFSC must be false');
        System.assertEquals(null, testParams.quote.parentQuoteId, 'quote parentQuoteId must be null');
        System.assertEquals('Invoice', testParams.quote.paymentMethod, 'quote paymentMethod must be "Invoice"');
        System.assertEquals(null, testParams.quote.rcAccountNumber, 'quote rcAccountNumber must be null');
        System.assertEquals(null, testParams.quote.ccAccountNumber, 'quote ccAccountNumber must be null');
        System.assertEquals(false, testParams.quote.isTerminationOpportunity, 'quote isTerminationOpportunity must be false');

        System.assertEquals(true, testParams.items != null && !testParams.items.isEmpty(), 'items must have values');
        System.assertEquals(1, testParams.items.size(), 'items must have 1 record');
        System.assertEquals('LC_DL_75', testParams.items[0].catalogId, 'item catalogId must be "LC_DL_75"');
        System.assertEquals('USD', testParams.items[0].currencyIsoCode, 'item currencyIsoCode must be "USD"');
        System.assertEquals('test', testParams.items[0].goa, 'item goa must be "test"');
        System.assertEquals('TestCartItem', testParams.items[0].name, 'item name must be "TestCartItem"');
        System.assertEquals('TestType', testParams.items[0].itemType, 'item itemType must be "TestType"');
        System.assertEquals('Invoice', testParams.items[0].billingType, 'item billingType must be "Invoice"');
        System.assertEquals('Monthly', testParams.items[0].billingCycleDuration, 'item billingCycleDuration must be "Monthly"');
        System.assertEquals(12, testParams.items[0].quantity, 'item quantity must be "12"');
        System.assertEquals(12.12, testParams.items[0].unitPrice, 'item unitPrice must be "12.12"');
        System.assertEquals(5.00, testParams.items[0].discount, 'item discount must be "5.00"');
        System.assertEquals('Percentage', testParams.items[0].discountType, 'item discountType must be "Percentage"');
        System.assertEquals('testPackageInfo', testParams.items[0].packageInfo, 'item packageInfo must be "testPackageInfo"');
        System.assertEquals('18', testParams.items[0].id, 'item id must be "18"');
        System.assertEquals(false, testParams.items[0].isDeleted, 'item isDeleted must be false');
        System.assertEquals('testGUID', testParams.items[0].guid, 'item guid must be "testGUID"');
        System.assertEquals('testCartItem', testParams.items[0].displayName, 'item displayName must be "testCartItem"');
        System.assertEquals(2, testParams.items[0].sortOrder, 'item sortOrder must be "2"');
        System.assertEquals(null, testParams.items[0].salesEndDate, 'item salesEndDate must be null');
        System.assertEquals('testSfPromoCodeId', testParams.items[0].sfPromoCodeId, 'item sfPromoCodeId must be "testSfPromoCodeId"');
        System.assertEquals(2, testParams.items[0].sortOrder, 'item sortOrder must be "2"');

        System.assertEquals(true, testParams.areaCodeLineItems != null && !testParams.areaCodeLineItems.isEmpty(), 'areaCodeLineItems must have values');
        System.assertEquals('testareacodeId', testParams.areaCodeLineItems[0].id, 'areaCodeLineItem id must be "testareacodeId"');
        System.assertEquals('LC_DL-UNL_50', testParams.areaCodeLineItems[0].cartItemCatalogId, 'areaCodeLineItem cartItemCatalogId must be "LC_DL-UNL_50"');
        System.assertEquals(12, testParams.areaCodeLineItems[0].quantity, 'areaCodeLineItem quantity must be "12"');
        System.assertEquals('testAreaCodeId', testParams.areaCodeLineItems[0].areaCodeId, 'areaCodeLineItem areaCodeId must be "testAreaCodeId"');
        System.assertEquals(false, testParams.areaCodeLineItems[0].isDeleted, 'areaCodeLineItem isDeleted must be false');
        System.assertEquals('USA', testParams.areaCodeLineItems[0].areaCodeInfo.country, 'areaCodeLineItem country must be "USA"');
        System.assertEquals('CA', testParams.areaCodeLineItems[0].areaCodeInfo.state, 'areaCodeLineItem state must be "CA"');
        System.assertEquals('Belmont', testParams.areaCodeLineItems[0].areaCodeInfo.city, 'areaCodeLineItem city must be "Belmont"');
        System.assertEquals('Local', testParams.areaCodeLineItems[0].areaCodeInfo.type, 'areaCodeLineItem type must be "Local"');
        System.assertEquals(12, testParams.areaCodeLineItems[0].areaCodeInfo.areaCode, 'areaCodeLineItem areaCode must be "12"');

        System.assertEquals(true, testParams.entitlements != null && !testParams.entitlements.isEmpty(), 'entitlements must have values');
        System.assertEquals('LC_SC_29', testParams.entitlements[0].elementId, 'entitlement id must be "LC_SC_29"');
        System.assertEquals('testEntName', testParams.entitlements[0].name, 'entitlement name must be "testEntName"');
        System.assertEquals(1, testParams.entitlements[0].quantity, 'entitlement quantity must be "1"');
        System.assertEquals(3.50, testParams.entitlements[0].unitPrice, 'entitlement unitPrice must be "3.50"');
        System.assertEquals(3.50, testParams.entitlements[0].effectivePrice, 'entitlement effectivePrice must be "3.50"');
        System.assertEquals('Monthly', testParams.entitlements[0].duration, 'entitlement duration must be "Monthly"');
        System.assertEquals('Currency', testParams.entitlements[0].discount.type, 'entitlement discount type must be "Currency"');
        System.assertEquals(5, testParams.entitlements[0].discount.value, 'entitlement discount value must be "5"');
        System.assertEquals('18', testParams.entitlements[0].billingPackage.catalogId, 'entitlement billingPackage catalogId must be "18"');
        System.assertEquals('1', testParams.entitlements[0].billingPackage.version, 'entitlement billingPackage version must be "1"');
        System.assertEquals('USD', testParams.entitlements[0].billingPackage.currencyCode, 'entitlement billingPackage currencyCode must be "USD"');
        System.assertEquals('testEnt', testParams.entitlements[0].displayName, 'entitlement displayName must be "testEnt"');
        System.assertEquals(1, testParams.entitlements[0].sortOrder, 'entitlement sortOrder must be "1"');

        System.assertEquals(true, testParams.products != null && !testParams.products.isEmpty(), 'products must have values');
        System.assertEquals('LC_DL_75', testParams.products[0].catalogId, 'product catalogId must be "LC_DL_75"');
        System.assertEquals('USD', testParams.products[0].currencyIsoCode, 'product currencyIsoCode must be "USD"');
        System.assertEquals('test', testParams.products[0].goa, 'product goa must be "test"');
        System.assertEquals('TestProduct', testParams.products[0].name, 'product name must be "TestProduct"');
        System.assertEquals('DL', testParams.products[0].categoryCode, 'product categoryCode must be "DL"');
        System.assertEquals('TestType', testParams.products[0].itemType, 'product itemType must be "TestType"');
        System.assertEquals('Invoice', testParams.products[0].billingType, 'product billingType must be "Invoice"');

        System.assertEquals(true, testParams.stepUps != null && !testParams.stepUps.isEmpty(), 'stepUps must have values');
        System.assertEquals('2019-12-26', testParams.stepUps[0].stepUpDate, 'stepUp stepUpDate must be "2019-12-26"');
        System.assertEquals(10.00, testParams.stepUps[0].stepDLs, 'stepUp stepDLs must be "10.00"');

        System.assertEquals(true, testParams.billingCodes != null && !testParams.billingCodes.isEmpty(), 'billingCodes must have values');
        System.assertEquals('testGuid', testParams.billingCodes[0].guid, 'billingCode guid must be "testGuid"');
        System.assertEquals('testId', testParams.billingCodes[0].Id, 'billingCode Id must be "testId"');
        System.assertEquals(null, testParams.billingCodes[0].parentId, 'billingCode parentId must be null');
        System.assertEquals(null, testParams.billingCodes[0].parentXid, 'billingCode parentXid must be null');
        System.assertEquals('123', testParams.billingCodes[0].billingId, 'billingCode billingId must be "123"');
        System.assertEquals('testBillingCode', testParams.billingCodes[0].name, 'billingCode name must be "testBillingCode"');
        System.assertEquals(12.00, testParams.billingCodes[0].depth, 'billingCode depth must be "12.00"');
        System.assertEquals(null, testParams.billingCodes[0].parentBillingId, 'billingCode parentBillingId must be null');
        System.assertEquals('testAddrId', testParams.billingCodes[0].addressId, 'billingCode addressId must be "testAddrId"');
        System.assertEquals(null, testParams.billingCodes[0].location, 'billingCode location must be null');
        System.assertEquals(null, testParams.billingCodes[0].bundles, 'billingCode bundles must be null');
        System.assertEquals(null, testParams.billingCodes[0].child, 'billingCode child must be null');
        System.assertEquals(null, testParams.billingCodes[0].billingCodePath, 'billingCode billingCodePath must be null');

        System.assertNotEquals(null, testParams.areaCodeItem, 'areaCodeItem must be not null');
        System.assertEquals('USA', testParams.areaCodeItem.country, 'areaCodeItem country must be "USA"');
        System.assertEquals('CA', testParams.areaCodeItem.state, 'areaCodeItem state must be "CA"');
        System.assertEquals('Belmont', testParams.areaCodeItem.city, 'areaCodeItem city must be "Belmont"');
        System.assertEquals('Local', testParams.areaCodeItem.type, 'areaCodeItem type must be "Local"');
        System.assertEquals(12, testParams.areaCodeItem.areaCode, 'areaCodeItem type must be "12"');

        System.assertEquals(true, testParams.promotionList != null && !testParams.promotionList.isEmpty(), 'promotionList must have values');
        System.assertEquals('testPromId', testParams.promotionList[0].id, 'promotion id must be "testPromId"');
        System.assertEquals('2019-12-26', testParams.promotionList[0].startDate, 'promotion startDate must be "2019-12-26"');
        System.assertEquals('2020-12-26', testParams.promotionList[0].endDate, 'promotion endDate must be "2020-12-26"');
        System.assertEquals('Z', testParams.promotionList[0].priority, 'promotion priority must be "Z"');
        System.assertEquals('testPromocodeId', testParams.promotionList[0].promoCodeId, 'promotion promoCodeId must be "testPromocodeId"');
        System.assertEquals('testPromoCode', testParams.promotionList[0].promoCode, 'promotion promoCode must be "testPromoCode"');
        System.assertEquals('testPromo', testParams.promotionList[0].name, 'promotion name must be "testPromo"');
        System.assertEquals('testDiscountTempl', testParams.promotionList[0].discountTemplates, 'promotion discountTemplates must be "testDiscountTempl"');
        System.assertEquals('testDescr', testParams.promotionList[0].description, 'promotion description must be "testDescr"');
        System.assertEquals('testQtId', testParams.promotionList[0].quoteId, 'promotion quoteId must be "testQtId"');

        System.assertNotEquals(null, testParams.approvalParams, 'approvalParams must be not null');
        System.assertEquals('testAccId', testParams.approvalParams.accountId, 'approvalParams accountId must be "testAccId"');
        System.assertEquals('move to invoice', testParams.approvalParams.action, 'approvalParams action must be "move to invoice"');
        System.assertEquals('Invoicing Request', testParams.approvalParams.recordType, 'approvalParams recordType must be "Invoicing Request"');
        System.assertEquals(null, testParams.approvalParams.accountPartnerId, 'approvalParams accountPartnerId must be null');
    }

    @isTest
    private static void verifyBuildSobjectMethodBuildsTheCorrectRecord() {
        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Id => ValueProviderBuilder.provideDummyId(DQ_Deal_Qualification__c.SObjectType),
                DQ_Deal_Qualification__c.Opportunity__c => ValueProviderBuilder.provideDummyId(Opportunity.SObjectType),
                DQ_Deal_Qualification__c.Status__c => 'New',
                DQ_Deal_Qualification__c.Charge_Term__c => 'Annual',
                DQ_Deal_Qualification__c.Renewal_Term__c => '12',
                DQ_Deal_Qualification__c.Initial_Term__c => '12',
                DQ_Deal_Qualification__c.CC_Initial_Term__c => 'None',
                DQ_Deal_Qualification__c.Special_Terms__c => '2 Free Months of Service',
                DQ_Deal_Qualification__c.Deal_Size__c => 500,
                DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c => 50
            })
            .build()
            .getRecord();

        BillingWrappers.DealQualification dqWrapper = new BillingWrappers.DealQualification(testDqRecord);
        dqWrapper.status = 'Revision Pending';
        dqWrapper.chargeTerm = 'Monthly';
        dqWrapper.renewalTerm = '24';
        dqWrapper.initialTerm = '24';
        dqWrapper.initialTermCC = '12';
        dqWrapper.specialTerms = '4 Free Months of Service';
        dqWrapper.specialTermsCC = '4 Free Months of Service';
        dqWrapper.dealSize = 700;
        dqWrapper.newAnnualRecurringCharges = 100;

        DQ_Deal_Qualification__c updatedDQRecord = dqWrapper.buildSobject();

        System.assertEquals(
            dqWrapper.dqId,
            updatedDQRecord.Id,
            'Id of updated DQ_Deal_Qualification__c should stay the same'
        );
        System.assertEquals(
            dqWrapper.status,
            updatedDQRecord.Status__c,
            'DQ_Deal_Qualification__c.Status__c field value should be updated and should match the "status" field value from wrapper'
        );
        System.assertEquals(
            dqWrapper.chargeTerm,
            updatedDQRecord.Charge_Term__c,
            'DQ_Deal_Qualification__c.Charge_Term__c field value should be updated and should match the "chargeTerm" field value from wrapper'
        );
        System.assertEquals(
            dqWrapper.renewalTerm,
            updatedDQRecord.Renewal_Term__c,
            'DQ_Deal_Qualification__c.Renewal_Term__c field value should be updated and should match the "renewalTerm" field value from wrapper'
        );
        System.assertEquals(
            dqWrapper.initialTerm,
            updatedDQRecord.Initial_Term__c,
            'DQ_Deal_Qualification__c.Initial_Term__c field value should be updated and should match the "initialTerm" field value from wrapper'
        );
        System.assertEquals(
            dqWrapper.initialTermCC,
            updatedDQRecord.CC_Initial_Term__c,
            'DQ_Deal_Qualification__c.CC_Initial_Term__c field value should be updated and should match the "initialTermCC" field value from wrapper'
        );
        System.assertEquals(
            dqWrapper.specialTerms,
            updatedDQRecord.Special_Terms__c,
            'DQ_Deal_Qualification__c.Special_Terms__c field value should be updated and should match the "specialTerms" field value from wrapper'
        );
        System.assertEquals(
            dqWrapper.specialTermsCC,
            updatedDQRecord.CC_Special_Terms__c,
            'DQ_Deal_Qualification__c.CC_Special_Terms__c field value should be updated and should match the "specialTermsCC" field value from wrapper'
        );
        System.assertEquals(
            dqWrapper.dealSize,
            updatedDQRecord.Deal_Size__c,
            'DQ_Deal_Qualification__c.Deal_Size__c field value should be updated and should match the "dealSize" field value from wrapper'
        );
        System.assertEquals(
            dqWrapper.newAnnualRecurringCharges,
            updatedDQRecord.New_Annual_Recurring_Charges__c,
            'DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c field value should be updated and should match the "newAnnualRecurringCharges" field value from wrapper'
        );
    }

    @isTest
    private static void verifyProservParam() {
        BillingWrappers.ProservParam testProservParam = (BillingWrappers.ProservParam) JSON.deserialize(PROSERV_PARAM, BillingWrappers.ProservParam.class);
        System.assertEquals(true, testProservParam.isSignUpCompleted, 'isSignUpCompleted should be true');
        System.assertEquals('12345', testProservParam.accountPackageId, 'accountPackageId should be 12345');
    }

//    @isTest
//    private static void verifyUpdateSobjectFieldsMethodBuildsTheCorrectRecord() {
//        DQ_Deal_Qualification_Discounts__c dqDiscountRecord = (DQ_Deal_Qualification_Discounts__c) new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
//            .setFields(new Map<SObjectField, Object>{
//                DQ_Deal_Qualification_Discounts__c.Id => ValueProviderBuilder.provideDummyId(DQ_Deal_Qualification_Discounts__c.SObjectType),
//                DQ_Deal_Qualification_Discounts__c.RecordTypeId => OpportunityService.DQ_SALES_RECORD_TYPE_ID,
//                DQ_Deal_Qualification_Discounts__c.Product__c => ValueProviderBuilder.provideDummyId(Product2.SObjectType),
//                DQ_Deal_Qualification_Discounts__c.OriginalPackageId__c => '1952',
//                DQ_Deal_Qualification_Discounts__c.OriginalPackageVersion__c => '2',
//                DQ_Deal_Qualification_Discounts__c.OriginalPackageName__c => 'test Package',
//                DQ_Deal_Qualification_Discounts__c.PackageName__c => 'test Package',
//                DQ_Deal_Qualification_Discounts__c.Product_Category__c => 'GOA_Devices',
//                DQ_Deal_Qualification_Discounts__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
//                DQ_Deal_Qualification_Discounts__c.Discount__c => 5,
//                DQ_Deal_Qualification_Discounts__c.Quantity__c => 10
//            })
//            .build()
//            .getRecord();
//
//        dqDiscountRecord.Product__r = (Product2) new SObjectBuilder(Product2.SObjectType)
//            .setFields(new Map<SObjectField, Object>{
//                Product2.Name => ValueProviderBuilder.provideUniqueString('test product')
//            })
//            .build()
//            .getRecord();
//
//        BillingWrappers.DealQualificationDiscount dqDiscountWrapper = new BillingWrappers.DealQualificationDiscount(dqDiscountRecord);
//        dqDiscountWrapper.originalPackageId = '2222';
//        dqDiscountWrapper.originalPackageVersion = '1';
//        dqDiscountWrapper.originalPackageName = 'updated package';
//        dqDiscountWrapper.packageName = 'updated package';
//        dqDiscountWrapper.productCategory = 'GOA_Devices';
//        dqDiscountWrapper.discountType = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
//        dqDiscountWrapper.discount = 20;
//        dqDiscountWrapper.quantity = 100;
//
//        DQ_Deal_Qualification_Discounts__c updatedDiscount = dqDiscountWrapper.updateSobjectFields(dqDiscountRecord, null);
//        System.assertEquals(
//            dqDiscountWrapper.originalPackageId,
//            updatedDiscount.OriginalPackageId__c,
//            'DQ_Deal_Qualification_Discounts__c.OriginalPackageId__c field value should be updated and should match the "originalPackageId" field value from wrapper'
//        );
//        System.assertEquals(
//            dqDiscountWrapper.originalPackageVersion,
//            updatedDiscount.OriginalPackageVersion__c,
//            'DQ_Deal_Qualification_Discounts__c.OriginalPackageVersion__c field value should be updated and should match the "originalPackageVersion" field value from wrapper'
//        );
//        System.assertEquals(
//            dqDiscountWrapper.originalPackageName,
//            updatedDiscount.OriginalPackageName__c,
//            'DQ_Deal_Qualification_Discounts__c.OriginalPackageName__c field value should be updated and should match the "originalPackageName" field value from wrapper'
//        );
//        System.assertEquals(
//            dqDiscountWrapper.packageName,
//            updatedDiscount.PackageName__c,
//            'DQ_Deal_Qualification_Discounts__c.PackageName__c field value should be updated and should match the "packageName" field value from wrapper'
//        );
//        System.assertEquals(
//            dqDiscountWrapper.discountType,
//            updatedDiscount.Discount_Type__c,
//            'DQ_Deal_Qualification_Discounts__c.Discount_Type__c field value should be updated and should match the "discountType" field value from wrapper'
//        );
//        System.assertEquals(
//            dqDiscountWrapper.discount,
//            updatedDiscount.Discount__c,
//            'DQ_Deal_Qualification_Discounts__c.Discount__c field value should be updated and should match the "discount" field value from wrapper'
//        );
//        System.assertEquals(
//            dqDiscountWrapper.quantity,
//            updatedDiscount.Quantity__c,
//            'DQ_Deal_Qualification_Discounts__c.Quantity__c field value should be updated and should match the "quantity" field value from wrapper'
//        );
//    }
}