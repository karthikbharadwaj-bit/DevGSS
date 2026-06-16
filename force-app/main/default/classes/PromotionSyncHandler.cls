public class PromotionSyncHandler implements IResourceHandler {
    class Params {
        public List<BillingWrappers.Promotion> promotionsToCreate;
        public List<BillingWrappers.Promotion> promotionsToDelete;
        public List<BillingWrappers.CartItem> items;
    }

    public ApiResponse execute(ApiRequest request) {
        try {
            Params params = (Params) JSON.deserialize(request.requestBody, Params.class);
            System.debug('params: ' + JSON.serialize(params));

            deletePromotions(params.promotionsToDelete);

            List<Promotion__c> promotionsToCreate = insertPromotions(params.promotionsToCreate);

            updateItems(params.items, promotionsToCreate);

            return ApiResponse.success(params);
        } catch (Exception e) {
            return ApiResponse.error(e);
        }
    }

    private List<BillingWrappers.CartItem> getPromotedItems(List<BillingWrappers.CartItem> items, List<Promotion__c> promotions) {
        List<BillingWrappers.CartItem> promotedItems = new List<BillingWrappers.CartItem>();

        // Create a map of promo codes to promotions for easy lookup
        Map<String, Promotion__c> promoCodeIdToPromo = new Map<String, Promotion__c>();
        for (Promotion__c promo : promotions) {
            promoCodeIdToPromo.put(promo.Promo_Code_Id__c, promo);
        }

        // Filter items that have promotions applied
        for (BillingWrappers.CartItem item : items) {
            if (item.sfPromoCodeId != null && promoCodeIdToPromo.containsKey(item.sfPromoCodeId)) {
                promotedItems.add(item);
            }
        }

        return promotedItems;
    }

    private void updateItems(List<BillingWrappers.CartItem> items, List<Promotion__c> promotionsToCreate) {
        List<BillingWrappers.CartItem> promotedItems = getPromotedItems(items, promotionsToCreate);

        if (promotedItems.isEmpty()) {
            return;
        }

        Map<String, Promotion__c> promoCodeIdToPromo = new Map<String, Promotion__c>();
        for (Promotion__c promo : promotionsToCreate) {
            promoCodeIdToPromo.put(promo.Promo_Code_Id__c, promo);
        }

        // Get mapping from catalogId to QuoteLineItem
        Map<String, QuoteLineItem> catalogIdToQli = getCatalogIdToQliMapping(promotedItems, promotionsToCreate);

        // Update QuoteLineItems with promotions
        List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();
        for (BillingWrappers.CartItem item : promotedItems) {
            qlisToUpdate.add(new QuoteLineItem(
                Id = catalogIdToQli.get(item.catalogId).Id,
                Promotion__c = promoCodeIdToPromo.get(item.sfPromoCodeId).Id)
            );
        }

        if(!qlisToUpdate.isEmpty()) {
            Triggers.switchOff();
            update qlisToUpdate;
            Triggers.switchOn();
        }
    }

    private List<Promotion__c> insertPromotions(List<BillingWrappers.Promotion> promotionList) {
        if (promotionList == null || promotionList.isEmpty()) {
            return new List<Promotion__c>();
        }

        List<Promotion__c> promotionsToCreate = new List<Promotion__c>();
        for (BillingWrappers.Promotion promoWrapper : promotionList) {
            Promotion__c promo =  new Promotion__c (
                Description__c = promoWrapper.description,
                Name = promoWrapper.name,
                Start_Date__c = promoWrapper.startDate != null ? Datetime.valueOfGmt(promoWrapper.startDate) : null,
                End_Date__c = promoWrapper.endDate != null ? Datetime.valueOfGmt(promoWrapper.endDate) : null,
                Discount_Templates__c = promoWrapper.discountTemplates,
                Promo_Code__c = promoWrapper.promoCode,
                Quote__c = promoWrapper.quoteId,
                Promo_Code_Id__c = promoWrapper.promoCodeId,
                Priority__c = promoWrapper.priority
            );
            promotionsToCreate.add(promo);
        }

        if (!promotionsToCreate.isEmpty()) {
            insert promotionsToCreate;
        }
        return promotionsToCreate;
    }

    private void deletePromotions(List<BillingWrappers.Promotion> promotionList) {
        if (promotionList == null || promotionList.isEmpty()) {
            return;
        }

        List<Promotion__c> promotionsToDelete = new List<Promotion__c>();
        for (BillingWrappers.Promotion promoWrapper : promotionList) {
            if (promoWrapper != null && promoWrapper.id != null) {
                promotionsToDelete.add(new Promotion__c(Id = promoWrapper.id));
            }
        }

        if (!promotionsToDelete.isEmpty()) {
            delete promotionsToDelete;
        }
    }

    private Map<String, QuoteLineItem> getCatalogIdToQliMapping(List<BillingWrappers.CartItem> promotedItems, List<Promotion__c> promotionsToCreate) {
        // Collect catalogIds from promoted items
        Set<String> catalogIds = new Set<String>();
        for (BillingWrappers.CartItem item : promotedItems) {
            if (String.isBlank(item.catalogId)) {
                throw new IllegalArgumentException('Catalog ID cannot be blank for promoted items');
            }
            catalogIds.add(item.catalogId);
        }

        // Get Quote ID from promotions (all promotions should be for the same quote)
        Id quoteId = null;
        if (!promotionsToCreate.isEmpty()) {
            quoteId = promotionsToCreate[0].Quote__c;
        }

        // Query QuoteLineItems by matching Product2.ExtId__c with catalogIds and QuoteId
        List<QuoteLineItem> existingQlis = ((List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsByExtIdAndQuoteId(catalogIds, quoteId)
            .executeQuery());

        // Create map from catalogId to QuoteLineItem
        Map<String, QuoteLineItem> catalogIdToQli = new Map<String, QuoteLineItem>();
        for (QuoteLineItem qli : existingQlis) {
            catalogIdToQli.put(qli.Product2.ExtId__c, qli);
        }

        return catalogIdToQli;
    }
}