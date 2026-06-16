@isTest
public class Test_GSPGuestLoginController {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
   @isTest
    static void testEmail()
   {
       Account account = new Account(Name='test gsp partner acc', RC_Brand__c = 'GSP', Permitted_Brands__c = 'GSP');
       insert account;
       Contact contact = new Contact(AccountId = account.id, Lastname = 'test gsp partner contact', Email = 'testcontact@gsp.com');
       insert contact;
       GSP_Partner_Email_Domain__c gspemaildomain = new GSP_Partner_Email_Domain__c(Partner_Account__c = account.id, 
                                                                                    Email_Domain__c = 'gsp.com');
       insert gspemaildomain;
       GSPGuestLoginController.checkContactEmail('testcontact@gsp.com');
   }
   @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void createContact()
    {
        Account account = new Account(Name='test gsp partner acc', RC_Brand__c = 'GSP', Permitted_Brands__c = 'GSP');
        insert account;
        Contact contact = new Contact(AccountId = account.id, Lastname = 'test gsp partner contact', Email = 'testcontact@gsp.com');
        GSPGuestLoginController.createContactRecord(contact, 'New Partner User Request');
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void createContact1()
    {
        Account account = new Account(Name='test gsp partner acc', RC_Brand__c = 'GSP', Permitted_Brands__c = 'GSP');
        insert account;
        Contact contact = new Contact(AccountId = account.id, Lastname = 'test gsp partner contact', Email = 'testcontact@gsp.com');
        GSPGuestLoginController.createContactRecord(contact, 'New Contact Request');
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void sendVerificationCode()
    {
        GSPGuestLoginController.sendVerificationCode('testcontact@gsp.com',123456,'<p>Verification code</p>');
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void requestForUserAccessPortal()
    {
       Account account = new Account(Name='test gsp partner acc', RC_Brand__c = 'GSP', Permitted_Brands__c = 'GSP');
       insert account;
       Contact contact = new Contact(AccountId = account.id, Lastname = 'test gsp partner contact', Email = 'testcontact@gsp.com');
       insert contact;
       GSP_Partner_Email_Domain__c gspemaildomain = new GSP_Partner_Email_Domain__c(Partner_Account__c = account.id, 
                                                                                    Email_Domain__c = 'gsp.com');
       insert gspemaildomain;
       GSPGuestLoginController.requestForUserAccessPortal('testcontact@gsp.com');
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testgetLastLoginDetails(){
        GSPGuestLoginController.getLastLoginDetails();
    }
}