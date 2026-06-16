/**
 * Domain handler for Quote Line Item Manager
 * Handles all requests for the quote-line-item-manager domain
 */
public class QuoteLineItemManagerDomainHandler extends DomainHandler {

    public QuoteLineItemManagerDomainHandler() {
        super();
        register('v1', 'quote-line-items', 'POST', QuoteLineItemUpsertHandler.class);
        register('v1', 'quote-line-items/missing/bulk', 'POST', QuoteLineItemRemoveMissingHandler.class);

        register('v1', 'promotions', 'POST', PromotionSyncHandler.class);
        register('v1', 'area-codes', 'POST', SyncAreaCodesHandler.class);
        register('v1', 'assignment-line-items', 'POST', SyncAssignmentLineItemsHandler.class);
    }

    public class QuoteLineItemRemoveMissingHandler implements IResourceHandler {
        public ApiResponse execute(ApiRequest request) {
            try {
                Map<Id, Set<String>> quoteIdToCatalogIds = (Map<Id, Set<String>>)JSON.deserialize(
                    request.requestBody,
                    Map<Id, Set<String>>.class
                );

                List<QuoteLineItem> qlisToRemove = getQliToRemoveByQuoteId(quoteIdToCatalogIds);
                if(!qlisToRemove.isEmpty()) {
                    delete qlisToRemove;
                }

                return ApiResponse.success(new Map<String, Object>{
                    'qlisToRemove' => qlisToRemove,
                    'quoteIdToCatalogIds' => quoteIdToCatalogIds
                });
            } catch (Exception e) {
                return ApiResponse.error(e.getMessage());
            }
        }

        private List<QuoteLineItem> getQliToRemoveByQuoteId(Map<Id, Set<String>> quoteIdToCatalogIds) {
            List<QuoteLineItem> qlis = new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIds(quoteIdToCatalogIds.keySet())
                .executeQuery();

            List<QuoteLineItem> qlisToRemove = new List<QuoteLineItem>();
            for(QuoteLineItem qli : qlis) {
                system.debug('qli.QuoteId: ' + qli.QuoteId);
                Set<String> catalogIds = quoteIdToCatalogIds.get(qli.QuoteId);
                if(!catalogIds.contains(qli.Product_Lic_Id__c)) {
                    qlisToRemove.add(qli);
                }
            }
            return qlisToRemove;
        }
    }


}