public abstract class CompanyProcessorSvc {

    private static final String COUNTRY_DOMAIN_SEPARATOR = '|';
    @testVisible protected AccountHierarchyData.IAccountHierarchyData accountHierarchyDataInstance = new AccountHierarchyData();
    @testVisible protected CompanyPersonsData.ICompanyPersonsData companyPersonsDataInstance = new CompanyPersonsData();
    @testVisible protected AccountContactRoleData.IAccountContactRoleData accountContactRoleDataInstance = new AccountContactRoleData();
    @testVisible protected ContactData.IContactData contactDataInstance = new ContactData();
    @testVisible protected DomainManagerSvc.IDomainManagerSvc domainManagerSvcInstance = new DomainManagerSvc();
    private List<Account_Hierarchy__c> accountHierarchyList;

    public abstract void processAccountHierarchy(List<sObject> objectsToProcess, Map<Id, sObject> oldObjects);
    public Set<Id> objectIdsToForceProcessDuringUpdate {get; set;}

    @testVisible protected String getCountryDomainKey(String country, String Domain){
        return country + COUNTRY_DOMAIN_SEPARATOR + domain;
    }

    @testVisible protected String getNormalizedCountry(String countryToNormalize){
        Map<String, CompanyMatchingCountryMapping__c> companyMatchingCountry = CompanyMatchingCountryMapping__c.getAll();
        if(companyMatchingCountry != null && companyMatchingCountry.containsKey(countryToNormalize.toUpperCase())){
            return companyMatchingCountry.get(countryToNormalize.toUpperCase()).ToCountry__c;
        } else {
            // RC requested this comment saying this should be removed by July 2020
            return 'United States';
        }
    }

    public class CompanyProcessorSvcException extends Exception{
    }

    public class CompanyProcessorSvcMock extends CompanyProcessorSvc {
        public override void processAccountHierarchy(List<sObject> objectsToProcess, Map<Id, sObject> oldObjects){
        }
    }

}