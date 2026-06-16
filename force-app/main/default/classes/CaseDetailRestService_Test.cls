@isTest
public with sharing class CaseDetailRestService_Test {

    private static final String API_USER_PROFILE_NAME = 'Api Only';

    private static final String USER_USERNAME = 'RC_SupportCommunityCaseListTestUser@rc.com';
    private static final String USER_EMAIL = 'useremail@rc.com';
    private static final String USER_FIRST_NAME = 'firstname';
    private static final String USER_LAST_NAME = 'lastname';
    private static final String USER_LANGUAGE = 'en_US';
    private static final String APIUSER_USERNAME = 'ApiOnlyTestUser@rc.com';
    private static final String APIUSER_EMAIL = 'apiuseremail@rc.com';
    private static final String APIUSER_LAST_NAME = 'apilastname';

    private static final String CONTACT_FIRST_NAME = USER_FIRST_NAME;
    private static final String CONTACT_LAST_NAME = USER_LAST_NAME;
    private static final String CONTACT_EMAIL = USER_EMAIL;
    private static final String CONTACT_PHONE = '77777777';
    private static final Decimal CONTACT_PHONE_EXT = 777;

    private static final String CASE_INFO_SUBJECT = 'test Subject';
    private static final String CASE_INFO_DESCRIPTION = 'test Description';
    private static final String CASE_GDPR_DESCRIPTION_VIEW = 'No';
    private static final String CASE_GDPR_DESCRIPTION_CHANGE = 'No';
    private static final String CASE_GDPR_DESCRIPTION_DOWNLOAD = 'No';
    private static final String CASE_GDPR_DESCRIPTION_DELETE = 'Yes';
    private static final String CASE_GDPR_DESCRIPTION_RETAIN_ANALYTICS = 'No';
    private static final String CASE_GDPR_DESCRIPTION_RETAIN_GLIP = 'No';
    private static final String CASE_GDPR_DESCRIPTION_NAME_PRIVACY_ACTIONS = 'Chris Vu';
    private static final String CASE_GDPR_DESCRIPTION_EMAIL_PRIVACY_ACTIONS = 'chris@mcgee-law.com';
    private static final String CASE_GDPR_DESCRIPTION_PHONE_PRIVACY_ACTIONS = 'None';
    private static final String CASE_GDPR_DESCRIPTION_RESIDENT_EU = 'Yes';
    private static final String CASE_GDPR_DESCRIPTION_COMMENT = 'Ownership has now been transferred to Jim McGee &lt;jimmcgee@mcgee-law.com&gt;. Please delete chris@mcgee-law.com in any database applicable.';
    private static final String CASE_GDPR_DESCRIPTION = '====================\r\n\r\nView: '+CASE_GDPR_DESCRIPTION_VIEW+'\r\n' +
        'Change: '+ CASE_GDPR_DESCRIPTION_CHANGE +'\r\nDownload: '+ CASE_GDPR_DESCRIPTION_DOWNLOAD +'\r\nDelete: '+ CASE_GDPR_DESCRIPTION_DOWNLOAD +
        '\r\nRetain Analytics Data: '+ CASE_GDPR_DESCRIPTION_RETAIN_ANALYTICS +'\r\nRetain Glip Messages: '+ CASE_GDPR_DESCRIPTION_RETAIN_GLIP +'\r\n' +
        'Name of user requiring privacy action: '+ CASE_GDPR_DESCRIPTION_NAME_PRIVACY_ACTIONS +'\r\nEmail of user requiring privacy action: '+ CASE_GDPR_DESCRIPTION_EMAIL_PRIVACY_ACTIONS +
        '\r\nRC Phone Number (if applicable) of the user requiring privacy action: '+ CASE_GDPR_DESCRIPTION_PHONE_PRIVACY_ACTIONS +'\r\n' +
        'Is this user a Citizen or legal resident within the EU (including UK): '+ CASE_GDPR_DESCRIPTION_RESIDENT_EU +'\r\n' +
        'Comments: '+ CASE_GDPR_DESCRIPTION_COMMENT;
    private static final String CASE_INFO_SEVERITY_LEVEL = 'Level 4 - Medium';
    private static final String CASE_TIMEZONE = '(GMT-12:00) International Date Line West';

    private static final String ISGDPR_FALSE = '\"isGdpr\": false,';
    private static final String ISGDPR_TRUE = '\"isGdpr\": true,';
    private static final String UID = '123456789';
    
    private static final String COMMENT = 'this is a test comment';
    private static final String COMMENT_TWO = 'this is a test comment - two';

    private static final String JSON_COMMENT = '{\"uid\":\"123456789\",'+
                                                '\"email\":\"useremail@rc.com\",'+
                                                '\"createdByUser\":\"0050U000005IMgHQAW\",'+
                                                '\"createdByContact\":null,'+
                                                '\"comment\": \"'+COMMENT+'\",'+
                                                '\"authorName\":\"Contact Test\"}';

    private static final String JSON_COMMENT_MAP_PART = 'createdByUser';
    
    private static User apiOnlyTestUser {
        get {
            if (apiOnlyTestUser == null) {
                apiOnlyTestUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{APIUSER_USERNAME}})
                    .selectFields(new List<String>{'ContactId', 'AccountId'})
                    .executeQuery()
                    .get(0);
            }
            return apiOnlyTestUser;
        }
        private set;
    }

    @TestSetup
    static void testSetup() {
            
        Profile apiProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{API_USER_PROFILE_NAME})
            .executeQuery()
            .get(0);

        List<Account> portalAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'Unted States',
                Account.RC_User_ID__c => UID
            })
            .create()
            .getRecords();

        List<Contact> portalContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_LAST_NAME,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.Phone => CONTACT_PHONE,
                    Contact.Phone_Ext__c => CONTACT_PHONE_EXT,
                    Contact.AccountId => portalAccounts[0].Id
                }
            )
            .create()
            .getRecords();

        List<AccountContactRole> accountCR = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => portalAccounts[0].Id,
                AccountContactRole.ContactId => portalContacts[0].Id,
                AccountContactRole.Role => 'RC Admin User',
                AccountContactRole.IsPrimary => false
            })
            .create()
            .getRecords();
            
        List<User> users = new SObjectBuilder(User.SObjectType)
                .quantity(2)
                .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => ValueProviderBuilder.provideList(
                        new List<String>{USER_LAST_NAME, USER_LAST_NAME}
                    ),
                    User.FirstName => ValueProviderBuilder.provideList(
                        new List<String>{USER_FIRST_NAME, USER_FIRST_NAME}
                    ),
                    User.CommunityNickname => ValueProviderBuilder.provideList(
                        new List<String>{USER_LAST_NAME, APIUSER_LAST_NAME}
                    ),
                    User.Email => ValueProviderBuilder.provideList(
                        new List<String>{USER_EMAIL, APIUSER_EMAIL}
                    ),
                    User.Username => ValueProviderBuilder.provideList(
                        new List<String>{USER_USERNAME, APIUSER_USERNAME}
                    ),
                    User.LanguageLocaleKey => USER_LANGUAGE,
                    User.ProfileId => ValueProviderBuilder.provideList(
                        new List<String>{apiProfile.Id, apiProfile.Id}
                    )
                }
            )
            .create()
            .getRecords();
        
		TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
        List<Case> newCases = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => ValueProviderBuilder.provideList(
                        new List<String> {
                            CaseHelper.RT_ID_SUPPORT_T1, 
                            CaseHelper.RT_ID_GDPR_REQUEST
                        }
                    ),
                    Case.Description => ValueProviderBuilder.provideList(
                        new List<String> {
                            CASE_INFO_DESCRIPTION, 
                            CASE_GDPR_DESCRIPTION
                        }
                    ),
                    Case.Case_Severity__c => CASE_INFO_SEVERITY_LEVEL,
                    Case.Timezone__c => CASE_TIMEZONE,
                    Case.Subject => CASE_INFO_SUBJECT,
                    Case.ContactId => portalContacts[0].Id,
                    Case.AccountId => portalAccounts[0].Id
                }
            )
            .create()
            .getRecords();
		TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
        List<CaseShare> caseShares = new List<CaseShare>();
        for (Case c : newCases) {
            caseShares.add(new CaseShare(
                CaseId = c.Id,
                UserOrGroupId = apiOnlyTestUser.Id,
                CaseAccessLevel = 'Read' // Can be 'Read' or 'Edit'
            ));
        }
        insert caseShares;
        SCWrappers.CaseCommentAPI commentWrapper = (SCWrappers.CaseCommentAPI) JSON.deserialize(
                                                    JSON_COMMENT, SCWrappers.CaseCommentAPI.class);
        
        commentWrapper.createdByUser = apiOnlyTestUser.Id;
        String jsonComment = JSON.serialize(commentWrapper);

        String apiComment = SCApiService.AUTHOR_NAME_KEY + CONTACT_FIRST_NAME + ' ' + CONTACT_LAST_NAME + '\n' +
            SCApiService.COMMENT_KEY + COMMENT_TWO + '\n' +
            SCApiService.UID_KEY + UID + '\n' +
            SCApiService.EMAIL_KEY + CONTACT_EMAIL + '\n' +
            SCApiService.CREATED_BY_USER_KEY + apiOnlyTestUser.Id + '\n' +
            SCApiService.CREATED_BY_CONTACT_KEY + portalContacts[0].Id;

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
    
                pSet = (PermissionSet) new PermissionSetSelector()
                    .selectPermissionSetsByName(new Object[]{new String[]{'Case_Modify_All_Permission'}})
                    .executeQuery()[0];
                    
                new SObjectBuilder(PermissionSetAssignment.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            PermissionSetAssignment.AssigneeId => apiOnlyTestUser.id,
                            PermissionSetAssignment.PermissionSetId => pSet.Id
                        }
                    )
                    .create();
            }

        System.runAs(apiOnlyTestUser) {
            new SObjectBuilder(CaseComment.SObjectType)
                .quantity(3)
                .setFields(
                    new Map<SObjectField, Object>{
                        CaseComment.IsPublished => true,
                        CaseComment.ParentId => newCases[0].Id,
                        CaseComment.CommentBody => ValueProviderBuilder.provideList(new Object[]{
                            'TestCommentBody_',
                            jsonComment,
                            apiComment
                        })
                    }
                )
                .create();
        }
    }

    @isTest
    private static void testGetCaseDetail() {
        Case testCase = (Case) new CaseSelector(false, false).selectCasesDefault().executeQuery()[0];

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseDetail';
        request.httpMethod = 'GET';
        request.params.put('uid', UID);
        request.params.put('email', USER_EMAIL);
        request.params.put('caseId', testCase.Id);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseDetailRestService.getCaseInfo();
            }
        Test.stopTest();

        String responseBody =  RestContext.response.responseBody.toString();

        System.assertEquals(200, RestContext.response.statusCode, 'response:\n' + responseBody);
        System.assertEquals(true, responseBody.contains(CaseDetailAPIController.SUCCESS_MESSAGE));
        System.assertEquals(false, responseBody.contains(ISGDPR_FALSE));

        //Make sure response contains Case Timezone
        System.assertEquals(true, responseBody.contains(CASE_TIMEZONE));
        System.assertEquals(false, responseBody.contains(JSON_COMMENT_MAP_PART));
    }

    
    @isTest
    private static void testGetCaseDetailOtherLang() {
        Case testCase = (Case) new CaseSelector(false, false).selectCasesDefault().executeQuery()[0];

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseDetail';
        request.httpMethod = 'GET';
        request.params.put('uid', UID);
        request.params.put('lang', 'de');
        request.params.put('email', USER_EMAIL);
        request.params.put('caseId', testCase.Id);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseDetailRestService.getCaseInfo();
            }
        Test.stopTest();

        String responseBody =  RestContext.response.responseBody.toString();

        System.assertEquals(200, RestContext.response.statusCode, 'response:\n' + responseBody);
        System.assertEquals(true, responseBody.contains(CaseDetailAPIController.SUCCESS_MESSAGE));
        System.assertEquals(false, responseBody.contains(ISGDPR_FALSE));

        //Make sure response contains Case Timezone
        System.assertEquals(true, responseBody.contains(CASE_TIMEZONE));
        System.assertEquals(false, responseBody.contains(JSON_COMMENT_MAP_PART));
    }

    @isTest
    private static void testGetCaseDetailWithContact() {
        Case testCase = (Case) new CaseSelector(false, false)
           .selectCasesDefault()
           .selectFields(new String[]{
                'Contact.Id',
                'Contact.Name',
                'Contact.User_Id__c',
                'AccountId',
                'Account'
            })
           .executeQuery()[0];

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseDetail';
        request.httpMethod = 'GET';
        request.params.put('uid', UID);
        request.params.put('email', CONTACT_EMAIL);
        request.params.put('caseId', testCase.Id);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseDetailRestService.getCaseInfo();
            }
        Test.stopTest();

        Boolean hasApiComment = false;
        String apiComment = SCApiService.AUTHOR_NAME_KEY + CONTACT_FIRST_NAME + ' ' + CONTACT_LAST_NAME + '\n' +
            SCApiService.COMMENT_KEY + COMMENT_TWO + '\n' +
            SCApiService.UID_KEY + UID + '\n' +
            SCApiService.EMAIL_KEY + CONTACT_EMAIL + '\n' +
            SCApiService.CREATED_BY_USER_KEY + apiOnlyTestUser.Id + '\n' +
            SCApiService.CREATED_BY_CONTACT_KEY + testCase.contactId;

        for (CaseComment csComment : ((List<CaseComment>) new CaseCommentSelector()
            .selectCaseCommentsByCaseId(new Object[]{testCase.Id})
            .executeQuery())
        ) {
            if (csComment.commentBody.equals(apiComment)) {
                hasApiComment = true;
                break;
            }
        }
        System.assert(hasApiComment, 'Any of the case comments have the formatted comment: ' + apiComment);

        String responseBody =  RestContext.response.responseBody.toString();

        System.assertEquals(200, RestContext.response.statusCode, 'response:\n' + responseBody);
        System.assertEquals(true, responseBody.contains(CaseDetailAPIController.SUCCESS_MESSAGE));

        //Make sure response contains Case Timezone
        System.assertEquals(true, responseBody.contains(CASE_TIMEZONE));
        System.assertEquals(true, responseBody.contains(COMMENT));
        System.assertEquals(true, responseBody.contains(COMMENT_TWO));
    }

    @isTest
    private static void testGetCaseDetailWithoutCaseId() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseDetail';
        request.httpMethod = 'GET';
        request.params.put('uid', UID);
        request.params.put('email', USER_EMAIL);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseDetailRestService.getCaseInfo();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseDetailRestService.BAD_REQUEST));
    }

    @isTest
    private static void testGetCaseDetailWrongCredentials() {

        Case testCase = (Case) new CaseSelector(false, false).selectCasesDefault().executeQuery()[0];

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseDetail';
        request.httpMethod = 'GET';
        request.params.put('uid', '19');
        request.params.put('email', 'Wrong@email.com');
        request.params.put('caseId', testCase.Id);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseDetailRestService.getCaseInfo();
            }
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseAPIUtil.ERROR_MESSAGE_INVALID_USERID_OR_EMAIL));
    }

    @isTest
    private static void testPostCommentSuccess() {
        Case testCase = (Case) new CaseSelector(false, false)
           .selectCasesDefault().executeQuery()[0];

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseDetail';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('email', USER_EMAIL);
        params.put('caseId', testCase.Id);
        params.put('comment', 'This is a comment for test class');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseDetailRestService.postComment();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseDetailAPIController.SUCCESS_MESSAGE_POST));
    }

    @isTest
    private static void testPostCommentSuccessWithContact() {
        Case testCase = (Case) new CaseSelector(false, false).selectCasesDefault().executeQuery()[0];

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseDetail';
        request.httpMethod = 'POST';
        RestContext.request = request;

        String comment = 'This is a comment for test class with contact';

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('email', CONTACT_EMAIL);
        params.put('caseId', testCase.Id);
        params.put('comment', comment);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseDetailRestService.postComment();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseDetailAPIController.SUCCESS_MESSAGE_POST));
    }

    @isTest
    private static void testPostCommentError() {
        Case testCase = (Case) new CaseSelector(false, false).selectCasesDefault().executeQuery()[0];

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseDetail';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('email', USER_EMAIL);
        params.put('comment', 'This is a comment for test class');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
            System.runAs (apiOnlyTestUser) {
                CaseDetailRestService.postComment();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseDetailRestService.BAD_REQUEST_POST));
    }

    @isTest
    private static void getCaseDetail_WhenCaseIsGDPR_ShouldReturnDescriptionGDPRCorrectly() {
        Case caseGDPR = [SELECT Id FROM CASE Where RecordTypeId = :CaseHelper.RT_ID_GDPR_REQUEST];

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseDetail';
        request.httpMethod = 'GET';
        request.params.put('uid', UID);
        request.params.put('email', USER_EMAIL);
        request.params.put('caseId', caseGDPR.Id);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseDetailRestService.getCaseInfo();
            }
        Test.stopTest();
        String responseBody =  RestContext.response.responseBody.toString();

        System.assertEquals(200, RestContext.response.statusCode, 'response:\n' + responseBody);
        System.assertEquals(true, responseBody.contains(CaseDetailAPIController.SUCCESS_MESSAGE));
        System.assertEquals(false, responseBody.contains(ISGDPR_TRUE));
        System.assertEquals(true, responseBody.contains('descriptionGDPR'),'doesnt contains the key descriptionGDPR');
        System.assertEquals(true, responseBody.contains('euCitizen'),'doesnt contains the key euCitizen');
        System.assertEquals(true, responseBody.contains('rcPhone'),'doesnt contains the key rcPhone');
        System.assertEquals(true, responseBody.contains('gdprEmail'),'doesnt contains the key gdprEmail');
        System.assertEquals(true, responseBody.contains('lastName'),'doesnt contains the key lastName');
        System.assertEquals(true, responseBody.contains('firstName'),'doesnt contains the key firstName');
        System.assertEquals(true, responseBody.contains('retainMessage'),'doesnt contains the key retainMessage');
        System.assertEquals(true, responseBody.contains('delete'),'doesnt contains the key delete');
        System.assertEquals(true, responseBody.contains('download'),'doesnt contains the key download');
        System.assertEquals(true, responseBody.contains('change'),'doesnt contains the key change');
        System.assertEquals(true, responseBody.contains('view'),'doesnt contains the key view');

        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_RESIDENT_EU),'doesnt contains the value' + CASE_GDPR_DESCRIPTION_RESIDENT_EU);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_VIEW),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_VIEW);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_CHANGE),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_CHANGE);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_DOWNLOAD),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_DOWNLOAD);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_DELETE),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_DELETE);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_RETAIN_ANALYTICS),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_RETAIN_ANALYTICS);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_RETAIN_GLIP),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_RETAIN_GLIP);
        String firstName = CASE_GDPR_DESCRIPTION_NAME_PRIVACY_ACTIONS.split(' ')[0];
        String lastName = CASE_GDPR_DESCRIPTION_NAME_PRIVACY_ACTIONS.split(' ')[1];

        System.assertEquals(true, responseBody.contains(firstName),' doesnt contains the value' + firstName);
        System.assertEquals(true, responseBody.contains(lastName),' doesnt contains the value' + lastName);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_EMAIL_PRIVACY_ACTIONS),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_EMAIL_PRIVACY_ACTIONS);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_PHONE_PRIVACY_ACTIONS),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_PHONE_PRIVACY_ACTIONS);

        //Make sure response contains Case Timezone
        System.assertEquals(true, responseBody.contains(CASE_TIMEZONE));
    }
    
    @isTest
    private static void getCaseDetail_WhenCaseIsGDPRAndHasNotComments_ShouldReturnDescriptionGDPRCorrectly() {
        Case caseGDPR = [SELECT Id, Description FROM CASE Where RecordTypeId = :CaseHelper.RT_ID_GDPR_REQUEST];

        Triggers.switchOff();
        TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
        caseGDPR.Description = caseGDPR.Description.replace(' ' + CASE_GDPR_DESCRIPTION_COMMENT, '');
        update caseGDPR;
        Triggers.switchOn();

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseDetail';
        request.httpMethod = 'GET';
        request.params.put('uid', UID);
        request.params.put('email', USER_EMAIL);
        request.params.put('caseId', caseGDPR.Id);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseDetailRestService.getCaseInfo();
            }
        Test.stopTest();
        String responseBody =  RestContext.response.responseBody.toString();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, responseBody.contains(CaseDetailAPIController.SUCCESS_MESSAGE));
        System.assertEquals(false, responseBody.contains(ISGDPR_TRUE));
        System.assertEquals(true, responseBody.contains('descriptionGDPR'),'doesnt contains the key descriptionGDPR');
        System.assertEquals(true, responseBody.contains('euCitizen'),'doesnt contains the key euCitizen');
        System.assertEquals(true, responseBody.contains('rcPhone'),'doesnt contains the key rcPhone');
        System.assertEquals(true, responseBody.contains('gdprEmail'),'doesnt contains the key gdprEmail');
        System.assertEquals(true, responseBody.contains('lastName'),'doesnt contains the key lastName');
        System.assertEquals(true, responseBody.contains('firstName'),'doesnt contains the key firstName');
        System.assertEquals(true, responseBody.contains('retainMessage'),'doesnt contains the key retainMessage');
        System.assertEquals(true, responseBody.contains('delete'),'doesnt contains the key delete');
        System.assertEquals(true, responseBody.contains('download'),'doesnt contains the key download');
        System.assertEquals(true, responseBody.contains('change'),'doesnt contains the key change');
        System.assertEquals(true, responseBody.contains('view'),'doesnt contains the key view');

        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_RESIDENT_EU),'doesnt contains the value' + CASE_GDPR_DESCRIPTION_RESIDENT_EU);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_VIEW),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_VIEW);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_CHANGE),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_CHANGE);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_DOWNLOAD),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_DOWNLOAD);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_DELETE),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_DELETE);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_RETAIN_ANALYTICS),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_RETAIN_ANALYTICS);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_RETAIN_GLIP),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_RETAIN_GLIP);
        String firstName = CASE_GDPR_DESCRIPTION_NAME_PRIVACY_ACTIONS.split(' ')[0];
        String lastName = CASE_GDPR_DESCRIPTION_NAME_PRIVACY_ACTIONS.split(' ')[1];

        System.assertEquals(true, responseBody.contains(firstName),' doesnt contains the value' + firstName);
        System.assertEquals(true, responseBody.contains(lastName),' doesnt contains the value' + lastName);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_EMAIL_PRIVACY_ACTIONS),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_EMAIL_PRIVACY_ACTIONS);
        System.assertEquals(true, responseBody.contains(CASE_GDPR_DESCRIPTION_PHONE_PRIVACY_ACTIONS),' doesnt contains the value' + CASE_GDPR_DESCRIPTION_PHONE_PRIVACY_ACTIONS);

        //Make sure response contains Case Timezone
        System.assertEquals(true, responseBody.contains(CASE_TIMEZONE));
    }
}