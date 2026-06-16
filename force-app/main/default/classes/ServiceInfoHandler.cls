public with sharing class ServiceInfoHandler {

    public class RunProcessOrderSentAfterActions extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> quoteIds = new Set<Id>();

            for (ServiceInfo__c serviceInfo : (List<ServiceInfo__c>) this.TriggerRecords) {
                if (isChangedFieldTo(serviceInfo, ServiceInfo__c.IsProcessOrderSent__c, true)) {
                    quoteIds.add(serviceInfo.Quote__c);
                }
            }

            if (quoteIds.isEmpty()) {
                return;
            }

            List<Order> ordersWithItems = (List<Order>) new OrderSelector()
                .selectOrdersByTechQuoteIdsForManualProvisioningCaseCreationProcessMPUB(quoteIds)
                .executeQuery();

            List<Order> filteredOrders = new List<Order>();
            for (Order order : ordersWithItems) {
                if (QuoteHelper.isExistingBusiness(order.TechnicalQuoteId__r)) {
                    filteredOrders.add(order);
                }
            }
            DealDeskCaseGenerator.createCaseForManualProvisioningMPUB(filteredOrders);
        }
    }
}