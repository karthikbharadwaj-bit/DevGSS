@isTest
private class Test_SupportCommunityUsers {
    private static final String COMMUNITY_NAME = 'RingCentral Support';
    private static final Integer DEFAULT_LIMIT_COUNT = 2;
    private static final String RC_GUEST_USER = 'RC Guest User';
    private static final String RC_ADMIN_USER = 'RC Admin User';

    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_CSM_NAME = 'CSM_S_U';
    private static final String ACCOUNT_CSM_EMAIL = 'csm@email.sent';
    private static final String ACCOUNT_PAYMENT_PLAN = 'Monthly';
    private static final String ACCOUNT_ID = '001123456789101112';
    private static final String ACCOUNT_POD = 'POD1';
    private static final String ACCOUNT_UID = 'UID1';
    private static final String ACCOUNT_CLUSTER = 'E1';

    private static final String USER_USERNAME = 'RC_SupportCommunityNewCaseTestUser@nvx.zn';
    private static final String USER_EMAIL = 'testerino@rc.com';
    private static final String USER_FIRST_NAME = 'Toaster';
    private static final String USER_LAST_NAME = 'McToast';
    private static final String USER_LANGUAGE = 'en_US';

    private static final String CONTACT_FIRST_NAME = USER_FIRST_NAME;
    private static final String CONTACT_LAST_NAME = USER_LAST_NAME;
    private static final String CONTACT_EMAIL = USER_EMAIL;
    private static final String CONTACT_PHONE = '77777777';
    private static final Decimal CONTACT_PHONE_EXT = 777;

    private static final String ADMIN_USER_USERNAME = 'RC_SupportCommunityNewCaseTestUserAdmin@nvx.zn';
    private static final String ADMIN_USER_EMAIL = 'testerinoadmin@rc.com';
    private static final String ADMIN_USER_FIRST_NAME = 'Admeeeno';
    private static final String ADMIN_USER_LAST_NAME = 'McAdmin';
    private static final String ADMIN_USER_LANGUAGE = 'en_US';

    private static final String ADMIN_CONTACT_FIRST_NAME = 'Admin';
    private static final String ADMIN_CONTACT_LAST_NAME = 'McToast';
    private static final String ADMIN_CONTACT_EMAIL = 'admin@tes.to';
    private static final String ADMIN_CONTACT_PHONE = '77777777';
    private static final Decimal ADMIN_CONTACT_PHONE_EXT = 777;

    private static final String CONTACT_ADMIN_EMAIL = 'contAdmin@nera.com';
    private static final String CONTACT_GUEST_EMAIL = 'cont@nera.com';
    private static final List<String> ADMIN_AND_GUEST_EMAILS = new List<String>{
        CONTACT_ADMIN_EMAIL,
        CONTACT_GUEST_EMAIL
    };

    private static final String GUEST_USER_PROFILE_NAME = 'RC Guest User';
    private static final String ADMIN_USER_PROFILE_NAME = 'RC Admin User';

    private static final List<String> USER_SEARCH_FIELDS = new List<String>{
        'ContactId',
        'Contact.AccountId',
        'Profile.Name'
    };

    private static final String COUNTRY = 'en_RU';
    private static final String CODE = 'Ru';
    private static final String LANG_TITLE = 'Russian';
    private static final String TITLE = 'test title';
    private static final String LANG = 'RU';
    private static final String DOMAIN = 'https://google.com/';
    private static final Boolean IS_COMMUNITY = true;

