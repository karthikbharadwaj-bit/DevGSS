@RestResource(urlMapping='/SCApi/v1/caseEscalate/*')
global class CaseEscalateRestService {

    @HttpPost
    global static void escalateCase() {
        RestRequest request = RestContext.request;
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);
        try {    
            Map<String,Object> response = CaseEscalateAPIController.escalateCase(request.requestBody.toString());
            
            res.responseBody = Blob.valueOf(JSON.serialize(response));

            CaseAPIUtil.validateMessageField(res, response, CaseEscalateAPIController.SUCCESS_MESSAGE_POST);
        } catch (Exception e) {
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
    }
}