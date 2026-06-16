@isTest
public class BillingHttpRequestMock implements HttpCalloutMock {

    public static final String ACCOUNT_ID = '123';
    public static final String PACKAGE_ID = '456';
    private static final String LBOX_ELEMENT_ID = 'LB_702';
    public static final String PACKAGE_STATUS_DELETED = 'Deleted';
    public static final String BASE_ENDPOINT;
    private static final String CATALOG_PATH;
    public static final String ACCOUNT_MANAGER_PATH;

    private static final String ACCOUNT_INFO_ENDPOINT;
    private static final String BILLING_INFO_ENDPOINT;
    private static final String BILLING_INFO_LICENSES_ENDPOINT;
    private static final String BILLING_INFO_ALLLICENSES_ENDPOINT;
    private static final String BILLING_PACKAGES_ENDPOINT;
    private static final String BILLING_PACKAGES_SHORT_VIEW_ENDPOINT;
    private static final String TAX_EXEMPTION_ENDPOINT;
    private static final String VAT_NUMBER_ENDPOINT;
    private static final String PAYMENT_METHOD_ENDPOINT;
    private static final String CONTACT_INFO_ENDPOINT;
    private static final String PAYMENT_METHOD_TYPE_ENDPOINT;
    private static final String PACKAGE_LIMITS_ENDPOINT;
    private static final String PACKAGE_CONSOLIDATION_SETTINGS_ENDPOINT;
    private static final String CHECK_COST_CENTERS_ENDPOINT;
    private static final String CREATE_COST_CENTERS_ENDPOINT;
    private static final String UPDATE_COST_CENTERS_STATUS_ENDPOINT;
    private static final String UPDATE_NGBS_PACKAGE_STATUS;

    private static String BILLING_INFO_ALL_LICENSE_RESPONSE = '{"productLine" : "RC","packageId" : "25309001","packageExpirationDate" : null,"packageDuration" : null,"packageDescription" : "RingCentral Office Standard","nextBillingDate" : "2021-04-03T07:00Z[UTC]","licenses" : ['
        + '{"topLicenseId" : "369487001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 2000.0,"licenseTypeId" : null,"licenseId" : "369488001","discount" : null,"description" : "Extended Enterprise Support - Platinum Tier - Office - Additional TAM","categoryId" : "EES-TAM","catalogId" : "LC_EES-TAM_949","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration":"Monthly","batch":null}],"creditBalance" : 0,"accountId" : "25309001"}';

    private static String CONTRACT_RESPONSE = '[{"id":42775001,"createdAt":"2019-07-26T16:47:33.664Z[UTC]","lastUpdated":"2019-07-31T15:41:37.203Z[UTC]",' +
        '"startBillingCycleNumber":0,"startDate":"2019-07-26","renewalDate":null,"term":12,"renewalTerm":12,' +
        '"autoRenewal":true,"packageVersion":"1","licenses":[{"id":25905001,"catalogId":"LC_DL-UNL_50",' +
        '"contractualQty":101},{"id":25906001,"catalogId":"LC_CRF_51","contractualQty":101}]}]';

    private static final String LICENSES_COUNTER_RESPONSE = '[' +
        '{"instanceQty" : 1,"categoryId" : "DID","catalogId" : "LC_DID_53","billingCodeId" : null,"batchQty" : 12}, ' +
        '{"instanceQty" : 1,"categoryId" : "DL-UNL","catalogId" : "LC_DL-UNL_50","billingCodeId" : null,"batchQty" : 12}, ' +
        '{"instanceQty" : 1,"categoryId" : "DL","catalogId" : "LC_DL_75","billingCodeId" : null,"batchQty" : 12}, ' +
        '{"instanceQty" : 1,"categoryId" : "E911","catalogId" : "LC_E911_52","billingCodeId" : null,"batchQty" : 12}, ' +
        '{"instanceQty" : 1,"categoryId" : "CRF","catalogId" : "LC_CRF_51","billingCodeId" : null,"batchQty" : 12}]';

