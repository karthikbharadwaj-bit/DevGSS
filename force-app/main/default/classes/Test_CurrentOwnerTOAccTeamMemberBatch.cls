@IsTest
public class Test_CurrentOwnerTOAccTeamMemberBatch {
    public Test_CurrentOwnerTOAccTeamMemberBatch() {

    }

    public static User createTestData() {
        Profile p = [select id from profile where name='System Administrator'];
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));

        User testUser = new User(alias = 'test1', email='testuser1@test.com',
        emailencodingkey='UTF-8', lastname='TestUser1', languagelocalekey='en_US',
        localesidkey='en_US', profileid = p.Id, country='United States',
        timezonesidkey='America/Los_Angeles', username= 'testuser'+randomInt+'@test.com', isActive=true);
        insert testUser;
        
        List<Account> accLst = new List<Account>();
        Account testAccount1 = new Account(
            Name = 'TestAccount1',
            OwnerId = System.UserInfo.getUserId(),
            RC_Brand__c ='Avaya Cloud Office',
            Current_Owner__c = testUser.Id
        );
        accLst.add(testAccount1);
        Account testAccount2 = new Account(
            Name = 'TestAccount2',
            OwnerId = System.UserInfo.getUserId(),
            RC_Brand__c ='Avaya Cloud Office',
            Current_Owner__c = testUser.Id
        );
        accLst.add(testAccount2);

        insert accLst;
        Account acc = accLst[1];
        AccountTeamMember ATM1 = new AccountTeamMember();
			ATM1.AccountId = acc.Id;
			ATM1.UserId = acc.Current_Owner__c;
			ATM1.AccountAccessLevel = 'Edit';
			ATM1.TeamMemberRole = 'Custom Engineering SE';
        insert ATM1;
        AccountShare accountShare1 = new AccountShare();
            accountShare1.UserOrGroupId = acc.Current_Owner__c;
            accountShare1.AccountAccessLevel = 'Edit';
            accountShare1.OpportunityAccessLevel = 'None';
            accountShare1.AccountId = acc.Id;
        insert accountShare1;

        return testUser;
    }
    @IsTest
    public static void testAddCurrentOwnerAsAccountTeamMember1() {
        User testUser = Test_CurrentOwnerTOAccTeamMemberBatch.createTestData();
        CurrentOwnerTOAccountTeamMemberBatch ATM_Batch = new CurrentOwnerTOAccountTeamMemberBatch();
        Database.executeBatch(ATM_Batch);

        List<Account> accRes = [SELECT Id, Current_Owner__c, OwnerId, (SELECT UserId FROM AccountTeamMembers) FROM Account WHERE Current_Owner__c = :testUser.Id];
        for (AccountTeamMember atm : accRes[0].AccountTeamMembers) {
            System.assertEquals(accRes[0].Current_Owner__c, atm.UserId, 'Current owner is not added Account Team Member');
        }
    }
    @IsTest
    public static void testAddCurrentOwnerAsAccountTeamMember2() {
        User testUser = Test_CurrentOwnerTOAccTeamMemberBatch.createTestData();
        Profile p = [select id from profile where name='Read Only'];
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));

        User testReadOnlyUser = new User(alias = 'test1', email='testReadOnlyuser1@test.com',
        emailencodingkey='UTF-8', lastname='TestUser1', languagelocalekey='en_US',
        localesidkey='en_US', profileid = p.Id, country='United States',
        timezonesidkey='America/Los_Angeles', username= 'testReadOnlyuser'+randomInt+'@test.com', isActive=true);
        insert testReadOnlyUser;
        
        System.runAs(testReadOnlyUser) {
            CurrentOwnerTOAccountTeamMemberBatch ATM_Batch = new CurrentOwnerTOAccountTeamMemberBatch('CALENDAR_YEAR(LastModifiedDate) = 2022');
            Database.executeBatch(ATM_Batch);
        }
        List<Account> accRes = [SELECT Id, Current_Owner__c, OwnerId, (SELECT UserId FROM AccountTeamMembers) FROM Account WHERE Current_Owner__c = :testUser.Id];
        for (AccountTeamMember atm : accRes[0].AccountTeamMembers) {
            System.assertEquals(accRes[0].Current_Owner__c, atm.UserId, 'Current owner is not added Account Team Member');
        }
    }
}