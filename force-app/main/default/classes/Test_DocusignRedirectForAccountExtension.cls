@isTest
public class Test_DocusignRedirectForAccountExtension {
    @isTest
    static void testRedirectUrlCompiledProperly() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Contact contact1 = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'JohnDoe@test.com',
                    Contact.FirstName => 'John',
                    Contact.LastName => 'Doe'
                }
            )
            .build()
            .getRecord();

        Contact contact2 = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'TonyTester@test.com',
                    Contact.FirstName => 'Tony',
                    Contact.LastName => 'Tester'
                }
            )
            .build()
            .getRecord();

        insert new List<Contact> {contact1, contact2};

        AccountContactRole role1 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => contact1.Id,
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => true
                }
            )
            .build()
            .getRecord();

        AccountContactRole role2 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => contact2.Id,
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => false
                }
            )
            .build()
            .getRecord();

        insert new List<AccountContactRole> {role1, role2};

        PageReference pageRef = Page.DocusignRedirectForAccount;    
        Test.setCurrentPageReference(pageRef);  
        ApexPages.currentPage().getParameters().put('id', acc.Id);
        ApexPages.StandardController controller = new ApexPages.standardController(acc);
        DocusignRedirectForAccountExtension ext = new DocusignRedirectForAccountExtension(controller);

        PageReference redirect = ext.redirect();

        String expectedUrl = '/apex/dsfs__DocuSign_CreateEnvelope' 
            + '?CRL=Email%7Ejohndoe%40test.com%3BFirstName%7EJohn%3BLastName%7EDoe' 
            + '%2CEmail%7Etonytester%40test.com%3BFirstName%7ETony%3BLastName%7ETester&DSEID=0&SourceID=' + acc.Id;
            
        System.assert(redirect.getURL().contains(expectedUrl), 'Wrong URL compiled');
    }
}