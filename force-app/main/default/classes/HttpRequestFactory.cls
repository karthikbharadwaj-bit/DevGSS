public inherited sharing virtual class HttpRequestFactory {

    @TestVisible protected String endpoint;
    @TestVisible protected String method;

    @TestVisible protected String body;
    @TestVisible protected String contentType;
    @TestVisible protected Map<String, String> headers;
    @TestVisible protected Integer timeout;

    @TestVisible
    protected HttpRequestFactory() {
        this.headers = new Map<String, String>();
        this.contentType = HttpHelper.CONTENT_TYPE_APPLICATION_JSON;
        this.timeout = HttpHelper.DEFAULT_TIMEOUT_MS;
    }

    public HttpRequest createRequest() {
        StringHelper.validateStrict(endpoint, 'Endpoint for HttpRequest should not be empty');
        StringHelper.validateStrict(method, 'Method for HttpRequest should not be empty');

        HttpRequest request = new HttpRequest();
        request.setEndpoint(this.endpoint);
        request.setMethod(this.method);
        
        if (String.isNotBlank(body)) {
            request.setBody(body);
            request.setHeader('Content-Type', this.contentType);
        }
        for (String headerName : this.headers.keySet()) {
            request.setHeader(headerName, this.headers.get(headerName));
        }
        request.setTimeout(this.timeout);

        return request;
    }
}