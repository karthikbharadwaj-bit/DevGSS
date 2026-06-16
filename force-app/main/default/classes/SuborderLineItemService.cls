@RestResource(urlMapping='/SuborderLineItemService/*')
global without sharing class SuborderLineItemService {

    @HttpPost
    global static void handleRequest() {
        String result = '';
        String body = RestContext.request.requestBody.toString();
        BillingWrappers.SuborderLineItemsParams params = (BillingWrappers.SuborderLineItemsParams) JSON.deserialize(body, BillingWrappers.SuborderLineItemsParams.class);
        RestResponse response = RestContext.response;
        if (response == null) {
            response = new RestResponse();
            RestContext.response = response;
        }
        try {
            if (params.action == 'upsertSuborderLineItems') {
                result = JSON.serialize(upsertSuborderLineItems(
                    params.suborderLineItemsMap,
                    params.suborders,
                    params.orderId,
                    params.quoteId,
                    params.accountLocations
                ));
            }
            if (params.action == 'deleteSuborderLineItems') {
                deleteSuborderLineItems(params.suborderLineItemsMap, params.orderId);
            }
            response.responseBody = Blob.valueOf(result);
        } catch (Exception e) {
            Map<String, String> errorMessage = new Map<String, String>();
            errorMessage.put('error', e.getMessage());
            errorMessage.put('stackTrace', e.getStackTraceString());
            response.responseBody = Blob.valueOf(JSON.serialize(errorMessage));
        }
    }

    @TestVisible
    private static void deleteSuborderLineItems(
        Map<String, List<BillingWrappers.SuborderLineItem>> suborderLineItemMap,
        Id orderId
    ) {
        List<Id> suborderLineItemsToExcludeIds = new List<Id>();
        if (orderId == null) {
            return;
        }

        for(List<BillingWrappers.SuborderLineItem> suborderLineItems : suborderLineItemMap.values()) {
            for(BillingWrappers.SuborderLineItem suborderLineItem : suborderLineItems) {
                suborderLineItemsToExcludeIds.add(suborderLineItem.phaseLineItemId);
            }
        }

        List<SuborderLineItem__c> suborderLineItemsForDelete = (List<SuborderLineItem__c>) new SuborderLineItemSelector()
            .selectSuborderLineItemsForDeleting(new List<Object>{
                suborderLineItemsToExcludeIds,
                new Set<Id>{ orderId }
            })
            .executeQuery();

        if (!suborderLineItemsForDelete.isEmpty()) {
            delete suborderLineItemsForDelete;
        }
    }

    @TestVisible
    private static Map<String, List<BillingWrappers.SuborderLineItem>> upsertSuborderLineItems(
        Map<String, List<BillingWrappers.SuborderLineItem>> suborderLineItemMap,
        List<BillingWrappers.Suborder> suborders,
        String orderId,
        String quoteId,
        List<BillingWrappers.BillingAccountLocation> accountLocations
    ) {
        Set<String> productElementIds = new Set<String>();
        Map<String, String> suborderIdToSuborderUniqueId = new Map<String, String>();

        if (suborderLineItemMap.keySet().isEmpty()) {
            return new Map<String, List<BillingWrappers.SuborderLineItem>>();
        }

        for (BillingWrappers.Suborder suborder: suborders) {
            if (!suborderLineItemMap.containsKey(suborder.uniqueId)) {
                continue;
            }
            for (BillingWrappers.SuborderLineItem suborderLineItem : suborderLineItemMap.get(suborder.uniqueId)) {
                productElementIds.add(suborderLineItem.productElementId);
            }
            suborderIdToSuborderUniqueId.put(suborder.phaseId, suborder.uniqueId);
        }

        Map<String, QuoteLineItem> quoteLineItemsMap = getElementIdToQuoteLineItemMap(quoteId, productElementIds);
        List<SuborderLineItem__c> suborderLineItemsToInsert = prepareSuborderLineItemsToInsert(
            suborders,
            suborderLineItemMap,
            quoteLineItemsMap
        );

        if (!suborderLineItemsToInsert.isEmpty()) {
            upsert suborderLineItemsToInsert;
        }

        List<Id> suborderLineItemsIdsForReselect = new List<Id>();
        for (SuborderLineItem__c suborderLineItem : suborderLineItemsToInsert) {
            suborderLineItemsIdsForReselect.add(suborderLineItem.Id);
        }

        Map<String, List<BillingWrappers.SuborderLineItem>> suborderUniqueIdToLinkedSLI = prepareSuborderUniqueIdToSuborderLineItemsMap(
            suborderLineItemsIdsForReselect,
            suborderIdToSuborderUniqueId,
            accountLocations
        );

        return suborderUniqueIdToLinkedSLI;
    }

    private static List<SuborderLineItem__c> prepareSuborderLineItemsToInsert(
        List<BillingWrappers.Suborder> suborders,
        Map<String, List<BillingWrappers.SuborderLineItem>> suborderLineItemMap,
        Map<String, QuoteLineItem> quoteLineItemsMap
    ) {
        List<SuborderLineItem__c> suborderLineItemsToInsert = new List<SuborderLineItem__c>();
        for (BillingWrappers.Suborder suborder: suborders) {
            if (!suborderLineItemMap.containsKey(suborder.uniqueId)) {
                continue;
            }
            for (BillingWrappers.SuborderLineItem suborderLineItemWrapper : suborderLineItemMap.get(suborder.uniqueId)) {
                QuoteLineItem quoteLineItem = quoteLineItemsMap.get(suborderLineItemWrapper.productElementId);
                if (quoteLineItem == null) {
                    continue;
                }
                suborderLineItemsToInsert.add(buildSuborderLineItem(suborderLineItemWrapper, quoteLineItem, suborder.phaseId));
            }
        }
        return suborderLineItemsToInsert;
    }

    private static Map<String, List<BillingWrappers.SuborderLineItem>> prepareSuborderUniqueIdToSuborderLineItemsMap(
        List<Id> suborderItemsIdsForReselect,
        Map<String, String> suborderIdToSuborderUniqueId,
        List<BillingWrappers.BillingAccountLocation> accountLocations
    ) {
        Map<String, List<BillingWrappers.SuborderLineItem>> suborderUniqueIdToLinkedSLI = new Map<String, List<BillingWrappers.SuborderLineItem>>();

        List<SuborderLineItem__c> suborderItemsForReselect = (List<SuborderLineItem__c>) new SuborderLineItemSelector()
            .selectSuborderLineItemsByIds(suborderItemsIdsForReselect)
            .executeQuery();

        for (SuborderLineItem__c suborderLineItem : suborderItemsForReselect) {
            String phaseUniqueId = suborderIdToSuborderUniqueId.get(suborderLineItem.Suborder__c);
            BillingWrappers.SuborderLineItem suborderLineItemWrapper = new BillingWrappers.SuborderLineItem();
            suborderLineItemWrapper.phaseLineItemId = suborderLineItem.Id;
            suborderLineItemWrapper.quantity = Integer.valueOf(suborderLineItem.Quantity__c);
            suborderLineItemWrapper.productElementId = suborderLineItem.SalesAgreementLineItem__r.Product_Lic_Id__c;
            suborderLineItemWrapper.locations = getSuborderLineItemLocations(suborderLineItem, accountLocations);
            if (suborderUniqueIdToLinkedSLI.containsKey(phaseUniqueId)) {
                suborderUniqueIdToLinkedSLI.get(phaseUniqueId).add(suborderLineItemWrapper);
            } else {
                suborderUniqueIdToLinkedSLI.put(phaseUniqueId, new List<BillingWrappers.SuborderLineItem>{
                    suborderLineItemWrapper
                });
            }
        }
        return suborderUniqueIdToLinkedSLI;
    }

    public static List<BillingWrappers.SuborderLineItemLocation> getSuborderLineItemLocations (
        SuborderLineItem__c suborderLineItem,
        List<BillingWrappers.BillingAccountLocation> accountLocations
    ) {
        List<BillingWrappers.SuborderLineItemLocation> locations = (List<BillingWrappers.SuborderLineItemLocation>) JSON.deserialize(
            suborderLineItem.LocationDetails__c,
            List<BillingWrappers.SuborderLineItemLocation>.class
        );

        for (BillingWrappers.SuborderLineItemLocation location : locations) {
            for (BillingWrappers.BillingAccountLocation accountLocation : accountLocations) {
                if (location.billingLocationId == accountLocation.accountId) {
                    location.locationId = accountLocation.uniqueId;
                }
            }
        }

        return locations;
    }

    public static Map<String, QuoteLineItem> getElementIdToQuoteLineItemMap(
        Id quoteId,
        Set<String> productElementIds
    ) {
        List<QuoteLineItem> quoteLineItems = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdAndProductLic(new List<Object>{
                new List<String> {quoteId},
                productElementIds
            })
            .executeQuery();

        Map<String, QuoteLineItem> quoteLineItemsMap = new Map<String, QuoteLineItem>();
        for (QuoteLineItem quoteLineItem : quoteLineItems) {
            quoteLineItemsMap.put(quoteLineItem.Product_Lic_Id__c, quoteLineItem);
        }

        return quoteLineItemsMap;
    }

    private static SuborderLineItem__c buildSuborderLineItem(
        BillingWrappers.SuborderLineItem suborderLineItemWrapper,
        QuoteLineItem quoteLineItem,
        String suborderId
    ) {
        SuborderLineItem__c suborderLineItem = new SuborderLineItem__c();
        suborderLineItem.Id = suborderLineItemWrapper.phaseLineItemId;
        suborderLineItem.Quantity__c = suborderLineItemWrapper.quantity;
        suborderLineItem.Suborder__c = suborderId;
        suborderLineItem.SalesAgreementLineItem__c = quoteLineItem.Id;
        suborderLineItem.CurrencyIsoCode = quoteLineItem.CurrencyIsoCode;
        suborderLineItem.Name = quoteLineItem.Product2.Name;
        suborderLineItem.LocationDetails__c = JSON.serialize(suborderLineItemWrapper.locations);
        return suborderLineItem;
    }
}