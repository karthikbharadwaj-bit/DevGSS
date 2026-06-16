public class InboundEmailService implements Messaging.InboundEmailHandler {
    private final String APPROVE_RESPONSE = 'approve';
    private final Set<String> APPROVE_RESPONSE_WORDS = new Set<String>{'approve', 'approved', 'confirm', 'confirmed','accept', 'accepted'};
    private final String REJECT_RESPONSE = 'reject';
    private final String OPPORTUNITY_CLOSE_EMAIL = 'InboundEmailService';
    private Set<String> closeDetailsFields =  new Set<String>{
        'CW_Categories_Who_did_we_beat__c',
        'CW_Who_did_we_beat__c',
        'CW_Categories_Who_did_we_beat_other__c',
        'CW_Categories_Who_did_we_replace__c',
        'CW_Who_did_we_replace__c',
        'CW_Categories_Who_did_we_replace_other__c',
        'CW_Primary_Win_Reason__c',
        'CW_Win_Reason_Features__c',
        'CW_Win_Reason_Features_enterprise__c',
        'CW_Win_Reason_Integrations__c',
        'CW_Win_Reason_Integrations_other__c',
        'CW_Win_Reason_Awards__c',
        'CW_Win_Reason_Awards_other__c',
        'CW_Win_Reason_Savings__c',
        'CW_Secondary_Win_Reason__c'
    };

    private static Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

    public static Map<String, String> orgWideEmailMap {
        get {
            if(orgWideEmailMap != null) {
                return orgWideEmailMap;
            }

            Map<String, String> orgWideEmailMapTemp = new Map<String, String>();
            if(!Test.isRunningTest()) {
                List<OrgWideEmailAddress> orgWideEmailAddresses = [
                        SELECT Id, DisplayName, Address
                        FROM OrgWideEmailAddress
                ];

                for (OrgWideEmailAddress owea : orgWideEmailAddresses) {
                    orgWideEmailMapTemp.put(owea.DisplayName, owea.Address);
                }
            }
            return orgWideEmailMapTemp;
        }

        set;
    }

    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        Feature_Toggle__c  featureToggle = Feature_Toggle__c.getInstance();

        if (isSystemEmail(email)) {
            return null;
        }

        if (featureToggle.Approval_For_Change_Order_Process__c) {
            if (envelope.toAddress == orgWideEmailMap.get(OPPORTUNITY_CLOSE_EMAIL)) {
                result = opportunityCloseHandler(email, envelope);
            }
        }

        return result;
    }

    private Boolean isSystemEmail(Messaging.InboundEmail email) {
        Boolean result = false;
        List<Emails__c> emailsToExclude = [
                        SELECT Id, Name, Email_Address__c 
                        FROM Emails__c
                        WHERE Name LIKE 'InboundEmailService%'];
        
        for (Emails__c emailToExclude : emailsToExclude) {
            if(email.fromAddress == emailToExclude.Email_Address__c) {
                result = true;
                break;
            }
        }
        return result;
    }

    private Messaging.InboundEmailResult opportunityCloseHandler(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        System.debug('/// InboundEmailService, email body ' + email.plainTextBody);
        Opportunity opty = getOpportunity(email.plainTextBody);
        if (opty == null) {
            result.success = false;
            result.message = 'This request has already expired. Please respond to the most recent email received';
            return result;
        }
        Id activeContractId = getActiveContractId(opty);
        saveInboundEmail(new List<Id>{opty.Id, activeContractId}, email);

        List<OpportunityContactRole> primaryContactRole = [SELECT Contact.Email, OpportunityId
            FROM OpportunityContactRole WHERE OpportunityId = :opty.Id
            AND IsPrimary = true
            AND Role = 'Signatory'];

        if(primaryContactRole.isEmpty() || primaryContactRole[0].Contact.Email != email.fromAddress) {
            result.success = false;
            result.message = 'You are not authorized to Approve or Reject this change. Please contact your Account Manager at RingCentral for assistance';
            return result;
        }

        if (OpportunityHelper.STAGE_NAMES_CLOSED.contains(opty.StageName)) {
            result.success = false;
            result.message = 'Opportunity is already closed';
            return result;
        }

        if (opty.StageName == OpportunityHelper.STAGE_NAME_AGREEMENT) {
            result.success = false;
            result.message = 'Opportunity is already in Agreement stage';
            return result;
        }

        String response = getCustomerResponse(email.plainTextBody.toLowerCase(), opty.Is_Billing_Opportunity__c);

        if (response == APPROVE_RESPONSE) {
            result.success = true;
            opty.CustomerConfirmation__c = OpportunityHelper.CONFIRMED;
            opty.StageName = OpportunityHelper.closedStage;
        } else if (response == REJECT_RESPONSE) {
            result.success = true;
            processRejectAnswer(opty);
        } else {
            result.success = false;
            result.message = 'To approve or reject, please answer with \'Approve\' or \'Reject\' to the first email';
            return result;
        }
        update opty;
        return result;
    }

    @TestVisible
    private Id getActiveContractId(Opportunity opty) {
        List<Account> accList = (List<Account>) new AccountSelector()
            .selectAccountsWithActiveContract(new List<Object>{new List<Id>{opty.AccountId}})
            .executeQuery();

        Id activeContractId;
        if (!accList.isEmpty() && !accList[0].Contracts.isEmpty()) {
            activeContractId = accList[0].Contracts[0].Id;
        }
        return activeContractId;
    }

    /**
     *  Customer response is considered as approved if approve words occures more that 2 times
     *  In other case it is considered as rejected
     */
    private String getCustomerResponse(String rawEmailBody, Boolean isNGBSOppty) {

        Integer approveCount = 0;
        Integer approveThreshold = (isNGBSOppty) ? 3 : 2;
        Integer rejectAmount = rawEmailBody.countMatches(REJECT_RESPONSE);

        for (String approveWord : APPROVE_RESPONSE_WORDS) {
            String matchingFormula = '\\b' + approveWord + '\\b';
            Pattern p = Pattern.compile(matchingFormula);
            Matcher m = p.matcher(rawEmailBody);
            while (m.find()) {
                approveCount++;
            }
        }

        String response;
        if (approveCount >= approveThreshold) {
            response = APPROVE_RESPONSE;
        } else {
            response = REJECT_RESPONSE;
        }

        return response;
    }

    private Opportunity getOpportunity(String rawBody) {

        String optyUuid = rawBody.substringAfter('/------').substringBefore('------/');
        if (optyUuid == '') {
            return null;
        }

        List<Opportunity> optyToProcess = new OpportunitySelector()
            .selectOpportunityByUUID(optyUuid)
            .executeQuery();
        if (!optyToProcess.isEmpty()) {
            return optyToProcess[0];
        }

        return null;
    }

    @TestVisible
    private void saveInboundEmail(List<Id> parentIdList, Messaging.InboundEmail email) {

        String title = email.fromAddress;
        String body = email.subject + '\n' + '\n' + email.plainTextBody;
        List<Note> noteList = new List<Note>();

        for (Id parentId : parentIdList) {
            if (parentId == null) {
                continue;
            }
            Note inboundEmailNote = new Note(ParentId = parentId, Title = title, Body = body);
            noteList.add(inboundEmailNote);
        }
        
        insert noteList;
    }

    private void processRejectAnswer(Opportunity optyToUpdate) {

        optyToUpdate.CustomerConfirmation__c = OpportunityHelper.REJECTED;
        optyToUpdate.ConfirmAndClose__c = false;
        optyToUpdate.StageName = OpportunityHelper.STAGE_NAME_AGREEMENT;
        for(String field : closeDetailsFields) {
            optyToUpdate.put(field, null);
        }
    }
}