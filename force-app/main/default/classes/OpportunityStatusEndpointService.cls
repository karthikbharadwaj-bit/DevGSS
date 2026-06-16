@RestResource(UrlMapping='/rccc/nic/opportunity/find')
global with sharing class OpportunityStatusEndpointService {
    @HttpPost
    global static void getByOppId() {
        OpportunityStatusEndpointHelper.OpportunityParamsResponse result = new OpportunityStatusEndpointHelper.OpportunityParamsResponse();
        List<OpportunityStatusEndpointHelper.OpportunitiesParams> opportunityParamsList = new List<OpportunityStatusEndpointHelper.OpportunitiesParams>();
        List<OpportunityStatusEndpointHelper.Messages> messagesNotFoundId = new List<OpportunityStatusEndpointHelper.Messages>();
        try {
            String body = RestContext.request.requestBody.toString();
            if (RestContext.response == null) {
                RestContext.response = new RestResponse();
            }
            OpportunityStatusEndpointHelper.IcbStatusRequest params = (OpportunityStatusEndpointHelper.IcbStatusRequest)
                JSON.deserialize(body,  OpportunityStatusEndpointHelper.IcbStatusRequest.class);

            OpportunityStatusEndpointHelper.Messages errorMessages = validateRequest(params);
            if (errorMessages != null) {
                OpportunityStatusEndpointHelper.handleError(OpportunityStatusEndpointHelper.STATUS_ERROR, errorMessages, opportunityParamsList);
                return;
            }
            result = getResult(params.opportunityIds, opportunityParamsList, messagesNotFoundId);
            OpportunityStatusEndpointHelper.setSuccessResponse(result);
        } catch (JSONException e) {
            IcbHelper.handleError(e);

        } catch (Exception e) {
            messagesNotFoundId.add(OpportunityStatusEndpointHelper.createErrorList(e.getMessage(), e.getStackTraceString()));
            OpportunityStatusEndpointHelper.handleError(OpportunityStatusEndpointHelper.STATUS_ERROR, messagesNotFoundId, opportunityParamsList);
        }
    }
    private static OpportunityStatusEndpointHelper.Messages validateRequest(OpportunityStatusEndpointHelper.IcbStatusRequest statusRequest) {
        if (statusRequest.opportunityIds == null || statusRequest.opportunityIds.isEmpty()) {
            return OpportunityStatusEndpointHelper.createErrorList(
                OpportunityStatusEndpointHelper.EMPTY_REQUEST,
                OpportunityStatusEndpointHelper.EMPTY_REQUEST_DETAILS
            );
        }
        return null;
    }
    private static OpportunityStatusEndpointHelper.OpportunityParamsResponse getResult(
        List<String> requestedOppIds,
        List<OpportunityStatusEndpointHelper.OpportunitiesParams> opportunityParamsList,
        List<OpportunityStatusEndpointHelper.Messages> messagesNotFoundId
    ) {
        OpportunityStatusEndpointHelper.OpportunityParamsResponse res = new OpportunityStatusEndpointHelper.OpportunityParamsResponse();

        Map<Id, Quote> oppIdToRcccQuote = new Map<Id, Quote>();
        Set<String> oppIdSet = new Set<String>(requestedOppIds);

        Map<Id, Opportunity> oppIdToOpp = new Map<Id, Opportunity>((List<Opportunity>) new OpportunitySelector()
            .selectOpportunityForSyncStatus(oppIdSet)
            .executeQuery()
        );

        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotesForEndpointStatusServiceByOppId(oppIdSet)
            .executeQuery();

        for (Quote qt : quotes) {
            if (!QuoteHelper.isRCCC(qt) || oppIdToRcccQuote.containsKey(qt.OpportunityId)) {
                continue;  
            }
            
            oppIdToRcccQuote.put(qt.OpportunityId, qt);
        }

        for (String strId : requestedOppIds) {
            Id opportunityIdFromStr = Id.valueOf(strId);

            if (!oppIdToOpp.containsKey(opportunityIdFromStr)) {
                messagesNotFoundId.add(OpportunityStatusEndpointHelper.createErrorList(
                    OpportunityStatusEndpointHelper.OPPORTUNITY_NOT_FOUND_DETAILS,
                    OpportunityStatusEndpointHelper.OPPORTUNITY_NOT_FOUND + strId
                ));
                continue;
            }

            OpportunityStatusEndpointHelper.OpportunitiesParams opportunityParams = new OpportunityStatusEndpointHelper.OpportunitiesParams();
            Quote qt = oppIdToRcccQuote.get(opportunityIdFromStr);
            Opportunity opp = oppIdToOpp.get(opportunityIdFromStr);

            opportunityParams.ngbsSyncStatus = qt != null ? SWNScenarioHelper.getRCCCSyncStatus(opp, qt) : null;
            opportunityParams.id = opp.Id;
            opportunityParamsList.add(opportunityParams);
        }
        res.data.opportunities = opportunityParamsList;
        res.messages = messagesNotFoundId;
        return res;
    }
}