@isTest
private class Test_UserSelector {
    //User fields defined
    private static final String USER_FIRST_NAME = 'TestTest';
    private static final String USER_LAST_NAME = 'TestTest';
    private static final String USER_USERNAME = 'Testuniqueuser@gmail.com';
    private static final String USER_EMAIL = 'Test_user@gmail.com';
    private static final String USER_ALIAS = 'Test';
    private static final String USER_TIMEZONE_SID_KEY = 'America/Los_Angeles';
    private static final String USER_LOCAL_SID_KEY = 'en_US';
    private static final String USER_EMAIL_ENCODING_KEY = 'UTF-8';
    private static final String USER_SYSTEM_ADMIN_PROFILE = 'System Administrator';
    private static final String USER_LANGUAGE_LOCAL_KEY  = 'en_US';
    private static final String USER_HIERARCHY_ROLE  = 'Sales Rep';

    private static final String PORTAL_USER_FIRST_NAME = 'TestFN';
    private static final String PORTAL_USER_LAST_NAME = 'TestLN';
    private static final String PORTAL_USER_EMAIL = 'user@email.com';
    private static final String PORTAL_USER_USERNAME = 'testUnique@Uniqueusername.com';
    private static final String PORTAL_USER_CUSTOMER_PROFILE = 'Customer Portal User';
    //Account fields defined
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BLLING_ID = '12345';

    //Contact fields defined
    private static final String CONTACT_FL_NAME = 'Test1';
    private static final String CONTACT_EMAIL = 'test@test.com';
    private static final String CONTACT_PHONE = '1234567890';
    private static final String CONTACT_PREFFERED_LANGUAGE = 'en_US';

    //Assert message defined
    private static final String ASSERT_MESSAGE = 'Users should be selected';

