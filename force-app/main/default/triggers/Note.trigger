trigger Note on Note (
        before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete) {

    new Triggers()
        .bind(Triggers.Evt.afterinsert, new NoteTriggerHelper.NoteAfterInsertUpdate())

        .bind(Triggers.Evt.afterupdate, new NoteTriggerHelper.NoteAfterInsertUpdate())

        .bind(Triggers.Evt.beforedelete, new NoteTriggerHelper.NoteBeforeDelete())
        .manage();
}