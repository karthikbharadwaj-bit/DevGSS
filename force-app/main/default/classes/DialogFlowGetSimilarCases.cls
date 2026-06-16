@RestResource(urlMapping='/getSimilarCases')
global with sharing class DialogFlowGetSimilarCases {
    
    private static final Set<String> REQUIRED_PARAMS = new Set<String>{
        'salesforceUserId',
        'subject'
    };
    
    private static final Integer DEFAULT_LIMIT = 5;
    
    @HttpPost
    global static void getCaseDetailsBySubject() {
        try {
            // Parse request
            RestRequest req = RestContext.request;
            Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            
            // Extract parameters
            Map<String, String> params = new Map<String, String>{
                'salesforceUserId' => (String)bodyMap.get('salesforceUserId'),
                'subject' => (String)bodyMap.get('subject')
            };
            
            // Validate required parameters
            DialogflowResponseHandler.validateRequiredParams(params, REQUIRED_PARAMS);
            
            // Get similar cases using selector
            List<Case> cases = CaseSelectorDialogflow.getInstance()
                .getSimilarCasesBySubject(params.get('subject'), DEFAULT_LIMIT);
            
            // Filter cases by subject or description
            List<Case> filteredCases = CaseSelectorDialogflow.getInstance()
                .getFilteredCases(params.get('subject'), cases);
            
            // Check case access
            Set<Id> caseIds = new Set<Id>();
            for (Case c : filteredCases) {
                caseIds.add(c.Id);
            }
            
            Map<Id, UserRecordAccess> accessMap = CaseSelectorDialogflow.getInstance()
                .getCaseAccessByUser(params.get('salesforceUserId'), caseIds);
            
            // Filter cases based on access and convert to wrappers
            List<DialogflowWrapper.CaseWrapper> responseList = new List<DialogflowWrapper.CaseWrapper>();
            for (Case c : filteredCases) {
                if (accessMap.containsKey(c.Id) && accessMap.get(c.Id).HasReadAccess) {
                    responseList.add(new DialogflowWrapper.CaseWrapper(c));
                }
            }
            
            // Send success response
            DialogflowResponseHandler.sendSuccess(
                'Similar cases retrieved successfully',
                responseList
            );
            
        } catch (Exception e) {
            DialogflowResponseHandler.handleException(e);
        }
    }
}