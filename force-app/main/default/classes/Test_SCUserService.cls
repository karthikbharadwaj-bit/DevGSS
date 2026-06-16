@isTest
private class Test_SCUserService {
    private static final String USER_USERNAME = 'RC_SupportCommunityNewCaseTestUser@nvx.zn';
    private static final String USER_EMAIL = 'testerino@rc.com';
    private static final String USER_FIRST_NAME = 'Toaster';
    private static final String USER_LAST_NAME = 'McToast';
    private static final String USER_LANGUAGE = 'en_US';
    private static final String USER_POD = 'ADB666';
    private static final String USER_CLUSTER = 'E777';

    private static final String CONTACT_FIRST_NAME = USER_FIRST_NAME;
    private static final String CONTACT_LAST_NAME = USER_LAST_NAME;
    private static final String CONTACT_EMAIL = USER_EMAIL;
    private static final String CONTACT_PHONE = '77777777';
    private static final Decimal CONTACT_PHONE_EXT = 777;

    private static final String ADMIN_USER_USERNAME = 'RC_SupportCommunityNewCaseTestUserAdmin@nvx.zn';
    private static final String ADMIN_USER_EMAIL = 'testerinoadmin@rc.com';
    private static final String ADMIN_USER_FIRST_NAME = 'Admeeeno';
    private static final String ADMIN_USER_LAST_NAME = 'McAdmin';

    private static final String ADMIN_CONTACT_FIRST_NAME = 'Admin';
    private static final String ADMIN_CONTACT_LAST_NAME = 'McToast';
    private static final String ADMIN_CONTACT_EMAIL = 'admin@tes.to';
    private static final String ADMIN_CONTACT_PHONE = '77777777';
    private static final Decimal ADMIN_CONTACT_PHONE_EXT = 777;

    private static final String GUEST_USER_PROFILE_NAME = 'RC Guest User';
    private static final String ADMIN_USER_PROFILE_NAME = 'RC Admin User';

    private static final String EXCEPTION_MESSAGE_NO_USER = 'User does not exist';
    private static final String ERROR_WRONG_EXCEPTION_MESSAGE = 'Wrong exception message';
    private static final String ERROR_EXCEPTION_NOT_THROWN = 'Exception not thrown when ';

    private static final String CASE_INFO_SUBJECT = 'test Subject';
    private static final String CASE_INFO_DESCRIPTION = 'test Description';
    private static final String CASE_INFO_SELECTED_PRODUCT = 'test product one';
    private static final String CASE_INFO_SELECTED_PRODUCT2 = 'test product two';
    private static final String CASE_INFO_SELECTED_PRODUCT3 = 'test product three';
    private static final String CASE_INFO_SEVERITY_LEVEL = 'Level 4 - Medium';
    private static final Datetime CASE_INFO_CREATED_DATE = Datetime.newInstanceGmt(2007, 1, 1);

    private static Id createCaseAsUser(User userToRunTestAs) {
        Id caseId;
        System.runAs(userToRunTestAs) {
            caseId = createCase();
        }
        return caseId;
    }

