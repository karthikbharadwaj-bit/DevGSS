@isTest
public class Test_Order_SubmitButtonController {

    private static User testUser = createUser('test'); // testUser with admin profile

	private static User createUser(String name){
	  User user = new User(
	      Username = name+'!user@gmail.com',
	      LastName = 'Test'+name,
	      Email = name+'_user@gmail.com',
	      Alias = 'test'+name,
	      TimeZoneSidKey = 'America/Los_Angeles',
	      LocaleSidKey = 'en_US',
	      EmailEncodingKey = 'UTF-8',
	      ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
	      LanguageLocaleKey = 'en_US'
	  );
	  insert user;
	  return user;
	}
    
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testAccountValidation() {
        
        System.runAs(testUser) {
            Account testAcc = new Account(
				Name = 'testAcc',
				inContact_Account_Id__c = '1234',
				RC_User_Id__c = 'test',
				RC_Account_Number__c = 'test',
				Timezone__c = 'Asia/Calcutta'
			);
			insert testAcc;
        
            Order testOrder = new Order(
				AccountId = testAcc.Id,
				EffectiveDate = System.today(),
				Status = 'New',
				Contact_Center_Number__c = 'test',
				RingCentral_Account_Number__c = 'testRCAccountNumber'
			);
			insert testOrder;
        
            Order_SubmitButtonController.checkSubmitOrderValidity(testOrder.Id);
        }
    }
    
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testOrderCasesValidation() {
        
        System.runAs(testUser) {
            Account testAcc = new Account(
				Name = 'testAcc',
				inContact_Account_Id__c = '1234',
				RC_User_Id__c = 'test',
				RC_Account_Number__c = 'test',
				Timezone__c = 'Asia/Calcutta'
			);
			insert testAcc;
            
            Id orderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Contact_Center').getRecordTypeId();
        
            Order testOrder = new Order(
				AccountId = testAcc.Id,
				EffectiveDate = System.today(),
				Status = 'New',
				Contact_Center_Number__c = 'test',
				RingCentral_Account_Number__c = 'testRCAccountNumber',
                RecordTypeId = orderRecordTypeId
			);
			insert testOrder;
            
            Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('inContact_Order').getRecordTypeId();
            
            Case testCase = new Case(
                 AccountId = testAcc.Id,
                 Order__c = testOrder.Id,
                 RecordTypeId = caseRecordTypeId
            );
        
            insert testCase;
            
            Order_SubmitButtonController.checkSubmitOrderValidity(testOrder.Id);
        }
    }
    
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testOrderInContactSegmentValidation() {
        
        System.runAs(testUser) {
            Account testAcc = new Account(
				Name = 'testAcc',
				inContact_Account_Id__c = '1234',
				RC_User_Id__c = 'test',
				RC_Account_Number__c = 'test',
				Timezone__c = 'Asia/Calcutta'
			);
			insert testAcc;
        
            Id recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Contact_Center').getRecordTypeId();
            
            Order testOrder = new Order(
				AccountId = testAcc.Id,
				EffectiveDate = System.today(),
				Status = 'New',
				Contact_Center_Number__c = 'test',
				RingCentral_Account_Number__c = 'testRCAccountNumber',
                RecordTypeId = recordTypeId
			);
			insert testOrder;
                      
        
            Order_SubmitButtonController.checkSubmitOrderValidity(testOrder.Id);
        }
    }

	@isTest
    public static void testResubmitOrder() {
        
        System.runAs(testUser) {
            Account testAcc = new Account(
				Name = 'testAcc',
				inContact_Account_Id__c = '1234',
				RC_User_Id__c = 'test',
				RC_Account_Number__c = 'test',
				Timezone__c = 'Asia/Calcutta'
			);
			insert testAcc;
        
            Order testOrder = new Order(
				AccountId = testAcc.Id,
				EffectiveDate = System.today(),
				Status = 'New',
				Contact_Center_Number__c = 'test',
				RingCentral_Account_Number__c = 'testRCAccountNumber',
				BillingStatus__c = 'Rejected',
				BillingStatusDetails__c = 'Rejected order'
			);
			insert testOrder;
        
            Boolean isRejected = Order_SubmitButtonController.resubmitOrder(testOrder.Id);

			System.assertEquals(true, isRejected);
        }
    }
}