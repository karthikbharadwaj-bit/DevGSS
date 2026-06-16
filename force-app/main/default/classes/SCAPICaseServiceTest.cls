@isTest
private class SCAPICaseServiceTest {

    private static final String CASE_INFO_SUBJECT = 'test Subject';
    private static final String CASE_INFO_DESCRIPTION = 'test Description';
    private static final String CASE_INFO_SELECTED_PRODUCT = 'test product one';
    private static final String CASE_INFO_SELECTED_PRODUCT2 = 'test product two';
    private static final String CASE_INFO_SELECTED_PRODUCT3 = 'test product three';
    private static final String CASE_INFO_SEVERITY_LEVEL = 'Level 4 - Medium';
    private static final Datetime CASE_INFO_CREATED_DATE = Datetime.newInstanceGmt(2007, 1, 1);

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

    private static final String AGENT_USER_USERNAME = 'RC_SupportCommunityNewCaseTestUserAgent@nvx.zn';
    private static final String AGENT_USER_EMAIL = 'testerinoagent@rc.com';
    private static final String AGENT_USER_FIRST_NAME = 'Agent0';
    private static final String AGENT_USER_LAST_NAME = 'McAgent';
    private static final String AGENT_USER_LANGUAGE = 'en_US';

    private static final String ADMIN_USER_USERNAME_ALT = 'RC_SupportCommunityNewCaseTestUserAdminTwo@nvx.zn';
    private static final String ADMIN_USER_LAST_NAME_ALT = 'McAdmin Two';

    private static final String ADMIN_CONTACT_FIRST_NAME = 'Admin';
    private static final String ADMIN_CONTACT_LAST_NAME = 'McToast';
    private static final String ADMIN_CONTACT_EMAIL = 'admin@tes.to';
    private static final String ADMIN_CONTACT_PHONE = '77777777';
    private static final Decimal ADMIN_CONTACT_PHONE_EXT = 777;

    private static final String ADMIN_CONTACT_LAST_NAME_ALT = 'McToast Two';

    private static final String COMMENT_BODY = 'Commento testomento';
    private static final String TOO_BIG_COMMENT_BODY =
        (String) new ValueProvider.UniqueFixedLengthStringProvider(4001).getValue();

    private static final String ATTACHMENT_NAME = 'Attachmento testomento';
    private static final String ATTACHMENT_BODY = 'This is a 30 characters string';
    private static final Integer ATTACHMENT_LENGTH = 30;

    private static final String GUEST_USER_PROFILE_NAME = 'RC Guest User';
    private static final String ADMIN_USER_PROFILE_NAME = 'RC Admin User';
    private static final String AGENT_USER_PROFILE_NAME = 'Support T2';
    private static final String CUSTOM_PERMISSION_NAME = 'Can_see_community_billing_info';

    private static final Boolean CSR_DESCENDING = false;
    private static final Integer CSR_LIMIT = 50;
    private static final Integer CSR_WRONG_LIMIT = 77;
    private static final Integer CSR_OFFSET = 0;
    private static final String CSR_ORDER_BY = 'dateCreated';
    private static final String CSR_WRONG_ORDER_BY = 'wrongField';
    private static final String CSR_SEARCH_BY_SUBJECT = 'subject';
    private static final String CSR_SEARCH_BY_CASE_NUMBER = CaseHelper.CASE_NUMBER;
    private static final String CSR_SEARCH_BY_CONTACT = 'contact';
    private static final String CSR_WRONG_SEARCH_BY = 'wrongField';
    private static final String CSR_MYCASES_LISTVIEW = 'myCases';
    private static final String CSR_ACCOUNTCASES_LISTVIEW = 'accountCases';
    private static final String CSR_SEARCHPART = 'Subject';
    private static final String CSR_TOO_SHORT_SEARCHPART = 'te';
    private static final String CSR_TOO_LONG_SEARCHPART =
        (String) new ValueProvider.UniqueFixedLengthStringProvider(256).getValue();

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

