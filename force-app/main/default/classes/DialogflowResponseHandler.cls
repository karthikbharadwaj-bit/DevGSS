public class DialogflowResponseHandler {
    // HTTP Status Codes
    public static final Integer STATUS_SUCCESS = 200;
    public static final Integer STATUS_BAD_REQUEST = 400;
    public static final Integer STATUS_UNAUTHORIZED = 401;
    public static final Integer STATUS_NOT_FOUND = 404;
    public static final Integer STATUS_SERVER_ERROR = 500;
    
    // Response structure
    public class ApiResponse {
        public Boolean success;
        public String message;
        public Object data;
        public String errorCode;
        
        public ApiResponse(Boolean success, String message, Object data, String errorCode) {
            this.success = success;
            this.message = message;
            this.data = data;
            this.errorCode = errorCode;
        }
    }
    
    // Success response
    public static void sendSuccess(String message, Object data) {
        RestContext.response.statusCode = STATUS_SUCCESS;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(
            new ApiResponse(true, message, data, null)
        ));
    }
    
    // Error response
    public static void sendError(Integer statusCode, String message, String errorCode) {
        RestContext.response.statusCode = statusCode;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(
            new ApiResponse(false, message, null, errorCode)
        ));
    }
    
    // Handle exceptions
    public static void handleException(Exception e) {
        String errorMessage = e.getMessage();
        String errorCode = e.getTypeName();
        Integer statusCode = STATUS_SERVER_ERROR;
        
        // Determine appropriate status code based on exception type
        if (e instanceof DialogflowService1.DialogflowException || 
            e instanceof CaseSelectorDialogflow.CaseSelectorException ||
            e instanceof UserSelectorDialogflow.UserSelectorException ||
            e instanceof KnowledgeArticleSelectorDialogflow.KnowledgeArticleSelectorException) {
            statusCode = STATUS_BAD_REQUEST;
        }
        
        // Log error
        System.debug(LoggingLevel.ERROR, 'Error in Dialogflow API: ' + errorMessage);
        System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        
        // Send error response
        sendError(statusCode, errorMessage, errorCode);
    }
    
    // Validate required parameters
    public static void validateRequiredParams(Map<String, String> params, Set<String> requiredParams) {
        List<String> missingParams = new List<String>();
        
        for (String param : requiredParams) {
            if (String.isBlank(params.get(param))) {
                missingParams.add(param);
            }
        }
        
        if (!missingParams.isEmpty()) {
            throw new DialogflowException('Required parameters missing: ' + String.join(missingParams, ', '));
        }
    }
    
    public class DialogflowException extends Exception {}
}