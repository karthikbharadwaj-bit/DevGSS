@isTest
public class Test_BatchJob_MMMxOrMEMx {

    @testSetup
    static void setupTestData() {

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User expansionUser = new User(
            Alias = 'expusr',
            Email = 'expansion@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Expansion',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'expansionuser' + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id
        );
        insert expansionUser;

        Account acc = new Account(
            Name = 'Test Paid Account',
            RC_Account_Status__c = 'Paid',
            RC_Upgrade_Date__c = System.today().addDays(-5), // older than 3 days
            OwnerId = UserInfo.getUserId()
        );
        insert acc;

        AccountTeamMember teamMember = new AccountTeamMember(
            AccountId = acc.Id,
            UserId = expansionUser.Id,
            TeamMemberRole = 'MMMx Expansion'
        );
        insert teamMember;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        BatchJob_UpdateDSAAccounts batch = new BatchJob_UpdateDSAAccounts();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Account updatedAcc = [
            SELECT Current_Owner__c, Current_Owner_Previous__c, 
                   MRR_Transfer_Effective_Date__c
            FROM Account
            WHERE Name = 'Test Paid Account'
            LIMIT 1
        ];

        System.assertNotEquals(null, updatedAcc.Current_Owner__c, 'New owner should be set');
        System.assertEquals(UserInfo.getUserId(), updatedAcc.Current_Owner_Previous__c, 'Previous owner should match');
        System.assertEquals(System.today(), updatedAcc.MRR_Transfer_Effective_Date__c, 'MRR Transfer Effective Date should be today');

        Integer teamCount = [SELECT COUNT() FROM AccountTeamMember WHERE AccountId = :updatedAcc.Id];
        System.assertEquals(0, teamCount, 'Expansion team member should be deleted');
    }


	@isTest
	static void testSchedulerExecution() {
    	Test.startTest();

    	ScheduleJob_UpdateDSAAccounts sched = new ScheduleJob_UpdateDSAAccounts();
    	sched.execute(null); 

    	Test.stopTest();

    	Account updatedAcc = [
        	SELECT Current_Owner__c, Current_Owner_Previous__c
        	FROM Account
        	WHERE Name = 'Test Paid Account'
       		LIMIT 1
    	];

    	System.assertNotEquals(null, updatedAcc.Current_Owner__c, 'Owner should be reassigned after scheduler run');
	}
}