/**
 * API Request wrapper class
 * Encapsulates request details from the REST API
 */
global class ApiRequest {
    public String httpMethod;
    public String domain;
    public String version;
    public String resourcePath;
    public String requestBody;
    public Map<String, String> headers;
    public Map<String, String> params;
}