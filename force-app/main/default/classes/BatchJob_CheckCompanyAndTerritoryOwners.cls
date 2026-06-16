global without sharing class BatchJob_CheckCompanyAndTerritoryOwners implements Database.Batchable<sObject>, Schedulable {
    Integer nDays = 1;

    public BatchJob_CheckCompanyAndTerritoryOwners(){
    }
    public BatchJob_CheckCompanyAndTerritoryOwners(Integer nDays) {
        this.nDays = nDays;
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
                'SELECT AH_Territory_Name__c,AH_Owner__c,AH_Alternate_Owner__c,Territory__c,Territory__r.LastModifiedDate ' +
                        'FROM Account_Hierarchy__c ' +
                        'WHERE LastModifiedDate >= LAST_N_DAYS: ' + nDays +
                        'OR Territory__r.LastModifiedDate >= LAST_N_DAYS: ' + nDays
        );
    }

    global void execute(Database.BatchableContext param1, List<sObject> scope) {
        Account_Hierarchy__c[] companies = (List<Account_Hierarchy__c>) scope;
        List<Account_Hierarchy__c> result = execute(companies);
        if (result.size() > 0) {
            update result;
        }

    }

    global void finish(Database.BatchableContext context) {
    }

    global void execute(SchedulableContext context) {
        BatchJob_CheckCompanyAndTerritoryOwners batch = new BatchJob_CheckCompanyAndTerritoryOwners(nDays);
        Database.executeBatch(batch);
    }

    global static List<Account_Hierarchy__c> execute(List<Account_Hierarchy__c> companies){
        Set<String> territoryIds = new Set<String>();
        Map<Id, Account_Hierarchy__c> result = new Map<Id, Account_Hierarchy__c>();
        for (Account_Hierarchy__c currentCompany : companies) {
            territoryIds.add(currentCompany.Territory__c);
        }

        Map<ID, Territory_Data__c> territoriesMap = new Map<ID, Territory_Data__c>([
                SELECT Id,Territory_Owner__c,Alternate_Owner__c,Name
                FROM Territory_Data__c
                WHERE Id IN :territoryIds
        ]);
        Territory_Data__c currentTerritory;

        for (Account_Hierarchy__c currentCompany : companies) {
            if (!String.isBlank(currentCompany.Territory__c)) {
                currentTerritory = territoriesMap.get(currentCompany.Territory__c);
                if (String.isBlank(currentCompany.AH_Territory_Name__c)
                        || !currentCompany.AH_Territory_Name__c.equals(currentTerritory.Name)) {
                    currentCompany.AH_Territory_Name__c = currentTerritory.Name;
                    result.put(currentCompany.Id, currentCompany);
                }
                if (String.isBlank(currentCompany.AH_Owner__c)
                        || !currentCompany.AH_Owner__c.equals(currentTerritory.Territory_Owner__c)) {
                    currentCompany.AH_Owner__c = currentTerritory.Territory_Owner__c;
                    result.put(currentCompany.Id, currentCompany);
                }
                if (String.isBlank(currentCompany.AH_Alternate_Owner__c)
                        || !currentCompany.AH_Alternate_Owner__c.equals(currentTerritory.Alternate_Owner__c)) {
                    currentCompany.AH_Alternate_Owner__c = currentTerritory.Alternate_Owner__c;
                    result.put(currentCompany.Id, currentCompany);
                }
            }
        }
        return result.values();
    }
}