    private static String SHIPPING_LICENSE_RESPONSE = '[{"elementID":"LC_SHIPT_81","name":"Test Shipping Name - Ground", "displayName":"Test DisplayName","billingType":"testBillingType","searchCategories":[{"key":"ShippingCode","value":"GROUND"}]}, {"elementID":"LC_SHIPT_82","name":"Test Shipping Name - Overnight", "displayName":"Test DisplayName","billingType":"testBillingType","searchCategories":[{"key":"ShippingCode","value":"OVERNIGHT"}]}, {"elementID":"LC_SHIPT_83","name":"Test Shipping Name - 2 Day", "displayName":"Test DisplayName","billingType":"testBillingType","searchCategories":[{"key":"ShippingCode","value":"2DAY"}]}]';
    public static final String ADDRESS_STRING = '{"label":null,"firstName":"Bill","lastName":"Murrey","phone":"+1(800)764-1298","street1":"111 Industrial Ctr","street2":null,"city":"Belmont","county":null,"state":"CA","zip":"94002","country":"USA"}';
    public static String GET_PAYMENT_METHOD_RESPONSE = '[{"id":27328005,"accountId":227775005,"addedAt":"2020-12-22T15:25:25.301Z[UTC]","creditCardInfo":{"terms":0,"address":{"label":null,"firstName":"Rechecked4183_RCUS2112","lastName":"Rechecked4183_RCUS2112","phone":null,"street1":"111 Industrial Ctr","street2":null,"city":"Belmont","county":null,"state":"CA","zip":"94002","country":"USA"}},"default":true}]';
    public static String POST_PAYMENT_METHOD_RESPONSE = '[{"id":27328005,"accountId":227775005,"addedAt":"2020-12-22T15:25:25.301Z[UTC]","creditCardInfo":{"terms":0,"address":' + ADDRESS_STRING + '},"invoiceInfo":{"terms":0,"address":' + ADDRESS_STRING + '},"invoiceOnBehalfInfo":{"terms":0,"address":' + ADDRESS_STRING + '},"default":true}]';
    public static String GET_PACKAGE_LIMITS_RESPONSE = '[{"id":117279005,"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":300000,"type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","targetId":null,"exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":true,"paymentType":null,"startDate":null,"limitDuration":null,"overriddenLimitId":null,"limitOverride":null}]';
    private static String ORDER_API_ERROR_RESPONSE = '{"message": "service=invoice, response={status=403, {code=40003, message=transaction limit exceeded, type=Amount, limitType=Amount}}"}';
    public static String POST_PACKAGES_SEARCH_RESPONSE ='[{"id":"880","version":"1","configureFeaturesVersion":3,"priceVersion":939,"status":"Actual","name":"Migrated Legacy (USD)","displayName":"Migrated Legacy (USD)","productId":"22","productName":"RingCentral Contact Center","startDate":"1970-01-01T11:00Z[UTC]","currency":"USD","offerType":"Regular",' +
        '"labels":{"UpgradeWizardExpiration":["Active Testing"],"Brand":["RingCentral"],"NsClass":["RC CC|RingCentral Contact Center"],"SIGNUP_SFDCVAR":["Active"],"SIGNUP_SFDC":["Active"]},"masterDuration":["Monthly","Annual"],"pricingId":880,"structureId":27580005,"edition":{"id":40,"name":"Migrated Legacy Catalog"},"paymentMethodTypes":["Invoice"],' +
        '"customParameters":[{"id":3,"name":"EnableUpgradeOnContract","description":"upgrade when account has contract: -1 = allowed, 0 - not allowed","value":"-1","level":"account","numeric":true},{"id":7,"name":"UsageCollectionDelay","description":"to manage the delay in usage collection","value":"1","level":"account","numeric":true},' +
        '{"id":8,"name":"UsageDelayedBillingEnabled","description":"Allow delayed usage billing: -1 = allowed, 0=not allowed","value":"-1","level":"account","numeric":true}],"headVersion":false,"nsReporting":true,"businessIdentity":{"id":4,"name":"RingCentral Inc.","createDate":"2023-02-24T13:19:01.714397Z[UTC]"}}]';
    private static String ACCOUNT_LBOXES_LIMITS_RESPONSE = '[{"id":12010103001,"description":"RCRooms' +
        '","lboxLimits":[{"type":"Max","value":1000,"defaultLimit":true},{"type":"Min","value":0,"defaultLimit":' +
        'true}],"lboxCatalogId":"' + LBOX_ELEMENT_ID + '","lboxItems":[{"id":12010103001,' +
        '"catalogId":"LC_RCRM_77","description":"RC Rooms"}]}]';

