public with sharing class CaseReopenAPIController {

    public static final String SUCCESS_MESSAGE_POST = 'Case has been reopened successfully.';
    public static final String BAD_REQUEST_REQUIRED_PARAMETER_MISSING = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': function, uid, email and caseId are required parameters.';
    public static final String BAD_REQUEST_CASE_NOT_FOUND = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': No case was found using the caseId parameter.';
    public static final String BAD_REQUEST_JUSTIFICATION_PARAMETER = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': '+ ReopenCaseController.INVALID_JUSTIFICATION_LENGTH;

    public static Map<String, Object> reopenCase(String request) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            Map<String, Object> req = CaseAPIUtil.deserializeRequest(request);

            validate(req);

            String caseId = (String) req.get('caseId');

            Case caseToReopen = getCaseToReopen(caseId);
            
            validateIfCaseCanBeReopened(caseToReopen);

            String uid = (String) req.get('uid');
            String email = (String) req.get('email');
            String justification = (String) req.get('justification');
            String function = (String) req.get('function');

            Contact contact = CaseAPIUtil.getContact(uid, email);

            String body = function + '\n\n' + justification;
            String formattedComment = CaseDetailAPIController.getSerializedComment(uid, email, body, contact);

            SCAPICaseService.addCommentFromAPIWithContact(caseId, formattedComment, contact);

            updateStatusToReopen(caseToReopen);

            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, SUCCESS_MESSAGE_POST);
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
        } catch (Exception e) {
            return CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }
        return res;
    }

    public static void updateStatusToReopen(Case caseToUpdate) {
        caseToUpdate.Status = CaseHelper.CASE_STATUS_REOPENED;
        update caseToUpdate;
    }
    
    public static void validate(Map<String,Object> req) {
        String function = StringHelper.safeString(((String) req.get('function'))?.trim());
        String justification = StringHelper.safeString(((String) req.get('justification'))?.trim());
        String uid = (String) req.get('uid');
        String email = (String) req.get('email');
        String caseId = (String) req.get('caseId');

        if (CaseAPIUtil.hasBlankString(new String[]{function, uid, email, caseId})) {
            throw new HandledException(BAD_REQUEST_REQUIRED_PARAMETER_MISSING);
        }

        if (!ReopenCaseController.isJustificationFieldValid(function, justification)) {
            throw new HandledException(BAD_REQUEST_JUSTIFICATION_PARAMETER);
        }

        try {
            ReopenCaseController.validateFunction(function);
        } catch (Exception e) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': ' + e.getMessage());
        }
    }

    private static Case getCaseToReopen(String caseId) {
        Case caseToReopen; 
        try {
            caseToReopen = (Case) new CaseSelector()
                .selectCaseForReopening(new Object[]{caseId})
                .setLimit(1)
                .executeQuery()[0];
        } catch(Exception e) {
            throw new HandledException(BAD_REQUEST_CASE_NOT_FOUND);
        }
        return caseToReopen;
    }

    private static void validateIfCaseCanBeReopened(Case cs) {
        String cannotBeReopenedReason = CaseHelper.getReopenErrorMessage(cs);
        if (cannotBeReopenedReason != null) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': ' + cannotBeReopenedReason);
        }
    }
}