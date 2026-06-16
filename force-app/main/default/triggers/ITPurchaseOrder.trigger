trigger ITPurchaseOrder on IT_Purchase_Order__c (before insert, before update){
    new Triggers()

        .bind(Triggers.Evt.beforeupdate, new ITPurchaseOrderTriggerHelper.SetLocationAndDepartment())

        .manage();
}