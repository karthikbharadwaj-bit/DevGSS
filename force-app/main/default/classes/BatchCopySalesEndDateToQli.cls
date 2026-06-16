public with sharing class BatchCopySalesEndDateToQli implements Database.Batchable<sObject>, Database.Stateful {

    private String query;

    public BatchCopySalesEndDateToQli() {
        this.query = 'SELECT Product2.SalesEndDate__c' +
                    ' FROM QuoteLineItem' +
                    ' WHERE Product2.SalesEndDate__c != null' +
                    ' AND Quote.RecordTypeId = \'' + QuoteHelper.RT_ID_BILLING + '\'';
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<QuoteLineItem> qliList = (List<QuoteLineItem>) scope;

        for(QuoteLineItem qli : qliList) {
            qli.SalesEndDate__c = qli.Product2.SalesEndDate__c;
        }

        Triggers.switchOff();
        update qliList;
        Triggers.switchOn();
    }

    public void finish(Database.BatchableContext BC) {

    }

}