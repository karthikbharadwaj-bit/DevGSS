trigger ContentVersion on ContentVersion (after insert, after update) {
    new Triggers()
        .bind(Triggers.Evt.afterinsert, new ContentVersionTriggerHelper.DocuSignDocumentsProcessing())
        .bind(Triggers.Evt.afterupdate, new ContentVersionTriggerHelper.DocuSignDocumentsProcessing())
        .bind(Triggers.Evt.afterupdate, new ContentVersionTriggerHelper.HandleAfterUpdateProcessing())
        .manage();
}