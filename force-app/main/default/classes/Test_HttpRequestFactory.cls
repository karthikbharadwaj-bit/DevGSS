@isTest
private class Test_HttpRequestFactory {

    private static final String ENDPOINT = 'http://test.com';
    private static final String METHOD = 'GET';
    private static final String BODY = 'test body';
    private static final String CONTENT_TYPE = 'test type';
    private static final Map<String, String> HEADERS = new Map<String, String>{'test' => 'header'};

    @isTest
    private static void testCreateRequest() {
        HttpRequestFactory requestFactory = new HttpRequestFactory();
        Test.startTest();

        try {
            requestFactory.createRequest();
        } catch (Exception e) {
            System.assertEquals(HttpHelper.ERROR_EMPTY_ENDPOINT, e.getMessage());
        }

        requestFactory.endpoint = ENDPOINT;
        try {
            requestFactory.createRequest();
        } catch (Exception e) {
            System.assertEquals(HttpHelper.ERROR_EMPTY_METHOD, e.getMessage());
        }

        requestFactory.method = METHOD;
        requestFactory.body = BODY;
        requestFactory.contentType = CONTENT_TYPE;
        requestFactory.headers.putAll(HEADERS);
        HttpRequest request = requestFactory.createRequest();
        Test.stopTest();

        System.assertEquals(ENDPOINT, request.getEndpoint());
        System.assertEquals(METHOD, request.getMethod());
        System.assertEquals(BODY, request.getBody());
        System.assertEquals(CONTENT_TYPE, request.getHeader('Content-Type'));
        for (String key : HEADERS.keySet()) {
            System.assertEquals(HEADERS.get(key), request.getHeader(key));
        }
    }
}