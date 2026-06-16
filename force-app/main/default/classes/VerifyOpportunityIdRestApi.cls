/*
 * Name         : VerifyOpportunityIdRestApi
 * Created By   : Alexander Savickiy
 * Created Date : 11/September/2018
 * Description  : Used to verify if there is an opportunity Id with such account user Id
 * Dependencies : No
 */
@RestResource(urlMapping='/VerifyOpportunityIdRestApi')
global with sharing class VerifyOpportunityIdRestApi {
	@HttpPost
	global static void verifyOpportunityId() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        OpportunityValidationRequest requestParams = (OpportunityValidationRequest)JSON.deserialize(requestBody, OpportunityValidationRequest.class);

        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        OpportunityValidationResponse validationResponse = new OpportunityValidationResponse(requestParams.oppId, requestParams.accUserId , false, '');

        if (!SFDescribeHelper.isValidSalesforceId(requestParams.oppId, Schema.Opportunity.sObjectType)) {
            validationResponse.errorMessage = 'Opportunity Id is empty or doesn\'t exist in salesforce';
            res.responseBody = Blob.valueOf(JSON.serialize(validationResponse));
            return;
        }

        if (String.isBlank(requestParams.accUserId)) {
            validationResponse.errorMessage = 'You must specify not blank account Enterprise Account id';
            res.responseBody = Blob.valueOf(JSON.serialize(validationResponse));
            return;
        }

        List<Opportunity> opty = [
            SELECT Id,
                (SELECT Id, Approved_Status__c
                FROM Quotes
                WHERE IsPrimary__c = true
                AND Approved_Status__c IN :QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED LIMIT 1)
            FROM Opportunity
            WHERE Account.RC_User_ID__c = :requestParams.accUserId
            AND Id = :requestParams.oppId AND StageName IN :OpportunityHelper.STAGE_NAMES_CLOSED
        ];

        if (!opty.isEmpty()) {
            if (!opty[0].Quotes.isEmpty()) {
                validationResponse.isValidId = true;
            }
        }

        res.responseBody = Blob.valueOf(JSON.serialize(validationResponse));
	}

    public class OpportunityValidationResponse{
        public String oppId;
        public String accUserId;
        public Boolean isValidId;
        public String errorMessage;

        public OpportunityValidationResponse(String oppId, String accUserId, Boolean isValidId, String errorMessage) {
            this.oppId = oppId;
            this.accUserId = accUserId;
            this.isValidId = isValidId;
            this.errorMessage = errorMessage;
        }
    }

    public class OpportunityValidationRequest{
        public String oppId;
        public String accUserId;
    }
}