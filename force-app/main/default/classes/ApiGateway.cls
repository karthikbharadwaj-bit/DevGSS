/**
 * Enterprise API Gateway
 * Provides a single entry point for all API services
 * Dispatches to appropriate domain handlers based on URL pattern
 */
@RestResource(urlMapping='/api/*')
global with sharing class ApiGateway {

    // Single entry point for all HTTP methods
    @HttpGet
    global static void handleGet() {
        processRequest('GET');
    }

    @HttpPost
    global static void handlePost() {
        processRequest('POST');
    }

    @HttpPut
    global static void handlePut() {
        processRequest('PUT');
    }

    @HttpDelete
    global static void handleDelete() {
        processRequest('DELETE');
    }

    @HttpPatch
    global static void handlePatch() {
        processRequest('PATCH');
    }

    /**
     * Central request processing logic
     */
    private static void processRequest(String httpMethod) {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Parse the URL to extract domain, version and resource path
            ApiRequest apiRequest = parseRequest(req, httpMethod);

            // Get appropriate domain handler from the factory
            IDomainHandler domainHandler = DomainHandlerFactory.getHandler(apiRequest.domain);

            // Forward the request to the domain handler
            ApiResponse apiResponse = domainHandler.handleRequest(apiRequest);

            // Set response
            res.statusCode = apiResponse.statusCode;
            res.responseBody = Blob.valueOf(apiResponse.responseBody);

        } catch(ApiDomainNotFoundException e) {
            handleError(res, 404, e.getMessage());
        } catch(ApiVersionException e) {
            handleError(res, 400, e.getMessage());
        } catch(ApiResourceNotFoundException e) {
            handleError(res, 404, e.getMessage());
        } catch(ApiMethodNotAllowedException e) {
            handleError(res, 405, e.getMessage());
        } catch(Exception e) {
            handleError(res, 500, e.getMessage());
        }
    }

    /**
     * Parse the request URL and extract domain, version and path components
     */
    private static ApiRequest parseRequest(RestRequest req, String httpMethod) {
        // URL format: /api/[domain]/v1/resource/path
        String path = req.requestURI;

        // Remove the base part
        path = path.replaceFirst('/api/', '');

        // Extract domain
        List<String> pathParts = path.split('/');
        if (pathParts.size() < 2) {
            throw new ApiDomainNotFoundException('Invalid URL format: missing domain or version');
        }

        String domain = pathParts[0];

        // Extract version
        String version = pathParts[1];
        if (!version.startsWith('v') || !version.substring(1).isNumeric()) {
            throw new ApiVersionException('Invalid API version format. Expected: v1, v2, etc.');
        }

        // Get resource path (everything after domain and version)
        String resourcePath = '';
        if (pathParts.size() > 2) {
            List<String> resourcePathParts = new List<String>();
            for (Integer i = 2; i < pathParts.size(); i++) {
                resourcePathParts.add(pathParts[i]);
            }
            resourcePath = String.join(resourcePathParts, '/');
        }
        if (String.isBlank(resourcePath)) {
            throw new ApiResourceNotFoundException('Invalid URL format: missing resource path');
        }

        // Create API request object
        ApiRequest apiRequest = new ApiRequest();
        apiRequest.httpMethod = httpMethod;
        apiRequest.domain = domain;
        apiRequest.version = version;
        apiRequest.resourcePath = resourcePath;
        apiRequest.requestBody = req.requestBody != null ? req.requestBody.toString() : null;
        apiRequest.headers = req.headers;
        apiRequest.params = req.params;

        return apiRequest;
    }

    /**
     * Handle error responses consistently
     */
    private static void handleError(RestResponse res, Integer statusCode, String message) {
        res.statusCode = statusCode;

        Map<String, Object> errorResponse = new Map<String, Object>{
            'status' => 'error',
            'code' => statusCode,
            'message' => message
        };

        res.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
    }

    // Custom exceptions
    public class ApiDomainNotFoundException extends Exception {}
    public class ApiVersionException extends Exception {}
    public class ApiResourceNotFoundException extends Exception {}
    public class ApiMethodNotAllowedException extends Exception {}
}