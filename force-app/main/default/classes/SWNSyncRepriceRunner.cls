public class SWNSyncRepriceRunner extends SWNActionRunner {
    @TestVisible
    private static final String EXCEEDED_MAX_SIZE_LIMIT = 'Exceeded max size limit of 6000000';

    public SWNSyncRepriceRunner() {}

    public SWNSyncRepriceRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        syncReprice();
    }

    private void syncReprice() {
        SWNMessageHelper.CompositeResult repriceResult = priceChange_new(sdc);
        if (repriceResult.baseMessage.status != Response.STATUS_SUCCESS) {
            sdc.currentStep.isStepCompletedSuccessfully = false;
        }
        SWNMessageHelper.SWNMessage msg = SWNHelper.INFO_MESSAGES_BUILDER.getSWNMessage(
            SWNMessageHelper.LabelMessage.REPRICE_RESPONSE_EXCEEDS_HEAP
        );
        if (msg.message.equals(repriceResult.baseMessage.message)) {
            sdc.currentStep.isStepCompletedSuccessfully = true;
        }
        res.addMessage(repriceResult.baseMessage);
    }

    private SWNMessageHelper.CompositeResult priceChange_new(SWNDataCollector sdc) {
        SWNMessageHelper.SWNMessage message;
        SWNMessageHelper.CompositeResult result;

        try {
            List<BillingWrappers.QuotePackageInfo> pInfos =
                (List<BillingWrappers.QuotePackageInfo>)
                    JSON.deserialize(sdc.qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
            BillingWrappers.QuotePackageInfo pInfo = pInfos[0];
            String packageId = pInfo.packageInfo.id;

            ChangePrice params = new ChangePrice(sdc);

            String accountPackageCatalogId = sdc.ngbsAcc?.getPackageById(sdc.packageId)?.catalogId;

            List<NGBS_Discount.DiscountTemplateGroup> dGroups;
            Response dtgRes = SWNHelper.getDiscountTemplateGroups(sdc.billingId, packageId);
            if (dtgRes.isSuccess()) {
                dGroups = (List<NGBS_Discount.DiscountTemplateGroup>) dtgRes.data.get('result');
            } else {
                return new SWNMessageHelper.CompositeResult();
            }

            for (NGBS_Discount.DiscountTemplateGroup dGroup : dGroups) {
                /* for correct reprice need to clear id */
                dGroup.id = null;

                /* need to keep all discounts with priority ^ */
                Boolean isSpecialPriority = dGroup.priority == '^';

                if (isSpecialPriority || dGroup.target.catalogId == accountPackageCatalogId) {
                    params.discounts.add(dGroup);
                }
            }

            Boolean isRepriceParamsDataEmpty = params.contractualLicenses.isEmpty() && params.discounts.isEmpty();

            if (isRepriceParamsDataEmpty) {
                message = SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(
                    SWNMessageHelper.LabelMessage.REPRICE_IS_SKIPPED
                );

                return new SWNMessageHelper.CompositeResult(message);
            }

            HttpResponse resp;
            try {
                resp = reprice(sdc.billingId, packageId, params);
                result = handleRepriceResponse(resp);
            } catch(Exception e) {
                result = handleRepriceResponseException(e);
            }
        } catch(Exception e) {
            message = SWNHelper.ERROR_MESSAGES_BUILDER.buildSWNMessage('Process Order', e.getMessage(), e.getStackTraceString());
            result = new SWNMessageHelper.CompositeResult(message);
        }

        return result;
    }

    @TestVisible
    private HttpResponse reprice(string accountId, string packageId, ChangePrice params) {
        HttpResponse res;

        try {
            /* http://stg01-jenkins01.lab.nordigy.ru:8080/view/EDI-ATT-SV7/job/edi-att-sv7-billing-account-build/API_documentation/ */
            String url = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/'+ accountId + '/purchase/' + packageId + '/priceChange';
            res = NGBSAPI.requestNGBS(url, HttpHelper.METHOD_POST, JSON.serialize(params));

        } catch(Exception e) {
            AquivaHelper.throwAquivaException(e.getMessage());
        }

        return res;
    }

    @TestVisible
    private SWNMessageHelper.CompositeResult handleRepriceResponse(HttpResponse res) {
        SWNMessageHelper.SWNMessage message = HttpHelper.isSuccess(res)
            ? SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.SYNC_REPRICE_SUCCESS)
            : SWNHelper.ERROR_MESSAGES_BUILDER.buildSWNMessage('Sync with NGBS', res.getBody(), null);

        return new SWNMessageHelper.CompositeResult(message);
    }

    @TestVisible
    private SWNMessageHelper.CompositeResult handleRepriceResponseException(Exception e) {
        if (!EXCEEDED_MAX_SIZE_LIMIT.equalsIgnoreCase(e.getMessage())) {
            AquivaHelper.throwAquivaException(e.getMessage());
        }
        SWNMessageHelper.SWNMessage message = SWNHelper.INFO_MESSAGES_BUILDER.getSWNMessage(
            SWNMessageHelper.LabelMessage.REPRICE_RESPONSE_EXCEEDS_HEAP
        );

        return new SWNMessageHelper.CompositeResult(message);
    }

    @TestVisible
    private class ChangePrice {
        public string salesOrderId;
        public ContractRestAPI.ContractualLicense[] contractualLicenses;
        public NGBS_Discount.DiscountTemplateGroup[] discounts;
        public List<String> responseFields = new List<String>();

        public ChangePrice(SWNDataCollector sdc) {
            this.salesOrderId = sdc.qt.OpportunityId;

            ContractRestAPI.ContractParams contractParams = new ContractRestAPI.ContractParams(sdc.qt);
            if (!contractParams.packages.isEmpty()) {
                this.contractualLicenses = contractParams.packages.get(0).licenses;
            } else {
                this.contractualLicenses = new List<ContractRestAPI.ContractualLicense>();
            }

            this.discounts = new List<NGBS_Discount.DiscountTemplateGroup>();
        }
    }
}