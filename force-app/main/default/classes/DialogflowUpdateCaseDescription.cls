@RestResource(urlMapping='/updateCaseDescription')
global with sharing class DialogflowUpdateCaseDescription {
    
    private static final Set<String> REQUIRED_PARAMS = new Set<String>{
        'salesforceUserId',
        'casenumber',
        'caseDescription'
    };
    
    @HttpPut
    global static void updateDescription() {
        try {
            // Parse request
            RestRequest req = RestContext.request;
            
            // Extract parameters
            Map<String, String> params = new Map<String, String>{
                'salesforceUserId' => req.params.get('salesforceUserId'),
                'casenumber' => req.params.get('casenumber'),
                'caseDescription' => req.params.get('caseDescription')
            };
            
            // Validate required parameters
            DialogflowResponseHandler.validateRequiredParams(params, REQUIRED_PARAMS);
            
            // Get case using selector
            Case caseRecord = CaseSelectorDialogflow.getInstance().getCaseByCaseNumber(params.get('casenumber'));
            if (caseRecord == null) {
                throw new DialogflowResponseHandler.DialogflowException('Case not found with number: ' + params.get('casenumber'));
            }
            
            // Check access using selector
            if (!UserSelectorDialogflow.getInstance().hasEditAccess(params.get('salesforceUserId'), caseRecord.Id)) {
                throw new DialogflowResponseHandler.DialogflowException('User does not have edit access to this case');
            }
            
            // Update case description
            updateCaseDescription(caseRecord, params.get('caseDescription'));
            
            // Send success response
            DialogflowResponseHandler.sendSuccess(
                'Case description updated successfully',
                new DialogflowWrapper.CaseWrapper(caseRecord)
            );
            
        } catch (Exception e) {
            DialogflowResponseHandler.handleException(e);
        }
    }
    
    private static void updateCaseDescription(Case caseRecord, String description) {
        try {
            caseRecord.Description = description;
            
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