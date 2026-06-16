@RestResource(urlMapping='/SCApi/v1/case-new/*')
global class CaseCreateRestService {
    @HttpGet
    global static void getCaseAreaPicklistHierarchy() {
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);
        try {
            Map<String,Object> response = CaseCreateAPIController.retrieveCaseAreaPicklistHierarchy(JSON.serialize(RestContext.request.params));
            
            res.responseBody = Blob.valueOf(JSON.serialize(response));
            CaseAPIUtil.validateMessageField(res, response, CaseCreateAPIController.MESSAGE_PICKLIST_VALUES_PROVIDED);
        } catch(Exception e) {
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);   
        }
    }

    @HttpPost
    global static void createCase() {
        RestRequest request = RestContext.request;
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);
        try {    
            Map<String,Object> response = CaseCreateAPIController.createCase(request.requestBody.toString());
            
            res.responseBody = Blob.valueOf(JSON.serialize(response));

            CaseAPIUtil.validateMessageField(res, response, CaseCreateAPIController.SUCCESS_MESSAGE_POST);
        } catch (Exception e) {
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
    }
    
}