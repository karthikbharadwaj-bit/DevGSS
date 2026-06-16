@isTest
private class Test_SyncWithNGBS {
    private static final String PACKAGE_ID = '1389379001';
    private static final String PACKAGE_CATALOG_ID = '18';
    private static final String PACKAGE_CHANGED_CATALOG_ID = '15';
    private static final String PACKAGE_VERSION = '1';
    private static final String PACKAGE_DURATION = Product2Helper.CHARGE_TERM_MONTHLY;
    private static final String PRODUCT_ANNUAL_NAME = 'Annual Product';
    private static final String PRODUCT_MONTHLY_NAME = 'Monthly Product';
    private static final String PRODUCT_DIGITALLINE_UNLIMITED = 'DigitalLine Unlimited';
    private static final String PRODUCT_DIGITALLINE = 'DigitalLine';
    private static final String ENTITLEMENT_NAME = 'Entitlement Name';
    private static final String OPP_NAME = 'oppName';
    private static final String ACC_NAME = 'accName';
    private static final String QUOTE_NAME = 'Test Quote';
    private static final String QLI_NAME = 'Test Qli';
    private static final String TEST_SCENARIO_NAME = 'Test Scenario';
    private static final String BATCH_QTY = '15';
    private static final String POC_OPP_NAME = 'oppNamePOC';
    private static final String TERMINATION_OPP_NAME = 'oppTermination';
    private static final String FEDRAMP_OPP_NAME = 'oppFedramp';
    private static final String BILLING_ID = (String) ValueProviderBuilder.provideUniqueString().getValue();
    private static final String CHANGED_BILLING_ID = '1239';
    private static final String LBOX_ELEMENT_ID = 'LB_702';
    private static String LABEL_VALUE = BillingWrappers.EXPIRATION_TYPE_EXPIRED;
    private static final String PACKAGE_INFO =
        '[{"id":"18","version":"1","packageInfo":{"id":' + PACKAGE_ID + ',"catalogId":"' +
            PACKAGE_CATALOG_ID + '","version":"' + PACKAGE_VERSION + '"},"productName":"Office"' +
            ',"duration":"' + PACKAGE_DURATION + '","edition":{"id":1,"name":"Standard"},"contract":' +
            '{"id":"a8f0S0000008cxHQAQ","extId":"nib","billingId":' + CHANGED_BILLING_ID +
            '},"offerType":"Regular","globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":' +
            '"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":' +
            '"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
            '"override":false}],"permissions":null,"discountTemplates":[{"id":123,"values":{}}]}]';

    private static final String PACKAGE_INFO_WITHOUT_CONTRACT =
        '[{"id":"18","version":"1","packageInfo":{"id":' + PACKAGE_ID + ',"catalogId":"' +
            PACKAGE_CATALOG_ID + '","version":"' + PACKAGE_VERSION + '"},"productName":"Office"' +
            ',"duration":"' + PACKAGE_DURATION + '","edition":{"id":1,"name":"Standard"},"contract": null,' +
            '"offerType":"Regular","globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":' +
            '"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":' +
            '"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
            '"override":false}],"permissions":null,"discountTemplates":[{"id":123,"values":{}}]}]';
    private static final String PACKAGE_INFO_QLI_WITH_LBOX = '{"categoryCode":"DL-UNL", "categoryPath":"DL-UNL", "discount"' +
        ':{},"duration":"Monthly","id":"18","price":0,"version":"1","parent":"LC_DL_75","q":33,' +
            '"lboxes":[{"elementID":"' + LBOX_ELEMENT_ID + '","min":1,"max":100}]}';
    private static String NGBS_ACCOUNT_RESPONSE = '{"id":"1","packages":[{"catalogId":"' + PACKAGE_CATALOG_ID + '",' +
        '"version":"' + PACKAGE_VERSION + '","offerType":"Regular","id":' + PACKAGE_ID + ',"licenses":[{"id":"3","qty":5,"catalogId": "' + Product2Helper.SUBSCRIPTION_LICENSE + '", "subLicenses":[]}],"masterDuration": "Monthly"}]}';

    private static final String NGBS_BILLING_INFO_RESPONSE = '[{"amount":0.08,"catalogId":"LC_DL_75","discountAmount":0,"qty":3,"billingType":"Recurring","billingCycleDuration":"Monthly","dateRangeStart":"2020-08-09","dateRangeEnd":"2020-09-08","description":"Disconnect Scrub, per 10 scrubs","descriptionKey":"E528A917D99E9C0E7976FE2F7301474B"},{"amount":0.03,"catalogId":"LC_DL-UNL_50","discountAmount":0,"qty":3,"billingType":"Recurring","billingCycleDuration":"Monthly","dateRangeStart":"2020-08-09","dateRangeEnd":"2020-09-08","description":"Automated speech recognition, per minute","descriptionKey":"0C87BF8CA6D34E48BBA4228C91DCD275"},{"amount":0.03,"catalogId":"LC_DID_53","discountAmount":0,"qty":3,"billingType":"Recurring","billingCycleDuration":"Monthly","dateRangeStart":"2020-08-09","dateRangeEnd":"2020-09-08","description":"Automated speech recognition, per minute","descriptionKey":"0C87BF8CA6D34E48BBA4228C91DCD275"}]';

    private static final String NGBS_POC_ACCOUNT_RESPONSE = '{"id":5218705001,"packages":[{"id":' + PACKAGE_ID + ',"catalogId":"18","version":"1","status":"Active","offerType":"ProofOfConcept","description":"RingCentral Office Standard","currency":"USD","masterDuration":"Monthly","licenses":[{"id":47787810001,"catalogId":"LC_DL_75","categoryId":"DL","externalId":"rc:phonelineid:1791051012","description":"DigitalLine","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","subLicenses":[{"id":47787812001,"catalogId":"LC_DL-UNL_50","categoryId":"DL-UNL","externalId":"rc:digitallineid:1791051012","description":"DigitalLine Unlimited","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","subLicenses":[{"id":47787815001,"catalogId":"LC_DID_53","categoryId":"DID","externalId":"rc:fphoneid:4056372012","description":"DID","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"DBEAB5095E8B54BE8527724B23C371A3"}],"descriptionKey":"C42D89795912155D0609ADF07491A640"},{"id":47787813001,"catalogId":"LC_CRF_51","categoryId":"CRF","externalId":"rc:CRF:1791051012","description":"Compliance and Administrative Cost Recovery Fee","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"C8EFB0CE91E66A64002E644CA3D67014"},{"id":47787814001,"catalogId":"LC_E911_52","categoryId":"E911","externalId":"rc:E911:1791051012","description":"e911 Service Fee","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"71EA7BE324BCD4A18F78A9EEA6DB7D5C"}],"descriptionKey":"F33BCA901CB8B47F14DE4C52F2413875"},{"id":47787943001,"catalogId":"LC_DL_75","categoryId":"DL","externalId":"rc:phonelineid:1791058012","description":"DigitalLine","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","subLicenses":[{"id":47787945001,"catalogId":"LC_DL-UNL_50","categoryId":"DL-UNL","externalId":"rc:digitallineid:1791058012","description":"DigitalLine Unlimited","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","subLicenses":[{"id":47787948001,"catalogId":"LC_DID_53","categoryId":"DID","externalId":"rc:fphoneid:4056379012","description":"DID","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"DBEAB5095E8B54BE8527724B23C371A3"}],"descriptionKey":"C42D89795912155D0609ADF07491A640"},{"id":47787946001,"catalogId":"LC_CRF_51","categoryId":"CRF","externalId":"rc:CRF:1791058012","description":"Compliance and Administrative Cost Recovery Fee","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"C8EFB0CE91E66A64002E644CA3D67014"},{"id":47787947001,"catalogId":"LC_E911_52","categoryId":"E911","externalId":"rc:E911:1791058012","description":"e911 Service Fee","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"71EA7BE324BCD4A18F78A9EEA6DB7D5C"}],"descriptionKey":"F33BCA901CB8B47F14DE4C52F2413875"},{"id":47787998001,"catalogId":"LC_DL_75","categoryId":"DL","externalId":"rc:phonelineid:1791060012","description":"DigitalLine","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","subLicenses":[{"id":47788000001,"catalogId":"LC_DL-UNL_50","categoryId":"DL-UNL","externalId":"rc:digitallineid:1791060012","description":"DigitalLine Unlimited","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","subLicenses":[{"id":47788003001,"catalogId":"LC_DID_53","categoryId":"DID","externalId":"rc:fphoneid:4056381012","description":"DID","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"DBEAB5095E8B54BE8527724B23C371A3"}],"descriptionKey":"C42D89795912155D0609ADF07491A640"},{"id":47788001001,"catalogId":"LC_CRF_51","categoryId":"CRF","externalId":"rc:CRF:1791060012","description":"Compliance and Administrative Cost Recovery Fee","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"C8EFB0CE91E66A64002E644CA3D67014"},{"id":47788002001,"catalogId":"LC_E911_52","categoryId":"E911","externalId":"rc:E911:1791060012","description":"e911 Service Fee","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"71EA7BE324BCD4A18F78A9EEA6DB7D5C"}],"descriptionKey":"F33BCA901CB8B47F14DE4C52F2413875"}]}]}';
    private static String contractResponse =
        '[{"id":42775001,"createdAt":"2019-07-26T16:47:33.664Z[UTC]","lastUpdated":"2019-07-31T15:41:37.203Z[UTC]",' +
            '"startBillingCycleNumber":0,"startDate":"2019-07-26","renewalDate":null,"term":12,"renewalTerm":12,' +
            '"autoRenewal":true,"packageVersion":"1","licenses":[{"id":25905001,"catalogId":"LC_DL-UNL_50",' +
            '"contractualQty":101},{"id":25906001,"catalogId":"LC_CRF_51","contractualQty":101}]}]';

    private static String activeContractResponse =
        '[{"id":42775001,"createdAt":"2019-07-26T16:47:33.664Z[UTC]","lastUpdated":"2019-07-31T15:41:37.203Z[UTC]",' +
            '"startBillingCycleNumber":1,"startDate":"2019-07-26","renewalDate":null,"term":12,"renewalTerm":12,' +
            '"autoRenewal":true,"packageVersion":"1","licenses":[{"id":25905001,"catalogId":"LC_DL-UNL_50",' +
            '"contractualQty":101},{"id":25906001,"catalogId":"LC_CRF_51","contractualQty":101}]}]';

    private static final String DISCOUNT_TEMPLATE_GROUP_RESPONSE = '[{"id":72106001,"packageId":1038319001,"contractId":null,' +
        '"description":"a description","priority":"A","addedAt":"2019-01-23T12:37:37.990Z[UTC]","promoCode":null,"promoType":null,' +
        '"target":{"catalogId":"' + PACKAGE_CATALOG_ID + '","version":"' + PACKAGE_VERSION + '"},"discountTemplates":[{"id":86266001,"description":"a description",' +
        '"applicableTo":{"type":"CatalogId","id":"LC_WB_409"},"applicationTerms":{"startDate":"2018-05-09T00:00Z[UTC]",' +
        '"endDate":"2020-05-09T00:00Z[UTC]","maxLicenses":10000,"licenseScope":"All"},"values":{' +
        '"Monthly":{"unit":"Money","value":1E+1,"recurringTerms":{"unit":"Months","value":1}}}}],"visible":true}]';

    private static final String ACCOUNT_LBOXES_LIMITS_RESPONSE = '[{"id":12010103001,"description":"RCRooms' +
        '","lboxLimits":[{"type":"Max","value":1000,"defaultLimit":true},{"type":"Min","value":0,"defaultLimit":' +
        'true}],"lboxCatalogId":"' + LBOX_ELEMENT_ID + '","lboxItems":[{"id":12010103001,' +
        '"catalogId":"LC_RCRM_77","description":"RC Rooms"}]}]';

    private static String LICENSES_COUNTER_RESPONSE = '[{' +
        '"instanceQty" : 1,' +
        '"categoryId" : "DID",' +
        '"catalogId" : "LC_DID_53",' +
        '"billingCodeId" : null,' +
        '"batchQty" : 12}, {"instanceQty" : 1,' +
        '"categoryId" : "DL-UNL",' +
        '"catalogId" : "LC_DL-UNL_50",' +
        '"billingCodeId" : null,' +
        '"batchQty" : 12' +
        '}, {"instanceQty" : 1,' +
        '"categoryId" : "DL",' +
        '"catalogId" : "LC_DL_75",' +
        '"billingCodeId" : null,' +
        '"batchQty" : 12' +
        '}, {"instanceQty" : 1,' +
        '"categoryId" : "E911",' +
        '"catalogId" : "LC_E911_52",' +
        '"billingCodeId" : null,' +
        '"batchQty" : 12}, ' +
        '{"instanceQty" : 1,' +
        '"categoryId" : "CRF",' +
        '"catalogId" : "LC_CRF_51",' +
        '"billingCodeId" : null,' +
        '"batchQty" : 12}]';

    private static String BILLING_INFO_SUMMARY_LICENSE_RESPONSE = '[' +
        '{"amount":120,"catalogId":"LC_DL_75","discountAmount":-572.33,"discountValue":{"unit":"Percent","value":30},"qty":30,"billingType":"Recurring","billingCycleDuration":"Monthly","dateRangeStart":"2020-06-17","dateRangeEnd":"2020-07-16","description":"DigitalLine Unlimited","descriptionKey":"C42D89795912155D0609ADF07491A640"},' +
        '{"amount":120,"catalogId":"LC_DL-UNL_50","discountAmount":-572.33,"discountValue":{"unit":"Percent","value":30},"qty":30,"billingType":"Recurring","billingCycleDuration":"Monthly","dateRangeStart":"2020-06-17","dateRangeEnd":"2020-07-16","description":"DigitalLine Unlimited","descriptionKey":"C42D89795912155D0609ADF07491A640"}]';

    private static final String ORDER_API_RESPONSE = '{"invoice" : {"id": 1}}';

