@isTest
public class Test_ChkContactOnAccount {
    @testSetup
    static void setupData() {
        Account account1 = new Account(Name='Test Account 1');
        Account account2 = new Account(Name='Test Account 2');
        insert new List<Account>{account1, account2};

        Contact existingContact1 = new Contact(FirstName='Existing', LastName='Contact1', Email='existing1@test.com', AccountId=account1.Id);
        Contact existingContact2 = new Contact(FirstName='Existing', LastName='Contact2', Email='existing2@test.com', AccountId=account2.Id);
        insert new List<Contact>{existingContact1, existingContact2};
    }

    @isTest
    static void testUpdateEmailToDuplicate() {
        Account account = [SELECT Id FROM Account WHERE Name='Test Account 1' LIMIT 1];

        Contact existingContact = new Contact(FirstName='Existing', LastName='Contact3', Email='unique3@test.com', AccountId=account.Id);
        insert existingContact;

        existingContact.Email = 'existing1@test.com';

        Map<Id, Contact> oldContactMap = new Map<Id, Contact>{existingContact.Id => [SELECT Id, Email FROM Contact WHERE Id = :existingContact.Id]};

        Test.startTest();
        chkContactOnAccount.areContactMailAllowedInsertUpdate(new List<Contact>{existingContact}, oldContactMap);
        Test.stopTest();

        System.assertEquals(1, existingContact.getErrors().size());
        System.assertEquals('Contact with provided Email already exist on Account', existingContact.getErrors()[0].getMessage());
    }
}