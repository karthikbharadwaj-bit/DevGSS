@RestResource(urlMapping='/getCasesDetails')
global with sharing class DialogFlowGetCaseDetails {
    
    private static final Set<String> REQUIRED_PARAMS = new Set<String>{
        'salesforceUserId',
        'caseNumber'
    };
    
    @HttpPost
    global static void getCaseDetailsByNumber() {
        try {
            // Parse request
            RestRequest req = RestContext.request;
            Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            
            // Extract parameters
            Map<String, String> params = new Map<String, String>{
                'salesforceUserId' => (String)bodyMap.get('salesforceUserId'),
                'caseNumber' => String.valueOf(bodyMap.get('caseNumber'))
            };
            
            // Validate required parameters
            DialogflowResponseHandler.validateRequiredParams(params, REQUIRED_PARAMS);
            
            // Get case using selector
            Case caseRecord = CaseSelectorDialogflow.getInstance().getCaseByCaseNumber(params.get('caseNumber'));
            if (caseRecord == null) {
                throw new DialogflowResponseHandler.DialogflowException('Case not found with number: ' + params.get('caseNumber'));
            }
            
            // Check access using selector
            if (!UserSelectorDialogflow.getInstance().hasReadAccess(params.get('salesforceUserId'), caseRecord.Id)) {
                throw new DialogflowResponseHandler.DialogflowException('User does not have access to this case');
            }
            
            // Send success response
            DialogflowResponseHandler.sendSuccess(
                'Case details retrieved successfully',
                new DialogflowWrapper.CaseWrapper(caseRecord)
            );
            
        } catch (Exception e) {
            DialogflowResponseHandler.handleException(e);
        }
    }
}