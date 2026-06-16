trigger Test_TriggersByAccount on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (!Test.isRunningTest()) {
        return;
    }

    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.TestTriggerHandler())
        .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.TestTriggerHandler())
        .bind(Triggers.Evt.beforedelete, new AccountTriggerHandler.TestTriggerHandler())
        .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.TestTriggerHandler())
        .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.TestTriggerHandler())
        .bind(Triggers.Evt.afterdelete, new AccountTriggerHandler.TestTriggerHandler())
        .bind(Triggers.Evt.afterundelete, new AccountTriggerHandler.TestTriggerHandler())
        .manage();
}