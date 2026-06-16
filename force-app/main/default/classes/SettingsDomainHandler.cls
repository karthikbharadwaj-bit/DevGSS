/**
 * Domain handler for Settings API
 * Handles all requests for the settings domain
 */
public class SettingsDomainHandler extends DomainHandler {

    public SettingsDomainHandler() {
        super();
        register('v1', 'settings', 'GET', TestResourceHandler.class);
    }

    /**
     * Test resource handler for the settings domain
     * Handles test endpoints
     */
    public class TestResourceHandler implements IResourceHandler {
        /**
         * Execute the handler for test requests
         * @param request The API request details
         * @return ApiResponse containing the response data
         */
        public ApiResponse execute(ApiRequest request) {
            // Simple test response
            Map<String, Object> responseData = new Map<String, Object>{
                'message' => 'Settings test endpoint successful',
                'timestamp' => System.now()
            };

            return ApiResponse.success(responseData);
        }
    }
}