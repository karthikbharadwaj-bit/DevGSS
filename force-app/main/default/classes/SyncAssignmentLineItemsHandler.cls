public class SyncAssignmentLineItemsHandler implements IResourceHandler {

    public ApiResponse execute(ApiRequest request) {
        try {
            Map<String, List<BillingWrappers.AssignmentLineItem>> quoteIdToAlisMap =
                (Map<String, List<BillingWrappers.AssignmentLineItem>>) JSON.deserialize(
                    request.requestBody,
                    Map<String, List<BillingWrappers.AssignmentLineItem>>.class
                );
            Map<String, Object> result = syncAssignmentLineItems(quoteIdToAlisMap);
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(e);
        }
    }

    private Map<String, Object> syncAssignmentLineItems(Map<String, List<BillingWrappers.AssignmentLineItem>> quoteIdToAlisMap) {
        List<AssignmentLineItem__c> alisToUpsert = new List<AssignmentLineItem__c>();
        Map<String, List<AssignmentLineItem__c>> alisToReturnByQuoteId = new Map<String, List<AssignmentLineItem__c>>();
        List<AssignmentLineItem__c> alisToDelete = new List<AssignmentLineItem__c>();
        Set<String> usedAlis = new Set<String>();

        List<AssignmentLineItem__c> assignments = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
            .selectALIForQuotes(new List<Object>{new List<String>(quoteIdToAlisMap.keySet())})
            .executeQuery();

        // Get all QuoteLineItems for all quotes
        List<QuoteLineItem> allQlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(new List<String>(quoteIdToAlisMap.keySet()))
            .executeQuery();

        // Create a map of quoteId + elementId to QuoteLineItem
        Map<String, QuoteLineItem> quoteElementToQliMap = new Map<String, QuoteLineItem>();
        for (QuoteLineItem qli : allQlis) {
            String key = qli.QuoteId + ':' + qli.Product2.ExtID__c;
            quoteElementToQliMap.put(key, qli);
        }

        Map<String, Area_Codes__c> mergedAreaCodesMap = new Map<String, Area_Codes__c>();
        for (String quoteId : quoteIdToAlisMap.keySet()) {
            List<BillingWrappers.AssignmentLineItem> alis = quoteIdToAlisMap.get(quoteId);
            mergedAreaCodesMap.putAll(AreaCodeService.syncAreaCodesForAssignmentLineItem(alis, quoteId));
        }

        for (String quoteId : quoteIdToAlisMap.keySet()) {
            List<BillingWrappers.AssignmentLineItem> alis = quoteIdToAlisMap.get(quoteId);
            for (BillingWrappers.AssignmentLineItem ali : alis) {
                String areaId = AreaCodeService.getAreaId(ali.areaCodeInfo);

                if (!mergedAreaCodesMap.containsKey(areaId)) {
                    throw new IllegalArgumentException('Error occurred during synchronization of assignment line items.');
                }

                Area_Codes__c sfAreaCode = mergedAreaCodesMap.get(areaId);

                // Use the combined key to get the correct QuoteLineItem for this quote
                String childKey = quoteId + ':' + ali.childId;
                String parentKey = quoteId + ':' + ali.parentId;

                QuoteLineItem childQli = quoteElementToQliMap.get(childKey);
                QuoteLineItem parentQli = quoteElementToQliMap.get(parentKey);

                if (childQli == null || parentQli == null) {
                    throw new IllegalArgumentException('QuoteLineItem not found for the specified quote and product.');
                }

                AssignmentLineItem__c aliBootstrap = new AssignmentLineItem__c(
                    AreaCode__c = sfAreaCode.Id,
                    AreaCode__r = sfAreaCode,
                    Child__c = childQli.Id,
                    Child__r = childQli,
                    Parent__c = parentQli.Id,
                    Parent__r = parentQli,
                    Quantity__c = ali.quantity
                );

                if (!alisToReturnByQuoteId.containsKey(quoteId)) {
                    alisToReturnByQuoteId.put(quoteId, new List<AssignmentLineItem__c>());
                }
                alisToReturnByQuoteId.get(quoteId).add(aliBootstrap);

                processExistingAssignment(aliBootstrap, assignments, usedAlis, alisToUpsert);
            }
        }

        processUnusedAssignments(assignments, usedAlis, alisToDelete);

        upsert alisToUpsert;
        delete alisToDelete;

        if (!Feature_Toggle__c.getInstance().EnableSpinnerless__c) {
            deleteCustomAdressesAssignments(alisToUpsert, alisToDelete);
        }

        return new Map<String, Object>{
            'upsertedAssignmentLineItems' => alisToUpsert.size(),
            'assignmentLineItemsMap' => alisToReturnByQuoteId,
            'deletedAssignmentLineItems' => alisToDelete.size()
        };
    }

    private void processExistingAssignment(
        AssignmentLineItem__c aliBootstrap,
        List<AssignmentLineItem__c> assignments,
        Set<String> usedAlis,
        List<AssignmentLineItem__c> alisToUpsert
    ) {
        AssignmentLineItem__c matchedALI = findMatchingAssignment(aliBootstrap, assignments);

        if (matchedALI != null) {
            usedAlis.add(matchedALI.Id);
            aliBootstrap.Id = matchedALI.Id;
            if (aliBootstrap.Quantity__c != matchedALI.Quantity__c) {
                alisToUpsert.add(aliBootstrap);
            }
        } else {
            alisToUpsert.add(aliBootstrap);
        }
    }

    private AssignmentLineItem__c findMatchingAssignment(
        AssignmentLineItem__c aliBootstrap,
        List<AssignmentLineItem__c> assignments
    ) {
        for (AssignmentLineItem__c existingAli : assignments) {
            if (
                aliBootstrap.AreaCode__c == existingAli.AreaCode__c
                && aliBootstrap.Child__c == existingAli.Child__c
                && aliBootstrap.Parent__c == existingAli.Parent__c
            ) {
                return existingAli;
            }
        }
        return null;
    }

    private void processUnusedAssignments(
        List<AssignmentLineItem__c> assignments,
        Set<String> usedAlis,
        List<AssignmentLineItem__c> alisToDelete
    ) {
        for (AssignmentLineItem__c existingAli : assignments) {
            if (!usedAlis.contains(existingAli.Id)) {
                alisToDelete.add(existingAli);
            }
        }
    }

    private void deleteCustomAdressesAssignments(List<AssignmentLineItem__c> alisToUpsert, List<AssignmentLineItem__c> alisToDelete) {
        List<Id> qliIdsFromChangedAssignmentLineItems = new List<Id>();
        for(AssignmentLineItem__c ali: alisToUpsert) {
            qliIdsFromChangedAssignmentLineItems.add(ali.Child__c);
        }
        for(AssignmentLineItem__c ali: alisToDelete) {
            qliIdsFromChangedAssignmentLineItems.add(ali.Child__c);
        }
        List<CustomAddressAssignments__c> customAddressesAssignmentsToDelete = new List<CustomAddressAssignments__c>();
        if (!qliIdsFromChangedAssignmentLineItems.isEmpty()) {
            customAddressesAssignmentsToDelete = new CustomAddressAssignmentsSelector()
                .selectCustomAddressAssignmentsByQliIds(qliIdsFromChangedAssignmentLineItems)
                .executeQuery();
        }
        if (!customAddressesAssignmentsToDelete.isEmpty()) {
            Triggers.switchOff();
            delete customAddressesAssignmentsToDelete;
            Triggers.switchOn();
        }
    }
}