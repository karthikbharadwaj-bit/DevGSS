@isTest
public class FunnelApiMock implements HttpCalloutMock {

    public Integer statusCode = 200;
    public String status = 'OK';
    public String response = '{"result":{"devices":{"LC_HD_523":{"AUT":{"ruleType":2,"endOfSalesDate":"11\\/20\\/2021"},"USA":null}},"countries":{"AUT":{"name":"Austria","hasStates":false,"shippingLicenseIds":["LC_SHIPT_245"]},"USA":{"name":"United States","hasStates":true,"shippingLicenseIds":["LC_SHIPT_80","LC_SHIPT_81","LC_SHIPT_84"]}}},"SAFAS_SID":"606adf5dda75c5fdad4da91d966dd1ec24a43d8d7e3953222fc741cf75cc46eb","id":null}';

    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();

        res.setStatus(this.status);
        res.setStatusCode(this.statusCode);
        res.setBody(this.response);

        return res;
    }
}