/**
 * API Response wrapper class
 * Handles the standardized response format for the API Gateway
 */
global class ApiResponse {
    public Integer statusCode;
    public String responseBody;

    public ApiResponse(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    public static ApiResponse success(Object data) {
        Map<String, Object> response = new Map<String, Object>{
            'status' => 'success',
            'data' => data
        };
        return new ApiResponse(200, JSON.serialize(response));
    }

    public static ApiResponse created(Object data) {
        Map<String, Object> response = new Map<String, Object>{
            'status' => 'success',
            'data' => data
        };
        return new ApiResponse(201, JSON.serialize(response));
    }

    public static ApiResponse error(String message) {
        Map<String, Object> response = new Map<String, Object>{
            'status' => 'error',
            'message' => message
        };
        return new ApiResponse(400, JSON.serialize(response));
    }

    public static ApiResponse error(Exception e) {
        Map<String, Object> response = new Map<String, Object>{
            'status' => 'error',
            'message' => e.getMessage(),
            'stackTrace' => e.getStackTraceString()
        };
        return new ApiResponse(400, JSON.serialize(response));
    }

    public static ApiResponse serverError(String message) {
        Map<String, Object> response = new Map<String, Object>{
            'status' => 'error',
            'message' => message
        };
        return new ApiResponse(500, JSON.serialize(response));
    }

    public static ApiResponse notFound(String message) {
        Map<String, Object> response = new Map<String, Object>{
            'status' => 'error',
            'message' => message
        };
        return new ApiResponse(404, JSON.serialize(response));
    }

    public static ApiResponse fromRestResponse(RestResponse restResponse) {
        if (restResponse == null) {
            return ApiResponse.serverError('Internal server error: null response');
        }

        String responseBody = restResponse.responseBody != null ?
            restResponse.responseBody.toString() : '';

        return new ApiResponse(
            restResponse.statusCode != null ? restResponse.statusCode : 500,
            responseBody
        );
    }
}