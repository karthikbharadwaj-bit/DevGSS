trigger RCQuoteTemplate on RC_Quote_Template__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete) {

        new Triggers()

            .bind(Triggers.Evt.beforeinsert, new RCQuoteTemplateTriggerHandler.PopulateExternalId())
            .manage();
}