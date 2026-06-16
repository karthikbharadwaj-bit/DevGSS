/**
 * Handler for upserting Quote Line Items
 * Handles requests for upserting quote line items with cart items
 */
public class QuoteLineItemUpsertHandler implements IResourceHandler {
    public ApiResponse execute(ApiRequest request) {
        try {
            Map<Id, List<BillingWrappers.CartItem>> quoteIdToCartItems = (Map<Id, List<BillingWrappers.CartItem>>)JSON.deserialize(
                request.requestBody,
                Map<Id, List<BillingWrappers.CartItem>>.class
            );

            processUpsert(quoteIdToCartItems);

            return ApiResponse.success( getMappedQuotes(quoteIdToCartItems.keySet()) );
        } catch (Exception e) {
            return ApiResponse.error(e);
        }
    }

    private Map<String, Object> getMappedQuotes(Set<Id> ids) {
        List<Quote> allQuotes = (List<Quote>) new QuoteSelector()
            .selectQuotesByIdsForUQTCalculatedOnly(new List<Object> { ids })
            .executeQuery();

        Quote masterQuote;
        Map<String, Quote> techQuotes = new Map<String, Quote>();

        for(Quote q : allQuotes) {
            if(!q.IsMultiProductTechnicalQuote__c) {
                masterQuote = q;
            } else {
                if( q.ServiceName__c == null ) {
                    throw new HandledException('ServiceName__c is required for technical quote: ' + q.Id);
                }
                techQuotes.put(q.ServiceName__c, q);
            }
        }

        return new Map<String, Object>{
            'masterQuote' => masterQuote,
            'techQuotes' => techQuotes
        };
    }

    /**
     * Two-phase upsert: First process master QLIs, then technical QLIs
     * This ensures technical QLIs can properly reference master QLIs
     */
    private void processUpsert(Map<Id, List<BillingWrappers.CartItem>> quoteIdToCartItems) {
        // Validate input
        if (quoteIdToCartItems == null || quoteIdToCartItems.isEmpty()) {
            throw new HandledException('QuoteIdToCartItems cannot be null or empty');
        }

        Set<Id> quoteIds = quoteIdToCartItems.keySet();

        Map<Id, Quote> quoteMap = buildQuoteMap(quoteIds);

        // Query once for all quotes
        List<QuoteLineItem> existingQLIs = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(quoteIds)
            .executeQuery();

        List<Entitlement__c> entitlements = new EntitlementSelector()
            .selectEntitlementForSyncQuoteLineItemsByQuoteId(quoteIds)
            .executeQuery();

        Map<String, BillingWrappers.CartItem> catalogIdToCartItem = buildCatalogIdToCartItemMap(quoteIdToCartItems);
        Map<String, List<QuoteLineItem>> quoteIdToExistingQLIs = buildQuoteIdToExistingQLIsMap(existingQLIs);
        Map<Id, List<PricebookEntry>> quoteIdToPbeList = QuoteLineItemHelper.getPbeBasedOnCartItems(new List<Id>(quoteIds), catalogIdToCartItem);

        // Separate master and technical quotes
        Map<Id, List<BillingWrappers.CartItem>> masterQuoteCartItems = new Map<Id, List<BillingWrappers.CartItem>>();
        Map<Id, List<BillingWrappers.CartItem>> technicalQuoteCartItems = new Map<Id, List<BillingWrappers.CartItem>>();

        for (Id quoteId : quoteIds) {
            Quote quote = quoteMap.get(quoteId);
            if (quote != null && quote.IsMultiProductTechnicalQuote__c) {
                technicalQuoteCartItems.put(quoteId, quoteIdToCartItems.get(quoteId));
            } else {
                masterQuoteCartItems.put(quoteId, quoteIdToCartItems.get(quoteId));
            }
        }

        // Phase 1: Process master QLIs and insert empty versions without triggers to get IDs
        Map<Id, Map<String, QuoteLineItem>> masterQuoteIdToCatalogIdToQLI = new Map<Id, Map<String, QuoteLineItem>>();
        Map<String, QuoteLineItem> masterCatalogIdToQLI = new Map<String, QuoteLineItem>();

        if (!masterQuoteCartItems.isEmpty()) {
            // Process master QLIs with full field population
            masterQuoteIdToCatalogIdToQLI = processQuoteLineItems(
                masterQuoteCartItems,
                catalogIdToCartItem,
                quoteIdToExistingQLIs,
                entitlements,
                quoteIdToPbeList
            );

            // Build master catalog mapping
            for (Map<String, QuoteLineItem> catalogMap : masterQuoteIdToCatalogIdToQLI.values()) {
                masterCatalogIdToQLI.putAll(catalogMap);
            }

            // Create empty master QLIs for ID generation (only for records without existing IDs)
            Map<String, QuoteLineItem> catalogIdToEmptyQLI = new Map<String, QuoteLineItem>();

            for (String catalogId : masterCatalogIdToQLI.keySet()) {
                QuoteLineItem fullQLI = masterCatalogIdToQLI.get(catalogId);
                QuoteLineItem emptyQLI = createEmptyQLI(fullQLI);
                // Only add records that don't already have an ID
                if (emptyQLI.Id == null) {
                    catalogIdToEmptyQLI.put(catalogId, emptyQLI);
                }
            }

            // Insert empty master QLIs without triggers to get IDs
            if (!catalogIdToEmptyQLI.isEmpty()) {
                Triggers.switchOff();
                insert catalogIdToEmptyQLI.values();
                Triggers.switchOn();

                // Update IDs in the fully populated master QLIs using catalog ID mapping
                // Only update IDs for records that were actually inserted
                for (String catalogId : catalogIdToEmptyQLI.keySet()) {
                    QuoteLineItem fullQLI = masterCatalogIdToQLI.get(catalogId);
                    QuoteLineItem emptyQLI = catalogIdToEmptyQLI.get(catalogId);
                    fullQLI.Id = emptyQLI.Id;
                }
            }
        }

        // Phase 2: Process technical QLIs and combine all for final upsert with triggers
        List<QuoteLineItem> allQLIs = new List<QuoteLineItem>();

        // Add fully populated master QLIs
        allQLIs.addAll(masterCatalogIdToQLI.values());

        // Process technical QLIs with full field population
        if (!technicalQuoteCartItems.isEmpty()) {
            Map<Id, Map<String, QuoteLineItem>> technicalQuoteMap = processTechnicalQuoteLineItems(
                technicalQuoteCartItems,
                catalogIdToCartItem,
                masterCatalogIdToQLI,
                quoteIdToExistingQLIs,
                entitlements,
                quoteIdToPbeList
            );

            // Extract technical QLIs and add to combined list
            for (Map<String, QuoteLineItem> catalogMap : technicalQuoteMap.values()) {
                allQLIs.addAll(catalogMap.values());
            }
        }

        // Final upsert of all QLIs with triggers enabled
        if (!allQLIs.isEmpty()) {
            // Avoid direct processing of Opportunity records during QuoteLineItem upsert due to 101 SOQL limit risk.
            // We update Opportunity totals without triggers by toggling the bypass flag.
            OpportunityTotals.bypassTriggers = true;
            upsert allQLIs;
            OpportunityTotals.bypassTriggers = false;
        }
    }

