@RestResource(urlMapping='/GlipApprovalService/*')
global with sharing class GlipApprovalService {
    public static final String INVALID_INPUT_MSG  = 'Invalid input. \'approvalWorkitemId\', \'approverEmail\' and \'action\' are required.';
    public static final String INVALID_ACTION_MSG = 'Invalid action. Please use "Approve" or "Reject".';
    public static final String GLIP_SUCCESS_MSG = 'Approval request successfully ';
    public static final String GLIP_ERROR_MSG = 'Error processing Approval: ';
    public static final String REQUEST_ALREADY_HANDLED_MSG = 'This action cannot be completed as the request is no longer pending approval. Click the Quote number to view the current status';
    public static final String INVALID_APPROVER = 'This action cannot be completed as you are not the approver on this quote';
    public static final String STATUS_FAILED = 'Failed';
    public static final String STATUS_PROCESSED = 'Processed';
    public static final String STATUS_UNAUTHORIZED = 'Unauthorized';

    public class GlipApprovalRequest {
        public String action;
        public String comment;
        public Id targetObjectId;
        public String approverEmail;
        public String approvalWorkitemId;
    }

    public class GlipApprovalResponse {
        public String status;
        public String message;
    }

    @httpPost
    global static void handleApprovalRequest() {
        GlipApprovalResponse responseBody = new GlipApprovalResponse();
        RestResponse response = RestContext.response;
        if (response == null) {
        	response = new RestResponse();
        	RestContext.response = response;
        }

        try {
            String body = RestContext.request.requestBody.toString();
            GlipApprovalRequest requestBody = (GlipApprovalRequest) JSON.deserialize(body, GlipApprovalRequest.class);

            // Validate input
            if (requestBody == null || String.isBlank(requestBody.approvalWorkitemId) || 
                String.isBlank(requestBody.action) || String.isBlank(requestBody.approverEmail)) {
                throw new IllegalArgumentException(INVALID_INPUT_MSG);
            }

            if (!(requestBody.action.equalsIgnoreCase('Approve') || requestBody.action.equalsIgnoreCase('Reject'))) {
                throw new IllegalArgumentException(INVALID_ACTION_MSG);
            }
            
            List<ProcessInstanceWorkitem> pendingWorkItems = [SELECT Id, Actor.Email From ProcessInstanceWorkitem where Id = :requestBody.approvalWorkitemId];

            if(pendingWorkItems.size() == 1) {
                if (pendingWorkItems[0].Actor.Email.equalsIgnoreCase(requestBody.approverEmail)) {
                    Approval.ProcessWorkitemRequest workItem = new Approval.ProcessWorkitemRequest();
                    workItem.setAction(requestBody.action.equalsIgnoreCase('Approve') ? 'Approve' : 'Reject');
                    workItem.setWorkitemId(requestBody.approvalWorkitemId);
                    workItem.setComments(requestBody.comment);
    
                    Approval.ProcessResult result = Approval.process(workItem);
    
                    if(result.isSuccess()) {
                        String actionResult = requestBody.action == 'Approve' ? 'Approved' : 'Rejected';
                        responseBody.status = actionResult;
                        responseBody.message = GLIP_SUCCESS_MSG + actionResult;
                    } else {
                        responseBody.status = STATUS_FAILED;
                        responseBody.message = GLIP_ERROR_MSG + result.getInstanceStatus();
                    }
                } else {
                    responseBody.status = STATUS_UNAUTHORIZED;
                    responseBody.message = INVALID_APPROVER;
                }
            } else {
                responseBody.status = STATUS_PROCESSED;
                responseBody.message = REQUEST_ALREADY_HANDLED_MSG;
            }
        } catch (IllegalArgumentException illex) {
            responseBody.status = STATUS_FAILED;
			responseBody.message = illex.getMessage();
        } catch (Exception ex) {
        	responseBody.status = STATUS_FAILED;
			responseBody.message = GLIP_ERROR_MSG + ex.getMessage();
        }
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = blob.valueOf(JSON.serialize(responseBody));
        if (responseBody.message.contains(GLIP_ERROR_MSG.trim())) {
            response.statusCode = 500;
        }
	}
}