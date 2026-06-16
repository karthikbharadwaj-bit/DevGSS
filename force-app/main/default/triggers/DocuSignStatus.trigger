trigger DocuSignStatus on dsfs__DocuSign_Status__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete) {

        new Triggers()
            .bind(Triggers.Evt.beforeinsert, new DocuSignStatusTriggerHandler.PrepopulateFields())
            
            .bind(Triggers.Evt.afterinsert, new DocuSignStatusTriggerHandler.SetOldAgreementExecuted())
            .bind(Triggers.Evt.afterinsert, new DocuSignStatusTriggerHandler.DocuSign_ChangeQuoteStatusAccordingly())
            .bind(Triggers.Evt.afterinsert, new DocuSignStatusTriggerHandler.DocuSign_ChangeEnvelopeStatus())
		
            .bind(Triggers.Evt.afterupdate, new DocuSignStatusTriggerHandler.SetOldAgreementExecuted())
            .bind(Triggers.Evt.afterupdate, new DocuSignStatusTriggerHandler.DocuSign_ChangeQuoteStatusAccordingly())
            .bind(Triggers.Evt.afterupdate, new DocuSignStatusTriggerHandler.DocuSign_ChangeEnvelopeStatus())

            .bind(Triggers.Evt.afterupdate, new DocuSignStatusTriggerHandler.PopulateAccountNdaStatus())

            .manage();
        
}