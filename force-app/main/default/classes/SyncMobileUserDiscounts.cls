public with sharing class SyncMobileUserDiscounts implements Queueable, Database.AllowsCallouts {

    private class SyncDiscountsException extends Exception {}

    private Map<String, String> errorsMap = new Map<String, String>();

    public class SyncDiscountsParam {
        public String serviceAccountBillingId;
        public NGBS_Discount.DiscountItemWrapper mobileUser;
        public SyncDiscountsParam(String serviceAccountBillingId, NGBS_Discount.DiscountItemWrapper mobileUser) {
            this.serviceAccountBillingId = serviceAccountBillingId;
            this.mobileUser = mobileUser;
        }
    }

    private List<SyncDiscountsParam> params = new List<SyncDiscountsParam>();

    public SyncMobileUserDiscounts(List<SyncDiscountsParam> params) {
        if (params != null) {
            // TODO: increase max processing size: if we need to sync more than 20 accounts - split and enqueue second job
            this.params = checkParameters(params);
        }
    }

    @TestVisible
    private List<SyncDiscountsParam> checkParameters(List<SyncDiscountsParam> params) {
        List<SyncDiscountsParam> result = new List<SyncDiscountsParam>();
        if (params == null) {
            return result;
        }
        for (SyncDiscountsParam param : params) {
            if (String.isEmpty(param.serviceAccountBillingId) || param.mobileUser == null) {
                continue;
            }
            result.add(param);
        }
        if (result.size() > 20) {
            throw new SyncDiscountsException('You cannot process more than 20 accounts');
        }
        return result;
    }

    public void execute(QueueableContext context) {
        for (SyncDiscountsParam param : params) {
            try {
                syncDiscount(param.serviceAccountBillingId, param.mobileUser);
            } catch (Exception ex) {
                errorsMap.put(param.serviceAccountBillingId, ex.getMessage());
            }
        }
        handleErrors();
    }

    public NGBS_Discount.DiscountTemplateGroup syncDiscount(String billingId, NGBS_Discount.DiscountItemWrapper mobileUser) {

        if (String.isBlank(billingId)) {
            throw new SyncDiscountsException('Billing id is empty');
        }

        if (mobileUser == null) {
            return null;
        }

        Package__c billingInfo = getBillingInfo(billingId);

        List<NGBS_Discount.DiscountTemplateGroup> dGroups = getDiscountTemplateGroupsForAccount(
            billingId,
            billingInfo.Account_Package_ID__c
        );
        String nextPriority = NGBS_Discount.getNextPriorities(dGroups, 1)?.get(0);

        NGBS_Discount.DiscountTemplateGroup dtgMU = buildMobileUserDTG(
            billingId,
            billingInfo,
            nextPriority,
            mobileUser
        );

        String endPoint = NGBSAPI.getDiscountTemplateGroupEndpoint(billingId, billingInfo.Account_Package_ID__c);

        if (!dGroups.isEmpty()) {
            removeOldMUDiscount(dGroups, endPoint);
        }

        createNewMUDiscount(dtgMU, endPoint);

        return dtgMU;
    }

    @TestVisible
    private Package__c getBillingInfo(String billingId) {
        if (String.isBlank(billingId)) {
            throw new SyncDiscountsException('Billing id is empty');
        }
        List<Package__c> packageList = (List<Package__c>) new PackageSelector()
            .selectPackageByAccountBillingId(billingId)
            .executeQuery();
        if (packageList.isEmpty()) {
            throw new SyncDiscountsException('Cannot find find a Package__c for account with BillingId = "' + billingId + '"');
        }
        return packageList.get(0);
    }

    private List<NGBS_Discount.DiscountTemplateGroup> getDiscountTemplateGroupsForAccount(String billingId, String accountPackageId) {
        if (String.isBlank(billingId)) {
            throw new SyncDiscountsException('Billing id is empty');
        }
        if (String.isBlank(accountPackageId)) {
            throw new SyncDiscountsException('AccountPackageId id is empty');
        }
        List<NGBS_Discount.DiscountTemplateGroup> dGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
        Response dtgRes = SWNHelper.getDiscountTemplateGroups(billingId, accountPackageId);
        if (dtgRes.isSuccess()) {
            dGroups = (List<NGBS_Discount.DiscountTemplateGroup>) dtgRes.data.get('result');
        }
        return dGroups;
    }

    @TestVisible
    private NGBS_Discount.DiscountTemplateGroup buildMobileUserDTG(String billingId, Package__c billingInfo, String dtgPriority, NGBS_Discount.DiscountItemWrapper mobileUser) {

        BillingWrappers.QuotePackageInfo targetPkgInfo = getTargetPackageInfo(billingInfo);

        List<BillingWrappers.BillingContract> billingContracts = getBillingContracts(
            billingId,
            billingInfo.Account_Package_ID__c,
            billingInfo.Account__c
        );

        Map<String, String> externalIdToBillingTypeMap = new Map<String, String> {
            Product2Helper.MOBILE_USER_ELEMENT_ID => Product2Helper.BILLING_TYPE_USAGE
        };

        NGBS_Discount.DiscountTemplateGroup dtgMU = new NGBS_Discount.DiscountTemplateGroup(
            NGBS_Discount.MU_ELA,
            targetPkgInfo,
            new List<NGBS_Discount.DiscountItemWrapper>{ mobileUser },
            dtgPriority,
            billingContracts,
            externalIdToBillingTypeMap
        );

        return dtgMU;
    }

    @TestVisible
    private List<BillingWrappers.BillingContract> getBillingContracts(String billingId, String packageId, Id accountId) {

        if (String.isBlank(billingId) || String.isBlank(packageId)) {
            return new List<BillingWrappers.BillingContract>();
        }

        return NGBSAPI.requestContractsFromBilling(billingId, packageId);
    }

    private BillingWrappers.QuotePackageInfo getTargetPackageInfo(Package__c pkg) {
        BillingWrappers.QuotePackageInfo targetPkgInfo = new BillingWrappers.QuotePackageInfo();
        targetPkgInfo.packageInfo.catalogId = pkg.Package_Catalog_Id__c;
        targetPkgInfo.packageInfo.version = pkg.Package_Version__c;
        return targetPkgInfo;
    }

    private void removeOldMUDiscount(List<NGBS_Discount.DiscountTemplateGroup> dtgList, String dtgEndpoint) {

        Set<String> dtgIdsToRemove = getDiscountsIdsForRemove(dtgList);

        if (dtgIdsToRemove.isEmpty()) {
            return;
        }

        List<String> errorMessages = new List<String>();
        for (String dtgId : dtgIdsToRemove) {
            String deleteDiscountGroupEndpoint = dtgEndpoint + '/' + dtgId;
            HttpResponse response = new HttpResponse();
            if (!Test.isRunningTest()) {
                response = NGBSAPI.requestNGBS(deleteDiscountGroupEndpoint, 'DELETE');
            } else {
                response.setBody('[{"id":12345}]');
                response.setStatusCode(200);
            }

            Integer statusCode = response.getStatusCode();
            if (statusCode != 200) {
                String errorMessage = 'Wrong status code for removing old mobile user discount. ' +
                    'Expected 200, got: ' + statusCode + '; dtgId: "' + dtgId + '"';
                errorMessages.add(errorMessage);
            }
        }
        if (!errorMessages.isEmpty()) {
            throw new SyncDiscountsException(String.join(errorMessages, ' \n'));
        }
    }

    @TestVisible
    private Set<String> getDiscountsIdsForRemove(List<NGBS_Discount.DiscountTemplateGroup> dtgList) {
        Set<String> dtgIdsToRemove = new Set<String>();

        if (dtgList == null || dtgList.isEmpty()) {
            return dtgIdsToRemove;
        }

        for (NGBS_Discount.DiscountTemplateGroup dtg : dtgList) {
            if (dtg.description == NGBS_Discount.MU_ELA) {
                dtgIdsToRemove.add(dtg.id);
            }
        }

        return dtgIdsToRemove;
    }

    private void createNewMUDiscount(NGBS_Discount.DiscountTemplateGroup dtgMU, String dtgEndpoint) {
        if (dtgMU == null) {
            return;
        }

        HttpResponse response = new HttpResponse();
        if (!Test.isRunningTest()) {
            response = NGBSAPI.requestNGBS(dtgEndpoint, HttpHelper.METHOD_POST, JSON.serialize(dtgMU));
        } else {
            response.setBody('[{"id":12345}]');
            response.setStatusCode(201);
        }

        Integer statusCode = response.getStatusCode();
        if (statusCode != 201) {
            String errorMessage = 'Wrong status code for creating new mobile user discount. Expected 201, got: ' + statusCode;
            throw new SyncDiscountsException(errorMessage);
        }
    }

    private void handleErrors() {
        if (errorsMap.isEmpty()) {
            return;
        }
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for (String billingId : errorsMap.keySet()) {
            logs.add(
                PlatformLog.buildLog(
                    'SyncMobileUserDiscounts',
                    'Error occured during syncing Mobile User discounts for Account with billing Id: ' + billingId,
                    errorsMap.get(billingId),
                    null,
                    null
                )
            );
        }
        PlatformLog.logResults(logs);
    }
}