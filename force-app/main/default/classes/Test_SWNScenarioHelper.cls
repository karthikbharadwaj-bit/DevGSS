@isTest
private class Test_SWNScenarioHelper {
    private static final String OPP_NAME = 'oppName';
    private static final String ACC_NAME = 'accName';
    private static final String QUOTE_NAME = 'Test Quote';
    private static final String QLI_NAME = 'Test Qli';
    private static final String POC_OPP_NAME = 'oppNamePOC';
    private static final String TERMINATION_OPP_NAME = 'oppTermination';
    private static final String FEDRAMP_OPP_NAME = 'oppFedramp';
    private static final String ENTITLEMENT_NAME = 'Entitlement Name';
    private static final String PRODUCT_DIGITALLINE_UNLIMITED = 'DigitalLine Unlimited';
    private static final String PRODUCT_DIGITALLINE = 'DigitalLine';
    private static final String BILLING_ID = (String) ValueProviderBuilder.provideUniqueString().getValue();
    private static final String PACKAGE_ID = '1389379001';
    private static final String PACKAGE_CATALOG_ID = '18';
    private static final String PACKAGE_CHANGED_CATALOG_ID = '15';
    private static final String PACKAGE_VERSION = '1';
    private static final String PARTNER_PACKAGE_ID = '3';
    private static final String PARTNER_PACKAGE_VERSION = '4';
    private static final String PACKAGE_DURATION = Product2Helper.CHARGE_TERM_MONTHLY;
    private static final String CHANGED_BILLING_ID = '1239';
    private static final String LBOX_ELEMENT_ID = 'LB_702';
    private static final String BATCH_QTY = '15';
    private static String LABEL_VALUE = BillingWrappers.EXPIRATION_TYPE_EXPIRED;
    private static final String PKG_DESCRIPTION = '{"contractExtId":"nib","salesAgreement":"Test"}';
    private static final String PKG_DESCRIPTION_CHANGED_CONTRACT = '{"contractExtId":"nid","salesAgreement":"Test"}';
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

    private static final String NGBS_BILLING_INFO_RESPONSE = '[{"amount":0.08,"catalogId":"LC_DL_75","discountAmount":0,"qty":3,"billingType":"Recurring",' +
        '"billingCycleDuration":"Monthly","dateRangeStart":"2020-08-09","dateRangeEnd":"2020-09-08",' +
        '"description":"Disconnect Scrub, per 10 scrubs","descriptionKey":"E528A917D99E9C0E7976FE2F7301474B"},' +
        '{"amount":0.03,"catalogId":"LC_DL-UNL_50","discountAmount":0,"qty":3,"billingType":"Recurring",' +
        '"billingCycleDuration":"Monthly","dateRangeStart":"2020-08-09","dateRangeEnd":"2020-09-08",' +
        '"description":"Automated speech recognition, per minute","descriptionKey":"0C87BF8CA6D34E48BBA4228C91DCD275"},' +
        '{"amount":0.03,"catalogId":"LC_DID_53","discountAmount":0,"qty":3,"billingType":"Recurring",' +
        '"billingCycleDuration":"Monthly","dateRangeStart":"2020-08-09","dateRangeEnd":"2020-09-08",' +
        '"description":"Automated speech recognition, per minute","descriptionKey":"0C87BF8CA6D34E48BBA4228C91DCD275"}]';

    private static final String NGBS_POC_ACCOUNT_RESPONSE = '{"id":5218705001,"packages":[{"id":' + PACKAGE_ID + ',"catalogId":"18","version":"1","status":"Active",' +
        '"offerType":"ProofOfConcept","description":"RingCentral Office Standard","currency":"USD","masterDuration":"Monthly",' +
        '"licenses":[{"id":47787810001,"catalogId":"LC_DL_75","categoryId":"DL","externalId":"rc:phonelineid:1791051012",' +
        '"description":"DigitalLine","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","subLicenses":[{' +
        '"id":47787812001,"catalogId":"LC_DL-UNL_50","categoryId":"DL-UNL","externalId":"rc:digitallineid:1791051012",' +
        '"description":"DigitalLine Unlimited","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly",' +
        '"subLicenses":[{"id":47787815001,"catalogId":"LC_DID_53","categoryId":"DID","externalId":"rc:fphoneid:4056372012",' +
        '"description":"DID","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"DBEAB5095E8B54BE8527724B23C371A3"}],' +
        '"descriptionKey":"C42D89795912155D0609ADF07491A640"},{"id":47787813001,"catalogId":"LC_CRF_51","categoryId":"CRF",' +
        '"externalId":"rc:CRF:1791051012","description":"Compliance and Administrative Cost Recovery Fee","qty":1,' +
        '"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"C8EFB0CE91E66A64002E644CA3D67014"},' +
        '{"id":47787814001,"catalogId":"LC_E911_52","categoryId":"E911","externalId":"rc:E911:1791051012",' +
        '"description":"e911 Service Fee","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly",' +
        '"descriptionKey":"71EA7BE324BCD4A18F78A9EEA6DB7D5C"}],"descriptionKey":"F33BCA901CB8B47F14DE4C52F2413875"},' +
        '{"id":47787943001,"catalogId":"LC_DL_75","categoryId":"DL","externalId":"rc:phonelineid:1791058012",' +
        '"description":"DigitalLine","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","subLicenses":[{' +
        '"id":47787945001,"catalogId":"LC_DL-UNL_50","categoryId":"DL-UNL","externalId":"rc:digitallineid:1791058012",' +
        '"description":"DigitalLine Unlimited","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly",' +
        '"subLicenses":[{"id":47787948001,"catalogId":"LC_DID_53","categoryId":"DID","externalId":"rc:fphoneid:4056379012",' +
        '"description":"DID","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"DBEAB5095E8B54BE8527724B23C371A3"}],' +
        '"descriptionKey":"C42D89795912155D0609ADF07491A640"},{"id":47787946001,"catalogId":"LC_CRF_51","categoryId":"CRF",' +
        '"externalId":"rc:CRF:1791058012","description":"Compliance and Administrative Cost Recovery Fee","qty":1,' +
        '"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"C8EFB0CE91E66A64002E644CA3D67014"},' +
        '{"id":47787947001,"catalogId":"LC_E911_52","categoryId":"E911","externalId":"rc:E911:1791058012",' +
        '"description":"e911 Service Fee","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly",' +
        '"descriptionKey":"71EA7BE324BCD4A18F78A9EEA6DB7D5C"}],"descriptionKey":"F33BCA901CB8B47F14DE4C52F2413875"},' +
        '{"id":47787998001,"catalogId":"LC_DL_75","categoryId":"DL","externalId":"rc:phonelineid:1791060012",' +
        '"description":"DigitalLine","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","subLicenses":[{' +
        '"id":47788000001,"catalogId":"LC_DL-UNL_50","categoryId":"DL-UNL","externalId":"rc:digitallineid:1791060012",' +
        '"description":"DigitalLine Unlimited","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly",' +
        '"subLicenses":[{"id":47788003001,"catalogId":"LC_DID_53","categoryId":"DID","externalId":"rc:fphoneid:4056381012",' +
        '"description":"DID","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"DBEAB5095E8B54BE8527724B23C371A3"}],' +
        '"descriptionKey":"C42D89795912155D0609ADF07491A640"},{"id":47788001001,"catalogId":"LC_CRF_51","categoryId":"CRF",' +
        '"externalId":"rc:CRF:1791060012","description":"Compliance and Administrative Cost Recovery Fee","qty":1,' +
        '"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"C8EFB0CE91E66A64002E644CA3D67014"},' +
        '{"id":47788002001,"catalogId":"LC_E911_52","categoryId":"E911","externalId":"rc:E911:1791060012",' +
        '"description":"e911 Service Fee","qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly",' +
        '"descriptionKey":"71EA7BE324BCD4A18F78A9EEA6DB7D5C"}],"descriptionKey":"F33BCA901CB8B47F14DE4C52F2413875"}]}]}';
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
    private static final String SCENARIO_KEY = 'TEST_SCENARIO_NAME';

