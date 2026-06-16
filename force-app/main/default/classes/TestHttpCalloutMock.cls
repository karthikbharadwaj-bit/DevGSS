@IsTest
public with sharing class TestHttpCalloutMock implements HttpCalloutMock {

    protected Integer code;
    protected String status;
    protected String bodyAsString;
    protected Blob bodyAsBlob;
    protected Map<String, String> responseHeaders;


    public TestHttpCalloutMock(Integer code, String status, String body) {
        this.code = code;
        this.status = status;
        this.bodyAsString = body;
        this.bodyAsBlob = null;
    }


    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(code);
        resp.setStatus(status);
        //resp.setBodyAsBlob(bodyAsBlob);
        resp.setBody(bodyAsString);

        return resp;
    }

}