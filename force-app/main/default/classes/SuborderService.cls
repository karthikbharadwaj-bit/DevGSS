@RestResource(urlMapping='/SuborderService/*')
global without sharing class SuborderService{

    @HttpPost
    global static void handleRequest() {
        String result = '';
        String body = RestContext.request.requestBody.toString();
        BillingWrappers.SubordersParams params = (BillingWrappers.SubordersParams)JSON.deserialize(body, BillingWrappers.SubordersParams.class);
        RestResponse response = RestContext.response;
        if (response == null) {
            response = new RestResponse();
            RestContext.response = response;
        }
        try {
            if (params.action == 'getSuborders') {
                result = JSON.serialize(getSubordersWihSuborderLineItems(params.orderId));
            }
            if (params.action == 'deleteSuborders') {
                deleteSuborders(params.suborders, params.orderId);
            }
            if (params.action == 'upsertSuborders') {
                result = JSON.serialize(upsertSuborders(params.suborders));
            }
            if (params.action == 'lockSuborders') {
                result = JSON.serialize(lockSuborders(params.orderId));
            }
            if (params.action == 'sendPaymentInformation') {
                sendPaymentInformation(params.suborderId, params.opportunityId, params.billingAccountId, params.billingPackageId, params.quoteNumber);
            }
            response.responseBody = Blob.valueOf(result);
        } catch(Exception e) {
            Map<String,String> errorMessage = new Map<String,String>();
            errorMessage.put('error', e.getMessage());
            errorMessage.put('stackTrace', e.getStackTraceString());
            response.responseBody = Blob.valueOf(JSON.serialize(errorMessage));
        }
    }

    @TestVisible
    private static List<Suborder__c> getSubordersWihSuborderLineItems(Id orderId) {
        List<Suborder__c> suborders = new SuborderSelector()
            .selectSubordersByOrderId(orderId)
            .executeQuery();
        return suborders;
    }

    @TestVisible
    private static void deleteSuborders(List<BillingWrappers.Suborder> suborders, Id orderId) {
        Set<Id> suborderIds = new Set<Id>();
        if (orderId == null) {
            return;
        }
        for (BillingWrappers.Suborder suborderWraper : suborders) {
            if (suborderWraper.phaseId != null) {
                suborderIds.add(suborderWraper.phaseId);
            }
        }

        List<Suborder__c> linkedSuborderToOrder = (List<Suborder__c>)new SuborderSelector()
            .selectSubordersByOrderId(orderId)
            .executeQuery();

        List<Suborder__c> suborderToDelete = new List<Suborder__c>();
        for (Suborder__c suborder : linkedSuborderToOrder) {
            if (!suborderIds.contains(suborder.Id)) {
                suborderToDelete.add(suborder);
            }
        }

        if (!suborderToDelete.isEmpty() ) {
            delete suborderToDelete;
        }
    }

    @TestVisible
    private static Map<String, Suborder__c> upsertSuborders(List<BillingWrappers.Suborder> suborders) {
        Map<Integer, String> suborderNumberToUniqId = new Map<Integer, String>();
        List<Suborder__c> subordersListToUpsert = new List<Suborder__c>();
        Set<Id> orderIds = new Set<Id>();

        if (suborders.isEmpty()) {
            return new Map<String, Suborder__c>();
        }

        for (BillingWrappers.Suborder suborderWraper : suborders) {
            subordersListToUpsert.add(buildSuborder(suborderWraper));
            orderIds.add(suborderWraper.orderId);
            suborderNumberToUniqId.put(suborderWraper.phaseNumber, suborderWraper.uniqueId);
        }

        upsert subordersListToUpsert;

        return getPhaseUniqIdToPhaseMap(suborderNumberToUniqId, orderIds);
    }

    private static Map<String, Suborder__c> getPhaseUniqIdToPhaseMap(Map<Integer, String> suborderNumberToUniqId, Set<Id> orderIds) {
        Map<String, Suborder__c> suborderUniqIdToSuborder = new Map<String, Suborder__c>();
        List<Suborder__c> reselectedSuborders = new SuborderSelector()
            .selectSubordersByOrdersIds(orderIds)
            .executeQuery();

        if (!reselectedSuborders.isEmpty()) {
            for (Suborder__c suborder : reselectedSuborders) {
                if (suborderNumberToUniqId.containsKey((Integer) suborder.SuborderNumber__c)) {
                    suborderUniqIdToSuborder.put(suborderNumberToUniqId.get((Integer) suborder.SuborderNumber__c), suborder);
                }
            }
        }
        return suborderUniqIdToSuborder;
    }

    private static Suborder__c buildSuborder(BillingWrappers.Suborder suborderWrapper) {
        Suborder__c suborder = new Suborder__c();
        suborder.Id = suborderWrapper.phaseId;
        suborder.Order__c = suborderWrapper.orderId;
        suborder.Status__c = suborderWrapper.status;
        suborder.CurrencyIsoCode = suborderWrapper.currencyIsoCode;
        suborder.SuborderNumber__c = suborderWrapper.phaseNumber;
        suborder.SignoffLink__c = suborderWrapper.signoffLink;
        suborder.RevenueCategory__c = suborderWrapper.revenueCategory;
        suborder.Suborder_Type__c = suborderWrapper.phaseType;
        suborder.Name = String.isNotBlank(suborderWrapper.orderNumber) ? 
                            SuborderHelper.buildSuborderNumber(suborderWrapper.orderNumber, String.valueOf(suborderWrapper.phaseNumber)) : 
                            String.valueOf(suborderWrapper.phaseNumber);
        if (!String.isBlank(suborderWrapper.billingMethod)) {
            suborder.BillingMethod__c = suborderWrapper.billingMethod;
        }
        if (!String.isBlank(suborderWrapper.billingDate)) {
            suborder.BillingDate__c = Date.valueOf(suborderWrapper.billingDate);
        }
        return suborder;
    }

    @TestVisible
    private static List<Suborder__c> lockSuborders(Id orderId) {
        List<Suborder__c> suborders = new SuborderSelector()
            .selectNotBilledSubordersByOrderId(orderId)
            .executeQuery();

        if (!suborders.isEmpty()) {
            for (Suborder__c suborder : suborders) {
                suborder.Status__c = SuborderHelper.STATUS_LOCKED;
            }
            update suborders;
        }

        return suborders;
    }

    @TestVisible
    private static void sendPaymentInformation(String suborderId, String opportunityId, String billingAccountId, String billingPackageId, String quoteNumber) {
        Suborder__c suborder = (Suborder__c) new ListOptional(new SuborderSelector()
            .selectSuborderBySuborderId(suborderId)
            .executeQuery()
        ).getFirst();
        List<BillingWrappers.PaymentOrderItem> paymentOrderItems = new List<BillingWrappers.PaymentOrderItem>();
        if (suborder != null) {
            List<SuborderLineItem__c> subordersLineItems = (List<SuborderLineItem__c>) new SuborderLineItemSelector()
                .selectSuborderLineItemsBySuborderIds(new Set<Id>{suborder.Id})
                .executeQuery();
            for (SuborderLineItem__c suborderLineItem : subordersLineItems) {
                List<BillingWrappers.SuborderLineItemLocation> locations = (List<BillingWrappers.SuborderLineItemLocation>) JSON.deserialize(
                    suborderLineItem.LocationDetails__c,
                    List<BillingWrappers.SuborderLineItemLocation>.class
                );
                for (BillingWrappers.SuborderLineItemLocation location : locations) {
                    paymentOrderItems.add(SuborderHelper.buildPaymentOrderItem(suborderLineItem, location));
                }
            }
        }
        if (!paymentOrderItems.isEmpty()) {
            NGBSAPI.sendPaymentInfo(opportunityId, billingAccountId, billingPackageId, paymentOrderItems, suborderId, quoteNumber);
        }
    }
}