    static {
        NGBS_Settings__c settings = NGBS_Settings__c.getInstance();

        BASE_ENDPOINT = !String.isBlank(settings.BaseEndpoint__c) ?
            settings.BaseEndpoint__c : 'http://fake-billing-api';

        CATALOG_PATH = !String.isBlank(settings.CatalogPath__c) ?
            settings.CatalogPath__c : '/restapi/v1.0/catalog';

        ACCOUNT_MANAGER_PATH = !String.isBlank(settings.AccountManagerPath__c) ?
            settings.AccountManagerPath__c : '/restapi/account-manager/v1.0';

        ACCOUNT_INFO_ENDPOINT = BASE_ENDPOINT + '/account-manager/v1.0/account/' + ACCOUNT_ID + '/summary';
        BILLING_INFO_ENDPOINT = BASE_ENDPOINT + '/account-manager/account/' + ACCOUNT_ID + '/package/'+PACKAGE_ID+'/billinginfo';
        BILLING_INFO_ALLLICENSES_ENDPOINT = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/' + ACCOUNT_ID + '/package/'+PACKAGE_ID+'/billinginfo/?filterCatalogId=';
        BILLING_INFO_LICENSES_ENDPOINT = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/' + ACCOUNT_ID + '/package/'+PACKAGE_ID+'/billinginfo/summary/license';
        BILLING_PACKAGES_ENDPOINT = BASE_ENDPOINT + CATALOG_PATH + '/packages';
        BILLING_PACKAGES_SHORT_VIEW_ENDPOINT =  BASE_ENDPOINT + ACCOUNT_MANAGER_PATH + '/account/' + ACCOUNT_ID + '/summary?shortView=true';
        TAX_EXEMPTION_ENDPOINT = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/' + ACCOUNT_ID + '/tax-settings';
        VAT_NUMBER_ENDPOINT = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/' + ACCOUNT_ID + '/tax-settings/VATNumber';
        PAYMENT_METHOD_ENDPOINT = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/[0-9]+/paymentMethod(/[0-9]+)?';
        CONTACT_INFO_ENDPOINT = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/[0-9]+/contactInfo';
        PAYMENT_METHOD_TYPE_ENDPOINT = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/[0-9]+/paymentMethod/type';
        PACKAGE_LIMITS_ENDPOINT = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/' + ACCOUNT_ID + '/package/'+PACKAGE_ID+'/limits';
        PACKAGE_CONSOLIDATION_SETTINGS_ENDPOINT = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/' + ACCOUNT_ID + '/packageConsolidationSettings';
        CHECK_COST_CENTERS_ENDPOINT = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/' + ACCOUNT_ID + '/billingCodes';
        CREATE_COST_CENTERS_ENDPOINT = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/' + ACCOUNT_ID + '/billingCodes/main';
        UPDATE_NGBS_PACKAGE_STATUS = BASE_ENDPOINT + '/restapi/account-manager/v1.0/account/' + ACCOUNT_ID + '/package/' + PACKAGE_ID + '/status?newStatus=' + PACKAGE_STATUS_DELETED;
    }

    public String body;
    public Integer code;
    public String status;
    protected Map<String, String> responseHeaders;

