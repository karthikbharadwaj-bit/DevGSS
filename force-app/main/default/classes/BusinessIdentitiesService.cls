/**
 * Created by Dmitriy.Borisov on 3/21/2020.
 */

public without sharing class BusinessIdentitiesService implements Queueable, Database.AllowsCallouts {

    private List<Approval__c> approvals;
    private String comment;

    public BusinessIdentitiesService(List<Approval__c> approvals, String comment) {
        this.approvals = approvals;
        this.comment = comment;
    }

    public void execute(QueueableContext context) {
        updateApprovals(approvals, comment, true);
    }

    public static void updateApprovals(List<Approval__c> approvals, String comment, Boolean isUpdateAccounts) {
        Set<Id> appIds = new Set<Id>();
        List<Approval__c> updateApprovals = new List<Approval__c>();
        Map<Id,Account> accountsToUpdate = new Map<Id,Account>();
        if (!approvals.isEmpty()) {
            TaxExemptionHelper.isFastApprovalExecuted = true;
            for (Approval__c app : approvals) {
                try{
                    ApprovalHelper.submitApprovalRequest(app.Id, ApprovalHelper.PROCESS_TAX_EXEMPTION_APPROVAL_PROCESS, null);
                    appIds.add(app.Id);
                    if (!accountsToUpdate.containsKey(app.Account__c)) {
                        accountsToUpdate.put(app.Account__c, new Account(Id = app.Account__c, TaxExemptionApprovals__c = false, ConfirmTaxExemptionRemoval__c = false));
                    }
                    Approval__c appUpdate = new Approval__c(Id = app.Id);
                    if (TaxExemptionHelper.VATBRANDS.contains(app.OpportunityBrand__c) && !TaxExemptionHelper.isIndiaCountry(app.Account__r.BillingCountry)) {
                        appUpdate.VATExemption__c = ApprovalHelper.STATUS_REJECTED;
                        updateApprovals.add(appUpdate);
                    } else {
                        if (app.CountyTaxExemption__c == ApprovalHelper.STATUS_APPROVED) {
                            appUpdate.CountyTaxExemption__c = ApprovalHelper.STATUS_REJECTED;
                        }
                        if (app.FederalTaxExemption__c == ApprovalHelper.STATUS_APPROVED) {
                            appUpdate.FederalTaxExemption__c = ApprovalHelper.STATUS_REJECTED;
                        }

                        if (app.LocalTaxExemption__c == ApprovalHelper.STATUS_APPROVED) {
                            appUpdate.LocalTaxExemption__c = ApprovalHelper.STATUS_REJECTED;
                        }

                        if (app.SalesTaxExemption__c == ApprovalHelper.STATUS_APPROVED) {
                            appUpdate.SalesTaxExemption__c = ApprovalHelper.STATUS_REJECTED;
                        }

                        if (app.StateTaxExemption__c == ApprovalHelper.STATUS_APPROVED) {
                            appUpdate.StateTaxExemption__c = ApprovalHelper.STATUS_REJECTED;
                        }
                        if (app.SEZWOPExemption__c == ApprovalHelper.STATUS_APPROVED || app.SEZWOPExemption__c == TaxExemptionHelper.CURRENT) {
                            appUpdate.SEZWOPExemption__c = ApprovalHelper.STATUS_REJECTED;
                        }
                        updateApprovals.add(appUpdate);
                    }
                } catch(Exception e) {
                    PlatformLog.logException('errorAccount', e);
                }
            }

            if (!appIds.isEmpty()) {
                if (UserInfo.getUserName().contains('rcesb@ringcentral.com')) {
                    ApprovalHelper.processApprovalRequest(appIds, 'Rejected because the Customer changed Billing Address outside of SFDC', 'Reject');
                } else {
                    ApprovalHelper.processApprovalRequest(appIds, comment, 'Reject');
                }
            }

            if (!updateApprovals.isEmpty()) {
                Triggers.switchOff();
                update updateApprovals;
                Triggers.switchOn();
            }

            if (!accountsToUpdate.isEmpty() && isUpdateAccounts) {
                update accountsToUpdate.values();
            }
        }
    }

    public static List<BillingWrappers.BusinessIdentity> parseResponseBody(String responseBody) {
        List<BillingWrappers.BusinessIdentity> bIdentities = new List<BillingWrappers.BusinessIdentity>();
        if (responseBody != null) {
            bIdentities = (List<BillingWrappers.BusinessIdentity>) JSON.deserialize(responseBody, List<BillingWrappers.BusinessIdentity>.class);
        }
        return bIdentities;
    }

    public static String getResponseBody(String packageId) {
        String responseBody;
        if (packageId != null) {
            String endpoint = NGBSAPI.NGBS_PACKAGES + '/' + packageId + '/businessidentities';
            responseBody = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET).getBody();
        }
        return responseBody;
    }
}