    private static final String PACKAGE_PARAMS_GET_RESPONSE = '[{"id":1,"name":"StatementFormatVersion","value":2},{"id":2,"name":"VirtualTimeCycleShift","value":0},{"id":3,"name":"EnableUpgradeOnContract","value":0},{"id":4,"name":"SkipCreditCardAddressVerification","value":0},{"id":5,"name":"ForceMRSDetailsPush","value":0}]';
    private static final String PACKAGE_PARAMS_PUT_RESPONSE = '[{"id":3,"name":"EnableUpgradeOnContract","value":-1}]';
    private static String GET_PAYMENT_METHOD_RESPONSE = '[{"id":27328005,"accountId":227775005,"addedAt":"2020-12-22T15:25:25.301Z[UTC]","invoiceInfo":{"terms":0,"address":{"label":null,"firstName":"Rechecked4183_RCUS2112","lastName":"Rechecked4183_RCUS2112","phone":null,"street1":"111 Industrial Ctr","street2":null,"city":"Belmont","county":null,"state":"CA","zip":"94002","country":"USA"}},"default":true}]';
    private static String GET_PAYMENT_METHOD_TYPE_RESPONSE = '{"currentType":"testPaymentMethodType","formerTypes":[]}';
    private static String BILLING_INFO_ALL_LICENSE_RESPONSE = '{"productLine" : "RC","packageId" : "25309001","packageExpirationDate" : null,"packageDuration" : null,"packageDescription" : "RingCentral Office Standard","nextBillingDate" : "2021-04-03T07:00Z[UTC]","licenses" : ['
        + '{"topLicenseId" : "369246001","scheduledForRemoval" : false,"replacement" : null,"qty" : 12,"price" : 4.99,"licenseTypeId" : null,"licenseId" : "369246001","discount" : null,"description" : "Additional Local Number","categoryId" : "ALN","catalogId" : "LC_ALN_38","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : true }, {'
        + '"topLicenseId" : "369247001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 49.0,"licenseTypeId" : "2","licenseId" : "369247001","discount" : null,"description" : "RingCentral Rooms License","categoryId" : "RCRM","catalogId" : "LC_RCRM_77","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369248001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 49.0,"licenseTypeId" : "2","licenseId" : "369248001","discount" : null,"description" : "RingCentral Rooms License","categoryId" : "RCRM","catalogId" : "LC_RCRM_77","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369174001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 0.5,"licenseTypeId" : null,"licenseId" : "369174001","discount" : null,"description" : "Cloud Recording Storage Overage","categoryId" : "CRO","catalogId" : "LC_CRO_574","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369175001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 34.99,"licenseTypeId" : null,"licenseId" : "369175001","discount" : null,"description" : "Mobile User","categoryId" : "MU","catalogId" : "LC_MU_281","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369176001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 0.0,"licenseTypeId" : null,"licenseId" : "369176001","discount" : null,"description" : "Office Standard - Subscription Fee","categoryId" : "SC","catalogId" : "LC_SC_29","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369177001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 0.0,"licenseTypeId" : null,"licenseId" : "369177001","discount" : null,"description" : "Compliance and Administrative Cost Recovery Fee","categoryId" : "CRF","catalogId" : "LC_CRF_43","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369189001","scheduledForRemoval" : false,"replacement" : null,"qty" : 25,"price" : 4.0,"licenseTypeId" : null,"licenseId" : "369191001","discount" : null,"description" : "Compliance and Administrative Cost Recovery Fee","categoryId" : "CRF","catalogId" : "LC_CRF_51","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : true }, {'
        + '"topLicenseId" : "369189001","scheduledForRemoval" : false,"replacement" : null,"qty" : 25,"price" : 1.0,"licenseTypeId" : null,"licenseId" : "369192001","discount" : null,"description" : "e911 Service Fee","categoryId" : "E911","catalogId" : "LC_E911_52","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : true }, {'
        + '"topLicenseId" : "369189001","scheduledForRemoval" : false,"replacement" : null,"qty" : 25,"price" : 34.99,"licenseTypeId" : null,"licenseId" : "369190001","discount" : null,"description" : "DigitalLine Unlimited","categoryId" : "DL-UNL","catalogId" : "LC_DL-UNL_50","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : true }, {'
        + '"topLicenseId" : "369180001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 34.99,"licenseTypeId" : null,"licenseId" : "369182001","discount" : null,"description" : "DigitalLine Unlimited","categoryId" : "DL-UNL","catalogId" : "LC_DL-UNL_50","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null}, {'
        + '"topLicenseId" : "369180001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 4.0,"licenseTypeId" : null,"licenseId" : "369183001","discount" : null,"description" : "Compliance and Administrative Cost Recovery Fee","categoryId" : "CRF","catalogId" : "LC_CRF_51","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null}, {'
        + '"topLicenseId" : "369180001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 1.0,"licenseTypeId" : null,"licenseId" : "369184001","discount" : null,"description" : "e911 Service Fee","categoryId" : "E911","catalogId" : "LC_E911_52","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369487001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 10000.0,"licenseTypeId" : "29","licenseId" : "369487001","discount" : null,"description" : "Extended Enterprise Support - Platinum Tier - Office","categoryId" : "EES","catalogId" : "LC_EES_489","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration":"Monthly","batch":null},{'
        + '"topLicenseId" : "369487001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 2000.0,"licenseTypeId" : null,"licenseId" : "369488001","discount" : null,"description" : "Extended Enterprise Support - Platinum Tier - Office - Additional TAM","categoryId" : "EES-TAM","catalogId" : "LC_EES-TAM_949","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration":"Monthly","batch":null}],"creditBalance" : 0,"accountId" : "25309001"}';

    public static final String BILLING_LICENSES_BY_CATEGORIES_RESP = '[' +
            '{"id": 1518892002,"catalogId": "LC_DL_75","scheduledForRemoval":false, "externalId": null,"categoryId": "DL","description": "test","qty": ' + BATCH_QTY + ',"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [' +
            '{"id": 1518896002,"catalogId": "LC_CRF_51","scheduledForRemoval":false, "externalId": null,"categoryId": "CRF","description": "test","qty": 1,"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [],"props": {}},' +
            '{"id": 1518897002,"catalogId": "LC_E911_52","scheduledForRemoval":false, "externalId": null,"categoryId": "E911","description": "test","qty": 1,"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [],"props": {}},' +
            '{"id": 1518895002,"catalogId": "LC_DL-UNL_50","scheduledForRemoval":false,"externalId": null,"categoryId": "DL-UNL","description": "test","qty": 1,"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [],"props": {}}],' +
            '"props": {}},' +
            '{"id": 1530356002,"catalogId": "LC_DL_75","externalId": null,"categoryId": "DL","description": "test","qty": ' + BATCH_QTY + ',"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [' +
            '{"id": 1530358002,"catalogId": "LC_CRF_51","externalId": null,"categoryId": "CRF","description": "test","qty": 1,"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [],"props": {}},' +
            '{"id": 1530359002,"catalogId": "LC_E911_52","externalId": null,"categoryId": "E911","description": "test","qty": 1,"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [],"props": {}},' +
            '{"id": 1530357002,"catalogId": "LC_DL-BAS_178","externalId": null,"categoryId": "DL-BAS","description": "test","qty": 1,"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [],"props": {}}],' +
            '"props": {}},' +
            '{"id": 1533395002,"catalogId": "LC_ALN_38","externalId": null,"categoryId": "ALN","description": "test","qty": ' + BATCH_QTY + ',"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [],"props": {}},' +
            '{"id": 1518893002,"catalogId": "LC_ATN_39","externalId": null,"categoryId": "ATN","description": "test","qty": ' + BATCH_QTY + ',"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [],"props": {}},' +
            '{"id": 1530353333,"catalogId": "LC_IB_351","externalId": null,"categoryId": "IB","description": "test","qty": 1,"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [],"props": {}},' +
            '{"id": 1530354444,"catalogId": "LC_EES_489","externalId": null,"categoryId": "EES","description": "test","qty": 1,"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": [],"props": {"LicenseTypeId" : "27"}}]]';

    private static final String TERMINATION_ACCOUNT_API_RESPONSE = '{"status": "success", "messages": [{"severity": "success", "message": "test"}],"data": {"engageAccountTerminated": true,"ngbsAccountTerminated": true}}';

    private static final String NGBS_PACKAGE_LIMITS_API_RESPONSE = '[{"value":500000,"limitOverride":{"value":50000,"startDate":"2022-02-10T13:22Z[UTC]","paymentType" : null,"limitDuration":{"value":1,"unit":"Months"}},"exclusions":[{"targetId":"HD","target":"LicenseCategoryId"}],"code":"MONTHLY_AMOUNT_LIMIT"}]';

    private static String getNGBSPackageWithLabelsResponse() {
        return '{"id":"18","version":"1","packageInfo":{"id":' + PACKAGE_ID + ',"catalogId":"' + PACKAGE_CATALOG_ID + '",' +
            '"version": "' + PACKAGE_VERSION + '"}, "labels": {"upgradeWizardExpiration": ["' + LABEL_VALUE + '"]}}';
    }

    private static final String BASE_ENDPOINT = 'http://test.com';
    private static final String MANAGER_PATH = 'http://test.com/test_manager';
    private static final String CCB_ENDPOINT = 'http://test.com/';
    private static final String STATUS = 'status';
    private static final String INFO = 'info';
    private static final String SUCCESS = 'success';

