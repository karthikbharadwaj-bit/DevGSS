@isTest
private class DialogFlowAuthTest {
    
    @isTest
    static void testGetAccessToken_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"access_token":"mock_access_token"}'));
        String accessToken = DialogFlowAuth.getAccessToken();
        Test.stopTest();
        
        Assert.isNotNull(accessToken, 'Access token should not be null');
        Assert.areEqual('mock_access_token', accessToken, 'Access token should match the mocked value');
    }
    
    @isTest
    static void testGetAccessToken_Failure() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, '{"error":"invalid_grant"}'));
        String accessToken = DialogFlowAuth.getAccessToken();
        Test.stopTest();
        
        Assert.isNull(accessToken, 'Access token should be null on failure');
    }

    @isTest
    static void testGenerateJWT() {
        Test.startTest();
        String jwt = DialogFlowAuth.generateJWTForTest();
        Test.stopTest();
        Assert.isNotNull(jwt, 'Generated JWT should not be null');
        Assert.isTrue(jwt.split('\\.').size() == 3, 'JWT should have three parts separated by dots');
    }
    
    @isTest
    static void testSignWithPrivateKey() {
        String unsignedToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ0ZXN0LWlzc3VlckB0ZXN0LmNvbSIsInNjb3BlIjoiaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaWFsb2dmbG93IiwiYXVkIjoiaHR0cHM6Ly9vYXV0aDIuZ29vZ2xlYXBpcy5lYW0vdG9rZW4iLCJleHAiOjE2NzgzMTIxODQsImlhdCI6MTY3ODMxMTE4NH0';
        Test.startTest();
        String signature = DialogFlowAuth.signWithPrivateKey(unsignedToken);
        Test.stopTest();
        Assert.isNotNull(signature, 'Signature should not be null');
        Assert.areNotEqual('', signature, 'Signature should not be empty');
    }
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
}