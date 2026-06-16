@RestResource(urlMapping='/SCApi/v1/caseDetail/*')
global class CaseDetailRestService {

    public static final String BAD_REQUEST = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': caseId, uid and email are required.';
    public static final String BAD_REQUEST_POST = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': caseId, comment, uid or email are required.';
    public static final String DEFAULT_LANG = 'en_US';

    @HttpGet
    global static void getCaseInfo() {
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);
        try {
            validateGetRequest(res, RestContext.request.params);

            SCWrappers.GetCaseDetailRequest caseDetailRequest = getCaseDetailRequest(RestContext.request.params);
            
            Map<String,Object> response = CaseDetailAPIController.getCaseDetail(JSON.serialize(caseDetailRequest));
            res.responseBody = Blob.valueOf(JSON.serialize(response));

            CaseAPIUtil.validateMessageField(res, response, CaseDetailAPIController.SUCCESS_MESSAGE);
        } catch(Exception e) {
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
        
    }

    @HttpPost
    global static void postComment() {
        RestRequest request = RestContext.request;
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);
        try {
            SCWrappers.CasePostComment comment = deserializeCasePostComment(request.requestBody.toString());

            validatePostRequest(res, comment);

            Map<String,Object> response = CaseDetailAPIController.postComment(JSON.serialize(comment));

            res.responseBody = Blob.valueOf(JSON.serialize(response));

            CaseAPIUtil.validateMessageField(res, response, CaseDetailAPIController.SUCCESS_MESSAGE_POST);
        } catch(Exception e) {
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
    }

    private static SCWrappers.GetCaseDetailRequest getCaseDetailRequest(Map<String, String> req) {
        SCWrappers.GetCaseDetailRequest request = new SCWrappers.GetCaseDetailRequest();
        request.caseId = req.get('caseId');
        request.email = req.get('email');
        request.uid = req.get('uid');
        request.lang = req.containsKey('lang') ? req.get('lang') : DEFAULT_LANG;
        return request;
    }

    private static SCWrappers.CasePostComment deserializeCasePostComment(String postCommentString) {
        return (SCWrappers.CasePostComment) JSON.deserialize(postCommentString, SCWrappers.CasePostComment.class);
    }

    private static void validateGetRequest(RestResponse res, Map<String, String> req) {
        String caseId = StringHelper.safeString(req.get('caseId'));
        String uid = StringHelper.safeString(req.get('uid'));
        String email = StringHelper.safeString(req.get('email'));
        String lang = StringHelper.safeString(req.get('lang'));

        if (CaseAPIUtil.hasBlankString(new String[]{caseId, uid, email})) {
            CaseAPIUtil.throwException(res, BAD_REQUEST);
        }

        if (String.isNotBlank(lang) && !CaseHelper.isValidLanguage(lang.toLowerCase())) {
            CaseAPIUtil.throwException(res, CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid lang parameter value.');
        }
    }
    
    private static void validatePostRequest(RestResponse res, SCWrappers.CasePostComment comment) {
        if (CaseAPIUtil.hasBlankString(new String[]{comment.caseId, comment.uid, comment.email, comment.comment})) {
            CaseAPIUtil.throwException(res, BAD_REQUEST_POST);
        }
    }
}