trigger PartnerRequest on Partner_Request__c (
    before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete)
{
    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new PartnerRequestTriggerHandler.ProcessPhoneAndTypeBeforeInsert())
        .bind(Triggers.Evt.beforeinsert, new PartnerRequestTriggerHandler.PartnerRequestBeforeInsert())
        .bind(Triggers.Evt.beforeupdate, new PartnerRequestTriggerHandler.ProcessPhoneBeforeUpdate())
        .bind(Triggers.Evt.afterinsert, new PartnerRequestTriggerHandler.PartnerRequestAfterInsert())
        .bind(Triggers.Evt.afterupdate, new PartnerRequestTriggerHandler.PartnerRequestAfterUpdate())
        .manage();

}