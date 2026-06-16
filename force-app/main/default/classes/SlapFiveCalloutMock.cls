@IsTest
global class SlapFiveCalloutMock implements HttpCalloutMock {

    private Integer statusCode;
    private String responseBody;

    // Default constructor → keeps existing tests working (200 OK)
    global SlapFiveCalloutMock() {
        this.statusCode = 200;
        this.responseBody = '{"status": "success"}';
    }

    // Overloaded constructor → allows non-200 responses
    global SlapFiveCalloutMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setBody(responseBody);
        return res;
    }
}