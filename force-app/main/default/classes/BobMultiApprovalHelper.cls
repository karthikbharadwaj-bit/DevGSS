public with sharing class BobMultiApprovalHelper {
    private static Map<Id, Double> accIdToNGBSMonthlyCreditLimitMap = new Map<Id, Double>();
    public static Double getMonthlyCreditLimitFromNGBSByAccountId(Id accId) {
        return accIdToNGBSMonthlyCreditLimitMap.get(accId);
    }

    @AuraEnabled
    public static Response getLayout(Id recordTypeId) {
        Response resp = new Response();
        String layoutName = Test.isRunningTest()
            ? 'Invoice-on-behalf Request Admin Layout'
            : LayoutHelper.getLayoutName(recordTypeId);

        List<LayoutHelper.Section> sections = LayoutHelper.getSections('Approval__c', layoutName);
        resp.setData('layout', JSON.serialize(sections));

        return resp;
    }

    @AuraEnabled
    public static Response getAccountLimits(String billingId, String packageId) {
        Response resp = NGBSAPI.getPackageLimits(billingId, packageId);
        List<BillingWrappers.GlobalPackageLimits> limits = (List<BillingWrappers.GlobalPackageLimits>) resp?.data.get('packageLimits');

        Response result = new Response();
        if (!limits.isEmpty()) {
            result.setData('limit', limits[0].value);
        }
        return result;
    }

    @AuraEnabled
    public static Response getAccountSummary(String billingId) {
        Response resp = new Response();
        if (String.isNotBlank(billingId)) {
            BillingWrappers.NGBSAccount accountInfo = NGBSAPI.getNGBSAccount(billingId);
            resp.setData('packageId', accountInfo?.getPackage()?.id);
        }

        return resp;
    }

    @AuraEnabled
    public static Response createAndSubmitApprovals(String approvalsListJSON, String accIdToMonthlyCreditLimitMapJSON) {
        Response resp = new Response();
        try {
            accIdToNGBSMonthlyCreditLimitMap = (Map<Id, Double>) JSON.deserialize(
                accIdToMonthlyCreditLimitMapJSON, Map<Id, Double>.class);
            List<Approval__c> appList = (List<Approval__c>) JSON.deserialize(
                approvalsListJSON, List<Approval__c>.class);
            insert appList;
            submitForApproval(appList);
        } catch(Exception ex) {
            resp.error(ex);
        }
        return resp;
    }

    public static void submitForApproval(List<Approval__c> appList) {
        List<Approval__c> updatedApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsByIds(new List<Object>{appList})
            .executeQuery();
        for (Approval__c approval : updatedApprovals) {
            if (approval.Status__c != ApprovalHelper.STATUS_APPROVED) {
                ApprovalHelper.submitApprovalRequest(approval.Id, ApprovalHelper.PROCESS_INVOICE_REQUEST_APPROVAL, null);
            }
        }
    }

    @AuraEnabled
    public static Response populatePartnerInfoOnAccounts(String accountListJSON) {
        Response resp = new Response();
        List<Account> accList = (List<Account>) JSON.deserialize(accountListJSON, List<Account>.class);
        try {
            update accList;
        } catch(Exception ex) {
            resp.error(ex);
        }
        return resp;
    }
}