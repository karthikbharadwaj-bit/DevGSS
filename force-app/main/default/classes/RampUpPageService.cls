@RestResource(UrlMapping='/RampUpPageService/*')
global without sharing class RampUpPageService {

    public class CustomException extends Exception {}

    public class RampUpPageItem {

        public Id Id;
        public Id entitlementId;
        public Id pdId;
        public String name;
        public Decimal quantity;
        public Decimal price;
        public String currencyCode;
        public Decimal discount;
        public String discountType;
        public String family;
        public String rampUpPeriod;
        public String entitlementPeriod;
        public Date startDate;
        public Date submittedDate;
        public Boolean isOrderTypeNew;

        public RampUpPageItem overage;

        public transient Product2 product;

        public RampUpPageItem(ProductDetail__c pd) {

            this.Id = pd.Id;
            this.quantity = pd.QuantityOrThreshold__c;
            this.startDate = pd.RampUpStartDate__c == null ? null : pd.RampUpStartDate__c.dateGmt();
            if (pd.OrderItem__c != null) {
                this.isOrderTypeNew = pd.OrderItem__r.Order.CC_Order_Type__c == OrderHelper.CC_ORDER_TYPE_NEW
                                        && pd.OrderItem__r.Order.Opportunity.Brand_Name__c.containsIgnoreCase(OpportunityHelper.BRAND_RINGCENTRAL);
                this.rampUpPeriod = pd.RampUp__c;
                this.product = pd.OrderItem__r.Product2;
                this.name = pd.OrderItem__r.Product2.Name;
                this.price = pd.OrderItem__r.TotalPrice;
                this.currencyCode = pd.OrderItem__r.CurrencyIsoCode;
                this.discount = pd.OrderItem__r.Discount_Number__c;
                this.discountType = pd.OrderItem__r.Discount_Type__c;
                this.family = pd.OrderItem__r.Product2.Family;
                this.quantity = pd.QuantityOrThreshold__c;
                this.submittedDate = pd.ProductDetail__c == null ? null : pd.ProductDetail__r.LastModifiedDate.dateGmt();
            } else if (pd.Entitlement__c != null) {
                this.rampUpPeriod = pd.RampUp__c;
                this.entitlementId = pd.Entitlement__c;
                this.entitlementPeriod = pd.RampUp__c;
                this.product = pd.Entitlement__r.Product__r;
                this.name = pd.Entitlement__r.Name;
                this.price = pd.Entitlement__r.Price__c;
                this.currencyCode = pd.Entitlement__r.CurrencyIsoCode;
                this.discount = pd.Entitlement__r.Discount__c;
                this.discountType = pd.Entitlement__r.Discount_Type__c;
                this.family = pd.Entitlement__r.Product__r.Family;
                this.quantity = pd.QuantityOrThreshold__c;
                this.submittedDate = pd.LastModifiedDate.dateGmt();
            }
        }
        
        public RampUpPageItem(ProductDetail__c oldPD, ProductDetail__c newPD) {

            this(newPD);
            if (newPD.QuantityOrThreshold__c != 0 && newPD.RampUp__c != oldPD.RampUp__c) {
                AquivaHelper.throwAquivaException(
                    'Invalid PD: ' + newPD.Id + '. Changing both quantity and RUP is not supported.'
                );
            }
            this.pdId = newPD.ProductDetail__c;
            this.quantity = oldPD.QuantityOrThreshold__c + newPD.QuantityOrThreshold__c;
            this.entitlementId = oldPD.Entitlement__c;
            this.entitlementPeriod = oldPD.RampUp__c;
        }

        public Boolean isUnaffectedEntitlement() {
            return this.entitlementId != null && this.pdId == null;
        }

        public Boolean isRampUpPeriodChange() {
            return this.entitlementId != null && this.pdId != null;
        }

        public Boolean isUpsell() {
            return this.entitlementId == null;
        }
    }

    @HttpGet
    global static void getRampUpPageItems() {
        
        RestResponse res = RestContext.response;
        try {
            Id orderId = RestContext.request.params.get('orderId');
            List<RampUpPageItem> result = buildItemList(orderId);
            res.responseBody = Blob.valueOf(JSON.serializePretty(result));
            res.statusCode = 200;
        } catch (AquivaHelper.AquivaException e) {
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String,String>{
                'error' => e.getMessage(),
                'stackTrace' => e.getStackTraceString()
            }));
        } catch (Exception e) {
            System.debug(loggingLevel.Error, 'e.getMessage() >>> ' + e.getMessage());
            System.debug(loggingLevel.Error, 'e.getStacktraceString() >>> ' + e.getStacktraceString());
            res.statusCode = 500;
        }
    }
    
    @HttpPost
    global static void saveChanges() {
        RestResponse res = RestContext.response;
        try {
            String body = RestContext.request.requestBody.toString();
            Id orderId = RestContext.request.params.get('orderId');
            validateOrderStatus(orderId);
            applyChanges(
                (List<RampUpPageItem>) JSON.deserialize(body, List<RampUpPageItem>.class),
                orderId
            );
            res.statusCode = 200;
        } catch (AquivaHelper.AquivaException e) {
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String,String>{
                'error' => e.getMessage(),
                'stackTrace' => e.getStackTraceString()
            }));
        } catch (Exception e) {
            System.debug(loggingLevel.Error, 'e.getMessage() >>> ' + e.getMessage());
            System.debug(loggingLevel.Error, 'e.getStacktraceString() >>> ' + e.getStacktraceString());
            res.statusCode = 500;
        }
    }

    private static List<RampUpPageItem> buildItemList(Id orderId) {

        List<RampUpPageItem> items = new List<RampUpPageItem>();
        // 1. Gather information on Order Product Details
        List<ProductDetail__c> orderPDs = getOrderRampUps(orderId);
        Map<Id, Integer> entitlementIdToDownsellQty = new Map<Id, Integer>();
        Set<Id> productIdsToExclude = new Set<Id>(); // up/down-selling products, which are unavailable for RUP changes
        Map<Id, ProductDetail__c> entitlementPDIdToOrderPD = new Map<Id, ProductDetail__c>();
        Set<Id> entitlementsTodownSellIds = new Set<Id>();

        for (ProductDetail__c pd : orderPDs) {
            if (!pd.OrderItem__r.Active__c && pd.QuantityOrThreshold__c < 0) {
                entitlementsTodownSellIds.add(pd.OrderItem__r.RC_Entitlement__c);
            } else if (pd.OrderItem__r.Active__c){
                if (pd.QuantityOrThreshold__c < 0) { // Downsell
                    productIdsToExclude.add(pd.OrderItem__r.Product2Id);
                } else if (pd.QuantityOrThreshold__c == 0) {
                    if (pd.ProductDetail__c != null) { // Ramp Up Change
                        entitlementPDIdToOrderPD.put(pd.ProductDetail__c, pd);
                    } else { // Zero Qty Upsell (e.g. Price/Discount Update)
                        productIdsToExclude.add(pd.OrderItem__r.Product2Id);
                    }
                } else { // Upsell
                    productIdsToExclude.add(pd.OrderItem__r.Product2Id);
                    items.add(new RampUpPageItem(pd));
                }
            }
        }
        // 2. Retrieve Entitlement Product Details,
        // sorted by RampUp Start Date DESC within each entitlement, i.e. ready to apply LIFO logic
        Map<Id, List<ProductDetail__c>> entPDsByEntitlementId = getEntitlementRampUps(orderId);
        // 3. Generate items based on entitlements (Taking into account all Downsells and RampUp Period Changes)
        for (Id entitlementId : entPDsByEntitlementId.keySet()) {
            for (ProductDetail__c entPD : entPDsByEntitlementId.get(entitlementId)) {
                if (!entitlementsTodownSellIds.contains(entitlementId)) {
                    if (productIdsToExclude.contains(entPD.Entitlement__r.Product__c)) {
                        continue;
                    } else if (entitlementPDIdToOrderPD.containsKey(entPD.Id)) { // Is affected by RampUp Period Change
                        items.add(new RampUpPageItem(entPD, entitlementPDIdToOrderPD.get(entPD.Id)));
                    } else { // Is not affected yet
                        items.add(new RampUpPageItem(entPD));
                    }
                }
            }
        }
        return putOveragesUnderParents(items);
    }

    private static List<ProductDetail__c> getOrderRampUps(Id orderId) {

        return (List<ProductDetail__c>) new ProductDetailSelector()
            .selectOrderProductDetailsByOrderIds(new List<Object>{new List<Id>{orderId}})
            .executeQuery();
    }

    private static Map<Id, List<ProductDetail__c>> getEntitlementRampUps(Id orderId) {

        Id accId = ((Order) new OrderSelector()
                .selectOrders()
                .selectFields(new List<String> {'AccountId'})
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{String.escapeSingleQuotes(orderId)})
                .executeQuery()[0])
            .AccountId;
        return CCUtils.groupPDsByEntitlementId(
            CCUtils.filterOngoingRampUps(
                (List<ProductDetail__c>) new ProductDetailSelector()
                    .selectEntitlementProductDetailsByAccountIds(new List<Object>{new List<Id>{accId}})
                    .executeQuery()
            )
        );
    }

    public static Map<Id, QuoteLineItem> getQuoteLineItemsByEntitlementId(Id orderId) {

        Map<Id, QuoteLineItem> quoteLineItemsByEntitlementId = new Map<Id, QuoteLineItem>();
        for (QuoteLineItem qli : (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsByOrderId(new List<Object>{orderId})
                .executeQuery()) {

            if (qli.Entitlement__c != null) {
                quoteLineItemsByEntitlementId.put(qli.Entitlement__c, qli);
            }
        }
        return quoteLineItemsByEntitlementId;
    }

    private static List<RampUpPageItem> putOveragesUnderParents(List<RampUpPageItem> items) {

        List<RampUpPageItem> sortedItems = new List<RampUpPageItem>();
        Set<Product2> products = new Set<Product2>();
        for (RampUpPageItem item : items) {
            products.add(item.product);
        }
        Map<Id, Id> sortedProducts = CCUtils.sortOveragesByProducts(new List<Product2>(products));
        Map<String, RampUpPageItem> parentsByOverageId = new Map<String, RampUpPageItem>();
        for (RampUpPageItem item : items) {
            if (sortedProducts.containsKey(item.product.Id)) {
                if (sortedProducts.get(item.product.Id) == null) { // item without overage, just add it to result
                    sortedItems.add(item);
                } else {
                    parentsByOverageId.put(
                        sortedProducts.get(item.product.Id) + String.valueOf(item.startDate) + item.entitlementPeriod,
                        item
                    );
                }
            }
        }
        for (RampUpPageItem item : items) {
            if (parentsByOverageId.containsKey(item.product.Id + String.valueOf(item.startDate) + item.entitlementPeriod)) {
                parentsByOverageId.get(item.product.Id + String.valueOf(item.startDate) + item.entitlementPeriod).overage = item;
                sortedItems.add(parentsByOverageId.get(item.product.Id + String.valueOf(item.startDate) + item.entitlementPeriod));
            }
        }
        return sortedItems;
    }

    private static void unpackOveragesFromParents(List<RampUpPageItem> items) {

        List<RampUpPageItem> overages = new List<RampUpPageItem>();
        for (RampUpPageItem item : items) {
            if (item.overage != null) {
                item.overage.rampUpPeriod = item.rampUpPeriod;
                overages.add(item.overage);
            }
        }
        items.addAll(overages);
    }

    private static void applyChanges(List<RampUpPageItem> items, Id orderId) {

        unpackOveragesFromParents(items);
        Map<Id, List<ProductDetail__c>> entPDsByEntId = getEntitlementRampUps(orderId);
        Map<Id, Map<Id, ProductDetail__c>> entPDMapByEntId = new Map<Id, Map<Id, ProductDetail__c>>();
        for (Id entitlementId : entPDsByEntId.keySet()) {
            entPDMapByEntId.put(entitlementId, new Map<Id, ProductDetail__c>(entPDsByEntId.get(entitlementId)));
        }
        Map<Id, ProductDetail__c> orderPDMap = new Map<Id, ProductDetail__c>(getOrderRampUps(orderId));
        Map<Id, ProductDetail__c> pdsByProductId = CCUtils.groupPDsByProductId(orderPDMap.values());
        Map<Id, QuoteLineItem> quoteLineItemByEntId = getQuoteLineItemsByEntitlementId(orderId);

        List<ProductDetail__c> pdsToUpdate = new List<ProductDetail__c>();
        Map<Id, OrderItem> orderItemsToInsertByEntPDId = new Map<Id, OrderItem>();
        List<OrderItem> orderItemsToDelete = new List<OrderItem>();
        List<ProductDetail__c> productDetailsToDelete = new List<ProductDetail__c>();
        Map<Id, ProductDetail__c> pdsToInsertByEntPDId = new Map<Id, ProductDetail__c>();
        for (RampUpPageItem item : items) {
            if (item.isUnaffectedEntitlement()) {
                ProductDetail__c pdToInsert = entPDMapByEntId.get(item.entitlementId).get(item.Id).clone();
                final Integer newRampUpPeriod = Integer.valueOf(String.isBlank(item.rampUpPeriod) ? '0' : item.rampUpPeriod);
                final Integer oldRampUpPeriod = Integer.valueOf(String.isBlank(pdToInsert.RampUp__c) ? '0' : pdToInsert.RampUp__c);
                if (newRampUpPeriod > oldRampUpPeriod) {
                    pdToInsert.RampUp__c = String.valueOf(newRampUpPeriod);
                    pdToInsert.ProductDetail__c = item.Id;
                    pdToInsert.Entitlement__c = null;
                    pdToInsert.QuantityOrThreshold__c = 0;
                    QuoteLineItem qli = quoteLineItemByEntId.get(item.entitlementId);
                    if (qli != null && qli.Product2Id != null) {
                        if (pdsByProductId.containsKey(qli.Product2Id)) {
                            pdToInsert.OrderItem__c = pdsByProductId.get(qli.Product2Id).OrderItem__c;
                        } else {
                            OrderItem oiToInsert = buildOrderItemToInsert(orderId, qli);
                            orderItemsToInsertByEntPDId.put(item.Id, oiToInsert);
                            pdToInsert.OrderItem__c = null;
                        }
                        pdsToInsertByEntPDId.put(item.Id, pdToInsert);
                    }
                }
            } else if (item.isRampUpPeriodChange()) {
                ProductDetail__c entitlementPD = entPDMapByEntId.get(item.entitlementId).get(item.pdId);
                ProductDetail__c orderItemPD = orderPDMap.get(item.Id);
                final Integer entRampUpPeriod = Integer.valueOf(String.isBlank(entitlementPD.RampUp__c) ? '0' : entitlementPD.RampUp__c);
                final Integer newRampUpPeriod = Integer.valueOf(String.isBlank(item.rampUpPeriod) ? '0' : item.rampUpPeriod);
                final Integer oldRampUpPeriod = Integer.valueOf(String.isBlank(orderItemPD.RampUp__c) ? '0' : orderItemPD.RampUp__c);
                if (newRampUpPeriod != oldRampUpPeriod && newRampUpPeriod > entRampUpPeriod) {
                    orderItemPD.RampUp__c = String.valueOf(newRampUpPeriod);
                    pdsToUpdate.add(orderItemPD);
                } else if (newRampUpPeriod == entRampUpPeriod) {
                    productDetailsToDelete.add(orderItemPD);
                    orderItemsToDelete.add(new OrderItem(Id = orderItemPD.OrderItem__c));
                }
            } else if (item.isUpsell()) {
                ProductDetail__c orderItemPD = orderPDMap.get(item.Id);
                final Integer newRampUpPeriod = Integer.valueOf(String.isBlank(item.rampUpPeriod) ? '0' : item.rampUpPeriod);
                final Integer oldRampUpPeriod = Integer.valueOf(String.isBlank(orderItemPD.RampUp__c) ? '0' : orderItemPD.RampUp__c);
                if (newRampUpPeriod != oldRampUpPeriod) {
                    orderItemPD.RampUp__c = String.valueOf(newRampUpPeriod);
                    pdsToUpdate.add(orderItemPD);
                }
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            update pdsToUpdate;

            OrderItemTriggerHelper.isRampUpChangeOrderItemInsert = true;
            insert orderItemsToInsertByEntPDId.values();

            for (Id entPDId : orderItemsToInsertByEntPDId.keySet()) {
                pdsToInsertByEntPDId.get(entPDId).OrderItem__c = orderItemsToInsertByEntPDId.get(entPDId).Id;
            }
            insert pdsToInsertByEntPDId.values();
            delete productDetailsToDelete;
            delete orderItemsToDelete;
        } catch (Exception e) {
            Database.rollback(sp);
            throw e;
        } finally {
            OrderItemTriggerHelper.isRampUpChangeOrderItemInsert = false;
        }
    }

    private static OrderItem buildOrderItemToInsert(Id orderId, QuoteLineItem qli) {

        return new OrderItem(
            Quantity = 1,
            Zero_Quantity__c = true,
            Threshold__c = qli.Threshold__c == null ? null : 0,
            PricebookEntryId = qli.PricebookEntryId,
            QuoteLineItemId = qli.Id,
            UnitPrice = qli.EffectivePrice__c,
            UnitPriceWithoutDiscount__c = qli.UnitPrice,
            Discount_Type__c = qli.Discount_Type__c,
            Discount_Number__c = qli.Discount_Number__c,
            Active__c = !qli.Deactivated__c,
            BillingStatus__c = (qli.BillingStatus__c == PhaseHelper.BILLING_STATUS_REPLACED
                ? qli.BillingStatus__c
                : (qli.Deactivated__c
                    ? PhaseHelper.BILLING_STATUS_CANCELLED
                    : PhaseHelper.BILLING_STATUS_ACTIVE)),
            RC_Entitlement__c = qli.Entitlement__c,
            OrderId = orderId
        );
    }

    private static void validateOrderStatus(Id orderId) {

        Order order = ((List<Order>) new OrderSelector()
            .selectOrdersByIds(new List<Object>{new List<Id>{orderId}})
            .executeQuery())[0];
        if (order.Status != OrderHelper.STATUS_NEW) {
            AquivaHelper.throwAquivaException('Ramp Up Change is available only when Order Status is New');
        }
    }
}