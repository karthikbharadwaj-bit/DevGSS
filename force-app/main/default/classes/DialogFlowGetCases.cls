@RestResource(urlMapping='/getCases')
global with sharing class DialogFlowGetCases {
    
    private static final Set<String> REQUIRED_PARAMS = new Set<String>{
        'salesforceUserId'
    };
    
    private static final Integer DEFAULT_LIMIT = 5;

    @HttpPost 
    global static void getCases() {
        try {
            // Parse request
            RestRequest req = RestContext.request;
            Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            
            // Extract parameters
            Map<String, String> params = new Map<String, String>{
                'salesforceUserId' => (String)bodyMap.get('salesforceUserId')
            };
            
            // Validate required parameters
            DialogflowResponseHandler.validateRequiredParams(params, REQUIRED_PARAMS);
            
            // Get cases using selector
            List<Case> cases = CaseSelectorDialogflow.getInstance()
                .getCasesByOwnerId(params.get('salesforceUserId'), DEFAULT_LIMIT);
            
            // Convert to wrappers
            List<DialogflowWrapper.CaseWrapper> responseList = DialogflowWrapper.wrapCases(cases);
            
            // Send success response
            DialogflowResponseHandler.sendSuccess(
                'Cases retrieved successfully',
                responseList
            );
            
        } catch (Exception e) {
            DialogflowResponseHandler.handleException(e);
        }
    }
}