    private static User guestTestUser {
        get {
            if (guestTestUser == null) {
                guestTestUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{USER_USERNAME}})
                    .selectFields(new List<String>{'ContactId', 'AccountId'})
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
                    .selectFields(new List<String>{'ContactId'})
                    .executeQuery()
                    .get(0);
            }
            return adminTestUser;
        }
        private set;
    }

    @testSetup
    private static void setup() {
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
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.CSM_Name__c => ACCOUNT_CSM_NAME,
                    Account.CSM_Email__c => ACCOUNT_CSM_EMAIL,
                    Account.Payment_Plan__c => ACCOUNT_PAYMENT_PLAN,
                    Account.RC_User_ID__c => ACCOUNT_UID,
                    Account.inContact_Cluster__c => ACCOUNT_CLUSTER
                }
            )
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => portalAccount.Id,
                Package__c.Service_Type__c => 'Office',
                Package__c.Account_Package_Id__c => '11111111111',
                Package__c.Account_POD__c => ACCOUNT_POD
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

        List<User> users = new SObjectBuilder(User.SObjectType)
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
                    User.Username => ValueProviderBuilder.provideList(new List<String>{USER_USERNAME, ADMIN_USER_USERNAME}),
                    User.LanguageLocaleKey => USER_LANGUAGE,
                    User.ProfileId => ValueProviderBuilder.provideList(
                        new List<String>{guestProfile.Id, adminProfile.Id})
                }
            )
            .create()
            .getRecords();

        List<SetupEntityAccess> seas = (List<SetupEntityAccess>) new SetupEntityAccessSelector()
                .selectSetupEntityAccessByCustomPermissionName(new List<Object>{SCUserService.CUSTOM_PERMISSION_NAME})
                .executeQuery();
        Id commAdminPermSetId = seas[0].ParentId;

        System.runAs((User) new UserSelector()
                .selectUsersByIdNoFields(new List<Object>{new List<Id>{UserInfo.getUserId()}})
                .executeQuery()[0]) {
            new SObjectBuilder(PermissionSetAssignment.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PermissionSetAssignment.AssigneeId => users[1].Id,
                        PermissionSetAssignment.PermissionSetId => commAdminPermSetId
                    }
                )
                .create();
        }

        new SObjectBuilder(Case.SObjectType)
            .quantity(2)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Case.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Case.ContactId => ValueProviderBuilder.provideList(
                        new List<Id>{portalContacts[0].Id, portalContacts[1].Id}
                    ),
                    Case.AccountId => portalAccount.Id
                }
            )
            .create();
        Topic top = (Topic) new SObjectBuilder(Topic.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Topic.Name => 'TestTop',
                    Topic.NetworkId => [SELECT Id FROM Network WHERE Name = :COMMUNITY_NAME LIMIT 1].Id
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(SupportCommunityTopicRating__c.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    SupportCommunityTopicRating__c.Position__c => ValueProviderBuilder.provideList(
                        new List<Integer>{1, 2}
                    ),
                    SupportCommunityTopicRating__c.TopicId__c => top.Id,
                    SupportCommunityTopicRating__c.Active__c => true,
                    SupportCommunityTopicRating__c.FullTitle__c => TITLE,
                    SupportCommunityTopicRating__c.Place__c => 'Trending',
                    SupportCommunityTopicRating__c.Language__c => 'en_US'
                }
            )
            .create();
        Triggers.switchOn();
    }

    @isTest
    private static void validateIsCommunityUserInsertedSuccessful() {
        System.assertNotEquals(guestTestUser, null, 'There is no RC Guest User or/and RC Admin User profiles');
    }

    @isTest
    private static void testGetUserInfo_asNonCommunityUser() {
        SupportCommunityUsers.UserInfo res = SupportCommunityUsers.getUserInfo();
        System.assertEquals(false, res.isAdmin, 'Non-community user has isAdmin as True');
        System.assertEquals(null, res.user, 'Non-community user have been returned successfully');
    }

    @isTest
    private static void testGetUserInfo_asGuest() {
        SupportCommunityUsers.UserInfo res;
        System.runAs(guestTestUser) {
            res = SupportCommunityUsers.getUserInfo();
        }
        System.assertEquals(false, res.isAdmin, 'Guest user has isAdmin as True');
        System.assertEquals(USER_FIRST_NAME, res.user.FirstName, 'Incorrect guest first name');
        System.assertEquals(USER_LAST_NAME, res.user.LastName, 'Incorrect guest last name');
        System.assertEquals(USER_EMAIL, res.user.Email, 'Incorrect guest email');
    }

    @isTest
    private static void testGetUserInfo_asAdmin() {
        SupportCommunityUsers.UserInfo res;
        System.runAs(adminTestUser) {
            res = SupportCommunityUsers.getUserInfo();
        }
        System.assertEquals(true, res.isAdmin, 'Admin user has isAdmin as False');
        System.assertEquals(ADMIN_USER_FIRST_NAME, res.user.FirstName, 'Incorrect admin first name');
        System.assertEquals(ADMIN_USER_LAST_NAME, res.user.LastName, 'Incorrect admin last name');
        System.assertEquals(ADMIN_USER_EMAIL, res.user.Email, 'Incorrect admin email');
    }

    @isTest
    private static void testGetUserFullInfo_asNonCommunityUser() {
        User res = (User) SupportCommunityUsers.getUserFullInfo()
            .data.get(SupportCommunityUsers.LABEL_USER_FULL_INFO);
        System.assertEquals(null, res, 'Non-community user full info have been returned successfully');
    }

    @isTest
    private static void testGetUserFullInfo_asGuest() {
        User res;
        System.runAs(guestTestUser) {
            res = (User) SupportCommunityUsers.getUserFullInfo()
                .data.get(SupportCommunityUsers.LABEL_USER_FULL_INFO);
        }
        System.assertNotEquals(null, res, 'Guest user full info not returned');
        System.assertEquals(USER_FIRST_NAME, res.FirstName, 'Incorrect guest first name');
        System.assertEquals(USER_LAST_NAME, res.LastName, 'Incorrect guest last name');
        System.assertEquals(USER_EMAIL, res.Email, 'Incorrect guest email');
        System.assertEquals(CONTACT_EMAIL, res.Contact.Email, 'Incorrect guest first name');
        System.assertEquals(CONTACT_PHONE, res.Contact.Phone, 'Incorrect guest first name');
        System.assertEquals(CONTACT_PHONE_EXT, res.Contact.Phone_Ext__c, 'Incorrect guest first name');
        System.assertEquals(ACCOUNT_NAME, res.Contact.Account.Name, 'Incorrect guest Account.Name');
        System.assertEquals(ACCOUNT_CSM_NAME, res.Contact.Account.CSM_Name__c, 'Incorrect guest Account.CSM_Name');
        System.assertEquals(ACCOUNT_CSM_EMAIL, res.Contact.Account.CSM_Email__c, 'Incorrect guest Account.CSM_Email');
        System.assertEquals(ACCOUNT_UID, res.Contact.Account.RC_User_ID__c, 'Incorrect guest Account.RC_User_ID');
        System.assertEquals(ACCOUNT_CLUSTER, res.Contact.Account.inContact_Cluster__c, 'Incorrect guest Account.inContact_Cluster');
        try {
            String plan = res.Contact.Account.Payment_Plan__c;
            System.assert(false, 'Billing info returned for a guest user');
        } catch (System.SObjectException ex) {
            System.assert(
                ex.getMessage().contains('row was retrieved via SOQL without querying the requested field'),
                'Wrong exception thrown'
            );
        }
    }

    @isTest
    private static void testGetUserFullInfo_asAdmin() {
        User res;
        System.runAs(adminTestUser) {
            res = (User) SupportCommunityUsers.getUserFullInfo()
                .data.get(SupportCommunityUsers.LABEL_USER_FULL_INFO);
        }
        System.assertNotEquals(null, res, 'Admin user full info not returned');
        System.assertEquals(ADMIN_USER_FIRST_NAME, res.FirstName, 'Incorrect admin first name');
        System.assertEquals(ADMIN_USER_LAST_NAME, res.LastName, 'Incorrect admin last name');
        System.assertEquals(ADMIN_USER_EMAIL, res.Email, 'Incorrect admin email');
        System.assertEquals(ADMIN_CONTACT_EMAIL, res.Contact.Email, 'Incorrect admin first name');
        System.assertEquals(ADMIN_CONTACT_PHONE, res.Contact.Phone, 'Incorrect admin first name');
        System.assertEquals(ADMIN_CONTACT_PHONE_EXT, res.Contact.Phone_Ext__c, 'Incorrect admin first name');
        System.assertEquals(ACCOUNT_NAME, res.Contact.Account.Name, 'Incorrect admin Account.Name');
        System.assertEquals(ACCOUNT_CSM_NAME, res.Contact.Account.CSM_Name__c, 'Incorrect admin Account.CSM_Name');
        System.assertEquals(ACCOUNT_CSM_EMAIL, res.Contact.Account.CSM_Email__c, 'Incorrect admin Account.CSM_Email');
        System.assertEquals(ACCOUNT_PAYMENT_PLAN, res.Contact.Account.Payment_Plan__c, 'Incorrect admin Account.Payment_Plan');
        System.assertEquals(ACCOUNT_UID, res.Contact.Account.RC_User_ID__c, 'Incorrect admin Account.RC_User_ID');
        System.assertEquals(ACCOUNT_CLUSTER, res.Contact.Account.inContact_Cluster__c, 'Incorrect admin Account.inContact_Cluster');
    }

    @isTest
    private static void testGetCasesInfo_asGuest() {
        List<Case> res;
        System.runAs(guestTestUser) {
            res = (List<Case>) SupportCommunityUsers.getCasesInfo().data.get(SupportCommunityUsers.LABEL_CASES);
        }
        System.assertEquals(
            1,
            res.size(),
            'Should be 1 case for guest user'
        );
    }

    @isTest
    private static void testGetCasesInfo_asAdmin() {
        List<Case> res;
        System.runAs(adminTestUser) {
            res = (List<Case>) SupportCommunityUsers.getCasesInfo().data.get(SupportCommunityUsers.LABEL_CASES);
        }
        System.assertEquals(
            2,

            res.size(),
            'Should be 2 cases for admin user'
        );
    }

    @isTest
    private static void getEmptyInfoAboutTopic() {
        System.assertEquals(1, SupportCommunityUsers.getTopicsInfo('en_US').size(), 'Should be 1 topic info');
    }

    @isTest
    private static void testCheckCasesRecordType() {
        String allFeedFilter = '[{"type":"Case","offset":0},{"type":"Maintenance","offset":0}]';
        String maintenanceFeedFilter = '[{"type":"Maintenance","offset":0}]';
        String emptyFilter = '[]';

        System.runAs(guestTestUser) {
            SupportCommunityUsers.DEFAULT_LIMIT_COUNT = DEFAULT_LIMIT_COUNT;
            Test.startTest();
            List<Case> casesToInsert = new List<Case>();
            casesToInsert.addAll(createCases(guestTestUser.ContactId, guestTestUser.AccountId, 1, 'Maintenance'));
            casesToInsert.addAll(createCases(guestTestUser.ContactId, guestTestUser.AccountId, 1, 'Support-Case'));
            insert casesToInsert;
            Test.stopTest();

            List<Object> casesFeed = SupportCommunityUsers.getCasesFeed(allFeedFilter);
            System.assertEquals(2, casesFeed.size(), 'Should be 2 cases for guest user');

            Map<String, Object> case0 = (Map<String, Object>) casesFeed[0];
            Map<String, Object> case1 = (Map<String, Object>) casesFeed[1];
            System.assertEquals('Case', case0.get('RecordTypeName'), 'The recordTypeName of case should be Case');
            System.assertEquals(
                'Maintenance',
                case1.get('RecordTypeName'),
                'The recordTypeName of case should be Maintenance'
            );

            System.assertEquals(
                1,
                SupportCommunityUsers.getCasesFeed(maintenanceFeedFilter).size(),
                'One maintenance case should be found for this filter'
            );
            System.assertEquals(
                0,
                SupportCommunityUsers.getCasesFeed(emptyFilter).size(),
                'No cases should be found for this filter'
            );
        }
    }

    @isTest
    private static void testGetCasesFeed() {
        String allFeedFilter = '[{"type":"Case","offset":0},{"type":"Maintenance","offset":0}]';
        String caseFeedFilter = '[{"type":"Case","offset":0}]';
        String emptyFilter = '[]';

        System.runAs(guestTestUser) {
            SupportCommunityUsers.DEFAULT_LIMIT_COUNT = DEFAULT_LIMIT_COUNT / 2;

            System.assertEquals(
                1,
                SupportCommunityUsers.getCasesFeed(caseFeedFilter).size(),
                'One case should be found for this filter'
            );
            System.assertEquals(
                0,
                SupportCommunityUsers.getCasesFeed(emptyFilter).size(),
                'No cases should be found for this filter'
            );
            System.assertEquals(
                1,
                SupportCommunityUsers.getCasesFeed('').size(),
                'One case should be found for this filter'
            );
            System.assertEquals(
                1,
                SupportCommunityUsers.getCasesFeed(allFeedFilter).size(),
                'One case should be found for this filter'
            );

            Test.startTest();
            List<Case> casesToInsert = new List<Case>();
            casesToInsert.addAll(createCases(guestTestUser.ContactId, guestTestUser.AccountId, 1, 'Maintenance'));
            insert casesToInsert;

            System.assertEquals(
                1,
                SupportCommunityUsers.getCasesFeed(caseFeedFilter).size(),
                'One case should be found for this filter'
            );
            System.assertEquals(
                0,
                SupportCommunityUsers.getCasesFeed(emptyFilter).size(),
                'No cases should be found for this filter'
            );
            System.assertEquals(
                1,
                SupportCommunityUsers.getCasesFeed('').size(),
                'One case should be found for this filter'
            );
            System.assertEquals(
                1,
                SupportCommunityUsers.getCasesFeed(allFeedFilter).size(),
                'One case should be found for this filter'
            );

            List<Case> casesToInsert2 = new List<Case>();
            casesToInsert2.addAll(createCases(guestTestUser.ContactId, guestTestUser.AccountId, 1, 'Support-Case'));
            insert casesToInsert2;

            System.assertEquals(
                1,
                SupportCommunityUsers.getCasesFeed(caseFeedFilter).size(),
                'One case should be found for this filter'
            );
            System.assertEquals(
                0,
                SupportCommunityUsers.getCasesFeed(emptyFilter).size(),
                'No cases should be found for this filter'
            );
            System.assertEquals(
                1,
                SupportCommunityUsers.getCasesFeed('').size(),
                'One case should be found for this filter'
            );
            System.assertEquals(
                1,
                SupportCommunityUsers.getCasesFeed(allFeedFilter).size(),
                'One case should be found for this filter'
            );
            Test.stopTest();

            SupportCommunityUsers.DEFAULT_LIMIT_COUNT = DEFAULT_LIMIT_COUNT * 4;
            System.assertEquals(
                3,
                SupportCommunityUsers.getCasesFeed(allFeedFilter).size(),
                'Three cases should be found for this filter'
            );
        }
    }

    @isTest
    private static void testProcessFilter() {
        SupportCommunityUsers.DEFAULT_LIMIT_COUNT = DEFAULT_LIMIT_COUNT;

        Map<String, String> mapParametersForCaseCondition = new Map<String, String>();
        mapParametersForCaseCondition.put('ContactId', '');
        mapParametersForCaseCondition.put('AccountId', ACCOUNT_ID);

        Map<String, String> mapParametersForMaintenanceCondition = new Map<String, String>();

        SupportCommunityUsers.Filter openCasesFilter = new SupportCommunityUsers.Filter('Case', true);
        System.assertEquals(
            ' WHERE AccountId = \'' +
            ACCOUNT_ID +
            '\' AND Status NOT IN :UNWANTED_CASE_STATUSES' +
            ' AND RecordType.Name NOT IN :casesRecordTypeNamesForFeed' +
            ' ORDER BY LastModifiedDate DESC LIMIT ' +
            DEFAULT_LIMIT_COUNT +
            ' OFFSET 0',
            SupportCommunityUsers.processFilter('', openCasesFilter, mapParametersForCaseCondition),
            'Wrong filter process Case and isOpen'
        );

        SupportCommunityUsers.Filter defaultFilter = new SupportCommunityUsers.Filter();
        System.assertEquals(
            ' WHERE AccountId = \'' +
            ACCOUNT_ID +
            '\' ORDER BY LastModifiedDate DESC LIMIT ' +
            DEFAULT_LIMIT_COUNT +
            ' OFFSET 0',
            SupportCommunityUsers.processFilter('', defaultFilter, mapParametersForCaseCondition),
            'Wrong filter process default'
        );

        SupportCommunityUsers.Filter maintenanceFilter = new SupportCommunityUsers.Filter('Maintenance', null);
        System.assertEquals(
            ' LIMIT 0',
            SupportCommunityUsers.processFilter('', maintenanceFilter, mapParametersForMaintenanceCondition),
            'Wrong filter process Maintenance'
        );

        mapParametersForMaintenanceCondition.put('Account_POD__c', ACCOUNT_POD);
        System.assertEquals(
            ' WHERE Account_POD__c = \'' +
            ACCOUNT_POD +
            '\' AND RecordType.Name = \'Maintenance\'' +
            ' ORDER BY CreatedDate DESC LIMIT ' +
            DEFAULT_LIMIT_COUNT +
            ' OFFSET 0',
            SupportCommunityUsers.processFilter('', maintenanceFilter, mapParametersForMaintenanceCondition),
            'Wrong filter process Maintenance with POD'
        );

        mapParametersForMaintenanceCondition.put('RC_User_ID__c', ACCOUNT_UID);
        System.assertEquals(
            ' WHERE (Account_POD__c = \'' +
            ACCOUNT_POD +
            '\' OR RC_User_ID__c = \'' +
            ACCOUNT_UID +
            '\') AND RecordType.Name = \'Maintenance\'' +
            ' ORDER BY CreatedDate DESC LIMIT ' +
            DEFAULT_LIMIT_COUNT +
            ' OFFSET 0',
            SupportCommunityUsers.processFilter('', maintenanceFilter, mapParametersForMaintenanceCondition),
            'Wrong filter process Maintenance with POD and UID'
        );

        mapParametersForMaintenanceCondition.put('inContact_Cluster__c', ACCOUNT_CLUSTER);
        System.assertEquals(
            ' WHERE (Account_POD__c = \'' +
            ACCOUNT_POD +
            '\' OR RC_User_ID__c = \'' +
            ACCOUNT_UID +
            '\' OR inContact_Cluster__c = \'' +
            ACCOUNT_CLUSTER +
            '\') AND RecordType.Name = \'Maintenance\'' +
            ' ORDER BY CreatedDate DESC LIMIT ' +
            DEFAULT_LIMIT_COUNT +
            ' OFFSET 0',
            SupportCommunityUsers.processFilter('', maintenanceFilter, mapParametersForMaintenanceCondition),
            'Wrong filter process Maintenance with POD and UID and Cluster'
        );
    }

    @isTest
    private static void testProcessFilterWithValidOffset() {
        Integer validOffset = 0;

        String allFeedFilterWithValidOffset =
            '[{"type":"Case","offset":' +
            validOffset +
            '},{"type":"Maintenance","offset":' +
            validOffset +
            '}]';
        String maintenanceFeedFilterWithValidOffset = '[{"type":"Maintenance","offset":' + validOffset + '}]';

        System.runAs(guestTestUser) {
            SupportCommunityUsers.DEFAULT_LIMIT_COUNT = DEFAULT_LIMIT_COUNT;
            Test.startTest();
            List<Case> casesToInsert = new List<Case>();
            casesToInsert.addAll(createCases(guestTestUser.ContactId, guestTestUser.AccountId, 1, 'Maintenance'));
            casesToInsert.addAll(createCases(guestTestUser.ContactId, guestTestUser.AccountId, 1, 'Support-Case'));
            insert casesToInsert;
            Test.stopTest();
            System.assertEquals(
                2,
                SupportCommunityUsers.getCasesFeed(allFeedFilterWithValidOffset).size(),
                'Should be 2 cases for guest user'
            );
            System.assertEquals(
                1,
                SupportCommunityUsers.getCasesFeed(maintenanceFeedFilterWithValidOffset).size(),
                'One maintenance case should be found for this filter'
            );
        }
    }

    @isTest
    private static void testProcessFilterWithNotValidOffset() {
        Integer validOffset = 0;
        Integer notValidMaxOffset = SupportCommunityUsers.MAX_VALID_OFFSET + 1;
        Integer notValidMinOffset = SupportCommunityUsers.MIN_VALID_OFFSET - 1;
        Integer notValidNullOffset = null;

        String allFeedFilterWithValidAndNotValidOffset =
            '[{"type":"Case","offset":' +
            validOffset +
            '},{"type":"Maintenance","offset":' +
            notValidMaxOffset +
            '}]';
        String allFeedFilterWithNotValidOffset =
            '[{"type":"Case","offset":' +
            notValidMinOffset +
            '},{"type":"Maintenance","offset":' +
            notValidMaxOffset +
            '}]';
        String maintenanceFeedFilterWithNotValidMaxOffset = '[{"type":"Maintenance","offset":' + notValidMaxOffset + '}]';
        String maintenanceFeedFilterWithNotValidMinOffset = '[{"type":"Maintenance","offset":' + notValidMinOffset + '}]';
        String maintenanceFeedFilterWithNotValidNullOffset = '[{"type":"Maintenance","offset":' + notValidNullOffset + '}]';

        System.runAs(guestTestUser) {
            SupportCommunityUsers.DEFAULT_LIMIT_COUNT = DEFAULT_LIMIT_COUNT;
            Test.startTest();
            List<Case> casesToInsert = new List<Case>();
            casesToInsert.addAll(createCases(guestTestUser.ContactId, guestTestUser.AccountId, 1, 'Maintenance'));
            casesToInsert.addAll(createCases(guestTestUser.ContactId, guestTestUser.AccountId, 1, 'Support-Case'));
            insert casesToInsert;
            Test.stopTest();

            System.assertEquals(
                0,
                SupportCommunityUsers.getCasesFeed(allFeedFilterWithValidAndNotValidOffset).size(),
                'Should be no cases for not valid offset'
            );
            System.assertEquals(
                0,
                SupportCommunityUsers.getCasesFeed(allFeedFilterWithNotValidOffset).size(),
                'Should be no cases for not valid offset'
            );
            System.assertEquals(
                0,
                SupportCommunityUsers.getCasesFeed(maintenanceFeedFilterWithNotValidMaxOffset).size(),
                'Should be no cases for not valid offset'
            );
            System.assertEquals(
                0,
                SupportCommunityUsers.getCasesFeed(maintenanceFeedFilterWithNotValidMinOffset).size(),
                'Should be no cases for not valid offset'
            );
            System.assertEquals(
                0,
                SupportCommunityUsers.getCasesFeed(maintenanceFeedFilterWithNotValidNullOffset).size(),
                'Should be no cases for not valid offset'
            );
        }
    }

    private static List<Case> createCases(
        String userContactId,
        String userAccountId,
        Integer count,
        String recordType
    ) {
        List<Case> testCases = new List<Case>();
        Id recordTypeIdContact = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        for (Integer i = 0; i < count; i++) {
            Case newCase = new Case(
                ContactId = userContactId,
                Subject = 'Test ' + i,
                Status = 'New',
                AccountId = userAccountId,
                RecordTypeId = recordTypeIdContact,
                Account_POD__c = ACCOUNT_POD
            );
            testCases.add(newCase);
        }
        return testCases;
    }
    @isTest
    private static void testGetLanguages() {
        SupportCommunityLanguages__c scLang = new SupportCommunityLanguages__c(
            Name = 'Test_01',
            Language__c = LANG,
            Country__c = COUNTRY,
            Code__c = CODE,
            Title__c = LANG_TITLE,
            Domain__c = DOMAIN,
            isCommunity__c = IS_COMMUNITY
        );
        insert scLang;
        Test.startTest();
        List<Object> langs = SupportCommunityUsers.getLanguages();
        Test.stopTest();
        Integer count = langs.size();
        System.assert(count > 0, 'Languages from Custom Settings is empty.');
        Boolean hasNewLang = false;
        for (Integer i = 0; i < count; i++) {
            Map<String, Object> curLang = (Map<String, Object>) (langs[i]);
            if (curLang.get('title') == LANG_TITLE) {
                hasNewLang = true;
                System.assertEquals(curLang.get('code'), CODE, 'Language short title of test language is incorrect.');
                System.assertEquals(curLang.get('domain'), DOMAIN, 'Language domain of test language is incorrect.');
                System.assertEquals(curLang.get('title'), LANG_TITLE, 'Language title of test language is incorrect.');
                System.assertEquals(
                    curLang.get('shortTitle'),
                    LANG,
                    'Language short title of test language is incorrect.'
                );
                System.assertEquals(curLang.get('language'), COUNTRY, 'Language code of test language is incorrect.');
                System.assertEquals(
                    curLang.get('isCommunity'),
                    IS_COMMUNITY,
                    'Language attribute "isCommunity" of test language is incorrect.'
                );
                break;
            }
        }
        System.assert(hasNewLang, 'Languages from Custom Settings was updated incorrectly.');
    }
}