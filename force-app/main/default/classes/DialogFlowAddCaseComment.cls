@RestResource(urlMapping='/AddCaseCommenttoCaseNumber')
global with sharing class DialogFlowAddCaseComment {
    
    private static final Set<String> REQUIRED_PARAMS = new Set<String>{
        'salesforceUserId',
        'casenumber',
        'casecomments'
    };
    
    private static final String DEFAULT_COMMENTER = 'Support Agent';
    
    @HttpPut
    global static void AddCaseCommenttoCaseNumber() {
        try {
            // Parse request
            RestRequest req = RestContext.request;
            
            // Extract parameters
            Map<String, String> params = new Map<String, String>{
                'salesforceUserId' => req.params.get('salesforceUserId'),
                'casenumber' => req.params.get('casenumber'),
                'casecomments' => req.params.get('casecomments')
            };
            
            // Validate required parameters
            DialogflowResponseHandler.validateRequiredParams(params, REQUIRED_PARAMS);
            
            // Get case using selector
            Case caseRecord = CaseSelectorDialogflow.getInstance().getCaseByCaseNumber(params.get('casenumber'));
            if (caseRecord == null) {
                throw new DialogflowResponseHandler.DialogflowException('Case not found with number: ' + params.get('casenumber'));
            }
            
            // Get user using selector
            User userRecord = UserSelectorDialogflow.getInstance().getUserById(params.get('salesforceUserId'));
            if (userRecord == null) {
                throw new DialogflowResponseHandler.DialogflowException('User not found with ID: ' + params.get('salesforceUserId'));
            }
            
            // Check access using selector
            if (!UserSelectorDialogflow.getInstance().hasReadAccess(params.get('salesforceUserId'), caseRecord.Id)) {
                throw new DialogflowResponseHandler.DialogflowException('User does not have access to this case');
            }
            
            // Create and insert comment
            CaseComment newComment = createCaseComment(
                caseRecord.Id,
                formatCommentBody(userRecord.Name, params.get('casecomments'))
            );
            
            // Send success response
            DialogflowResponseHandler.sendSuccess(
                'Case comment added successfully',
                new DialogflowWrapper.CaseCommentWrapper(newComment, caseRecord)
            );
            
        } catch (Exception e) {
            DialogflowResponseHandler.handleException(e);
        }
    }
    
    private static String formatCommentBody(String userName, String comments) {
        return String.isNotBlank(userName) ? 
            userName + ' : ' + comments :
            DEFAULT_COMMENTER + ' : ' + comments;
    }
    
    private static CaseComment createCaseComment(Id caseId, String commentBody) {
        CaseComment newComment = new CaseComment(
            CommentBody = commentBody,
            ParentId = caseId,
            IsPublished = true
        );
        
        Database.SaveResult result = Database.insert(newComment, false);
        
        if (!result.isSuccess()) {
            throw new DialogflowResponseHandler.DialogflowException('Failed to add comment: ' + result.getErrors()[0].getMessage());
        }
        
        return newComment;
    }
}