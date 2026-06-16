trigger ServiceInfo on ServiceInfo__c (after update) {
    new Triggers()
        .bind(Triggers.Evt.afterupdate, new ServiceInfoHandler.RunProcessOrderSentAfterActions())
        .manage();
}