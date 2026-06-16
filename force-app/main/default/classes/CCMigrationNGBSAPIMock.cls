public class CCMigrationNGBSAPIMock implements HttpCalloutMock {

    public static final String BILLING_ID = '55525013';
    public static final String NGBS_ACCOUNT_RESPONSE = '{"packages":[{"id":55525013,"catalogId":"583","version":"2","currency":"USD"}],"currency":"USD"}';

    public static final String BILLING_INFO_RESPONSE = '{"accountId":55525013,"product":"Engage Digital Standalone","productLine":"Engage products",'
        + '"licenses":[{"licenseId":4884431013,"topLicenseId":4884431013,"catalogId":"SA_SEAT_5","categoryId":"SEAT",'
        + '"description":"Engage Digital named seat, omni-channel","billingCycleDuration":"Annual","billingType":"Recurring",'
        + '"qty":40,"price":1080,"billingStartDate":"2023-01-23","billingEndDate":"2024-01-22","scheduledForRemoval":false,'
        + '"activeState":"Active","discount":{"value":{"unit":"Money","value":0},"startDate":"2022-08-03","endDate":null},'
        + '"props":{"end":"c&#124;named_user_omni_limit"}},{"licenseId":4884431013,"topLicenseId":4884431013,"catalogId":"SA_SEAT_5","categoryId":"SEAT",'
        + '"description":"Engage Digital named seat, omni-channel","billingCycleDuration":"Annual","billingType":"Recurring",'
        + '"qty":40,"price":1080,"billingStartDate":"2023-01-23","billingEndDate":"2024-01-22","scheduledForRemoval":false,'
        + '"activeState":"Active","discount":{"value":{"unit":"Percentage","value":0},"startDate":"2022-08-03","endDate":null},'
        + '"props":{"end":"c&#124;named_user_omni_limit"}}]}'; 

    public static final String PACKAGE_LIMITS_RESPONSE = '[{'
        + '    "id": 105378013,'
        + '    "value": 250000,'
        + '    "overriddenLimitId": null,'
        + '    "limitOverride": {'
        + '      "id": 105379013,'
        + '      "value": 500000,'
        + '      "overriddenLimitId": 105378013,'
        + '      "limitOverride": null'
        + '    }'
        + '  }]';

    private final String NOT_FOUND_ERROR_BODY = '{"code": 404, "message": "HTTP 404 Not Found"}';
    private final NGBS_Settings__c settings = NGBS_Settings__c.getInstance();
    private final String ACCOUNT_ID = BILLING_ID;
    private final String PACKAGE_ID = BILLING_ID;
    private final String ACCOUNT_MANAGER_PATH = settings.BaseEndpoint__c + settings.AccountManagerPath__c + '/account/' + ACCOUNT_ID;
    private final String GET_NGBS_ACCOUNT_PATH = ACCOUNT_MANAGER_PATH + '/summary?shortView=true';
    private final String GET_NGBS_BILLING_INFO_PATH = ACCOUNT_MANAGER_PATH + '/package/'+ PACKAGE_ID + '/billinginfo';
    private final String GET_NGBS_PACKAGE_LIMITS_PATH = String.format(NGBSAPI.NGBS_PACKAGE_LIMITS_F0RMAT, new List<String> {ACCOUNT_ID, PACKAGE_ID});

    private String body;
    private Integer statusCode;

    public CCMigrationNGBSAPIMock() {
        this(200);
    }

    public CCMigrationNGBSAPIMock(Integer statusCode) {
        this.statusCode = statusCode;
    }

    public HTTPResponse respond(HTTPRequest req) {
        if (statusCode != 200) {
            body = NOT_FOUND_ERROR_BODY;
            return createResponse();
        }

        String endpoint = req.getEndpoint();

        if (endpoint == GET_NGBS_ACCOUNT_PATH) {
            body = NGBS_ACCOUNT_RESPONSE;
        } else if (endpoint == GET_NGBS_BILLING_INFO_PATH) {
            body = BILLING_INFO_RESPONSE;
        } else if (endpoint == GET_NGBS_PACKAGE_LIMITS_PATH) {
            body = PACKAGE_LIMITS_RESPONSE;
        } else {
            statusCode = 404;
            body = NOT_FOUND_ERROR_BODY;
        }
        return createResponse();
    }

    private HttpResponse createResponse() {
        HTTPResponse res = new HTTPResponse();
        res.setStatusCode(statusCode);
        res.setBody(body);
        return res;
    }
}