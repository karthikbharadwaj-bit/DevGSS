@isTest
public with sharing class Test_StartRefundManagement {
	private static final String SANDBOX_NAME = 'box50';
    private static final String USER_NAME = 'asuser@aquivalabs.com';

	private static User createUser(String profileName){
		User user = new User(
			Username = USER_NAME + '.' + SANDBOX_NAME,
			LastName = 'testUser',
			Email = 'testUser@gmail.com',
			Alias = 'testUser',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = [SELECT Id, Name FROM Profile WHERE Name =: profileName].Id,
			LanguageLocaleKey = 'en_US'
		);
		insert user;
		return user;
	}

	@isTest
	public static void test_WithValidationErrorsNoCustomPermission() {
		User testUser = createUser('System Administrator');
		Account testAcc = new Account(Name = 'testAcc');
		insert testAcc;

		Approval__c testApproval = new Approval__c(
            Status__c = 'New',
            Account__c = testAcc.Id
        );
        insert testApproval;

		System.runAs(testUser) {
			Test.startTest();
				String result = StartRefundManagement.processData(testApproval.Id);
				List <RefundManagementHelper.ErrorWrapper> errorList = (List <RefundManagementHelper.ErrorWrapper>)JSON.deserialize(result, List <RefundManagementHelper.ErrorWrapper>.class);
			Test.stopTest();
				//Check if user has no appropriate custom permission
				System.assertEquals(1, errorList.size());
		}
	}

    @isTest
	public static void test_WithValidationErrors2() {
        
        User testUser2 = createUser(ProfileHelper.PROFILE_NAME_SUPPORT_BACK_OFFICE);//Added as part of profile consolidation of Support Agent profiles - T1
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Support_Director'];
        insert new PermissionSetAssignment(AssigneeId = testUser2.id, PermissionSetId = ps.Id);
        
        System.runAs(testUser2) {
        
        Account testAcc = new Account(Name = 'testAcc');
        insert testAcc;
        
        Approval__c testApproval = new Approval__c(
            Status__c = 'New',
            Account__c = testAcc.Id
        );
        insert testApproval;
        
        //Added as part of profile consolidation of Support Agent profiles - T1
        
            
            if(FeatureManagement.checkPermission('Support_Director_permission')){
                Test.startTest();
                //process one more time for user with custom permission assigned
                String result = StartRefundManagement.processData(testApproval.Id);
                List <RefundManagementHelper.ErrorWrapper> errorList = (List <RefundManagementHelper.ErrorWrapper>)JSON.deserialize(result, List <RefundManagementHelper.ErrorWrapper>.class);
                Test.stopTest();
                
                //Check if user has custom permissions but it's profile name is not "System Administrator" and user doesn't belongs to Bid Desc queue
                System.assertEquals(1, errorList.size());
            }
        }
        
        
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
	public static void test_getapproval() {  
    User testUser = createUser('System Administrator');
		Account testAcc = new Account(Name = 'testAcc');
		insert testAcc;

		Approval__c testApproval = new Approval__c(
            Status__c = 'New',
            Account__c = testAcc.Id
        );
        insert testApproval;
        StartRefundManagement.getApproval(testApproval.id);
        StartRefundManagement.getFeatureToggleValue();
    
    }
    
    
}