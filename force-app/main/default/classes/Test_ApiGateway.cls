/**
 * @description Test class for ApiGateway
 */
@IsTest
private class Test_ApiGateway {

    private static final String TEST_DOMAIN = 'test-domain';
    private static final String TEST_PATH = '/api/' + TEST_DOMAIN + '/v1/test-resource';
    private static final String SUCCESS_STATUS = 'success';
    private static final String ERROR_STATUS = 'error';
    private static final String ASSERT_STATUS_MISMATCH = 'Response status should match expected value';
    private static final String ASSERT_CODE_MISMATCH = 'Status code should match expected value';

    // Control flags for mock handler behavior - moved from inner class to top level
    private static Boolean mockHandlerShouldExecute = true;
    private static Boolean mockHandlerShouldThrowException = false;

    /**
     * @description Sets up test data and mocks
     */
    @TestSetup
    static void testData() {
        // No setup needed as we're using RestContext directly
    }

    /**
     * @description GET request should return success response when valid path provided
     */
    @IsTest
    static void responseShouldSucceedWhenGetMethodCalled() {
        RestRequest req = new RestRequest();
        req.requestURI = TEST_PATH;
        req.httpMethod = 'GET';

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        // Mock handler will return success response
        Test.startTest();
            mockHandlerShouldExecute = true;
            mockHandlerShouldThrowException = false;
            DomainHandlerFactory.registerMockHandler(TEST_DOMAIN, new MockSuccessDomainHandler());
            ApiGateway.handleGet();
        Test.stopTest();

        // Clear mock handlers for other tests
        DomainHandlerFactory.clearMockHandlers();

        // ASSERT
        System.assertEquals(200, res.statusCode, ASSERT_CODE_MISMATCH);

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(SUCCESS_STATUS, responseMap.get('status'), ASSERT_STATUS_MISMATCH);
    }

    /**
     * @description POST request should return success response when valid data provided
     */
    @IsTest
    static void responseShouldSucceedWhenPostMethodCalled() {
        RestRequest req = new RestRequest();
        req.requestURI = TEST_PATH;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"test":"data"}');
        req.addHeader('Content-Type', 'application/json');
        req.addParameter('param1', 'value1');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        // Mock handler will return success response
        Test.startTest();
            mockHandlerShouldExecute = true;
            mockHandlerShouldThrowException = false;
            DomainHandlerFactory.registerMockHandler(TEST_DOMAIN, new MockSuccessDomainHandler());
            ApiGateway.handlePost();
        Test.stopTest();

        // Clear mock handlers for other tests
        DomainHandlerFactory.clearMockHandlers();

