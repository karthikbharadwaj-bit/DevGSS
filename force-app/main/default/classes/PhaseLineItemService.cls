@RestResource(urlMapping='/PhaseLineItemService/*')
global without sharing class PhaseLineItemService{

    @HttpPost
    global static void handleRequest() {
        String result = '';
        String body = RestContext.request.requestBody.toString();
        BillingWrappers.PhaseLineItemsParams params = (BillingWrappers.PhaseLineItemsParams) JSON.deserialize(body, BillingWrappers.PhaseLineItemsParams.class);
        RestResponse response = RestContext.response;
        if (response == null) {
            response = new RestResponse();
            RestContext.response = response;
        }
        try {
            if (params.action == 'upsertPhaseLineItems') {
                result = JSON.serialize(upsertPhaseLineItems(params.phaseLineItemsMap, params.phases, params.selectedQuoteId));
            }
            if (params.action == 'deletePhaseLineItems') {
                deletePhaseLineItems(params.phaseLineItemsMap, params.selectedQuoteId);
            }
            if (params.action == 'createPhaseLineItemsForChangeOrder') {
                createPhaseLineItemsForChangeOrder(params.orderId, params.selectedQuoteId);
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
    private static Map<String, List<BillingWrappers.PhaseLineItem>> upsertPhaseLineItems(
        Map<String, List<BillingWrappers.PhaseLineItem>> phaseLineItemMap,
        List<BillingWrappers.Phase> phases,
        String selectedQuoteId
    ) {
        Set<String> productElementIds = new Set<String>();
        Map<String, String> phaseIdToPhaseUniqueId = new Map<String, String>();

        if (phaseLineItemMap.keySet().isEmpty()) {
            return new Map<String, List<BillingWrappers.PhaseLineItem>>();
        }

        for (BillingWrappers.Phase phase: phases) {
            if (!phaseLineItemMap.containsKey(phase.uniqueId)) {
                continue;
            }
            for (BillingWrappers.PhaseLineItem phaseLineItem : phaseLineItemMap.get(phase.uniqueId)) {
                productElementIds.add(phaseLineItem.productElementId);
            }
            phaseIdToPhaseUniqueId.put(phase.phaseId, phase.uniqueId);
        }

        Map<String, QuoteLineItem> quoteLineItemsMap = getElementIdToQuoteLineItemMap(selectedQuoteId, productElementIds);
        List<Hardware_Line_Item__c> phaseLineItemsToInsert = preparePhaseLineItemsToInsert(
            phases,
            phaseLineItemMap,
            quoteLineItemsMap
        );

        if (!phaseLineItemsToInsert.isEmpty()) {
            upsert phaseLineItemsToInsert;
        }

        List<Id> phaseLineItemsIdsForReselect = new List<Id>();
        for (Hardware_Line_Item__c phaseLineItem : phaseLineItemsToInsert) {
            phaseLineItemsIdsForReselect.add(phaseLineItem.Id);
        }

        Map<String, List<BillingWrappers.PhaseLineItem>> phaseUniqueIdToLinkedPLI = preparePhaseUniqueIdToPhaseLineItemsMap(
            phaseLineItemsIdsForReselect,
            phaseIdToPhaseUniqueId
        );

        return phaseUniqueIdToLinkedPLI;
    }

    @TestVisible
    private static void deletePhaseLineItems(
        Map<String, List<BillingWrappers.PhaseLineItem>> phaseLineItemMap,
        Id selectedQuoteId
    ) {
        List<Id> phaseLineItemsToExcludeIds = new List<Id>();
        if (selectedQuoteId == null) {
            return;
        }

        for(List<BillingWrappers.PhaseLineItem> phaseLineItems : phaseLineItemMap.values()) {
            for(BillingWrappers.PhaseLineItem phaseLineItem : phaseLineItems) {
                phaseLineItemsToExcludeIds.add(phaseLineItem.phaseLineItemId);
            }
        }

        List<Hardware_Line_Item__c> phaseLineItemsForDelete = (List<Hardware_Line_Item__c>) new HardwareLineItemSelector()
            .selectPhaseLineItemsForDeleting(new List<Object>{
                phaseLineItemsToExcludeIds,
                new Set<Id>{ selectedQuoteId }
            })
            .executeQuery();

        if (!phaseLineItemsForDelete.isEmpty()) {
            delete phaseLineItemsForDelete;
        }
    }

    private static List<Hardware_Line_Item__c> preparePhaseLineItemsToInsert(
        List<BillingWrappers.Phase> phases,
        Map<String, List<BillingWrappers.PhaseLineItem>> phaseLineItemMap,
        Map<String, QuoteLineItem> quoteLineItemsMap
    ) {
        List<Hardware_Line_Item__c> phaseLineItemsToInsert = new List<Hardware_Line_Item__c>();
        Map<String, Map<String, Decimal>> phaseIdToExistingQuantityMap = getPhaseIdToExistingQuantityMap(phases);
        for (BillingWrappers.Phase phase: phases) {
            if (!phaseLineItemMap.containsKey(phase.uniqueId)) {
                continue;
            }
            for (BillingWrappers.PhaseLineItem phaseLineItem : phaseLineItemMap.get(phase.uniqueId)) {
                QuoteLineItem quoteLineItem = quoteLineItemsMap.get(phaseLineItem.productElementId);
                if (quoteLineItem == null) {
                    continue;
                }
                Hardware_Line_Item__c hardLineItem = buildPhaseLineItem(
                    phaseLineItem.quantity,
                    phase.phaseId,
                    quoteLineItem,
                    quoteLineItem.CurrencyIsoCode
                );
                hardLineItem.Id = phaseLineItem.phaseLineItemId;
                hardLineItem.ExistingQuantity__c = getExistingQuantityForPhaseLineItem(phaseLineItem, phase, phaseIdToExistingQuantityMap);
                phaseLineItemsToInsert.add(hardLineItem);
            }
        }
        return phaseLineItemsToInsert;
    }

    private static Map<String, List<BillingWrappers.PhaseLineItem>> preparePhaseUniqueIdToPhaseLineItemsMap(
        List<Id> phaseLineItemsIdsForReselect,
        Map<String, String> phaseIdToPhaseUniqueId
    ) {
        Map<String, List<BillingWrappers.PhaseLineItem>> phaseUniqueIdToLinkedPLI = new Map<String, List<BillingWrappers.PhaseLineItem>>();

        List<Hardware_Line_Item__c> phaseLineItemsForReselect = (List<Hardware_Line_Item__c>) new HardwareLineItemSelector()
            .selectPhaseLineItemsByIds(new List<Object>{
                phaseLineItemsIdsForReselect
            })
            .executeQuery();

        for (Hardware_Line_Item__c phaseLineItem : phaseLineItemsForReselect) {
            String phaseUniqueId = phaseIdToPhaseUniqueId.get(phaseLineItem.RingCentral_Hardware_Phase__c);
            BillingWrappers.PhaseLineItem phaseLineItemWrapper = new BillingWrappers.PhaseLineItem();
            phaseLineItemWrapper.phaseLineItemId = phaseLineItem.Id;
            phaseLineItemWrapper.quantity = Integer.valueOf(phaseLineItem.Quantity__c);
            phaseLineItemWrapper.productElementId = phaseLineItem.Quote_Line_Item__r.Product_Lic_Id__c;
            if (phaseUniqueIdToLinkedPLI.containsKey(phaseUniqueId)) {
                phaseUniqueIdToLinkedPLI.get(phaseUniqueId).add(phaseLineItemWrapper);
            } else {
                phaseUniqueIdToLinkedPLI.put(phaseUniqueId, new List<BillingWrappers.PhaseLineItem>{
                    phaseLineItemWrapper
                });
            }
        }
        return phaseUniqueIdToLinkedPLI;
    }

    public static Map<String, QuoteLineItem> getElementIdToQuoteLineItemMap(
        Id selectedQuoteId,
        Set<String> productElementIds
    ) {
        List<QuoteLineItem> quoteLineItems = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdAndProductLic(new List<Object>{
                new List<String> {selectedQuoteId},
                productElementIds
            })
            .executeQuery();

        Map<String, QuoteLineItem> quoteLineItemsMap = new Map<String, QuoteLineItem>();
        for (QuoteLineItem quoteLineItem : quoteLineItems) {
            quoteLineItemsMap.put(quoteLineItem.Product_Lic_Id__c, quoteLineItem);
        }

        return quoteLineItemsMap;
    }

    private static void createPhaseLineItemsForChangeOrder(Id orderId, Id quoteId) {
        try {
            List<Suborder__c> notBilledSuborders = (List<Suborder__c>) new SuborderSelector()
                .selectNotBilledSubordersByOrderId(orderId)
                .executeQuery();

            List<Phase__c> phases = (List<Phase__c>) new PhaseSelector()
                .selectPhasesByQuoteIds(new List<Object>{new Set<Id> { quoteId }})
                .executeQuery();

            Map<Decimal, Id> phaseNumberToPhaseId = new Map<Decimal, Id>();
            for (Phase__c phase : phases) {
                phaseNumberToPhaseId.put(phase.Phase_Number__c, phase.Id);
            }

            Map<String, QuoteLineItem> productLicIdToQli = QuoteLineItemHelper.getProductLicIdToQliMap(quoteId);

            List<Hardware_Line_Item__c> phaseLineItemsToInsert = new List<Hardware_Line_Item__c>();
            for (Suborder__c suborder : notBilledSuborders) {
                for(SuborderLineItem__c suborderLineItem : suborder.SuborderLineItems__r) {
                    QuoteLineItem quoteLineItem = productLicIdToQli.get(suborderLineItem.SalesAgreementLineItem__r.Product_Lic_Id__c);
                    phaseLineItemsToInsert.add(
                        buildPhaseLineItem(
                            suborderLineItem,
                            phaseNumberToPhaseId.get(suborder.SuborderNumber__c),
                            quoteLineItem
                        )
                    );
                }
            }

            if (phaseLineItemsToInsert.isEmpty()) {
                return;
            }

            insert phaseLineItemsToInsert;
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Error while creating phase line items for change order: ' + e.getMessage());
        }
    }

    public static Hardware_Line_Item__c buildPhaseLineItem(
        Decimal quantity,
        Id phaseId,
        QuoteLineItem quoteLineItem,
        String currencyIsoCode
    ) {
        Hardware_Line_Item__c hardLineItem = new Hardware_Line_Item__c();
        hardLineItem.Quantity__c = quantity;
        hardLineItem.RingCentral_Hardware_Phase__c = phaseId;
        hardLineItem.Quote_Line_Item__c = quoteLineItem.Id;
        hardLineItem.CurrencyIsoCode = currencyIsoCode;
        hardLineItem.Name = quoteLineItem.Product2.Name;
        return hardLineItem;
    }

    public static Hardware_Line_Item__c buildPhaseLineItem(
        SuborderLineItem__c suborderLineItem,
        Id phaseId,
        QuoteLineItem quoteLineItem
    ) {
        Hardware_Line_Item__c hardLineItem = buildPhaseLineItem(
            suborderLineItem.Quantity__c,
            phaseId,
            quoteLineItem,
            suborderLineItem.CurrencyIsoCode
        );
        hardLineItem.ExistingQuantity__c = suborderLineItem.Quantity__c;
        return hardLineItem;
    }

    @TestVisible
    private static  Map<String, Map<String, Decimal>> getPhaseIdToExistingQuantityMap(List<BillingWrappers.Phase> phases) {
        Set<Id> suborderIds = new Set<Id>();
        for (BillingWrappers.Phase phase : phases) {
            if (phase.suborderId != null) {
                suborderIds.add(phase.suborderId);
            }
        }

        if (suborderIds.isEmpty()) {
            return new Map<String, Map<String, Decimal>>();
        }

        Map<Id, Suborder__c> suborderMap = new Map<Id, Suborder__c>(
            (List<Suborder__c>) new SuborderSelector()
                .selectSubordersAndSuborderLineItemsByIds(suborderIds)
                .executeQuery()
        );

        Map<String, Map<String, Decimal>> phaseIdToMapExistingQuantity = new Map<String, Map<String, Decimal>>();

        for (BillingWrappers.Phase phase: phases) {
            if (phase.suborderId != null && suborderMap.containsKey(phase.suborderId)) {
                for (SuborderLineItem__c suborderLineItem : suborderMap.get(phase.suborderId).SuborderLineItems__r) {
                    Map<String, Decimal> productElementIdToExistingQuantity = new Map<String, Decimal>();
                    productElementIdToExistingQuantity.put(
                        suborderLineItem.SalesAgreementLineItem__r.Product_Lic_Id__c,
                        suborderLineItem.Quantity__c
                    );
                    if (phaseIdToMapExistingQuantity.containsKey(phase.phaseId)) {
                        Map<String, Decimal> existingMap = phaseIdToMapExistingQuantity.get(phase.phaseId);
                        existingMap.putAll(productElementIdToExistingQuantity);
                        phaseIdToMapExistingQuantity.put(phase.phaseId, existingMap);
                    } else {
                        phaseIdToMapExistingQuantity.put(phase.phaseId, productElementIdToExistingQuantity);
                    }
                }
            }
        }
        return phaseIdToMapExistingQuantity;
    }

    @TestVisible
    private static Decimal getExistingQuantityForPhaseLineItem(
        BillingWrappers.PhaseLineItem phaseLineItem,
        BillingWrappers.Phase phase,
        Map<String, Map<String, Decimal>> phaseIdToExistingQuantityMap
    ) {
        Decimal existingQuantity = 0;
        if (phaseLineItem.existingQuantity != null) {
            existingQuantity = phaseLineItem.existingQuantity;
        } else if (!phaseIdToExistingQuantityMap.isEmpty() && phaseIdToExistingQuantityMap.get(phase.phaseId).containsKey(phaseLineItem.productElementId)) {
            existingQuantity = phaseIdToExistingQuantityMap.get(phase.phaseId)?.get(phaseLineItem.productElementId);
        }
        return existingQuantity;
    }
}