    private static User anotherAccRCAdminUser {
        get {
            if (anotherAccRCAdminUser == null) {
                anotherAccRCAdminUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{ADMIN_USER_USERNAME_ALT}})
                    .selectFields(new List<String>{'ContactId', 'AccountId', 'Contact.AccountId'})
                    .executeQuery()
                    .get(0);
            }
            return anotherAccRCAdminUser;
        }
        private set;
    }

    private static Id createCaseAsUser(User userToRunTestAs) {
        Id caseId;
        System.runAs(userToRunTestAs) {
            caseId = createCase();
        }
        return caseId;
    }

    private static Id createCase() {

        Triggers.switchOff();
        Case newCase;
            newCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
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
        Triggers.switchOn();
        return newCase.Id;
    }

    private static SCWrappers.CaseSearchRequest getCaseSearchRequest(String searchPart, String listView,
        String orderByField, String searchByField, Integer searchLimit, Integer offset, Boolean count) {
        SCWrappers.CaseSearchRequest searchRequest = new SCWrappers.CaseSearchRequest();
        searchRequest.searchPart = searchPart;
        searchRequest.descending = CSR_DESCENDING;
        searchRequest.orderByField = orderByField;
        searchRequest.searchLimit = searchLimit;
        searchRequest.offset = offset;
        searchRequest.listView = listView;
        searchRequest.count = count;
        searchRequest.searchByField = searchByField;
        return searchRequest;
    }

    private static User agentTestUser {
        get {
            if (agentTestUser == null) {
                Profile agentProfile = (Profile) new ProfileSelector()
                    .selectProfileByName(new List<String>{AGENT_USER_PROFILE_NAME})
                    .executeQuery()
                    .get(0);
                agentTestUser = (User) new SObjectBuilder(User.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            User.LastName => AGENT_USER_LAST_NAME,
                            User.FirstName => AGENT_USER_FIRST_NAME,
                            User.CommunityNickname => AGENT_USER_LAST_NAME,
                            User.Email => AGENT_USER_EMAIL,
                            User.Username => AGENT_USER_USERNAME,
                            User.LanguageLocaleKey => USER_LANGUAGE,
                            User.ProfileId => agentProfile.Id
                        }
                    )
                    .create()
                    .getRecord();
            }
            return agentTestUser;
        }
        private set;
    }

    private static List<Attachment> createAttachments(Id caseId) {

        return (List<Attachment>) new SObjectBuilder(Attachment.SObjectType)
            .quantity(2)
            .setField(Attachment.ParentId, caseId)
            .setField(Attachment.Name, ValueProviderBuilder.provideUniqueString(ATTACHMENT_NAME))
            .setField(Attachment.Body, Blob.valueOf(ATTACHMENT_BODY))
            .create()
            .getRecords();
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
        Triggers.switchOn();
    }

    @isTest
    static void testRetrieveCaseDetail() {

        SCWrappers.CaseDetail caseDetail;

        Id newCaseId = createCaseAsUser(guestTestUser);

        System.runAs(guestTestUser) {

            Test.setCreatedDate(newCaseId, CASE_INFO_CREATED_DATE);

            List<CaseComment> comments = (List<CaseComment>) new SObjectBuilder(CaseComment.SObjectType)
                .quantity(2)
                .setField(CaseComment.ParentId, newCaseId)
                .setField(CaseComment.IsPublished, true)
                .setField(CaseComment.CommentBody, COMMENT_BODY)
                .create()
                .getRecords();

            Test.startTest();
            caseDetail = SCAPICaseService.retrieveCaseDetail(newCaseId);
            Test.stopTest();

        }

        System.assert(caseDetail != null, 'Case detail not received');
        System.assert(caseDetail.subject.contains(CASE_INFO_SUBJECT), 'Incorrent case subject');
        System.assertEquals('New', caseDetail.status, 'Incorrent case status');
        System.assertEquals(CASE_INFO_DESCRIPTION, caseDetail.description, 'Incorrent case description');
        System.assertEquals(CASE_INFO_SEVERITY_LEVEL, caseDetail.severityLevel, 'Incorrent case severityLevel');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT, caseDetail.selectedProduct, 'Incorrent case selectedProduct');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT2, caseDetail.selectedProduct2, 'Incorrent case selectedProduct2');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT3, caseDetail.selectedProduct3, 'Incorrent case selectedProduct3');
        System.assertEquals(false, caseDetail.isClosed, 'Incorrent case isClosed flag');
        System.assertEquals(5, caseDetail.fileSizeLimit, 'Incorrent case file size limit');
        System.assertEquals(USER_FIRST_NAME + ' ' + USER_LAST_NAME, caseDetail.creatorName, 'Incorrent case creator');
        System.assertEquals(
            CASE_INFO_CREATED_DATE.format('h:mm a z, MM/dd/yyyy', 'America/Los_Angeles'),
            caseDetail.createdDate,
            'Incorrent case created date'
        );
    }

    @isTest
    static void testRetrieveCaseDetail_shouldFailNullId() {
        SCWrappers.CaseDetail caseDetail;
        try {
            caseDetail = SCAPICaseService.retrieveCaseDetail(null);
            System.assert(false, 'Exception not thrown when trying retrieve cases without case id');
        } catch (Exception ex) {
            System.assertEquals(
                Label.SC_Case_Detail_invalid_case_id,
                ex.getMessage(),
                'Wrong exception message on search fail'
            );
        }
    }

    @isTest
    static void testRetrieveCaseDetail_shouldFailInvalidId() {
        SCWrappers.CaseDetail caseDetail;
        try {
            caseDetail = SCAPICaseService.retrieveCaseDetail('invalidId');
            System.assert(false, 'Exception not thrown when trying retrieve cases with invalid case id');
        } catch (Exception ex) {
            System.assertEquals(
                Label.SC_Case_Detail_invalid_case_id,
                ex.getMessage(),
                'Wrong exception message on search fail'
            );
        }
    }

    @isTest
    private static void testGetCases_asAdmin_ShouldSeeGuestCases() {
        Id guestCaseId = createCaseAsUser(guestTestUser);
        Id adminCaseId = createCaseAsUser(adminTestUser);

        SCWrappers.CaseSearchRequest searchRequest = getCaseSearchRequest(
            CSR_SEARCHPART, CSR_ACCOUNTCASES_LISTVIEW, null, CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, true
        );

        System.runAs(adminTestUser) {
            SCWrappers.CaseListView foundCases = SCAPICaseService.getCasesForCaseListView(searchRequest);
            System.assert(
                foundCases.caseDetails.size() == 2,
                'Admin user should see guest user\'s cases.'
            );
            System.assert(
                foundCases.totalCases == 2,
                'Admin user should see his and guest user\'s cases.'
            );
        }
    }

    @isTest
    private static void testGetCases_asAnotherAccAdmin_ShouldNotSeeGuestCases() {
        Id guestCaseId = createCaseAsUser(guestTestUser);

        SCWrappers.CaseSearchRequest searchRequest = getCaseSearchRequest(
            CSR_SEARCHPART, CSR_MYCASES_LISTVIEW, null, CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, true
        );

        System.runAs(anotherAccRCAdminUser) {
            SCWrappers.CaseListView foundCases = SCAPICaseService.getCasesForCaseListView(searchRequest);
            System.assert(
                foundCases.caseDetails.size() == 0,
                'Another account admin user should not see guest user\'s cases.'
            );
            System.assert(
                foundCases.totalCases == 0,
                'Another account admin user should not see guest user\'s cases.'
            );
        }
    }

    @isTest
    private static void testGetCases_asGuest_ShouldNotSeeAdminCases() {
        Id guestCaseId = createCaseAsUser(guestTestUser);
        Id adminCaseId = createCaseAsUser(adminTestUser);

        SCWrappers.CaseSearchRequest searchRequest = getCaseSearchRequest(
            CSR_SEARCHPART, CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, true
        );

        System.runAs(guestTestUser) {
            List<Case> createdCases = new CaseSelector()
                .selectCasesDefaultDetailed(new List<Object>{CaseHelper.getAllowedRecordTypesForContact(SCUserService.currentUser.Contact), SCUserService.currentUser.ContactId})
                .selectFields(SCAPICaseService.FIELD_TO_RETRIEVE)
                .setCondition(SCAPICaseService.GUEST_CONDITION)
                .executeQuery();

            SCWrappers.CaseListView foundCases = SCAPICaseService.getCasesForCaseListView(searchRequest);
            System.assertEquals(1, foundCases.caseDetails.size(), 'User can only see cases created by him');
            System.assertEquals(
                createdCases.size(),
                foundCases.totalCases,
                'There should be only ' + createdCases.size() + ' case(s)'
            );
            System.assertEquals(
                createdCases.get(0).CaseNumber,
                foundCases.caseDetails.get(0).caseNumber,
                'Case should be shown to it\'s owner'
            );
        }
    }

    @isTest
    private static void testGetCases_SearchBySubject() {
        Id guestCaseId = createCaseAsUser(guestTestUser);

        System.runAs(guestTestUser) {
            SCWrappers.CaseSearchRequest searchRequestBySubject = getCaseSearchRequest(CSR_SEARCHPART,
                CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, false);
            SCWrappers.CaseListView foundCases = SCAPICaseService.getCasesForCaseListView(searchRequestBySubject);
            System.assertEquals(1, foundCases.caseDetails.size(), 'There should be one case');
            System.assertEquals(CASE_INFO_SUBJECT, foundCases.caseDetails.get(0).subject, 'Subjects should be equal');

            SCWrappers.CaseSearchRequest searchRequestByCaseNumber = getCaseSearchRequest(CSR_SEARCHPART,
                CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_CASE_NUMBER, CSR_LIMIT, CSR_OFFSET, false);
            foundCases = SCAPICaseService.getCasesForCaseListView(searchRequestByCaseNumber);
            System.assertEquals(0, foundCases.caseDetails.size(), 'There should not be any cases');

            SCWrappers.CaseSearchRequest searchRequestByContact = getCaseSearchRequest(CSR_SEARCHPART,
                CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_CONTACT, CSR_LIMIT, CSR_OFFSET, false);
            foundCases = SCAPICaseService.getCasesForCaseListView(searchRequestByContact);
            System.assertEquals(0, foundCases.caseDetails.size(), 'There should not be any cases');
        }
    }

    @isTest
    private static void testGetCases_SearchByCaseNumber() {
        Id guestCaseId = createCaseAsUser(guestTestUser);

        System.runAs(guestTestUser) {
            List<Case> createdCases = new CaseSelector()
                .selectCasesDefaultDetailed(new List<Object>{CaseHelper.getAllowedRecordTypesForContact(SCUserService.currentUser.Contact), SCUserService.currentUser.ContactId})
                .selectFields(SCAPICaseService.FIELD_TO_RETRIEVE)
                .setCondition(SCAPICaseService.GUEST_CONDITION)
                .executeQuery();
            String caseNumber = createdCases.get(0).CaseNumber;

            SCWrappers.CaseSearchRequest searchRequestByCaseNumber = getCaseSearchRequest(caseNumber,
                CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_CASE_NUMBER, CSR_LIMIT, CSR_OFFSET, false);
            SCWrappers.CaseListView foundCases = SCAPICaseService.getCasesForCaseListView(searchRequestByCaseNumber);
            System.assertEquals(1, foundCases.caseDetails.size(), 'There should be one case');

            SCWrappers.CaseSearchRequest searchRequestBySubject = getCaseSearchRequest(caseNumber,
                CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, false);
            foundCases = SCAPICaseService.getCasesForCaseListView(searchRequestBySubject);
            System.assertEquals(0, foundCases.caseDetails.size(), 'There should not be any cases');

            SCWrappers.CaseSearchRequest searchRequestByContact = getCaseSearchRequest(caseNumber,
                CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_CONTACT, CSR_LIMIT, CSR_OFFSET, false);
            foundCases = SCAPICaseService.getCasesForCaseListView(searchRequestByContact);
            System.assertEquals(0, foundCases.caseDetails.size(), 'There should not be any cases');
        }
    }

    @isTest
    private static void testGetCases_SearchByContact() {
        Id guestCaseId = createCaseAsUser(guestTestUser);

        System.runAs(guestTestUser) {
            List<Case> createdCases = new CaseSelector()
                .selectCasesDefaultDetailed(new List<Object>{CaseHelper.getAllowedRecordTypesForContact(SCUserService.currentUser.Contact), SCUserService.currentUser.ContactId})
                .selectFields(SCAPICaseService.FIELD_TO_RETRIEVE)
                .setCondition(SCAPICaseService.GUEST_CONDITION)
                .executeQuery();
            String contactName = createdCases.get(0).Contact.Name;

            SCWrappers.CaseSearchRequest searchRequestByContact = getCaseSearchRequest(contactName,
                CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_CONTACT, CSR_LIMIT, CSR_OFFSET, false);
            SCWrappers.CaseListView  foundCases = SCAPICaseService.getCasesForCaseListView(searchRequestByContact);
            System.assertEquals(1, foundCases.caseDetails.size(), 'There should be one case');

            SCWrappers.CaseSearchRequest searchRequestByCaseNumber = getCaseSearchRequest(contactName,
                CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_CASE_NUMBER, CSR_LIMIT, CSR_OFFSET, false);
            foundCases = SCAPICaseService.getCasesForCaseListView(searchRequestByCaseNumber);
            System.assertEquals(0, foundCases.caseDetails.size(), 'There should not be any cases');

            SCWrappers.CaseSearchRequest searchRequestBySubject = getCaseSearchRequest(contactName,
                CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, false);
            foundCases = SCAPICaseService.getCasesForCaseListView(searchRequestBySubject);
            System.assertEquals(0, foundCases.caseDetails.size(), 'There should not be any cases');
        }
    }

    @isTest
    private static void testGetCases_shouldFailNoPermissionToAccessViewList() {
        SCWrappers.CaseSearchRequest reqToAccListView = getCaseSearchRequest(
            CSR_SEARCHPART, CSR_ACCOUNTCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, false
        );
        System.runAs(guestTestUser) {
            try {
                SCAPICaseService.getCasesForCaseListView(reqToAccListView);
                System.assert(false, 'Exception not thrown when there user have no permissions to access list view');
            } catch (Exception ex) {
                System.assertEquals(
                    Label.SC_Case_Management_no_permissions_to_access_list_view,
                    ex.getMessage(),
                    'Wrong exception message on search fail'
                );
            }
        }
    }

    @isTest
    private static void testGetCases_shouldFailTooShortSearch() {
        SCWrappers.CaseSearchRequest requestWithShortSearch = getCaseSearchRequest(
            CSR_TOO_SHORT_SEARCHPART, CSR_MYCASES_LISTVIEW, CSR_ORDER_BY,
            CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, false
        );
        try {
            SCAPICaseService.getCasesForCaseListView(requestWithShortSearch);
            System.assert(false, 'Exception not thrown when trying to search with less then 3 symbols');
        } catch (Exception ex) {
            System.assertEquals(
                String.format(
                    Label.SC_Case_Management_search_too_short,
                    new List<String>{String.valueOf(SCAPICaseService.MIN_SEARCH_LENGTH)}),
                ex.getMessage(),
                'Wrong exception message on search fail'
            );
        }
    }

    @isTest
    private static void testGetCases_shouldFailTooLongSearch() {
        SCWrappers.CaseSearchRequest requestWithLongSearch = getCaseSearchRequest(
            CSR_TOO_LONG_SEARCHPART, CSR_MYCASES_LISTVIEW, CSR_ORDER_BY,
            CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, false
        );
        try {
            SCAPICaseService.getCasesForCaseListView(requestWithLongSearch);
            System.assert(false, 'Exception not thrown when trying to search with more then 255 symbols');
        } catch (Exception ex) {
            System.assertEquals(
                String.format(
                    Label.SC_Case_Management_search_too_long,
                    new List<String>{String.valueOf(SCAPICaseService.MAX_SEARCH_LENGTH)}),
                ex.getMessage(),
                'Wrong exception message on search fail'
            );
        }
    }

    @isTest
    private static void testGetCases_shouldFailWrongOrderByField() {
        SCWrappers.CaseSearchRequest requestWithWrongOrderByField = getCaseSearchRequest(
            CSR_SEARCHPART, CSR_MYCASES_LISTVIEW, CSR_WRONG_ORDER_BY,
            CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, false
        );
        System.runAs(guestTestUser) {
            try {
                SCAPICaseService.getCasesForCaseListView(requestWithWrongOrderByField);
                System.assert(false, 'Exception not thrown when trying to search with wrong order by field');
            } catch (Exception ex) {
                System.assertEquals(
                    Label.SC_Case_Management_wrong_order_by_value,
                    ex.getMessage(),
                    'Wrong exception message on search fail'
                );
            }
        }
    }

    @isTest
    private static void testGetCases_shouldFailWrongSearchByField() {
        SCWrappers.CaseSearchRequest requestWithWrongSearchByField = getCaseSearchRequest(
            CSR_SEARCHPART, CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_WRONG_SEARCH_BY, CSR_LIMIT, CSR_OFFSET, true
        );
        System.runAs(guestTestUser) {
            try {
                SCAPICaseService.getCasesForCaseListView(requestWithWrongSearchByField);
                System.assert(false, 'Exception not thrown when trying to search with wrong search by field');
            } catch (Exception ex) {
                System.assertEquals(
                    Label.SC_Case_Management_wrong_search_by_value,
                    ex.getMessage(),
                    'Wrong exception message on search fail'
                );
            }
        }
    }

    @isTest
    private static void testGetCases_shouldFailWrongLimitValue() {
        SCWrappers.CaseSearchRequest requestWithWrongLimit = getCaseSearchRequest(
            CSR_SEARCHPART, CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT,
            CSR_WRONG_LIMIT, CSR_OFFSET, false
        );
        System.runAs(guestTestUser) {
            try {
                SCAPICaseService.getCasesForCaseListView(requestWithWrongLimit);
                System.assert(false, 'Exception not thrown when trying to search with wrong limit value');
            } catch (Exception ex) {
                System.assertEquals(
                    Label.SC_Case_Management_wrong_limit_value,
                    ex.getMessage(),
                    'Wrong exception message on search fail'
                );
            }
        }
    }

    @isTest
    private static void testGetCasesForCSV() {

        System.runAs(guestTestUser) {
            Id caseId = createCase();
            SCWrappers.CaseSearchRequest searchRequest = getCaseSearchRequest(
                CSR_SEARCHPART, CSR_MYCASES_LISTVIEW, CSR_ORDER_BY, CSR_SEARCH_BY_SUBJECT, CSR_LIMIT, CSR_OFFSET, false
            );
            List<Case> foundCases = SCAPICaseService.getCasesForCSV(searchRequest);
            System.assertEquals(1, foundCases.size(), 'Case should be shown to it\'s owner');
            System.assertEquals(CASE_INFO_SUBJECT, foundCases.get(0).Subject, 'Wrong case was found');
        }
    }

    @isTest
    private static void testPostComment_asCaseCreator() {

        Id newCaseId = createCaseAsUser(guestTestUser);

        System.runAs(guestTestUser) {

            Test.startTest();
            SCWrappers.CommentWrapper comment = SCAPICaseService.addComment(newCaseId, COMMENT_BODY);
            Test.stopTest();

            System.assert(comment != null, 'Comment not received');
            System.assertEquals(true, comment.isCurrentUser, 'Incorrent isCurrentUser flag');
            System.assertEquals(true, comment.isCaseCreator, 'Incorrent isCaseCreator flag');
            System.assertEquals(COMMENT_BODY, comment.body, 'Incorrent comment body');
            System.assert(comment.avatarUrl.contains('005/F'), 'Incorrent avatar url');
            System.assertEquals(USER_FIRST_NAME + ' ' + USER_LAST_NAME, comment.authorName, 'Incorrent author name');
        }
    }

    @isTest
    static void testRetrieveCaseDetail_commentsByInternalUser_shouldBeVisible() {

        SCWrappers.CaseDetail caseDetail;
        Id newCaseId;
        Id newCaseId1;
        System.runAs(guestTestUser) {
            newCaseId = createCase();
            List<CaseComment> comments = (List<CaseComment>) new SObjectBuilder(CaseComment.SObjectType)
                .quantity(2)
                .setField(CaseComment.ParentId, newCaseId)
                .setField(CaseComment.IsPublished, true)
                .setField(CaseComment.CommentBody, COMMENT_BODY)
                .create()
                .getRecords();

            Test.setCreatedDate(newCaseId, CASE_INFO_CREATED_DATE);
        }

        System.runAs(agentTestUser) {
         newCaseId1 = createCase();
            List<CaseComment> comments = (List<CaseComment>) new SObjectBuilder(CaseComment.SObjectType)
                .quantity(2)
                .setField(CaseComment.ParentId, newCaseId1)
                .setField(CaseComment.IsPublished, true)
                .setField(CaseComment.CommentBody, COMMENT_BODY)
                .create()
                .getRecords();

            Test.setCreatedDate(newCaseId1, CASE_INFO_CREATED_DATE);
        }

        Test.startTest();
        System.runAs(adminTestUser) {
            caseDetail = SCAPICaseService.retrieveCaseDetail(newCaseId);
        }
        Test.stopTest();

        System.assert(caseDetail != null, 'Case detail not received');
        System.assert(!caseDetail.comments.isEmpty(), 'No comments returned');
        System.assertEquals(2, caseDetail.comments.size(), 'Incorrent number of comments');
    }

    @isTest
    private static void testPostComment_asGuest_shouldFailTooBigComment() {

        Id newCaseId = createCaseAsUser(guestTestUser);

        Test.startTest();
        System.runAs(guestTestUser) {
            try {
                SCAPICaseService.addComment(newCaseId, TOO_BIG_COMMENT_BODY);
                System.assert(false, 'Exception not thrown when trying to post too big comment');
            } catch (Exception ex) {
                System.assertEquals(
                    String.format(
                        Label.SC_Case_Detail_too_large_comment,
                        new List<String>{String.valueOf(SCAPICaseService.MAXIMUM_COMMENT_SIZE)}),
                    ex.getMessage(),
                    'Wrong exception message on search fail'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    private static void testPostComment_asRCAdminFromAnotherAccount_shouldFailHaveNoPermission() {

        Id newCaseId = createCase();

        System.runAs(anotherAccRCAdminUser) {

            try {
                SCAPICaseService.addComment(newCaseId, COMMENT_BODY);
                System.assert(false, 'Exception not thrown when trying to post comment as unrelated user');
            } catch (Exception ex) {
                System.assertEquals(
                    Label.SC_Case_Detail_no_case_or_no_permission,
                    ex.getMessage(),
                    'Wrong exception message on search fail'
                );
            }
        }
    }

    @isTest
    private static void testPostComment_asGuest_shouldFailEmptyCommentBody() {

        Id newCaseId = createCaseAsUser(guestTestUser);

        try {
            SCAPICaseService.addComment(newCaseId, null);
            System.assert(false, 'Exception not thrown when trying to post comment with empty body');
        } catch (Exception ex) {
            System.assertEquals(
                Label.SC_Case_Detail_empty_comment_body,
                ex.getMessage(),
                'Wrong exception message on search fail'
            );
        }
    }

    @isTest
    private static void testPostComment_asRCAdminUser() {

        SCWrappers.CommentWrapper comment;
        Id newCaseId = createCaseAsUser(guestTestUser);

        System.runAs(adminTestUser) {

            Test.startTest();
            comment = SCAPICaseService.addComment(newCaseId, COMMENT_BODY);
            Test.stopTest();
        }

        System.assert(comment != null, 'Comment not received');
        System.assertEquals(true, comment.isCurrentUser, 'Incorrent isCurrentUser flag');
        System.assertEquals(false, comment.isCaseCreator, 'Incorrent isCaseCreator flag');
        System.assertEquals(COMMENT_BODY, comment.body, 'Incorrent comment body');
        System.assert(comment.avatarUrl.contains('005/F'), 'Incorrent avatar url');
        System.assertEquals(
            ADMIN_CONTACT_FIRST_NAME + ' ' + ADMIN_CONTACT_LAST_NAME,
            comment.authorName,
            'Incorrent author name'
        );
    }

    @isTest
    private static void testGetAttachments() {

        Id newCaseId = createCase();
        Map<Id, Attachment> atts = new Map<Id, Attachment>(createAttachments(newCaseId));

        List<SCWrappers.AttachmentWrapper> attsResponse;

        System.runAs(guestTestUser) {

            Test.startTest();
            attsResponse = SCAPICaseService.getAttachments(newCaseId);
            Test.stopTest();
        }

        System.assert(attsResponse != null, 'Attachments not received');
        System.assertEquals(2, attsResponse.size(), 'Incorrent size of attachments');
        for (SCWrappers.AttachmentWrapper att : attsResponse) {
            System.assert(att.name.contains(ATTACHMENT_NAME), 'Incorrent attachment name');
            System.assert(att.url.contains(att.id), 'Incorrent url for attachment');
            System.assert(atts.containsKey(att.id), 'Incorrent attachment Id');
        }
    }

    @isTest
    private static void testDeleteAttachment() {

        Id newCaseId = createCase();
        List<Attachment> atts = createAttachments(newCaseId);

        System.runAs(guestTestUser) {

            Test.startTest();
            SCAPICaseService.deleteAttachment(atts[0].Id);
            Test.stopTest();
        }

        List<Attachment> attsAfterDelete = new AttachmentSelector()
            .selectAttachmentsByParentId(new List<String>{newCaseId})
            .executeQuery();

        System.assertEquals(1, attsAfterDelete.size(), 'Attachment not deleted');
    }

    @isTest
    private static void testGetAttachmentStorageSpaceLeft() {

        Id caseId = createCase();
        List<Attachment> atts = createAttachments(caseId);

        Integer spaceLeft = SCAPICaseService.STORAGE_LIMIT;
        spaceLeft -= ATTACHMENT_LENGTH * 2;

        Test.startTest();
        Integer responseSpaceLeft = SCAPICaseService.getAttachmentStorageSpaceLeft(caseId);
        Test.stopTest();

        System.assertEquals(spaceLeft, responseSpaceLeft, 'Incorrent space value');
    }

    @isTest
    private static void testAddAttachment() {

        Id caseId = createCase();

        Attachment att = (Attachment) new SObjectBuilder(Attachment.SObjectType)
            .setField(Attachment.ParentId, caseId)
            .setField(Attachment.Name, ATTACHMENT_NAME)
            .setField(Attachment.Body, Blob.valueOf(ATTACHMENT_BODY))
            .build()
            .getRecord();

        Test.startTest();
        SCAPICaseService.addAttachment(caseId, att);
        Test.stopTest();

        List<Attachment> realAttachments = new AttachmentSelector()
            .selectAttachmentsByParentId(new List<Id>{caseId})
            .selectFields(new List<Schema.SObjectField>{Attachment.Body})
            .executeQuery();

        System.assertEquals(1, realAttachments.size(), 'Incorrect number of attachments on case');
        System.assertEquals(ATTACHMENT_NAME, realAttachments[0].Name, 'Incorrect attachment name');
        System.assertEquals(ATTACHMENT_BODY, realAttachments[0].Body.toString(), 'Incorrect attachment body');
    }
}