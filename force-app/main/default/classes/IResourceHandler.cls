/**
 * Interface for all resource handlers
 * Each endpoint within a domain will have its own implementation
 * that processes requests for that specific resource
 */
public interface IResourceHandler {
    /**
     * Execute the handler for this resource
     * @param request The API request details
     * @return ApiResponse containing the response data
     */
    ApiResponse execute(ApiRequest request);
}