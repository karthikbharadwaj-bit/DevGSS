trigger TemplateSectionJunction on TemplateSectionJunction__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete) {

        new Triggers()

            .bind(Triggers.Evt.beforeinsert, new TemplateSectionJunctionTriggerHandler.PopulateExternalId())
            .manage();
}