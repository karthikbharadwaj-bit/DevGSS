public class SWNContractCancellationRunner extends SWNActionRunner {

    public SWNContractCancellationRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        syncContractCancellation();
    }

    private void syncContractCancellation() {
        cancelContract();
        if (!res.isSuccess()) {
            sdc.currentStep.isStepCompletedSuccessfully = false;
            return;
        }
        if (!String.isBlank(sdc.opp.Account.Active_Sales_Agreement__c)) {
            sdc.currentStep.quoteFieldsToUpdate.put(Quote.Id.toString(), sdc.opp.Account.Active_Sales_Agreement__c);
            sdc.currentStep.quoteFieldsToUpdate.put(Quote.Status.toString(), QuoteHelper.QUOTE_STATUS_TERMINATED);
        }
        sdc.currentStep.accountFieldsToUpdate.put(Account.Id.toString(), sdc.opp.AccountId);
        sdc.currentStep.accountFieldsToUpdate.put(Account.Active_Sales_Agreement__c.toString(), null);
    }

    @TestVisible
    private void cancelContract() {
        BillingWrappers.QuotePackageInfo packageInfo = QuoteHelper.getPackageInfo(sdc.qt);
        if (packageInfo == null) {
            res.addMessage(SWNHelper.ERROR_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.CANCEL_CONTRACT_IF_NO_PKG_INFO_ON_QUOTE));
            return;
        }
        String contractId = getActiveContractId(sdc.billingContracts);

        Boolean isActionCompleted = false;
        String endpoint = sdc.isMPUB
            ? NGBSAPI.getContractCancellationEndpointMPUB(sdc.billingId, contractId)
            : NGBSAPI.getContractCancellationEndpointMPLite(sdc.billingId, packageInfo.packageInfo.id, contractId);

        HttpResponse httpResponse = NGBSAPI.requestNGBS(
            endpoint,
            HttpHelper.METHOD_DELETE,
            HTTPHelper.CONTENT_TYPE_APPLICATION_JSON
        );
        if (HttpHelper.isSuccess(httpResponse)) {
            Response discountsDeletion = deleteCurrentDiscounts();
            if (!discountsDeletion.isError()) {
                isActionCompleted = true;
            }
        }

        if (!isActionCompleted) {
            res.error(Label.Contract_Cancellation_request_failed, httpResponse.getBody());
            return;
        }

        res.addMessage(SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.CANCEL_CONTRACT_SUCCESS));
    }

    @TestVisible
    private String getActiveContractId(List<BillingWrappers.BillingContract> billingContracts) {
        String activeContractId;
        for (BillingWrappers.BillingContract contract : billingContracts) {
            if (contract.isActiveContract()) {
                activeContractId = contract.id;
            }
        }
        return activeContractId;
    }

    @TestVisible
    private Response deleteCurrentDiscounts() {
        Response res = new Response();
        String ngbsPackageId = sdc.ngbsPackage?.id;

        List<NGBS_Discount.DiscountTemplateGroup> dGroups;
        Response dtgRes = SWNHelper.getDiscountTemplateGroups(sdc.billingId, ngbsPackageId);
        if (dtgRes.isSuccess()) {
            dGroups = (List<NGBS_Discount.DiscountTemplateGroup>) dtgRes.data.get('result');
        } else {
            return dtgRes;
        }
        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(sdc.qt);
        String targetCatalogId = pInfo.packageInfo.catalogId;
        String targetVersion = pInfo.packageInfo.version;

        List<NGBS_Discount.DiscountTemplateGroup> filteredDTG = SWNHelper.filterDiscountTemplates_new(
            dGroups,
            targetCatalogId,
            targetVersion,
            null
        );

        SWNMessageHelper.CompositeResult deleteResult = SWNSyncDiscountRunner.deleteDiscounts_new(filteredDTG, sdc.billingId, ngbsPackageId, null);

        if (deleteResult.baseMessage.status == Response.STATUS_ERROR) {
            res.error(deleteResult.baseMessage.header, deleteResult.baseMessage.message);
        }

        return res;
    }
}