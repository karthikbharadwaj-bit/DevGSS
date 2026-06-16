public with sharing class SuborderLineItemTriggerHandler {

    public class PopulateSuborderSumOfAllItems extends Triggers.TriggerHandlerBase {

        override public void handle () {
            Set<Id> suborderIds = new Set<Id>();
            for (SuborderLineItem__c sli : (List<SuborderLineItem__c>) triggerRecords) {
                if (sli.Suborder__c != null) {
                    suborderIds.add(sli.Suborder__c);
                }
            }

            if (suborderIds.isEmpty()) {
                return;
            }

            List<Suborder__c> suborders = (List<Suborder__c>) new SuborderSelector()
                .selectSubordersByIdAndStatus(suborderIds, SuborderHelper.STATUS_NEW)
                .executeQuery();
            Set<Id> parentSuborderIds = new Set<Id>();
            for (Suborder__c suborder : suborders) {
                Decimal sumOfOneTimeItems = 0;
                Decimal sumOfRecurringItems = 0;

                for (SuborderLineItem__c suborderLineItem : suborder.SuborderLineItems__r) {
                    if (suborderLineItem.SalesAgreementLineItem__r.ChargeTerm__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                        sumOfOneTimeItems += suborderLineItem.Quantity__c * suborderLineItem.SalesAgreementLineItem__r.EffectivePriceNew__c;
                    } else {
                        sumOfRecurringItems += suborderLineItem.Quantity__c * suborderLineItem.SalesAgreementLineItem__r.EffectivePriceNew__c;
                    }
                }
                if(suborder.SumOfOneTimeItems__c != sumOfOneTimeItems) {
                    parentSuborderIds.add(suborder.Id);
                }
                suborder.SumOfOneTimeItems__c = sumOfOneTimeItems;
                suborder.SumOfRecurringItems__c = sumOfRecurringItems;
            }

            Triggers.switchOff();
            update suborders;
            Triggers.switchOn();

            // Logic to update PS Integration Records if corresponding Suborder's SumOfOneTimeItems__c is updated
            if (!parentSuborderIds.isEmpty()) {
                List<PS_Integration__c> psIntegrationsToUpdate = new PSIntegrationSelector()
                    .selectPSIntegrationsBySubOrderIds(new List<Object> { parentSuborderIds })
                    .executeQuery();
                if (!psIntegrationsToUpdate.isEmpty()) {
                    update psIntegrationsToUpdate;
                }
            }
        }
    }

    public class PopulateOrderSubTotals extends Triggers.TriggerHandlerBase {
        override public void handle () {
            Set<Id> suborderIds = new Set<Id>();
            Set<Id> orderIds = new Set<Id>();
            for (SuborderLineItem__c sli : (List<SuborderLineItem__c>) triggerRecords) {
                if (sli.Suborder__c != null) {
                    suborderIds.add(sli.Suborder__c);
                }
            }

            if (suborderIds.isEmpty()) {
                return;
            }

            List<Suborder__c> suborders = (List<Suborder__c>) new SuborderSelector()
                .selectSubordersByIdAndStatus(suborderIds, SuborderHelper.STATUS_NEW)
                .executeQuery();
            
            for (Suborder__c suborder : suborders) {
                orderIds.add(suborder.Order__c);
            }
            List<Order> ordersToUpdate = new List<Order>();
            ordersToUpdate = SuborderHelper.getOrdersWithSubTotals(orderIds);
            if (!ordersToUpdate.isEmpty()) {
                Triggers.switchOff();
                update ordersToUpdate;
                Triggers.switchOn();
            }
        }
    }
}