    /**
     * Create empty QLI with only essential fields from fully populated QLI
     */
    private QuoteLineItem createEmptyQLI(QuoteLineItem fullQLI) {
        QuoteLineItem emptyQLI = new QuoteLineItem();

        if (fullQLI.Id != null) {
            emptyQLI.Id = fullQLI.Id;
        } else {
            emptyQLI.QuoteId = fullQLI.QuoteId;
            emptyQLI.Product2Id = fullQLI.Product2Id;
            emptyQLI.PricebookEntryId = fullQLI.PricebookEntryId;
            emptyQLI.UnitPrice = fullQLI.UnitPrice;
            emptyQLI.Quantity = fullQLI.Quantity;
        }

        return emptyQLI;
    }

    /**
     * Process technical quote line items with master QLI references using catalog ID mapping
     */
    private Map<Id, Map<String, QuoteLineItem>> processTechnicalQuoteLineItems(
        Map<Id, List<BillingWrappers.CartItem>> technicalQuoteCartItems,
        Map<String, BillingWrappers.CartItem> catalogIdToCartItem,
        Map<String, QuoteLineItem> masterCatalogIdToQLI,
        Map<String, List<QuoteLineItem>> quoteIdToExistingQLIs,
        List<Entitlement__c> entitlements,
        Map<Id, List<PricebookEntry>> quoteIdToPbeList
    ) {
        Map<Id, Map<String, QuoteLineItem>> technicalQuoteMap = processQuoteLineItems(
            technicalQuoteCartItems,
            catalogIdToCartItem,
            quoteIdToExistingQLIs,
            entitlements,
            quoteIdToPbeList
        );

        // Apply technical-specific field population using catalog ID mapping
        for (Id quoteId : technicalQuoteMap.keySet()) {
            Map<String, QuoteLineItem> catalogMap = technicalQuoteMap.get(quoteId);
            for (String catalogId : catalogMap.keySet()) {
                QuoteLineItem technicalQLI = catalogMap.get(catalogId);
                populateTechnicalQLIFields(technicalQLI, catalogId, masterCatalogIdToQLI);
            }
        }

        return technicalQuoteMap;
    }

