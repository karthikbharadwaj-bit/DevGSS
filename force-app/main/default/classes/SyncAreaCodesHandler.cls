/**
 * Handler for Area Codes synchronization
 * Handles POST requests for area-codes endpoint
 */
public class SyncAreaCodesHandler implements IResourceHandler {

    /**
     * Main execute method to handle the request
     */
    public ApiResponse execute(ApiRequest request) {
        try {
            Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes = (Map<String, List<BillingWrappers.AreaCodeLineItem>>) JSON.deserialize(
                request.requestBody,
                Map<String, List<BillingWrappers.AreaCodeLineItem>>.class
            );

            if (!isValidRequest(quoteToAreaCodes)) {
                return ApiResponse.error('Invalid request parameters');
            }

            // Process synchronization
            AreaCodeSyncProcessor processor = new AreaCodeSyncProcessor(quoteToAreaCodes);

            Map<String, List<Area_Code_Line_Item__c>> syncResults = processor.process();

            // Perform DML operations
            if (!syncResults.isEmpty()) {
                new DMLHandler().performOperations(syncResults);
            }

            // Prepare response
            Map<String, Integer> result = new Map<String, Integer>{
                'upsertedRecords' => syncResults.get('upsert').size(),
                'deletedRecords' => syncResults.get('delete').size()
            };

            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(e);
        }
    }

    private Boolean isValidRequest(Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes) {
        return quoteToAreaCodes != null && !quoteToAreaCodes.isEmpty();
    }

    /**
     * Inner class to handle DML operations with trigger control
     */
    private class DMLHandler {
        public void performOperations(Map<String, List<Area_Code_Line_Item__c>> syncResults) {
            Triggers.switchOff();
            try {
                if (!syncResults.get('upsert').isEmpty()) {
                    upsert syncResults.get('upsert');
                }
                if (!syncResults.get('delete').isEmpty()) {
                    delete syncResults.get('delete');
                }
            } finally {
                Triggers.switchOn();
            }
        }
    }

    /**
     * Area code synchronization processor
     */
    private class AreaCodeSyncProcessor {
        private final Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes;

        public AreaCodeSyncProcessor(Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes) {
            this.quoteToAreaCodes = quoteToAreaCodes;
        }

        public Map<String, List<Area_Code_Line_Item__c>> process() {
            // Collect area code data
            Map<String, Object> areaCodeData = new AreaCodeDataCollector(quoteToAreaCodes).collect();

            // Get existing area codes
            Map<String, Area_Codes__c> areaCodeByAreaId = new AreaCodeFetcher(areaCodeData, quoteToAreaCodes).fetch();

            // Create new area codes if needed
            List<Area_Codes__c> newAreaCodes = new AreaCodeCreator(quoteToAreaCodes, areaCodeByAreaId).create();
            if (!newAreaCodes.isEmpty()) {
                insert newAreaCodes;
                new AreaCodeEnricher(areaCodeByAreaId).enrich(newAreaCodes);
            }

            // Process line items
            return new LineItemProcessor(
                quoteToAreaCodes,
                areaCodeByAreaId,
                quoteToAreaCodes.keySet()
            ).process();
        }
    }

    /**
     * Inner class to collect area code data
     */
    private class AreaCodeDataCollector {
        private final Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes;

        public AreaCodeDataCollector(Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes) {
            this.quoteToAreaCodes = quoteToAreaCodes;
        }

        public Map<String, Object> collect() {
            Map<String, Object> result = new Map<String, Object>{
                'countries' => new Set<String>(),
                'states' => new Set<String>(),
                'cities' => new Set<String>(),
                'areaCodes' => new Set<Integer>()
            };

            for (String quoteId : quoteToAreaCodes.keySet()) {
                for (BillingWrappers.AreaCodeLineItem item : quoteToAreaCodes.get(quoteId)) {
                    if (isValidAreaCodeInfo(item)) {
                        addToResult(result, item.areaCodeInfo);
                    }
                }
            }
            return result;
        }

        private Boolean isValidAreaCodeInfo(BillingWrappers.AreaCodeLineItem item) {
            return item.areaCodeInfo != null &&
                   String.isNotBlank(item.areaCodeInfo.country) &&
                   item.areaCodeInfo.areaCode != null;
        }

        private void addToResult(Map<String, Object> result, BillingWrappers.AreaCodeData info) {
            ((Set<String>) result.get('countries')).add(info.country);
            ((Set<String>) result.get('states')).add(info.state);
            ((Set<String>) result.get('cities')).add(info.city);
            ((Set<Integer>) result.get('areaCodes')).add(info.areaCode);
        }
    }

    /**
     * Inner class to fetch existing area codes
     */
    private class AreaCodeFetcher {
        private final Map<String, Object> areaCodeData;
        private final Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes;

        public AreaCodeFetcher(Map<String, Object> areaCodeData, Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes) {
            this.areaCodeData = areaCodeData;
            this.quoteToAreaCodes = quoteToAreaCodes;
        }

