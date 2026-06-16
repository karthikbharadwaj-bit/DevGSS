public without sharing class AccountContactRoleData implements IAccountContactRoleData{

    public Interface IAccountContactRoleData{
        List<AccountContactRole> getAccountContactRolesForCompanyMatchingByAccountIds(Set<Id> accountIds);
    }

    public List<AccountContactRole> getAccountContactRolesForCompanyMatchingByAccountIds(Set<Id> accountIds){
        return [SELECT Id, Account.Name, Account.Id, Contact.FirstName, Contact.Email, Contact.LastName, Role, 
                IsPrimary, IsDeleted 
            FROM AccountContactRole
            WHERE IsDeleted = false AND Account.Id IN : accountIds];
    }

    public class AccountContactRoleDataMock implements IAccountContactRoleData{
        public List<AccountContactRole> accountContactRolesToReturn;

        public List<AccountContactRole> getAccountContactRolesForCompanyMatchingByAccountIds(Set<Id> accountIds){
            return accountContactRolesToReturn;
        }
    }

}