    public BillingHttpRequestMock() {}
    public BillingHttpRequestMock(List<MockInfo> mockInfos) {
        for (MockInfo mockInfo : mockInfos) {
            this.endpointToBodyMap.put(mockInfo.endpoint, mockInfo);
        }
    }
    class MyException extends Exception {
    }

    public class MockInfo {
        public String status = 'Completed';
        public String body = '';
        public Integer code = 200;
        public String method = HttpHelper.METHOD_GET;
        public String endpoint;

        public MockInfo(String body) {
            this.body = body;
        }

        public MockInfo(String status, String body, Integer code, String method) {
            this.status = status;
            this.body = body;
            this.code = code;
            this.method = method;
        }

        public MockInfo(String endpoint, String status, String body, Integer code, String method) {
            this(status, body, code, method);
            this.endpoint = endpoint;
        }
    }
    public Map<String, MockInfo> endpointToBodyMap = new Map<String, MockInfo>();

    public HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();

        Boolean isContactInfoEndpoint = Pattern.compile(CONTACT_INFO_ENDPOINT).matcher(req.getEndpoint()).matches();
        Boolean isPaymentMethodEndpoint = Pattern.compile(PAYMENT_METHOD_ENDPOINT).matcher(req.getEndpoint()).matches();
        Boolean isPaymentMethodTypeEndpoint = Pattern.compile(PAYMENT_METHOD_TYPE_ENDPOINT).matcher(req.getEndpoint()).matches();

