@IsTest
private class Test_DomainHandler {

    // Mock implementation of DomainHandler for testing
    private class MockDomainHandler extends DomainHandler {
        public MockDomainHandler() {
            super();
        }
    }

    // Mock implementation of IResourceHandler for testing
    private class MockResourceHandler implements IResourceHandler {
        public ApiResponse execute(ApiRequest request) {
            return new ApiResponse(200, '{"status": "success"}');
        }
    }

    @IsTest
    static void testHandlerRegistration() {
        // Given
        MockDomainHandler handler = new MockDomainHandler();
        String version = 'v1';
        String resource = '/test';
        String method = 'GET';

        // When
        handler.register(version, resource, method, MockResourceHandler.class);

        // Then
        System.assert(handler.resourceHandlers.containsKey(version), 'Version should be registered');
        System.assert(handler.resourceHandlers.get(version).containsKey(resource), 'Resource should be registered');
        System.assert(handler.resourceHandlers.get(version).get(resource).containsKey(method), 'Method should be registered');
        System.assertEquals(MockResourceHandler.class, handler.resourceHandlers.get(version).get(resource).get(method), 'Handler class should match');
    }

    @IsTest
    static void testFindHandlerSuccess() {
        // Given
        MockDomainHandler handler = new MockDomainHandler();
        ApiRequest request = new ApiRequest();
        request.version = 'v1';
        request.resourcePath = '/test';
        request.httpMethod = 'GET';
        handler.register(request.version, request.resourcePath, request.httpMethod, MockResourceHandler.class);

        // When
        Type foundHandler = handler.findHandler(request);

        // Then
        System.assertEquals(MockResourceHandler.class, foundHandler, 'Should find correct handler');
    }

    @IsTest
    static void testFindHandlerInvalidVersion() {
        // Given
        MockDomainHandler handler = new MockDomainHandler();
        ApiRequest request = new ApiRequest();
        request.version = 'v1';
        request.resourcePath = '/test';
        request.httpMethod = 'GET';

        // When/Then
        try {
            handler.findHandler(request);
            System.assert(false, 'Should throw ApiVersionException');
        } catch (ApiGateway.ApiVersionException e) {
            System.assert(e.getMessage().contains('Version not found'), 'Should throw correct exception');
        }
    }

    @IsTest
    static void testFindHandlerInvalidResource() {
        // Given
        MockDomainHandler handler = new MockDomainHandler();
        ApiRequest request = new ApiRequest();
        request.version = 'v1';
        request.resourcePath = '/test';
        request.httpMethod = 'GET';
        handler.register(request.version, '/different', request.httpMethod, MockResourceHandler.class);

        // When/Then
        try {
            handler.findHandler(request);
            System.assert(false, 'Should throw ApiResourceNotFoundException');
        } catch (ApiGateway.ApiResourceNotFoundException e) {
            System.assert(e.getMessage().contains('Resource not found'), 'Should throw correct exception');
        }
    }

    @IsTest
    static void testFindHandlerInvalidMethod() {
        // Given
        MockDomainHandler handler = new MockDomainHandler();
        ApiRequest request = new ApiRequest();
        request.version = 'v1';
        request.resourcePath = '/test';
        request.httpMethod = 'POST';
        handler.register(request.version, request.resourcePath, 'GET', MockResourceHandler.class);

        // When/Then
        try {
            handler.findHandler(request);
            System.assert(false, 'Should throw ApiMethodNotAllowedException');
        } catch (ApiGateway.ApiMethodNotAllowedException e) {
            System.assert(e.getMessage().contains('Method not allowed'), 'Should throw correct exception');
        }
    }

    @IsTest
    static void testHandleRequest() {
        // Given
        MockDomainHandler handler = new MockDomainHandler();
        ApiRequest request = new ApiRequest();
        request.version = 'v1';
        request.resourcePath = '/test';
        request.httpMethod = 'GET';
        handler.register(request.version, request.resourcePath, request.httpMethod, MockResourceHandler.class);

        // When
        ApiResponse response = handler.handleRequest(request);

        // Then
        System.assertEquals(200, response.statusCode, 'Status code should match');
        System.assertEquals('{"status": "success"}', response.responseBody, 'Response body should match');
    }

    @IsTest
    static void testCreateErrorResponse() {
        // Given
        MockDomainHandler handler = new MockDomainHandler();
        Integer statusCode = 400;
        String message = 'Bad Request';

        // When
        ApiResponse response = handler.createErrorResponse(statusCode, message);
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody);

        // Then
        System.assertEquals(400, response.statusCode, 'Status code should match');
        System.assertEquals('error', responseMap.get('status'), 'Status should be error');
        System.assertEquals(400, responseMap.get('code'), 'Error code should match');
        System.assertEquals('Bad Request', responseMap.get('message'), 'Error message should match');
    }
}