        public Map<String, Area_Codes__c> fetch() {
            Map<String, Area_Codes__c> areaCodeByAreaId = new Map<String, Area_Codes__c>();

            List<Area_Codes__c> areaCodes = (List<Area_Codes__c>) new AreaCodesSelector()
                .selectAreaCodesForMatchedSync(
                    new List<Object>{
                        (Set<String>) areaCodeData.get('countries'),
                        (Set<String>) areaCodeData.get('states'),
                        (Set<String>) areaCodeData.get('cities'),
                        (Set<Integer>) areaCodeData.get('areaCodes')
                    },
                    new List<Object>{ quoteToAreaCodes.keySet() }
                )
                .executeQuery();

            for (Area_Codes__c areaCode : areaCodes) {
                areaCodeByAreaId.put(AreaCodeService.getAreaId(areaCode), areaCode);
            }

            return areaCodeByAreaId;
        }
    }

    /**
     * Inner class to create new area codes
     */
    private class AreaCodeCreator {
        private final Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes;
        private final Map<String, Area_Codes__c> existingAreaCodes;

        public AreaCodeCreator(Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes,
                             Map<String, Area_Codes__c> existingAreaCodes) {
            this.quoteToAreaCodes = quoteToAreaCodes;
            this.existingAreaCodes = existingAreaCodes;
        }

        public List<Area_Codes__c> create() {
            Map<String, BillingWrappers.AreaCodeData> uniqueAreaCodes = new Map<String, BillingWrappers.AreaCodeData>();
            List<Area_Codes__c> areaCodes = new List<Area_Codes__c>();

            // Collect unique area codes
            for (String quoteId : quoteToAreaCodes.keySet()) {
                for (BillingWrappers.AreaCodeLineItem item : quoteToAreaCodes.get(quoteId)) {
                    String areaId = AreaCodeService.getAreaId(item.areaCodeInfo);
                    if (!uniqueAreaCodes.containsKey(areaId)) {
                        uniqueAreaCodes.put(areaId, item.areaCodeInfo);
                    }
                }
            }

            // Create new area codes
            for (String areaId : uniqueAreaCodes.keySet()) {
                if (!existingAreaCodes.containsKey(areaId)) {
                    Area_Codes__c newAreaCode = AreaCodeService.buildAreaCode(uniqueAreaCodes.get(areaId));
                    if (newAreaCode != null) {
                        areaCodes.add(newAreaCode);
                    }
                }
            }

            return areaCodes;
        }

    }

    /**
     * Inner class to process line items
     */
    private class LineItemProcessor {
        private final Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes;
        private final Map<String, Area_Codes__c> areaCodeByAreaId;
        private final Set<String> quoteIds;
        private final Map<String, Id> areaCodeLineItemIdByKey;
        private final Map<Id, String> catalogIdByQLIId;
        private final Map<String, Map<String, Id>> qliIdByQuoteAndCatalog = new Map<String, Map<String, Id>>();

        public LineItemProcessor(Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes,
                               Map<String, Area_Codes__c> areaCodeByAreaId,
                               Set<String> quoteIds) {
            this.quoteToAreaCodes = quoteToAreaCodes;
            this.areaCodeByAreaId = areaCodeByAreaId;
            this.quoteIds = quoteIds;
            this.areaCodeLineItemIdByKey = new Map<String, Id>();
            this.catalogIdByQLIId = new Map<Id, String>();
        }

        private String generateKey(String quoteId, String catalogId, BillingWrappers.AreaCodeData areaCodeInfo) {
            String areaCodeKey = AreaCodeService.getAreaId(areaCodeInfo);
            return buildKey(quoteId, catalogId, areaCodeKey);
        }

        private String generateKey(String quoteId, String catalogId, Area_Codes__c areaCode) {
            String areaCodeKey = AreaCodeService.getAreaId(areaCode);
            return buildKey(quoteId, catalogId, areaCodeKey);
        }

        private String buildKey(String quoteId, String catalogId, String areaCodeKey) {
            return quoteId + '_' + catalogId + '_' + (areaCodeKey != null ? areaCodeKey : '');
        }

        public Map<String, List<Area_Code_Line_Item__c>> process() {
            Map<String, List<Area_Code_Line_Item__c>> result = new Map<String, List<Area_Code_Line_Item__c>>{
                'upsert' => new List<Area_Code_Line_Item__c>(),
                'delete' => new List<Area_Code_Line_Item__c>()
            };

            Map<Id, Area_Code_Line_Item__c> existingItems = getExistingItems();
            Set<String> requestKeys = new Set<String>();

            // Process items from request and collect composite keys
            for (String quoteId : quoteToAreaCodes.keySet()) {
                for (BillingWrappers.AreaCodeLineItem item : quoteToAreaCodes.get(quoteId)) {
                    String key = generateKey(quoteId, item.cartItemCatalogId, item.areaCodeInfo);
                    requestKeys.add(key);
                    processItem(item, existingItems, result, quoteId);
                }
            }

            // Find and delete items whose composite keys are not in the request
            for (Area_Code_Line_Item__c existingItem : existingItems.values()) {
                String catalogId = catalogIdByQLIId.get(existingItem.Quote_Line_Item__c);
                String quoteId = getQuoteIdFromQLI(existingItem.Quote_Line_Item__c);
                if (catalogId != null && quoteId != null && existingItem.Area_Code__r != null) {
                    String existingKey = generateKey(quoteId, catalogId, existingItem.Area_Code__r);
                    if (!requestKeys.contains(existingKey)) {
                        result.get('delete').add(existingItem);
                    }
                }
            }

            return result;
        }

