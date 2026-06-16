@RestResource(urlMapping='/SCApi/v1/caseReopen/*')
global class CaseReopenRestService {

    @HttpPost
    global static void reopenCase() {
        RestRequest request = RestContext.request;
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);
        try {    
            Map<String,Object> response = CaseReopenAPIController.reopenCase(request.requestBody.toString());
            
            res.responseBody = Blob.valueOf(JSON.serialize(response));

            CaseAPIUtil.validateMessageField(res, response, CaseReopenAPIController.SUCCESS_MESSAGE_POST);
        } catch (Exception e) {
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
    }
}