	@testSetup
    private static void createTestData(){

        User testUserAdmin = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.FirstName => USER_FIRST_NAME,
                    User.LastName => USER_LAST_NAME,
                    User.Username => USER_USERNAME,
                    User.Email => USER_EMAIL,
                    User.Alias => USER_ALIAS,
                    User.TimeZoneSidKey => USER_TIMEZONE_SID_KEY,
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => USER_LOCAL_SID_KEY,
                    User.EmailEncodingKey => USER_EMAIL_ENCODING_KEY,
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name =: USER_SYSTEM_ADMIN_PROFILE].Id,
                    User.LanguageLocaleKey => USER_LANGUAGE_LOCAL_KEY,
                    User.Hierarchy_Role__c => USER_HIERARCHY_ROLE
                }
            )
            .create()
            .getRecord();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.Billing_ID__c => ACCOUNT_BLLING_ID
                }
            )
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CONTACT_FL_NAME,
                    Contact.LastName => CONTACT_FL_NAME,
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.Phone => CONTACT_PHONE,
                    Contact.Preferred_Language__c => CONTACT_PREFFERED_LANGUAGE
                }
            )
            .create()
            .getRecord();

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.FirstName => PORTAL_USER_FIRST_NAME,
                    User.LastName => PORTAL_USER_LAST_NAME,
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name =: PORTAL_USER_CUSTOMER_PROFILE].Id,
                    User.UserName => PORTAL_USER_USERNAME,
                    User.Email => PORTAL_USER_EMAIL,
                    User.ContactId => testContact.Id,
                    User.DelegatedApproverId => testUserAdmin.Id
                }
            )
            .create()
            .getRecord();

    }

    @isTest
    private static void testSelectUsers(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        System.assert(users.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUsersByIdNoFields(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> usersByIdNoFields = (List<User>) new UserSelector()
            .selectUsersByIdNoFields(new List<Object>{new Set<Id>{users[1].Id}})
            .setLimit(2)
            .executeQuery();

        System.assert(usersByIdNoFields.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUserForApproval(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> userForApproval = (List<User>) new UserSelector()
            .selectUserForApproval(new List<Object>{new Set<Id>{users[1].Id}})
            .setLimit(2)
            .executeQuery();

        System.assert(userForApproval.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUserForOpportunities(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> userForOpportunities = (List<User>) new UserSelector()
            .selectUserForOpportunities(new List<Object>{new Set<Id>{users[1].Id}})
            .setLimit(1)
            .executeQuery();

        System.assert(userForOpportunities.size() > 0, ASSERT_MESSAGE);
    }

 	@isTest
    private static void testSelectUserByLastName(){
        List<User> userByLastName = (List<User>) new UserSelector()
            .selectUserByLastName(new List<Object>{new Set<String>{PORTAL_USER_LAST_NAME}})
            .executeQuery();

        System.assert(userByLastName.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUserByName(){
        List<User> userByName = (List<User>) new UserSelector()
            .selectUserByName(new List<Object>{new Set<String>{PORTAL_USER_FIRST_NAME + ' ' + PORTAL_USER_LAST_NAME}})
            .executeQuery();

        System.assert(userByName.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUserByUsername(){
        List<User> userByUsername = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object>{new Set<String>{PORTAL_USER_USERNAME}})
            .executeQuery();

        System.assert(userByUsername.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectActiveUserByNameAndProfile(){
        List<User> activeUserByNameAndProfile = (List<User>) new UserSelector()
            .selectActiveUserByNameAndProfile(new List<Object>{new Set<String>{PORTAL_USER_FIRST_NAME + ' ' + PORTAL_USER_LAST_NAME},
                								   			   new Set<String>{PORTAL_USER_CUSTOMER_PROFILE}})
            .executeQuery();

        System.assert(activeUserByNameAndProfile.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUserByIdForLeadConvert(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> userByIdForLeadConvert = (List<User>) new UserSelector()
            .selectUserByIdForLeadConvert(new List<Object>{new Set<Id>{users[0].Id}})
            .setLimit(2)
            .executeQuery();

        System.assert(userByIdForLeadConvert.size() > 0, ASSERT_MESSAGE);
    }

   	@isTest
    private static void testSelectUserForDFRList(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> userForDFRList = (List<User>) new UserSelector()
            .selectUserForDFRList(new List<Object>{new Set<Id>{users[1].Id}})
            .setLimit(2)
            .executeQuery();

        System.assert(userForDFRList.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUserForDFRSingle(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> userForDFRSingle = (List<User>) new UserSelector()
            .selectUserForDFRSingle(new List<Object>{new Set<Id>{users[1].Id}})
            .setLimit(2)
            .executeQuery();

        System.assert(userForDFRSingle.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUserRoleById(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> userRoleById = (List<User>) new UserSelector()
            .selectUserRoleById(new List<Object>{new Set<Id>{users[1].Id}})
            .setLimit(2)
            .executeQuery();

        System.assert(userRoleById.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUsersRolesByIds(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> usersRolesByIds = (List<User>) new UserSelector()
            .selectUsersRolesByIds(new List<Object>{new Set<Id>{users[1].Id}})
            .setLimit(2)
            .executeQuery();

        System.assert(usersRolesByIds.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUserByIdForNewCase(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> userByIdForNewCase = (List<User>) new UserSelector()
            .selectUserByIdForNewCase(new List<Object>{new Set<Id>{users[1].Id}})
            .setLimit(2)
            .executeQuery();

        System.assert(userByIdForNewCase.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectMarketoUser(){
        List<User> marketoUser = (List<User>) new UserSelector()
            .selectMarketoUser()
            .executeQuery();

        System.assert(marketoUser.size() > 0, ASSERT_MESSAGE);
    }

   	@isTest
    private static void testSelectUsersByContactId(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<User> usersByContactId = (List<User>) new UserSelector()
            .selectUsersByContactId(new List<Object>{new Set<Id>{contacts[0].Id}})
            .executeQuery();

        System.assert(usersByContactId.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUsersByIdWithContactInfo(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<User> usersByAccountIdsAndProfileName = (List<User>) new UserSelector()
            .selectUsersByAccountIdsAndProfileName(new List<Object>{new Set<Id>{accounts[0].Id},
                													new Set<String>{PORTAL_USER_CUSTOMER_PROFILE}})
            .executeQuery();

        List<User> usersByIdWithContactInfo = (List<User>) new UserSelector()
            .selectUsersByIdWithContactInfo(new List<Object>{new Set<Id>{usersByAccountIdsAndProfileName[0].Id}})
            .executeQuery();

        System.assert(usersByIdWithContactInfo.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUsersByIdWithContactInfoForAPI(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> usersByIdWithContactInfoForAPI = (List<User>) new UserSelector()
            .selectUsersByIdWithContactInfoForAPI(new List<Object>{new Set<Id>{users[1].Id}})
            .setLimit(2)
            .executeQuery();

        System.assert(usersByIdWithContactInfoForAPI.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUsersByAccountIdsAndProfileName(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<User> usersByAccountIdsAndProfileName = (List<User>) new UserSelector()
            .selectUsersByAccountIdsAndProfileName(new List<Object>{new Set<Id>{accounts[0].Id},
                													new Set<String>{PORTAL_USER_CUSTOMER_PROFILE}})
            .executeQuery();

        System.assert(usersByAccountIdsAndProfileName.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectActiveUserByName(){
        List<User> activeUserByName = (List<User>) new UserSelector()
            .selectActiveUserByName(new List<Object>{new Set<String>{PORTAL_USER_FIRST_NAME + ' ' + PORTAL_USER_LAST_NAME}})
            .executeQuery();

        System.assert(activeUserByName.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUserForSignUp(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> userForSignUp = (List<User>) new UserSelector()
            .selectUserForSignUp(users[1].Id)
            .setLimit(2)
            .executeQuery();

        System.assert(userForSignUp.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUserByNameAndEmail(){
        List<User> userByNameAndEmail = (List<User>) new UserSelector()
            .selectUserByNameAndEmail(new List<Object>{new Set<String>{USER_FIRST_NAME + ' ' + USER_LAST_NAME},
                									   new Set<String>{USER_EMAIL}})
            .executeQuery();

        System.assert(userByNameAndEmail.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectManagerEmailByIds(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> managerEmailByIds = (List<User>) new UserSelector()
            .selectManagerEmailByIds(new List<Object>{new Set<Id>{users[1].Id}})
            .setLimit(2)
            .executeQuery();

        System.assert(managerEmailByIds.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUserByIdForGlip(){
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> userByIdForGlip = (List<User>) new UserSelector()
            .selectUserByIdForGlip(new List<Object>{new Set<Id>{users[1].Id}})
            .setLimit(2)
            .executeQuery();

        System.assert(userByIdForGlip.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectRelaywareApiUser() {
        Test.startTest();
            QueryFactory factory = new UserSelector()
                .selectRelaywareApiUser()
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM User WHERE Name = \'' + UserHelper.API_USER_NAME + '\' AND ' + 'Profile.Name = \'' + ProfileHelper.PROFILE_NAME_RELAYWARE + '\'';
        Assert.isTrue(factory.getQuery().contains(expectedWhereClause), 'selectRelaywareApiUser must have the right WHERE clause');
    }

    @isTest
    private static void testSelectCachedUsers(){
        List<User> cachedUsers = (List<User>) new UserSelector()
            .selectCachedUsers()
            .executeQuery();

        System.assert(cachedUsers.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectCurrentUserForSettingsService(){
        List<User> currentUserForSettingsService = (List<User>) new UserSelector()
            .selectCurrentUserForSettingsService()
            .executeQuery();

        System.assert(currentUserForSettingsService.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUsersByProfileIds(){
        List<User> userByUsername = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object>{new Set<String>{PORTAL_USER_USERNAME}})
            .setLimit(2)
            .executeQuery();

        List<User> usersByProfileIds = (List<User>) new UserSelector()
            .selectUsersByProfileIds(new Set<Id>{userByUsername[0].ProfileId})
            .setLimit(2)
            .executeQuery();

        System.assert(usersByProfileIds.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUsersByIds(){
        List<User> users = (List<User>) new UserSelector(true, true)
            .selectUsers()
            .setLimit(2)
            .executeQuery();

        List<User> usersByIds = (List<User>) new UserSelector()
            .selectUsersByIds(new Set<Id>{users[0].Id})
            .setLimit(2)
            .executeQuery();

        System.assert(usersByIds.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectUsersWithDelegatedApproversByIds() {
        Set<Id> userIds = new Set<Id>();
        List<User> users = (List<User>) new UserSelector(true, true)
            .selectUsers()
            .setCondition('DelegatedApproverId != null')
            .executeQuery();

        List<User> usersWithDelegatedApproversByIds = (List<User>) new UserSelector()
            .selectUsersWithDelegatedApproversByIds(new Set<Id>{users[0].Id})
            .executeQuery();

        System.assert(usersWithDelegatedApproversByIds.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testGetCacheableUserFields() {
        // Test that the getCacheableUserFields method returns the expected fields
        UserSelector userSelector = new UserSelector();
        List<String> cacheableFields = userSelector.getCacheableUserFields();
        Assert.areEqual(25, cacheableFields.size(), 'Should have exactly 25 cacheable user fields');
    }
}