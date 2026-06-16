public with sharing class ProcessBillingPackageSync implements Queueable, Database.AllowsCallouts {
    String oppId;
    String accountId;
    String billingPackageId;
    String billingId;

    public ProcessBillingPackageSync(String oppId, String accountId, String billingId, String billingPackageId) {
        this.oppId = oppId;
        this.accountId = accountId;
        this.billingId = billingId;
        this.billingPackageId = billingPackageId;
    }

    public void execute(QueueableContext context) {
        try{
            // Need to have ServiceType(product name) for Package record for correct work in related triggers
            BillingWrappers.NGBSAccount ngbsAcc = NGBSAPI.getNGBSAccount(billingId);
            BillingWrappers.NGBSAccountPackage pkg = ngbsAcc.getPackageById(billingPackageId);
            syncProServDiscounts(oppId, billingPackageId, pkg.product);
            createBillingAccountPackage(oppId, accountId, billingPackageId, pkg.product);
        } catch (Exception e) {
            PlatformLog.logException('ProcessBillingPackageSync', e);
        }
    }

    private static void createBillingAccountPackage(String oppId, String accountId, String billingPackageId, String productName) {
        Package__c pkgForInsert = PackageHelper.buildPackage(oppId, accountId, billingPackageId, productName);
        insert pkgForInsert;
    }

    private static void syncProServDiscounts(String oppId, String billingPackageId, String productName) {
        if (productName == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) {
            Map<Id, String> oppIdToBillingPackageId = new Map<Id, String>();
            oppIdToBillingPackageId.put(oppId, billingPackageId);
            ProServDiscountsHelper.syncProServDiscounts(oppIdToBillingPackageId);
        }
    }
}