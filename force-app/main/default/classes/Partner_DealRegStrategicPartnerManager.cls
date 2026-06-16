public without sharing class Partner_DealRegStrategicPartnerManager {

    public static List<Strategic_Partner_Account__c> getStrategicPartnerManagers(String userName){
        String query;
        List<Strategic_Partner_Account__c> strategicPartnerManagers = new List<Strategic_Partner_Account__c>();
        if(userName!=null && userName!=''){
            query='select Country__c, VAR_Territory__c, Strategic_Partner_Manager__c, '
                + 'Strategic_Partner_Manager__r.Id, Strategic_Partner_Manager__r.Full_Name__c, Strategic_Partner_Manager__r.Email '
                + 'from Strategic_Partner_Account__c';
            String searchKey =  '\'%'+userName + '%\'';
            query += ' where Strategic_Partner_Manager__r.Full_Name__c Like '+searchKey;
            query += ' and Strategic_Partner_Manager__r.IsActive = true order by Strategic_Partner_Manager__r.Full_Name__c asc';
            system.debug('query - '+query);
            strategicPartnerManagers = Database.query(query);
        }
        return strategicPartnerManagers; 
    }
}