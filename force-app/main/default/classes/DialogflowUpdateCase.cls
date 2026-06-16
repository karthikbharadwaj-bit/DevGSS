@RestResource(urlMapping='/updateCases')
global with sharing class DialogflowUpdateCase {
    
    private static final Set<String> REQUIRED_PARAMS = new Set<String>{
        'salesforceUserId',
        'caseNumber',
        'priority'
    };
    
    private static final Set<String> VALID_PRIORITIES = new Set<String>{
        'High',
        'Medium',
        'Low'
    };
    
    @HttpPut
    global static void updateCasePriority() {
        try {
            // Parse request
            RestRequest req = RestContext.request;
            Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            
            // Extract and validate parameters
            Map<String, String> params = new Map<String, String>{
                'salesforceUserId' => (String)bodyMap.get('salesforceUserId'),
                'caseNumber' => String.valueOf(bodyMap.get('caseNumber')),
                'priority' => (String)bodyMap.get('priority')
            };
            
            // Validate required parameters
            DialogflowResponseHandler.validateRequiredParams(params, REQUIRED_PARAMS);
            validatePriorityValue(params.get('priority'));
            
            // Get case using selector
            Case caseRecord = CaseSelectorDialogflow.getInstance().getCaseByCaseNumber(params.get('caseNumber'));
            if (caseRecord == null) {
                throw new DialogflowResponseHandler.DialogflowException('Case not found with number: ' + params.get('caseNumber'));
            }
            
            // Get user using selector
            User userRecord = UserSelectorDialogflow.getInstance().getUserById(params.get('salesforceUserId'));
            if (userRecord == null) {
                throw new DialogflowResponseHandler.DialogflowException('User not found with ID: ' + params.get('salesforceUserId'));
            }
            
            // Check edit access using selector
            if (!UserSelectorDialogflow.getInstance().hasEditAccess(params.get('salesforceUserId'), caseRecord.Id)) {
                throw new DialogflowResponseHandler.DialogflowException('User does not have edit access to this case');
            }
            
            // Update case priority
            updateCaseWithPriority(caseRecord, params.get('priority'));
            
            // Send success response
            DialogflowResponseHandler.sendSuccess(
                'Case priority updated successfully',
                new DialogflowWrapper.CaseWrapper(caseRecord)
            );
            
        } catch (Exception e) {
            DialogflowResponseHandler.handleException(e);
        }
    }
    
    private static void validatePriorityValue(String priority) {
        if (!VALID_PRIORITIES.contains(priority)) {
            throw new DialogflowResponseHandler.DialogflowException(
                'Invalid priority value. Must be one of: ' + String.join(new List<String>(VALID_PRIORITIES), ', ')
            );
        }
    }
    
    private static void updateCaseWithPriority(Case caseRecord, String priority) {
        try {
            caseRecord.Priority = priority;
            
            // Disable triggers for the update
            Triggers.switchOff();
            
            Database.SaveResult result = Database.update(caseRecord, false);
            
            if (!result.isSuccess()) {
                throw new DialogflowResponseHandler.DialogflowException('Failed to update case: ' + result.getErrors()[0].getMessage());
            }
        } finally {
            // Ensure triggers are re-enabled
            Triggers.switchOn();
        }
    }
}