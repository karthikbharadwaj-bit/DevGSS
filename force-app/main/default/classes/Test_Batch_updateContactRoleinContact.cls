@isTest
public class Test_Batch_updateContactRoleinContact {
	public static Account testAccount;
    public static Contact testContact;
    public static AccountContactRole testACR;
    public static AccountContactRole testACR1;
    public static Segment_Master__c testSM;
    
    public static void createTestData(){
 	
        testSM = new Segment_Master__c();
        testSM.Name = 'Small Business';
       	testSM.Min__c = 20;
        testSM.Max__c = 100;
        testSM.Country__c = 'United States';
        testSM.Start_Date__c = Date.today();
        insert testSM;
          
        testAccount = new Account();
		testAccount.Name = 'Test123';
		testAccount.RC_Account_Status__c = 'Paid';
		testAccount.SignupPlatform__c = 'WEB';
		testAccount.RC_Service_name__c = 'office123';
        testAccount.Segment_Name__c = testSM.Id;
		testAccount.RC_Activation_Date__c = null;
        testAccount.RC_Upgrade_Date__c = Date.today().addMonths(-10);
		testAccount.Partner_ID__c = '9852';
        testAccount.wave__c = 'Wave 1';
        
		insert testAccount;

		testContact = new Contact();
		testContact.AccountId =  testAccount.id;
		testContact.Email = 'fake@email.com';
		testContact.LastName = 'TestLast';
		testContact.Phone='9910106804';
		insert testContact;
 		
        testACR = new AccountContactRole();
        testACR.AccountId = testAccount.Id;
        testACR.ContactId = testContact.Id;
        testACR.Role = 'Signatory';
        testACR.IsPrimary = true;
        insert testACR;       
        
        testACR1 = new AccountContactRole();
        testACR1.AccountId = testAccount.Id;
        testACR1.ContactId = testContact.Id;
        testACR1.Role = 'Influencer';
        testACR1.IsPrimary = false;
        insert testACR1;  
        
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest 
    static void testUpdateContactRole() {
	    Triggers.switchOff();
        createTestData();
        Triggers.switchon();
        
        Batch_updateContactRoleinContact bcrt = new Batch_updateContactRoleinContact();
		database.executeBatch(bcrt);
    }  
    
}