public with sharing class CaseEscalateAPIController {

    public static final String SUCCESS_MESSAGE_POST = 'Case has been escalated succesfully.';
    public static final String BAD_REQUEST_REQUIRED_PARAMETER_MISSING = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Justification, uid, email and caseId are required parameters.';
    public static final String BAD_REQUEST_INVALID_CASEID = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': No case was found using the caseId parameter.';    

    public static Map<String, Object> escalateCase(String request) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            Map<String, Object> req = CaseAPIUtil.deserializeRequest(request);

            validateEscalateCaseRequest(req);

            String caseId = (String) req.get('caseId');

            Case caseToEscalate = getCaseToEscalate(caseId);

            validateIfCaseCanBeEscalated(caseToEscalate);

            String uid = (String) req.get('uid');
            String email = (String) req.get('email');
            String justification = ((String) req.get('justification')).trim();

            Contact contact = CaseAPIUtil.getContact(uid, email);

            insertCaseComment(justification.trim(), caseId);
            updateIsEscalatedFieldCase(caseToEscalate);
            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, SUCCESS_MESSAGE_POST);
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
        } catch (Exception e) {
            CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }
        return res;
    }

    private static void insertCaseComment(String body, String caseId) {
        insert new CaseComment(
            CommentBody = body,
            ParentId = caseId,
            isPublished = true
        );
    }

    private static void updateIsEscalatedFieldCase(Case caseToUpdate) {
        caseToUpdate.IsEscalated = true;
        update caseToUpdate;
    }
    
    private static void validateEscalateCaseRequest(Map<String,Object> req) {
        String justification = ((String) req.get('justification'))?.trim();
        String uid = (String) req.get('uid');
        String email = (String) req.get('email');
        String caseId = (String) req.get('caseId');

        if (CaseAPIUtil.hasBlankString(new String[]{justification, uid, email, caseId})) {
            throw new HandledException(BAD_REQUEST_REQUIRED_PARAMETER_MISSING);
        }

        try {
            EscalateCaseController.validateJustification(justification);
        } catch(Exception e) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + e.getMessage());
        }
    }

    private static Case getCaseToEscalate(String caseId) {
        Case caseToEscalate; 
        try {
            caseToEscalate = (Case) new CaseSelector()
                .selectCaseForEscalating(new Object[]{caseId})
                .setLimit(1)
                .executeQuery()[0];
        } catch(Exception e) {
            throw new HandledException(BAD_REQUEST_INVALID_CASEID);
        }
        return caseToEscalate;
    }

    private static void validateIfCaseCanBeEscalated(Case cs) {
        if (!CaseHelper.isEscalatable(cs)) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': ' + CaseHelper.getEscalateErrorMessage(cs));
        }
    }
}