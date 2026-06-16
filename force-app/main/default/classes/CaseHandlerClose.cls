public with sharing class CaseHandlerClose implements CaseHandlerStrategy.ICaseHandler {

    public static final String INVALID_ACTION =  'action value must be "close"';
    public static final String REQUIRED_VALUES = 'action, uid, email and caseId are required values';
    public static final String SUCCESS_MESSAGE = 'The case was successfully closed.';
    public static final String ALREADY_CLOSED =  'The Case is already closed';
    public static final String STATUS_CLOSED_BY_CUSTOMER = CaseHelper.CASE_STATUS_CLOSED;

    public void validate(Map<String,Object> req) {
        String action = StringHelper.safeString(req.get('action'));
        String uid = StringHelper.safeString(req.get('uid'));
        String email = StringHelper.safeString(req.get('email'));
        String caseId = StringHelper.safeString(req.get('caseId'));

        if (CaseAPIUtil.hasBlankString(new String[]{action, uid, email, caseId})) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': ' + REQUIRED_VALUES);
        }

        if (action.toLowerCase() != 'close') {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': ' + INVALID_ACTION);
        }

    }

    public Map<String,Object> execute(Map<String,Object> req) {
        Map<String,Object> response = new Map<String,Object>();

        String uid = StringHelper.safeString(req.get('uid'));
        String email = StringHelper.safeString(req.get('email'));
        String caseId = StringHelper.safeString(req.get('caseId'));

        Case aCase = CaseHandlerStrategy.getCase(email, uid, caseId);
    
        if (aCase.IsClosed) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': ' + ALREADY_CLOSED);
        }

        aCase.Status = STATUS_CLOSED_BY_CUSTOMER;
        update aCase;

        response.put(CaseAPIUtil.MESSAGE_FIELD_NAME, SUCCESS_MESSAGE);
        response.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
        return response;
    }
}