        // ASSERT
        System.assertEquals(200, res.statusCode, ASSERT_CODE_MISMATCH);

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(SUCCESS_STATUS, responseMap.get('status'), ASSERT_STATUS_MISMATCH);
    }

    /**
     * @description PUT request should return success response when valid path provided
     */
    @IsTest
    static void responseShouldSucceedWhenPutMethodCalled() {
        RestRequest req = new RestRequest();
        req.requestURI = TEST_PATH;
        req.httpMethod = 'PUT';

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        // Mock handler will return success response
        Test.startTest();
            mockHandlerShouldExecute = true;
            mockHandlerShouldThrowException = false;
            DomainHandlerFactory.registerMockHandler(TEST_DOMAIN, new MockSuccessDomainHandler());
            ApiGateway.handlePut();
        Test.stopTest();

        // Clear mock handlers for other tests
        DomainHandlerFactory.clearMockHandlers();

        // ASSERT
        System.assertEquals(200, res.statusCode, ASSERT_CODE_MISMATCH);
    }

    /**
     * @description DELETE request should return success response when valid path provided
     */
    @IsTest
    static void responseShouldSucceedWhenDeleteMethodCalled() {
        RestRequest req = new RestRequest();
        req.requestURI = TEST_PATH;
        req.httpMethod = 'DELETE';

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        // Mock handler will return success response
        Test.startTest();
            mockHandlerShouldExecute = true;
            mockHandlerShouldThrowException = false;
            DomainHandlerFactory.registerMockHandler(TEST_DOMAIN, new MockSuccessDomainHandler());
            ApiGateway.handleDelete();
        Test.stopTest();

        // Clear mock handlers for other tests
        DomainHandlerFactory.clearMockHandlers();

        // ASSERT
        System.assertEquals(200, res.statusCode, ASSERT_CODE_MISMATCH);
    }

    /**
     * @description PATCH request should return success response when valid path provided
     */
    @IsTest
    static void responseShouldSucceedWhenPatchMethodCalled() {
        // ARRANGE
        RestRequest req = new RestRequest();
        req.requestURI = TEST_PATH;
        req.httpMethod = 'PATCH';

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        // Mock handler will return success response
        Test.startTest();
            mockHandlerShouldExecute = true;
            mockHandlerShouldThrowException = false;
            DomainHandlerFactory.registerMockHandler(TEST_DOMAIN, new MockSuccessDomainHandler());
            ApiGateway.handlePatch();
        Test.stopTest();

        // Clear mock handlers for other tests
        DomainHandlerFactory.clearMockHandlers();

        // ASSERT
        System.assertEquals(200, res.statusCode, ASSERT_CODE_MISMATCH);
    }

    /**
     * @description Gateway should return 404 error when invalid domain is provided
     */
    @IsTest
    static void responseShouldReturn404WhenInvalidDomainProvided() {
        // ARRANGE
        RestRequest req = new RestRequest();
        req.requestURI = '/api/invalid-domain/v1/settings';
        req.httpMethod = 'GET';

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        // ACT
        Test.startTest();
            ApiGateway.handleGet();
        Test.stopTest();

        // ASSERT
        System.assertEquals(404, res.statusCode, ASSERT_CODE_MISMATCH);

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(ERROR_STATUS, responseMap.get('status'), ASSERT_STATUS_MISMATCH);
        System.assertEquals(404, responseMap.get('code'), 'Error code should be 404');
    }

    /**
     * @description Gateway should return 400 error when invalid version format is provided
     */
    @IsTest
    static void responseShouldReturn400WhenInvalidVersionProvided() {
        // ARRANGE
        RestRequest req = new RestRequest();
        req.requestURI = '/api/' + TEST_DOMAIN + '/invalid-version/settings';
        req.httpMethod = 'GET';

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        // ACT
        Test.startTest();
            ApiGateway.handleGet();
        Test.stopTest();

        // ASSERT
        System.assertEquals(400, res.statusCode, ASSERT_CODE_MISMATCH);

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(ERROR_STATUS, responseMap.get('status'), ASSERT_STATUS_MISMATCH);
        System.assertEquals(400, responseMap.get('code'), 'Error code should be 400');
    }

    /**
     * @description Gateway should return 404 error when resource path is missing
     */
    @IsTest
    static void responseShouldReturn404WhenResourcePathMissing() {
        // ARRANGE
        RestRequest req = new RestRequest();
        req.requestURI = '/api/' + TEST_DOMAIN + '/v1';
        req.httpMethod = 'GET';

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        // ACT
        Test.startTest();
            ApiGateway.handleGet();
        Test.stopTest();

        // ASSERT
        System.assertEquals(404, res.statusCode, ASSERT_CODE_MISMATCH);

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(ERROR_STATUS, responseMap.get('status'), ASSERT_STATUS_MISMATCH);
        System.assertEquals(404, responseMap.get('code'), 'Error code should be 404');
    }

    /**
     * @description Gateway should return 500 error when domain handler throws exception
     */
    @IsTest
    static void responseShouldReturn500WhenDomainHandlerThrowsException() {
        // ARRANGE
        RestRequest req = new RestRequest();
        req.requestURI = TEST_PATH;
        req.httpMethod = 'GET';

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        // Register a mock handler that will throw an exception
        Test.startTest();
            mockHandlerShouldExecute = false;
            mockHandlerShouldThrowException = true;
            DomainHandlerFactory.registerMockHandler(TEST_DOMAIN, new MockSuccessDomainHandler());
            ApiGateway.handleGet();
        Test.stopTest();

        // Clear mock handlers for other tests
        DomainHandlerFactory.clearMockHandlers();

        // ASSERT
        System.assertEquals(500, res.statusCode, ASSERT_CODE_MISMATCH);

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(ERROR_STATUS, responseMap.get('status'), ASSERT_STATUS_MISMATCH);
        System.assertEquals(500, responseMap.get('code'), 'Error code should be 500');
    }

    /**
     * @description Gateway should return 405 error when method is not allowed for resource
     */
    @IsTest
    static void responseShouldReturn405WhenMethodNotAllowed() {
        RestRequest req = new RestRequest();
        req.requestURI = TEST_PATH;
        req.httpMethod = 'POST'; // Using POST but any method would work for this test

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            DomainHandlerFactory.registerMockHandler(TEST_DOMAIN, new MockMethodNotAllowedHandler());
            ApiGateway.handlePost();
        Test.stopTest();

        DomainHandlerFactory.clearMockHandlers();

        // ASSERT
        System.assertEquals(405, res.statusCode, ASSERT_CODE_MISMATCH);

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(ERROR_STATUS, responseMap.get('status'), ASSERT_STATUS_MISMATCH);
        System.assertEquals(405, responseMap.get('code'), 'Error code should be 405');
    }

    /**
     * @description Gateway should return 404 error when URL format is missing domain or version
     */
    @IsTest
    static void responseShouldReturn404WhenMissingDomainOrVersion() {
        RestRequest req = new RestRequest();
        req.requestURI = '/api/'; // Invalid URL with missing domain and version
        req.httpMethod = 'GET';

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            ApiGateway.handleGet();
        Test.stopTest();

        // ASSERT
        System.assertEquals(404, res.statusCode, ASSERT_CODE_MISMATCH);

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(ERROR_STATUS, responseMap.get('status'), ASSERT_STATUS_MISMATCH);
        System.assertEquals(404, responseMap.get('code'), 'Error code should be 404');

        // Verify the error message mentions missing domain or version
        String errorMessage = (String)responseMap.get('message');
        System.assert(errorMessage.contains('missing domain or version'), 'Error message should mention missing domain or version');
    }

    /**
     * @description Mock domain handler for testing success cases
     */
    private class MockSuccessDomainHandler implements IDomainHandler {
        public ApiResponse handleRequest(ApiRequest request) {
            if (mockHandlerShouldThrowException) {
                throw new TestException('Test exception');
            }

            if (mockHandlerShouldExecute) {
                Map<String, Object> responseData = new Map<String, Object>{
                    'message' => 'Success',
                    'requestInfo' => new Map<String, Object>{
                        'method' => request.httpMethod,
                        'domain' => request.domain,
                        'version' => request.version,
                        'path' => request.resourcePath,
                        'hasBody' => String.isNotBlank(request.requestBody),
                        'hasHeaders' => request.headers != null && !request.headers.isEmpty(),
                        'hasParams' => request.params != null && !request.params.isEmpty()
                    }
                };
                return ApiResponse.success(responseData);
            }

            return ApiResponse.error('Mock handler failed');
        }
    }

    /**
     * @description Mock domain handler that throws ApiMethodNotAllowedException
     */
    private class MockMethodNotAllowedHandler implements IDomainHandler {
        public ApiResponse handleRequest(ApiRequest request) {
            throw new ApiGateway.ApiMethodNotAllowedException('Method ' + request.httpMethod + ' is not allowed for resource ' + request.resourcePath);
        }
    }

    private class TestException extends Exception {}
}