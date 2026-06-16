public class OpportunityStatusEndpointHelper {
    public static final String STATUS_SUCCESS = 'success';
    public static final String STATUS_ERROR = 'error';
    public static final String SEVERITY_ERROR = 'error';
    public static final String WRONG_JSON_FORMAT = 'wrong json format';
    //Validation error info
    public static final String EMPTY_REQUEST = 'Empty request';
    public static final String EMPTY_REQUEST_DETAILS = 'Request does not contain Opportunity Id';
    public static final String OPPORTUNITY_NOT_FOUND = 'No opportunity with id - ';
    public static final String OPPORTUNITY_NOT_FOUND_DETAILS = 'Non-existent Opportunity Id';

    public class OpportunityParamsResponse {                
        public OpportunityParamsResponseData data = new OpportunityParamsResponseData();
        public String status;
        public List<Messages> messages = new List<Messages>();

        public OpportunityParamsResponse() {

        }

        public OpportunityParamsResponse(String status, Messages messages, List<OpportunitiesParams> opportnuityParamsList) {
            this.status = status;
            this.messages.add(messages);
            this.data.opportunities = opportnuityParamsList;
        }
        public OpportunityParamsResponse(String status, List<Messages> messages, List<OpportunitiesParams> opportnuityParamsList) {
            this.status = status;
            this.messages = messages;
            this.data.opportunities = opportnuityParamsList;
        }
    }
    public class OpportunityParamsResponseData {                
        public List<OpportunitiesParams> opportunities = new List<OpportunitiesParams>();
    }
    public class Messages{
        public String severity;
        public String message;
        public String messageDetails;

        public Messages(){

        }

        public Messages(String severity, String message, String messageDetails) {
            this.severity = severity;
            this.message = message;
            this.messageDetails = messageDetails;
        }
    }
    public class OpportunitiesParams{
        public String ngbsSyncStatus;
        public ID id;
    }
    public class IcbStatusRequest {
        public List<String> opportunityIds;
    }
    public static Messages createErrorList(String message, String details) {
        return new Messages(
                SEVERITY_ERROR,
                message,
                details
            );
    }
    private static void setResponseBody(OpportunityParamsResponse params) {
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(params));
    }
    public static void handleError(String status, Messages errorMessages, List<OpportunitiesParams> opportnuityParamsList) {
        setResponse(status, errorMessages, opportnuityParamsList);
    }
    public static void setResponse(String status, Messages messageList, List<OpportunitiesParams> opportnuityParamsList){
        setResponseBody(new OpportunityParamsResponse(status, messageList, opportnuityParamsList));
    }
    public static void setSuccessResponse(OpportunityParamsResponse params){
        params.status = STATUS_SUCCESS;
        setResponseBody(params);
    }
    public static void handleError(String status, List<Messages> errorMessages, List<OpportunitiesParams> opportnuityParamsList) {
        setResponse(status, errorMessages, opportnuityParamsList);
    }
    public static void setResponse(String status, List<Messages> messageList, List<OpportunitiesParams> opportnuityParamsList){
        setResponseBody(new OpportunityParamsResponse(status, messageList, opportnuityParamsList));
    }
}