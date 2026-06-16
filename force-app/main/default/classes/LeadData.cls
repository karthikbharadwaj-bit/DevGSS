public without sharing class LeadData implements ILeadData{

    public Interface ILeadData{
        List<Lead> retrieveLeads(Set<Id> leadIds);
        List<Lead> retrieveLeadsByOwnerRoutingReason(Id leadOwnerId, Set<String> routingReasons);
    }

    public List<Lead> retrieveLeads(Set<Id> leadIds){
        return [SELECT Id, OwnerId, Routing_Reason__c
                FROM Lead
                WHERE Id IN : leadIds];
    }

    public List<Lead> retrieveLeadsByOwnerRoutingReason(Id leadOwnerId, Set<String> routingReasons){
        return [SELECT Id, OwnerId, Routing_Reason__c
                FROM Lead
                WHERE OwnerID =: leadOwnerId
                AND Routing_Reason__c IN: routingReasons
                ORDER BY LastModifiedDate ASC
                LIMIT 50];
    }

    public class LeadDataMock implements ILeadData {
        public List<Lead> leadsToReturn = new List<Lead>();

        public List<Lead> retrieveLeads(Set<Id> leadIds){
            return leadsToReturn;
        }
        public List<Lead> retrieveLeadsByOwnerRoutingReason(Id leadOwnerId, Set<String> routingReasons){
            return leadsToReturn;
        }

    }

}