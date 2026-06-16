public with sharing class CreateSupportEntitlements extends QueueableBase {

    public static final String ADVANCED_SUPPORT = 'Advanced Support';
    public static final String EXTENDED_CC_SUPPORT = 'Extended Contact Center Support';
    public static final String MANAGED_SERVICES = 'managed_services';

    private static final Integer MAX_SCOPE_SIZE = 100;

    @TestVisible
    private class OrdersData {
        public Set<Id> accountIdSet = new Set<Id>();
        public List<Product2> product2List = new List<Product2>();
        Map<Order, List<OrderItem>> orderToOrderItemsMap = new Map<Order, List<OrderItem>>();

        public OrdersData(Set<Id> accountIdSet, List<Product2> product2List, Map<Order, List<OrderItem>> orderToOrderItemsMap) {
            this.accountIdSet = accountIdSet;
            this.product2List = product2List;
            this.orderToOrderItemsMap = orderToOrderItemsMap;
        }
    }

    private class EntitlementsData {
        public List<Entitlement> entitlementsForInsert = new List<Entitlement>();
        public List<Entitlement> entitlementsForUpdate = new List<Entitlement>();

        public EntitlementsData(List<Entitlement> entitlementsForInsert, List<Entitlement> entitlementsForUpdate) {
            this.entitlementsForInsert = entitlementsForInsert;
            this.entitlementsForUpdate = entitlementsForUpdate;
        }
    }

    public override void execute(QueueableContext context) {

        Set<Id> orderIds = new Set<Id>();
        for (Object item : getLocalScope(MAX_SCOPE_SIZE)) {
            Id orderId = (Id) item;
            orderIds.add(orderId);
        }

        OrdersData data = queryOrdersData(orderIds);
        if (data == null || data.orderToOrderItemsMap.isEmpty()) {
            return;
        }

        Set<Id> accountIdSet = data.accountIdSet;
        List<Product2> product2List = data.product2List;
        Map<Order, List<OrderItem>> orderToOrderItemsMap = data.orderToOrderItemsMap;

        Map<Id, Map<Id, Entitlement>> existingEntitlements = getExistingEntitlements(accountIdSet, product2List);
        EntitlementsData supportEntitlements = handleSupportEntitlements(orderToOrderItemsMap, existingEntitlements);

        List<Entitlement> entitlementsForInsert = supportEntitlements.entitlementsForInsert;
        List<Entitlement> entitlementsForUpdate = supportEntitlements.entitlementsForUpdate;

        if (!entitlementsForUpdate.isEmpty()) {
            update entitlementsForUpdate;
        }

        if (!entitlementsForInsert.isEmpty()) {
            insert entitlementsForInsert;
        }
    }

    @TestVisible
    private OrdersData queryOrdersData(Set<Id> orderIds) {

        if (orderIds == null || orderIds.isEmpty()) {
            return null;
        }

        List<Order> ordersList = (List<Order>) new OrderSelector()
            .newQueryFactory()
            .selectFields(
                new List<String>{
                    'Id',
                    'Name',
                    'AccountId',
                    'Account.Id',
                    'Account.Name',
                    'Account.UC_ES_Service_Level__c',
                    'Account.Contact_Center_End_Date__c',
                    'Account.Enterprise_Support_Start_Date__c',
                    'Account.Enterprise_Support_End_Date__c',
                    'OpportunityId',
                    'QuoteId',
                    'EffectiveDate'
                }
            )
            .subselect(
                new OrderItemSelector('OrderItems', Order.SObjectType)
                    .newQueryFactory()
                    .selectFields(new List<String>{
                        'Id',
                        'QuoteLineItemId',
                        'QuoteLineItem.Product2Id',
                        'QuoteLineItem.Product2.Id',
                        'QuoteLineItem.Product2.ExtID__c',
                        'QuoteLineItem.Product2.SupportType__c',
                        'QuoteLineItem.Product2.Name',
                        'QuoteLineItem.NewQuantity__c'
                    })
                    .setCondition('QuoteLineItem.Product2.SupportType__c != null')
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{orderIds})
            .executeQuery();

        Set<Id> accountIdSet = new Set<Id>();
        List<Product2> product2List = new List<Product2>();

        Map<Order, List<OrderItem>> orderToOrderItemsMap = new Map<Order, List<OrderItem>>();
        for (Order orderRecord : ordersList) {
            if (orderRecord.OrderItems.isEmpty()) {
                continue;
            }
            orderToOrderItemsMap.put(orderRecord, orderRecord.OrderItems);

            accountIdSet.add(orderRecord.AccountId);
            for (OrderItem orderItem : orderRecord.OrderItems) {
                product2List.add(orderItem.QuoteLineItem.Product2);
            }
        }

        return new OrdersData(accountIdSet, product2List, orderToOrderItemsMap);
    }

    private EntitlementsData handleSupportEntitlements(Map<Order, List<OrderItem>> orderToOrderItemsMap, Map<Id, Map<Id, Entitlement>> existingEntitlements) {
        List<Entitlement> entitlementsForInsert = new List<Entitlement>();
        List<Entitlement> entitlementsForUpdate = new List<Entitlement>();
        for (Order orderRecord : orderToOrderItemsMap.keySet()) {
            for (OrderItem orderItem : orderToOrderItemsMap.get(orderRecord)) {
                Boolean isEntitlementExists = false;
                if (existingEntitlements.containsKey(orderRecord.AccountId)) {
                    Entitlement existingEntitlement;
                    Map<Id, Entitlement> productIdToEntitlementMap = existingEntitlements.get(orderRecord.AccountId);
                    isEntitlementExists = productIdToEntitlementMap.containsKey(orderItem.QuoteLineItem.Product2Id);
                    if (isEntitlementExists) {
                        existingEntitlement = productIdToEntitlementMap.get(orderItem.QuoteLineItem.Product2Id);
                        if (orderItem.QuoteLineItem.NewQuantity__c > 0) {
                            continue;
                        }
                        Product2 product = orderItem.QuoteLineItem.Product2;
                        if (product.SupportType__c.equals(MANAGED_SERVICES)) {
                            existingEntitlement.Name = StringHelper.snakeCaseToStartCase(product.SupportType__c);
                        }
                        existingEntitlement.EndDate = orderRecord.EffectiveDate;
                        entitlementsForUpdate.add(existingEntitlement);
                        continue;
                    }
                }

                Entitlement supportEntitlement = buildSupportEntitlement(
                    orderRecord.AccountId,
                    orderItem.QuoteLineItem.Product2,
                    orderRecord.EffectiveDate
                );
                if (supportEntitlement == null) {
                    continue;
                }
                entitlementsForInsert.add(supportEntitlement);
            }
        }

        return new EntitlementsData(entitlementsForInsert, entitlementsForUpdate);
    }

    @TestVisible
    private Map<Id, Map<Id, Entitlement>> getExistingEntitlements(Set<Id> accountIdSet, List<Product2> productList) {
        if (accountIdSet == null || accountIdSet.isEmpty() || productList == null || productList.isEmpty()) {
            return new Map<Id, Map<Id, Entitlement>>();
        }

        Map<String, List<Id>> supportTypeToProduct2IdsMap = new Map<String, List<Id>>();
        for (Product2 product2Record : productList) {
            if (product2Record.SupportType__c == null) {
                continue;
            }
            String supportType = StringHelper.snakeCaseToStartCase(product2Record.SupportType__c);
            if (!supportTypeToProduct2IdsMap.containsKey(supportType)) {
                supportTypeToProduct2IdsMap.put(supportType, new List<Id>{product2Record.Id});
            } else {
                supportTypeToProduct2IdsMap.get(supportType).add(product2Record.Id);
            }
        }

        Set<Id> product2IdSet = new Set<Id>();
        for (String supportType : supportTypeToProduct2IdsMap.keySet()) {
            product2IdSet.addAll(supportTypeToProduct2IdsMap.get(supportType));
        }

        List<Entitlement> entitlementsList = (List<Entitlement>) new SupportEntitlementSelector()
            .newQueryFactory()
            .selectFields(
                new List<String>{
                    'Id',
                    'AccountId',
                    'Product__c',
                    'EndDate',
                    'Status',
                    'Type'
                }
            )
            .setCondition('EndDate = null AND AccountId IN :bind0 AND Product__c in :bind1 AND Type IN :bind2')
            .setQueryBindings(new List<Object>{accountIdSet, product2IdSet, supportTypeToProduct2IdsMap.keySet()})
            .executeQuery();

        if (entitlementsList.isEmpty()) {
            return new Map<Id, Map<Id, Entitlement>>();
        }

        Map<Id, Map<Id, Entitlement>> accountIdToProductIdToEntitlementMap = new Map<Id, Map<Id, Entitlement>>();
        for (Entitlement supportEntitlement : entitlementsList) {
            if (!accountIdToProductIdToEntitlementMap.containsKey(supportEntitlement.AccountId)) {
                accountIdToProductIdToEntitlementMap.put(
                    supportEntitlement.AccountId,
                    new Map<Id, Entitlement>{supportEntitlement.Product__c => supportEntitlement}
                );
            } else {
                accountIdToProductIdToEntitlementMap.get(supportEntitlement.AccountId).put(
                    supportEntitlement.Product__c,
                    supportEntitlement
                );
            }
        }

        return accountIdToProductIdToEntitlementMap;
    }

    private Boolean isCCCatalogId(String extId) {
        return extId != null && (QuoteLineItemHelper.EES_CC_LICENSES.contains(extId)
            || QuoteLineItemHelper.RCCC_EES_PRODUCT_CATALOG_ID.contains(extId));
    }

    @TestVisible
    private String buildEntitlementName(String supportType, String prodName) {
        if (!String.isEmpty(supportType) && supportType.equals(MANAGED_SERVICES)) {
            return StringHelper.snakeCaseToStartCase(supportType);
        }
        return !String.isEmpty(prodName) ? prodName : ADVANCED_SUPPORT;
    }

    @TestVisible
    private Entitlement buildSupportEntitlement(Id accId, Product2 prod, Date startDate) {
        return (Entitlement) new SObjectBuilder(Entitlement.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement.Name => buildEntitlementName(prod.SupportType__c, prod.Name),
                Entitlement.AccountId => accId,
                Entitlement.Product__c => prod.Id,
                Entitlement.Type => StringHelper.snakeCaseToStartCase(prod.SupportType__c),
                Entitlement.StartDate => startDate
            })
            .build()
            .getRecord();
    }
}