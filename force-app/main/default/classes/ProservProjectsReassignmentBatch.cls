public with sharing class ProservProjectsReassignmentBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Set<Id> processedOrdersIds = new Set<Id>();

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return new OrderSelector()
            .selectOrders()
            .selectFields(
                new List<String> {
                    'ProservProject__c',
                    'Type',
                    'Opportunity.Parent_Order__c'
                }
            )
            .setCondition('(Type = \'' + OrderHelper.TYPE_INITIAL_ORDER + '\' OR Type = \'' + OrderHelper.TYPE_CHANGE_ORDER + '\') ' +
                    'AND (RecordTypeId = \'' + OrderHelper.RT_ID_PROSERV + '\' OR RecordTypeId = \'' + OrderHelper.RT_ID_CC_PROSERV + '\')')
            .withoutSelectorOrderByIncluded()
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .executeQueryLocator();
    }

    public void execute(Database.BatchableContext BC, List<Order> scope){
        List<Order> ordersToUpdate = new List<Order>();
        Map<Order, List<Order>> initialToChangeOrdersMap = new Map<Order, List<Order>>();
        Map<Id, Order> ordersMap = new Map<Id, Order>(
            (List<Order>) new OrderSelector()
                .selectOrders()
                .selectFields(
                    new List<String> {
                        'ProservProject__c',
                        'Type',
                        'Opportunity.Parent_Order__c'
                    }
                )
                .setCondition('(Type = \'' + OrderHelper.TYPE_INITIAL_ORDER + '\' OR Type = \'' + OrderHelper.TYPE_CHANGE_ORDER + '\') ' +
                        'AND (RecordTypeId = \'' + OrderHelper.RT_ID_PROSERV + '\' OR RecordTypeId = \'' + OrderHelper.RT_ID_CC_PROSERV + '\')')
                .withoutSelectorOrderByIncluded()
                .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
                .executeQuery()
        );

        for(Order order : scope) {
            if (processedOrdersIds.contains(order.Id) || order.Type != OrderHelper.TYPE_CHANGE_ORDER) {
                continue;
            }
            List<Order> changeOrders = new List<Order>();
            Order currentLevelOrder = order;
            do {
                if (currentLevelOrder?.Opportunity?.Parent_Order__c == null) {
                    break;
                }
                Order parentOrder = ordersMap.get(currentLevelOrder.Opportunity?.Parent_Order__c);
                changeOrders.add(currentLevelOrder);
                processedOrdersIds.add(currentLevelOrder.Id);
                currentLevelOrder = parentOrder;
            } while (currentLevelOrder.Type != OrderHelper.TYPE_INITIAL_ORDER);
            initialToChangeOrdersMap.put(currentLevelOrder, changeOrders);
        }

        for(Order inititialOrder : initialToChangeOrdersMap.keySet()) {
            for(Order changeOrder : initialToChangeOrdersMap.get(inititialOrder)) {
                if (changeOrder.ProServProject__c != inititialOrder.ProServProject__c) {
                    changeOrder.ProServProject__c = inititialOrder.ProServProject__c;
                    ordersToUpdate.add(changeOrder);
                }
            }
        }

        update ordersToUpdate;
    }

    public void finish(Database.BatchableContext BC) {}
}