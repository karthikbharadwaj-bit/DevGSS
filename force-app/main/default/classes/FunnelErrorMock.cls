@isTest
public class FunnelErrorMock implements HttpCalloutMock {
    
    public Integer statusCode = 400;
    
    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        FunnelAPI.FunnelResponse request = new FunnelAPI.FunnelResponse();
        request.error = new FunnelAPI.FunnelError();
        request.error.data = new FunnelAPI.ErrorData();
        request.error.message = 'Test Error';
        String str = JSON.serialize(request);
        res.setBody(str);
        res.setStatusCode(this.statusCode);
        return res;
    }
}