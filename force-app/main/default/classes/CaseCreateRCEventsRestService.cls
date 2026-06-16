@RestResource(urlMapping='/SCApi/v1/case-events-new/*')
global with sharing class CaseCreateRCEventsRestService {

    @HttpPost
    global static void createCase() {
        RestRequest request = RestContext.request;
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);
        try {    
            Map<String, Object> requestMap = CaseAPIUtil.deserializeRequest(request.requestBody.toString());
            requestMap.put('isRingCentralOpenEventsAccount', true);
            
            Map<String,Object> response = CaseCreateAPIController.createCase(JSON.serialize(requestMap));
            
            res.responseBody = Blob.valueOf(JSON.serialize(response));

            CaseAPIUtil.validateMessageField(res, response, CaseCreateAPIController.SUCCESS_MESSAGE_POST);
        } catch (Exception e) {
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
    }
}