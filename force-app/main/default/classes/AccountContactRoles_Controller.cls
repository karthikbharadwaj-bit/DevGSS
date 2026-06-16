/*
* Created By    : Madhumita
* Created Date  : 26-08-2020
* Description   : Controller class for Account_ContactRolesRelatedList lightning component
* Test Class    :

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class AccountContactRoles_Controller {
    @AuraEnabled
    public static String getAllContactRole(String accId) {
        ContactRoleWrapper crWrapper = new ContactRoleWrapper();
        List<AccountContactRole> acctContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesForAccountOrderedByCreatedDate(new List<Object>{new Set<Id>{ accId }})
            .executeQuery();

        if (Schema.sObjectType.AccountContactRole.isDeletable()) {
            crWrapper.checkdeleteAccess = true;
        } else {
            crWrapper.checkdeleteAccess = false;
        }
         if (Schema.sObjectType.AccountContactRole.isUpdateable()) {
            crWrapper.checkeditAccess = true;
         } else {
             crWrapper.checkeditAccess = false;
         }
         if (Schema.sObjectType.AccountContactRole.isCreateable()) {
            crWrapper.checkcreateAccess = true;
         } else {
             crWrapper.checkcreateAccess = false;
         }
        crWrapper.accountContactsList = acctContactRoles;

        if (String.isNotEmpty(accId)) {
            crWrapper.account = getAccount(accId);
        }

        if (crWrapper.account != null) {
            crWrapper.isCustomerAccount = isCustomerAccount(crWrapper.account);
        }

        return JSON.serializePretty(crWrapper);


    }

    @AuraEnabled
    public static ContactRoleWrapper getCRDataController(Id accId, Decimal pageNumber, Decimal pageSize) {

        ContactRoleWrapper crWrapper = new ContactRoleWrapper();

        Integer pSize = (Integer)pageSize;
        Integer pNumber = (Integer)pageNumber;
        Integer offset = (pNumber - 1) * pSize;
        Integer recordEnd = pSize * pNumber;
        Integer totalRecords = [SELECT COUNT() FROM AccountContactRole WHERE AccountId=:accId and Role != '[None]'];

        List<AccountContactRole> acctContactRoles = [SELECT Id,createdDate,Role,IsPrimary,Contact.Name,Contact.FirstName,Contact.LastName,
                                                     Contact.Phone,Contact.Email,Contact.Title,ContactId,AccountId,Account.Name
                                                     FROM AccountContactRole
                                                     WHERE AccountId=:accId and Role != '[None]' ORDER BY Role, CreatedDate ASC NULLS LAST LIMIT :pSize OFFSET :offset];

        crWrapper.accountContactsList = acctContactRoles;
        crWrapper.pageSize = pSize;
        crWrapper.pageNumber = pNumber;
        crWrapper.recordStart = offset + 1;
        crWrapper.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        crWrapper.totalRecords = totalRecords;
        if (Schema.sObjectType.AccountContactRole.isDeletable()) {
            crWrapper.checkdeleteAccess = true;
        }else{
            crWrapper.checkdeleteAccess = false;
        }
         if (Schema.sObjectType.AccountContactRole.isUpdateable()) {
            crWrapper.checkeditAccess = true;
         }else{
             crWrapper.checkeditAccess = false;
         }
         if (Schema.sObjectType.AccountContactRole.isCreateable()) {
            crWrapper.checkcreateAccess = true;
         }else{
             crWrapper.checkcreateAccess = false;
         }

        return crWrapper;

    }

    @AuraEnabled
    public static String editContactRole(Id acrId)
    {
        AcrValueWrapper crWrapper = new AcrValueWrapper();
        AccountContactRole accContactRole = new AccountContactRole();
        accContactRole = [SELECT Id,Role,IsPrimary,ContactId FROM AccountContactRole WHERE Id=:acrId];

        crWrapper.cId = accContactRole.ContactId;
        crWrapper.role = accContactRole.Role;
        crWrapper.primary = accContactRole.IsPrimary;
        return JSON.serialize(crWrapper);


    }

    @AuraEnabled
    public static String deleteContactRole(Id acrId) {
        String resultMessage;
        try{
            if(acrId != null){
                AccountContactRole accContactRole = new AccountContactRole();
                accContactRole = [SELECT Id FROM AccountContactRole WHERE Id=:acrId];

                delete accContactRole;
                resultMessage = 'success';
            }

            return  resultMessage;
        }
        catch(exception e){
            resultMessage = 'Error';
            return resultMessage;
        }
    }

    @AuraEnabled
    public static Boolean validateContactRole(Id acrId) {
        Boolean canChange = false;
        Set<Id> acrIdSet = new Set<Id>{ acrId };
        List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesByIds(new List<Object>{ acrIdSet })
            .executeQuery();
        if (accountContactRoles != null &&
            !accountContactRoles.isEmpty() &&
            accountContactRoles[0].Role == AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE) {
                canChange = ApprovalHelper.validateChangingAccountContactRoles(
                    accountContactRoles[0].AccountId,
                    accountContactRoles[0].ContactId
                );
        }
        return  canChange;
    }

    private static Account getAccount(Id accountId) {
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccountById(accountId)
            .executeQuery();
        Account acc = accounts[0];
        return acc;
    }

    private static Boolean isCustomerAccount(Account account) {
        return (account.RecordTypeId == AccountHelper.RT_ID_CUSTOMER_ACCOUNT);
    }

    public class AcrValueWrapper
    {
        @AuraEnabled
        public Id cId{get;set;}
        @AuraEnabled
        public String role{get;set;}
        @AuraEnabled
        public Boolean primary{get;set;}
    }
    public class ContactRoleWrapper{
        @AuraEnabled
        public List<AccountContactRole> accountContactsList{get;set;}
        @AuraEnabled
        public Integer pageSize {get;set;}
        @AuraEnabled
        public Integer pageNumber {get;set;}
        @AuraEnabled
        public Integer totalRecords {get;set;}
        @AuraEnabled
        public Integer recordStart {get;set;}
        @AuraEnabled
        public Integer recordEnd {get;set;}
        @AuraEnabled
        public Boolean checkeditAccess {get;set;}
        @AuraEnabled
        public Boolean checkdeleteAccess {get;set;}
        @AuraEnabled
        public Boolean checkcreateAccess {get;set;}
        @AuraEnabled
        public Account account {get;set;}
        @AuraEnabled
        public Boolean isCustomerAccount {get;set;}
    }
}