    private static Id createCase() {

        Case newCase;
        newCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1,
                    Case.Subject => CASE_INFO_SUBJECT,
                    Case.Case_Severity__c => CASE_INFO_SEVERITY_LEVEL,
                    Case.Product_Assistance__c => CASE_INFO_SELECTED_PRODUCT,
                    Case.Product_Assistance_Lvl2__c => CASE_INFO_SELECTED_PRODUCT2,
                    Case.Product_Assistance_Lvl3__c => CASE_INFO_SELECTED_PRODUCT3,
                    Case.Description => CASE_INFO_DESCRIPTION
                }
            )
            .create()
            .getRecord();

        Test.setCreatedDate(newCase.Id, CASE_INFO_CREATED_DATE);
        return newCase.Id;
    }

    @testSetup
    static void setup() {
        Triggers.switchOff();

        Profile guestProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{GUEST_USER_PROFILE_NAME})
            .executeQuery()
            .get(0);

        Profile adminProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{ADMIN_USER_PROFILE_NAME})
            .executeQuery()
            .get(0);

        Account portalAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.Account_POD__c, USER_POD)
            .setField(Account.inContact_Cluster__c, USER_CLUSTER)
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideUniqueString('RC_USER_ID_'))
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => portalAccount.Id,
                Package__c.Service_Type__c => 'Office',
                Package__c.Account_Package_Id__c => '11111111111',
                Package__c.Account_POD__c => USER_POD
            })
            .create()
            .getRecord();

        List<Contact> portalContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_FIRST_NAME, ADMIN_CONTACT_FIRST_NAME}),
                    Contact.LastName => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_LAST_NAME, ADMIN_CONTACT_LAST_NAME}),
                    Contact.Email => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_EMAIL, ADMIN_CONTACT_EMAIL}),
                    Contact.Phone => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_PHONE, ADMIN_CONTACT_PHONE}),
                    Contact.Phone_Ext__c => ValueProviderBuilder.provideList(
                        new List<Decimal>{CONTACT_PHONE_EXT, ADMIN_CONTACT_PHONE_EXT}),
                    Contact.AccountId => ValueProviderBuilder.provideList(
                        new List<String>{portalAccount.Id, portalAccount.Id})
                }
            )
            .create()
            .getRecords();

        new SObjectBuilder(User.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    User.ContactId => ValueProviderBuilder.provideList(
                        new List<String>{portalContacts[0].Id, portalContacts[1].Id}),
                    User.LastName => ValueProviderBuilder.provideList(
                        new List<String>{USER_LAST_NAME, ADMIN_USER_LAST_NAME}),
                    User.FirstName => ValueProviderBuilder.provideList(
                        new List<String>{USER_FIRST_NAME, ADMIN_USER_FIRST_NAME}),
                    User.CommunityNickname => ValueProviderBuilder.provideList(
                        new List<String>{USER_LAST_NAME, ADMIN_USER_LAST_NAME}),
                    User.Email => ValueProviderBuilder.provideList(
                        new List<String>{USER_EMAIL, ADMIN_USER_EMAIL}),
                    User.Username => ValueProviderBuilder.provideList(
                        new List<String>{USER_USERNAME, ADMIN_USER_USERNAME}),
                    User.LanguageLocaleKey => USER_LANGUAGE,
                    User.ProfileId => ValueProviderBuilder.provideList(
                        new List<String>{guestProfile.Id, adminProfile.Id})
                }
            )
            .create();

        Triggers.switchOn();
    }

    private static User guestTestUser {
        get {
            if (guestTestUser == null) {
                guestTestUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{USER_USERNAME}})
                    .selectFields(new List<String>{'ContactId', 'AccountId', 'Contact.AccountId'})
                    .executeQuery()
                    .get(0);
            }
            return guestTestUser;
        }
        private set;
    }

    private static User adminTestUser {
        get {
            if (adminTestUser == null) {
                adminTestUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{ADMIN_USER_USERNAME}})
                    .selectFields(new List<String>{'ContactId', 'AccountId', 'Contact.AccountId'})
                    .executeQuery()
                    .get(0);
            }
            return adminTestUser;
        }
        private set;
    }

    @isTest
    static void testCurrentUser() {
        System.runAs(guestTestUser) {
            System.assertEquals(
                guestTestUser.Id,
                SCUserService.currentUser.Id,
                'Wrong user was retrieved as a current user'
            );
        }
    }

    @isTest
    static void testIsUserSCAdmin() {
        System.runAs(guestTestUser) {
            System.assert(!SCUserService.isCurrentUserSCAdmin, 'Not admin user was identified as an admin');
            System.assert(
                SCUserService.isUserSCAdmin(adminTestUser.Id),
                'Admin user was not identified as an admin'
            );

            try {
                SCUserService.isUserSCAdmin(null);
                System.assert(false, ERROR_EXCEPTION_NOT_THROWN + 'trying to use method with null value');
            } catch(Exception ex) {
                System.assertEquals(
                    SCUserService.ERROR_USER_ID_IS_EMPTY,
                    ex.getMessage(),
                    ERROR_WRONG_EXCEPTION_MESSAGE);
            }
        }
    }

    @isTest
    static void testGetUserByUidAndContactEmail() {
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectField('RC_User_ID__c')
            .setCondition('Name =:bind0')
            .setQueryBindings(new List<Object>{'My Account'})
            .executeQuery();
        System.debug('accounts: ' + accounts);
        String uid = accounts.get(0).RC_User_ID__c;
        System.assertEquals(
            guestTestUser.Id,
            SCUserService.getUserInfoByUidAndContactEmail(uid, CONTACT_EMAIL).Id,
            'The values are not the same'
        );

        try {
            SCUserService.getUserInfoByUidAndContactEmail(uid, ADMIN_USER_EMAIL);
            System.assert(false, ERROR_EXCEPTION_NOT_THROWN + 'there is no user found');
        } catch(Exception ex) {
            System.assertEquals(SCUserService.ERROR_NO_USER_WAS_FOUND, ex.getMessage(), ERROR_WRONG_EXCEPTION_MESSAGE);
        }

        try {
            SCUserService.getUserInfoByUidAndContactEmail(null, CONTACT_EMAIL);
            System.assert(false, ERROR_EXCEPTION_NOT_THROWN + 'trying to use method with null value');
        } catch(Exception ex) {
            System.assertEquals(SCUserService.ERROR_USER_ID_IS_EMPTY, ex.getMessage(), ERROR_WRONG_EXCEPTION_MESSAGE);
        }

        try {
            SCUserService.getUserInfoByUidAndContactEmail(uid, null);
            System.assert(false, ERROR_EXCEPTION_NOT_THROWN + 'trying to use method with null value');
        } catch(Exception ex) {
            System.assertEquals(
                SCUserService.ERROR_CONTACT_EMAIL_IS_EMPTY,
                ex.getMessage(),
                ERROR_WRONG_EXCEPTION_MESSAGE);
        }
    }

    @isTest
    static void testUserFields() {
        User adminTestUser = (User) new UserSelector()
            .selectUserByUsername(new List<Object>{new List<String>{ADMIN_USER_USERNAME}})
            .executeQuery()
            .get(0);
        System.runAs(adminTestUser) {
            System.assertEquals(USER_POD.replace('ADB', 'POD'), SCUserService.accountPOD, 'User POD not found');
            System.assertEquals(USER_CLUSTER, SCUserService.accountCluster, 'User Cluster not found');
        }
    }

    @isTest
    static void testGetRCAdminsForUserAccount() {

        Id adminProfileId = new ProfileSelector()
            .selectProfileByName(new List<String>{ADMIN_USER_PROFILE_NAME})
            .executeQuery()
            .get(0)
            .Id;

        User guestTestUser = (User) new UserSelector()
            .selectUserByUsername(new List<Object>{new List<String>{USER_USERNAME}})
            .selectFields(new List<String>{'ContactId'})
            .executeQuery()
            .get(0);

        List<User> users = SCUserService.getRCAdminsForUserAccount(guestTestUser.Id);

        System.assertEquals(1, users.size());
        System.assertEquals(adminProfileId, users[0].ProfileId, 'Incorrent admin user profile');
        System.assert(ADMIN_USER_USERNAME.equalsIgnoreCase(users[0].Username), 'Incorrent admin user username');
    }

    @isTest
    static void testGetRCAdminsForUserAccount_neg_invalidIdShouldThrowException() {

        try {
            List<User> users = SCUserService.getRCAdminsForUserAccount('random_string');
            System.assert(false, ERROR_EXCEPTION_NOT_THROWN + 'id is invalid');
        } catch (Exception ex) {

            System.assert(ex.getMessage().contains(EXCEPTION_MESSAGE_NO_USER), ERROR_WRONG_EXCEPTION_MESSAGE);
        }

    }
}