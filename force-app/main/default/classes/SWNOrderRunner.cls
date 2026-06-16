public class SWNOrderRunner extends SWNActionRunner {
    @TestVisible
    private static final String ORDERS = 'orders';
    private static final String ID = 'id';
    private static final String INVOICE = 'invoice';
    @TestVisible
    private static final String QUOTE_ALREADY_SYNCED = 'This quote already synced with NGBS';
    @TestVisible
    private static final String ERROR_DURING_ORDER_SYNC = 'An error occurred during applying orders';

    @TestVisible
    private SWNOrderRunner() {}

    public SWNOrderRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    protected override void run() {
        syncOrder();
    }

    @TestVisible
    private void syncOrder() {
        if (!SWNHelper.isLBOOrOfficeProductSelected(sdc.qt)) {
            return;
        }

        if (sdc.syncable.isOrderStepCompleted() || sdc.qt.InvoiceId__c != null) {
            isSkipFinalize = true;
            return;
        }

        callOrderAPI(sdc);

        if (!res.isError()) {
            sdc.syncable.setOrderDate(System.today());
            sdc.currentStep.quoteFieldsToUpdate.put(Quote.Id.toString(), sdc.qt.Id);
            sdc.currentStep.quoteFieldsToUpdate.put(Quote.InvoiceId__c.toString(), (String) res.data.get(ORDERS));

            DealDeskCaseGenerator.createCase(sdc.qt, sdc.opp, false, null, sdc.syncable);
        } else {
            sdc.currentStep.isStepCompletedSuccessfully = false;
        }
    }

    @TestVisible
    private void callOrderAPI(SWNDataCollector sdc) {
        NGBSOrderRequest.OrderRequestInfo ori = validateCallOrderAPI(sdc);
        if (ori?.salesOrderId == null) {
            return;
        }

        String body = JSON.serialize(ori);
        HttpResponse response = requestNGBS(sdc, body);
        handleResponse(response);
    }

    @TestVisible
    private void handleResponse(HttpResponse response) {
        if (response?.getStatusCode() != 200) {
            res.info(ERROR_DURING_ORDER_SYNC);
            return;
        }
        Map<String,Object> billingResponse = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
        Map<String,Object> invoiceResponse = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(billingResponse.get(INVOICE)));
        res.setData(ORDERS, String.valueOf(invoiceResponse.get(ID)));
    }

    @TestVisible
    private HttpResponse requestNGBS(SWNDataCollector sdc, String body) {
        String url = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/' + sdc.billingId +'/purchase/'+ sdc.packageId +'/order/v2';
        return NGBSAPI.requestNGBS(url, HttpHelper.METHOD_POST, body, HTTPHelper.CONTENT_TYPE_APPLICATION_JSON);
    }

    @TestVisible
    private NGBSOrderRequest.OrderRequestInfo validateCallOrderAPI(SWNDataCollector sdc) {
        if (!hasAccessToCallOrder(sdc.qt.QuoteLineItems)) {
            handleException(CaseHelper.CASE_REASON_PERMISSION, null, true);
            return null;
        }

        // reselection quote added to prevent double transactions to order API
        Quote reselectQuote = SWNHelper.selectQuoteByIdWithExactField(sdc.qt.Id, Quote.InvoiceId__c);
        if (reselectQuote.InvoiceId__c != null) {
            res.info(QUOTE_ALREADY_SYNCED);
            return null;
        }

        return getNGBSOrderInfo(sdc);
    }

    @TestVisible
    private NGBSOrderRequest.OrderRequestInfo getNGBSOrderInfo(SWNDataCollector sdc) {
        List<BillingWrappers.BillingInfoSummaryLicense> licenses = NGBSAPI.getNGBSBillingInfoSummaryLicenses(sdc.billingId, sdc.packageId);
        Map<String, BillingWrappers.BillingInfoSummaryLicense> licenseMap = SWNHelper.getLicenseMap(licenses);
        List<String> bypassLicenses = QuoteLineItemHelper.getLicensesForPurchaseBypass(sdc.opp.BusinessIdentity__c);

        return new NGBSOrderRequest.OrderRequestInfo(
            sdc.qt,
            collectQliIds(sdc.qt),
            getExceptionMap(sdc, bypassLicenses),
            licenseMap,
            sdc.billingId,
            sdc.packageId,
            bypassLicenses
        );
    }

    private Map<String, String> getExceptionMap(SWNDataCollector sdc, List<String> bypassLicenses) {
        if (sdc.qt.QuoteLineItems.isEmpty()) {
            return new Map<String, String>();
        }
        return getLBOBillingExceptionsWithLabels(sdc.qt.BusinessIdentity__c, sdc.qt.QuoteLineItems, bypassLicenses);
    }

    @TestVisible
    private Set<Id> collectQliIds(Quote qt) {
        Set<Id> qliIds = new Set<Id>();
        if (QuoteHelper.isEngageTerminationQuote(qt)) {
            return qliIds;
        }

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qliIds.add(qli.Id);
        }

        return qliIds;
    }

    @TestVisible
    private Boolean hasAccessToCallOrder(List<QuoteLineItem> qlis) {
        if (Schema.SObjectType.CustomAddress__c.isAccessible() && Schema.SObjectType.CustomAddressAssignments__c.isAccessible()) {
            return true;
        }

        for (QuoteLineItem qli : qlis) {
            Boolean isShippingAvailableForLicense = Product2Helper.isShippingTypeAuto(qli.Product2);
            if (isShippingAvailableForLicense && !qli.Zero_Quantity__c && qli.Quantity > 0) {
                return false;
            }
        }
        return true;
    }

    @TestVisible
    private Map<String, String> getLBOBillingExceptionsWithLabels(String businessIdentity, List<QuoteLineItem> qlis, List<String> bypassLicenses) {
        List<LicensesLabelsOverride__c> licensesLabelsOverrideSettings = Product2Helper.getLicensesLabelsOverridesForBusinessIdentity(businessIdentity);

        Map <String, String> exceptionMap = SWNHelper.getLBOBillingExceptions(qlis, bypassLicenses);
        for (QuoteLineItem qli : qlis) {
            if (!isOrderingAvailable(qli, licensesLabelsOverrideSettings)) {
                BillingWrappers.QLIPackageInfo qliPackage = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
                exceptionMap.put(qli.Product_Lic_Id__c, qliPackage.CategoryCode);
            }
        }

        return exceptionMap;
    }

    @TestVisible
    private Boolean isOrderingAvailable(QuoteLineItem qli, List<LicensesLabelsOverride__c> licensesLabelsOverrideSettings) {
        if (qli == null) {
            return false;
        }

        return !Product2Helper.isUpsellTypeManual(qli.Product2, licensesLabelsOverrideSettings)
            || Product2Helper.isUpsellTypeAuto(qli.Product2, licensesLabelsOverrideSettings)
            || String.isEmpty(qli.Product2?.UpsellType__c);
    }
}