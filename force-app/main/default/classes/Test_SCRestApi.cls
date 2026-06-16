@isTest
private class Test_SCRestApi {
    private static final String USER_USERNAME = 'RC_SupportCommunityNewCaseTestUser@nvx.zn';
    private static final String USER_EMAIL = 'testerino@rc.com';
    private static final String USER_FIRST_NAME = 'Toaster';
    private static final String USER_LAST_NAME = 'McToast';
    private static final String USER_LANGUAGE = 'en_US';
    private static final String USER_USERROLE_NAME = 'TestRoleName';

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
    private static final String OTHER_USER_PROFILE_NAME = 'Other';
    private static final String SYSTEM_ADMIN_PROFILE = 'System Administrator';

    private static final String CASE_INFO_SUBJECT = 'test Subject';
    private static final String CASE_INFO_DESCRIPTION = 'test Description';
    private static final String CASE_INFO_SELECTED_PRODUCT = 'test product one';
    private static final String CASE_INFO_SELECTED_PRODUCT2 = 'test product two';
    private static final String CASE_INFO_SELECTED_PRODUCT3 = 'test product three';
    private static final String CASE_INFO_SEVERITY_LEVEL = 'Level 4 - Medium';
    private static final Datetime CASE_INFO_CREATED_DATE = Datetime.newInstanceGmt(2007, 1, 1);

    private static final String ERROR_WRONG_STATUS_CODE = 'Wrong status code';
    private static final String ERROR_WRONG_MESSAGE = 'Wrong error message';
    private static final String ERROR_WRONG_RESPONSE = 'Wrong response';
    private static final String ERROR_LINE = 'errorLine';
    private static final String ERROR_STACK_TRACE = 'errorStackTrace';
    private static final String GET = 'GET';
    private static final String SC_API_REQUEST = '/services/apexrest/SCApi/v1/userInfo';
    private static final String SALES_AGREEMENT_END_DATE = 'salesAgreementEndDate';

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

