@isTest
global class SLEDWebServiceCalloutMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        system.debug('Mocked Answer');
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"status": "success"}');
        return res;
    }
}