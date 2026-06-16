public with sharing class ProServProjectData {

    public Proserv_Project__c retrieveProServByQuoteNumber(String quoteNumber){

        List<Proserv_Project__c> proservList = new List<Proserv_Project__c>();
        if (quoteNumber != null) {
            proservList = [SELECT Id, PS_Health_Status_Color_Message__c,
                           PS_Health_Status_Project_Color__c
                           FROM Proserv_Project__c
                           WHERE PS_Quote_Number__c = :quoteNumber];
        }
        if (!proservList.isEmpty()) {
            return proservList[0];
        } else {
            return null;
        }
        
    }

    public List<Proserv_Project__c> retrieveProservs(Set<Id> proServIds) {
        List<Proserv_Project__c> proservList = new List<Proserv_Project__c>();
        if (!proServIds.isEmpty()) {
            proservList = [SELECT Id, PS_Health_Status_Color_Message__c,
                            PS_Health_Status_Project_Color__c
                            FROM Proserv_Project__c
                            WHERE Id IN :proServIds];
        }
        if (!proservList.isEmpty()) {
            return proservList;
        } else {
            return null;
        }
    }
}