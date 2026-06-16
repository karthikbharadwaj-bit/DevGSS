@isTest
public class Test_BatchJobCleanupThirdPartyLink {
    
	@isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    public static void testBatch(){

        User user = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => 'testUser@invalidEmail.com.org',
                    User.LastName => 'testUser',
                    User.Email => 'testUser@invalidEmail.com',
                    User.Alias => 'testUser',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id FROM Profile WHERE Name ='Standard User'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.isActive => false
                }
            )
            .create()
            .getRecord();
        
        List<ThirdPartyAccountLink> link = new List<ThirdPartyAccountLink>{
            new ThirdPartyAccountLink(
                SSOProviderId = [Select Id from AuthProvider where DeveloperName = 'RC_IdentityConnect'].Id,
                Provider = 'RC_IdentityConnect',
                RemoteIdentifier = '123456708795768367628',
                UserId = user.ID
            )};
                
        Test.startTest();
		BatchJob_CleanupThirdPartyLink batch = new BatchJob_CleanupThirdPartyLink();
        
        batch.start(null);
        batch.execute(null,link);
        batch.finish(null);
        batch.execute(null);
        
        Test.stopTest();
    }
}