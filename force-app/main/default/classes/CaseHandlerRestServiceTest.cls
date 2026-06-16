@isTest
public with sharing class CaseHandlerRestServiceTest {

    private static final String UID = '123456789';
    private static final String CONTACT_FIRSTNAME = 'firstName';
    private static final String CONTACT_LASTNAME = 'lastName';
    private static final String CONTACT_EMAIL = 'test@test.com';
    private static final String APIONLY_USERNAME = 'APIONLY_USERNAME@test.com';

    private static User apiOnlyTestUser {
        get {
            if (apiOnlyTestUser == null) {
                apiOnlyTestUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{APIONLY_USERNAME}})
                    .selectFields(new List<String>{'ContactId', 'AccountId'})
                    .executeQuery()
                    .get(0);
            }
            return apiOnlyTestUser;
        }
        private set;
    }

    @TestSetup
    static void makeData(){
        Profile apiOnlyProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{'API Only'})
            .executeQuery()
            .get(0);

        new SObjectBuilder(User.SObjectType).setFields(new Map<SObjectField, Object>{
            User.LastName => 'lastName',
            User.FirstName => 'fisrtName',
            User.CommunityNickname => 'lastName',
            User.Email => APIONLY_USERNAME,
            User.Username => APIONLY_USERNAME,
            User.LanguageLocaleKey => 'en_US',
            User.ProfileId => apiOnlyProfile.Id
        })
        .create();
    }

    
    @isTest
    private static void actionClose_whenAllDataIsCorrect_shouldCloseTheCase() {
        Account acc = CaseHandlerCloseTest.createAccount();
        Contact cont = CaseHandlerCloseTest.createContact(acc);
        Case aCase = CaseHandlerCloseTest.createCase(acc, cont);
        
        Group nonTellusGroup = (Group) new GroupSelector()
            .selectGroupBasedOnDeveloperNames(new Object[]{new String[]{'Non_Telus_Users'}})
            .executeQuery()[0];

        insert new AccountShare(
            userorgroupid = nonTellusGroup.Id,
            accountid = acc.Id,
            accountaccesslevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            CaseAccessLevel  = 'Edit',
            ContactAccessLevel = 'Edit'
        );

        System.runAs(new User(Id = UserInfo.getUserId())){
            new SObjectBuilder(GroupMember.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    GroupMember.GroupId => nonTellusGroup.Id,
                    GroupMember.UserOrGroupId => apiOnlyTestUser.id
                })
                .create();
        }
        
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseHandler';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('action', 'close');
        params.put('email', CaseHandlerCloseTest.CONTACT_EMAIL);
        params.put('uid', CaseHandlerCloseTest.UID);
        params.put('caseId', aCase.Id);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseHandlerRestService.caseHandler();
            }
        Test.stopTest();
        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());

        aCase = CaseHandlerCloseTest.getCase();

        system.assertEquals(true, resMap.get(CaseAPIUtil.SUCCESS_FIELD_NAME), 'Invalid success value');
        system.assertEquals(CaseHandlerClose.SUCCESS_MESSAGE, resMap.get(CaseAPIUtil.MESSAGE_FIELD_NAME), 'Invalid success message');
        system.assertEquals(CaseHandlerClose.STATUS_CLOSED_BY_CUSTOMER, aCase.Status, 'Invalid status field value');
    }

    @isTest
    private static void actionClose_whenRequiredParametersAreNotPopulated_shouldThrowAnException() {
        Account acc = CaseHandlerCloseTest.createAccount();
        Contact cont = CaseHandlerCloseTest.createContact(acc);
        Case aCase = CaseHandlerCloseTest.createCase(acc, cont);
        
        Group nonTellusGroup = (Group) new GroupSelector()
            .selectGroupBasedOnDeveloperNames(new Object[]{new String[]{'Non_Telus_Users'}})
            .executeQuery()[0];

        insert new AccountShare(
            userorgroupid = nonTellusGroup.Id,
            accountid = acc.Id,
            accountaccesslevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            CaseAccessLevel  = 'Edit',
            ContactAccessLevel = 'Edit'
        );

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseHandler';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseHandlerRestService.caseHandler();
            }
        Test.stopTest();
        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());

        aCase = CaseHandlerCloseTest.getCase();

        String response = RestContext.response.responseBody.toString();

        system.assert(
            response.contains(CaseHandlerStrategy.INVALID_ACTION), 
            'Invalid exception message, actual: ' + response + '\nExpected: ' + CaseHandlerStrategy.INVALID_ACTION
        );
        system.assertNotEquals(CaseHandlerClose.STATUS_CLOSED_BY_CUSTOMER, aCase.Status, 'Invalid status field value');
    }
}