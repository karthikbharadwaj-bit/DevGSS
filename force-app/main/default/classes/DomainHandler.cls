/**
 * Base class for domain handlers
 * Provides common functionality for handling API requests
 * Implements the template method pattern
 */
public abstract class DomainHandler implements IDomainHandler {

    /**
     * Nested map structure to store handlers:
     * version -> resource -> method -> handler implementation
     * To be populated by subclasses
     */
    @TestVisible
    protected Map<String, Map<String, Map<String, Type>>> resourceHandlers;

    public DomainHandler() {
        this(new Map<String, Map<String, Map<String, Type>>>());
    }

    public DomainHandler(Map<String, Map<String, Map<String, Type>>> resourceHandlers) {
        this.resourceHandlers = resourceHandlers;
    }

    public void register(String version, String resource, String method, Type handler) {
        if (!resourceHandlers.containsKey(version)) {
            resourceHandlers.put(version, new Map<String, Map<String, Type>>());
        }

        if (!resourceHandlers.get(version).containsKey(resource)) {
            resourceHandlers.get(version).put(resource, new Map<String, Type>());
        }

        resourceHandlers.get(version).get(resource).put(method, handler);
    }

    /**
     * Virtual method that subclasses can override to find the appropriate handler
     * @param resourcePath The path to the resource
     * @return Type of the handler to use
     */
    public virtual Type findHandler(ApiRequest request) {
        // Extract request details
        String version = request.version;
        String resource = request.resourcePath;
        String method = request.httpMethod;

        if (!resourceHandlers.containsKey(version)) {
            throw new ApiGateway.ApiVersionException('Version not found: ' + version);
        }
        if (!resourceHandlers.get(version).containsKey(resource)) {
            throw new ApiGateway.ApiResourceNotFoundException('Resource not found: ' + resource);
        }
        if (!resourceHandlers.get(version).get(resource).containsKey(method)) {
            throw new ApiGateway.ApiMethodNotAllowedException('Method not allowed: ' + method);
        }
        return resourceHandlers.get(version).get(resource).get(method);
    }

    /**
     * Handle a request for this domain
     * Template method that orchestrates the request handling process
     * @param request The API request details
     * @return ApiResponse containing the response data
     */
    public virtual ApiResponse handleRequest(ApiRequest request) {
        // Find the appropriate handler for this resource
        Type handlerType = findHandler(request);

        // Create an instance of the handler
        IResourceHandler handler = (IResourceHandler)handlerType.newInstance();

        // Execute the handler
        return handler.execute(request);
    }

    /**
     * Create a standardized error response
     * @param statusCode HTTP status code
     * @param message Error message
     * @return ApiResponse with error details
     */
    @TestVisible
    protected ApiResponse createErrorResponse(Integer statusCode, String message) {
        Map<String, Object> errorBody = new Map<String, Object>{
            'status' => 'error',
            'code' => statusCode,
            'message' => message
        };

        ApiResponse response = new ApiResponse(statusCode, JSON.serialize(errorBody));

        return response;
    }
}