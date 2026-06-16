@RestResource(urlMapping='/SCApi/v1/caseInfo/*')
global class CaseInfoRestService {

    public static final String BAD_REQUEST = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': uid and email are required parameters';
    public static final String BAD_REQUEST_POST = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': uid, email, firstNamne, lastName, contactEmail and phone are required parameters';
    public static final String BAD_REQUEST_POST_WO_PHONE = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': uid, email, firstNamne, lastName and contactEmail are required parameters';

    @HttpGet
    global static void getContactInfo() {
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);

        try {
            String uid = RestContext.request.params.get('uid');
            String email = RestContext.request.params.get('email');
            
            validateGetRequest(res, uid, email);

            SCWrappers.ContactInfoAPIRequest request = getContactInfoAPIRequest(email, uid);

            Map<String,Object> response = CaseInfoAPIController.getContactInfo(JSON.serialize(request));
            res.responseBody = Blob.valueOf(JSON.serialize(response));

            CaseAPIUtil.validateMessageField(res, response, CaseInfoAPIController.SUCCESS_MESSAGE);
        }
        catch(Exception e){
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
    }

    @HttpPost
    global static void postContactInfo() {
        RestRequest request = RestContext.request;
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);
        try{
            SCWrappers.ContactInfoAPIPostRequest reqWrapper = deserializeContactInfoPostRequest(request.requestBody.toString());

            validatePostRequest(res, reqWrapper);

            Map<String,Object> response = CaseInfoAPIController.upsertRelatedUser(JSON.serialize(reqWrapper));
            res.responseBody = Blob.valueOf(JSON.serialize(response));

            CaseAPIUtil.validateMessageField(res, response, CaseInfoAPIController.SUCCESS_MESSAGE_POST);
        }
        catch(Exception e){
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
    }

    private static SCWrappers.ContactInfoAPIRequest getContactInfoAPIRequest(String email, String uid) {
        SCWrappers.ContactInfoAPIRequest request = new SCWrappers.ContactInfoAPIRequest();
        request.email = email;
        request.uid = uid;
        return request;
    }

    private static SCWrappers.ContactInfoAPIPostRequest deserializeContactInfoPostRequest(String postRequestString) {
        return (SCWrappers.ContactInfoAPIPostRequest) JSON.deserialize(postRequestString, SCWrappers.ContactInfoAPIPostRequest.class);
    }

    private static void validatePostRequest(RestResponse res, SCWrappers.ContactInfoAPIPostRequest request) {
        List<String> excludedUserIds = new List<String>();
        for (Bypass_Phone_Number_Required_Validation__mdt bypassPhoneMdt : [SELECT User_Id__c FROM Bypass_Phone_Number_Required_Validation__mdt]) {
            excludedUserIds.add(bypassPhoneMdt.User_Id__c);
        }
        Boolean isExcludedUserForPhone = excludedUserIds.size() > 0 && excludedUserIds.contains(UserInfo.getUserId());
        if (CaseAPIUtil.hasBlankString(new String[]{
            request.uid, request.email, request.firstName, request.lastName, request.contactEmail}) 
            || (!isExcludedUserForPhone && CaseAPIUtil.hasBlankString(new String[]{request.phone}))) {
            CaseAPIUtil.throwException(res, isExcludedUserForPhone ? BAD_REQUEST_POST_WO_PHONE : BAD_REQUEST_POST);
        }
        
        if(isExcludedUserForPhone && request.phone == 'null') {
            request.phone = '';
        }
    }
    
    private static void validateGetRequest(RestResponse res, String uid, String email) {
        if (CaseAPIUtil.hasBlankString(new String[]{uid, email})) {
            CaseAPIUtil.throwException(res, BAD_REQUEST);
        }
    }
}