    private static String getNGBSPackageWithLabelsResponse() {
        return '{"id":"18","version":"1","packageInfo":{"id":' + PACKAGE_ID + ',"catalogId":"' + PACKAGE_CATALOG_ID + '",' +
            '"version": "' + PACKAGE_VERSION + '"}, "labels": {"upgradeWizardExpiration": ["' + LABEL_VALUE + '"]}}';
        }

    private static final String BASE_ENDPOINT = 'http://test.com';
    private static final String MANAGER_PATH = 'http://test.com/test_manager';

    @testSetup
    private static void test_generateData() {
        NGBS_Settings__c settings = (NGBS_Settings__c) new SObjectBuilder(NGBS_Settings__c.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            NGBS_Settings__c.BaseEndpoint__c => BASE_ENDPOINT,
            NGBS_Settings__c.AccountManagerPath__c => MANAGER_PATH,
            NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
            NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
        })
        .create()
        .getRecord();
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

    private static void setAllowRepricePermission(Id userId) {
        PermissionSet ps1 = new PermissionSet(
            Name = CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE,
            Label = CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE
        );
        insert ps1;

        SetupEntityAccess testEntityAccess = new SetupEntityAccess(
            ParentId = ps1.Id,
            SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE].Id);
        insert testEntityAccess;

        PermissionSetAssignment psa1 = new PermissionSetAssignment(
            AssigneeId = userId,
            PermissionSetId = ps1.Id
        );
        insert psa1;
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

    private static User createSalesUser() {
        Profile salesProfile = (Profile) new ProfileSelector()
            .selectProfileByName(ProfileHelper.PROFILE_NAME_SALES_REP_LIGHTNING)
            .executeQuery()
            .get(0);

        return (User) new SObjectBuilder(User.SObjectType)
            .setField(User.ProfileId, salesProfile.Id)
            .create()
            .getRecord();
    }

    private static BillingWrappers.BillingContract buildActiveBillingContract() {
        BillingWrappers.BillingContract cnt = new BillingWrappers.BillingContract();
        cnt.id = '2';
        cnt.startBillingCycleNumber = 1;
        cnt.term = 24;
        cnt.renewalTerm = 24;
        cnt.startDate = System.today();
        cnt.description = PKG_DESCRIPTION;
        return cnt;
    }

    private static List<BillingWrappers.BillingContract> buildActiveBillingContracts() {
        return new List<BillingWrappers.BillingContract> {buildActiveBillingContract()};
    }

    private static BillingHttpRequestMock buildContractMock(List<BillingWrappers.BillingContract> contractsToReturn) {
        BillingHttpRequestMock.MockInfo mockInfo = new BillingHttpRequestMock.MockInfo(
            JSON.serialize(contractsToReturn)
        );
        BillingHttpRequestMock mock = new BillingHttpRequestMock();
        mock.endpointToBodyMap.put('/contract', mockInfo);
        return mock;
    }