        if ((req.getEndpoint() == ACCOUNT_INFO_ENDPOINT
            || req.getEndpoint() == BILLING_PACKAGES_SHORT_VIEW_ENDPOINT) && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';

            final String defaultAccountSummaryResponse = '{"packages":[{"id":9710001,"catalogId":"2","version":"1","currency": "USD", "status":"active"}]}';

//            if (String.isBlank(this.body)) {
                this.body = defaultAccountSummaryResponse;
//            }
        } else if (req.getEndpoint() == BILLING_INFO_ALLLICENSES_ENDPOINT + 'LC_EES_489' && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';
            if (String.isBlank(this.body)) {
                this.body = BILLING_INFO_ALL_LICENSE_RESPONSE;
            }
        } else if (req.getEndpoint() == BILLING_INFO_ENDPOINT && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';

            final String defaultBillingInfoResponse = '{"licenses":[{"licenseId":98698001,"catalogId":"LC_SC_1",' +
                '"description":"Subscription Fee","billingCycleDuration":"Monthly","qty":1,"price":24.99,' +
                '"billingStartDate":"2017-08-14","billingEndDate":"2017-09-13","discount":{"value":{"unit":"Percent",' +
                '"value":10,"recurringTerms":{"unit":"Years","value":100}}}}]}';

            if (String.isBlank(this.body)) {
                this.body = defaultBillingInfoResponse;
            }
        } else if (req.getEndpoint() == BILLING_INFO_LICENSES_ENDPOINT && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';

            final String defaultBillingInfoSummaryLicensesResponse = '[{"amount":0,"catalogId":"LC_SC_29",' +
            '"discountAmount":0,"qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly",' +
            '"dateRangeStart":"2020-08-23","dateRangeEnd":"2020-09-22","description":"Office Standard - Subscription Fee",' +
            '"descriptionKey":"3AE2610F8AA96E08CB5AD44D1AD440CA"}]';

//            if (String.isBlank(this.body)) {
                this.body = defaultBillingInfoSummaryLicensesResponse;
//            }
        } else if (req.getEndpoint().substringBeforeLast('/').substringBeforeLast('/') == BILLING_PACKAGES_ENDPOINT && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';

            final String packagesDefaultResponse = '{"labels":{"Brand":["RingCentral"]}}';

            if (String.isBlank(this.body)) {
                this.body = packagesDefaultResponse;
            }
        } else if (req.getEndpoint() == TAX_EXEMPTION_ENDPOINT && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';
            this.body = '{"VATExemption": false, "federalTaxExemption": true, "stateTaxExemption": false,' +
                '"countyTaxExemption": true, "localTaxExemption": false}';
        } else if (req.getEndpoint() == TAX_EXEMPTION_ENDPOINT && req.getMethod() == HttpHelper.METHOD_POST) {
            this.code = 200;
            this.status = 'Complete';

            NGBSAPI.TaxExemption taxExemption =
                (NGBSAPI.TaxExemption) JSON.deserialize(req.getBody(), NGBSAPI.TaxExemption.class);
            this.body = TaxExemptionHelper.prepareTaxExemptionBody(
                taxExemption.getFederalTaxExemption(),
                taxExemption.getStateTaxExemption(),
                taxExemption.getCountyTaxExemption(),
                taxExemption.getLocalTaxExemption(),
                taxExemption.getSalesTaxExemption(),
                taxExemption.getVatExemption(),
                taxExemption.getSezWopExemption(),
                taxExemption.getVatCountry(),
                taxExemption.getVatNumber(),
                taxExemption.getGstNumber());
        } else if (req.getEndpoint() == PAYMENT_METHOD_ENDPOINT && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';
            String addressStr = '{"label": "string", "firstName": "string", "lastName": "string", "phone": "string",'
                + '"street1": "string", "street2": "string", "city": "string", "county": "string", "state": "string",'
                + '"zip": "66251", "country": "string"}';
            this.body = '[{"id": "123456", "nickname": "hsggag", "invoiceInfo": {"terms": 0, "address": ' + addressStr
                + '}, "creditCardInfo": {"address": ' + addressStr +'}}]';
        } else if(req.getEndpoint().endsWith('contract')) {
            this.code = 200;
            this.status = 'Complete';
            this.body = CONTRACT_RESPONSE;

        } else if(req.getEndpoint().endsWith('licenses/counters') && req.getMethod() == HttpHelper.METHOD_POST) {
            this.code = 200;
            this.status = 'Complete';
            this.body = LICENSES_COUNTER_RESPONSE;

        } else if(req.getEndpoint().contains('license/info/categories') && req.getMethod() == HttpHelper.METHOD_POST) {
            this.code = 200;
            this.status = 'Complete';
            this.body = LICENSES_COUNTER_RESPONSE;

        } else if(isPaymentMethodEndpoint && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';
            this.body = GET_PAYMENT_METHOD_RESPONSE;

        } else if(isPaymentMethodEndpoint && req.getMethod() == HttpHelper.METHOD_POST) {
            this.code = 200;
            this.status = 'Complete';
            this.body = POST_PAYMENT_METHOD_RESPONSE;

        } else if(req.getEndpoint().endsWith('limits/override') && req.getMethod() == HttpHelper.METHOD_POST) {
            this.code = 200;
            this.status = 'Complete';
            this.body = GET_PAYMENT_METHOD_RESPONSE;
        } else if(req.getEndpoint().endsWith('limits/update') && req.getMethod() == HttpHelper.METHOD_PUT) {
            this.code = 200;
            this.status = 'Complete';
            this.body = GET_PAYMENT_METHOD_RESPONSE;
        } else if (req.getEndpoint() == VAT_NUMBER_ENDPOINT && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';
            this.body = '{"VATNumber":"61954506077","VATCountry":"FR"}';
        } else if (req.getEndpoint() == VAT_NUMBER_ENDPOINT && req.getMethod() == HttpHelper.METHOD_POST) {
            this.code = 200;
            this.status = 'Complete';
            this.body = '{"VATNumber":"61954506077","VATCountry":"FR"}';
        } else if (req.getEndpoint().endsWith('/licenses?path=SHP=0:SHIP=0:SHIPT=1') && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';
            this.body = SHIPPING_LICENSE_RESPONSE;
        } else if (isContactInfoEndpoint && req.getMethod() == HttpHelper.METHOD_PUT) {
            this.code = 200;
            this.status = 'Complete';
            this.body = '';
        } else if (req.getEndpoint().endsWith('/summary?withlboxes=false') && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';
            this.body = '{"id": "18","catalogId": "18","version": "1","labels": {"SIGNUP_SFDC": ["Active"]}}';
        } else if (req.getEndpoint() == PACKAGE_LIMITS_ENDPOINT) {
            this.body = GET_PACKAGE_LIMITS_RESPONSE;
            this.code = 200;
            this.status = 'Complete';
        } else if (isPaymentMethodTypeEndpoint && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';
            this.body = '{"currentType": "Invoice", "formerTypes": []}';
        } else if (req.getEndpoint().endsWith('/order/v2') && req.getMethod() == HttpHelper.METHOD_POST) {
            this.code = 403;
            this.status = 'Forbidden';
            this.body = ORDER_API_ERROR_RESPONSE;
        } else if (req.getEndpoint().endsWith('/search') && req.getMethod() == HttpHelper.METHOD_POST) {
            this.code = 200;
            this.status = 'Complete';
            this.body = POST_PACKAGES_SEARCH_RESPONSE;
        } else if (req.getEndpoint().equalsIgnoreCase(BASE_ENDPOINT + ACCOUNT_MANAGER_PATH + '/account/123/package/456/freeServiceCredit')
            && (req.getMethod() == HttpHelper.METHOD_GET || req.getMethod() == HttpHelper.METHOD_PUT)
        ) {
            this.code = 200;
            this.status = 'Complete';
            this.body = '{"amount": 200}';
        } else if (req.getEndpoint().equalsIgnoreCase(PACKAGE_CONSOLIDATION_SETTINGS_ENDPOINT) && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';
            this.body = '{"billingAlignmentEnabled":false,"invoiceConsolidationEnabled":false}';
        } else if (req.getEndpoint().equalsIgnoreCase(PACKAGE_CONSOLIDATION_SETTINGS_ENDPOINT) && req.getMethod() == HttpHelper.METHOD_POST) {
            this.code = 200;
            this.status = 'Complete';
            this.body = '{"billingAlignmentEnabled":true,"invoiceConsolidationEnabled":true}';
        } else if (req.getEndpoint().endsWith('/lboxes')) {
            this.code = 200;
            this.status = 'Complete';
            body = ACCOUNT_LBOXES_LIMITS_RESPONSE;
        } else if (req.getEndpoint().equalsIgnoreCase(CHECK_COST_CENTERS_ENDPOINT) && req.getMethod() == HttpHelper.METHOD_GET) {
            this.code = 200;
            this.status = 'Complete';
            this.body = '[{"id":3333505002,"type":"Regular","name":"Main","billingCodePath":[{"name":"Main","code":null}]}]';
        } else if (req.getEndpoint().equalsIgnoreCase(CREATE_COST_CENTERS_ENDPOINT) && req.getMethod() == HttpHelper.METHOD_POST) {
            this.code = 201;
            this.status = 'Created';
            this.body = '[]';
        } else if (req.getEndpoint().equalsIgnoreCase(UPDATE_NGBS_PACKAGE_STATUS) && req.getMethod() == HttpHelper.METHOD_POST) {
            this.code = 200;
            this.status = 'OK';
            this.body = '{}';
        }

        if (!endpointToBodyMap.isEmpty()) {
            for (String endpoint : endpointToBodyMap.keySet()) {
                MockInfo info = endpointToBodyMap.get(endpoint);
                if (req.getEndpoint().endsWith(endpoint) && req.getMethod() == info.method) {
                    this.code = info.code;
                    this.status = info.status;
                    this.body = info.body;
                }
            }
        }

        if (responseHeaders != null) {
            for (String key : this.responseHeaders.keySet()) {
                res.setHeader(key, this.responseHeaders.get(key));
            }
        }

        if (this.body == null) {
            throw new MyException('Error: there is no handler for ' +
                req.getMethod() + ' ' + req.getEndpoint() + ' ' +
                'endpoint in BillingHttpRequestMock.cls');
        }

        res.setBody(this.body);
        res.setStatusCode(this.code);
        res.setStatus(this.status);
        return res;
    }
}