    /**
     * Generic method to process quote line items for either master or technical quotes
     * Returns Map<QuoteId, Map<CatalogId, QuoteLineItem>>
     */
    private Map<Id, Map<String, QuoteLineItem>> processQuoteLineItems(
        Map<Id, List<BillingWrappers.CartItem>> quoteIdToCartItems,
        Map<String, BillingWrappers.CartItem> catalogIdToCartItem,
        Map<String, List<QuoteLineItem>> quoteIdToExistingQLIs,
        List<Entitlement__c> entitlements,
        Map<Id, List<PricebookEntry>> quoteIdToPbeList
    ) {
        Set<Id> quoteIds = quoteIdToCartItems.keySet();
        Map<Id, Map<String, QuoteLineItem>> result = new Map<Id, Map<String, QuoteLineItem>>();

        for(Id quoteId : quoteIds) {
            List<BillingWrappers.CartItem> cartItems = quoteIdToCartItems.get(quoteId);
            List<PricebookEntry> pbeList = quoteIdToPbeList.get(quoteId);
            List<QuoteLineItem> existingQLIs = quoteIdToExistingQLIs.get(quoteId);

            // Handle case where no existing QLIs exist (e.g., first-time quote creation)
            if (existingQLIs == null) {
                existingQLIs = new List<QuoteLineItem>();
            }

            // Use the simplified Map-based method to preserve catalog ID relationships
            Map<String, QuoteLineItem> catalogIdToQLI = QuoteLineItemHelper.processUpsertQuoteLineItemsAsMap(
                quoteId,
                cartItems,
                catalogIdToCartItem,
                pbeList,
                existingQLIs,
                entitlements,
                new QuoteLineItem(),
                new Map<String, Product2>()
            );

            // Merge results
            result.put(quoteId, catalogIdToQLI);
        }

        return result;
    }

    private Map<String, BillingWrappers.CartItem> buildCatalogIdToCartItemMap(Map<Id, List<BillingWrappers.CartItem>> quoteIdToCartItems) {
        Map<String, BillingWrappers.CartItem> catalogIdToCartItem = new Map<String,BillingWrappers.CartItem>();
        for(List<BillingWrappers.CartItem> items : quoteIdToCartItems.values()) {
            for(BillingWrappers.CartItem item : items) {
                catalogIdToCartItem.put(item.catalogId, item);
            }
        }
        return catalogIdToCartItem;
    }

    private Map<String, List<QuoteLineItem>> buildQuoteIdToExistingQLIsMap(List<QuoteLineItem> existingQLIs) {
        Map<String, List<QuoteLineItem>> quoteIdToExistingQLIs = new Map<String, List<QuoteLineItem>>();
        for(QuoteLineItem qli : existingQLIs) {
            if(!quoteIdToExistingQLIs.containsKey(qli.QuoteId)) {
                quoteIdToExistingQLIs.put(qli.QuoteId, new List<QuoteLineItem>());
            }
            quoteIdToExistingQLIs.get(qli.QuoteId).add(qli);
        }
        return quoteIdToExistingQLIs;
    }

    private Map<Id, Quote> buildQuoteMap(Set<Id> quoteIds) {
        if (quoteIds == null || quoteIds.isEmpty()) {
            throw new HandledException('Quote IDs cannot be null or empty');
        }

        List<Quote> quotes = new QuoteSelector()
            .selectQuotesByIds(new List<Object> { quoteIds })
            .executeQuery();

        if (quotes == null) {
            throw new HandledException('Quote selector returned null');
        }

        return new Map<Id, Quote>(quotes);
    }

    private void populateTechnicalQLIFields(
        QuoteLineItem technicalQLI,
        String catalogId,
        Map<String, QuoteLineItem> masterCatalogIdToQLI
    ) {
        // Validate required parameters
        if (technicalQLI == null) {
            throw new HandledException('Technical QuoteLineItem cannot be null');
        }

        if (String.isBlank(catalogId)) {
            throw new HandledException('Catalog ID is required for technical QLI: ' + technicalQLI.Id);
        }

        if (!masterCatalogIdToQLI.containsKey(catalogId)) {
            throw new HandledException('Master QLI not found for technical QLI with catalog ID: ' + catalogId + '. Master QLIs must be processed before technical QLIs.');
        }

        QuoteLineItem masterQLI = masterCatalogIdToQLI.get(catalogId);
        if (masterQLI?.Id == null) {
            throw new HandledException('Master QLI found but has no Id for catalog ID: ' + catalogId);
        }

        technicalQLI.MasterQLI__c = masterQLI.Id;
        technicalQLI.IsMultiProductTechnicalQLI__c = true;
    }
}