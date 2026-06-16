public class SWNEngageAccountTerminationRunner extends SWNActionRunner {
    private static final String ID_PARAM = 'id';
    private static final String NAME_PARAM = 'name';

    class EngageAccountRequestParams {
        public String opportunityId;
        public String ngbsPackageId;
        public Map<String, String> salesAgentInfo;

        public EngageAccountRequestParams(Id oppId, String ngbsPackageId) {
            this.opportunityId = oppId;
            this.ngbsPackageId = ngbsPackageId;
            this.salesAgentInfo = new Map<String, String> {
                ID_PARAM => UserInfo.getUserId(),
                NAME_PARAM => UserInfo.getUserName()
            };
        }
    }

    @TestVisible
    private SWNEngageAccountTerminationRunner() {}

    public SWNEngageAccountTerminationRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    protected override void run() {
        terminateAccount();
    }

    @TestVisible
    private void terminateAccount() {
        Response terminationResp = accountTermination(sdc.opp, sdc.ngbsPackage?.id);
        if (!terminationResp.isSuccess()) {
            sdc.currentStep.isStepCompletedSuccessfully = false;
        }

        res.messages.addAll(terminationResp.messages);
    }

    private Response accountTermination(Opportunity opp, String ngbsPackageId) {
        Response resp = new Response();
        HttpResponse httpResp = processAccountTermination(opp, ngbsPackageId);

        return HttpHelper.isSuccess(httpResp)
            ? handleSuccess(resp)
            : handleError(resp, httpResp, opp.Account.RC_User_ID__c);
    }

    @TestVisible
    private Response handleError(Response resp, HttpResponse httpResp, String rcUserId) {
        try {
            String errorMessage = parseErrorMessage(httpResp.getBody());
            resp.error(Label.Account_Termination_request_failed, errorMessage);
        } catch (Exception e) {
            handleExceptionError(httpResp, rcUserId);
        }
        return resp;
    }

    @TestVisible
    private String parseErrorMessage(String body) {
        BillingWrappers.EngageCCBTerminationResponseParams responseParams = (BillingWrappers.EngageCCBTerminationResponseParams) JSON.deserialize(body, BillingWrappers.EngageCCBTerminationResponseParams.class);
        Set<String> errorMessages = new Set<String>();

        for (BillingWrappers.EngageTerminationMessages mes : responseParams.messages) {
            errorMessages.add(mes.message);
        }
        errorMessages.remove(null);
        return String.join(errorMessages, '\n');
    }

    @TestVisible
    private void handleExceptionError(HttpResponse httpResp, String rcUserId) {
        String errorMessage = '';

        if (httpResp.getStatus() != null) {
            errorMessage += httpResp.getStatus() + '. Please Contact Your Administrator.';
        }

        if (httpResp.getBody() != null) {
            errorMessage += '\nTechnical Details: ' + httpResp.getBody() + '.';
        }

        errorMessage += '\nRequest endpoint: ' + buildEndpoint(rcUserId);
        throw new AquivaHelper.AquivaException(CCBAPI.REQUEST_CCB_EXCEPTION_MESSAGE + errorMessage);
    }

    @TestVisible
    private Response handleSuccess(Response resp) {
        resp.addMessage(SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.ACCOUNT_TERMINATION_SUCCESS));
        return resp;
    }

    private HttpResponse processAccountTermination(Opportunity opp, String ngbsPackageId) {
        EngageAccountRequestParams params = new EngageAccountRequestParams(opp.Id, ngbsPackageId);
        String endpoint = buildEndpoint(opp.Account.RC_User_ID__c);

        return CCBAPI.requestCCB(endpoint, HttpHelper.METHOD_PUT, JSON.serialize(params));
    }

    @TestVisible
    private String buildEndpoint(String rcUserId) {
        String baseEndpoint = POHelper.isEngageUILessSettingsOn
            ? CCBAPI.CCB_SETTINGS.DirectBaseEndpoint__c + CCBAPI.CCB_SETTINGS.APIVersion2Path__c
            : CCBAPI.CCB_SETTINGS.BaseEndpoint__c;
        return baseEndpoint + CCBAPI.CCB_SETTINGS.TerminationPath__c + '/' + rcUserId;
    }
}