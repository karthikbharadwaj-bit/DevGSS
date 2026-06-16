public without sharing class CompanyPersonsData implements ICompanyPersonsData{
	
    public Interface ICompanyPersonsData{
        void deleteCompanyPersonsByLeadIds(Set<Id> oldLeadIds);
        void deleteCompanyPersonsByContactIds(Set<Id> contactIds);
        List<Company_Persons__c> createCompanyPersons(List<Company_Persons__c> newCompanyPersons);
    }

    public void deleteCompanyPersonsByLeadIds(Set<Id> leadIds){
        DELETE [SELECT Id FROM Company_Persons__c WHERE Lead__c IN:leadIds]; 
    }

    public void deleteCompanyPersonsByContactIds(Set<Id> contactIds){
        DELETE [SELECT Id FROM Company_Persons__c WHERE Contact__c IN:contactIds]; 
    }

    public List<Company_Persons__c> createCompanyPersons(List<Company_Persons__c> newCompanyPersons){
        INSERT newCompanyPersons;
        return newCompanyPersons;
    }

    public class CompanyPersonsDataMock implements ICompanyPersonsData{
        public List<Company_Persons__c> companyPersonsToReturn = new List<Company_Persons__c>();

        public void deleteCompanyPersonsByLeadIds(Set<Id> leadIds){
            companyPersonsToReturn.clear();
        }

        public void deleteCompanyPersonsByContactIds(Set<Id> contactIds){
            companyPersonsToReturn.clear();
        }

        public List<Company_Persons__c> createCompanyPersons(List<Company_Persons__c> newCompanyPersons){
            companyPersonsToReturn.addAll(newCompanyPersons);
            return newCompanyPersons;
        }
    }
}