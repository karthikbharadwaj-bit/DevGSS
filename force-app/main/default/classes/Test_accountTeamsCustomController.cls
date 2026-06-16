@isTest
public class Test_accountTeamsCustomController {
    public Test_accountTeamsCustomController() {

    }

    @isTest
    public static void testAddCurrentUsertoAccountTeamMember() {
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
        for (Account acc: accLst) {
            accountTeamsCustomController.addCurrentUsertoAccountTeamMember(acc.id, testUser.Id);
        }
        accountTeamsCustomController.addCurrentUsertoAccountTeamMember(accLst[0].id, testUser.Id);

        List<Account> accRes = [SELECT Id, Current_Owner__c, OwnerId, (SELECT UserId FROM AccountTeamMembers) FROM Account WHERE Current_Owner__c = :testUser.Id];
        for (Account acc: accRes) {
            for (AccountTeamMember atm : acc.AccountTeamMembers) {
                System.assertEquals(acc.Current_Owner__c, atm.UserId, 'Current owner is not added Account Team Member');
            }
        }
    }

    @isTest
    public static void testAccountOwnerUpdateWithRenewalManagersATM() {
        Profile p = [select id from profile where name='System Administrator'];
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));

        User testUser = new User(alias = 'test1', email='testuser1@test.com',
        emailencodingkey='UTF-8', lastname='TestUser1', languagelocalekey='en_US',
        localesidkey='en_US', profileid = p.Id, country='United States',
        timezonesidkey='America/Los_Angeles', username= 'testuser'+randomInt+'@test.com', isActive=true);
        insert testUser;

        Account testAccount1 = new Account(
            Name = 'TestAccount1',
            OwnerId = System.UserInfo.getUserId(),
            RC_Brand__c ='Avaya Cloud Office'
        );
        insert testAccount1;
        // Account acc = [SELECT Id FROM Account LIMIT 1];

        AccountTeamMember RenewalManagerATM = new AccountTeamMember();
            RenewalManagerATM.AccountId = testAccount1.Id;
            RenewalManagerATM.UserId = System.UserInfo.getUserId();
            RenewalManagerATM.AccountAccessLevel = 'Edit'; 
            RenewalManagerATM.CaseAccessLevel = 'Edit';
            RenewalManagerATM.ContactAccessLevel = 'Edit';
            RenewalManagerATM.OpportunityAccessLevel = 'Edit';
            RenewalManagerATM.TeamMemberRole = 'Renewals Manager';
            insert RenewalManagerATM;

            List<AccountTeamMember> listAcc=[SELECT Id FROM AccountTeamMember WHERE AccountId =:testAccount1.Id AND TeamMemberRole='Renewals Manager']; 

        testAccount1.OwnerId = testUser.Id;
        Test.startTest();
        update testAccount1;
        Test.stopTest();
        Boolean showWarning = accountTeamsCustomController.determineOwnerChange(testAccount1.Id);
        System.assert(!showWarning, 'ATM Warning not shown ' + showWarning);
            
    }
}