public with sharing class SuborderTriggerHandler {

    public class PopulateOrderSubTotals extends Triggers.TriggerHandlerBase {
        override public void handle () {
            Set<Id> orderIds = new Set<Id>();
            for (Suborder__c suborder : (List<Suborder__c>) triggerRecords) {
                if (suborder.Order__c != null) {
                    orderIds.add(suborder.Order__c);
                }
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

    public class UpdatePSIntegrationRecords extends Triggers.TriggerHandlerBase {
        Set<SObjectField> fieldsToCheck = new Set<SObjectField>{
            Suborder__c.Suborder_Type__c,
            Suborder__c.SumOfOneTimeItems__c
        };
        override public void handle() {
            List<PS_Integration__c> psIntegrationsRecordsToUpdate = new List<PS_Integration__c>();
            Set<Id> suborderIds = new Set<Id>();

            if(Trigger.isDelete){
                psIntegrationsRecordsToUpdate = PSIntegrationHelper.updatePSRecordsOnSuborderDelete(((Map<Id, Suborder__c>)Trigger.oldMap).keySet());
            }else{
                Map<Id, List<Suborder__c>> orderToSuborderUpdateListMap = new Map<Id, List<Suborder__c>>();
                for (Suborder__c suborder : (List<Suborder__c>) Trigger.new) {
                    if (checkEligiblePSRecordOnUpdate(suborder) || checkEligiblePSRecordOnInsert(suborder)){
                        if (!orderToSuborderUpdateListMap.containsKey(suborder.Order__c)) {
                            orderToSuborderUpdateListMap.put(suborder.Order__c, new List<Suborder__c>());
                        }
                        orderToSuborderUpdateListMap.get(suborder.Order__c).add(suborder);
                    } else if (suborder.Status__c == SuborderHelper.STATUS_NEW &&
                        isChangedAnyField(suborder, fieldsToCheck)
                    ) {
                        suborderIds.add(suborder.Id);
                    }
                }
                if (!orderToSuborderUpdateListMap.isEmpty()) {
                    psIntegrationsRecordsToUpdate = PSIntegrationHelper.buildPSRecords(orderToSuborderUpdateListMap, Trigger.isUpdate);
                }
                System.debug('suborderIds >> ' + suborderIds);
                if (!suborderIds.isEmpty()) {
                    // Get the related PS Integration records
                    List<PS_Integration__c> psIntegrationsToUpdate = new PSIntegrationSelector()
                        .selectPSIntegrationsBySubOrderIds(new List<Object> { subOrderIds })
                        .executeQuery();
                    // update the PS Integration records to get the LastModifiedDate updated 
                    if (!psIntegrationsToUpdate.isEmpty()) {
                        update psIntegrationsToUpdate;
                    }
                }
            }

            if(!psIntegrationsRecordsToUpdate.isEmpty()){
                upsert psIntegrationsRecordsToUpdate;
            }
        }

        private boolean checkEligiblePSRecordOnUpdate(Suborder__c suborder) {
            return Trigger.isUpdate && isChangedField(suborder, Suborder__c.Status__c) && 
                (suborder.Status__c == SuborderHelper.STATUS_NEW  ||  suborder.Status__c == SuborderHelper.STATUS_BILLED ||  suborder.Status__c == SuborderHelper.STATUS_FAILED);
        }

        private boolean checkEligiblePSRecordOnInsert(Suborder__c suborder) {
            return Trigger.isInsert && suborder.Status__c == SuborderHelper.STATUS_NEW;
        }
    }

    public class PopulateMaxSubOrderNumberOnOrder extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> orderIdSet = new Set<Id>();
            Set<Id> subordersToDeleteIdSet = new Set<Id>();

            for (Suborder__c suborder : (List<Suborder__c>) this.triggerRecords) {
                if (suborder.Order__c == null) {
                    continue;
                }
                if (Trigger.isInsert) {
                    orderIdSet.add(suborder.Order__c);
                } else if (Trigger.isUpdate &&
                    (isChangedField(suborder, Suborder__c.Order__c) || isChangedField(suborder, Suborder__c.SuborderNumber__c))) {
                    orderIdSet.add(suborder.Order__c);
                } else if (Trigger.isDelete) {
                    orderIdSet.add(suborder.Order__c);
                    subordersToDeleteIdSet.add(suborder.Id);
                }
            }

            if (orderIdSet.isEmpty()) {
                return;
            }

            List<Order> ordersToUpdate = new List<Order>();
            List<Order> orderList = (List<Order>) new OrderSelector()
                .selectOrdersWithSuborders(new List<Object> {orderIdSet, subordersToDeleteIdSet})
                .executeQuery();
            for (Order ord : orderList) {
                Integer suborderNum = findMaxSubOrderNumber(ord.Suborders__r);
                if (ord.MaxPhaseNumber__c == null || suborderNum > ord.MaxPhaseNumber__c) {
                    ord.MaxPhaseNumber__c = suborderNum;
                    ordersToUpdate.add(ord);
                }
            }

            if (!ordersToUpdate.isEmpty()) {
                Triggers.switchOff();
                update ordersToUpdate;
                Triggers.switchOn();
            }
        }

        private Integer findMaxSubOrderNumber(List<Suborder__c> suborders) {
            Integer result = 0;
            if (suborders == null || suborders.isEmpty()) {
                return result;
            }

            for (Suborder__c so : suborders) {
                Integer suborderNum = so.SuborderNumber__c == null ? 0 : (Integer) so.SuborderNumber__c;
                if (result != Math.max(result, suborderNum)) {
                    result = suborderNum;
                }
            }

            return result;
        }
    }
}