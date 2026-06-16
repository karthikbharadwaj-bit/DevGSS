@isTest
public class Test_IgniteLoginFormController {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void doLogin() {
        try {
            IgniteLoginFormController.doLogin('test@salesforce.com', '1234', null);   
        } catch(Exception e) {
            
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    static void doResetPassword() {
        IgniteLoginFormController.doResetPassword('test@salesforce.com');
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
	static void doResetPassword2() {

        UserRole r = [SELECT Id FROM UserRole WHERE PortalType ='Partner' LIMIT 1];

        Account acc;
        Contact con;

        System.runAs(new User(Id = UserInfo.getUserId())) {

            acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('test account')
                })
                .create()
                .getRecord();
        
            con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'test@test.com',
                        Contact.Phone => '1234567890',
                        Contact.Technical_Certification__c => 'Certified Expert',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();
        }

        User portalUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'Internal RC Community - Partner Admin'].Id,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All',
                    User.UserRoleId => r.Id,
                    User.ContactId => con.Id
                }
            )
            .create()
            .getRecord();
        
    	IgniteLoginFormController.doResetPassword(portalUser.Username);
	}
}