trigger ContentDocumentTrigger on ContentDocument (after Insert, after update, before delete) {
	 new Triggers()
        .bind(Triggers.Evt.afterinsert, new ContentDocumentTriggerHelper.CloneContentDocumentToAttachment())
        .bind(Triggers.Evt.afterupdate, new ContentDocumentTriggerHelper.CloneContentDocumentToAttachment())
        .bind(Triggers.Evt.beforedelete, new ContentDocumentTriggerHelper.CloneContentDocumentToAttachment())
        .manage();
}