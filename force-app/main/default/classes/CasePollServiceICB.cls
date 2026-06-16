@RestResource(UrlMapping='/rccc/nic/case/find')
global with sharing class CasePollServiceICB {
    @HttpPost
    global static void getByCaseNumber() {
        try {
            String body = RestContext.request.requestBody.toString();

            if (RestContext.response == null) {
                RestContext.response = new RestResponse();
            }

            IcbHelper.IcbPollRequest params = (IcbHelper.IcbPollRequest)
                JSON.deserialize(body,  IcbHelper.IcbPollRequest.class);

            List<IcbHelper.IcbMessage> errorMessages = validateRequest(params);
            if (errorMessages != null) {
                IcbHelper.handleError(errorMessages);
                return;
            }

            List<Case> cases = (List<Case>) new CaseSelector()
                .selectCasesIcbByNumber(params.caseNumbers)
                .executeQuery();

            Map<Id, PartnerNetworkRecordConnection> pnrcMapToCaseRecordMap =
                PartnerNetworkConnectionHelper.getLocalRecordIdToPnrcMap(cases);

            List<IcbHelper.IcbCase> icbCases = new List<IcbHelper.IcbCase>();

            for(Case caseSObject : cases) {
                icbCases.add(
                    new IcbHelper.IcbCase(
                        caseSObject,
                        pnrcMapToCaseRecordMap.get(caseSObject.Id)
                    )
                );
            }

            IcbHelper.setResponse(icbCases, IcbHelper.STATUS_SUCCESS);

        } catch (JSONException e) {
            IcbHelper.handleError(e);

        } catch (Exception e) {
            IcbHelper.handleError(e);
        }
    }

    private static List<IcbHelper.IcbMessage> validateRequest(IcbHelper.IcbPollRequest pollRequest) {
        if (pollRequest.caseNumbers == null || pollRequest.caseNumbers.isEmpty()) {
            return IcbHelper.createErrorList(
                    IcbHelper.EMPTY_REQUEST,
                    IcbHelper.EMPTY_REQUEST_DETAILS
            );
        }
        return null;
    }
}