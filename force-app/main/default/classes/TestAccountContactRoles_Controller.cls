@isTest
public class TestAccountContactRoles_Controller {

    @TestSetup
    static void prepare() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => testAccount.Id,
                Contact.LastName => 'John',
                Contact.FirstName => 'Doe',
                Contact.Email => 'contact1@ringcentral.tld'
            })
            .create()
            .getRecord();
    }

    static Account selectTestAccount() {
        List<Account> listAccounts = new AccountSelector()
            .selectAccounts()
            .selectFields(new List<SObjectField>{
                Account.Id, Account.Name
            })
            .subselect(
                new ContactSelector()
                    .selectContacts()
                    .selectFields(new List<SObjectField>{
                        Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email
                    })
            )
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object>{
                'My Account'
            })
            .setLimit(1)
            .executeQuery();

        return listAccounts.size() == 0 ? null : listAccounts.get(0);
    }

    @isTest
    private static void testAccountContactRoles(){

        Account testAccount = selectTestAccount();
        Contact testContact = testAccount.Contacts[0];

        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testAccount.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => 'RC Admin User'
                }
            )
            .create()
            .getRecord();

        String response = '';

        Test.startTest();
            response = AccountContactRoles_Controller.getAllContactRole(testAccount.Id);
        	AccountContactRoles_Controller.editContactRole(testAccountContactRole.Id);
        	AccountContactRoles_Controller.deleteContactRole(testAccountContactRole.Id);
            AccountContactRoles_Controller.getCRDataController(testAccount.Id, 1, 10);
        Test.stopTest();

        Map<String,Object> responseObjectMap = (Map<String,Object>)JSON.deserializeUntyped(response);
        Boolean isCustomerAccount = (Boolean)responseObjectMap.get('isCustomerAccount');
        System.assertEquals(true, isCustomerAccount, 'Account wasn\'t identified as Customer');

        testAccount.RecordTypeId = AccountHelper.RT_ID_PARTNER_ACCOUNT;
        update testAccount;

        response = AccountContactRoles_Controller.getAllContactRole(testAccount.Id);
        responseObjectMap = (Map<String,Object>)JSON.deserializeUntyped(response);
        isCustomerAccount = (Boolean)responseObjectMap.get('isCustomerAccount');
        System.assertEquals(false, isCustomerAccount, 'Account was identified as Customer');
    }

    @isTest
    private static void testValidateAccountContactRoles(){

        Account testAccount = selectTestAccount();
        Contact testContact = testAccount.Contacts[0];

        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testAccount.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                    Opportunity.AccountId => testAccount.Id
                })
            .create()
            .getRecord();

        Approval__c testApproval = new Approval__c (
            Status__c = 'PendingL1Approval',
            RecordTypeId = ApprovalHelper.RT_ID_INVOICING_REQUEST,
            Account__c = testAccount.Id,
            AccountPayableContact__c = testContact.Id,
            Opportunity__c = testOpp.Id
        );

        Test.startTest();

        insert testApproval;

        Boolean canChange = AccountContactRoles_Controller.validateContactRole(testAccountContactRole.Id);

        Test.stopTest();

        System.assertEquals(true, canChange, 'IsHasApprovals ACR validation is failed.');

    }
}