@isTest
public with sharing class Test_RefundManagementHelper {
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
				List<RefundManagementHelper.ErrorWrapper> errorList = RefundManagementHelper.checkRefundManagementPageAccessPermissions(testApproval.Id);
			Test.stopTest();
				//Check if user has no appropriate custom permission
				System.assertEquals(1, errorList.size());
		}
	}

     @isTest
   public static void test_WithValidationErrors2() {
        User testUser2 = createUser(ProfileHelper.PROFILE_NAME_SUPPORT_BACK_OFFICE);//Added as part of profile consolidation of Support Agent profiles - T1
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Support_Director'];
        Test.startTest();
          //insert new PermissionSetAssignment(AssigneeId = testUser2.id, PermissionSetId = ps.Id);
        Account testAcc = new Account(Name = 'testAcc');
        insert testAcc;

        Approval__c testApproval = new Approval__c(
            Status__c = 'New',
            Account__c = testAcc.Id
        );
        insert testApproval;


        //Added as part of profile consolidation of Support Agent profiles - T1
        System.runAs(testUser2) {
            if(FeatureManagement.checkPermission('Support_Director_permission')){

                //process one more time for user with custom permission assigned
                List<RefundManagementHelper.ErrorWrapper> errorList = RefundManagementHelper.checkRefundManagementPageAccessPermissions(testApproval.Id);
                Test.stopTest();

                //Check if user has custom permissions but it's profile name is not "System Administrator" and user doesn't belongs to Bid Desc queue
                System.assertEquals(1, errorList.size());
            }
        }
    }


	@isTest
	public static void testIsBidDeskQueueAssignedMethod() {

		Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => ValueProviderBuilder.provideUniqueString('testAccount'),
					Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT
				}
			)
			.create()
			.getRecord();

        User testSysAdminUser = createUser('System Administrator');
        testSysAdminUser.ManagerId = UserInfo.getUserId();

		Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Approval__c.Account__c => testAcc.Id,
                    Approval__c.Level1Approver__c => testSysAdminUser.ManagerId
				}
			)
			.create()
			.getRecord();

		System.runAs(testSysAdminUser) {

			Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
			req1.setComments('Submitting request for approval.');
			req1.setObjectId(testApproval.Id);

			Group bidDeskQueue = (Group) new GroupSelector()
				.selectGroupBasedOnDeveloperNames(
					new List<Object>{
						new Set<String>{
							'BidDesk'
						}
					}
				)
				.executeQuery()
				.get(0);

			req1.setNextApproverIds(new Id[] { bidDeskQueue.Id });

			Approval.ProcessResult res = Approval.process(req1);

			Test.startTest();
				Boolean result = RefundManagementHelper.isBidDeskQueueAssigned(testApproval.Id);
				System.assert(!result);
			Test.stopTest();
		}
	}

	@isTest
	public static void testIsBidDeskQueueIdMethod() {

		System.assert(
			!RefundManagementHelper.isBidDeskQueueId(null),
			'isBidDeskQueueId method should return false if passed param is null'
		);

		Id testOppId = (Id) ValueProviderBuilder.provideDummyId(Opportunity.SObjectType).getValue();
		System.assert(
			!RefundManagementHelper.isBidDeskQueueId(testOppId),
			'isBidDeskQueueId method should return false if passed param is not Group id'
		);

		Group bidDeskQueue = (Group) new GroupSelector()
			.selectGroupBasedOnDeveloperNames(
				new List<Object>{
					new Set<String>{
						'BidDesk'
					}
				}
			)
			.executeQuery()
			.get(0);

		System.assert(
			RefundManagementHelper.isBidDeskQueueId(bidDeskQueue.Id),
			'isBidDeskQueueId method should return true if passed param is Id of "Bid Desk" queue'
		);
	}
}