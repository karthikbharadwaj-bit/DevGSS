public class SWNUpdateLicenseLimitsRunner extends SWNActionRunner {

    public SWNUpdateLicenseLimitsRunner() {}

    public SWNUpdateLicenseLimitsRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        syncLicenseLimits();
    }

    private void syncLicenseLimits() {
        Response overrideLicenseLimitResult = updateLicenseLimits(sdc.qt);
        if (!overrideLicenseLimitResult.isSuccess()) {
            sdc.currentStep.isStepCompletedSuccessfully = false;
        }

        res.messages.addAll(overrideLicenseLimitResult.messages);
    }

    private Response updateLicenseLimits(Quote qt) {
        Response resp = new Response();

        Boolean isPOCQuote = QuoteHelper.isEntitlementPackageOfferTypePOC(qt);
        if (!isPOCQuote) {
            resp.addMessage(SWNHelper.ERROR_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.OVERRIDE_LICENSE_LIMITS_FOR_POC));
            return resp;
        }

        Map<String,List<NGBSAPI.LBoxLimitBrief>> lBoxElementIdToLBoxLimitBriefList = buildLBoxElementIdToLBoxLimitBriefList(qt);
        if (lBoxElementIdToLBoxLimitBriefList.isEmpty()) {
            resp.addMessage(SWNHelper.ERROR_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.LICENSE_LIMITS_OVERRIDE_IF_EXISTS_LBOX_ON_QLI));
            return resp;
        }

        BillingWrappers.QuotePackageInfo packageInfo = QuoteHelper.getPackageInfo(qt);
        if (packageInfo == null) {
            resp.addMessage(SWNHelper.ERROR_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.LICENSE_LIMITS_OVERRIDE_IF_PKG_INFO_ON_QUOTE));
            return resp;
        }

        List<NGBSAPI.LBox> accountLBoxesLimits = getAccountLBoxesLimits(qt.Account.Billing_ID__c, packageInfo.packageInfo.id);

        List<NGBSAPI.LBoxLimitOverride> lBoxLimitOverrideList =
            getLBoxLimitOverrideList(accountLBoxesLimits, lBoxElementIdToLBoxLimitBriefList);

        SWNMessageHelper.SWNMessage licenseLimitsMsg = SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.LICENSE_LIMIT_OVERRIDE_SUCCESS);
        if (lBoxLimitOverrideList.isEmpty()) {
            resp.addMessage(licenseLimitsMsg);
            return resp;
        }

        String body = JSON.serialize(lBoxLimitOverrideList);

        System.debug('License limits override body >>> ' + body);

        HttpResponse httpResponse = NGBSAPI.requestNGBS(
            String.format(
                NGBSAPI.NGBS_LBOX_LIMITS_OVERRIDE,
                new List<String> {qt.Account.Billing_ID__c, packageInfo.packageInfo.id}
            ),
            HttpHelper.METHOD_POST,
            body,
            HTTPHelper.CONTENT_TYPE_APPLICATION_JSON
        );

        if (!HttpHelper.isSuccess(httpResponse)) {
            resp.addMessage(SWNHelper.ERROR_MESSAGES_BUILDER.buildSWNMessage(httpResponse.getBody(), Label.License_limits_override_request_failed, null));
            return resp;
        }

        resp.addMessage(licenseLimitsMsg);
        return resp;
    }

    @TestVisible
    private Map<String,List<NGBSAPI.LBoxLimitBrief>> buildLBoxElementIdToLBoxLimitBriefList(Quote qt) {
        Map<String,List<NGBSAPI.LBoxLimitBrief>> lBoxElementIdToLBoxLimitBriefList =
            new Map<String,List<NGBSAPI.LBoxLimitBrief>>();
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            if (String.isBlank(qli.PackageInfo__c)) {
                continue;
            }

            BillingWrappers.QLIPackageInfo qliPackageInfo = new BillingWrappers.QLIPackageInfo(
                qli.PackageInfo__c
            );
            List<BillingWrappers.LBox> lboxes = qliPackageInfo.lboxes;
            if (lboxes != null && !lboxes.isEmpty()) {
                for (BillingWrappers.LBox lbox : lboxes) {
                    Decimal lboxMax = (Decimal) NumberHelper.getNumberNullSafe(lbox.max);

                    if (!lBoxElementIdToLBoxLimitBriefList.containsKey(lbox.elementID)) {
                        lBoxElementIdToLBoxLimitBriefList.put(lbox.elementID, new List<NGBSAPI.LBoxLimitBrief>());
                    }
                    lBoxElementIdToLBoxLimitBriefList.get(lbox.elementID).add(
                            new NGBSAPI.LBoxLimitBrief(SWNHelper.MAX, lboxMax.intValue())
                    );
                }
            }
        }
        return lBoxElementIdToLBoxLimitBriefList;
    }

    @TestVisible
    private List<NGBSAPI.LBox> getAccountLBoxesLimits(String billingId, String packageId) {
        HttpResponse response = NGBSAPI.requestNGBS(
            String.format(
                NGBSAPI.NGBS_LBOX_LIMITS,
                new List<String> {billingId, packageId}),
            HttpHelper.METHOD_GET);

        if (response.getStatusCode() == 200) {
            return (List<NGBSAPI.LBox>) JSON.deserialize(response.getBody(), List<NGBSAPI.LBox>.class);
        }

        return new List<NGBSAPI.LBox>();
    }

    @TestVisible
    private List<NGBSAPI.LBoxLimitOverride> getLBoxLimitOverrideList(
        List<NGBSAPI.LBox> accountLboxLimits,
        Map<String,List<NGBSAPI.LBoxLimitBrief>> lBoxElementIdToLBoxLimitBriefList
    ) {

        List<NGBSAPI.LBoxLimitOverride> lBoxLimitOverrideList = new List<NGBSAPI.LBoxLimitOverride>();
        for (NGBSAPI.LBox lBox : accountLboxLimits) {
            List<NGBSAPI.LBoxLimitBrief> lBoxLimitsBrief = lBoxElementIdToLBoxLimitBriefList.get(lBox.lboxCatalogId);
            if (lBoxLimitsBrief == null) {
                continue;
            }

            Integer accountLBoxLimit = getMaxAccountLBoxLimitValue(lBox.lboxLimits);
            Integer qliLBoxLimit = getMaxQliLBoxLimitValue(lBoxLimitsBrief);

            if (qliLBoxLimit > accountLBoxLimit) {
                NGBSAPI.LBoxLimitOverride lBoxLimitOverride = new NGBSAPI.LBoxLimitOverride(lBox.id, lBoxLimitsBrief);
                lBoxLimitOverrideList.add(lBoxLimitOverride);
            }
        }
        return lBoxLimitOverrideList;
    }

    @TestVisible
    private Integer getMaxAccountLBoxLimitValue(List<NGBSAPI.LBoxLimit> lboxLimits) {
        Integer maxLBoxValue = 0;
        for (NGBSAPI.LBoxLimit lBoxLimit : lboxLimits) {
            if (lBoxLimit.type == SWNHelper.MAX) {
                maxLBoxValue = lBoxLimit.value;
                break;
            }
        }
        return maxLBoxValue;
    }

    @TestVisible
    private Integer getMaxQliLBoxLimitValue(List<NGBSAPI.LBoxLimitBrief> lBoxLimitsBrief) {
        Integer maxLBoxValue = 0;
        for (NGBSAPI.LBoxLimitBrief limitBrief : lBoxLimitsBrief) {
            if (limitBrief.type == SWNHelper.MAX) {
                maxLBoxValue = limitBrief.value;
                break;
            }
        }
        return maxLBoxValue;
    }

}