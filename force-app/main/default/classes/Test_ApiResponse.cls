@isTest
private class Test_ApiResponse {
    @isTest
    static void testConstructor() {
        Test.startTest();
        ApiResponse response = new ApiResponse(200, '{"test":"data"}');
        Test.stopTest();
        
        System.assertEquals(200, response.statusCode, 'Status code should match');
        System.assertEquals('{"test":"data"}', response.responseBody, 'Response body should match');
    }
    
    @isTest
    static void testSuccess() {
        Map<String, String> testData = new Map<String, String>{
            'key' => 'value'
        };
        
        Test.startTest();
        ApiResponse response = ApiResponse.success(testData);
        Test.stopTest();
        
        System.assertEquals(200, response.statusCode, 'Success response should have 200 status code');
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody);
        System.assertEquals('success', responseMap.get('status'), 'Status should be success');
        System.assert(responseMap.containsKey('data'), 'Response should contain data');
    }
    
    @isTest
    static void testCreated() {
        Map<String, String> testData = new Map<String, String>{
            'key' => 'value'
        };
        
        Test.startTest();
        ApiResponse response = ApiResponse.created(testData);
        Test.stopTest();
        
        System.assertEquals(201, response.statusCode, 'Created response should have 201 status code');
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody);
        System.assertEquals('success', responseMap.get('status'), 'Status should be success');
        System.assert(responseMap.containsKey('data'), 'Response should contain data');
    }
    
    @isTest
    static void testError() {
        String errorMessage = 'Test error message';
        
        Test.startTest();
        ApiResponse response = ApiResponse.error(errorMessage);
        Test.stopTest();
        
        System.assertEquals(400, response.statusCode, 'Error response should have 400 status code');
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody);
        System.assertEquals('error', responseMap.get('status'), 'Status should be error');
        System.assertEquals(errorMessage, responseMap.get('message'), 'Error message should match');
    }
    
    @isTest
    static void testServerError() {
        String errorMessage = 'Test server error message';
        
        Test.startTest();
        ApiResponse response = ApiResponse.serverError(errorMessage);
        Test.stopTest();
        
        System.assertEquals(500, response.statusCode, 'Server error response should have 500 status code');
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody);
        System.assertEquals('error', responseMap.get('status'), 'Status should be error');
        System.assertEquals(errorMessage, responseMap.get('message'), 'Error message should match');
    }
    
    @isTest
    static void testNotFound() {
        String errorMessage = 'Resource not found';
        
        Test.startTest();
        ApiResponse response = ApiResponse.notFound(errorMessage);
        Test.stopTest();
        
        System.assertEquals(404, response.statusCode, 'Not found response should have 404 status code');
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody);
        System.assertEquals('error', responseMap.get('status'), 'Status should be error');
        System.assertEquals(errorMessage, responseMap.get('message'), 'Error message should match');
    }
    
    @isTest
    static void testFromRestResponse_ValidResponse() {
        RestResponse restResponse = new RestResponse();
        restResponse.statusCode = 200;
        restResponse.responseBody = Blob.valueOf('{"test":"data"}');
        
        Test.startTest();
        ApiResponse response = ApiResponse.fromRestResponse(restResponse);
        Test.stopTest();
        
        System.assertEquals(200, response.statusCode, 'Status code should match');
        System.assertEquals('{"test":"data"}', response.responseBody, 'Response body should match');
    }
    
    @isTest
    static void testFromRestResponse_NullResponse() {
        Test.startTest();
        ApiResponse response = ApiResponse.fromRestResponse(null);
        Test.stopTest();
        
        System.assertEquals(500, response.statusCode, 'Null response should return 500 status code');
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody);
        System.assertEquals('error', responseMap.get('status'), 'Status should be error');
        System.assertEquals('Internal server error: null response', responseMap.get('message'), 'Error message should match');
    }
    
    @isTest
    static void testFromRestResponse_NullStatusCode() {
        RestResponse restResponse = new RestResponse();
        restResponse.responseBody = Blob.valueOf('{"test":"data"}');
        
        Test.startTest();
        ApiResponse response = ApiResponse.fromRestResponse(restResponse);
        Test.stopTest();
        
        System.assertEquals(500, response.statusCode, 'Null status code should return 500');
        System.assertEquals('{"test":"data"}', response.responseBody, 'Response body should match');
    }
    
    @isTest
    static void testFromRestResponse_NullResponseBody() {
        RestResponse restResponse = new RestResponse();
        restResponse.statusCode = 200;
        
        Test.startTest();
        ApiResponse response = ApiResponse.fromRestResponse(restResponse);
        Test.stopTest();
        
        System.assertEquals(200, response.statusCode, 'Status code should match');
        System.assertEquals('', response.responseBody, 'Null response body should return empty string');
    }
}