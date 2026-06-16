public without sharing class AccountData implements IAccountData{
    
    public Interface IAccountData{
        List<Account> updateAccounts(List<Account> accountsToUpdate, Boolean allOrNone);
        List<Account> retrieveAccounts(Set<Id> accountIds);
    }

    public List<Account> updateAccounts(List<Account> accountsToUpdate, Boolean allOrNone){
        Database.SaveResult[] saveResult = Database.update(accountsToUpdate, allOrNone);
        return accountsToUpdate;
    }

    public List<Account> retrieveAccounts(Set<Id> accountIds){
       /* return [SELECT Id, LS_Enrichment_Date__c, LS_Status__c, LS_Linkedin_Profile__c,
                    LS_Ownership__c, LS_Account_Name__c , LS_Phone__c, LS_Website__c,  
                    LS_Employees__c, LS_No_of_Employees_Range__c,
                    LS_Installed_Base_Technologies__c, LS_Country__c, LS_Primary_NAICS__c
                FROM Account 
                WHERE Id IN : accountIds];*/
        return null;
    }

    public class AccountDataMock implements IAccountData {
        public List<Account> accountsToReturn = new List<Account>();

        public List<Account> updateAccounts(List<Account> accountsToUpdate, Boolean allOrNone){
            return accountsToReturn;
        }

        public List<Account> retrieveAccounts(Set<Id> accountIds){
            return accountsToReturn;
        }
    }

}