        Profile systemAdminProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{SYSTEM_ADMIN_PROFILE})
            .executeQuery()
            .get(0);

        UserRole newRole = (UserRole) new SObjectBuilder(UserRole.SObjectType)
                .setField(UserRole.DeveloperName, USER_USERROLE_NAME)
                .setField(UserRole.Name, USER_USERROLE_NAME)
                .create()
                .getRecord();

        User testUser = new User(Alias = 'tstr01',
                                 Email='tstr01@theOrg.com',
                                 EmailEncodingKey='UTF-8',
                                 FirstName= 'TstrFrst',
                                 LastName='TstrLst01',
                                 LanguageLocaleKey='en_US',
                                 LocaleSidKey='en_US',
                                 TimeZoneSidKey='America/Los_Angeles',
                                 UserName='tstt01@theOrg.com',
                                 ProfileId=systemAdminProfile.Id);

        testUser.UserRoleId = newRole.Id;
        insert testUser;

        System.runAs(testUser) {
            Account portalAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideUniqueString('RC_USER_ID_'))
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
		}
        Triggers.switchOn();
    }

    private static Id createCaseAsUser(User userToRunTestAs) {
        Id caseId;
        System.runAs(userToRunTestAs) {
            caseId = createCase();
        }
        return caseId;
    }

    private static void createContactRole(Id acc, Id con, String role){
        List<AccountContactRole> accountCR = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => acc,
                AccountContactRole.ContactId => con,
                AccountContactRole.Role => role,
                AccountContactRole.IsPrimary => false
            })
            .create()
            .getRecords();
    }

    private static Id createCase() {

        List<Case> newCases;
        newCases = (List<Case>) new SObjectBuilder(Case.SObjectType)
        .quantity(2)
        .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => ValueProviderBuilder.provideList(
                    new List<String>{CaseHelper.RT_ID_SUPPORT_CASE, CaseHelper.RT_ID_MAINTENANCE_CASE}),
                    Case.Subject => ValueProviderBuilder.provideList(
                    new List<String>{CASE_INFO_SUBJECT, CASE_INFO_SUBJECT}),
                    Case.Case_Severity__c => ValueProviderBuilder.provideList(
                    new List<String>{CASE_INFO_SEVERITY_LEVEL, CASE_INFO_SEVERITY_LEVEL}),
                    Case.Description => ValueProviderBuilder.provideList(
                    new List<String>{CASE_INFO_DESCRIPTION, CASE_INFO_DESCRIPTION}),
                    Case.Product_Assistance__c => ValueProviderBuilder.provideList(
                    new List<String>{CASE_INFO_SELECTED_PRODUCT, CASE_INFO_SELECTED_PRODUCT}),
                    Case.Product_Assistance_Lvl2__c => ValueProviderBuilder.provideList(
                    new List<String>{CASE_INFO_SELECTED_PRODUCT2, CASE_INFO_SELECTED_PRODUCT2}),
                    Case.Product_Assistance_Lvl3__c => ValueProviderBuilder.provideList(
                    new List<String>{CASE_INFO_SELECTED_PRODUCT3, CASE_INFO_SELECTED_PRODUCT3})
                }
            )
        .create()
        .getRecords();

        Test.setCreatedDate(newCases[0].Id, CASE_INFO_CREATED_DATE);
        return newCases[0].Id;
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

    @isTest
    static void testGetUserInfo() {
        Id adminCaseId = createCaseAsUser(adminTestUser);
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectField('RC_User_ID__c')
            .setCondition('Name =:bind0')
            .setQueryBindings(new List<Object>{'My Account'})
            .executeQuery();

        List<Object> bindings = new List<Object>();
        bindings.add(accounts[0].Id);
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(bindings)
            .setCondition('AccountId = :bind0')
            .executeQuery();

        createContactRole(accounts[0].Id,contacts[0].Id,ADMIN_USER_PROFILE_NAME);

        Test.startTest();
            Map<String, String> params = new Map<String, String>();
            params.put(SCRestApi.EMAIL, CONTACT_EMAIL);
            params.put(SCRestApi.UID, accounts.get(0).RC_User_ID__c);
            params.put(SCRestApi.CASE_LIMIT, '5');
            RestContext.request = constructRequest(SC_API_REQUEST, GET, params);
            RestContext.response = new RestResponse();
            SCRestApi.getUserInfo();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assertEquals(200, RestContext.response.statusCode, ERROR_WRONG_STATUS_CODE);
        System.assertEquals(true, !responseBody.contains(SALES_AGREEMENT_END_DATE));
        System.assert(responseBody.contains('"totalUserCases":0'), ERROR_WRONG_RESPONSE);
        System.assert(responseBody.contains('"totalAccCases":1'), ERROR_WRONG_RESPONSE);
    }

    @isTest
    static void testGetUserInfoWithContact() {
        Id adminCaseId = createCaseAsUser(adminTestUser);
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectField('RC_User_ID__c')
            .setCondition('Name =:bind0')
            .setQueryBindings(new List<Object>{'My Account'})
            .executeQuery();

        List<Object> bindings = new List<Object>();
        bindings.add(accounts[0].Id);
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(bindings)
            .setCondition('AccountId = :bind0')
            .executeQuery();

        createContactRole(accounts[0].Id,contacts[0].Id,ADMIN_USER_PROFILE_NAME);
        createContactRole(accounts[0].Id,contacts[1].Id,OTHER_USER_PROFILE_NAME);

        Test.startTest();
        Map<String, String> params = new Map<String, String>();
        params.put(SCRestApi.EMAIL, CONTACT_EMAIL);
        params.put(SCRestApi.UID, accounts.get(0).RC_User_ID__c);
        params.put(SCRestApi.CASE_LIMIT, '5');
        RestContext.request = constructRequest(SC_API_REQUEST, GET, params);
        RestContext.response = new RestResponse();
        SCRestApi.getUserInfo();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assertEquals(200, RestContext.response.statusCode, ERROR_WRONG_STATUS_CODE);
        System.assertEquals(false, responseBody.contains(SALES_AGREEMENT_END_DATE));
    }

    @isTest
    static void testGetUserInfo_ShouldLoginWithHighestPermission_WithTwoContactRoles() {



        Id adminCaseId = createCaseAsUser(adminTestUser);
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectField('RC_User_ID__c')
            .setCondition('Name =:bind0')
            .setQueryBindings(new List<Object>{'My Account'})
            .executeQuery();

        List<Object> bindings = new List<Object>();
        bindings.add(accounts[0].Id);
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(bindings)
            .setCondition('AccountId = :bind0')
            .executeQuery();

        createContactRole(accounts[0].Id,contacts[1].Id,ADMIN_USER_PROFILE_NAME);
        createContactRole(accounts[0].Id,contacts[0].Id,OTHER_USER_PROFILE_NAME);

        Test.startTest();
        Map<String, String> params = new Map<String, String>();
        params.put(SCRestApi.EMAIL, CONTACT_EMAIL);
        params.put(SCRestApi.UID, accounts.get(0).RC_User_ID__c);
        params.put(SCRestApi.CASE_LIMIT, '5');
        RestContext.request = constructRequest(SC_API_REQUEST, GET, params);
        RestContext.response = new RestResponse();
        SCRestApi.getUserInfo();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assertEquals(200, RestContext.response.statusCode, ERROR_WRONG_STATUS_CODE);
        System.assert(responseBody.contains('"isAdmin":true'), ERROR_WRONG_RESPONSE);
    }

    @isTest
    static void testGetUserInfo_ShouldLoginAsGuest_WithContactRoles() {


        Id adminCaseId = createCaseAsUser(adminTestUser);
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectField('RC_User_ID__c')
            .setCondition('Name =:bind0')
            .setQueryBindings(new List<Object>{'My Account'})
            .executeQuery();

        Test.startTest();
        Map<String, String> params = new Map<String, String>();
        params.put(SCRestApi.EMAIL, CONTACT_EMAIL);
        params.put(SCRestApi.UID, accounts.get(0).RC_User_ID__c);
        params.put(SCRestApi.CASE_LIMIT, '5');
        RestContext.request = constructRequest(SC_API_REQUEST, GET, params);
        RestContext.response = new RestResponse();
        SCRestApi.getUserInfo();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assertEquals(200, RestContext.response.statusCode, ERROR_WRONG_STATUS_CODE);
        System.assert(responseBody.contains('"isAdmin":false'), ERROR_WRONG_RESPONSE);
    }

    @isTest
    static void testGetUserInfo_ShouldLoginAsGuest_WithoutContactRoles() {


        Id adminCaseId = createCaseAsUser(adminTestUser);
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectField('RC_User_ID__c')
            .setCondition('Name =:bind0')
            .setQueryBindings(new List<Object>{'My Account'})
            .executeQuery();
        List<Object> bindings = new List<Object>();
        bindings.add(accounts[0].Id);
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(bindings)
            .setCondition('AccountId = :bind0')
            .executeQuery();

        createContactRole(accounts[0].Id,contacts[0].Id, ADMIN_USER_PROFILE_NAME);

        Test.startTest();
        Map<String, String> params = new Map<String, String>();
        params.put(SCRestApi.EMAIL, CONTACT_EMAIL);
        params.put(SCRestApi.UID, accounts.get(0).RC_User_ID__c);
        params.put(SCRestApi.CASE_LIMIT, '5');
        RestContext.request = constructRequest(SC_API_REQUEST, GET, params);
        RestContext.response = new RestResponse();
        SCRestApi.getUserInfo();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assertEquals(200, RestContext.response.statusCode, ERROR_WRONG_STATUS_CODE);
        System.assert(responseBody.contains('"isAdmin":false'), ERROR_WRONG_RESPONSE);
    }

    @isTest
    static void testGetUserInfo_ShouldNotFail_WhenNoCaseLimitParameter() {
        Id adminCaseId = createCaseAsUser(adminTestUser);
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectField('RC_User_ID__c')
            .setCondition('Name =:bind0')
            .setQueryBindings(new List<Object>{'My Account'})
            .executeQuery();
        List<Object> bindings = new List<Object>();
        bindings.add(accounts[0].Id);
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(bindings)
            .setCondition('AccountId = :bind0')
            .executeQuery();

        createContactRole(accounts[0].Id,contacts[0].Id, ADMIN_USER_PROFILE_NAME);
        Map<String, String> params = new Map<String, String>();
        params.put(SCRestApi.EMAIL, contacts[0].Email);
        params.put(SCRestApi.UID, accounts.get(0).RC_User_ID__c);
        RestContext.request = constructRequest(SC_API_REQUEST, GET, params);
        RestContext.response = new RestResponse();
        Test.startTest();

        SCRestApi.getUserInfo();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assertEquals(200, RestContext.response.statusCode, ERROR_WRONG_STATUS_CODE);
        System.assert(responseBody.contains('"totalAccCases":1'), ERROR_WRONG_RESPONSE);
    }

    @isTest
    static void testGetUserInfo_ShouldFail_WhenNoUserFound() {
        Test.startTest();
        Map<String, String> params = new Map<String, String>();
        params.put(SCRestApi.EMAIL, CONTACT_EMAIL);
        params.put(SCRestApi.UID, 'some_UID');
        params.put(SCRestApi.CASE_LIMIT, '5');
        RestContext.request = constructRequest(SC_API_REQUEST, GET, params);
        RestContext.response = new RestResponse();
        SCRestApi.getUserInfo();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assertEquals(404, RestContext.response.statusCode, ERROR_WRONG_STATUS_CODE);
        System.assert(responseBody.contains(CaseAPIUtil.ERROR_MESSAGE_INVALID_USERID_OR_EMAIL), ERROR_WRONG_MESSAGE);
    }

    private static RestRequest constructRequest(String uri, String method, Map<String, String> params) {
        RestRequest request = new RestRequest();
        request.requestURI = uri;
        request.httpMethod = method;
        for (String param : params.keySet()) {
            request.addParameter(param, params.get(param));
        }
        request.addHeader('Content-Type', 'application/json');
        return request;
    }

    @isTest
    static void testGetUserInfoContactInfoFieldValidations() {
        Id adminCaseId = createCaseAsUser(adminTestUser);

        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectField('RC_User_ID__c')
            .setCondition('Name =:bind0')
            .setQueryBindings(new List<Object>{'My Account'})
            .executeQuery();

        Triggers.switchOff();
        if(accounts.get(0) != null) {
            accounts.get(0).inContact_Cluster__c = 'Test inContact_Cluster';
            update accounts.get(0);
        }

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => accounts[0].Id,
                Package__c.Service_Type__c => 'Office',
                Package__c.Account_Package_Id__c => '11111111111',
                Package__c.Account_POD__c => 'Test Account_POD'
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        Test.startTest();

        List<Object> bindings = new List<Object>();
        bindings.add(accounts[0].Id);
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(bindings)
            .setCondition('AccountId = :bind0')
            .executeQuery();

        createContactRole(accounts[0].Id,contacts[0].Id,ADMIN_USER_PROFILE_NAME);

        Map<String, String> params = new Map<String, String>();
        params.put(SCRestApi.EMAIL, CONTACT_EMAIL);
        params.put(SCRestApi.UID, accounts.get(0).RC_User_ID__c);
        params.put(SCRestApi.CASE_LIMIT, '5');
        RestContext.request = constructRequest(SC_API_REQUEST, GET, params);
        RestContext.response = new RestResponse();
        SCRestApi.getUserInfo();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assertEquals(200, RestContext.response.statusCode, ERROR_WRONG_STATUS_CODE);
        System.assertEquals(true, !responseBody.contains(SALES_AGREEMENT_END_DATE));
        System.assert(responseBody.contains('"totalUserCases":0'), ERROR_WRONG_RESPONSE);
        System.assert(responseBody.contains('"totalAccCases":1'), ERROR_WRONG_RESPONSE);
        System.assert(responseBody.contains('Test inContact_Cluster'), ERROR_WRONG_RESPONSE);
        System.assert(responseBody.contains('Test Account_POD'), ERROR_WRONG_RESPONSE);
    }

    @isTest
    static void testGetUserInfoWithContactContactInfoFieldValidations() {


        Triggers.switchOff();
        Id adminCaseId = createCaseAsUser(adminTestUser);
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectField('RC_User_ID__c')
            .setCondition('Name =:bind0')
            .setQueryBindings(new List<Object>{'My Account'})
            .executeQuery();

        List<Object> bindings = new List<Object>();
        bindings.add(accounts[0].Id);
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(bindings)
            .setCondition('AccountId = :bind0')
            .executeQuery();

        Triggers.switchOff();
        if(accounts.get(0) != null) {
            accounts.get(0).inContact_Cluster__c = 'Test inContact_Cluster';
            update accounts.get(0);
        }

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => accounts[0].Id,
                Package__c.Service_Type__c => 'Office',
                Package__c.Account_Package_Id__c => '11111111111',
                Package__c.Account_POD__c => 'Test Account_POD'
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        Test.startTest();


        createContactRole(accounts[0].Id,contacts[0].Id,ADMIN_USER_PROFILE_NAME);
        createContactRole(accounts[0].Id,contacts[1].Id,OTHER_USER_PROFILE_NAME);

        Map<String, String> params = new Map<String, String>();
        params.put(SCRestApi.EMAIL, CONTACT_EMAIL);
        params.put(SCRestApi.UID, accounts.get(0).RC_User_ID__c);
        params.put(SCRestApi.CASE_LIMIT, '5');
        RestContext.request = constructRequest(SC_API_REQUEST, GET, params);
        RestContext.response = new RestResponse();
        SCRestApi.getUserInfo();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assertEquals(200, RestContext.response.statusCode, ERROR_WRONG_STATUS_CODE);
        System.assertEquals(false, responseBody.contains(SALES_AGREEMENT_END_DATE));
        System.assert(responseBody.contains('Test inContact_Cluster'), ERROR_WRONG_RESPONSE);
        System.assert(responseBody.contains('Test Account_POD'), ERROR_WRONG_RESPONSE);
    }

    @isTest
    static void testGetUserInfo_whenContactAccountIsPartnerSoldEnterpriseSupport_shouldBeOk() {

        ByPassTrigger__c byPassTrigger = new ByPassTrigger__c();
        byPassTrigger.Bypass_Entitlement_Trigger__c = true;
        byPassTrigger.Bypass_Account_Trigger__c = true;
        insert byPassTrigger;

        Id adminCaseId = createCaseAsUser(adminTestUser);

        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectField('RC_User_ID__c')
            .setCondition('Name =:bind0')
            .setQueryBindings(new List<Object>{ 'My Account' })
            .executeQuery();

        Feature_Toggle__c toggle = new Feature_Toggle__c();
        toggle.SkipBrandPartnerSyncFromAccount__c = true;
        insert toggle;

        Triggers.switchOff();
        if (accounts.get(0) != null) {
            accounts.get(0).inContact_Cluster__c = 'Test inContact_Cluster';
            accounts.get(0).RC_Brand__c = 'Avaya Cloud Office';
            accounts.get(0).Enterprise_Support_Start_Date__c = Date.today();
            accounts.get(0).Enterprise_Support_End_Date__c = Date.today().addDays(3);
            accounts.get(0).Actual_transport_MRR__c = 100;
            accounts.get(0).Minute_Bundle__c = 10;
            update accounts.get(0);
        }

        List<Object> bindings = new List<Object>();
        bindings.add(accounts[0].Id);
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(bindings)
            .setCondition('AccountId = :bind0')
            .executeQuery();

        createContactRole(accounts[0].Id, contacts[0].Id, ADMIN_USER_PROFILE_NAME);

        List<Product2> prodList = new List<Product2>();

        Product2 testProduct = new Product2(
            Name = 'first product',
            IsActive = true,
            Sub_Category__c = 'Main'
        );
        prodList.add(testProduct);

        Product2 testProServProduct = new Product2(
            Name = 'first product',
            IsActive = true,
            Sub_Category__c = 'Professional Services'
        );
        prodList.add(testProServProduct);
        insert prodList;
        
        Triggers.switchOn();

        List<Entitlement> entitlementList = new List<Entitlement>();
        for (Product2 prod : prodList) {
            entitlementList.add(
                new Entitlement(
                    Name = 'test support entitlement',
                    AccountId = accounts[0].Id,
                    Product__c = prod.Id,
                    StartDate = Date.today(),
                    Type = 'Advanced Support'
                )
            );
        }
        insert entitlementList;

        Map<String, String> params = new Map<String, String>();
        params.put(SCRestApi.EMAIL, CONTACT_EMAIL);
        params.put(SCRestApi.UID, accounts.get(0).RC_User_ID__c);
        params.put(SCRestApi.CASE_LIMIT, '5');
        RestContext.request = constructRequest(SC_API_REQUEST, GET, params);
        RestContext.response = new RestResponse();

        Test.startTest();
            SCRestApi.getUserInfo();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assertEquals(200, RestContext.response.statusCode, ERROR_WRONG_STATUS_CODE);
        System.assertEquals(true, !responseBody.contains(SALES_AGREEMENT_END_DATE));
        System.assert(responseBody.contains('"brand":"Avaya Cloud Office"'), ERROR_WRONG_RESPONSE);
        System.assert(responseBody.contains('"is_partner_sold_ES":false'), ERROR_WRONG_RESPONSE);
    }

    @isTest
    static void testGetUserInfo_ShouldFail_WhenInvalidCaseLimit() {

        Id adminCaseId = createCaseAsUser(adminTestUser);
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectField('RC_User_ID__c')
            .setCondition('Name =:bind0')
            .setQueryBindings(new List<Object>{'My Account'})
            .executeQuery();

        List<Object> bindings = new List<Object>();
        bindings.add(accounts[0].Id);
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(bindings)
            .setCondition('AccountId = :bind0')
            .executeQuery();

        Test.startTest();

        Map<String, String> params = new Map<String, String>();
        params.put(SCRestApi.EMAIL, CONTACT_EMAIL);
        params.put(SCRestApi.UID, accounts.get(0).RC_User_ID__c);
        params.put(SCRestApi.CASE_LIMIT, 'Invalid case limit');
        RestContext.request = constructRequest(SC_API_REQUEST, GET, params);
        RestContext.response = new RestResponse();
        SCRestApi.getUserInfo();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        System.assertEquals(400, RestContext.response.statusCode, ERROR_WRONG_STATUS_CODE);
        System.assert(responseBody.contains(CaseAPIUtil.BAD_REQUEST_MESSAGE), ERROR_WRONG_MESSAGE);
    }
    @IsTest
    static void testSetResetGlobalVariable() {
        List<Boolean> fieldValues = new List<Boolean>();
        fieldValues.add(true);
        ContactHelper.setResetGlobalVariable(fieldValues);
        Assert.areEqual(true, ContactHelper.IS_DO_NOT_CONTACT_EVENT, 'The global variable should be set to true.');
        fieldValues.clear();
        fieldValues.add(false);
        ContactHelper.setResetGlobalVariable(fieldValues);
        Assert.areEqual(false, ContactHelper.IS_DO_NOT_CONTACT_EVENT, 'The global variable should be set to false.');
    }
}