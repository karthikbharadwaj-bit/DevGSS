@isTest
private with sharing class CaseListRestService_Test {

    private static final String APIONLY_USER_PROFILE_NAME = 'API Only';

    private static final String RC_USERID = '123456789';

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
    private static final String CASE_CLOSED_STATUS = 'Closed';
    private static final String CASE_INFO_DESCRIPTION = 'test Description';
    private static final String CASE_INFO_SEVERITY_LEVEL = 'Level 4 - Medium';

    private static final String ERROR_WRONG_RESPONSE = 'Wrong response';

    private static User APIOnlyTestUser {
        get {
            if (APIOnlyTestUser == null) {
                APIOnlyTestUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{USER_USERNAME}})
                    .selectFields(new List<String>{'ContactId', 'AccountId'})
                    .executeQuery()
                    .get(0);
            }
            return APIOnlyTestUser;
        }
        private set;
    }

    @TestSetup
    static void testSetup() {
        Profile APIOnlyProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{APIONLY_USER_PROFILE_NAME})
            .executeQuery()
            .get(0);

        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'Unted States',
                Account.RC_User_ID__c => RC_USERID
            })
            .create()
            .getRecords();

        List<Contact> contacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_LAST_NAME,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.Phone => CONTACT_PHONE,
                    Contact.Phone_Ext__c => CONTACT_PHONE_EXT,
                    Contact.AccountId => accounts[0].Id
                }
            )
            .create()
            .getRecords();

        List<AccountContactRole> accountCR = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => accounts[0].Id,
                AccountContactRole.ContactId => contacts[0].Id,
                AccountContactRole.Role => 'RC Admin User',
                AccountContactRole.IsPrimary => false
            })
            .create()
            .getRecords();

        List<User> users = new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => USER_LAST_NAME,
                    User.FirstName => USER_FIRST_NAME,
                    User.CommunityNickname => USER_LAST_NAME,
                    User.Email => USER_EMAIL,
                    User.Username => USER_USERNAME,
                    User.LanguageLocaleKey => USER_LANGUAGE,
                    User.ProfileId => APIOnlyProfile.Id
                }
            )
            .create()
            .getRecords();

        new SObjectBuilder(Case.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => ValueProviderBuilder.provideList(
                        new List<String>{CaseHelper.RT_ID_SUPPORT_CASE, CaseHelper.RT_ID_MAINTENANCE_CASE}
                    ),
                    Case.Subject => ValueProviderBuilder.provideList(
                        new List<String>{CASE_INFO_SUBJECT, CASE_INFO_SUBJECT}
                    ),
                    Case.Case_Severity__c => ValueProviderBuilder.provideList(
                        new List<String>{CASE_INFO_SEVERITY_LEVEL, CASE_INFO_SEVERITY_LEVEL}
                    ),
                    Case.Description => ValueProviderBuilder.provideList(
                        new List<String>{CASE_INFO_DESCRIPTION, CASE_INFO_DESCRIPTION}
                    ),
                    Case.Status => ValueProviderBuilder.provideList(
                        new List<String>{CASE_CLOSED_STATUS, null}
                    ),
                    Case.Site__c => ValueProviderBuilder.provideList(
                        new List<String>{'test site', 'test site'}
                    ),
                    Case.ContactId => contacts[0].Id,
                    Case.AccountId => accounts[0].Id
                }
            )
            .create();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet pSet = (PermissionSet) new PermissionSetSelector()
                .selectPermissionSetsByName(new Object[]{new String[]{'AEM_Permissions'}})
                .executeQuery()[0];

            new SObjectBuilder(PermissionSetAssignment.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PermissionSetAssignment.AssigneeId => apiOnlyTestUser.id,
                        PermissionSetAssignment.PermissionSetId => pSet.Id
                    }
                )
                .create();

            Group nonTellusGroup = (Group) new GroupSelector()
                .selectGroupBasedOnDeveloperNames(new Object[]{new String[]{'Non_Telus_Users'}})
                .executeQuery()[0];

            new SObjectBuilder(GroupMember.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    GroupMember.GroupId => nonTellusGroup.Id,
                    GroupMember.UserOrGroupId => apiOnlyTestUser.id
                })
                .create();

            insert new AccountShare(
                userorgroupid = nonTellusGroup.Id,
                accountid = accounts[0].Id,
                accountaccesslevel = 'Edit',
                OpportunityAccessLevel = 'Edit',
                CaseAccessLevel  = 'Edit',
                ContactAccessLevel = 'Edit'
            );
        }
    }

    @isTest
    private static void testGetCases() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseListAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );
        System.assert(RestContext.response.responseBody.toString().contains('"totalCases":1'), ERROR_WRONG_RESPONSE);
    }

    @isTest
    private static void testGetCasesWithOpenCasesStatusFilter() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('statusFilter', 'Open Cases');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseListAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );
        System.assert(RestContext.response.responseBody.toString().contains('"totalCases":0'), ERROR_WRONG_RESPONSE);
    }

    @isTest
    private static void testGetCasesWithClosedCasesStatusFilter() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('statusFilter', 'Closed Cases');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseListAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );
        System.assert(RestContext.response.responseBody.toString().contains('"totalCases":1'), ERROR_WRONG_RESPONSE);
    }

    @isTest
    private static void testGetCasesWithContact() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains('"totalCases":1'),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCasesRecordTypeShouldBeSupportOnly() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseListAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCasesWrongUser() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', 'wrong@test.com');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.NOT_FOUND_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCasesWithoutUser() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCasesWithSubject() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('subject', 'test');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains('test Subject'),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCasesWithSearchLimit() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('searchLimit', '1');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseListAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCasesWithCaseNumber() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put(CaseHelper.CASE_NUMBER, '1');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseListAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCasesWithContactName() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('contactName', CONTACT_FIRST_NAME);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseListAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCasesWithSite() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('site', 'test');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseListAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCasesSortByCaseNumber() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('sortBy', CaseHelper.CASE_NUMBER);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseListAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCasesSortBySite() {

        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        Triggers.switchOff();
        new SObjectBuilder(Case.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => ValueProviderBuilder.provideList(
                        new List<String>{CaseHelper.RT_ID_SUPPORT_CASE, CaseHelper.RT_ID_SUPPORT_CASE}
                    ),
                    Case.Subject => ValueProviderBuilder.provideList(
                        new List<String>{CASE_INFO_SUBJECT, CASE_INFO_SUBJECT}
                    ),
                    Case.Case_Severity__c => ValueProviderBuilder.provideList(
                        new List<String>{CASE_INFO_SEVERITY_LEVEL, CASE_INFO_SEVERITY_LEVEL}
                    ),
                    Case.Description => ValueProviderBuilder.provideList(
                        new List<String>{CASE_INFO_DESCRIPTION, CASE_INFO_DESCRIPTION}
                    ),
                    Case.Status => ValueProviderBuilder.provideList(
                        new List<String>{CASE_CLOSED_STATUS, CASE_CLOSED_STATUS}
                    ),
                    Case.Site__c => ValueProviderBuilder.provideList(
                        new List<String>{'test site', null}
                    ),
                    Case.ContactId => contacts[0].Id,
                    Case.AccountId => accounts[0].Id
                }
            )
            .create();
        Triggers.switchOn();

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('sortBy', 'site');
        request.params.put('sortOrder', 'desc');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseListAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );

        List<Object> cases = (List<Object>) ((Map<String,Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString())).get('cases');
        System.assert(cases.get(0).toString().contains('test site'), 'Case with populated site should be the at the top');
        System.assert(cases.get(1).toString().contains('test site'), 'Case with populated site should be the at the top');
        System.assert(!cases.get(2).toString().contains('test site'), 'Case with populated site should be the at the top');
    }

    @isTest
    private static void testGetCasesSortByWrongField() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('sortBy', 'wrongField');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCasesSortOrderWrongField() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('sortOrder', 'wrongOrder');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains('Invalid sortOrder value.'),
            RestContext.response.responseBody.toString()
        );
    }


    @isTest
    private static void testGetCases_WhenCaseNumberIsWrong_ShouldThrowException() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put(CaseHelper.CASE_NUMBER, 'invalid case number');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCases_WhenOffsetIsWrong_ShouldThrowException() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('offset', 'invalid offset');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetCases_WhenSearchLimitIsWrong_ShouldThrowException() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('searchLimit', 'invalid');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void testGetCases_WhenLangIsInvalid_ShouldThrowException() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('view', 'Invalid value');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void testGetCases_WhenViewIsInvalid_ShouldThrowException() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('lang', 'invalid lang');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void testGetCases_WhenContactIsNotAdminAndViewIsContact_ShouldThrowException() {

    String uid = '123';

    Triggers.switchOff();
    List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Account.Name => ValueProviderBuilder.provideUniqueString(),
            Account.BillingStreet => '2078 Adamsville Road',
            Account.BillingCity => 'Laredo',
            Account.BillingPostalCode => '78040',
            Account.BillingState => 'Texas',
            Account.BillingCountry => 'Unted States',
            Account.RC_User_ID__c => uid
        })
        .create()
        .getRecords();

    List<Contact> contacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Contact.FirstName => CONTACT_FIRST_NAME,
                Contact.LastName => CONTACT_LAST_NAME,
                Contact.Email => CONTACT_EMAIL,
                Contact.Phone => CONTACT_PHONE,
                Contact.Phone_Ext__c => CONTACT_PHONE_EXT,
                Contact.AccountId => accounts[0].Id
            }
        )
        .create()
        .getRecords();

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', uid);
        request.params.put('email', USER_EMAIL);
        request.params.put('view', 'contact');
        RestContext.request = request;
        // Call the method to test
        Triggers.switchOn();
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseListAPIController.BAD_REQUEST_ONLY_VALID_FOR_ADMIN_USERS),
            RestContext.response.responseBody.toString()
        );
    }


    @isTest
    private static void testGetCases_WhenContactIsAdminAndViewIsContact_ShouldBeOk() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USERID);
        request.params.put('email', USER_EMAIL);
        request.params.put('view', 'contact');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(APIOnlyTestUser) {
                CaseListRestService.getCaseList();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains('"totalCases":1'),
            RestContext.response.responseBody.toString()
        );
    }

}