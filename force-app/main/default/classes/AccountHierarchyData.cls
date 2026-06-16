public without sharing class AccountHierarchyData implements IAccountHierarchyData{

    public Interface IAccountHierarchyData{
        List<Account_Hierarchy__c> getAccountHierarchiesByDunsNumber(Set<String> dunsNumbers);
        List<Account_Hierarchy__c> insertAccountHierarchies(List<Account_Hierarchy__c> accountHierarchies);
        List<Account_Hierarchy__c> getAccountHierarchiesByCountryDomain(Set<String> countryDomain);
        List<Account_Hierarchy__c> getAccountHierarchiesById(Set<Id> accountHierarchyIds);
    }

    public List<Account_Hierarchy__c> getAccountHierarchiesByDunsNumber(Set<String> dunsNumbers){
        return [SELECT Id, D_U_N_S_Number__c, Country_Domain__c 
                FROM Account_Hierarchy__c
                WHERE D_U_N_S_Number__c IN : dunsNumbers
                AND (Company_Status__c != null AND Company_Status__c != 'Invalid')];
    }

    public List<Account_Hierarchy__c> getAccountHierarchiesByCountryDomain(Set<String> countryDomain){
        return [SELECT Id, D_U_N_S_Number__c, Country_Domain__c 
                FROM Account_Hierarchy__c
                WHERE Country_Domain__c IN : countryDomain
                AND (Company_Status__c != null AND Company_Status__c != 'Invalid')];
    }

    public List<Account_Hierarchy__c> insertAccountHierarchies(List<Account_Hierarchy__c> accountHierarchies){
        insert accountHierarchies;
        return accountHierarchies;
    }

    public List<Account_Hierarchy__c> getAccountHierarchiesById(Set<Id> accountHierarchyIds){
        return [SELECT Id, Name, D_U_N_S_Number__c, Country_Domain__c 
                FROM Account_Hierarchy__c
                WHERE Id IN : accountHierarchyIds];
    }

    public class AccountHierarchyDataMock implements IAccountHierarchyData{
        public List<Account_Hierarchy__c> accountHierarchiesToReturn;

        public List<Account_Hierarchy__c> getAccountHierarchiesByDunsNumber(Set<String> dunsNumbers){
            return accountHierarchiesToReturn;
        }
        
        public List<Account_Hierarchy__c> insertAccountHierarchies(List<Account_Hierarchy__c> accountHierarchies){
            return accountHierarchiesToReturn; 
        }
        
        public List<Account_Hierarchy__c> getAccountHierarchiesByCountryDomain(Set<String> countryDomain){
            return accountHierarchiesToReturn; 
        }

        public List<Account_Hierarchy__c> getAccountHierarchiesById(Set<Id> accountHierarchyIds){
            return accountHierarchiesToReturn;
        }
    }
}