@isTest
public class FunnelApiProServMock implements HttpCalloutMock {

    public Integer statusCode = 202;

    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setStatusCode(this.statusCode);
        return res;
    }
}