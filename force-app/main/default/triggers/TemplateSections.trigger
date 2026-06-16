trigger TemplateSections on TemplateSections__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete) {

        new Triggers()

            .bind(Triggers.Evt.beforeinsert, new TemplateSectionTriggerHandler.PopulateExternalId())
            .manage();
}