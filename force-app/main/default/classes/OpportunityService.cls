@RestResource(UrlMapping='/OpportunityService/*')
global with sharing class OpportunityService {
    global static final String ACTION_CREATE_OPPORTUNITY = 'createOpportunity';
    global static final String ACTION_CREATE_CHANGE_ORDER_OPPORTUNITY = 'createChangeOrderOpportunity';
    global static final String ACTION_CONFIRM_AND_CLOSE_OPPORTUNITY = 'confirmAndClose';
    global static final String ACTION_GET_DEAL_QUALIFICATION = 'getDealQualification';
    global static final String ACTION_SYNC_DEAL_QUALIFICATION = 'syncDealQualification';
    global static final String ACTION_UPDATE_DQ_STATUS = 'updateDqStatus';
    global static final String ACTION_SAVE_DEAL_QUALIFICATION = 'saveDealQualification';
    global static final String ACTION_GET_APPROVERS_FOR_DQ = 'getApproversForDq';
    global static final String ACTION_CREATE_DQ_APPROVER = 'createDqApprover';
    global static final String ACTION_REVISE_DQ = 'reviseDq';

    global static final String ACTION_CREATE_TECHNICAL_OPPORTUNITIES = 'createTechnicalOpportunities';
    global static final String ACTION_UPDATE_TECHNICAL_OPPORTUNITIES = 'updateTechnicalOpportunities';
    global static final String ACTION_GET_TECHNICAL_OPPORTUNITIES = 'getTechnicalOpportunities';

    global static final String REVISION_PENDING_STATUS = 'Revision Pending';
    global static final String PENDING_APPROVAL_STATUS = 'Pending Approval';

    @HttpPost
    global static void doPost() {
        String result = '';
        String requestBody = RestContext.request.requestBody.toString();
        BillingWrappers.OpportunityServiceParams paramsData = (BillingWrappers.OpportunityServiceParams) JSON.deserialize(requestBody, BillingWrappers.OpportunityServiceParams.class);
        RestResponse res = RestContext.response;
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }
        try {
            if (paramsData.action == ACTION_CREATE_OPPORTUNITY) {
                Opportunity oppty = paramsData.opportunityWrapper.createOpportunityRecord();
                paramsData.opportunityWrapper.updateContactRole();
                result = JSON.serializePretty(oppty);
            }

            if (paramsData.action == ACTION_CONFIRM_AND_CLOSE_OPPORTUNITY) {
                result = paramsData.opportunityWrapper.confirmAndClose();
            }

            if (paramsData.action == ACTION_GET_DEAL_QUALIFICATION) {
                BillingWrappers.DQParams dqParameters = paramsData.dealQualificationParams;
                result = DQServiceHelper.getDealQualificationJson(dqParameters.opportunityId);
            }

            if (paramsData.action == ACTION_SYNC_DEAL_QUALIFICATION) {
                BillingWrappers.DQParams dqParameters = paramsData.dealQualificationParams;
                result = DQServiceHelper.syncDealQualificationJson(dqParameters.quoteId, dqParameters.status, dqParameters.isPrmFlow);
            }

            if (paramsData.action == ACTION_UPDATE_DQ_STATUS) {
                BillingWrappers.DQParams dqParameters = paramsData.dealQualificationParams;
                result = DQServiceHelper.updateDQStatus(dqParameters);
            }

            if (paramsData.action == ACTION_SAVE_DEAL_QUALIFICATION) {
                BillingWrappers.DQParams dqParameters = paramsData.dealQualificationParams;
                result = DQServiceHelper.saveDqRecord(dqParameters);
            }

            if (paramsData.action == ACTION_GET_APPROVERS_FOR_DQ) {
                Id dqOrOppId = paramsData.dealQualificationParams.dqOrOppId;
                result = DQGoa.getApproversDataJSON(DQGoa.getApproversForDQ(dqOrOppId));
            }

            if (paramsData.action == ACTION_CREATE_DQ_APPROVER) {
                BillingWrappers.DQParams dqParameters = paramsData.dealQualificationParams;
                BillingWrappers.DealQualification dqRecord = dqParameters.dqRecord;
                result = DQServiceHelper.createDealQualificationApprover(dqRecord?.dqId, dqParameters.status);
            }

            if (paramsData.action == ACTION_REVISE_DQ) {
                BillingWrappers.DQParams dqParameters = paramsData.dealQualificationParams;
                BillingWrappers.DealQualification dqRecord = dqParameters.dqRecord;
                result = DQServiceHelper.reviseDealQualification(dqRecord.dqId, dqParameters.status);
            }

            if (paramsData.action == ACTION_CREATE_TECHNICAL_OPPORTUNITIES) {
                Id masterOppId = paramsData.opportunityId;
                List<String> services = paramsData.services;

                Map<String, Opportunity> opps = OpportunityHelper.createTechnicalOpportunities(masterOppId, services);
                result = JSON.serialize(opps);
            }

            if (paramsData.action == ACTION_UPDATE_TECHNICAL_OPPORTUNITIES) {
                Id masterOppId = paramsData.opportunityId;
                Map<String, BillingWrappers.QuoteWrapper> quotesByService = paramsData.quotesByService;
                OpportunityHelper.updateTechnicalOpportunities(masterOppId, quotesByService);
            }

            if (paramsData.action == ACTION_GET_TECHNICAL_OPPORTUNITIES) {
                Id masterOppId = paramsData.opportunityId;

                Map<String, Opportunity> opps = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterOppId);
            }

            if (paramsData.action == ACTION_CREATE_CHANGE_ORDER_OPPORTUNITY) {
				Opportunity oppty = paramsData.opportunityWrapper.createPSChangeOrderOpportunityRecord();
                result = JSON.serializePretty(oppty);
            }

            res.responseBody = Blob.valueOf(result);
        } catch(Exception e) {
            Map<String,String> errMsg = new Map<String,String>();
            errMsg.put('error', e.getMessage());
            errMsg.put('stackTrace', e.getStackTraceString());
            res.responseBody = Blob.valueOf( JSON.serialize(errMsg) );
        }
    }
}