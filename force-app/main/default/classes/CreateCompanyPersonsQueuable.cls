public without sharing class CreateCompanyPersonsQueuable implements Queueable {

    Map<Id, Lead> leads = new Map<Id, Lead>();
    Map<Id, Lead> oldLeads = new Map<Id, Lead>();
    Set<Id> leadsToBeDeleted = new Set<Id>();

    public CreateCompanyPersonsQueuable(Map<Id, Lead> leadItems, Map<Id, Lead> oldLeadItems, Set<Id> leadsToBeDeleted) {
        this.leads = leadItems;
        this.oldLeads = oldLeadItems;
        this.leadsToBeDeleted = leadsToBeDeleted;
    }

    public void execute(QueueableContext queContext) {
        List<Company_Persons__c> persons = new List<Company_Persons__c>();

        Boolean leadIdNotNull = (LeadsToBeDeleted == null || LeadsToBeDeleted.size() == 0);
        for (Lead ld : leads.values()) {
            if (ld.AH_Name__c != null
                    && (oldLeads == null
                        || ld.AH_Name__c != oldLeads.get(ld.Id).AH_Name__c)) {
                Company_Persons__c cp = new Company_Persons__c(
                        Company__c = ld.AH_Name__c,
                        Lead__c = leadIdNotNull ? ld.Id : (LeadsToBeDeleted.contains(ld.Id) ? null : ld.Id)
                );
                persons.add(cp);
            }
        }

        if (persons.size() > 0) {
            insert persons;
        }
    }  
}