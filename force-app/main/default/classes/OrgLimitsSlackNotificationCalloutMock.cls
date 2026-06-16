@isTest
public with sharing class OrgLimitsSlackNotificationCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        // Send a mock response for a specific method.
        System.assertEquals('POST', request.getMethod());
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        return response; 
    }
}