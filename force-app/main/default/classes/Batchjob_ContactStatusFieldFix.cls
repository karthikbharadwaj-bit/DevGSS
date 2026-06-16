public with sharing class Batchjob_ContactStatusFieldFix implements Database.Batchable<sObject> {
    DateTime startDate;
    DateTime endDate;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return new OpportunityContactRoleSelector()
            .selectOCRForFixContactStatusField(new List<Object>{ startDate, endDate })
            .executeQueryLocator();
    }

    public Batchjob_ContactStatusFieldFix(DateTime startDate, DateTime endDate) {
        this.startDate = startDate;
        this.endDate = endDate;
    }

    public void execute(Database.BatchableContext ctx, List<sObject> oppCRs) {
        Map<Id, Contact> contactById = new Map<Id, Contact>();

        for (OpportunityContactRole oppCR : (List<OpportunityContactRole>) oppCRs) {
            Contact contToUpdate = contactById.containsKey(oppCR.ContactId) ? contactById.get(oppCR.ContactId) : new Contact(Id = oppCR.ContactId);

            if (oppCR.Contact.Account_Status__c != null && (oppCR.Contact.Account_Status__c == 'Paid' || oppCR.Contact.Account_Status__c.containsIgnoreCase('trial'))) {
                if (!oppCR.Contact.Customer_record__c) {
                    String quotedProducts = String.isBlank(oppCR.Contact.Quoted_Products__c) ? '' : oppCR.Contact.Quoted_Products__c;
                    contToUpdate.Contact_Status__c = '4. Customer';
                    contToUpdate.Customer_Record__c = true;
                    contToUpdate.Quoted_Products__c = ContactUpdatePlatformEventsHelper.getQuotedProducts(oppCR.Opportunity, quotedProducts);
                }
            } else {
                contToUpdate.Contact_Status__c = '3.5 Closed Won Opp';
            }

            contactById.put(contToUpdate.Id, contToUpdate);
        }
        
        if (!contactById.isEmpty()) {
            DG_DFR_Class.byPassDFRContact = true;
            update contactById.values();
        }
    }

    public void finish(Database.BatchableContext BC) {
    }
}