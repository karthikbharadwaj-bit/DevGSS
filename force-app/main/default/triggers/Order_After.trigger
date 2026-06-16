trigger Order_After on Order (after insert, after update) {
    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger != null && bypassTrigger.Bypass_Order_Trigger__c == true) {
             System.debug('$$$ ByPassTrigger__c Active For Order Credit $$$');
            return;
        }
    new Triggers()
        .bind(Triggers.Evt.afterinsert, new OrderAfterTriggerHandler.CreateOrderItemsForNewOrders())
        .bind(Triggers.Evt.afterinsert, new OrderTriggerHelper.CreateSupportEntitlementsRecords())
        .bind(Triggers.Evt.afterupdate, new OrderAfterTriggerHandler.UpdateTotalFieldsOnPackage())
        .manage();
  // B-802 Updated Order and Site Object for CloudConnect
  if( Trigger.isAfter ) {
    if( Trigger.isInsert ) {
      OrderAfterTriggerHandler.insertOrders( Trigger.newMap );
      OrderAfterTriggerHandler.sendMessages( Trigger.newMap );
      OrderAfterTriggerHandler.createPhases( Trigger.newMap );
      OrderAfterTriggerHandler.mapPhaseToOrder( Trigger.newMap );
      // OrderAfterTriggerHandler.shareOrders( Trigger.newMap );
      OrderAfterTriggerHandler.updateAccsWithProServOrders( Trigger.new );
    }
    if( Trigger.isUpdate ) {
      OrderAfterTriggerHandler.activateOrdersAuto( Trigger.newMap );
      OrderAfterTriggerHandler.syncEntitlements(Trigger.oldMap, Trigger.newMap);
      OrderAfterTriggerHandler.createCreditMemo(Trigger.oldMap, Trigger.newMap);

        // Mavenlink integration logic
        Set<Id> orderId = new Set<Id>();
        for(Order ord : (List<Order>) Trigger.new) {
            if (isChangedFieldFrom(ord, Order.OrderNumber, null)
                || isChangedField(ord, Order.RecordTypeId)
                || isChangedFieldFrom(ord, Order.SOW_Type__c, null)
                || isChangedFieldFrom(ord, Order.Signed_SOW__c, null)
                || isChangedFieldFrom(ord, Order.Account_UID__c, null)) {
                orderId.add(ord.Id);
            }
        }
        if (!orderId.isEmpty()) {
            PhaseTriggerHandler.updateRelatedPhases('Order', orderId);
        }
        // End of Mavenlink integration logic
    }
  }

    private Boolean isChangedFieldFrom(Order record, sObjectField field, object fromValue) {
        return oldValue(record, field) == fromValue && isChangedField(record, field);
    }

    private Object oldValue(Order record, sObjectField field) {
        if (Trigger.isUpdate || Trigger.isDelete) {
            return oldRecord(record).get(field);
        } else {
            return null;
        }
    }

    private sObject oldRecord(sObject record) {
        if (Trigger.isUpdate || Trigger.isDelete) {
            return Trigger.oldMap.get(record.Id);
        }
        else {
            return null;
        }
    }

    private Boolean isChangedField(Order record, sObjectField field) {
        if (Trigger.isInsert || Trigger.isUndelete) {
            return record.get(field) != null;
        } else if (Trigger.isDelete) {
            return Trigger.oldMap.get(record.Id).get(field) != null;
        } else if (Trigger.isUpdate) {
            return record.get(field) != Trigger.oldMap.get(record.Id).get(field);
        } else {
            return false;
        }
    }
}