public with sharing class OrderItemHelper {

    public static List<OrderItem> buildOrderItemsForOrdersByProvisioning(List<Order> ordList, List<QuoteLineItem> qliList, Boolean isNewService) {
        List<OrderItem> orderItems = new List<OrderItem>();
        Map<String, List<QuoteLineItem>> provisioningToQLIListMap = QuoteLineItemHelper.getProvisioningToQLIListMap(qliList, isNewService);

        for (Order ord : ordList) {
            List<QuoteLineItem> qliForOrder = provisioningToQLIListMap.get(ord.Provisioning__c);

            if (!qliForOrder.isEmpty()) {
                orderItems.addAll(buildOrderItems(ord, qliForOrder));
            }
        }

        return orderItems;
    }

    public static List<OrderItem> buildOrderItems(Order ord, List<QuoteLineItem> qliList) {
        System.assertNotEquals(null, ord, 'Order cannot be null');
        System.assertNotEquals(null, qliList, 'QuoteLineItems cannot be null');

        List<OrderItem> orderItems = new List<OrderItem>();

        if (qliList.isEmpty()) {
            return orderItems;
        }

        for (QuoteLineItem qli : qliList) {
            Boolean isProServChangeOrder = OpportunityHelper.isProServChangeOrderOpportunity(qli.Quote.Opportunity.Parent_Order__c, qli.Quote.Opportunity.Tier_Name__c);
            Boolean isProservTaxLineItem = Product2Helper.isTaxes(qli.Product2) && ord.RecordTypeId == OrderHelper.RT_ID_PROSERV;
            Decimal prevQuantity = isProServChangeOrder ? qli.NewQuantity__c : qli.Quantity;
            Decimal notDeliveredQuantity = qli.DeliveredQuantity__c != null ? prevQuantity - qli.DeliveredQuantity__c : qli.Quantity;
            Decimal quantity = isProServChangeOrder ? notDeliveredQuantity : qli.Quantity;
            if (isProservTaxLineItem || (isProServChangeOrder && quantity == 0)) {
                continue;
            }
            OrderItem orderItem = new OrderItem(
                OrderId = ord.Id,
                Quantity = quantity,
                PricebookEntryId = qli.PricebookEntryId,
                UnitPrice = qli.EffectivePrice__c,
                UnitPriceWithoutDiscount__c = qli.UnitPrice,
                QuoteLineItemId = qli.Id,
                Zero_Quantity__c = qli.Zero_Quantity__c,
                Discount_Type__c = qli.Discount_type__c,
                Discount_Number__c = qli.Discount_number__c,
                Not_Shipped_Phones__c = notDeliveredQuantity
            );

            if (qli.IsMultiProductTechnicalQLI__c) {
                orderItem.QuoteLineItemId = qli.MasterQLI__c;
            }

            orderItems.add(orderItem);
        }

        return orderItems;
    }
}