    @testSetup
    private static void test_generateData() {
        Triggers.switchOff();
        NGBS_Settings__c settings = (NGBS_Settings__c) new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => BASE_ENDPOINT,
                NGBS_Settings__c.AccountManagerPath__c => MANAGER_PATH,
                NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        CCB_Settings__c ccbSettings = (CCB_Settings__c) new SObjectBuilder(CCB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CCB_Settings__c.BaseEndpoint__c => CCB_ENDPOINT,
                CCB_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                CCB_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        new SObjectBuilder(NGBS_Order_API_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            NGBS_Order_API_Settings__c.Batch_False_Licenses_Codes__c => 'GLP;LR;ICI;RCRM;RCON;NM;MS;EES;CC;CCES'
        })
            .create()
            .getRecord();

        Funnel_Limits__c funnelLimits = (Funnel_Limits__c) new SObjectBuilder(Funnel_Limits__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Funnel_Limits__c.Name => 'ILN ITN ILNP',
                Funnel_Limits__c.Categories__c => 'ILN ITN ILNP',
                Funnel_Limits__c.Quantity__c => 0,
                Funnel_Limits__c.Manual_Upsell__c => true,
                Funnel_Limits__c.Only_LBO__c => true
            })
            .create()
            .getRecord();
        NGBSLBOBillingLimits__c billingLimits = (NGBSLBOBillingLimits__c) new SObjectBuilder(NGBSLBOBillingLimits__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSLBOBillingLimits__c.Name => 'ILN ITN ILNP',
                NGBSLBOBillingLimits__c.Categories__c => 'ILN ITN ILNP',
                NGBSLBOBillingLimits__c.Quantity__c => 0,
                NGBSLBOBillingLimits__c.Manual_Upsell__c => true,
                NGBSLBOBillingLimits__c.Only_LBO__c => true
            })
            .create()
            .getRecord();

        NGBS_Phoenix_Settings__c phoenixSettings = (NGBS_Phoenix_Settings__c) new SObjectBuilder(NGBS_Phoenix_Settings__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableBrands__c => 'RingCentral;RingCentral Canada;RingCentral AU;RingCentral UK;RingCentral EU; Unify Office;',
                NGBS_Phoenix_Settings__c.NGBSPhoenixAvailablePackageIDs__c => '666;210;260;220;230;231;240;241;250;251;510;',
                NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableProducts__c => 'RC Meetings;Meetings;'
            })
            .create()
            .getRecord();

        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => BILLING_ID,
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, billingAcc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
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

        Triggers.switchOn();

        /* opportunities */
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .build()
            .getRecord();
        Opportunity oppPOC = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => POC_OPP_NAME,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .build()
            .getRecord();
        Opportunity oppTermination = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => TERMINATION_OPP_NAME,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.isTermination__c => true,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY
            })
            .build()
            .getRecord();
        Opportunity oppFedRamp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => FEDRAMP_OPP_NAME,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.isFedRamp__c => true
            })
            .build()
            .getRecord();

        insert new List<Opportunity>{
            opp,
            oppPOC,
            oppTermination,
            oppFedRamp
        };

        /* products */
        Map<SObjectField, Object> productDigitalLineMap = new Map<SObjectField, Object> {
            Product2.Name => PRODUCT_DIGITALLINE,
            Product2.ExtId__c => 'LC_DL_75',
            Product2.Family => Product2Helper.FAMILY_COMMON_PHONE,
            Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
        };
        Product2 productDigitalLine = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(productDigitalLineMap).build().getRecord();

        Map<SObjectField, Object> productDigitalLineUnlimitedMap = new Map<SObjectField, Object> {
            Product2.Name => PRODUCT_DIGITALLINE_UNLIMITED,
            Product2.ExtId__c => 'LC_DL-UNL_50',
            Product2.Family => Product2Helper.FAMILY_SERVICE,
            Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
        };
        Product2 productDigitalLineUnlimited = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(productDigitalLineUnlimitedMap).build().getRecord();

        Map<SObjectField, Object> productDIDMap = new Map<SObjectField, Object> {
            Product2.Name => 'DID',
            Product2.ExtId__c => 'LC_DID_53',
            Product2.Family => Product2Helper.FAMILY_TECHNICAL
        };
        Product2 productDID = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(productDIDMap).build().getRecord();

        insert new List<Product2>{
            productDigitalLine,
            productDigitalLineUnlimited,
            productDID
        };

        /* quotes */
        BillingWrappers.QuotePackageInfoWrapper qtPInfoWrapper = new BillingWrappers.QuotePackageInfoWrapper(PACKAGE_INFO);
        BillingWrappers.QuotePackageInfo qtPInfo = qtPInfoWrapper.getPackageInfo();
        qtPInfo.packageInfo.name = 'Office Standard';
        qtPInfo.duration = 'Monthly';
        qtPInfoWrapper.setPackageInfo(qtPInfo);

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.PackageNameNew__c => 'Test',
                Quote.BillingPackage__c => pkg.Id,
                Quote.Package_Info__c => qtPInfoWrapper.toString()
            })
            .build()
            .getRecord();

        Quote qtPOC = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => oppPOC.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO
            })
            .build()
            .getRecord();

        insert new List<Quote>{
            qt,
            qtPOC
        };

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.QuoteId => qt.Id,
                Order.TechnicalQuoteId__c => qt.Id,
                Order.AccountId => billingAcc.Id,
                Order.EffectiveDate => System.today(),
                Order.Status => OrderHelper.STATUS_NEW,
                Order.RecordTypeId => OrderHelper.RT_ID_ENGAGE_DIGITAL_STANDALONE
            })
        .create()
        .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productDigitalLineUnlimited.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        /* ents */
        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => ENTITLEMENT_NAME,
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => billingAcc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.PackageCatalogId__c => PACKAGE_CATALOG_ID,
                Entitlement__c.PackageVersion__c => PACKAGE_VERSION,
                Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Product__c => productDigitalLineUnlimited.Id,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quote__c => qt.Id
            })
            .build()
            .getRecord();

        Entitlement__c entDigitalLineUnlimited = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => ENTITLEMENT_NAME,
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => billingAcc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.PackageCatalogId__c => PACKAGE_CATALOG_ID,
                Entitlement__c.PackageVersion__c => PACKAGE_VERSION,
                Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Product__c => productDigitalLineUnlimited.Id,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quote__c => qt.Id
            })
            .build()
            .getRecord();
        Entitlement__c entDigitalLine = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => ENTITLEMENT_NAME,
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => billingAcc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.PackageCatalogId__c => PACKAGE_CATALOG_ID,
                Entitlement__c.PackageVersion__c => PACKAGE_VERSION,
                Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Product__c => productDigitalLine.Id,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quote__c => qt.Id
            })
            .build()
            .getRecord();

        insert new List<Entitlement__c>{
            ent,
            entDigitalLineUnlimited,
            entDigitalLine
        };

        // TODO rework
        qt.CurrentService__c = ent.Id;
        qtPOC.CurrentService__c = ent.Id;
        updateWithoutTriggers(new List<SObject>{qt, qtPOC});

        /* qlis */
        BillingWrappers.QLIPackageInfo qliPackageInfo = new BillingWrappers.QLIPackageInfo(TestDataGenerator.TEST_PACKAGE_INFO);
        qliPackageInfo.categoryPath = 'DL';
        Test.startTest();

        QuoteLineItem qliDigitalLineUnlimited = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDigitalLineUnlimited.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Entitlement__c => entDigitalLineUnlimited.Id,
                QuoteLineItem.PackageInfo__c => JSON.serialize(qliPackageInfo)
            })
            .build()
            .getRecord();

        QuoteLineItem qliDigitalLine = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDigitalLine.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Entitlement__c => entDigitalLine.Id,
                QuoteLineItem.PackageInfo__c => JSON.serialize(qliPackageInfo)
            })
            .build()
            .getRecord();

        QuoteLineItem qliDigitalLinePOC = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qtPOC.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDigitalLine.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .build()
            .getRecord();

        QuoteLineItem qliDigitalLineUnlimitedPOC = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qtPOC.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDigitalLineUnlimited.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .build()
            .getRecord();

        QuoteLineItem qliDIDPOC = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qtPOC.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDID.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .build()
            .getRecord();

        insert new List<QuoteLineItem>{
            qliDigitalLineUnlimited,
            qliDigitalLine,
            qliDigitalLinePOC,
            qliDigitalLineUnlimitedPOC,
            qliDIDPOC
        };

        new SOBjectBuilder(OrderItem.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                OrderItem.OrderId => testOrder.Id,
                OrderItem.PricebookEntryId => currentPricebookEntry.Id,
                OrderItem.QuoteLineItemId => qliDigitalLineUnlimited.Id,
                OrderItem.Quantity => qliDigitalLineUnlimited.Quantity,
                OrderItem.UnitPrice => qliDigitalLineUnlimited.UnitPrice
            })
            .create();
        Test.stopTest();

        /* other */
        Contract__c contract = (Contract__c) new SObjectBuilder(Contract__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contract__c.ExtID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        new SObjectBuilder(Contract_Discount__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contract_Discount__c.Contract__c => contract.Id,
                Contract_Discount__c.ApplicableTo__c => ValueProviderBuilder.provideUniqueString(),
                Contract_Discount__c.Duration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Contract_Discount__c.Discount__c => 1
            })
            .create();

        Area_Codes__c areaCode = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => 'Test',
                Area_Codes__c.Area_Code__c => 1234,
                Area_Codes__c.City__c => 'test',
                Area_Codes__c.Country__c => 'test',
                Area_Codes__c.State__c => 'test',
                Area_Codes__c.State_Abbreviation__c => 'tes'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Area_Code__c => areaCode.Id,
                Area_Code_Line_Item__c.Quantity__c => qliDigitalLineUnlimited.Quantity,
                Area_Code_Line_Item__c.Quote_Line_Item__c => qliDigitalLineUnlimited.Id
            })
            .create();
    }

    @isTest
    private static void test_isMultiproductFTEnabled() {
        Feature_Toggle__c featureToggle = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.EnableMultiProduct__c => true
            })
            .create()
            .getRecord();
        Test.startTest();
            Response res = SyncWithNGBS.isMultiproductFTEnabled();
        Test.stopTest();

        System.assert(res.isSuccess(), 'isMultiproductFTEnabled should return response with Success status');
        System.assert(res.data.containsKey('isMultiproductEnabled'), 'response should contains "isMultiproductEnabled" data');
        System.assertEquals(res.getData('isMultiproductEnabled'), true, 'Multiproduct FT is enabled');
    }

    @isTest
    private static void test_isContractExistInSFShoudReturnTrueWoContract() {
        Quote q = queryQuote(OPP_NAME);

        Test.startTest();
        Boolean result = SWNHelper.isContractExistInSF(q);
        Test.stopTest();

        System.assert(
            result,
            getMessageForComment('true')
        );
    }

    @isTest
    private static void test_isContractExistInSFShoudReturnTrueWContract() {
        Quote q = queryQuote(OPP_NAME);
        q.Package_Info__c = PACKAGE_INFO;

        Test.startTest();
        Boolean result = SWNHelper.isContractExistInSF(q);
        Test.stopTest();

        System.assert(
            result,
            getMessageForComment('true')
        );
    }

    @isTest
    private static void test_selectContractShoudReturnContractWoCorrectId() {

        Test.startTest();
        Contract__c result = ContractRestAPI.selectContract(new BillingWrappers.QuotePackageInfo());
        Test.stopTest();

        System.assertEquals(
            result,
            null,
            getMessageForComment('null')
        );
    }

    @isTest
    private static void test_selectContractShoudReturnContractWCorrectId() {
        BillingWrappers.QuotePackageInfo packageInfo = new BillingWrappers.QuotePackageInfo();
        Contract__c contract = queryContract();
        packageInfo.contract.id = contract.Id;

        Test.startTest();
        Contract__c result = ContractRestAPI.selectContract(packageInfo);
        Test.stopTest();

        System.assertEquals(
            contract.Id,
            result.Id,
            'Incorrect Contract has been returned'
        );
    }

    @isTest
    private static void testOrderStepForLBOAccounts() {

        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            if (qli.Product_Lic_Id__c == 'LC_DL_75') {
                qli.PackageInfo__c = PACKAGE_INFO_QLI_WITH_LBOX.replace('"categoryCode":"DL-UNL"', '"categoryCode":"DL"').replace('"LC_DL_75"','null');
            } else {
                qli.PackageInfo__c = PACKAGE_INFO_QLI_WITH_LBOX;
            }
            qli.Quantity += 32;
            qli.NewQuantity__c += 42;
            qli.Zero_Quantity__c = false;
        }
        updateWithoutTriggers(qt.QuoteLineItems);
        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.ORDER);

        Test.stopTest();

        Opportunity reselectOpp = queryOpportunity(OPP_NAME);
        Quote reselectQuote = queryQuote(OPP_NAME);

        System.assert(reselectOpp.OrderDate__c != null, 'For the ORDER step, the date must be filled in the OrderDate__c field');
        System.assert(reselectQuote.InvoiceId__c != null, 'For the ORDER step, the InvoiceId must be filled in the InvoiceId__c field');
        System.assertEquals(true, reselectOpp.isOrderStepCompleted__c, 'isOrderStepCompleted__c field should be true');
    }

    @isTest
    private static void verifySyncActionUpgradeReturnSuccess() {
        Quote qt = queryQuote(OPP_NAME);

        Entitlement__c ent = queryEntitlement(ENTITLEMENT_NAME);
        ent.PackageCatalogId__c = PACKAGE_CHANGED_CATALOG_ID;
        updateWithoutTriggers(ent);

        List<QuoteLineItem> qlis = queryQuoteLineItems();
        for (QuoteLineItem qli : qlis) {
            qli.Entitlement__c = ent.Id;
        }
        updateWithoutTriggers(qlis);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.UPGRADE);

        Test.stopTest();

        System.assert(res.isSuccess(), 'syncWithNGBS should return response with Success status');

        Opportunity reselectedOpp = queryOpportunity(OPP_NAME);
        System.assert(
            reselectedOpp.isUpgradeStepCompleted__c,
            'Opportunity.isUpgradeStepCompleted__c should be true after UPGRADE action'
        );
    }

    @isTest
    private static void verifySyncActionUpgradeReturnSuccessForCrossUpgrade() {

        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.isFSCSynced__c = true;
        updateWithoutTriggers(opp);

        Quote qt = queryQuote(OPP_NAME);
        BillingWrappers.QuotePackageInfoWrapper qtPInfoWrapper = new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c);
        BillingWrappers.QuotePackageInfo qtPInfo = qtPInfoWrapper.getPackageInfo();
        qtPInfo.productName = 'Fax';
        qtPInfo.existingPackageInfo = new BillingWrappers.ExistingPackageInfo();
        qtPInfo.existingPackageInfo.productName = 'Office';
        qtPInfoWrapper.setPackageInfo(qtPInfo);

        qt.Package_Info__c = qtPInfoWrapper.toString();
        updateWithoutTriggers(qt);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.UPGRADE);

        Test.stopTest();

        System.assert(res.isSuccess(), 'syncWithNGBS should return response with Success status');

        Opportunity reselectedOpp = queryOpportunity(OPP_NAME);
        System.assert(
            reselectedOpp.isUpgradeStepCompleted__c,
            'Opportunity.isUpgradeStepCompleted__c should be true after UPGRADE action'
        );
    }

    @isTest
    private static void verifySyncActionUpgradeReturnError() {
        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        updateWithoutTriggers(qt);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.UPGRADE);

        Test.stopTest();
        Opportunity reselectedOpp = queryOpportunity(OPP_NAME);

        System.assert(res.isError(), 'syncWithNGBS should return response with Error status if NGBS & SFDC has different packages');
        System.assertEquals(false, reselectedOpp.isUpgradeStepCompleted__c, 'Opportunity.isUpgradeStepCompleted__c should be false');
    }

    @isTest
    private static void testSyncActionUpsell() {

        Quote qt = queryQuote(OPP_NAME);

        qt.Package_Info__c = PACKAGE_INFO
            .replace(Product2Helper.PRODUCT_OFFICE, Product2Helper.PRODUCT_MEETINGS);
        updateWithoutTriggers(qt);

        List<QuoteLineItem> qlis = queryQuoteLineItems();
        for (QuoteLineItem qli : qlis) {
            qli.NewQuantity__c = 10;
            qli.Zero_Quantity__c = false;
        }
        updateWithoutTriggers(qlis);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.UP_SELL);

        Test.stopTest();

        System.assert(res.isSuccess(), 'syncWithNGBS should return response with Success status');

        Opportunity reselectedOpp = queryOpportunity(OPP_NAME);
        System.assert(
            reselectedOpp.isUpsellStepCompleted__c,
            'Opportunity.isUpsellStepCompleted__c should be true after UP_SELL action'
        );
    }

    @isTest
    private static void testSyncActionDownsell() {

        Quote qt = queryQuote(OPP_NAME);

        List<QuoteLineItem> qlis = queryQuoteLineItems();
        for (QuoteLineItem qli : qlis) {
            qli.NewQuantity__c = 2;
            qli.Zero_Quantity__c = false;
        }
        updateWithoutTriggers(qlis);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.DOWN_SELL);

        Test.stopTest();

        System.assert(res.isSuccess(), 'syncWithNGBS should return response with Success status');

        Opportunity reselectedOpp = queryOpportunity(OPP_NAME);
        System.assert(
            reselectedOpp.isDownsellStepCompleted__c,
            'Opportunity.isDownsellStepCompleted__c should be true after DOWN_SELL action'
        );
    }

    @isTest
    private static void testSyncActionReprice() {

        PermissionSet ps1 = new PermissionSet(
            Name = CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE,
            Label = CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE
        );
        insert ps1;

        PermissionSetAssignment psa1 = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = ps1.Id
        );
        insert psa1;

        Test.setMock(HttpCalloutMock.class, new Mock());

        User currentUser = [select Id from User where Id = :UserInfo.getUserId()];
        Quote qt = queryQuote(OPP_NAME);

        System.runAs(currentUser) {

            Opportunity opp = queryOpportunity(OPP_NAME);
            opp.isContractsSynced__c = true;
            updateWithoutTriggers(opp);

            Test.startTest();

            Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.REPRICE_SYNC);

            Test.stopTest();

            System.assert(res.isSuccess(), 'getSyncScenario should return response with Success status');

            Opportunity reselectedOpp = queryOpportunity(OPP_NAME);
            System.assert(
                reselectedOpp.isRepriceSynced__c,
                'Opportuinty.isRepriceSynced__c should be true after reprice sync'
            );
        }
    }

    @isTest
    private static void testRepriceShouldBeSkippedIfThereNothingToSync() {

        PermissionSet ps1 = new PermissionSet(
            Name = CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE,
            Label = CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE
        );
        insert ps1;

        PermissionSetAssignment psa1 = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = ps1.Id
        );
        insert psa1;

        Test.setMock(HttpCalloutMock.class, new EmptyDiscountTemplateGroupMock());

        User currentUser = [select Id from User where Id = :UserInfo.getUserId()];
        Quote qt = queryQuote(OPP_NAME);

        System.runAs(currentUser) {

            Opportunity opp = queryOpportunity(OPP_NAME);
            opp.isContractsSynced__c = true;
            updateWithoutTriggers(opp);

            Test.startTest();

            Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.REPRICE_SYNC);

            Test.stopTest();

            System.assert(res.isSuccess(), 'should return response with Success status');

            Opportunity reselectedOpp = queryOpportunity(OPP_NAME);
            System.assert(
                reselectedOpp.isRepriceSynced__c,
                'Opportuinty.isRepriceSynced__c should be true after skipped reprice sync(if there nothing to sync)'
            );
        }
    }

    @isTest
    private static void testSyncActionOverrideLicenseLimitsLboxSectionEmpty() {
        updateNGBSSettings();

        Account acc = queryAccount();
        acc.Billing_ID__c = '123';
        updateWithoutTriggers(acc);

        Opportunity opp = queryOpportunity(POC_OPP_NAME);

        Quote qt = queryQuote(POC_OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT
            .replace(QuoteHelper.OFFER_TYPE_REGULAR, QuoteHelper.OFFER_TYPE_POC);
        updateWithoutTriggers(qt);

        Entitlement__c ent = queryEntitlement(ENTITLEMENT_NAME);
        ent.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_POC;
        updateWithoutTriggers(ent);

        List<QuoteLineItem> qlis = queryQuoteLineItems();
        for (QuoteLineItem qli : qlis) {
            qli.Entitlement__c = ent.Id;
            qli.NewQuantity__c = 10;
        }
        updateWithoutTriggers(qlis);

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        tstMock.body = NGBS_ACCOUNT_RESPONSE
            .replace(QuoteHelper.OFFER_TYPE_REGULAR, QuoteHelper.PACKAGE_OFFER_TYPE_POC);
        Test.setMock(HttpCalloutMock.class, tstMock);

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.UPDATE_LICENSE_LIMITS);

        Test.stopTest();

        System.assert(!res.isError());

        Response.ResponseMessage[] messages = res.messages;

        Response.ResponseMessage mess = messages.get(0);
        System.assertEquals(
            'Can\'t override package limits. There are no quote line items with L-Box found',
            mess.message,
            'syncWithNGBS should return "info" response with message "Can\'t override package limits. There are no quote line items with L-Box found"'
        );
        System.assertEquals(
            'Please contact your manager',
            mess.messageDetails,
            'syncWithNGBS should return "info" response with messageDetails ' +
                '"Please contact your manager"'
        );
    }

    @isTest
    private static void testSyncActionOverrideLicenseLimitsSucceded() {
        updateNGBSSettings();

        Account acc = queryAccount();
        acc.Billing_ID__c = '123';
        updateWithoutTriggers(acc);

        Opportunity opp = queryOpportunity(POC_OPP_NAME);

        Quote qt = queryQuote(POC_OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT
            .replace(QuoteHelper.OFFER_TYPE_REGULAR, QuoteHelper.OFFER_TYPE_POC);
        updateWithoutTriggers(qt);

        Entitlement__c ent = queryEntitlement(ENTITLEMENT_NAME);
        ent.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_POC;
        updateWithoutTriggers(ent);

        List<QuoteLineItem> qlis = queryQuoteLineItems();
        for (QuoteLineItem qli : qlis) {
            qli.Entitlement__c = ent.Id;
            qli.PackageInfo__c = PACKAGE_INFO_QLI_WITH_LBOX;
            qli.NewQuantity__c = 10;
        }
        updateWithoutTriggers(qlis);

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        tstMock.body = NGBS_ACCOUNT_RESPONSE
            .replace(QuoteHelper.OFFER_TYPE_REGULAR, QuoteHelper.PACKAGE_OFFER_TYPE_POC);
        Test.setMock(HttpCalloutMock.class, tstMock);

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.UPDATE_LICENSE_LIMITS);

        Test.stopTest();
        System.assert(!res.isError());
    }

    private static Account queryAccount() {
        return (Account) new AccountSelector()
            .selectAccounts()
            .executeQuery()
            .get(0);
    }
    private static Quote queryQuote(String oppName) {
        return (Quote) new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(oppName)
            .selectField('Opportunity.RCCCSyncStatus__c')
            .executeQuery()
            .get(0);
    }

    private static Opportunity queryOpportunity(String oppName) {
        return (Opportunity) new OpportunitySelector()
            .selectOpportunityForSyncWithNGBSByName(oppName)
            .executeQuery()
            .get(0);
    }

    private static Entitlement__c queryEntitlement(String entName) {
        return (Entitlement__c) new EntitlementSelector()
            .selectEntitlementForSyncWithNGBSByName(entName)
            .executeQuery()
            .get(0);
    }

    private static List<Product2> queryProducts() {
        return (List<Product2>) new Product2Selector()
            .selectProducts()
            .executeQuery();
    }

    private static List<QuoteLineItem> queryQuoteLineItems() {
        return (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsForSyncWithNGBS()
            .executeQuery();
    }

    private static List<Case> queryCases() {
        return (List<Case>) new CaseSelector()
            .selectCasesDefault()
            .selectFields(new Set<String> {'Description', 'Subject'})
            .executeQuery();
    }

    private static Contract__c queryContract() {
        return (Contract__c) new BillingContractSelector()
            .selectContractWithDiscounts()
            .executeQuery()
            .get(0);
    }

    private static Funnel_Limits__c queryFunnelLimits() {
        return [SELECT Name, Categories__c, Quantity__c, Manual_Upsell__c, Only_LBO__c FROM Funnel_Limits__c];
    }

    private static NGBSLBOBillingLimits__c queryBillingLimits() {
        return [SELECT Name, Categories__c, Quantity__c, Manual_Upsell__c, Only_LBO__c FROM NGBSLBOBillingLimits__c];
    }

    private static Quote queryQuotePlus(String oppName) {
        return (Quote) new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(oppName)
            .subselect(new QuoteLineItemSelector().
                selectQuoteLineItemsForSyncWithNGBS())
            .executeQuery()
            .get(0);
    }

    private static List<NGBS_Discount.DiscountTemplateGroup> getNGBSDiscountTemplateGroup() {
        Integer quantity = 1;
        Quote qt = queryQuote(OPP_NAME);

        // pInfo
        BillingWrappers.QuotePackageInfo quotePackageInfo = new BillingWrappers.QuotePackageInfo();
        quotePackageInfo.packageInfo = new BillingWrappers.PackageInfo();
        quotePackageInfo.packageInfo.catalogId = '1';
        quotePackageInfo.packageInfo.version = '1';

        List<NGBS_Discount.DiscountItemWrapper> discountItemsList = new List<NGBS_Discount.DiscountItemWrapper>{
            new NGBS_Discount.DiscountItemWrapper(
                'Test name',
                'LC_DL_1',
                Product2Helper.CHARGE_TERM_MONTHLY,
                new NGBS_Discount.DiscountValue(11.0, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, true)
            )
        };

        String priority = 'A';
        List<BillingWrappers.BillingContract> billingContracts = null;

        List<NGBS_Discount.DiscountTemplateGroup> tempGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
        for (Integer i = 0; i < quantity; i++) {
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
        return tempGroups;
    }

    private static String getMessageForComment(String expected) {
        return 'Method should return \'' + expected + '\' value';
    }

    private static void updateWithoutTriggers(SObject sobjectToUpdate) {
        Triggers.switchOff();
        update sobjectToUpdate;
        Triggers.switchOn();
    }

    private static void updateWithoutTriggers(List<SObject> sobjectsToUpdate) {
        Triggers.switchOff();
        update sobjectsToUpdate;
        Triggers.switchOn();
    }

    private class Mock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(getRequestBody(req));

            return res;
        }

        private String getRequestBody(HTTPRequest req) {
            String body = '';
            String endpoint = req.getEndpoint();

            if (
                req.getEndpoint().endsWith('contract') &&
                    req.getMethod() == HttpHelper.METHOD_GET
                ) {
                body = contractResponse;
            } else if (
                req.getEndpoint().endsWith('freeServiceCredit') &&
                    req.getMethod() == HttpHelper.METHOD_PUT
                ) {
                body = '';
            } else if (
                req.getEndpoint().endsWith(CHANGED_BILLING_ID) ||
                    req.getMethod() == HttpHelper.METHOD_PUT
                ) {
                body = TestDataGenerator.TEST_PACKAGE_INFO;
            } else if (req.getEndpoint().endsWith('/summary')) {
                body = NGBS_ACCOUNT_RESPONSE;
            } else if (req.getEndpoint().endsWith('/summary?shortView=true')) {
                body = NGBS_ACCOUNT_RESPONSE;
            } else if (req.getEndpoint().endsWith('/0')) {
                body = NGBS_ACCOUNT_RESPONSE;
            } else if (req.getEndpoint().endsWith('/discountTemplateGroup')) {
                body = DISCOUNT_TEMPLATE_GROUP_RESPONSE;
            } else if (req.getEndpoint().endsWith('/lboxes')) {
                body = ACCOUNT_LBOXES_LIMITS_RESPONSE;
            } else if (req.getEndpoint().endsWith('/id2')) {
                body = '';
            } else if (req.getEndpoint().endsWith('/counters')){
                body = LICENSES_COUNTER_RESPONSE;
            } else if (endpoint.endsWith('/billinginfo/summary/license')) {
                body = BILLING_INFO_SUMMARY_LICENSE_RESPONSE;
            } else if (req.getEndpoint().endsWith('/order/v2')){
                body = ORDER_API_RESPONSE;
            } else if (req.getMethod() == HttpHelper.METHOD_GET && req.getEndpoint().endsWith('/paymentMethod')) {
                body = GET_PAYMENT_METHOD_RESPONSE;
            } else if (req.getMethod() == HttpHelper.METHOD_GET && req.getEndpoint().endsWith('/paymentMethod/type')) {
                body = GET_PAYMENT_METHOD_TYPE_RESPONSE;
            } else if (isPackageGetParameters(req)) {
                body = PACKAGE_PARAMS_GET_RESPONSE;
            } else if (isPackagePutParameters(req)) {
                body = PACKAGE_PARAMS_PUT_RESPONSE;
            } else if (endpoint.endsWith('/billinginfo/')){
                body = BILLING_INFO_ALL_LICENSE_RESPONSE;
            } else if (endpoint.endsWith('/billinginfo')){
                body = BILLING_INFO_ALL_LICENSE_RESPONSE;
            } else if (endpoint.endsWith('/packages/' + PACKAGE_CHANGED_CATALOG_ID + '/' + PACKAGE_VERSION)) {
                body = getNGBSPackageWithLabelsResponse();
            } else if (req.getEndpoint().endsWith('/contactInfo') && req.getMethod() == HttpHelper.METHOD_PUT){
                body = '';
            } else if (req.getEndpoint().endsWith('/limits') && req.getMethod() == HttpHelper.METHOD_GET){
                body = NGBS_PACKAGE_LIMITS_API_RESPONSE;
            } else if (req.getEndpoint().contains('license/info/categories') && req.getMethod() == HttpHelper.METHOD_POST) {
                body = BILLING_LICENSES_BY_CATEGORIES_RESP;
            } else {
                body = PACKAGE_INFO;
            }

            return body;
        }

        private Boolean isPackageGetParameters(HTTPRequest req) {
            return req.getEndpoint().endsWith('/parameters') &&
                req.getMethod() == HttpHelper.METHOD_GET;
        }

        private Boolean isPackagePutParameters(HTTPRequest req) {
            return req.getEndpoint().endsWith('/parameters') &&
                req.getMethod() == HttpHelper.METHOD_PUT;
        }
    }

    private class ErrorMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            res.setStatus('BAD');
            res.setStatusCode(404);
            res.setBody('');

            return res;
        }
    }

    private class POCMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(getRequestBody(req));

            return res;
        }

        private String getRequestBody(HTTPRequest req) {
            String body = '';

            if (req.getEndpoint().endsWith('/summary?shortView=true')) {
                body = NGBS_POC_ACCOUNT_RESPONSE;
            } else if (req.getEndpoint().endsWith('billinginfo/summary/license')) {
                body = NGBS_BILLING_INFO_RESPONSE;
            }

            return body;
        }
    }

    private class EmptyDiscountTemplateGroupMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            String body = '';

            if (req.getEndpoint().endsWith('/summary?shortView=true')) {
                body = NGBS_ACCOUNT_RESPONSE;
            } else if (
                req.getEndpoint().endsWith('contract') &&
                    req.getMethod() == HttpHelper.METHOD_GET
                ) {
                body = activeContractResponse;
            } else {
                // empty body for discount template groups
                body = '[]';
            }

            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(body);

            return res;
        }
    }

    private class EngageAccountTerminationMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(getRequestBody(req));

            return res;
        }

        private String getRequestBody(HTTPRequest req) {
            String body = '';
            String endpoint = req.getEndpoint();

            if (req.getEndpoint().endsWith('/130021990')) {
                body = TERMINATION_ACCOUNT_API_RESPONSE;
            } else if (req.getEndpoint().endsWith('/summary?shortView=true')) {
                body = NGBS_ACCOUNT_RESPONSE;
            }
            return body;
        }
    }

    @isTest
    private static void testProvisionCaseCreationLBOAccounts() {

        NGBSLBOBillingLimits__c bl = queryBillingLimits();
        bl.Categories__c += ' DL-UNL';
        updateWithoutTriggers(bl);

        Account acc = queryAccount();
        acc.Name = 'testAcc';
        acc.EnabledLBO__c = true;

        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.Enabled_LBO__c = true;
        qt.LBODealDeskProvision__c = true;
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.PackageInfo__c = PACKAGE_INFO_QLI_WITH_LBOX;
            qli.NewQuantity__c += 5;
            qli.Zero_Quantity__c = false;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.ORDER);

        Test.stopTest();

        Opportunity reselectOpp = queryOpportunity(OPP_NAME);
        List<Case> cases = queryCases();
        System.assertEquals(true, reselectOpp.IsAreaCodeCaseCreated__c, 'IsAreaCodeCaseCreated field should be true');
        System.assertEquals(true, reselectOpp.IsManualProvisionCaseCreated__c, 'IsManualProvisionCaseCreated field should be true');
        System.assertEquals(2, cases.size(), 'Cases size should be equals 2');
        System.assertEquals('LBO: ' + DealDeskCaseGenerator.CASE_SUBJECT_AREA_CODES, cases[0].Subject, 'Case subject must be "LBO: Products for area code assignment"');
        System.assertEquals('LBO: ' + DealDeskCaseGenerator.CASE_SUBJECT_MANUAL_PROVISION + acc.Name, cases[1].Subject, 'Incorrect Case subject');
        System.assertEquals(true, cases[0].Description.contains('License'), 'Case description should contains "License" in description');
        System.assertEquals(true, cases[1].Description.contains('Product Name:'), 'Case must have product name in description');
    }

    @isTest
    private static void testDownsellWithoutCaseCreationLBOAccounts() {

        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Package_Info__c = PACKAGE_INFO_QLI_WITH_LBOX;
            qli.NewQuantity__c = 2;
        }

        updateWithoutTriggers(qt.QuoteLineItems);
        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.DOWN_SELL);

        Test.stopTest();

        Opportunity reselectOpp = queryOpportunity(OPP_NAME);
        System.assertEquals(true, reselectOpp.isDownsellStepCompleted__c, 'isDownsellStepCompleted field should be true');
    }

    @isTest
    private static void testExceptionlCaseCreationLBOAccounts() {

        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Quantity = -2;
        }
        updateWithoutTriggers(qt.QuoteLineItems);
        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.CONTRACT_SYNC);

        Test.stopTest();

        List<Case> cases = queryCases();
        System.assertEquals(1, cases.size(), 'Cases size should be equals 1');
        System.assertEquals('LBO: ' + DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION, cases[0].Subject, 'Case subject must be "LBO: Manual Order Required for Quote"');
        System.assertEquals(true, cases[0].Description.contains('Manual Order'), 'Case description should contains "Manual Order" in description');
        System.assertEquals(true, cases[0].Description.contains(CaseHelper.CASE_REASON_EXCEPTION), 'Case description must contains "Exception" in description');
    }

    @isTest
    private static void testSpendingLimitsExceptionCaseCreationForLBOAccounts() {
        updateNGBSSettings();
        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        acc.Billing_ID__c = '123';
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT
            .replace(PACKAGE_ID, BillingHttpRequestMock.PACKAGE_ID);
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Quantity = 54;
            qli.Zero_Quantity__c = false;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        Test.startTest();
        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.ORDER);

        Test.stopTest();

        List<Case> cases = queryCases();
        System.assertEquals(true, res.isError(), 'Response must return an error');
        System.assertEquals(CaseHelper.CASE_REASON_SPENDING_LIMIT_EXCEPTION, res.messages[0].messageDetails, 'Response must be with error "Sync hasn\'t been performed: spending limit is too low"');
        System.assertEquals(1, cases.size(), 'Cases size should be equals 1');
        System.assertEquals('LBO: ' + DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION, cases[0].Subject, 'Case subject must be "LBO: Manual Order Required for Quote"');
        System.assertEquals(true, cases[0].Description.contains('Manual Order'), 'Case description should contains "Manual Order" in description');
        System.assertEquals(true, cases[0].Description.contains(CaseHelper.CASE_REASON_SPENDING_LIMIT_EXCEPTION), 'Case description must contains "Sync hasn\'t been performed: spending limit is too low" in description');
    }

    @isTest
    private static void testUpgradeCaseCreationLBOAccounts() {

        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO
            .replace(CHANGED_BILLING_ID, 'null')
            .replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID)
            .replace(PACKAGE_DURATION, Product2Helper.CHARGE_TERM_ANNUAL);
        qt.Initial_Term_months__c = '12';
        qt.Term_months__c = '12';
        qt.Start_Date__c = Date.today();
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Quantity = 5;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        Entitlement__c ent = queryEntitlement(ENTITLEMENT_NAME);
        ent.ChargeTerm__c = Product2Helper.CHARGE_TERM_ANNUAL;
        updateWithoutTriggers(ent);

        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new Mock());

        BILLING_INFO_SUMMARY_LICENSE_RESPONSE = BILLING_INFO_SUMMARY_LICENSE_RESPONSE.replace('LC_DL-UNL_50', Product2Helper.SUBSCRIPTION_LICENSE);

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.UPGRADE);

        Test.stopTest();

        List<Case> cases = queryCases();
        System.assertEquals(1, cases.size(), 'Cases size should be equals 1');
        for (Case c : cases) {
            if (c.Description.contains(CaseHelper.CASE_REASON_PLAN_CHANGED)) {
                System.assertEquals(true, c.Description.contains(CaseHelper.CASE_REASON_PLAN_CHANGED), 'Case description should contains "Plan on Quote was Changed" in description');
            }
            if (c.Description.contains(CaseHelper.CASE_REASON_PACKAGE_CHANGED)) {
                System.assertEquals(true, c.Description.contains(CaseHelper.CASE_REASON_PACKAGE_CHANGED), 'Case description should contains "Package on Quote was Upgraded/Downgraded" in description');
            }
        }
        System.assertEquals('LBO: ' + DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION, cases[0].Subject, 'Case subject must be "LBO: Manual Order Required for Quote"');
    }

    @isTest
    private static void testGetBillingOppDetail() {

        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.startTest();
        Opportunity reselectOpp = SyncWithNGBS.getOppBillingDetail(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, reselectOpp, 'Reselected Opportunity must be not null');
    }

    @isTest
    private static void testPhoenixConvertToPaidWithCaseCreation() {

        Account acc = queryAccount();
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO
            .replace(CHANGED_BILLING_ID, 'null')
            .replace(PACKAGE_CATALOG_ID, '231')
            .replace(PACKAGE_DURATION, Product2Helper.CHARGE_TERM_ANNUAL);
        qt.Initial_Term_months__c = '12';
        qt.Term_months__c = '12';
        qt.Start_Date__c = Date.today();
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Quantity = 5;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        Entitlement__c ent = queryEntitlement(ENTITLEMENT_NAME);
        ent.ChargeTerm__c = Product2Helper.CHARGE_TERM_ANNUAL;
        updateWithoutTriggers(ent);

        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
        NGBS_ACCOUNT_RESPONSE = NGBS_ACCOUNT_RESPONSE.replace('"offerType":"Regular"', '"offerType":null');
        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.CONVERT_TO_PAID);
        System.assertEquals(true, res.isError(), 'Response must return error');
        Test.stopTest();

        List<Case> cases = queryCases();

        System.assertEquals(1, cases.size(), 'Cases size should be equals 1');
        System.assertEquals('RingCentral Video: ' + DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION, cases[0].Subject, 'Case subject must be "RingCentral Video: Manual Order Required for Quote"');
        System.assertEquals(true, cases[0].Description.contains('Manual Order is required for this Quote'), 'Case description must contain "Manual Order is required for this Quote"');
        System.assertEquals(true, cases[0].Description.contains(CaseHelper.CASE_REASON_CONVERTED_TO_PAID), 'Case description must contain "Quote is Converted to Paid"');
    }

    @isTest
    private static void testPhoenixUpsellWithCaseCreation() {

        Account acc = queryAccount();
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO
            .replace(CHANGED_BILLING_ID, 'null')
            .replace(PACKAGE_CATALOG_ID, '231')
            .replace(PACKAGE_DURATION, Product2Helper.CHARGE_TERM_ANNUAL)
            .replace(Product2Helper.PRODUCT_OFFICE, Product2Helper.PRODUCT_MEETINGS);
        qt.Initial_Term_months__c = '12';
        qt.Term_months__c = '12';
        qt.Start_Date__c = Date.today();
        updateWithoutTriggers(qt);

        String packageInfoQLI = '{"Version":"1","q":null,"Price":null,"parent":null,"lbox":null,"Id":"231","duration":"Monthly","Discount":{"Value":0,"Type":"Money"},"categoryPath":"ITN","CategoryCode":"ITN"}';

        updateWithoutTriggers(qt.QuoteLineItems);
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Quantity = 5;
            qli.NewQuantity__c = 35;
            qli.Package_Info__c = packageInfoQLI;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        Entitlement__c ent = queryEntitlement(ENTITLEMENT_NAME);
        ent.ChargeTerm__c = Product2Helper.CHARGE_TERM_ANNUAL;
        updateWithoutTriggers(ent);

        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.UP_SELL);
        System.assertEquals(true, res.isError(), 'Response must return error');
        System.assertEquals('Error', res.messages[0].message, 'Message must be "Error"');
        System.assertEquals('Licenses are not synced with Service Web. Licenses should be added manually in Service Web.', res.messages[0].messageDetails, 'Message details must be "Licenses are not synced with Service Web. Licenses should be added manually in Service Web."');
        Test.stopTest();
        List<Case> cases = queryCases();

        System.assertEquals(1, cases.size(), 'Cases size must be equals 1');
        System.assertEquals('RingCentral Video: ' + DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION, cases[0].Subject, 'Case subject must be "RingCentral Video: Manual Order Required for Quote"');
        System.assertEquals(true, cases[0].Description.contains('Manual Order is required for this Quote'), 'Case description must contain "Manual Order is required for this Quote"');
        System.assertEquals(true, cases[0].Description.contains(CaseHelper.CASE_REASON_UPSELL), 'Case description must contain "Quote contains Upsell"');
    }

    @isTest
    private static void testUpgradeForLBOAccountsWOCases() {

        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO;
        qt.Initial_Term_months__c = '12';
        qt.Term_months__c = '12';
        qt.Start_Date__c = Date.today();
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        Entitlement__c ent = queryEntitlement(ENTITLEMENT_NAME);
        ent.PackageCatalogId__c = PACKAGE_CHANGED_CATALOG_ID;
        updateWithoutTriggers(ent);

        List<QuoteLineItem> qlis = queryQuoteLineItems();
        for (QuoteLineItem qli : qlis) {
            qli.Quantity = 5;
            qli.Entitlement__c = ent.Id;
        }
        updateWithoutTriggers(qlis);

        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.UPGRADE);

        Test.stopTest();

        Opportunity reselectOpp = queryOpportunity(OPP_NAME);
        System.assertEquals(true, reselectOpp.isUpgradeStepCompleted__c);
    }

    @isTest
    private static void testConvertToPaidWithCaseCreationForLBOAccounts() {

        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO
            .replace(CHANGED_BILLING_ID, 'null')
            .replace(PACKAGE_CATALOG_ID, '231')
            .replace(PACKAGE_DURATION, Product2Helper.CHARGE_TERM_ANNUAL);
        qt.Initial_Term_months__c = '12';
        qt.Term_months__c = '12';
        qt.Start_Date__c = Date.today();
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Quantity = 5;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        Entitlement__c ent = queryEntitlement(ENTITLEMENT_NAME);
        ent.ChargeTerm__c = Product2Helper.CHARGE_TERM_ANNUAL;
        updateWithoutTriggers(ent);

        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        NGBS_ACCOUNT_RESPONSE = NGBS_ACCOUNT_RESPONSE.replace('"offerType":"Regular",', '');

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.CONVERT_TO_PAID);
        System.assertEquals(true, res.isError(), 'Response must return error');
        Test.stopTest();

        List<Case> cases = queryCases();

        System.assertEquals(1, cases.size(), 'Cases size should be equals 1');
        System.assertEquals('RingCentral Video: ' + DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION, cases[0].Subject, 'Case subject must be "RingCentral Video: Manual Order Required for Quote"');
        System.assertEquals(true, cases[0].Description.contains('Manual Order is required for this Quote'), 'Case description must contain "Manual Order is required for this Quote"');
        System.assertEquals(true, cases[0].Description.contains(CaseHelper.CASE_REASON_CONVERTED_TO_PAID), 'Case description must contain "Quote is Converted to Paid"');
    }

    @isTest
    private static void testUpgradeWithoutCaseCreationLBOAccounts() {
        updateNGBSSettings();
        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        acc.Billing_ID__c = '123';
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO
            .replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID)
            .replace(PACKAGE_ID, BillingHttpRequestMock.PACKAGE_ID);
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Quantity = 5;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

