public with sharing class SuborderHelper {

    public static final String STATUS_NEW = 'New';
    public static final String STATUS_LOCKED = 'Locked';
    public static final String STATUS_CANCELED = 'Canceled';
    public static final String STATUS_BILLED = 'Billed';
    public static final String STATUS_FAILED = 'Failed';
    public static final String TYPE_CHANGEORDER = 'Change Order';

    public static final Map<String,String> CHARGE_TERMS_MAP = new Map<String,String> {
        'One - Time' => 'OneTime',
        'Monthly' => 'Monthly',
        'Annual' => 'Annual'
    };

    public static List<Suborder__c> createSuborders(List<Order> proServOrders, Map<Id, Phase__c> phasesMap) {
        List<Suborder__c> suborders = new List<Suborder__c>();

        if (phasesMap.isEmpty()) {
            return new List<Suborder__c>();
        }

        for (Order order : proServOrders) {
            for (Phase__c phase : phasesMap.values()) {
                suborders.add(buildSuborder(order, phase));
            }
        }

        if (!suborders.isEmpty()) {
            insert suborders;
        }

        return suborders;
    }

    public static Suborder__c buildSuborder(Order order, Phase__c phase) {
        Suborder__c suborder = new Suborder__c();
        suborder.Order__c = order.Id;
        suborder.Phase__c = phase.Id;
        suborder.Status__c = STATUS_NEW;
        suborder.CurrencyIsoCode = order.CurrencyIsoCode;
        suborder.SuborderNumber__c = phase.Phase_Number__c;
        suborder.Suborder_Type__c = phase.Phase_Type__c;
        suborder.Name = buildSuborderNumber(phase.Order__r?.orderNumber, String.valueOf(phase.Phase_Number__c));
        return suborder;
    }

    public static String buildSuborderNumber(String orderNumber, String phaseNumber) {
        return String.isNotBlank(orderNumber) ? orderNumber + ' - ' + phaseNumber : phaseNumber;
    }

    public static BillingWrappers.PaymentOrderItem buildPaymentOrderItem(SuborderLineItem__c suborderLineItem, BillingWrappers.SuborderLineItemLocation location) {
        BillingWrappers.PaymentOrderItem paymentOrderItem = new BillingWrappers.PaymentOrderItem();
        paymentOrderItem.catalogId = suborderLineItem.SalesAgreementLineItem__r.Product_Lic_Id__c;
        paymentOrderItem.qty = location.quantity;
        paymentOrderItem.billingCodeId = location.billingCodeId;
        paymentOrderItem.billingCycleDuration = CHARGE_TERMS_MAP.get(suborderLineItem.SalesAgreementLineItem__r.ChargeTerm__c);
        return paymentOrderItem;
    }

    public static List<Suborder__c> filterNonBilledSuborders(List<Suborder__c> suborders) {
        List<Suborder__c> nonBilledSuborders = new List<Suborder__c>();
        for (Suborder__c suborder : suborders) {
            if (suborder.Status__c != SuborderHelper.STATUS_BILLED) {
                nonBilledSuborders.add(suborder);
            }
        }
        return nonBilledSuborders;
    }

    public static Map<Id, SubTotals> calculateSubTotalsForOrders(List<Suborder__c> subordersWithSLI, Boolean isCurrentOrder) {
        Map<Id, SubTotals> orderToSubtotals = new Map<Id, SubTotals>();
        for (Suborder__c suborder: subordersWithSLI) {
            Decimal total = 0;
            Decimal netListtotal = 0;
            Decimal netNetTotal = 0; 
            
            for (SuborderLineItem__c suborderLineItem : suborder.SuborderLineItems__r) {
                total += suborderLineItem.Quantity__c * suborderLineItem.SalesAgreementLineItem__r.EffectivePriceNew__c;
                Boolean shouldIncludeInNetTotals = isCurrentOrder || suborder.Status__c != SuborderHelper.STATUS_BILLED;
                
                if (shouldIncludeInNetTotals) {
                    netNetTotal += suborderLineItem.Quantity__c * (suborderLineItem.SalesAgreementLineItem__r?.EffectivePrice__c ?? 0);
                    netListtotal += suborderLineItem.Quantity__c * (suborderLineItem.SalesAgreementLineItem__r?.UnitPrice ?? 0);
                }
            }

            SubTotals subtotals = new SubTotals(suborder.Suborder_Type__c, total, netListtotal, netNetTotal, orderToSubtotals.get(suborder.Order__c));
            orderToSubtotals.put(suborder.Order__c, subtotals);
        }

        return orderToSubtotals;
    }

    public static List<Order> getOrdersWithSubTotals(Set<Id> orderIds) {
		List<Order> ordersToUpdate = new List<Order>();
        
        if (!orderIds.isEmpty()) {
            List<Order> orderList = new List<Order>();
            orderList = (List<Order>) new OrderSelector()
            	.selectOrdersForSuborderManagement(new List<Object>{orderIds})
            	.executeQuery();
        

            Map<Id, Id> currentOrderToPrevOrderMap = new Map<Id, Id>();
            Map<Id, SuborderHelper.SubTotals> prevOrderToSubtotals = new Map<Id, SuborderHelper.SubTotals>();
            Map<Id, SuborderHelper.SubTotals> orderToSubtotals = new Map<Id, SuborderHelper.SubTotals>();
            Set<Id> prevOrderIds = new Set<Id>();

        
            for (Order order : orderList) {
                currentOrderToPrevOrderMap.put(order.Id, null);
                if (order.Type == TYPE_CHANGEORDER && order.Opportunity.Parent_Order__c != null) {
                    currentOrderToPrevOrderMap.put(order.Id, order.Opportunity.Parent_Order__c);
                    prevOrderIds.add(order.Opportunity.Parent_Order__c);
                }
            }

            List<Suborder__c> prevSubordersWithSLI = new List<Suborder__c>();
            if (!prevOrderIds.isEmpty() && prevOrderIds.size() > 0) {
                prevSubordersWithSLI = (List<Suborder__c>) new SuborderSelector()
                    .selectSubordersByOrdersIds(new Set<Id>(currentOrderToPrevOrderMap.values()))
                    .executeQuery();
            }
            if (!prevSubordersWithSLI.isEmpty()) {
                prevOrderToSubtotals = 
                SuborderHelper.calculateSubTotalsForOrders(prevSubordersWithSLI, false);
            }

            List<Suborder__c> subordersWithSLI = (List<Suborder__c>) new SuborderSelector()
                .selectSubordersByOrdersIds(orderIds)
                .executeQuery();
            if (!subordersWithSLI.isEmpty()) {
                orderToSubtotals = 
                SuborderHelper.calculateSubTotalsForOrders(subordersWithSLI, true);
            }
            
            if (orderToSubtotals.isEmpty()) {
                return new List<Order>();
            }

        
            for (Id orderId : orderToSubtotals.keySet()) {
                Id prevOrderId = currentOrderToPrevOrderMap.get(orderId);
                SuborderHelper.SubTotals prevSubtotals = prevOrderId != null && !prevOrderToSubtotals.isEmpty() ? 
                    prevOrderToSubtotals.get(prevOrderId) : new SuborderHelper.SubTotals();
                ordersToUpdate.add(
                    new Order(
                        Id = orderId,
                        UCSubtotal__c = orderToSubtotals.get(orderId).ucSubTotals,
                        CCSubtotal__c = orderToSubtotals.get(orderId).ccSubTotals,
                        Incremental_UC_SubTotal__c = orderToSubtotals.get(orderId).netUCPriceNotBilled - prevSubtotals.netUCPriceNotBilled,
                        Incremental_CC_SubTotal__c = orderToSubtotals.get(orderId).netCCPriceNotBilled - prevSubtotals.netCCPriceNotBilled,
                        Incremental_ProServ_List_Price__c = orderToSubtotals.get(orderId).netListPriceTotal - prevSubtotals.netListPriceTotal,
                        Incremental_ProServ_Discount__c = orderToSubtotals.get(orderId).netDiscountTotal - prevSubtotals.netDiscountTotal,
                        Incremental_ProServ_Net_Price__c = orderToSubtotals.get(orderId).netPricTotal - prevSubtotals.netPricTotal
                    )
                );
            }
        }
        return ordersToUpdate;
    }
    public class SubTotals {
        public Decimal ucSubTotals = 0;
        public Decimal ccSubTotals = 0;
        
        public Decimal netListPriceTotal = 0;
        public Decimal netPricTotal = 0;
        public Decimal netDiscountTotal= 0;
        public Decimal netCCPriceNotBilled = 0;
        public Decimal netUCPriceNotBilled = 0;
        
        public Subtotals(){
            
        }

        public Subtotals(String suborderType, Decimal suborderTotal, Decimal netListPrice, Decimal netSuborderTotal, SubTotals existingSubtotal) {
            if (existingSubtotal != null) {
                this.ucSubTotals = existingSubtotal.ucSubTotals;
                this.ccSubTotals = existingSubtotal.ccSubTotals;
                this.netListPriceTotal = existingSubtotal.netListPriceTotal;
                this.netPricTotal = existingSubtotal.netPricTotal;
                this.netUCPriceNotBilled = existingSubtotal.netUCPriceNotBilled;
                this.netCCPriceNotBilled = existingSubtotal.netCCPriceNotBilled;
            } 
            if (suborderType == 'UC') {
                this.ucSubTotals += suborderTotal;
                this.netUCPriceNotBilled += netSuborderTotal;
            }
            if (suborderType == 'CC') {
                this.ccSubTotals += suborderTotal;
                this.netCCPriceNotBilled += netSuborderTotal;
            }
            this.netListPriceTotal += netListPrice;
            this.netPricTotal += netSuborderTotal;
            this.netDiscountTotal += (netListPriceTotal - netPricTotal) ;
            
        }
    }
}