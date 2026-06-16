@isTest
private with sharing class Test_SupportCommunityCaseList {
    private static final String CSR_SEARCHPART = 'test Subject';
    private static final String CSR_TOO_SHORT_SEARCHPART = 'te';
    private static final Boolean CSR_DIRECTION = true;
    private static final Integer CSR_LIMIT = 50;
    private static final Integer CSR_OFFSET = 0;
    private static final String CSR_MYCASES_LISTVIEW = 'myCases';
    private static final String CSR_ORDER_BY = 'dateCreated';
    private static final String CSR_SEARCH_BY_SUBJECT = 'subject';

    private static final String ADMIN_CONTACT_FIRST_NAME = 'Admin';
    private static final String ADMIN_CONTACT_LAST_NAME = 'McToast';
    private static final String ADMIN_CONTACT_EMAIL = 'admin@tes.to';
    private static final String ADMIN_CONTACT_PHONE = '77777777';
    private static final Decimal ADMIN_CONTACT_PHONE_EXT = 777;

    private static final String ADMIN_CONTACT_LAST_NAME_ALT = 'McToast Two';

    private static final String GUEST_USER_PROFILE_NAME = 'RC Guest User';
    private static final String ADMIN_USER_PROFILE_NAME = 'RC Admin User';
    private static final String CUSTOM_PERMISSION_NAME = 'Can_see_community_billing_info';

    private static final String ADMIN_USER_USERNAME = 'RC_SupportCommunityNewCaseTestUserAdmin@nvx.zn';
    private static final String ADMIN_USER_EMAIL = 'testerinoadmin@rc.com';
    private static final String ADMIN_USER_FIRST_NAME = 'Admeeeno';
    private static final String ADMIN_USER_LAST_NAME = 'McAdmin';
    private static final String ADMIN_USER_USERNAME_ALT = 'RC_SupportCommunityNewCaseTestUserAdminTwo@nvx.zn';
    private static final String ADMIN_USER_LAST_NAME_ALT = 'McAdmin Two';

    private static final String USER_USERNAME = 'RC_SupportCommunityCaseListTestUser@rc.com';
    private static final String USER_EMAIL = 'useremail@rc.com';
    private static final String USER_FIRST_NAME = 'firstname';
    private static final String USER_LAST_NAME = 'lastname';
    private static final String USER_LANGUAGE = 'en_US';

    private static final String CONTACT_FIRST_NAME = USER_FIRST_NAME;
    private static final String CONTACT_LAST_NAME = USER_LAST_NAME;
    private static final String CONTACT_EMAIL = USER_EMAIL;
    private static final String CONTACT_PHONE = '77777777';
    private static final Decimal CONTACT_PHONE_EXT = 777;

    private static final String CASE_INFO_SUBJECT = 'test Subject';
    private static final String CASE_INFO_DESCRIPTION = 'test Description';
    private static final String CASE_INFO_SELECTED_PRODUCT = 'test product one';
    private static final String CASE_INFO_SELECTED_PRODUCT2 = 'test product two';
    private static final String CASE_INFO_SELECTED_PRODUCT3 = 'test product three';
    private static final String CASE_INFO_SEVERITY_LEVEL = 'Level 4 - Medium';
    private static final Datetime CASE_INFO_CREATED_DATE = Datetime.newInstanceGmt(2007, 1, 1);

    private static SCWrappers.CaseSearchRequest getCaseSearchRequest(String searchPart, String listView,
        String orderByField, String searchByField, Integer searchLimit, Integer offset, Boolean count) {
        SCWrappers.CaseSearchRequest searchRequest = new SCWrappers.CaseSearchRequest();
        searchRequest.searchPart = searchPart;
        searchRequest.descending = CSR_DIRECTION;
        searchRequest.orderByField = orderByField;
        searchRequest.searchLimit = searchLimit;
        searchRequest.offset = offset;
        searchRequest.listView = listView;
        searchRequest.count = count;
        searchRequest.searchByField = searchByField;
        return searchRequest;
    }

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
                    .selectFields(new List<String>{'ContactId', 'AccountId'})
                    .executeQuery()
                    .get(0);
            }
            return adminTestUser;
        }
        private set;
    }

    private static Id createCase() {

        Case newCase;
        newCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1,
                    Case.Subject =>
                        (String) new ValueProvider.UniqueFixedLengthStringProvider(CASE_INFO_SUBJECT, 30).getValue(),
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

    @TestSetup
    static void testSetup() {
        Profile guestProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{GUEST_USER_PROFILE_NAME})
            .executeQuery()
            .get(0);

        Profile adminProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{ADMIN_USER_PROFILE_NAME})
            .executeQuery()
            .get(0);

        List<Account> portalAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecords();

        List<Contact> portalContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_FIRST_NAME, ADMIN_CONTACT_FIRST_NAME}),
                    Contact.LastName => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_LAST_NAME, ADMIN_CONTACT_LAST_NAME, ADMIN_CONTACT_LAST_NAME_ALT}),
                    Contact.Email => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_EMAIL, ADMIN_CONTACT_EMAIL}),
                    Contact.Phone => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_PHONE, ADMIN_CONTACT_PHONE}),
                    Contact.Phone_Ext__c => ValueProviderBuilder.provideList(
                        new List<Decimal>{CONTACT_PHONE_EXT, ADMIN_CONTACT_PHONE_EXT}),
                    Contact.AccountId => ValueProviderBuilder.provideList(
                        new List<String>{portalAccounts[0].Id, portalAccounts[0].Id, portalAccounts[1].Id})
                }
            )
            .create()
            .getRecords();

        List<User> users = new SObjectBuilder(User.SObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    User.ContactId => ValueProviderBuilder.provideList(
                        new List<String>{portalContacts[0].Id, portalContacts[1].Id, portalContacts[2].Id}),
                    User.LastName => ValueProviderBuilder.provideList(
                        new List<String>{USER_LAST_NAME, ADMIN_USER_LAST_NAME}),
                    User.FirstName => ValueProviderBuilder.provideList(
                        new List<String>{USER_FIRST_NAME, ADMIN_USER_FIRST_NAME}),
                    User.CommunityNickname => ValueProviderBuilder.provideList(
                        new List<String>{USER_LAST_NAME, ADMIN_USER_LAST_NAME, ADMIN_USER_LAST_NAME_ALT}),
                    User.Email => ValueProviderBuilder.provideList(
                        new List<String>{USER_EMAIL, ADMIN_USER_EMAIL}),
                    User.Username => ValueProviderBuilder.provideList(
                        new List<String>{USER_USERNAME, ADMIN_USER_USERNAME, ADMIN_USER_USERNAME_ALT}),
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
        for(SetupEntityAccess sea : seas){
            if(sea.ParentId.getSObjectType() == PermissionSet.SObjectType){
                commAdminPermSetId = sea.ParentId;
                break;
            }
        }

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

        System.runAs(guestTestUser) {
            new SObjectBuilder(Case.SObjectType)
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
                .create();
        }
    }

    @isTest
    private static void testGetCases() {
        SCWrappers.CaseSearchRequest request = getCaseSearchRequest(
            CSR_SEARCHPART, CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, true
        );
        SCWrappers.CaseListView result;
        List<Case> createdCases = new CaseSelector()
            .selectCasesDefaultDetailed(new List<Object>())
            .executeQuery();

        System.runAs(guestTestUser) {
            Test.startTest();
            result = (SCWrappers.CaseListView) (SupportCommunityCaseList.getCases(
                JSON.serialize(request)).data.get(SupportCommunityCaseList.LABEL_CASES)
            );
        Test.stopTest();
        }

        System.assert(result != null, 'Case not found');
        System.assertEquals(
            createdCases.size(),
            result.totalCases,
            'There should be only ' + createdCases.size() + ' case(s)'
        );
        System.assertEquals(
            createdCases.get(0).Subject,
            result.caseDetails.get(0).subject,
            'Case should be shown to it\'s owner'
        );
    }

    @isTest
    private static void testGetCases_shouldFailNoListView() {
        SCWrappers.CaseListView result;
        SCWrappers.CaseSearchRequest reqToAccListView = getCaseSearchRequest(
            CSR_SEARCHPART, null, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, null, null, false
        );
        try {
            System.runAs(guestTestUser) {
                result = (SCWrappers.CaseListView) (SupportCommunityCaseList.getCases(
                    JSON.serialize(reqToAccListView)).data.get(SupportCommunityCaseList.LABEL_CASES)
                );
            }
        } catch (Exception ex) {
            System.assertEquals(
                Label.SC_Case_Management_no_listview,
                ex.getMessage(),
                'Wrong exception message on search fail'
            );
        }
    }

    @isTest
    private static void testGetCases_shouldFailEmptySearch() {
        SCWrappers.CaseListView result;
        SCWrappers.CaseSearchRequest requestWithEmptySearch = getCaseSearchRequest(
            null, CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, null, null, false
        );
        try {
            System.runAs(guestTestUser) {
                result = (SCWrappers.CaseListView) (SupportCommunityCaseList.getCases(
                    JSON.serialize(requestWithEmptySearch)).data.get(SupportCommunityCaseList.LABEL_CASES)
                );
            }
        } catch (Exception ex) {
            System.assertEquals(
                String.format(
                    Label.SC_Case_Management_search_too_short,
                    new List<String>{String.valueOf(SCCaseService.MIN_SEARCH_LENGTH)}),
                ex.getMessage(),
                'Wrong exception message on search fail'
            );
        }
    }

    @isTest
    private static void testGetCases_shouldFailTooShortSearch() {
        SCWrappers.CaseListView result;
        SCWrappers.CaseSearchRequest requestWithEmptySearch = getCaseSearchRequest(
            CSR_TOO_SHORT_SEARCHPART, CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, null, null, false
        );
        try {
            System.runAs(guestTestUser) {
                result = (SCWrappers.CaseListView) (SupportCommunityCaseList.getCases(
                    JSON.serialize(requestWithEmptySearch)).data.get(SupportCommunityCaseList.LABEL_CASES)
                );
            }
        } catch (Exception ex) {
            System.assertEquals(
                String.format(
                    Label.SC_Case_Management_search_too_short,
                    new List<String>{String.valueOf(SCCaseService.MIN_SEARCH_LENGTH)}),
                ex.getMessage(),
                'Wrong exception message on search fail'
            );
        }
    }

    @isTest
    private static void testDownloadAsCSV() {
        SCWrappers.CaseSearchRequest request = getCaseSearchRequest(
            CSR_SEARCHPART, CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, false
        );
        List<Case> createdCases = new CaseSelector()
            .selectCasesDefaultDetailed(new List<Object>())
            .selectFields(SCCaseService.FIELD_TO_RETRIEVE)
            .executeQuery();

        String expectedString = ''
            + 'CaseNumber,Subject,CreatedDate,Status,Contact.Name\n'
            + createdCases.get(0).CaseNumber + ',' + createdCases.get(0).Subject + ','
            + createdCases.get(0).CreatedDate + ',' + createdCases.get(0).Status + ','
            + USER_FIRST_NAME + ' ' + USER_LAST_NAME + '\n';

        String result;
        System.runAs(guestTestUser) {
            Test.startTest();
                result = (String) (SupportCommunityCaseList.downloadAsCSV(
                    JSON.serialize(request)).data.get(SupportCommunityCaseList.LABEL_CSV)
                );
            Test.stopTest();
        }
        System.assert(result != null, 'CSV did not downloaded');
        System.assertEquals(expectedString, result, 'Strings should be equal');
    }

    @isTest
    private static void testDownloadAsCSV_shouldFailNoListView() {
        SCWrappers.CaseListView result;
        SCWrappers.CaseSearchRequest reqToAccListView = getCaseSearchRequest(
            CSR_SEARCHPART, null, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, null, null, false
        );
        try {
            System.runAs(guestTestUser) {
                result = (SCWrappers.CaseListView) (SupportCommunityCaseList.downloadAsCSV(
                    JSON.serialize(reqToAccListView)).data.get(SupportCommunityCaseList.LABEL_CASES)
                );
            }
        } catch (Exception ex) {
            System.assertEquals(
                Label.SC_Case_Management_no_listview,
                ex.getMessage(),
                'Wrong exception message on search fail'
            );
        }
    }

    @isTest
    private static void testIsCurrentUserSCAdmin_whenCurrentUserIsGuest() {
        System.runAs(guestTestUser) {
            Response res = new Response();
            res = SupportCommunityCaseList.isCurrentUserSCAdmin();
            System.assertEquals(false, res.data.get(SupportCommunityCaseList.LABEL_ISADMIN));
        }
    }

    @isTest
    private static void testIsCurrentUserSCAdmin_whenCurrentUserIsAdmin() {
        System.runAs(adminTestUser) {
            Response res = new Response();
            res = SupportCommunityCaseList.isCurrentUserSCAdmin();
            System.assertEquals(true, res.data.get(SupportCommunityCaseList.LABEL_ISADMIN));
        }
    }
}