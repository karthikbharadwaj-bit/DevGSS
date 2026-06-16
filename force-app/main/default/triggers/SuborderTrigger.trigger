trigger SuborderTrigger on Suborder__c (after insert, after update, after delete, before delete) {

    new Triggers()
        .bind(Triggers.Evt.afterinsert, new SuborderTriggerHandler.PopulateOrderSubTotals())
        .bind(Triggers.Evt.afterupdate, new SuborderTriggerHandler.PopulateOrderSubTotals())
        .bind(Triggers.Evt.afterdelete, new SuborderTriggerHandler.PopulateOrderSubTotals())

        .bind(Triggers.Evt.afterinsert, new SuborderTriggerHandler.UpdatePSIntegrationRecords())
        .bind(Triggers.Evt.afterupdate, new SuborderTriggerHandler.UpdatePSIntegrationRecords())
        .bind(Triggers.Evt.beforedelete, new SuborderTriggerHandler.UpdatePSIntegrationRecords())

        .bind(Triggers.Evt.afterinsert, new SuborderTriggerHandler.PopulateMaxSubOrderNumberOnOrder())
        .bind(Triggers.Evt.afterupdate, new SuborderTriggerHandler.PopulateMaxSubOrderNumberOnOrder())
        .bind(Triggers.Evt.afterdelete, new SuborderTriggerHandler.PopulateMaxSubOrderNumberOnOrder())

        .manage();
}