@isTest
public with sharing class CaseReopenRestService_Test {
    private static final String API_ONLY_PROFILE_NAME = 'API Only';

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
    
    private static final String JUSTIFICATION_PARAMETER = 'This is a text for justification parameter. It must be at least 50 characters.';
    private static final String FUNCTION_PARAMETER = 'Other reason';

    public static final String SUBJECT_HAS_ALREADY_BEEN_REOPENED = 'Case has already been reopened';

    private static User apiOnlyTestUser {
        get {
            if (apiOnlyTestUser == null) {
                apiOnlyTestUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{USER_USERNAME}})
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

        Profile apiOnlyProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{API_ONLY_PROFILE_NAME})
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
                Account.RC_User_ID__c => '123456789'
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
                    Contact.Contact_Status__c => '2. Contacted',
                    Contact.AccountId => portalAccounts[0].Id
                }
            )
            .create()
            .getRecords();

        new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => USER_LAST_NAME,
                    User.FirstName => USER_FIRST_NAME,
                    User.CommunityNickname => USER_LAST_NAME,
                    User.Email => USER_EMAIL,
                    User.Username => USER_USERNAME,
                    User.LanguageLocaleKey => USER_LANGUAGE,
                    User.ProfileId => apiOnlyProfile.Id
                }
            )
            .create();

    }

    private static Case createCase(String subject) {
        return (Case) new sObjectBuilder(Case.sObjectType)
            .setFields(
                new Map<sObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject => subject,
                    Case.Status =>  CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE,
                    Case.OwnerId => apiOnlyTestUser.Id
                }
            )
            .create()
            .getRecord();
    }

    @isTest
    private static void reopenCase_whenAllParametersAreCorrect_shouldCreateCaseCommentAndReopenCase() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseReopen';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase('Test case');
        caseToTest.ContactId = ((List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery()
        )[0].Id;
        update caseToTest;
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('justification', JUSTIFICATION_PARAMETER);
        params.put('function', FUNCTION_PARAMETER);
        params.put('caseId', caseToTest.Id);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        TriggerHandler.BY_PASS_PARTNERCOMM_ON_INSERT = true;
        TriggerHandler.BY_PASS_PARTNERCOMM_ON_UPDATE = true;

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseReopenRestService.reopenCase();
        }
        Test.stopTest();

        List<CaseComment> caseComments = (List<CaseComment>) new CaseCommentSelector()
            .selectCaseCommentsByCaseId(new Object[]{caseToTest.Id})
            .executeQuery();

        caseToTest = (Case) new CaseSelector()
            .selectCaseForReopening(new Object[]{caseToTest.Id})
            .executeQuery()[0];

        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseReopenAPIController.SUCCESS_MESSAGE_POST), 
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(1, caseComments.size(), 'There should be a case comment.');
        System.assertEquals(CaseHelper.CASE_STATUS_REOPENED, caseToTest.Status, 'Case status should be Reopened');
    }
    @isTest
    private static void reopenCase_whenJustificationParemeterIsTooShort_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseReopen';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase('Test case');
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('justification', 'This justification text is too short :(');
        params.put('function', ReopenCaseController.OTHER_REASON_STRING);
        params.put('caseId', caseToTest.Id);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseReopenRestService.reopenCase();
        }
        Test.stopTest();

        List<CaseComment> caseComments = (List<CaseComment>) new CaseCommentSelector()
            .selectCaseCommentsByCaseId(new Object[]{caseToTest.Id})
            .executeQuery();

        caseToTest = (Case) new CaseSelector()
            .selectCaseForEscalating(new Object[]{caseToTest.Id})
            .executeQuery()[0];

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(0, caseComments.size(), 'There shouldn\'t be case comments.');
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseReopenAPIController.BAD_REQUEST_JUSTIFICATION_PARAMETER));
    }
    @isTest
    private static void reopenCase_whenCaseIdIsInvalid_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseReopen';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('justification', JUSTIFICATION_PARAMETER);
        params.put('function', FUNCTION_PARAMETER);
        params.put('caseId', 'Invalid case id');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseReopenRestService.reopenCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseReopenAPIController.BAD_REQUEST_CASE_NOT_FOUND), 
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void reopenCase_whenRequiredParametersAreMissing_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseReopen';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase('Test case');

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('caseId', caseToTest.Id);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseReopenRestService.reopenCase();
        }
        Test.stopTest();

        List<CaseComment> caseComments = (List<CaseComment>) new CaseCommentSelector()
            .selectCaseCommentsByCaseId(new Object[]{caseToTest.Id})
            .executeQuery();

        caseToTest = (Case) new CaseSelector()
            .selectCaseForEscalating(new Object[]{caseToTest.Id})
            .executeQuery()[0];

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(0, caseComments.size(), 'There shouldn\'t be case comments.');
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseReopenAPIController.BAD_REQUEST_REQUIRED_PARAMETER_MISSING), 
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void reopenCase_whenCaseIsAlreadyReopen_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseReopen';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase('Test case');

        caseToTest.Status = 'Reopened';
        update caseToTest;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('justification', JUSTIFICATION_PARAMETER);
        params.put('function', FUNCTION_PARAMETER);
        params.put('caseId', caseToTest.Id);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseReopenRestService.reopenCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseHelper.getReopenErrorMessage(caseToTest)), 
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void reopenCase_whenCaseIsNotClosed_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseReopen';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase('Test case');
        caseToTest.Status = 'New';
        update caseToTest;


        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('caseId', caseToTest.Id);
        params.put('justification', JUSTIFICATION_PARAMETER);
        params.put('function', FUNCTION_PARAMETER);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseReopenRestService.reopenCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseHelper.getReopenErrorMessage(caseToTest)), 
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void reopenCase_whenReasonIsOtherReasonAndJustificationEmpty_shouldThrowError(){
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseReopen';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase('Test case');

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('caseId', caseToTest.Id);
        params.put('justification', '');
        params.put('function', ReopenCaseController.OTHER_REASON_STRING);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        TriggerHandler.BY_PASS_PARTNERCOMM_ON_INSERT = true;
        TriggerHandler.BY_PASS_PARTNERCOMM_ON_UPDATE = true;

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseReopenRestService.reopenCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseReopenAPIController.BAD_REQUEST_JUSTIFICATION_PARAMETER), 
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void reopenCase_whenCaseHasAlreadyBeenReopened_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseReopen';
        request.httpMethod = 'POST';
        RestContext.request = request;

        TriggerHandler.BY_PASS_PARTNERCOMM_ON_INSERT = true;
        TriggerHandler.BY_PASS_PARTNERCOMM_ON_UPDATE = true;

        Case caseToTest = createCase(SUBJECT_HAS_ALREADY_BEEN_REOPENED);
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('justification', JUSTIFICATION_PARAMETER);
        params.put('function', FUNCTION_PARAMETER);
        params.put('caseId', caseToTest.Id);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseReopenRestService.reopenCase();
        }
        Test.stopTest();

        caseToTest = (Case) new CaseSelector()
            .selectCaseForReopening(new Object[]{caseToTest.Id})
            .executeQuery()[0];

        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseHelper.CASE_HAS_ALREADY_BEEN_REOPENED_TEXT), 
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(400, RestContext.response.statusCode, 'Status code should be 400');
        System.assertEquals(CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE, caseToTest.Status, 'Case status should be Closed');
    }
}