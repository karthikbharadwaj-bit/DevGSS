public virtual class SWNSyncDiscountRunner extends SWNActionRunner {
    @TestVisible
    private static final String DISCOUNTS_SYNCED_MSG = 'Discounts already synced';
    @TestVisible
    private static final String DISCOUNTS_SYNCED_MSG_DETAILS = 'Discounts for this quote were already synced';
    @TestVisible
    private static final String SYNC_DISCOUNTS_ERROR = 'An error occurred during applying discounts';

    private String billingId;
    private String billingPackageId;

    @TestVisible
    private SWNSyncDiscountRunner() {}

    public SWNSyncDiscountRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    public SWNSyncDiscountRunner(Id quoteId, String action, String billingId, String billingPackageId) {
        super(quoteId, action);
        this.billingId = billingId;
        this.billingPackageId = billingPackageId;
    }

    @TestVisible
    protected override void run() {
        syncDiscount();
    }

    protected virtual void syncDiscount() {
        // we are not reusing this.res because we don't want its (this.res.status) status to be overriden by the response of this method.
        Response discountResp = processDiscounts_new();
        if (!discountResp.isSuccess()) {
            sdc.currentStep.isStepCompletedSuccessfully = false;
        }
        if (discountResp.isInfo()) {
            sdc.currentStep.isStepCompletedSuccessfully = true;
        }
        res.messages.addAll(discountResp.messages);

        NGBS_Discount.syncDiscountsForELA(sdc.qt);
    }

    @TestVisible
    protected Response processDiscounts_new() {
        Response discountResp = new Response();
        if (sdc.syncable.isDiscountsSynced()) {
            discountResp.info(DISCOUNTS_SYNCED_MSG, DISCOUNTS_SYNCED_MSG_DETAILS);
            return discountResp;
        }

        String billingId = String.isNotBlank(this.billingId) ? this.billingId : sdc.billingId;
        String billingPackageId = String.isNotBlank(this.billingPackageId) ? this.billingPackageId : sdc.ngbsPackage?.id;
        discountResp = SWNHelper.processDiscounts_new(
            sdc.qt,
            sdc.billingContracts,
            billingId,
            billingPackageId
        );

        return discountResp;
    }


    public static SWNMessageHelper.CompositeResult applyNewDiscounts(
        Quote primaryQuote,
        BillingWrappers.QuotePackageInfo pInfo,
        Contract__c accountContract,
        List<BillingWrappers.BillingContract> billingContracts,
        String accountPackageId,
        List<NGBS_Discount.DiscountTemplateGroup> filteredDTG,
        List<NGBS_Discount.DiscountTemplateGroup> allDTG
    ) {
        SWNMessageHelper.SWNMessage msg;
        List<NGBS_Discount.DiscountTemplateGroup> dGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
        if (SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedLBODownsell__c) {
            dGroups = NGBS_Discount.getMergedDtgList(
                primaryQuote,
                accountContract,
                billingContracts,
                filteredDTG,
                allDTG
            );
        } else {
            dGroups = NGBS_Discount.getUpdatedDtgList(
                primaryQuote,
                pInfo,
                accountContract,
                billingContracts,
                filteredDTG,
                allDTG
            );
        }

        if (dGroups.isEmpty()) {
            msg = SWNHelper.INFO_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.NOTHING_TO_SYNC);
            return new SWNMessageHelper.CompositeResult(msg);
        }

        List<String> addedPriorities = new List<String>();
        String endpoint = NGBSAPI.getDiscountTemplateGroupEndpoint(primaryQuote.Account.Billing_ID__c, accountPackageId);
        for (NGBS_Discount.DiscountTemplateGroup dtg : dGroups) {
            HttpResponse response;
            if (dtg.discountTemplates.size() == 0) {
                continue;
            }
            try {
                if (!Test.isRunningTest()) {
                    response = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_POST, JSON.serialize(dtg));
                } else {
                    response = new HttpResponse();
                    response.setBody('[{"id":12345}]');
                    response.setStatusCode(201);
                }
                addedPriorities.add(dtg.priority);
            } catch (Exception ex) {
                removeDiscounts(addedPriorities, primaryQuote, accountPackageId);
                throw new AquivaHelper.AquivaException(SYNC_DISCOUNTS_ERROR + ' ' + ex.getMessage());
            }
        }
        msg = SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.SYNC_DISCOUNTS_SUCCESS);
        return new SWNMessageHelper.CompositeResult(msg);
    }

    public static void removeDiscounts(List<String> addedPriorities, Quote primaryQuote, String accountPackageId) {
        if (addedPriorities.isEmpty()) {
            return;
        }

        Response dtgRes = SWNHelper.getDiscountTemplateGroups(primaryQuote.Account.Billing_ID__c, accountPackageId);
        if (!dtgRes.isSuccess()) {
            throw new AquivaHelper.AquivaException(SYNC_DISCOUNTS_ERROR + ' ' + dtgRes.messages[0]);
        }

        List<NGBS_Discount.DiscountTemplateGroup> allGroups = (List<NGBS_Discount.DiscountTemplateGroup>) dtgRes.data.get(SWNHelper.RESULT);
        List<NGBS_Discount.DiscountTemplateGroup> removingGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
        for (NGBS_Discount.DiscountTemplateGroup dGroup : allGroups) {
            for (String priority : addedPriorities) {
                if (dGroup.priority == priority) {
                    removingGroups.add(dGroup);
                }
            }
        }
        SWNSyncDiscountRunner.deleteDiscounts_new(removingGroups, primaryQuote.Account.Billing_ID__c, accountPackageId, null);
    }

    public static SWNMessageHelper.CompositeResult deleteDiscounts_new(
        List<NGBS_Discount.DiscountTemplateGroup> discountGroups,
        String billingId,
        String targetPackageId,
        String targetChargeTerm
    ) {
        String endpoint = NGBSAPI.getDiscountTemplateGroupEndpoint(billingId, targetPackageId);
        for (NGBS_Discount.DiscountTemplateGroup dg : discountGroups) {
            // don't delete discounts for certain chargeterm if specified.
            if (isSkipDiscountDeletion(targetChargeTerm, dg.discountTemplates)) {
                continue;
            }

            String deleteDiscountGroupEndpoint = endpoint + '/' + dg.id;
            HttpResponse response = NGBSAPI.requestNGBS(deleteDiscountGroupEndpoint, HttpHelper.METHOD_DELETE);

            if (response.getStatusCode() != 200) {
                SWNMessageHelper.SWNMessage msg = SWNHelper.ERROR_MESSAGES_BUILDER.buildSWNMessage(SYNC_DISCOUNTS_ERROR, response.getBody(), null);
                return new SWNMessageHelper.CompositeResult(msg);
            }
        }
        return new SWNMessageHelper.CompositeResult();
    }

    private static Boolean isSkipDiscountDeletion(String targetChargeTerm, List<NGBS_Discount.DiscountTemplate> discountTemplates) {
        if (String.isBlank(targetChargeTerm)) {
            return false;
        }

        for (NGBS_Discount.DiscountTemplate dt : discountTemplates) {
            if (dt.values.containsKey(targetChargeTerm)) {
                return false;
            }
        }

        return true;
    }
}