@isTest
public class Test_AccountTeamMemberSelector {
    @isTest
    private static void accountTeamMemberByAccountId(){
        List<Account> testAccounts = (List<Account>) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecords();
        System.assert(testAccounts[0].id <> null);
        // Get Profiles
        Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'Sales Rep - Lightning'];

        System.debug(profile);
        // Create Users
        User user1 = new User(
                FirstName = 'John1',
                LastName = 'Doe1',
                Email = 'example@testemail.tld',
                Username = 'example@testemail.tld'+Math.Random(),
                Alias = 'JohnDoe1',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
        );

        User user2 = new User(
                FirstName = 'John2',
                LastName = 'Doe2',
                Email = 'example@testemail.tld',
                Username = 'example@testemail.tld'+Math.Random(),
                Alias = 'JohnDoe2',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
        );

        insert new List<User>{
            user1, user2
        };

       	List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        AccountTeamMember atm1 = new AccountTeamMember();
        atm1.userId = user1.id;
        atm1.AccountId = testAccounts[0].id;
        atm1.TeamMemberRole = 'Strategic Partner RC Owner';
		atmList.add(atm1);            
        AccountTeamMember atm2 = new AccountTeamMember();
        atm2.userId = user2.id;
        atm2.AccountId = testAccounts[0].id;
        atm2.TeamMemberRole = 'Strategic Partner RC Owner';
        atmList.add(atm2);          
        insert atmList;
        System.assert(atmList[0].Id <> null);
         Test.startTest();

            List<AccountTeamMember> testATM = (List<AccountTeamMember>) new AccountTeamMemberSelector()
                .selectAccountTeamMemberByAccountId(new List<Object>{testAccounts})
                .executeQuery();
        
        Test.stopTest();

        System.assertEquals(2, testATM.size());
     }
          
    @isTest
    private static void accountTeamMemberByAccountIdAndRole(){
        List<Account> testAccounts = (List<Account>) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecords();
        System.assert(testAccounts[0].id <> null);
        // Get Profiles
        Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'Sales Rep - Lightning'];

        System.debug(profile);
        // Create Users
        User user1 = new User(
                FirstName = 'John1',
                LastName = 'Doe1',
                Email = 'example@testemail.tld',
                Username = 'example@testemail.tld'+Math.Random(),
                Alias = 'JohnDoe1',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
        );

        User user2 = new User(
                FirstName = 'John2',
                LastName = 'Doe2',
                Email = 'example@testemail.tld',
                Username = 'example@testemail.tld'+Math.Random(),
                Alias = 'JohnDoe2',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
        );

        insert new List<User>{
            user1, user2
        };

       	List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        AccountTeamMember atm1 = new AccountTeamMember();
        atm1.userId = user1.id;
        atm1.AccountId = testAccounts[0].id;
        atm1.TeamMemberRole = 'Strategic Partner RC Owner';
		atmList.add(atm1);            
        AccountTeamMember atm2 = new AccountTeamMember();
        atm2.userId = user2.id;
        atm2.AccountId = testAccounts[0].id;
        atm2.TeamMemberRole = 'Renewals Manager';
        atmList.add(atm2);          
        insert atmList;
        System.assert(atmList[0].Id <> null);
         Test.startTest();

            List<AccountTeamMember> testATM = (List<AccountTeamMember>) new AccountTeamMemberSelector()
                .selectAccountTeamMemberByAccountIdAndRole(new List<Object>{testAccounts,'Renewals Manager'})
                .executeQuery();
        
        Test.stopTest();

        System.assertEquals(1, testATM.size());
     }

}