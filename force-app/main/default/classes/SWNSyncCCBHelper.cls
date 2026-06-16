public with sharing class SWNSyncCCBHelper {
    @TestVisible
    private static final String SYNC_CCB_HEADER_SUCCESS_MESSAGE = 'Sync with CCB succeeded';
    @TestVisible
    private static final String HEADER_KEY = 'header';
    @TestVisible
    private static final String STATUS_KEY = 'status';
    @TestVisible
    private static final String SUCCESS_STATUS = 'success';

    public static Response syncCCB(Quote qt, String syncStep, Boolean isMPUB, List<Cost_Center__c> costCenters) {
        POWrappers.SignUpParams data = collectAndTransformData(qt, isMPUB);
        List<QuoteLineItem> filteredQliList = getFilteredQlis(qt, syncStep, costCenters);

        Map<String, SubscriberInfoBuilder.AssignmentData[]> filtered = SubscriberInfoBuilder.getAssignmentsFilterByLimits(
            filteredQliList,
            data.areaCodeLineItems,
            data.assignementLineItem,
            new Map<Id, QuoteLineItem>(filteredQliList),
            new Map<Id, Area_Codes__c>(data.areaCodes),
            data.targetQuote,
            null,
            null,
            data.opportunity.BusinessIdentity__c,
            null
        );
        data.assignmentsToSignUp = filtered.get('auto');
        data.assignmentsToManual = filtered.get('manual');

        POSignUpBodyHelper.SignUpBodyBuilder signUpBodyBuilder = new POSignUpBodyHelper.SignUpBodyBuilder();
        POWrappers.SignUpRequestBody body = signUpBodyBuilder.buildBody(data);

        String bodyString = getBodyString(body.requestBodyMap);

        Response syncResult;
        if (POHelper.isEngageUILessSettingsOn) {
            syncResult = syncWithFunnel(data.targetQuote, bodyString);
        } else {
            POSignUp.UISignUP defaultSignUp = new POSignUp.UISignUP(data.targetQuote, bodyString);
            syncResult = defaultSignUp.proceedDefaultSignUp();
        }

        return syncResult;
    }

    @TestVisible
    private static String getBodyString(Map<String, Object> requestBodyMap) {
        return POHelper.isEngageUILessSettingsOn
            ? JSON.serialize(requestBodyMap)
                .replaceAll('isOverride', 'override')
                .replaceAll('limitType', 'type')
            : new POSignUp.EngageSignUpRunner().toStringURL(requestBodyMap);
    }

    @TestVisible
    private static List<QuoteLineItem> getFilteredQlis(Quote qt, String syncStep, List<Cost_Center__c> costCenters) {
        switch on SWNStep.SYNC_STEP.valueOf(syncStep) {
            when UPGRADE {
                return handleUpgrade(qt.QuoteLineItems);
            }
            when UP_SELL {
                return handleUpsell(qt.QuoteLineItems);
            }
            when DOWN_SELL {
                return handleDownsell(qt, costCenters);
            }
            when else {
                return new List<QuoteLineItem>();
            }
        }
    }

    private static List<QuoteLineItem> handleUpgrade(List<QuoteLineItem> qlis) {
        List<QuoteLineItem> filteredQliList = new List<QuoteLineItem>();
        for (QuoteLineItem qli : qlis) {
            if (qli.NewQuantity__c > 0) {
                filteredQliList.add(qli);
            }
        }
        return filteredQliList;
    }

    private static List<QuoteLineItem> handleUpsell(List<QuoteLineItem> qlis) {
        List<QuoteLineItem> filteredQliList = new List<QuoteLineItem>();
        for (QuoteLineItem qli : qlis) {
            if (qli.NewQuantity__c != 0) {
                filteredQliList.add(qli);
            }
        }
        return filteredQliList;
    }

    private static List<QuoteLineItem> handleDownsell(Quote qt, List<Cost_Center__c> costCenters) {
        List<QuoteLineItem> filteredQliList = new List<QuoteLineItem>();
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            Decimal entQty = qli.Entitlement__r?.Quantity__c ?? 0;
            Decimal qliQty = qli.NewQuantity__c;

            // Specific case: existing items (which are not changed or upselled) should be sent with existing quantity
            if (entQty != 0 && qliQty >= entQty) {
                QuoteLineItem qliCloned = qli.clone(true);
                qliCloned.NewQuantity__c = entQty;
                filteredQliList.add(qliCloned);
            }

        }
        filteredQliList.addAll(getCcbDownsellQLIs(qt, costCenters));
        return filteredQliList;
    }

    private static List<QuoteLineItem> getCcbDownsellQLIs(Quote qt, List<Cost_Center__c> costCenters) {
        List<QuoteLineItem> downsellQLIs = new List<QuoteLineItem>();
        Map<Id, QuoteLineItem> qlisForSimplifiedAutoDownsellMap = new Map<Id, QuoteLineItem>();

        if (SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedDownsellForRingCX__c) {
            Map<String, List<QuoteLineItem>> dowsellTypeToQlisMap = SWNHelper.getQliTypesForSimplifiedLBODownsell(qt, qt.QuoteLineItems, costCenters);
            qlisForSimplifiedAutoDownsellMap = new Map<Id, QuoteLineItem>(SWNHelper.getQlisForAutoDownsell(dowsellTypeToQlisMap));
        }

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            Decimal entQty = qli.Entitlement__r?.Quantity__c ?? 0;
            Decimal qliQty = qli.NewQuantity__c ?? 0;

            if (qliQty != 0 && entQty > qliQty && (!SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedDownsellForRingCX__c || qlisForSimplifiedAutoDownsellMap.containsKey(qli.Id))) {
                downsellQLIs.add(qli);
            }
        }

        return downsellQLIs;
    }

    @TestVisible
    private class SyncWithFunnelParams {
        public String endpoint;
        public HttpResponse res;

        @TestVisible
        private SyncWithFunnelParams() {}

        public SyncWithFunnelParams(Quote qt, String body) {
            if (QuoteHelper.isEngage(qt)) {
                this.doCcbPost(body);
            }
        }

        private void doCcbPost(String body) {
            this.endpoint = CCBAPI.CCB_SETTINGS.BaseEndpoint__c + CCBAPI.CCB_SETTINGS.ChangePath__c;
            this.res = CCBAPI.requestCCB(endpoint, HttpHelper.METHOD_POST, body);
        }
    }

    @TestVisible
    private static Response syncWithFunnel(Quote qt, String body) {
        Response resp = new Response();
        SyncWithFunnelParams params = new SyncWithFunnelParams(qt, body);

        if (HttpHelper.isSuccess(params.res)) {
            resp.setData(STATUS_KEY, SUCCESS_STATUS);
            resp.setData(HEADER_KEY, SYNC_CCB_HEADER_SUCCESS_MESSAGE);
        } else {
            try {
                resp.error(
                    CCBAPI.SYNC_CCB_FAILED,
                    buildSyncWithFunnelErrorMessage(params.res)
                );
            } catch (Exception e) {
                AquivaHelper.throwAquivaException(CCBAPI.REQUEST_CCB_EXCEPTION_MESSAGE + buildSyncWithFunnelExceptionMessage(params));
            }
        }

        return resp;
    }

    @TestVisible
    private static String buildSyncWithFunnelExceptionMessage(SyncWithFunnelParams params) {
        HttpResponse httpResp = params.res;
        return String.join(new List<String> {
            String.isNotBlank(httpResp.getStatus()) ? httpResp.getStatus() + '. Please Contact Your Administrator.' : '',
            String.isNotBlank(httpResp.getBody()) ? 'Technical Details: ' + httpResp.getBody() + '.' : '',
            'Request endpoint: ' + params.endpoint
        }, '\n').trim();
    }

    @TestVisible
    private static String buildSyncWithFunnelErrorMessage(HttpResponse httpResp) {
        List<String> errs = new List<String>();
        BillingWrappers.EngageCCBTerminationResponseParams responseParams = (BillingWrappers.EngageCCBTerminationResponseParams) JSON.deserialize(
            httpResp.getBody(),
            BillingWrappers.EngageCCBTerminationResponseParams.class
        );

        for (BillingWrappers.EngageTerminationMessages mes : responseParams.messages) {
            if (String.isNotBlank(mes.message)) {
                errs.add(mes.message);
            }

            if (String.isNotBlank(mes.messageDetails)) {
                errs.add(mes.messageDetails);
            }
        }
        return String.join(errs, '\n');
    }

    @TestVisible
    private static POWrappers.SignUpParams collectAndTransformData(Quote qt, Boolean isMPUB) {
        Set<Id> targetIdSet = new Set<Id> {qt.Id, qt.MasterQuote__c};
        // Single ED does not have master quote
        targetIdSet.remove(null);

        PODataCollector dataCollector = isMPUB
            ? new PODataCollector.OrderBasedDC(targetIdSet).collectData()
            : new PODataCollector.QuoteBasedDC(targetIdSet).collectData();

        Response response = dataCollector.transformData()[0];

        POWrappers.SignUpParams data = (POWrappers.SignUpParams) JSON.deserialize(
            JSON.serialize(response.data),
            POWrappers.SignUpParams.class
        );

        return data;
    }
}