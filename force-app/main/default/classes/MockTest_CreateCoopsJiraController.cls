@isTest
global class MockTest_CreateCoopsJiraController implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"id": "8280640","key": "COOPS-8883","self": "https://jira-tests.ringcentral.com/rest/api/2/issue/8280640"}');
        response.setStatusCode(200);
        return response; 
    }
}