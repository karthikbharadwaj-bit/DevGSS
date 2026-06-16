@isTest
public with sharing class CaseEscalateRestService_Test {
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

    private static Case createCase() {
        return (Case) new sObjectBuilder(Case.sObjectType)
            .setFields(
                new Map<sObjectField, Object>{
                    Case.IsEscalated => false,
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject => 'Test case',
                    Case.Status => 'New',
                    Case.OwnerId => apiOnlyTestUser.Id
                }
            )
            .create()
            .getRecord();
    }

    @isTest
    private static void escalateCase_whenAllParametersAreCorrect_shouldCreateCaseCommentAndEscalateCase() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-escalate';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase();
        Test.setCreatedDate(caseToTest.Id, Datetime.now().addDays(-5));
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('justification', 'This is a text for justification parameter. It must be at least 50 characters.');
        params.put('caseId', caseToTest.Id);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseEscalateRestService.escalateCase();
        }
        Test.stopTest();

        List<CaseComment> caseComments = (List<CaseComment>) new CaseCommentSelector()
            .selectCaseCommentsByCaseId(new Object[]{caseToTest.Id})
            .executeQuery();

        System.assertEquals(1, caseComments.size(), 'There should be a case comment.');
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseEscalateAPIController.SUCCESS_MESSAGE_POST), 
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void escalateCase_whenJustificationParemeterIsTooShort_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-escalate';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase();
        Test.setCreatedDate(caseToTest.Id, Datetime.now().addDays(-5));
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('justification', 'This justification text is too short :(');
        params.put('caseId', caseToTest.Id);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseEscalateRestService.escalateCase();
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
        System.assertEquals(false, caseToTest.IsEscalated);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(EscalateCaseController.JUSTIFICATION_TOO_SHORT));
    }
    @isTest
    private static void escalateCase_whenJustificationParemeterIsTooLong_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-escalate';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase();
        Test.setCreatedDate(caseToTest.Id, Datetime.now().addDays(-5));
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('justification', StringHelper.getRandomString(EscalateCaseController.MAX_SIZE_JUSTIFICATION + 1));
        params.put('caseId', caseToTest.Id);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseEscalateRestService.escalateCase();
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
        System.assertEquals(false, caseToTest.IsEscalated);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(EscalateCaseController.JUSTIFICATION_TOO_LONG));
    }
    @isTest
    private static void escalateCase_whenCaseIdIsInvalid_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-escalate';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('justification', 'This is a text for justification parameter. It must be at least 50 characters.');
        params.put('caseId', 'Invalid case id');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseEscalateRestService.escalateCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseEscalateAPIController.BAD_REQUEST_INVALID_CASEID), 
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void escalateCase_whenRequiredParametersAreMissing_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-escalate';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase();
        Test.setCreatedDate(caseToTest.Id, Datetime.now().addDays(-5));

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('caseId', caseToTest.Id);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseEscalateRestService.escalateCase();
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
        System.assertEquals(false, caseToTest.IsEscalated);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseEscalateAPIController.BAD_REQUEST_REQUIRED_PARAMETER_MISSING), 
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void escalateCase_whenCaseIsAlreadyEscalated_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-escalate';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase();
        
        Test.setCreatedDate(caseToTest.Id, Datetime.now().addDays(-5));

        caseToTest.IsEscalated = true;
        update caseToTest;


        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('justification', 'This is a text for justification parameter. It must be at least 50 characters.');
        params.put('caseId', caseToTest.Id);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseEscalateRestService.escalateCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseHelper.getEscalateErrorMessage(caseToTest)), 
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void escalateCase_whenCaseCannotBeEscaletedBecauseSLA_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-escalate';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase();
        update caseToTest;

        Test.setCreatedDate(caseToTest.Id, Datetime.now().addDays(-1));

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('caseId', caseToTest.Id);
        params.put('justification', 'This is a text for justification parameter. It must be at least 50 characters.');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseEscalateRestService.escalateCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseHelper.getEscalateErrorMessage(caseToTest)), 
            RestContext.response.responseBody.toString()
        );
    }
    @isTest
    private static void escalateCase_whenCaseIsClosed_shouldThrowAnErrorMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-escalate';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Case caseToTest = createCase();
        caseToTest.CloseCustomerSupportLevel1__c = 'Faxing';
        caseToTest.Status = 'Closed';
        update caseToTest;

        Test.setCreatedDate(caseToTest.Id, Datetime.now().addDays(-1));

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);
        params.put('caseId', caseToTest.Id);
        params.put('justification', 'This is a text for justification parameter. It must be at least 50 characters.');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseEscalateRestService.escalateCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseHelper.getEscalateErrorMessage(caseToTest)), 
            RestContext.response.responseBody.toString()
        );
    }
}