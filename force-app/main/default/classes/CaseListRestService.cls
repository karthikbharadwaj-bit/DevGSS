@RestResource(urlMapping='/SCApi/v1/case/*')
global class CaseListRestService {

    public static final String BAD_REQUEST_UID_AND_EMAIL_ARE_REQUIRED = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': uid and email are required parameters.';

    @HttpGet
    global static void getCaseList() {
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);

        try {
            SCWrappers.GetCaseListRequest request = getCaseListRequest(RestContext.request.params);

            Map<String, Object> response = CaseListAPIController.getCasesInfo(JSON.serialize(request));

            res.responseBody = Blob.valueOf(JSON.serialize(response));

            CaseAPIUtil.validateMessageField(res, response, CaseListAPIController.SUCCESS_MESSAGE);
        } catch (Exception e) {
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
    }

    public static SCWrappers.GetCaseListRequest getCaseListRequest(Map<String, String> requestParams) {
        SCWrappers.GetCaseListRequest request = new SCWrappers.GetCaseListRequest();
        request.email = RestContext.request.params.get('email');
        request.uid = RestContext.request.params.get('uid');
        request.subject = RestContext.request.params.get('subject');
        request.caseNumber = RestContext.request.params.get(CaseHelper.CASE_NUMBER);
        request.searchLimit = RestContext.request.params.get('searchLimit');
        request.contactName = RestContext.request.params.get('contactName');
        request.offset = RestContext.request.params.get('offset');
        request.sortBy = RestContext.request.params.get('sortBy');
        request.sortOrder = RestContext.request.params.get('sortOrder');
        request.view = RestContext.request.params.get('view');
        request.site = RestContext.request.params.get('site');
        request.lang = RestContext.request.params.get('lang');
        request.statusFilter = RestContext.request.params.get('statusFilter');
        return request;
    }
}