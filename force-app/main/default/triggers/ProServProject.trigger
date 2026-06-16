trigger ProServProject on ProServ_Project__c (
    before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete) {
    
    new Triggers()
            .bind(Triggers.Evt.afterinsert, new ProServProjectTriggerHandler.ProServProjectAfter())

            .bind(Triggers.Evt.afterupdate, new ProServProjectTriggerHandler.ProServProjectAfter())

            .manage();
}