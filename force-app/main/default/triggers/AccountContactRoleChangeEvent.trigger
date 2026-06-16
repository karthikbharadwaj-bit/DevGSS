trigger AccountContactRoleChangeEvent on AccountContactRoleChangeEvent(after insert) {
    new Triggers()
        .bind(Triggers.Evt.afterinsert, new AccountContactRoleChangeEventHandler.SyncWithTechnicalAccounts())
        .bind(Triggers.Evt.afterinsert, new AccountContactRoleChangeEventHandler.UpdateRelatedContact())
        .manage();
}