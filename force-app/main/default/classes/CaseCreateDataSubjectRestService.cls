@RestResource(UrlMapping='/SCApi/v1/case-dsr-new/*')
global class CaseCreateDataSubjectRestService {

    public static final String USER_ROLE_RINGCENTRAL_USER = 'RingCentral User';
    public static final String USER_ROLE_AUTHORIZED_AGENT = 'Authorized agent for Data Subject Requests';
    public static final String USER_ROLE_NOT_SURE = 'Not Sure';
    public static final String USER_ROLE_EMPLOYEE_OR_CONTRACTOR = 'RingCentral Employee or contractor (current or former)';
    public static final String USER_ROLE_JOB_APPLICANT = 'Job applicant';

    @HttpPost
    global static void createCase() {

        RestRequest request = RestContext.request;
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);
        try {

            // Logic depends on what role user have chosen during DSR form submission
            Map<String, Object> requestMap = CaseAPIUtil.deserializeRequest(request.requestBody.toString());
            requestMap.put('isDataSubjectRequest', true);

            String userRole = (String) requestMap.get('relation');
            String customerName = requestMap.get('firstName') + ' ' + requestMap.get('lastName');
            String email = StringHelper.safeString(requestMap.get('email'));

            Map<String, Object> response;
            if (USER_ROLE_RINGCENTRAL_USER == userRole
                || USER_ROLE_AUTHORIZED_AGENT == userRole
                || USER_ROLE_NOT_SURE == userRole
                || USER_ROLE_EMPLOYEE_OR_CONTRACTOR == userRole
                || USER_ROLE_JOB_APPLICANT == userRole){

                response = CaseCreateAPIController.createCase(JSON.serialize(requestMap));

                // Send email only if Case ID is present (indicates successful creation) and An email will be sent to the email address mentioned in the form.
                if (response.containsKey(CaseCreateAPIController.CASE_ID)) {
                CaseHelper.sendDSREmail(
                    (Id) response.get(CaseCreateAPIController.CASE_ID),
                        customerName,
                        email
                );
                }

                res.responseBody = Blob.valueOf(JSON.serialize(response));

                CaseAPIUtil.validateMessageField(res, response, CaseCreateAPIController.SUCCESS_MESSAGE_POST);
            }
        } catch (Exception e) {
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
    }
}