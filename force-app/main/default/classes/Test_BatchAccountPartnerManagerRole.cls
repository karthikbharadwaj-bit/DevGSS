@isTest
public class Test_BatchAccountPartnerManagerRole {
    private static User salesmanagerUser = createUser('sm'); //salesmanagerUser

    @isTest
    static void testBatchAccountPartnerManagerRole() {
        Test.startTest();
        Account testAccount1 = new Account();
        testAccount1.Name = 'Test123';
        testAccount1.SignupType__c = 'TRIAL_30NOCC';
        testAccount1.RC_Account_Status__c = 'TRIAL';
        testAccount1.SignupPlatform__c = 'WEB';
        testAccount1.RC_Service_name__c = 'office123';
        testAccount1.RC_Activation_Date__c = null;
        testAccount1.Partner_ID__c = '9852';
        insert testAccount1;
        testAccount1.isPartner = true;
        update testAccount1;
        Id portalAcctId = testAccount1.id;
        Integer roleCnt;
        roleCnt = [Select count() from UserRole where PortalAccountId = :portalAcctId];
        System.assertEquals(0, roleCnt);
        System.runAs(salesmanagerUser) {
		if(roleCnt < 3) {
 
        //Add one role, role will be added bottom up
        //If no roles exist, adds User
        //If 1 role (User) exists, adds Manager
        //If 2 roles (Manager, User) exist, adds Executive
    
        UserRole role = new UserRole();
        role.portalType = 'Partner'; // use 'CustomerPortal' for customer portal roles
        role.PortalAccountId = portalAcctId;
        role.CaseAccessForAccountOwner = 'Edit'; //Modify as needed
        role.OpportunityAccessForAccountOwner = 'Read'; //Modify as needed
        insert role;
    	}
        }
        roleCnt = [Select count() from UserRole where PortalAccountId = :portalAcctId];
        System.assertEquals(1, roleCnt);        
        Id batchJobId = Database.executeBatch(new BatchAccountPartnerManagerRole());
        Test.stopTest();
    }
    

    private static User createUser(String name) {
        return createUser(name, true);
    }

    private static User createUser(String name, Boolean isNeedInsert) {
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
        if(isNeedInsert) {
            insert user;
        }
        return user;
    }
}