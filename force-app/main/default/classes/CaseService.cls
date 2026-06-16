@RestResource(urlMapping='/CaseService/*')
global without sharing class CaseService{

    @HttpPost
    global static void handleRequest() {
        String result = '';
        String body = RestContext.request.requestBody.toString();
        BillingWrappers.CaseCreateParams params = (BillingWrappers.CaseCreateParams)JSON.deserialize(body, BillingWrappers.CaseCreateParams.class);
        RestResponse response = RestContext.response;
        if (response == null) {
            response = new RestResponse();
            RestContext.response = response;
        }
        try {
            if (params.action == 'getProServCases') {
                response.responseBody = Blob.valueOf(JSON.serialize(getProServCases(params)));
            } else {
                response.responseBody = Blob.valueOf(JSON.serialize(createCase(params)));
            }
        } catch(Exception e) {
            Map<String,String> errorMessage = new Map<String,String>();
            errorMessage.put('error', e.getMessage());
            errorMessage.put('stackTrace', e.getStackTraceString());
            response.responseBody = Blob.valueOf(JSON.serialize(errorMessage));
        }
    }

    @TestVisible
    private static Response createCase(BillingWrappers.CaseCreateParams params) {
        Response resp = new Response();
        Map<SObjectField, Object> fieldsMap = CaseHelper.prepareCaseFields(params);
        Case newCase = CaseHelper.buildCase(fieldsMap);
        Case createdCase = (Case) new CaseSelector()
            .selectCasesByIds(new Set<Id>{newCase.Id})
            .executeQuery()
            .get(0);
        CaseHelper.sendProServCaseEmail(createdCase);
        resp.setData('CaseId', createdCase.Id);
        resp.setData('CaseNumber', createdCase.CaseNumber);
        return resp;
    }

    @TestVisible
    private static Response getProServCases(BillingWrappers.CaseCreateParams params) {
        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCaseByOpportunityAndQuoteAndRecordTypeName(
                new List<Object>{
                    params.opportunityId, params.quoteApprovalId, CaseHelper.RT_NAME_PROFESSIONAL_SERVICES
                })
            .executeQuery();
        Case latestUCCase;
        Case latestCCCase;
        Case latestUcCancelationCase;
        Case latestCcCancelationCase;
        Boolean isProservCancelationFlow = false;

        for (Case cs : cases) {
            Boolean isCaseUc = CaseHelper.isUcProServCase(cs);
            Boolean isCaseCc = CaseHelper.isCcProServCase(cs);
            Boolean isUcCancelationCase = cs.Subject.toLowerCase().contains('UC ProServ cancellation for'.toLowerCase());
            Boolean isCcCancelationCase = cs.Subject.toLowerCase().contains('CC ProServ cancellation for'.toLowerCase());
            if (isCaseUc && latestUCCase == null) {
                latestUCCase = cs;
            }
            if (isCaseCc && latestCCCase == null) {
                latestCCCase = cs;
            }
            if (isUcCancelationCase && latestUcCancelationCase == null) {
                latestUcCancelationCase = cs;
            }
            if (isCcCancelationCase && latestCcCancelationCase == null) {
                latestCcCancelationCase = cs;
            }
        }

        if (latestUcCancelationCase?.CreatedDate > latestUCCase?.CreatedDate || latestCcCancelationCase?.CreatedDate > latestCCCase?.CreatedDate) {
            isProservCancelationFlow = true;
        }

        Response resp = new Response();
        resp.setData('latestUCCase', latestUCCase);
        resp.setData('latestCCCase', latestCCCase);
        resp.setData('latestUCCancelationCase', latestUcCancelationCase);
        resp.setData('latestCCCancelationCase', latestCcCancelationCase);
        resp.setData('isProservCancelationFlow', isProservCancelationFlow);
        return resp;
    }

}