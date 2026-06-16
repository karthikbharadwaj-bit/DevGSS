public class BatchJob_QuotesAndQLIsMPRemediation implements Database.Batchable<sObject> {
    public String query = '';
    public Boolean switchOffTriggers = false;
    public Map<String, String> oppTierToServiceName = new Map<String, String> {
        'RC Office' => 'Office',
        'Office' => 'Office',
        'Fax' => 'Fax',
        'RC Meetings' => 'Meetings',
        'Meetings' => 'Meetings',
        'Engage Voice Standalone' => 'Engage Voice Standalone',
        'Engage Digital Standalone' => 'Engage Digital Standalone',
        'RingCentral Contact Center' => 'RingCentral Contact Center',
        'Engage Digital Legacy' => 'Engage Digital Legacy',
        'Engage Voice Legacy' => 'Engage Voice Legacy'
    };

    public BatchJob_QuotesAndQLIsMPRemediation(String customQuery, Boolean switchOffTriggers) {
        this.query = customQuery;
        this.switchOffTriggers = switchOffTriggers;
    }
 
    public Database.QueryLocator start(Database.BatchableContext BC){
       return Database.getQueryLocator(query);
    }
 
    public void execute(Database.BatchableContext BC, List<Quote> scope){
        List<QuoteLineItem> qlisToUpdate = new List<QuoteLIneItem>();
        List<Quote> quotesToUpdate = new List<Quote>();

        for (Quote quoteItem : scope) {
            if (quoteItem.Opportunity.Tier_Name__c == null || oppTierToServiceName.get(quoteItem.Opportunity.Tier_Name__c) == null) {
                continue;
            }
            
            quoteItem.ServiceName__c = oppTierToServiceName.get(quoteItem.Opportunity.Tier_Name__c);
            quotesToUpdate.add(quoteItem);
            for (QuoteLineItem qli : quoteItem.QuoteLineItems) {
                qli.ServiceName__c = oppTierToServiceName.get(quoteItem.Opportunity.Tier_Name__c);
                qlisToUpdate.add(qli);
            }
        }

        if (this.switchOffTriggers) {
            Triggers.switchOff();
        }

        if (!qlisToUpdate.isEmpty()) {
            update qlisToUpdate;
        }

        if (!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
        }
    }
 
    public void finish(Database.BatchableContext BC){
    }
 }