        private String getQuoteIdFromQLI(Id qliId) {
            for (String quoteId : qliIdByQuoteAndCatalog.keySet()) {
                if (qliIdByQuoteAndCatalog.get(quoteId).values().contains(qliId)) {
                    return quoteId;
                }
            }
            return null;
        }

        private Map<Id, Area_Code_Line_Item__c> getExistingItems() {
            Map<Id, Area_Code_Line_Item__c> aclisMap = new Map<Id, Area_Code_Line_Item__c>();

            // First, query QuoteLineItems to get Product_Lic_Id__c mapping
            List<QuoteLineItem> qlis = new QuoteLineItemSelector()
                .selectQuoteLineItemsForAreaCodeSync(new List<Object>{ quoteIds })
                .executeQuery();
            for (QuoteLineItem qli : qlis) {
                catalogIdByQLIId.put(qli.Id, qli.Product_Lic_Id__c);
                if (!qliIdByQuoteAndCatalog.containsKey(qli.QuoteId)) {
                    qliIdByQuoteAndCatalog.put(qli.QuoteId, new Map<String, Id>());
                }
                qliIdByQuoteAndCatalog.get(qli.QuoteId).put(qli.Product_Lic_Id__c, qli.Id);
            }

            // Then query Area Code Line Items with related QuoteLineItems and Area Codes
            List<Area_Code_Line_Item__c> aclis = new AreaCodeLineItemSelector()
                .selectACLIForSync(new List<Object>{ quoteIds })
                .executeQuery();

            for (Area_Code_Line_Item__c acli : aclis) {
                aclisMap.put(acli.Id, acli);
                // Build the quote-specific catalog ID to area code line item ID mapping
                if (acli.Quote_Line_Item__r.Product_Lic_Id__c != null && acli.Area_Code__r != null) {
                    String key = generateKey(
                        acli.Quote_Line_Item__r.QuoteId,
                        acli.Quote_Line_Item__r.Product_Lic_Id__c,
                        acli.Area_Code__r
                    );
                    areaCodeLineItemIdByKey.put(key, acli.Id);
                }
            }
            return aclisMap;
        }

        private void processItem(BillingWrappers.AreaCodeLineItem item,
                               Map<Id, Area_Code_Line_Item__c> existingItems,
                               Map<String, List<Area_Code_Line_Item__c>> result,
                               String quoteId) {
            String processedKey = item.isDeleted ? 'delete' : 'upsert';

            // Get existing area code line item ID using composite key that includes area code info
            String key = generateKey(quoteId, item.cartItemCatalogId, item.areaCodeInfo);
            Id existingId = areaCodeLineItemIdByKey.get(key);

            // Skip if trying to delete non-existent item
            if (processedKey == 'delete' && existingId == null) {
                return;
            }

            Id relatedQLIId = getRelatedQLIId(item, quoteId);
            if (relatedQLIId == null) {
                return;
            }

            Area_Code_Line_Item__c lineItem = new Area_Code_Line_Item__c(
                Id = existingId,
                Quantity__c = item.quantity,
                Quote_Line_Item__c = relatedQLIId,
                Area_Code__c = getRelatedAreaCodeId(item)
            );

            result.get(processedKey).add(lineItem);
        }

        private Id getRelatedQLIId(BillingWrappers.AreaCodeLineItem item, String quoteId) {
            return qliIdByQuoteAndCatalog.get(quoteId).get(item.cartItemCatalogId);
        }

        private Id getRelatedAreaCodeId(BillingWrappers.AreaCodeLineItem item) {
            Area_Codes__c areaCode = areaCodeByAreaId.get(AreaCodeService.getAreaId(item.areaCodeInfo));
            return areaCode != null ? areaCode.Id : null;
        }
    }

    /**
     * Inner class to enrich area codes map
     */
    private class AreaCodeEnricher {
        private final Map<String, Area_Codes__c> areaCodeByAreaId;

        public AreaCodeEnricher(Map<String, Area_Codes__c> areaCodeByAreaId) {
            this.areaCodeByAreaId = areaCodeByAreaId;
        }

        public void enrich(List<Area_Codes__c> newAreaCodes) {
            for (Area_Codes__c areaCode : newAreaCodes) {
                String areaId = AreaCodeService.getAreaId(areaCode);
                if (!areaCodeByAreaId.containsKey(areaId)) {
                    areaCodeByAreaId.put(areaId, areaCode);
                }
            }
        }
    }
}