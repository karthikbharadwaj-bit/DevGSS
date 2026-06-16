@RestResource(urlMapping='/SCApi/v1/caseHandler/*')
global with sharing class CaseHandlerRestService {
    @HttpPost
    global static void caseHandler() {
        RestRequest request = RestContext.request;
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);
        try {    
            Map<String,Object> response = CaseHandlerAPIController.caseHandler(request.requestBody.toString());
            
            res.responseBody = Blob.valueOf(JSON.serialize(response));

            CaseAPIUtil.validateSuccessField(res, response);
        } catch (Exception e) {
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
    }
}