//        Entitlement__c ent = queryEntitlement(ENTITLEMENT_NAME);
//        ent.ChargeTerm__c = Product2Helper.CHARGE_TERM_ANNUAL;
//        updateWithoutTriggers(ent);

        Opportunity opp = queryOpportunity(OPP_NAME);

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.endpointToBodyMap = new Map<String, BillingHttpRequestMock.MockInfo>{
            '/summary?shortView=true' => new BillingHttpRequestMock.MockInfo(
                NGBS_ACCOUNT_RESPONSE
                    .replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID)
                    .replace(PACKAGE_ID, BillingHttpRequestMock.PACKAGE_ID)
            )
        };
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.UPGRADE);

        Test.stopTest();

        Opportunity reselectOpp = queryOpportunity(OPP_NAME);

        System.assertEquals(true, reselectOpp.isUpgradeStepCompleted__c, 'isUpgradeStepCompleted must be true');
    }

    @isTest
    private static void testGetOppBillingDetail() {
        Opportunity opp = queryOpportunity(OPP_NAME);
        Test.startTest();
        Opportunity reselectOpp = SyncWithNGBS.getOppBillingDetail(opp.Id);
        Test.stopTest();
        System.assertNotEquals(null, reselectOpp.Id, 'Opportuntiy must be returned');
    }

    @isTest
    private static void testCONVERT_TO_PAIDStep() {

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        updateWithoutTriggers(qt);

        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.CONVERT_TO_PAID); // S1
        Test.stopTest();

        System.assert(res.isSuccess(), 'Response should return success status');
    }

    @isTest
    private static void verifyGetSyncInfoReturnCorrectValue() {
        List<String> stepNames = new List<String>{
            SWNStep.CONTRACT_SYNC,
            SWNStep.DISCOUNT_SYNC,
            SWNStep.UP_SELL,
            SWNStep.DOWN_SELL,
            SWNStep.ORDER,
            SWNStep.UPGRADE,
            SWNStep.REPRICE_SYNC,

            SWNStep.UPDATE_LICENSE_LIMITS,
            SWNStep.CONTRACT_CANCELLATION,
            SWNStep.CONVERT_TO_PAID,

            SWNStep.SYNC_TO_CCB_UPSELL,
            SWNStep.SYNC_TO_CCB_DOWNSELL,
            SWNStep.SYNC_TO_CCB_UPGRADE
        };
        Map<String, String> statusMap = new Map<String, String>{
            SWNStep.CONTRACT_SYNC => SWNHelper.NOT_SYNCED,
            SWNStep.DISCOUNT_SYNC => SWNHelper.NOT_SYNCED,
            SWNStep.UP_SELL => SWNHelper.NOT_SYNCED,
            SWNStep.DOWN_SELL => SWNHelper.SYNCED,
            SWNStep.ORDER => SWNHelper.SYNCED,
            SWNStep.UPGRADE => SWNHelper.SYNCED,
            SWNStep.REPRICE_SYNC => SWNHelper.NOT_SYNCED,

            SWNStep.UPDATE_LICENSE_LIMITS => SWNHelper.SYNCED,
            SWNStep.CONTRACT_CANCELLATION => SWNHelper.SYNCED,
            SWNStep.CONVERT_TO_PAID => SWNHelper.NOT_SYNCED,

            SWNStep.SYNC_TO_CCB_UPSELL => SWNHelper.SYNCED,
            SWNStep.SYNC_TO_CCB_DOWNSELL => SWNHelper.SYNCED,
            SWNStep.SYNC_TO_CCB_UPGRADE => SWNHelper.SYNCED
        };

        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.isOrderStepCompleted__c = true;
        opp.isDownsellStepCompleted__c = true;
        opp.isUpgradeStepCompleted__c = true;
        opp.isLicenseLimitsSynced__c = true;
        opp.isContractCancelled__c = true;

        updateWithoutTriggers(opp);
        Quote qt = queryQuote(OPP_NAME);
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
        NGBS_ACCOUNT_RESPONSE = NGBS_ACCOUNT_RESPONSE.replace('"offerType":"Regular"', '"offerType":null');
        Response res = SyncWithNGBS.getSyncInfo(qt.Id, stepNames);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncInfo should return response with Success status');

        for(String stepName : stepNames) {
            Assert.isTrue(res.data.containsKey(String.valueOf(stepName)), 'response should contain '+stepName+' data');
            Assert.areEqual(statusMap.get(stepName), ((SWNStepInfo) res.data.get(String.valueOf(stepName))).status, stepName + ' should not be ' + statusMap.get(stepName));
        }

        Assert.isTrue(res.data.containsKey('syncInfo'), 'response should contain syncInfo');
    }

    // Upsell
    @isTest
    private static void verifySyncToCCBUpsellStepReturnSignupLink() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, false)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, false)
            .create();

        Triggers.switchOff();
        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME + '1',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.IsMultiProductTechnicalOpportunity__c => false
            })
            .create()
            .getRecord();

        Quote masterQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.Tier_Name__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        opp.IsMultiProductTechnicalOpportunity__c = true;
        opp.MasterOpportunity__c = masterOpp.Id;
        updateWithoutTriggers(opp);

        Quote qt = queryQuote(OPP_NAME);
        qt.isTermination__c = false;
        qt.IsMultiProductTechnicalQuote__c = true;
        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        qt.MasterQuote__c = masterQt.Id;
        updateWithoutTriggers(qt);
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 100;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        Response result = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_CCB_UPSELL);
        Test.stopTest();

        System.assert(result.isSuccess(), 'should be success');
        System.assert((String) result.getData('redirectUrl') != null, 'should return redirect url');
    }

    @isTest
    private static void verifySyncToCCBUpsellStepMarkOpportunityAsSynced() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, false)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, false)
            .create();
        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.isTermination__c = false;
        opp.Tier_Name__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        updateWithoutTriggers(opp);

        Quote qt = queryQuote(OPP_NAME);
        qt.IsMultiProductTechnicalQuote__c = true;
        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 30;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        System.assert(!opp.isUpsellStepCompleted__c, 'initially should false');

        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        Response result = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_CCB_UPSELL);
        Test.stopTest();

        opp = queryOpportunity(OPP_NAME);

        System.assert(result.isSuccess(), 'should be success');
        System.assert(opp.isUpsellStepCompleted__c, 'should be set as true');
    }

    @isTest
    private static void verifySyncToCCBUpsellStepMarkServiceInfoAsSynced() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
                .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, false)
                .setField(Feature_Toggle__c.EnableMultiProduct__c, false)
                .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
                .create();
        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.isTermination__c = false;
        opp.Tier_Name__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        updateWithoutTriggers(opp);

        Quote qt = queryQuote(OPP_NAME);
        qt.IsMultiProductTechnicalQuote__c = true;
        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        updateWithoutTriggers(qt);
        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    ServiceInfo__c.Quote__c => qt.Id
                }
            )
            .create()
            .getRecord();

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 30;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        serviceInfo = (ServiceInfo__c) new ListOptional(
            new ServiceInfoSelector()
                .selectServiceInfoForNGBSSyncablesById(serviceInfo.Id)
                .executeQuery())
            .getFirst();

        System.assert(!serviceInfo.UpsellStepStatus__c, 'initially should false');

        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        Response result = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_CCB_UPSELL);
        Test.stopTest();

        serviceInfo = (ServiceInfo__c) new ListOptional(
            new ServiceInfoSelector()
                .selectServiceInfoForNGBSSyncablesById(serviceInfo.Id)
                .executeQuery())
            .getFirst();

        System.assert(result.isSuccess(), 'should be success');
        System.assert(serviceInfo.UpsellStepStatus__c, 'should be set as true');
    }

    @isTest
    private static void verifySyncToCCBUpsellStepMarkOpportunityAsSyncedWithMPEnabled() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, true)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, true)
            .create();
        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.isTermination__c = false;
        opp.Tier_Name__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        updateWithoutTriggers(opp);

        Quote qt = queryQuote(OPP_NAME);
        qt.IsMultiProductTechnicalQuote__c = true;
        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 30;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        System.assert(!opp.isUpsellStepCompleted__c, 'initially should false');

        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        Response result = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_CCB_UPSELL);
        Test.stopTest();

        opp = queryOpportunity(OPP_NAME);

        System.assert(result.isSuccess(), 'should be success');
        System.assert(opp.isUpsellStepCompleted__c, 'should be set as true');
    }

    // Downsell
    @isTest
    private static void verifySyncToCCBDownsellStepReturnSignupLink() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, false)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, false)
            .create();

        Triggers.switchOff();
        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME + '1',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.IsMultiProductTechnicalOpportunity__c => false
            })
            .create()
            .getRecord();

        Quote masterQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.Tier_Name__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        opp.IsMultiProductTechnicalOpportunity__c = true;
        opp.MasterOpportunity__c = masterOpp.Id;
        updateWithoutTriggers(opp);

        Quote qt = queryQuote(OPP_NAME);
        qt.isTermination__c = false;
        qt.IsMultiProductTechnicalQuote__c = true;
        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        qt.MasterQuote__c = masterQt.Id;
        updateWithoutTriggers(qt);
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 1;
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        Response result = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_CCB_DOWNSELL);
        Test.stopTest();

        System.assert(result.isSuccess(), 'should be success');
        System.assert((String) result.getData('redirectUrl') != null, 'should return redirect url');
    }

    @isTest
    private static void verifySyncToCCBDownsellStepMarkOpportunityAsSynced() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, false)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, true)
            .create();

        Triggers.switchOff();
        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME + '1',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.IsMultiProductTechnicalOpportunity__c => false
            })
            .create()
            .getRecord();

        Quote masterQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.isTermination__c = false;
        opp.Tier_Name__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        opp.MasterOpportunity__c = masterOpp.Id;
        updateWithoutTriggers(opp);

        Quote qt = queryQuote(OPP_NAME);
        qt.IsMultiProductTechnicalQuote__c = true;
        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        qt.MasterQuote__c = masterQt.Id;
        updateWithoutTriggers(qt);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 1;

            BillingWrappers.QLIPackageInfo pInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            pInfo.duration = Product2Helper.CHARGE_TERM_ONE_TIME;
            qli.PackageInfo__c = JSON.serialize(pInfo);
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        System.assert(!opp.isDownsellStepCompleted__c, 'initially should false');

        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        Response result = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_CCB_DOWNSELL);
        Test.stopTest();

        opp = queryOpportunity(OPP_NAME);

        System.assert(result.isSuccess(), 'should be success');
        System.assert(opp.isDownsellStepCompleted__c, 'should be set as true');
    }

    // Upgrade CCB
    @isTest
    private static void verifySyncToCCBUpgradeStepMarkOpportunityAsSynced() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, false)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, false)
            .create();
        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.isTermination__c = false;
        opp.Tier_Name__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        updateWithoutTriggers(opp);

        Quote qt = queryQuote(OPP_NAME);
        qt.IsMultiProductTechnicalQuote__c = true;
        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;

        BillingWrappers.QuotePackageInfoWrapper qtPInfoWrapper = new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c);
        BillingWrappers.QuotePackageInfo qtPInfo = qtPInfoWrapper.getPackageInfo();
        qtPInfo.packageInfo.id = PACKAGE_ID;
        qtPInfo.packageInfo.catalogId = PACKAGE_CHANGED_CATALOG_ID;
        qtPInfo.packageInfo.name = 'test billing package';
        qtPInfoWrapper.setPackageInfo(qtPInfo);

        qt.Package_Info__c = qtPInfoWrapper.toString();
        updateWithoutTriggers(qt);


        System.assert(!opp.isUpgradeStepCompleted__c, 'initially should false');

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.endpointToBodyMap = new Map<String, BillingHttpRequestMock.MockInfo>{
            '/summary?shortView=true' => new BillingHttpRequestMock.MockInfo(
                NGBS_ACCOUNT_RESPONSE.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID)
            )
        };
        Test.setMock(HttpCalloutMock.class, testMock);
        Test.startTest();
        Response result = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_CCB_UPGRADE);
        Test.stopTest();

        opp = queryOpportunity(OPP_NAME);

        System.assert(result.isSuccess(), 'should be success');
        System.assert(opp.isUpgradeStepCompleted__c, 'should be set as true');
    }

    @isTest
    private static void verifySyncToCCBUpgradeStepMarkOpportunityAsSyncedWithMPEnabled() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, true)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, true)
            .create();
        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.isTermination__c = false;
        opp.Tier_Name__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        updateWithoutTriggers(opp);

        Quote qt = queryQuote(OPP_NAME);
        qt.IsMultiProductTechnicalQuote__c = true;
        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;

        BillingWrappers.QuotePackageInfoWrapper qtPInfoWrapper = new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c);
        BillingWrappers.QuotePackageInfo qtPInfo = qtPInfoWrapper.getPackageInfo();
        qtPInfo.packageInfo.id = PACKAGE_ID;
        qtPInfo.packageInfo.catalogId = PACKAGE_CHANGED_CATALOG_ID;
        qtPInfo.packageInfo.name = 'test billing package';
        qtPInfoWrapper.setPackageInfo(qtPInfo);

        qt.Package_Info__c = qtPInfoWrapper.toString();
        updateWithoutTriggers(qt);


        System.assert(!opp.isUpgradeStepCompleted__c, 'initially should false');

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.endpointToBodyMap = new Map<String, BillingHttpRequestMock.MockInfo>{
            '/summary?shortView=true' => new BillingHttpRequestMock.MockInfo(
                NGBS_ACCOUNT_RESPONSE.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID)
            )
        };
        Test.setMock(HttpCalloutMock.class, testMock);
        Test.startTest();
        Response result = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_CCB_UPGRADE);
        Test.stopTest();

        opp = queryOpportunity(OPP_NAME);

        System.assert(result.isSuccess(), 'should be success');
        System.assert(opp.isUpgradeStepCompleted__c, 'should be set as true');
    }

    @isTest
    private static void verifySyncToCCBUpgradeStepReturnSignupLink() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, false)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, false)
            .create();

        Triggers.switchOff();
        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME + '1',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.IsMultiProductTechnicalOpportunity__c => false
            })
            .create()
            .getRecord();

        Quote masterQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.isTermination__c = false;
        opp.Tier_Name__c = OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE;
        opp.MasterOpportunity__c = masterOpp.Id;
        updateWithoutTriggers(opp);
        Quote qt = queryQuote(OPP_NAME);
        qt.IsMultiProductTechnicalQuote__c = true;
        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE;
        qt.MasterQuote__c = masterQt.Id;

        BillingWrappers.QuotePackageInfoWrapper qtPInfoWrapper = new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c);
        BillingWrappers.QuotePackageInfo qtPInfo = qtPInfoWrapper.getPackageInfo();
        qtPInfo.duration = 'Annual';
        qtPInfo.packageInfo.id = PACKAGE_ID;
        qtPInfoWrapper.setPackageInfo(qtPInfo);

        qt.Package_Info__c = qtPInfoWrapper.toString();

        updateWithoutTriggers(qt);

        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        Response result = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_CCB_UPGRADE);
        Test.stopTest();

        System.assert(result.isSuccess(), 'should be success');
        System.assert((String) result.getData('redirectUrl') != null, 'should return redirect url');
    }

    @isTest
    private static void verifySyncToNGBSDownsellStepCompleted() {
        Opportunity opp = queryOpportunity(OPP_NAME);
        Quote qt = queryQuote(OPP_NAME);
        qt.ServiceName__c = OpportunityHelper.TIER_RC_CONTACT_CENTER;
        qt.IsMultiProductTechnicalQuote__c = true;
        updateWithoutTriggers(qt);
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 1;

            BillingWrappers.QLIPackageInfo pInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            pInfo.duration = Product2Helper.CHARGE_TERM_ONE_TIME;
            qli.PackageInfo__c = JSON.serialize(pInfo);
        }
        updateWithoutTriggers(qt.QuoteLineItems);

        System.assert(!opp.isDownsellStepCompleted__c, 'initially should false');

        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        Response result = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_NGBS_DOWNSELL);
        Test.stopTest();

        opp = queryOpportunity(OPP_NAME);

        System.assert(result.isSuccess(), 'should be success');
        System.assert(opp.isDownsellStepCompleted__c, 'should be set as true');
    }

    // TODO: rewrite the test when Termination Single Product flow will be aligned with MPUB (LTR-569)
    // @isTest
    private static void testEngageAccountTermination() {
        Test.setMock(HttpCalloutMock.class, new EngageAccountTerminationMock());
        Account acc = queryAccount();
        acc.RC_User_ID__c = '130021990';
        updateWithoutTriggers(acc);
        Opportunity opp = queryOpportunity(TERMINATION_OPP_NAME);
        Quote qt = queryQuote(OPP_NAME);

        Test.startTest();
        Response stepRes = SyncWithNGBS.getSyncScenario(qt.Id);
        Response syncInfoRes = SyncWithNGBS.getSyncInfo(qt.Id, new List<String> {SWNStep.ENGAGE_ACCOUNT_TERMINATION});
        Response syncRes = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.ENGAGE_ACCOUNT_TERMINATION);
        Test.stopTest();

        List<Quote> quoteList = new QuoteSelector()
            .selectQuoteForSyncWithNGBSByQuoteId(qt.Id).executeQuery();
        System.assertEquals(0, quoteList.size(), 'quote should not be exist');
        System.assertEquals(true, syncInfoRes.isSuccess(), 'getSyncInfo should return response with Success status');

        Opportunity reselectOpp = queryOpportunity(TERMINATION_OPP_NAME);
        System.assertEquals(true, reselectOpp.isTerminationStepCompleted__c, 'isTerminationStepCompleted field should be true');

        System.assertEquals(true, stepRes.isSuccess(), 'getSyncScenario should return response with Success status');
        System.assertEquals(true, stepRes.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) stepRes.data.get('scenario');

        System.assertEquals(true, sc.stepNames.contains(SWNStep.ENGAGE_ACCOUNT_TERMINATION), 'terminationStep must be in sc');
        System.assertEquals(1, sc.stepNames.size(), 'sc must have 1 steps');
    }

    @isTest
    private static void testUpdateSyncStepExecutorInfo() {
        Opportunity opp1 = queryOpportunity(OPP_NAME);
        System.assertEquals(null, opp1.NGBS_Sync_Executor_Info__c);
        new SWNSyncDiscountRunner().updateSyncStepExecutorInfo(
            new NGBSSyncables.OpportunitySync(opp1),
            SWNStep.DISCOUNT_SYNC
        );
        Opportunity opp2 = queryOpportunity(OPP_NAME);
        System.assertNotEquals(null, opp2.NGBS_Sync_Executor_Info__c);
        SWNActionRunner.SyncStepExecutorInfo executorInfo = (SWNActionRunner.SyncStepExecutorInfo) JSON.deserialize(opp2.NGBS_Sync_Executor_Info__c, SWNActionRunner.SyncStepExecutorInfo.class);
        System.assertEquals(SWNStep.DISCOUNT_SYNC, executorInfo.stepName);
    }

    @isTest
    private static void testUpdatingFedRampStateToTrueWithNgbsApi() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        Triggers.switchOff();
        Quote qtFedramp = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => queryOpportunity(FEDRAMP_OPP_NAME).Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        Response result = SyncWithNGBS.getSyncScenario(qtFedramp.Id);
        Test.stopTest();
        System.assertEquals(true, NGBSAPI.getIsFedRampState(), 'Set flag isFedRamp in NGBSAPI the same as on Opportunity');
    }

    @isTest
    private static void testFinalizeStepWithInvalidParams() {
        Test.startTest();

        try {
            Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
                })
                .create()
                .getRecord();

            SWNStep testStep = new SWNStep.SWNStepBuilder()
                .withName(SWNStep.SYNC_TO_ICB)
                .withLabel('test step')
                .build();
            testStep.quoteFieldsToUpdate.put('Status', QuoteHelper.QUOTE_STATUS_TERMINATED);

            new SWNSyncToICBOrInContactRunner().finalizeStep(
                testStep,
                'test scenario',
                new NGBSSyncables.OpportunitySync(testOpp),
                null
            );
            System.assert(false, 'Exception should be thrown');
        } catch (Exception ex) {
            System.assert(
                ex.getMessage().contains('Cannot update Quote due to missing Quote.Id'),
                'Unexpected exception message: ' + ex.getMessage()
            );
        }
        Test.stopTest();
    }

    @isTest
    private static void testFinalizeStep() {
        Triggers.switchOff();
        IValueProvider accountId = ValueProviderBuilder.provideGenericParent(Account.SObjectType);

        new SObjectBuilder(DealDeskCaseDescription__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DealDeskCaseDescription__c.Account__c => accountId,
                DealDeskCaseDescription__c.CaseDescription__c => 'Test Description'
            })
            .create();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => accountId,
                Opportunity.isUpsellStepCompleted__c => true,
                Opportunity.CloseDate => System.today(),
                Opportunity.SyncInfo__c => '{"timeStampMap":{"SYNC_INVOICE":"2022-02-08T14:08:19.649Z","CONTRACT_SYNC":"2022-02-08T14:06:08.971Z", "UP_SELL": "2022-02-08T14:06:09.971Z"},"scenarioName":"WHOLESALE_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE","userNameMap":{"test":"test"}}'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();

        Triggers.switchOff();
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => QUOTE_NAME,
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        SWNStep testStep = new SWNStep.SWNStepBuilder()
            .withName(SWNStep.SYNC_TO_ICB)
            .withLabel('test step')
            .build();
        NGBSSyncables.ISyncable syncable = new NGBSSyncables.OpportunitySync(testOpp);
        syncable.setFSCSynced();

        testStep.quoteFieldsToUpdate.put('Id', testQuote.Id);
        testStep.quoteFieldsToUpdate.put('Status', QuoteHelper.QUOTE_STATUS_TERMINATED);

        CaseHelper.doChainJob = false;

        new SWNSyncToICBOrInContactRunner().finalizeStep(
            testStep,
            'WHOLESALE_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE',
            syncable,
            null
        );
        Opportunity reselectedOpp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<SObjectField>{
                Opportunity.isFSCSynced__c
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testOpp.Id })
            .executeQuery()
            .get(0);
        System.assertEquals(
            true,
            reselectedOpp.isFSCSynced__c,
            'opportunity fields specified in Step.opportunityFieldsToUpdate map ' +
            'should be updated with corresponding values'
        );
        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Id>{ testQuote.Id })
            .selectField(Quote.Status)
            .executeQuery()
            .get(0);
        Test.stopTest();
        System.assertEquals(
            QuoteHelper.QUOTE_STATUS_TERMINATED,
            reselectedQuote.Status,
            'Quote fields specified in Step.quoteFieldsToUpdate map ' +
            'should be updated with corresponding values'
        );
    }

    @isTest
    private static void testCreateDealDeskCaseDescriptions() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Shipping_Tab_New_Business__c, true)
            .create();

        LicensesLabelsOverride__c licensesLabelsOverride = (LicensesLabelsOverride__c) new SObjectBuilder(LicensesLabelsOverride__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                LicensesLabelsOverride__c.Name => 'Amazon US Initial Order Type',
                LicensesLabelsOverride__c.BusinessIdentityId__c => '62005',
                LicensesLabelsOverride__c.Label__c => 'initialOrderType'
            })
            .create()
            .getRecord();

        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.Id => ValueProviderBuilder.provideDummyId(NGBSProcessOrderCaseTemplate__mdt.SObjectType),
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => ValueProviderBuilder.provideList(new List<String>{
                    DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                    DealDeskCaseDescriptionHelper.CHANGE_ORDER_CASE_TEMPLATE_TYPE
                }),
                NGBSProcessOrderCaseTemplate__mdt.ShippingReq__c => Product2Helper.SHIPPING_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.UpsellType__c => Product2Helper.ORDER_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => 'L1',
                NGBSProcessOrderCaseTemplate__mdt.Subject__c => ValueProviderBuilder.provideList(new List<String>{
                    DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                    DealDeskCaseDescriptionHelper.CHANGE_ORDER_CASE_TEMPLATE_TYPE
                }),
                NGBSProcessOrderCaseTemplate__mdt.Owner__c => ValueProviderBuilder.provideList(new List<String>{
                    UserInfo.getUserId(),
                    '005_who_pretends_to_be_a_user_id'
                }),
                NGBSProcessOrderCaseTemplate__mdt.Description__c => ValueProviderBuilder.provideUniqueString('Test Template')
            })
            .quantity(2)
            .build()
            .getRecords();

        DealDeskCaseDescriptionHelper.initializeTemplatesMap();

        Triggers.switchOff();
        Account acc = queryAccount();

        acc.RC_User_ID__c = '111111';
        acc.Billing_ID__c = '222222';
        update acc;

        Opportunity opp = queryOpportunity(OPP_NAME);

        Quote qt = queryQuote(OPP_NAME);

        qt.Account__c = acc.Id;
        qt.Enabled_LBO__c = true;
        qt.isPrimary__c = true;
        qt.BusinessIdentity__c = '{"currency":"USD","biId":"62005"}';
        update qt;

        Test.startTest();
        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Test product',
                Product2.IsActive => true,
                Product2.ExtID__c => 'L1',
                Product2.ShippingType__c => Product2Helper.SHIPPING_TYPE_MANUAL,
                Product2.UpsellType__c => Product2Helper.ORDER_TYPE_MANUAL
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new PricebookEntrySelector()
            .getAllPBEs()
            .executeQuery()
            .get(0);

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.UnitPrice => pbe.UnitPrice,
                QuoteLineItem.PackageInfo__c => '{}'
            })
            .create();
        Triggers.SwitchOn();

        Response res = SyncWithNGBS.createDealDeskCaseDescriptions(qt.Id);

        List<DealDeskCaseDescription__c> dealDeskCaseDescriptions = (List<DealDeskCaseDescription__c>) new DealDeskCaseDescriptionSelector()
            .selectDealDeskCaseDescriptionsForAccounts(new List<Object> {new Set<Id> {acc.Id}})
            .executeQuery();
        Test.stopTest();

        System.assertEquals(2, dealDeskCaseDescriptions.size(), 'SyncWithNGBS.createDealDeskDescriptions() should create two DealDeskCaseDescription__c records');
    }

    @isTest
    private static void verifySyncScenarioWithSpendingLimitRetrieveStep() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        acc.Billing_ID__c = '11111';
        acc.RC_User_ID__c = '2222';

        Opportunity opp = queryOpportunity(OPP_NAME);

        Quote qt = queryQuote(OPP_NAME);
        qt.Enabled_LBO__c = true;
        qt.Total_One_Time__c = 100000;
        qt.Upsell_Status__c = QuoteHelper.STATUS_NEW_CUSTOMER;
        Triggers.switchOff();
        Test.startTest();
        String packageQLIInfoHD139 = '{"Version":"1","q":null,"Price":null,"parent":null,"lbox":null,"Id":"18","duration":"One - Time","Discount":{"Value":0,"Type":"Money"},"categoryPath":"HD","CategoryCode":"HD"}';
        Product2 productDevice = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Polycom VVX501 with 1 Expansion Module',
                Product2.ExtId__c => 'LC_HD_139',
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productDevice.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qliDevice = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDevice.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 500,
                QuoteLineItem.NewQuantity__c => 500,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.PackageInfo__c => packageQLIInfoHD139
            })
            .create()
            .getRecord();

        Approval__c creditLimitApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Credit Limit Increase',
                    Approval__c.Account__c => acc.Id,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.Quote__c => qt.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE,
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.DateOfSignOff__c => System.today()
                })
            .create()
            .getRecord();
        Triggers.switchOn();
        updateWithoutTriggers(new List<Sobject>{acc, qt});
        Test.stopTest();

        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE);

        Opportunity reselectOpp = (Opportunity) new OpportunitySelector().selectOpportunityForSyncWithNGBS(opp.Id)
            .executeQuery()
            .get(0);
        System.assertEquals(true, res.isSuccess(), 'Response must be with success status');
        System.assertEquals('Spending limits retrieved',res.messages[0].message, 'Response message must be "Spending limits retrieved"');
        System.assertEquals('Spending limits retrieved successfully', res.messages[0].messageDetails, 'Response message details must be "Spending limits retrieved successfully"');
        System.assertEquals(Response.STATUS_SUCCESS, res.messages[0].severity, 'Response message must be with success status');
        System.assertEquals(true, reselectOpp.IsSpendingLimitRetrieveStepCompleted__c, 'IsSpendingLimitRetrieveStepCompleted field must be true');
    }

    private static void updateNGBSSettings() {
        NGBS_Settings__c settings = NGBS_Settings__c.getOrgDefaults();
        settings.BaseEndpoint__c = 'http://fake-billing-api';
        settings.CatalogPath__c = '/restapi/v1.0/catalog';
        settings.AccountManagerPath__c = '/restapi/account-manager/v1.0';
        updateWithoutTriggers(settings);
    }

    @isTest
    private static void verifySyncToCCBDownsellStepCreatesDownsellCase() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.EnableMultiProduct__c => true,
                Feature_Toggle__c.EnableUILessProcessOrderEngage__c => true,
                Feature_Toggle__c.EnableSimplifiedDownsellForRingCX__c => true
            })
            .create();

        Triggers.switchOff();
        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME + '1',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.IsMultiProductTechnicalOpportunity__c => false
            })
            .create()
            .getRecord();

        Quote masterQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.isTermination__c = false;
        opp.Tier_Name__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        opp.MasterOpportunity__c = masterOpp.Id;
        // intentionally set to false to check if it will be set to true
        opp.IsDownsellCaseCreated__c = false;
        updateWithoutTriggers(opp);

        Quote qt = queryQuote(OPP_NAME);
        qt.IsMultiProductTechnicalQuote__c = true;
        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY;
        qt.MasterQuote__c = masterQt.Id;
        updateWithoutTriggers(qt);

        List<Product2> productsToUpdate = new List<Product2>();
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 1;

            BillingWrappers.QLIPackageInfo pInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            pInfo.duration = Product2Helper.CHARGE_TERM_ONE_TIME;
            qli.PackageInfo__c = JSON.serialize(pInfo);
            Product2 prod = new Product2(Id = qli.Product2Id, downsellType__c = Product2Helper.PRODUCT_DOWNSELL_TYPE_AUTO_WITH_CASE);
            productsToUpdate.add(prod);
        }
        updateWithoutTriggers(qt.QuoteLineItems);
        updateWithoutTriggers(productsToUpdate);
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            Response firstAttemptResponse = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_CCB_DOWNSELL);
        Test.stopTest();

        opp = queryOpportunity(OPP_NAME);

        Assert.isTrue(opp.IsDownsellCaseCreated__c, 'case should be created');
    }

    @isTest
    static void testFilterQuoteLineItems_HiddenLicense() {
        // Arrange
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>{
            new QuoteLineItem(Product2 = new Product2(Family = 'OTHER'), isHiddenLicense__c = false),
            new QuoteLineItem(Product2 = new Product2(Family = 'OTHER'), isHiddenLicense__c = true)
        };

        // Act
        List<QuoteLineItem> filteredList = SWNHelper.filterQuoteLineItems(quoteLineItems);

        // Assert
        System.assertEquals(1, filteredList.size());
        System.assertEquals(false, filteredList[0].isHiddenLicense__c);
    }

    @isTest
    static void testFilterQuoteLineItems_HiddenProductFamily() {
        // Arrange
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>{
            new QuoteLineItem(Product2 = new Product2(Family = Product2Helper.FAMILY_FEE)),
            new QuoteLineItem(Product2 = new Product2(Family = Product2Helper.FAMILY_TAXES)),
            new QuoteLineItem(Product2 = new Product2(Family = Product2Helper.FAMILY_TECHNICAL_LICENSE)),
            new QuoteLineItem(Product2 = new Product2(Family = 'OTHER'))
        };

        // Act
        List<QuoteLineItem> filteredList = SWNHelper.filterQuoteLineItems(quoteLineItems);

        // Assert
        System.assertEquals(1, filteredList.size());
        System.assertEquals('OTHER', filteredList[0].Product2.Family);
    }

    @isTest
    private static void testCreateDownsellCase() {
        Quote qt = queryQuotePlus(OPP_NAME);
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 0;
            qli.Zero_Quantity__c = false;
            qli.Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        }

        Opportunity opp = queryOpportunity(OPP_NAME);
        NGBSSyncables.ISyncable syncable = new NGBSSyncables.OpportunitySync(opp);

        String bodyForMock = '[{' +
            '"amount": 120009.99,' +
            '"catalogId": "LC_HD_4",' +
            '"discountAmount": 0,' +
            '"qty": 2001' +
            '}]';
        BillingHttpRequestMock mockNGBSBillingInfoSummaryLicenses = new BillingHttpRequestMock();
        mockNGBSBillingInfoSummaryLicenses.body = bodyForMock;
        mockNGBSBillingInfoSummaryLicenses.code = 200;
        mockNGBSBillingInfoSummaryLicenses.status = 'Completed';

        Test.setMock(HttpCalloutMock.class, mockNGBSBillingInfoSummaryLicenses);

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = qt;
        sdc.syncable = syncable;
        sdc.qlis = qt.QuoteLineItems;
        sdc.costCenters = new List<Cost_Center__c>();

        Test.startTest();
            SWNHelper.createDownsellCase(sdc);
        Test.stopTest();

        List<Case> cases = (List<Case>) new CaseSelector()
            .newQueryFactory()
            .setCondition('Subject = :bind0 AND Opportunity_Reference__c = :bind1')
            .setQueryBindings(new List<Object>{ DealDeskCaseGenerator.CASE_SUBJECT_DOWNSELL_SIMPLIFIED_LBO, opp.Id })
            .selectFields(new List<Schema.SObjectField> { Case.Subject })
            .executeQuery();

        System.assert(cases.size() > 0, 'case should be created');
    }

    @isTest
    private static void verifySyncToCCBUpgradeWithSimplifiedLboDownsell() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, true)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, true)
            .setField(Feature_Toggle__c.EnableSimplifiedDownsellForRingCX__c, true)
            .create();

        Triggers.switchOff();
        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME + '1',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.IsMultiProductTechnicalOpportunity__c => false
            })
            .create()
            .getRecord();

        Quote masterQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Opportunity opp = queryOpportunity(OPP_NAME);
        opp.isTermination__c = false;
        opp.Tier_Name__c = OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE;
        opp.MasterOpportunity__c = masterOpp.Id;
        updateWithoutTriggers(opp);
        Quote qt = queryQuote(OPP_NAME);
        qt.IsMultiProductTechnicalQuote__c = true;
        qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE;
        qt.MasterQuote__c = masterQt.Id;

        BillingWrappers.QuotePackageInfoWrapper qtPInfoWrapper = new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c);
        BillingWrappers.QuotePackageInfo qtPInfo = qtPInfoWrapper.getPackageInfo();
        qtPInfo.duration = 'Annual';
        qtPInfo.packageInfo.id = PACKAGE_ID;
        qtPInfoWrapper.setPackageInfo(qtPInfo);

        qt.Package_Info__c = qtPInfoWrapper.toString();

        updateWithoutTriggers(qt);

        Triggers.switchOff();
        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'SA SEAT',
                Product2.ExtId__c => 'SA_SEAT',
                Product2.downsellType__c => product2helper.PRODUCT_DOWNSELL_TYPE_AUTO_WITH_CASE
            })
            .create()
            .getRecords();

        List<PricebookEntry> pbes = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => products[0].Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecords();

        List<Entitlement__c> ents = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => 'SA_SEAT',
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => opp.AccountId,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Quantity__c => 10,
                Entitlement__c.Product__c => products[0].Id,
                Entitlement__c.Quote__c => qt.Id
            })
            .create()
            .getRecords();

        BillingWrappers.QLIPackageInfo qliPackageInfo = new BillingWrappers.QLIPackageInfo(TestDataGenerator.TEST_PACKAGE_INFO);
        qliPackageInfo.CategoryCode = 'SA';
        qliPackageInfo.categoryPath = 'SA';
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => products[0].Id,
                QuoteLineItem.PricebookEntryId => pbes[0].Id,
                QuoteLineItem.Quantity => -5,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Entitlement__c => ents[0].Id,
                QuoteLineItem.PackageInfo__c => JSON.serialize(qliPackageInfo),
                QuoteLineItem.ChargeTerm__c => 'Annual'
            })
            .create()
            .getRecords();
        Triggers.switchOn();

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            Response result = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.SYNC_TO_CCB_UPGRADE);
        Test.stopTest();

        opp = queryOpportunity(OPP_NAME);

        System.assert(result.isSuccess(), 'should be success');
        System.assert(opp.IsDownsellCaseCreated__c, 'should be set as true');
    }

    @isTest
    private static void testDownsellCaseCreationLBOAccountsMPUBAndSimplifiedLBODownsell() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true,
                Feature_Toggle__c.EnableSimplifiedLBODownsell__c  => true
            })
            .create();

        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        List<Entitlement__c> ents = new List<Entitlement__c>();
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Zero_Quantity__c = false;
            qli.PackageInfo__c = PACKAGE_INFO_QLI_WITH_LBOX;
            qli.Quantity = -2;
            qli.NewQuantity__c = 17;
            ents.add(new Entitlement__c(Id = qli.Entitlement__c, Quantity__c = 16));
        }
        updateWithoutTriggers(qt.QuoteLineItems);
        updateWithoutTriggers(ents);
        Opportunity opp = queryOpportunity(OPP_NAME);

        Triggers.switchOff();
        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => acc.Id,
                Package__c.Account_Package_Id__c => acc.Billing_ID__c
            })
            .create()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => qt.Id,
                ServiceInfo__c.BillingPackage__c => pack.Id
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.DOWN_SELL);
        Test.stopTest();

        List<Case> cases = queryCases();
        Quote reselectQuote = queryQuote(OPP_NAME);
        ServiceInfo__c reselectServiceInfo = (ServiceInfo__c) new ListOptional(
            new ServiceInfoSelector()
                .selectServiceInfoForNGBSSyncablesById(serviceInfo.Id)
                .executeQuery())
            .getFirst();
        Assert.areEqual(1, cases.size(), 'List cases size must be 1');
        Assert.isTrue(reselectServiceInfo.IsDownsellCaseCreated__c, 'IsDownsellCaseCreated__c field must be true');
        Assert.areEqual(2, reselectQuote.CountOfDownsellQLI__c, 'CountOfDownsellQLI__c field should be 2');
    }

    @isTest
    private static void testDownsellCaseCreationLBOAccountsSimplifiedLBODownsell() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => false,
                Feature_Toggle__c.EnableSimplifiedLBODownsell__c  => true
            })
            .create();

        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        List<Entitlement__c> ents = new List<Entitlement__c>();
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Zero_Quantity__c = false;
            qli.PackageInfo__c = PACKAGE_INFO_QLI_WITH_LBOX;
            qli.Quantity = -2;
            qli.NewQuantity__c = 17;
            ents.add(new Entitlement__c(Id = qli.Entitlement__c, Quantity__c = 16));
        }
        updateWithoutTriggers(qt.QuoteLineItems);
        updateWithoutTriggers(ents);
        Triggers.switchOff();
        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Triggers.switchOn();

        Test.startTest();
        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.DOWN_SELL);
        Test.stopTest();

        Opportunity reselectOpp = queryOpportunity(OPP_NAME);
        Quote reselectQuote = queryQuote(OPP_NAME);
        Assert.isTrue(reselectOpp.IsDownsellCaseCreated__c, 'IsDownsellCaseCreated__c field must be true');
        Assert.areEqual(2, reselectQuote.CountOfDownsellQLI__c, 'CountOfDownsellQLI__c field should be 2');
    }

    @isTest
    private static void testDownsellCaseCreationLBOAccountsMPUB() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true,
                Feature_Toggle__c.EnableSimplifiedLBODownsell__c  => false
            })
            .create();

        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        List<Entitlement__c> ents = new List<Entitlement__c>();
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Zero_Quantity__c = false;
            qli.PackageInfo__c = PACKAGE_INFO_QLI_WITH_LBOX;
            qli.Quantity = -2;
            qli.NewQuantity__c = 17;
            ents.add(new Entitlement__c(Id = qli.Entitlement__c, Quantity__c = 16));
        }
        updateWithoutTriggers(qt.QuoteLineItems);
        updateWithoutTriggers(ents);
        Opportunity opp = queryOpportunity(OPP_NAME);

        Triggers.switchOff();
        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => acc.Id,
                Package__c.Account_Package_Id__c => acc.Billing_ID__c
            })
            .create()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => qt.Id,
                ServiceInfo__c.BillingPackage__c => pack.Id
            })
            .create()
            .getRecord();

        Test.setMock(HttpCalloutMock.class, new Mock());

        Triggers.switchOn();

        Test.startTest();
        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.DOWN_SELL);
        Test.stopTest();

        Quote reselectQuote = queryQuote(OPP_NAME);
        ServiceInfo__c reselectServiceInfo = (ServiceInfo__c) new ListOptional(
            new ServiceInfoSelector()
                .selectServiceInfoForNGBSSyncablesById(serviceInfo.Id)
                .executeQuery())
            .getFirst();
        Assert.isTrue(reselectServiceInfo.IsDownsellCaseCreated__c, 'IsDownsellCaseCreated__c field must be true');
        Assert.areEqual(2, reselectQuote.CountOfDownsellQLI__c, 'CountOfDownsellQLI__c field should be 2');
    }

    @isTest
    private static void testDownsellCaseCreationLBOAccounts() {

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => false,
                Feature_Toggle__c.EnableSimplifiedLBODownsell__c  => false
            })
            .create();

        Account acc = queryAccount();
        acc.EnabledLBO__c = true;
        updateWithoutTriggers(acc);

        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.Enabled_LBO__c = true;
        updateWithoutTriggers(qt);

        List<Entitlement__c> ents = new List<Entitlement__c>();
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Zero_Quantity__c = false;
            qli.PackageInfo__c = PACKAGE_INFO_QLI_WITH_LBOX;
            qli.Quantity = -2;
            qli.NewQuantity__c = 17;
            ents.add(new Entitlement__c(Id = qli.Entitlement__c, Quantity__c = 16));
        }
        updateWithoutTriggers(qt.QuoteLineItems);
        updateWithoutTriggers(ents);
        Triggers.switchOff();
        Opportunity opp = queryOpportunity(OPP_NAME);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Triggers.switchOn();

        Test.startTest();
        Response res = SyncWithNGBS.syncWithNGBS_v3(qt.Id, SWNStep.DOWN_SELL);
        Test.stopTest();

        Opportunity reselectOpp = queryOpportunity(OPP_NAME);
        Quote reselectQuote = queryQuote(OPP_NAME);
        Assert.isTrue(reselectOpp.IsDownsellCaseCreated__c, 'IsDownsellCaseCreated__c field must be true');
        Assert.areEqual(2, reselectQuote.CountOfDownsellQLI__c, 'CountOfDownsellQLI__c field should be 2');
    }

    @isTest
    static void testLicenseIdsToSkipForCheckQuantity() {
        List<NGBSHiddenLicenses__c> hiddenLicenseList = new List<NGBSHiddenLicenses__c>();
        hiddenLicenseList.add(
            new NGBSHiddenLicenses__c(Name = 'LicenseIdsToSkipForCheckQuantity', SkipQuantityValidationInSync__c = true, LicenseElementId__c = 'ID1;ID2;ID3')
        );
        insert hiddenLicenseList;

        Test.startTest();
            List<String> licenseIdsToSkip = SWNHelper.getLicenseIdsToSkipForCheckQuantity();
        Test.stopTest();

        Assert.areEqual(new List<String>{'ID1', 'ID2', 'ID3'}, licenseIdsToSkip, 'The result should contain all expected license IDs');
    }

    @isTest
    static void testUpdateRCCCSyncStatus() {
        Quote qt = queryQuote(OPP_NAME);
        Assert.areEqual(IcbHelper.CC_SYNC_STATUS_NOT_APPLICABLE, qt.Opportunity.RCCCSyncStatus__c, 'RCCCSyncStatus__c should be null before test execution');

        Test.startTest();
            SyncWithNGBS.updateRCCCSyncStatus(qt.Id);
            qt = queryQuote(OPP_NAME);
            Assert.areEqual(IcbHelper.CC_SYNC_STATUS_NOT_APPLICABLE, qt.Opportunity.RCCCSyncStatus__c, 'RCCCSyncStatus__c should not be updated for a non-RC quote');

            qt.IsMultiProductTechnicalQuote__c = true;
            qt.ServiceName__c = OpportunityHelper.TIER_RC_CONTACT_CENTER;
            updateWithoutTriggers(qt);
            SyncWithNGBS.updateRCCCSyncStatus(qt.Id);
        Test.stopTest();

        qt = queryQuote(OPP_NAME);
        Assert.areEqual(IcbHelper.DEFAULT_SYNC_ERROR, qt.Opportunity.RCCCSyncStatus__c, 'RCCCSyncStatus__c should be updated to the default sync error');
    }

    @isTest
    static void testGetSyncSteps() {
        Test.startTest();
            Response result = SyncWithNGBS.getSyncSteps();
        Test.stopTest();

        Map<String, SWNStep> steps = (Map<String, SWNStep>) result.data.get(SyncWithNGBS.STEPS);

        Assert.isNotNull(steps, 'Steps should not be null');
        Assert.areEqual(23, steps.size(), 'Steps amount should be equal to 23');
    }

    @isTest
    static void testPostValidationActionSuccess() {
        Quote qt = queryQuote(OPP_NAME);

        Test.startTest();
            SyncWithNGBS.postValidationAction(qt.Id);
        Test.stopTest();

        SalesFunnelStatus__c salesFunnelStatus = (SalesFunnelStatus__c) new ListOptional(new SalesFunnelStatusSelector()
            .selectSalesFunnelStatuses()
            .executeQuery()
        ).getFirst();

        Assert.isNotNull(salesFunnelStatus, 'Sales Funnel Status should be created');
    }

    @isTest
    static void testPostValidationActionError() {
        Id quoteId = (Id) ValueProviderBuilder.provideDummyId(Quote.SObjectType).getValue();

        Test.startTest();
            Response result = SyncWithNGBS.postValidationAction(quoteId);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_ERROR, result.status, 'Status should be Error');
    }
}