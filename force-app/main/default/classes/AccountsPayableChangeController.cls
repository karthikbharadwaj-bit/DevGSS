public without sharing class AccountsPayableChangeController {
    @AuraEnabled()
    public static Response getApprovalInfo(Id recordId) {
        Response result = new Response();

        Approval__c approval = (Approval__c) new ApprovalSelector()
            .selectInvoicingApprovalsForAPCChange(recordId)
            .executeQuery()
            .get(0);

        if (!ApprovalHelper.isApprovalApproved(approval)) {
            result.error('Error', 'Approval must be approved first');
            result.setData('approvalInfo', new ApprovalInfoWrapper(approval));
            return result;
        }

        ApprovalInfoWrapper approvalInfo;

        if (ApprovalHelper.isInvoiceOnBehalfRequestApproval(approval)
            || ApprovalHelper.isInvoiceWholesaleRequestApproval(approval)
        ) {
            Id partnerAccountId = (
                (Contact) new ContactSelector()
                    .selectContactsByIds(new List<Object>{ new List<Id>{ approval.PartnerAccountPayableContact__c } })
                    .executeQuery()
                    .get(0)
            ).AccountId;
            approvalInfo = new ApprovalInfoWrapper(approval, partnerAccountId);
        } else {
            approvalInfo = new ApprovalInfoWrapper(approval);
        }
        result.setData('approvalInfo', approvalInfo);

        return result;
    }

    @AuraEnabled()
    public static Response unlockRecord(Id recordId) {
        Response result = new Response();
        try {
            if (Approval.isLocked(recordId)) {
                Approval.unlock(recordId);
            }
        } catch (Exception ex) {
            result.error(ex.getTypeName(), ex.getMessage());
        }
        return result;
    }

    @AuraEnabled()
    public static Response updateApproval(String params) {
        Response result = new Response();

        ApprovalUpdateParams approvalParams = (ApprovalUpdateParams)
            JSON.deserialize(params, ApprovalUpdateParams.class);

        Approval__c approval = new Approval__c(
            Id = approvalParams.recordId,
            InvoiceApprovalType__c = ApprovalHelper.GOTOTHEFINALSTEP
        );

        if (String.isNotBlank(approvalParams.selectedAccountPayableId)) {
            approval.AccountPayableContact__c = approvalParams.selectedAccountPayableId;
        }

        if (String.isNotBlank(approvalParams.selectedPartnerPayableId)) {
            approval.PartnerAccountPayableContact__c = approvalParams.selectedPartnerPayableId;
        }

        try {
            update approval;
            result.addMessage('success', 'Approval is updated');
        } catch(Exception e) {
            return lockRecord(approvalParams.recordId);
        }
        return result;
    }

    @AuraEnabled()
    public static Response submitRecord(String params) {
        Response result = new Response();

        SubmitApprovalParams submitParams = (SubmitApprovalParams)
            JSON.deserialize(params, SubmitApprovalParams.class);

        try {
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setComments(
                'Requesting Final Approval of APC change by ' +
                UserInfo.getName() +
                ' from Invoice Approval Queue.'
            );
            request.setObjectId(submitParams.recordId);
            request.setSubmitterId(submitParams.ownerId);
            request.setProcessDefinitionNameOrId(ApprovalHelper.PROCESS_INVOICE_REQUEST_APPROVAL);
            request.setSkipEntryCriteria(false);

            Approval.ProcessResult submitResult = Approval.process(request);

            result.setData('submitResult', submitResult.isSuccess());
            result.addMessage('success', 'Approval is submitted');
        } catch (Exception ex) {
            return lockRecord(submitParams.recordId);
        }
        return result;
    }

    @TestVisible
    private static Response lockRecord(Id recordId) {
        Response result = new Response();
        try {
            if (!Approval.isLocked(recordId)) {
                Approval.lock(recordId);
            }
        } catch (Exception ex) {
            result.error(ex.getTypeName(), ex.getMessage());
        }
        return result;
    }

    public class ApprovalInfoWrapper {
        @AuraEnabled
        public Id ownerId;

        @AuraEnabled
        public Id accountId;

        @AuraEnabled
        public Id existingAccountPayableId;

        @AuraEnabled
        public Id partnerAccountId;

        @AuraEnabled
        public Id existingPartnerPayableId;

        public ApprovalInfoWrapper(Approval__c approval) {
            this.ownerId = approval.OwnerId;
            this.accountId = approval.Account__c;
            this.existingAccountPayableId = approval.AccountPayableContact__c;
        }

        public ApprovalInfoWrapper(Approval__c approval, Id partnerAccountId) {
            this.ownerId = approval.OwnerId;
            this.accountId = approval.Account__c;
            this.existingAccountPayableId = approval.AccountPayableContact__c;
            this.partnerAccountId = partnerAccountId;
            this.existingPartnerPayableId = approval.PartnerAccountPayableContact__c;
        }
    }

    public class ApprovalUpdateParams {
        @AuraEnabled
        public Id recordId {get;set;}

        @AuraEnabled
        public Id selectedAccountPayableId {get;set;}

        @AuraEnabled
        public Id selectedPartnerPayableId {get;set;}
    }

    public class SubmitApprovalParams {
        @AuraEnabled
        public Id recordId {get;set;}

        @AuraEnabled
        public Id ownerId {get;set;}
    }
}