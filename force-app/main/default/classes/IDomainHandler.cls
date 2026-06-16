/**
 * Interface for all domain handlers
 * Each domain will have its own implementation that processes requests
 * for that specific domain
 */
public interface IDomainHandler {
    /**
     * Handle a request for this domain
     * @param request The API request details
     * @return ApiResponse containing the response data
     */
    ApiResponse handleRequest(ApiRequest request);
}