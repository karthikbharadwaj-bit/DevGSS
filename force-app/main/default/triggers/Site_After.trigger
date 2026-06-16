trigger Site_After on Site__c (after update, after insert) {

  // B-802 Updated Order and Site Object for CloudConnect
  if( Trigger.isAfter ) {
    if( Trigger.isUpdate ) {
      SiteAfterTriggerHandler.updateOrders( Trigger.newMap );
      SiteAfterTriggerHandler.autoLockOrder(Trigger.newMap);
    }
  }
}