/**********************************************************************************************************
Created By:     eugenebasianomutya
Created Date:   10182016
Description:    Trigger of Resource Object
**********************************************************************************************************/

trigger Resource on Resources__c(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete, 
    after undelete) {
        new Triggers()
            .bind(Triggers.Evt.beforeinsert, new ResourceTriggerHandler.ResourceBefore())
            .bind(Triggers.Evt.beforeupdate, new ResourceTriggerHandler.ResourceBefore())
            .bind(Triggers.Evt.beforedelete, new ResourceTriggerHandler.ResourceBefore())

            .bind(Triggers.Evt.afterinsert, new ResourceTriggerHandler.ResourceAfter())
            .bind(Triggers.Evt.afterupdate, new ResourceTriggerHandler.ResourceAfter())
            .bind(Triggers.Evt.afterdelete, new ResourceTriggerHandler.ResourceAfter())
            .bind(Triggers.Evt.afterundelete, new ResourceTriggerHandler.ResourceAfter())

            .bind(Triggers.Evt.afterinsert, new ResourceTriggerHandler.CalculateTotalEstimateOnProject())
            .bind(Triggers.Evt.afterupdate, new ResourceTriggerHandler.CalculateTotalEstimateOnProject())
            .bind(Triggers.Evt.afterdelete, new ResourceTriggerHandler.CalculateTotalEstimateOnProject())
            .bind(Triggers.Evt.afterundelete, new ResourceTriggerHandler.CalculateTotalEstimateOnProject())

            .manage();
}