    private static Quote buildQuoteWithRequiredData() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ACC_NAME,
                Account.Id => ValueProviderBuilder.provideDummyId(Account.sObjectType),
                Account.Billing_Id__c => BILLING_ID
            })
            .build()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => acc.Id,
                Package__c.Account_Package_Id__c => '1231231231',
                Package__c.Id => ValueProviderBuilder.provideDummyId(Package__c.SObjectType)
            })
            .build()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME,
                Opportunity.Id => ValueProviderBuilder.provideDummyId(Opportunity.sObjectType),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .build()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => QUOTE_NAME,
                Quote.Package_Info__c => PACKAGE_INFO,
                Quote.BillingPackage__c => pkg.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Display_Name__c, QLI_NAME)
            .setField(QuoteLineItem.newQuantity__c, 10)
            .build()
            .getRecord();

        QuoteLineItem qli2 = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Display_Name__c, QLI_NAME)
            .setField(QuoteLineItem.newQuantity__c, 10)
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.PackageOfferType__c => QuoteHelper.OFFER_TYPE_REGULAR,
                Entitlement__c.PackageDuration__c => PACKAGE_DURATION,
                Entitlement__c.PackageCatalogId__c => PACKAGE_CATALOG_ID,
                Entitlement__c.PackageVersion__c => PACKAGE_VERSION,
                Entitlement__c.ChargeTerm__c => PACKAGE_DURATION,
                Entitlement__c.Quantity__c => 10
            })
            .build()
            .getRecord();

        Entitlement__c ent2 = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.PackageOfferType__c => QuoteHelper.OFFER_TYPE_REGULAR,
                Entitlement__c.PackageDuration__c => PACKAGE_DURATION,
                Entitlement__c.PackageCatalogId__c => PACKAGE_CATALOG_ID,
                Entitlement__c.PackageVersion__c => PACKAGE_VERSION,
                Entitlement__c.ChargeTerm__c => PACKAGE_DURATION,
                Entitlement__c.Quantity__c => 10
            })
            .build()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'PRODUCT_NAME',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SMS
            })
            .build()
            .getRecord();

        Product2 prod2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'PRODUCT_NAME',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SMS
            })
            .build()
            .getRecord();

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Product2',
            prod
        );

        qli2 = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli2,
            QuoteLineItem.class,
            'Product2',
            prod2
        );

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Entitlement__r',
            ent
        );

        qli2 = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli2,
            QuoteLineItem.class,
            'Entitlement__r',
            ent2
        );

        testQuote = (Quote) Test_Utils.putIntoUnwritableField(
            testQuote,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli, qli2 }
        );
        return (Quote) Test_Utils.putIntoUnwritableFields(
            testQuote,
            Quote.class,
            new Map<String, Object> {
                'Account' => acc,
                'AccountId' => acc.Id,
                'Opportunity' => opp,
                'OpportunityId' => opp.Id
            }
        );
    }

    @isTest
    static void testGetKeyForSalesCancellationFlow() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => '[{"id":"18","version":"1","packageInfo":{"id":9710001}}]',
                Quote.Enabled_LBO__c => true
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Display_Name__c, 'QUOTELINEITEM_NAME')
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.PackageOfferType__c => QuoteHelper.OFFER_TYPE_REGULAR,
                Entitlement__c.PackageDuration__c => '12',
                Entitlement__c.PackageCatalogId__c => '123',
                Entitlement__c.PackageVersion__c => '2'
            })
            .build()
            .getRecord();

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Entitlement__r',
            ent
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );

        Test.startTest();
            SWNScenarioHelper.SalesQuoteCancellationFlow flow = new SWNScenarioHelper.SalesQuoteCancellationFlow(qt);
            flow.s.isFree = false;
            flow.s.isTrial = false;
            flow.s.isUpsell = true;
            flow.s.isDownsell = true;
            String key = flow.getKey();
        Test.stopTest();

        Assert.areEqual('LBO_NON_CONTRACTED_S16', key, 'Current scenario name should be equal to LBO_NON_CONTRACTED_S16');
    }

    @isTest
    static void testGetKeyForNonLBOSalesCancellationFlow() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => '[{"id":"18","version":"1","packageInfo":{"id":9710001}}]'
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Display_Name__c, 'QUOTELINEITEM_NAME')
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.PackageOfferType__c => QuoteHelper.OFFER_TYPE_REGULAR,
                Entitlement__c.PackageDuration__c => '12',
                Entitlement__c.PackageCatalogId__c => '123',
                Entitlement__c.PackageVersion__c => '2'
            })
            .build()
            .getRecord();

        qli.putSObject(QuoteLineItem.Entitlement__c, ent);

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );

        Test.startTest();
            SWNScenarioHelper.SalesQuoteCancellationFlow flow = new SWNScenarioHelper.SalesQuoteCancellationFlow(qt);
            flow.s.isFree = false;
            flow.s.isTrial = false;
            flow.s.isUpsell = true;
            flow.s.isDownsell = true;
            String key = flow.getKey();
        Test.stopTest();

        Assert.areEqual('NON_CONTRACTED_S16', key, 'Current scenario name should be equal to NON_CONTRACTED_S16');
    }

    @isTest
    static void testGetKeyForPaidUpgradeSalesQuoteFlow() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => '[{"id":"18","version":"1","packageInfo":{"id":9710001}}]',
                Quote.Enabled_LBO__c => true
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Display_Name__c, 'QUOTELINEITEM_NAME')
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.PackageOfferType__c => QuoteHelper.OFFER_TYPE_REGULAR,
                Entitlement__c.PackageDuration__c => '12',
                Entitlement__c.PackageCatalogId__c => '123',
                Entitlement__c.PackageVersion__c => '2'
            })
            .build()
            .getRecord();

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Entitlement__r',
            ent
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );

        Test.startTest();
            SWNScenarioHelper.SalesQuoteFlow flow = new SWNScenarioHelper.SalesQuoteFlow(qt);
            flow.s.isFree = false;
            flow.s.isTrial = false;
            String key = flow.getKey();
        Test.stopTest();

        Assert.areEqual('LBO_NON_CONTRACTED_PAID_UPGRADE', key, 'Current scenario name should be equal to LBO_NON_CONTRACTED_PAID_UPGRADE');
    }

    @isTest
    static void testGetKeyForPaidNonUpgradeSalesQuoteFlow() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => '[{"id":"18","version":"1","duration":"12","packageInfo":{"id":9710001,"catalogId":"18","version":"1"}}]',
                Quote.Enabled_LBO__c => true,
                Quote.isPrimary__c => true
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Display_Name__c, 'QUOTELINEITEM_NAME')
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.PackageOfferType__c => QuoteHelper.OFFER_TYPE_REGULAR,
                Entitlement__c.PackageDuration__c => '12',
                Entitlement__c.PackageCatalogId__c => '18',
                Entitlement__c.PackageVersion__c => '1'
            })
            .build()
            .getRecord();

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Entitlement__r',
            ent
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );

        Test.startTest();
            SWNScenarioHelper.SalesQuoteFlow flow = new SWNScenarioHelper.SalesQuoteFlow(qt);
            flow.s.isFree = false;
            flow.s.isTrial = false;
            String key = flow.getKey();
        Test.stopTest();

        Assert.areEqual('LBO_NON_CONTRACTED_PAID', key, 'Current scenario name should be equal to LBO_NON_CONTRACTED_PAID');
    }

    @isTest
    static void testGetKeyForNonPaidUpgradeSalesQuoteFlow() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => '[{"id":"18","version":"1","packageInfo":{"id":9710001,"catalogId":"18","version":"1"}}]',
                Quote.Enabled_LBO__c => true
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Display_Name__c, 'QUOTELINEITEM_NAME')
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.PackageOfferType__c => QuoteHelper.PACKAGE_OFFER_TYPE_TRIAL,
                Entitlement__c.PackageDuration__c => '12',
                Entitlement__c.PackageCatalogId__c => '123',
                Entitlement__c.PackageVersion__c => '2'
            })
            .build()
            .getRecord();

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Entitlement__r',
            ent
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );

        Test.startTest();
            SWNScenarioHelper.SalesQuoteFlow flow = new SWNScenarioHelper.SalesQuoteFlow(qt);
            flow.s.isFree = false;
            String key = flow.getKey();
        Test.stopTest();

        Assert.areEqual('LBO_NON_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE', key, 'Current scenario name should be equal to LBO_NON_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE');
    }

    @isTest
    static void testGetKeyForPOCQuoteFlow() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => '[{"id":"18","version":"1","duration":"12","packageInfo":{"id":9710001,"catalogId":"18","version":"1"}}]'
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Display_Name__c => 'QUOTELINEITEM_NAME',
                QuoteLineItem.NewQuantity__c => 10,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.IsHiddenLicense__c => false,
                QuoteLineItem.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY

            })
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.PackageOfferType__c => QuoteHelper.PACKAGE_OFFER_TYPE_POC,
                Entitlement__c.PackageDuration__c => '12',
                Entitlement__c.PackageCatalogId__c => '18',
                Entitlement__c.PackageVersion__c => '1',
                Entitlement__c.Quantity__c => 1
            })
            .build()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'PRODUCT_NAME',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SMS
            })
            .build()
            .getRecord();

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Entitlement__r',
            ent
        );

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Product2',
            prod
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );

        Test.startTest();
            SWNScenarioHelper.POCQuoteFlow flow = new SWNScenarioHelper.POCQuoteFlow(qt);
            String key = flow.getKey();
        Test.stopTest();

        Assert.areEqual('NON_CONTRACTED_S8', key, 'Current scenario name should be equal to NON_CONTRACTED_S8');
        Assert.areEqual(prod.Name, flow.getAffectedLicenses().get(SWNStep.UP_SELL)[0], 'Affected license should be equal to PRODUCT_NAME');
    }

    @isTest
    static void testGetKeyForUpgradeEngageQuoteFlow() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => '[{"id":"18","version":"1","duration":"12","packageInfo":{"id":9710001,"catalogId":"18","version":"1"}}]'
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Display_Name__c => 'QUOTELINEITEM_NAME'
            })
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.PackageOfferType__c => QuoteHelper.OFFER_TYPE_REGULAR,
                Entitlement__c.PackageDuration__c => '12',
                Entitlement__c.PackageCatalogId__c => '18',
                Entitlement__c.PackageVersion__c => '2'
            })
            .build()
            .getRecord();

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Entitlement__r',
            ent
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );

        Test.startTest();
            SWNScenarioHelper.EngageQuoteFlow flow = new SWNScenarioHelper.EngageQuoteFlow(qt);
            String key = flow.getKey();
        Test.stopTest();

        Assert.areEqual('NON_CONTRACTED_PAID_UPGRADE_CCB', key, 'Current scenario name should be equal to NON_CONTRACTED_PAID_UPGRADE_CCB');
    }

    @isTest
    static void testGetKeyForNonUpgradeEngageQuoteFlow() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => '[{"id":"18","version":"1","duration":"12","packageInfo":{"id":9710001,"catalogId":"18","version":"1"}}]'
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Display_Name__c => 'QUOTELINEITEM_NAME',
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.IsHiddenLicense__c => false,
                QuoteLineItem.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY

            })
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.PackageOfferType__c => QuoteHelper.OFFER_TYPE_REGULAR,
                Entitlement__c.PackageDuration__c => '12',
                Entitlement__c.PackageCatalogId__c => '18',
                Entitlement__c.PackageVersion__c => '1',
                Entitlement__c.Quantity__c => 10
            })
            .build()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'PRODUCT_NAME',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SMS
            })
            .build()
            .getRecord();

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Entitlement__r',
            ent
        );

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Product2',
            prod
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );

        Test.startTest();
            SWNScenarioHelper.EngageQuoteFlow flow = new SWNScenarioHelper.EngageQuoteFlow(qt);
            String key = flow.getKey();
        Test.stopTest();

        Assert.areEqual('NON_CONTRACTED_PAID_SYNC_CCB_DOWNSELL', key, 'Current scenario name should be equal to NON_CONTRACTED_PAID_SYNC_CCB_DOWNSELL');
        Assert.areEqual(prod.Name, flow.getAffectedLicenses().get(SWNStep.DOWN_SELL)[0], 'Affected license should be equal to PRODUCT_NAME');
    }

    @isTest
    private static void testSyncScenarioContractedPaidUpgrade() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_PAID_UPGRADE'),
            sc,
            'getSyncScenario should return "CONTRACTED_PAID_UPGRADE" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedPaid() {
        Quote qt = buildQuoteWithRequiredData();
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_PAID'),
            sc,
            'getSyncScenario should return "CONTRACTED_PAID" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedPaidUpsell() {
        Quote qt = buildQuoteWithRequiredData();
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c += 5;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_PAID_UPSELL'),
            sc,
            'getSyncScenario should return "CONTRACTED_PAID_UPSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedPaidDownsell() {
        Quote qt = buildQuoteWithRequiredData();
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 1;
        }
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_PAID_DOWNSELL'),
            sc,
            'getSyncScenario should return "CONTRACTED_PAID_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedPaidUpsellDownsell() {
        Quote qt = buildQuoteWithRequiredData();
        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_PAID_UPSELL_DOWNSELL'),
            sc,
            'getSyncScenario should return "CONTRACTED_PAID_UPSELL_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedUpgradeUpsell() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c += 5;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_PAID_UPGRADE_UPSELL'),
            sc,
            'getSyncScenario should return "CONTRACTED_PAID_UPGRADE_UPSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedUpgradeDownsell() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 1;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_PAID_UPGRADE_DOWNSELL'),
            sc,
            'getSyncScenario should return "CONTRACTED_PAID_UPGRADE_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedUpgradeUpsellDownsell() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);

        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL'),
            sc,
            'getSyncScenario should return "CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedNonPaidUpgradeUpsellTargetChange() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        qt.QuoteLineItems.get(0).Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_TRIAL;

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c += 5;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE'),
            sc,
            'getSyncScenario should return "CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedNonPaidUpgradeDownsellTargetChange() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        qt.QuoteLineItems.get(0).Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_TRIAL;

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 1;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE'),
            sc,
            'getSyncScenario should return "CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedNonPaidUpgradeUpsellDownsellTargetChange() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_TRIAL;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE'),
            sc,
            'getSyncScenario should return "CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedNonPaidUpgradeTargetChange() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        qt.QuoteLineItems.get(0).Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_TRIAL;

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = qli.Entitlement__r.Quantity__c;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE'),
            sc,
            'getSyncScenario should return "CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedPaidUpgrade() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_PAID_UPGRADE'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_PAID_UPGRADE" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedPaid() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_PAID'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_PAID" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedPaidUpsell() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c += 5;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_PAID_UPSELL'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_PAID_UPSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedNonPaidUpgradeUpsellDownsell() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT.replace(PACKAGE_CATALOG_ID, '21');
        qt.QuoteLineItems.get(0).Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_POC;
        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedNonPaidUpgradeUpsellDownsellLBO() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT.replace(PACKAGE_CATALOG_ID, '21');
        qt.Enabled_LBO__c = true;
        qt.QuoteLineItems.get(0).Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_POC;
        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL'),
            sc,
            'getSyncScenario should return "LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedNonPaidUpgradeUpsellDownsell() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, '21');
        qt.QuoteLineItems.get(0).Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_POC;
        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL'),
            sc,
            'getSyncScenario should return "CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedNonPaidUpgradeUpsellDownsellLBO() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, '21');
        qt.Enabled_LBO__c = true;
        qt.QuoteLineItems.get(0).Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_POC;
        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL'),
            sc,
            'getSyncScenario should return "LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedPaidUpsellDownsell() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_Contract_Cancellation__c, true)
            .create();

        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_S15'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_S15" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedPaidUpsellDownsellForLBOAccounts() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_Contract_Cancellation__c, true)
            .create();

        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.Enabled_LBO__c = true;
        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('LBO_NON_CONTRACTED_S15'),
            sc,
            'getSyncScenario should return "LBO_NON_CONTRACTED_S15" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedUpgradeUpsellForLBOAccounts() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        qt.Enabled_LBO__c = true;

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c += 5;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('LBO_CONTRACTED_PAID_UPGRADE_UPSELL'),
            sc,
            'getSyncScenario should return "LBO_CONTRACTED_PAID_UPGRADE_UPSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedUpgradeDownsellForLBOAccounts() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Enabled_LBO__c = true;
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 1;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('LBO_CONTRACTED_PAID_UPGRADE_DOWNSELL'),
            sc,
            'getSyncScenario should return "LBO_CONTRACTED_PAID_UPGRADE_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioContractedUpgradeUpsellDownsellForLBOAccounts() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Enabled_LBO__c = true;
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('LBO_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL'),
            sc,
            'getSyncScenario should return "LBO_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedS1forLBOAccounts() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.Enabled_LBO__c = true;
        qt.IsSendOrderToNGBS__c = true;

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c += 5;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNStep.ORDER,
            sc.stepNames[1],
            'For LBO quote "LBO_NON_CONTRACTED_PAID_UPSELL" scenario must have ORDER step'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedPaidDownsell() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 1;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_PAID_DOWNSELL'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_PAID_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedPaidUpgradeUpsell() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c += 5;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_PAID_UPGRADE_UPSELL'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_PAID_UPGRADE_UPSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedPaidUpgradeDownsell() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 1;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_PAID_UPGRADE_DOWNSELL'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_PAID_UPGRADE_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedPaidUpgradeUpsellDownsell() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedNonPaidUpgradeUpsellTargetChange() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        qt.QuoteLineItems.get(0).Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_TRIAL;

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c += 5;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedNonPaidUpgradeDownsellTargetChange() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        qt.QuoteLineItems.get(0).Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_TRIAL;

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.NewQuantity__c = 1;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE" scenario'
        );
    }

    @isTest
    private static void testSyncScenarioNonContractedNonPaidUpgradeTargetChange() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT.replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_TRIAL;
            qli.NewQuantity__c = qli.Entitlement__r.Quantity__c;
        }

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Assert.areEqual(
            SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE'),
            sc,
            'getSyncScenario should return "NON_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE" scenario'
        );
    }

    @isTest
    private static void testGetSyncScenarioWithAffectedLicenses() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO_WITHOUT_CONTRACT;
        qt.QuoteLineItems.get(0).NewQuantity__c = 1;
        qt.QuoteLineItems.get(1).NewQuantity__c += 5;

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
        Test.stopTest();

        Assert.isTrue(res.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(res.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get(SWNScenarioHelper.SCENARIO);

        Map<String, SWNStep> stepNameToStepMap = new Map<String, SWNStep>();
        for (SWNStep st : sc.steps) {
            stepNameToStepMap.put(st.name, st);
        }
        SWNStep upsellStep = stepNameToStepMap.get(SWNStep.UP_SELL);
        SWNStep downsellStep = stepNameToStepMap.get(SWNStep.DOWN_SELL);

        Assert.isTrue(!upsellStep.affectedLicenses.isEmpty(), 'upsellStep should contains affectedLicenses names');
        Assert.isTrue(
            upsellStep.affectedLicenses.contains(qt.QuoteLineItems.get(1).Product2.Name),
            'affectedLicenses for upsell step should contain the names of licenses for which increased quantity'
        );
    }

    @isTest
    private static void testGetSyncScenarioWithSpendingLimitRetrieveStep() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        String packageQLIInfoHD139 = '{"Version":"1","q":null,"Price":null,"parent":null,"lbox":null,"Id":"18","duration":"One - Time","Discount":{"Value":0,"Type":"Money"},"categoryPath":"HD","CategoryCode":"HD"}';
        Quote qt = buildQuoteWithRequiredData();
        qt.Enabled_LBO__c = true;
        qt.Upsell_Status__c = QuoteHelper.STATUS_NEW_CUSTOMER;
        qt.IsSendOrderToNGBS__c = true;

        Product2 productDevice = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Polycom VVX501 with 1 Expansion Module',
                Product2.ExtId__c => 'LC_HD_139',
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME
            })
            .build()
            .getRecord();

        QuoteLineItem qliDevice = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Quantity => 500,
                QuoteLineItem.NewQuantity__c => 500,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.PackageInfo__c => packageQLIInfoHD139
            })
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.PackageOfferType__c => QuoteHelper.OFFER_TYPE_REGULAR,
                Entitlement__c.PackageDuration__c => PACKAGE_DURATION,
                Entitlement__c.PackageCatalogId__c => PACKAGE_CATALOG_ID,
                Entitlement__c.PackageVersion__c => PACKAGE_VERSION,
                Entitlement__c.Quantity__c => 10
            })
            .build()
            .getRecord();

        Approval__c creditLimitApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Credit Limit Increase',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE,
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.DateOfSignOff__c => System.today()
                })
            .build()
            .getRecord();

        qliDevice = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qliDevice,
            QuoteLineItem.class,
            'Entitlement__r',
            ent
        );

        qliDevice = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qliDevice,
            QuoteLineItem.class,
            'Product2',
            productDevice
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qliDevice }
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'Approvals__r',
            new List<Approval__c> { creditLimitApproval }
        );

        Test.startTest();
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            Response res = SWNScenarioHelper.getSyncScenario(sdc);
            SWNScenarioHelper.Scenario scenario = (SWNScenarioHelper.Scenario) res.data.get('scenario');
        Test.stopTest();

        Assert.areEqual(true, res.isSuccess(), 'Response must be with success status');
        Assert.areEqual(true, scenario.stepNames.contains(SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE), 'Step names list must be with "SYNC_SPENDING_LIMIT_RETRIEVE" step');
        Assert.areEqual(true, scenario.steps.contains(SWNStep.STEPS.get(SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE)), 'Steps list must have step "SYNC_SPENDING_LIMIT_RETRIEVE" step');
    }

    @isTest
    static void testGetSyncScenarioWithoutRepriceStep() {
        List<String> expectedSteps = new List<String> {
            SWNStep.CONTRACT_SYNC,
            SWNStep.DISCOUNT_SYNC
        };

        User testUser = createSalesUser();
        setAllowRepricePermission(testUser.Id);
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = buildQuoteWithRequiredData();

        Response result;
        Test.setMock(HttpCalloutMock.class, buildContractMock(buildActiveBillingContracts()));
        Test.startTest();
            System.runAs(testUser) {
                result = SWNScenarioHelper.getSyncScenario(sdc);
            }
        Test.stopTest();

        Assert.isNotNull(result, 'A Scenario must be returned');
        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) result.data.get(SWNScenarioHelper.SCENARIO);
        Assert.areEqual(expectedSteps, sc.stepNames, 'Scenario has unexpected Steps, Reprice step must be filtered out.');
    }

    @isTest
    static void testGetSyncScenarioWithRepriceStepPriceIsChanged() {
        final Decimal ORIGINAL_UNIT_PRICE = 100;
        final Decimal ORIGINAL_EFFECTIVE_PRICE = 100;
        final Decimal NEW_UNIT_PRICE = ORIGINAL_UNIT_PRICE + 1;
        final Decimal NEW_EFFECTIVE_PRICE = ORIGINAL_EFFECTIVE_PRICE + 1;

        Product2 product = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Family => Product2Helper.FAMILY_TIER,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Id => ValueProviderBuilder.provideDummyId(Entitlement__c.sObjectType),
                Entitlement__c.Price__c => ORIGINAL_UNIT_PRICE,
                Entitlement__c.PackageOfferType__c => QuoteHelper.OFFER_TYPE_REGULAR,
                Entitlement__c.PackageDuration__c => PACKAGE_DURATION,
                Entitlement__c.PackageCatalogId__c => PACKAGE_CATALOG_ID,
                Entitlement__c.PackageVersion__c => PACKAGE_VERSION
            })
            .build()
            .getRecord();
        ent = (Entitlement__c) Test_Utils.putIntoUnwritableField(
            ent,
            Entitlement__c.class,
            'EffectivePrice__c',
            ORIGINAL_EFFECTIVE_PRICE
        );
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.Entitlement__c => ent.Id,
                QuoteLineItem.UnitPrice => NEW_UNIT_PRICE
            })
            .build()
            .getRecord();
        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableFields(
            qli,
            QuoteLineItem.class,
            new Map<String, Object> {
                'EffectivePrice__c' => NEW_EFFECTIVE_PRICE,
                'Product2' => product,
                'Entitlement__r' => ent
            }
        );
        Quote testQuote = buildQuoteWithRequiredData();
        testQuote = (Quote) Test_Utils.putIntoUnwritableField(
            testQuote,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = testQuote;

        List<String> expectedSteps = new List<String> {
            SWNStep.CONTRACT_SYNC,
            SWNStep.DISCOUNT_SYNC,
            SWNStep.REPRICE_SYNC
        };

        User testUser = createSalesUser();
        setAllowRepricePermission(testUser.Id);

        Response result;
        Test.setMock(HttpCalloutMock.class, buildContractMock(buildActiveBillingContracts()));
        Test.startTest();
            System.runAs(testUser) {
                result = SWNScenarioHelper.getSyncScenario(sdc);
            }
        Test.stopTest();

        Assert.isNotNull(result, 'A Scenario must be returned');
        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) result.data.get(SWNScenarioHelper.SCENARIO);
        Assert.areEqual(expectedSteps, sc.stepNames, 'Reprice step must be present in the Scenario');
    }

    @isTest
    private static void verifyStateIsUpgradeWhenVersionIsChanged() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_VERSION, '2');

        Test.startTest();
            SWNScenarioHelper.SalesQuoteState st = new SWNScenarioHelper.SalesQuoteState(qt);
            Boolean result = st.isUpgrade;
        Test.stopTest();

        Assert.isTrue(result, 'version change is upgrade');
    }

    @isTest
    private static void verifyStateIsUpgradeWhenChargeTermIsChanged() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace(PACKAGE_DURATION, Product2Helper.CHARGE_TERM_ANNUAL);

        Test.startTest();
            SWNScenarioHelper.SalesQuoteState st = new SWNScenarioHelper.SalesQuoteState(qt);
            Boolean result = st.isUpgrade;
        Test.stopTest();

        Assert.isTrue(result, 'charge term change is upgrade');
    }

    @isTest
    private static void verifyStateIsNotUpgrade() {
        Quote qt = buildQuoteWithRequiredData();

        Test.startTest();
            SWNScenarioHelper.SalesQuoteState st = new SWNScenarioHelper.SalesQuoteState(qt);
            Boolean result = st.isUpgrade;
        Test.stopTest();

        Assert.isTrue(!result, 'only catalog, version, charge term change is upgrade');
    }

    @isTest
    private static void verifyStateIsUpgradeWhenCatalogIsChanged() {
        Quote qt = buildQuoteWithRequiredData();
        qt.QuotelineItems.get(0).Entitlement__r.PackageCatalogId__c = PACKAGE_CHANGED_CATALOG_ID;
        qt.QuotelineItems.get(0).Entitlement__r.ChargeTerm__c = Product2Helper.CHARGE_TERM_ANNUAL;

        Test.startTest();
            SWNScenarioHelper.SalesQuoteState st = new SWNScenarioHelper.SalesQuoteState(qt);
            Boolean result = st.isUpgrade;
        Test.stopTest();

        Assert.isTrue(result, 'catalog change is upgrade');
    }

    @isTest
    private static void testScenarioStepsChangeForLBOAccounts() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Upsell_Status__c = QuoteHelper.STATUS_NEW_CUSTOMER;
        qt.Enabled_LBO__c = true;
        qt.IsSendOrderToNGBS__c = true;
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.PackageInfo__c = PACKAGE_INFO_QLI_WITH_LBOX;
            qli.UnitPrice = 100;
            qli.Entitlement__r.Price__c = 50;
            qli.NewQuantity__c += 5;
        }
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            BillingWrappers.BillingContract billingContract = buildActiveBillingContract();
            billingContract.description = PKG_DESCRIPTION_CHANGED_CONTRACT;
            SWNDataCollector sdc = new SWNDataCollector();
            sdc.qt = qt;
            sdc.billingContracts = new List<BillingWrappers.BillingContract>{billingContract};
            Response resScenario = SWNScenarioHelper.getSyncScenario(sdc);

            Assert.isTrue(resScenario.isSuccess(), 'getSyncScenario should return response with Success status');
            Assert.isTrue(resScenario.data.containsKey('scenario'), 'response should contains "scenario" data');
            SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) resScenario.data.get('scenario');
            Assert.areEqual(true, sc.stepNames.contains(SWNStep.ORDER), 'orderStep must be in resScenario');
            Assert.areEqual(4, sc.stepNames.size(), 'resScenario must have 4 steps');
            qt.IsSendOrderToNGBS__c = false;

            SWNDataCollector sdc2 = new SWNDataCollector();
            sdc2.qt = qt;
            sdc2.billingContracts = new List<BillingWrappers.BillingContract>{billingContract};
            Response resScenarioLimited = SWNScenarioHelper.getSyncScenario(sdc2);
        Test.stopTest();

        Assert.isTrue(resScenarioLimited.isSuccess(), 'getSyncScenario should return response with Success status');
        Assert.isTrue(resScenarioLimited.data.containsKey('scenario'), 'response should contains "scenario" data');

        SWNScenarioHelper.Scenario scLimited = (SWNScenarioHelper.Scenario) resScenarioLimited.data.get('scenario');

        Assert.areNotEqual(true, scLimited.stepNames.contains(SWNStep.ORDER), 'orderStep must not be in resScenarioLimited');
        Assert.areEqual(3, scLimited.stepNames.size(), 'resScenarioLimited must have 3 steps');
        Assert.areEqual(true, scLimited.stepNames.contains(SWNStep.DISCOUNT_SYNC), 'DiscountSyncStep must not be in resScenarioLimited');
        Assert.areEqual(true, scLimited.stepNames.contains(SWNStep.CONTRACT_SYNC), 'ContractSyncStep must not be in resScenarioLimited');
        Assert.areEqual(true, scLimited.stepNames.contains(SWNStep.REPRICE_SYNC), 'RepriceSyncStep must not be in resScenarioLimited');
    }

    @isTest
    private static void testIsUpgradeFromPhoenixInSalesQuoteState() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace('"permissions":null','"existingPackageInfo":{"productName":"'+ Product2Helper.PRODUCT_MEETINGS + '"}');

        Test.startTest();
            SWNScenarioHelper.SalesQuoteState st = new SWNScenarioHelper.SalesQuoteState(qt);
            Boolean result = st.isPhoenixToOffice;
        Test.stopTest();

        Assert.isTrue(result, 'define upgrade from Phoenix to Office is working');
    }

    @isTest
    private static void testIsUpgradeStepWholesalePositive() {
        Quote qt = buildQuoteWithRequiredData();
        qt.QuotelineItems.get(0).Entitlement__r.PartnerConfig__c = '{"partnerPackageId": "5", "partnerPackageVersion": 6}';
        qt.QuotelineItems.get(0).Entitlement__r.PackageCatalogId__c = '4';
        qt.QuotelineItems.get(0).Entitlement__r.PackageVersion__c = '2';
        qt.QuotelineItems.get(0).Entitlement__r.ChargeTerm__c = Product2Helper.CHARGE_TERM_ANNUAL;

        Test.startTest();
            SWNScenarioHelper.SalesQuoteState st = new SWNScenarioHelper.SalesQuoteState(qt);
            Boolean result = st.isUpgrade;
        Test.stopTest();

        Assert.isTrue(result, 'UPGRADE step should exists when Partner Catalog is changed');
    }

    @isTest
    private static void testIsUpgradeStepWholesaleNegative() {
        Quote qt = buildQuoteWithRequiredData();
        qt.QuotelineItems.get(0).Entitlement__r.PartnerConfig__c = '{"partnerPackageId": "3", "partnerPackageVersion": 4}';
        qt.QuotelineItems.get(0).Entitlement__r.PackageCatalogId__c = PACKAGE_CATALOG_ID;
        qt.QuotelineItems.get(0).Entitlement__r.PackageVersion__c = PACKAGE_VERSION;
        qt.QuotelineItems.get(0).Entitlement__r.ChargeTerm__c = Product2Helper.CHARGE_TERM_ANNUAL;

        Test.startTest();
            SWNScenarioHelper.SalesQuoteState st = new SWNScenarioHelper.SalesQuoteState(qt);
            Boolean result = st.isUpgrade;
        Test.stopTest();

        Assert.isFalse(result, 'UPGRADE step should not exists when Partner Catalog is not changed');
    }

    @isTest
    private static void testHasInvoiceStepPartnerPackageChanged() {
        Quote qt = buildQuoteWithRequiredData();
        qt.Package_Info__c = PACKAGE_INFO.replace('"permissions":null','"partnerPackage":{"id":"1"}');
        qt.QuotelineItems.get(0).Entitlement__r.PartnerConfig__c = '{"partnerPackageId": "18", "partnerPackageVersion": 1}';

        Test.startTest();
            SWNScenarioHelper.SalesQuoteState st = new SWNScenarioHelper.SalesQuoteState(qt);
            Boolean result = st.hasInvoiceStep;
        Test.stopTest();

        Assert.isTrue(result, 'SyncInvoice step should appear when Partner Catalog is changed');
    }

    @isTest
    static void testLBONonContractedS16ScenarioExists() {
        final List<String> steps = new List<String> {SWNStep.DOWN_SELL, SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.ORDER};

        Test.startTest();
            SWNScenarioHelper.Scenario sc = SWNScenarioHelper.SCENARIOS.get('LBO_NON_CONTRACTED_S16');
            List<String> result = sc.stepNames;
        Test.stopTest();

        Assert.isNotNull(sc, 'Scenario should exist in the list');
        Assert.areEqual(steps, result, 'Steps should be equal');
    }

    @isTest
    static void testNonContractedS16ScenarioExists() {
        final List<String> steps = new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE, SWNStep.UP_SELL};

        Test.startTest();
            SWNScenarioHelper.Scenario sc = SWNScenarioHelper.SCENARIOS.get('NON_CONTRACTED_S16');
            List<String> result = sc.stepNames;
        Test.stopTest();

        Assert.isNotNull(sc, 'Scenario should exist in the list');
        Assert.areEqual(steps, result, 'Steps should be equal');
    }

    @isTest
    static void testGetScenarioByKey() {
        final String NON_EXISTING_KEY = 'nonExistingKey';
        final String EXISTING_KEY = 'existingKey';

        new SWNMockBuilders.ScenarioBuilder(EXISTING_KEY).buildAndPut();
        if (SWNScenarioHelper.SCENARIOS.containsKey(NON_EXISTING_KEY)) {
            SWNScenarioHelper.SCENARIOS.remove(NON_EXISTING_KEY);
        }

        Test.startTest();
            SWNScenarioHelper.Scenario resultWhenNonExisting = SWNScenarioHelper.getScenarioByKey(NON_EXISTING_KEY);
            SWNScenarioHelper.Scenario resultWhenExisting = SWNScenarioHelper.getScenarioByKey(EXISTING_KEY);
        Test.stopTest();

        Assert.isNull(resultWhenNonExisting, 'Should return null if there is no such scenario');
        Assert.isNotNull(resultWhenExisting, 'Should return scenario if it exists');
    }

    @isTest
    static void testGetSyncScenarioFromJSON() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableSimplifiedLBODownsell__c, true)
            .create();

        String syncInfo = '{"stepNames":["DISCOUNT_SYNC"],"scenarioName":"' + SCENARIO_KEY + '"}';
        Assert.isFalse(syncInfo.contains(SWNStep.DOWN_SELL), 'DOWN_SELL step should not be in the JSON');

        SWNDataCollector sdc = new SWNDataCollector();

        Test.startTest();
            Response res = SWNScenarioHelper.getSyncScenarioFromJSON(sdc, syncInfo);
        Test.stopTest();

        Assert.isTrue(res.data.containsKey(SWNScenarioHelper.SCENARIO_KEY), 'Scenario should have key in the response');
        Assert.areEqual(SCENARIO_KEY, (String) res.data.get(SWNScenarioHelper.SCENARIO_KEY), 'Scenario should be parsed from syncInfo');
    }


    @isTest
    static void testGetSyncScenarioFromJSONDownSell() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableSimplifiedLBODownsell__c, true)
            .create();

        String syncInfo = '{"stepNames":["DISCOUNT_SYNC", "' + SWNStep.DOWN_SELL + '"],"scenarioName":"' + SCENARIO_KEY + '"}';
        Assert.isTrue(syncInfo.contains(SWNStep.DOWN_SELL), 'DOWN_SELL step should be in the JSON');

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = buildQuoteWithRequiredData();
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            Response res = SWNScenarioHelper.getSyncScenarioFromJSON(sdc, syncInfo);
        Test.stopTest();

        Assert.isTrue(res.data.containsKey(SWNScenarioHelper.SCENARIO_KEY), 'Scenario should have key in the response');
        Assert.areNotEqual(SCENARIO_KEY, (String) res.data.get(SWNScenarioHelper.SCENARIO_KEY), 'Scenario should not be parsed from syncInfo');
    }
}