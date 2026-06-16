@isTest
public class TestContactData {

    private static List<Contact> getAllContacts(){
        return [SELECT Id, Name
                FROM Contact];
    }
	
    @isTest
    private static void testDeleteContactsByAccountIdsShouldDeleteContactsSuccessfully(){
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord(); 
        
        ContactData.IContactData contactData = new ContactData();
        Set<Id> accountIds = new Set<Id>{testAccount.Id};
        test.startTest();
            contactData.deleteContactsByAccountIds(accountIds);
        test.stopTest();

        System.assertEquals(0, getAllContacts().size(), 'Contacts should have been deleted successfully');
    }

    @isTest
    private static void testCreateContactsShouldCreateContactsSuccessfully(){
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                }
            )
            .build()
            .getRecord();
        List<Contact> contactsToInsert = new List<Contact>{testContact};
        
        ContactData.IContactData contactData = new ContactData();
        Set<Id> accountIds = new Set<Id>{testAccount.Id};
        test.startTest();
            contactData.createContacts(contactsToInsert);
        test.stopTest();

        System.assertEquals(1, getAllContacts().size(), 'Contact should have been inserted successfully');
    }

    @isTest
    private static void testGetContactsByAccountIdsShouldRetieveContactsSuccessfully(){

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
                
        ContactData.IContactData contactData = new ContactData();
        Set<Id> accountIds = new Set<Id>{testAccount.Id};
        test.startTest();
            List<Contact> contactsRetrieved = contactData.getContactsByAccountIds(accountIds);
        test.stopTest();

        System.assertEquals(1, getAllContacts().size(), 
            'Contact should be retrieved successfully');
    }

    @isTest
    private static void testMocksDeleteContactsByAccountIdsShouldReturnExpectedResults() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact contactToReturn = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        ContactData.ContactDataMock contactDataMock = new ContactData.ContactDataMock();
        contactDataMock.setContactsToReturn(new List<Contact>{contactToReturn});
        
        test.startTest();
            contactDataMock.deleteContactsByAccountIds(null);
        test.stopTest();

        System.assertEquals(0, contactDataMock.getContactsToReturn().size(), 'All contacts should be deleted successfully');
    }

    @isTest
    private static void testMocksCreateContactsShouldReturnExpectedResults() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        List<Contact> contactsToInsert = new List<Contact>{testContact};

        ContactData.ContactDataMock contactDataMock = new ContactData.ContactDataMock();
        
        test.startTest();
            contactDataMock.createContacts(contactsToInsert);
        test.stopTest();

        System.assertEquals(1, contactDataMock.getContactsToReturn().size(), 'All contacts should be inserted successfully');
    }

    @isTest
    private static void testMocksGetContactsByAccountIdsShouldReturnExpectedResults() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        
        ContactData.ContactDataMock contactDataMock = new ContactData.ContactDataMock();
        contactDataMock.setContactsToReturn(new List<Contact>{testContact});
        
        test.startTest();
            List<Contact> contactsRetrieved = contactDataMock.getContactsByAccountIds(null);
        test.stopTest();

        System.assertEquals(1, contactsRetrieved.size(), 
            'Contact should be retrieved successfully');
    }
    
}