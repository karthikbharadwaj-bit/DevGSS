@istest
public class Test_Contact_New_BookingController {
	//test method to create contact
    @isTest
    static void  CreateContact()
     { 
         User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
         	List<Account> Acct = new List<Account>();
         
         	Account accObj = new Account();
            accObj.Name = 'Test Account Parent ';
            accObj.Partner_ID__c = '12346';
            Acct.add(accObj);
          	insert Acct;
         
         	Contact contactObj = new Contact();
            contactObj.AccountId =  accObj.Id;
            contactObj.Email = 'test@test.com';
            contactObj.Phone = '9910106804';
            contactObj.LastName = 'TestLast';
            contactObj.FirstName='Test';
            insert contactObj;
      
      		Contact c = Contact_New_BookingController.getContact(contactObj.id);
            system.assertEquals(c.id,contactObj.id);

     }

}