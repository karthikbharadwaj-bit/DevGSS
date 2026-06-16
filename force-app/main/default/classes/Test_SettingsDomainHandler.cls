@IsTest
private class Test_SettingsDomainHandler {
    @IsTest
    static void testSettingsEndpoint() {
        // Given
        SettingsDomainHandler handler = new SettingsDomainHandler();
        ApiRequest mockRequest = new ApiRequest();
        mockRequest.httpMethod = 'GET';
        mockRequest.version = 'v1';
        mockRequest.resourcePath = 'settings';

        // When
        ApiResponse response = handler.handleRequest(mockRequest);

        // Then
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.statusCode, 'Response should be successful');

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody);
        Map<String, Object> responseData = (Map<String, Object>)responseMap.get('data');
        System.assertEquals('Settings test endpoint successful', responseData.get('message'), 'Unexpected message in response');
        System.assertNotEquals(null, responseData.get('timestamp'), 'Timestamp should not be null');
    }
}