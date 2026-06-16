public class SWNProServSyncDiscountRunner extends SWNSyncDiscountRunner {
    public SWNProServSyncDiscountRunner(Id quoteId, String action, String billingId, String billingPackageId) {
        super(quoteId, action, billingId, billingPackageId);
    }

    @TestVisible
    protected override void syncDiscount() {
        isSkipFinalize = true;

        Response discountResp = processDiscounts_new();
        res.messages.addAll(discountResp.messages);

        NGBS_Discount.syncDiscountsForELA(sdc.qt);
    }
}