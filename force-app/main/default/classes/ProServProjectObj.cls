public with sharing class ProServProjectObj {

    public void populateOrderProServId (List<ProServ_Project__c> projects) {
        Map<Id, Id> orderProject = new Map<Id, Id>();
        List<Order> orders = new List<Order>();

        for (ProServ_Project__c project : projects) {

            if (project.Order__c != null) {
                orderProject.put(project.Order__c, project.Id);               
            }
        }
        
        if (orderProject.size() > 0) {

            orders = [SELECT Id, ProServProject__c 
                        FROM Order 
                        WHERE Id IN :orderProject.keySet()];

            for (Order ord : orders) {
                ord.ProServProject__c = orderProject.get(ord.Id);
            }                            
        }

        if(orders.size() > 0) {
            update orders;
        }
        
    }

    public void populatePhaseProServId (List<ProServ_Project__c> projects) {
        //Find Phase with OriginalQuoteNumber = PS Quote Number
        Map<String, Id> quoteNumberProject = new Map<String, Id>();
        List<Phase__c> phases = new List<Phase__c>();

        for (ProServ_Project__c project : projects) {

            if (project.PS_Quote_Number__c != null) {
                quoteNumberProject.put(project.PS_Quote_Number__c, project.Id);               
            }            
        }

        if (quoteNumberProject.size() > 0) {

            phases = [SELECT Id, OriginalQuoteNumber__c, OriginalQuoteNumber__r.QuoteNumber
                      FROM Phase__c 
                      WHERE OriginalQuoteNumber__r.QuoteNumber IN :quoteNumberProject.keySet()];

            for (Phase__c phase : phases) {
                phase.ProServProject__c = quoteNumberProject.get(phase.OriginalQuoteNumber__r.QuoteNumber);
            }           
        }

        if(phases.size() > 0) {
            update phases;
        }
    }

    public static Proserv_Project__c createProject(Order order) {
        Proserv_Project__c proservProject = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Order__c => order.Id,
                Proserv_Project__c.Account__c => order.AccountId,
                Proserv_Project__c.Opportunity__c => order.OpportunityId,
                Proserv_Project__c.Quote__c => order.QuoteId,
                Proserv_Project__c.CurrencyIsoCode => order.CurrencyIsoCode,
                Proserv_Project__c.Project_Complexity__c => order.Quote?.PSProjectComplexity__c,
                Proserv_Project__c.Timezone__c => order.Account?.Timezone__c
            })
            .build()
            .getRecord();

        return proservProject;
    }
}