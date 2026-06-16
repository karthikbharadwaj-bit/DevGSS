@isTest
public with sharing class CaseInfoRestService_Test {

    private static final String API_USER_PROFILE_NAME = 'Com Integration Profile';

    private static final String USER_USERNAME = 'RC_SupportCommunityCaseListTestUser@rc.com';
    private static final String USER_EMAIL = 'useremail@rc.com';
    private static final String USER_FIRST_NAME = 'firstname';
    private static final String USER_LAST_NAME = 'lastname';
    private static final String USER_LANGUAGE = 'en_US';
    private static final String RC_USER_ID = '1234567890';
    private static final String NEW_EMAIL = 'new@rc.com';
    private static final String NEW_FIRST_NAME = 'New First Name';
    private static final String NEW_LAST_NAME = 'New Last Name';
    private static final String NEW_PHONE = '1234567890';
    private static final String APIUSER_USERNAME = 'ApiOnlyTestUser@rc.com';
    private static final String APIUSER_EMAIL = 'apiuseremail@rc.com';
    private static final String APIUSER_FIRST_NAME = 'apifirstname';
    private static final String APIUSER_LAST_NAME = 'apilastname';

    private static final String CONTACT_FIRST_NAME = USER_FIRST_NAME;
    private static final String CONTACT_LAST_NAME = USER_LAST_NAME;
    private static final String CONTACT_EMAIL = USER_EMAIL;
    private static final String CONTACT_PHONE = '77777777';
    private static final Decimal CONTACT_PHONE_EXT = 777;

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

    @testSetup
    private static void setupData() {
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
                Account.RC_User_ID__c => RC_USER_ID,
                Account.RC_Brand__c => 'RingCentral'
            })
            .create()
            .getRecords();
            
        new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => CONTACT_FIRST_NAME,
                Contact.LastName => CONTACT_LAST_NAME,
                Contact.Email => CONTACT_EMAIL,
                Contact.Phone => CONTACT_PHONE,
                Contact.Phone_Ext__c => CONTACT_PHONE_EXT,
                Contact.AccountId => portalAccounts[0].Id
            })
            .create();
    
        new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.LastName => APIUSER_LAST_NAME,
                User.FirstName => APIUSER_FIRST_NAME,
                User.CommunityNickname => APIUSER_LAST_NAME,
                User.Email => APIUSER_EMAIL,
                User.Username => APIUSER_USERNAME,
                User.LanguageLocaleKey => USER_LANGUAGE,
                User.ProfileId => apiProfile.Id
            })
            .create();
            
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet pSet = (PermissionSet) new PermissionSetSelector()
                .selectPermissionSetsByName(new Object[]{new String[]{'AEM_Permissions'}})
                .executeQuery()[0];
                
            new SObjectBuilder(PermissionSetAssignment.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    PermissionSetAssignment.AssigneeId => apiOnlyTestUser.id,
                    PermissionSetAssignment.PermissionSetId => pSet.Id
                })
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
                accountid = portalAccounts[0].Id,
                accountaccesslevel = 'Edit',
                OpportunityAccessLevel = 'Edit',
                CaseAccessLevel  = 'Edit',
                ContactAccessLevel = 'Edit'
            );
        }
    }

    @isTest
    private static void testGetContactInfo() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseInfo';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USER_ID);
        request.params.put('email', USER_EMAIL);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseInfoRestService.getContactInfo();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseInfoAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetContactInfoWithContact() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseInfo';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USER_ID);
        request.params.put('email', USER_EMAIL);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseInfoRestService.getContactInfo();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseInfoAPIController.SUCCESS_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetContactInfoMissingParam() {

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseInfo';
        request.httpMethod = 'GET';
        request.params.put('uid', RC_USER_ID);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseInfoRestService.getContactInfo();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetContactInfoWrongParams() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseInfo';
        request.httpMethod = 'GET';
        request.params.put('uid', '123124');
        request.params.put('email', USER_EMAIL);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseInfoRestService.getContactInfo();
            }
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.ERROR_MESSAGE_INVALID_USERID_OR_EMAIL),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testGetContactInfoWithoutUser() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseInfo';
        request.httpMethod = 'GET';
        request.params.put('uid', '123124');
        request.params.put('email', USER_EMAIL);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseInfoRestService.getContactInfo();
            }
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.ERROR_MESSAGE_INVALID_USERID_OR_EMAIL),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void testPostContactInfoInsertContact() {

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseInfo';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', RC_USER_ID);
        params.put('email', USER_EMAIL);
        params.put('firstName', NEW_FIRST_NAME);
        params.put('lastName', NEW_LAST_NAME);
        params.put('phone', NEW_PHONE);
        params.put('contactEmail', NEW_EMAIL);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
                CaseInfoRestService.postContactInfo();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseInfoAPIController.SUCCESS_MESSAGE_POST),
            RestContext.response.responseBody.toString()
        );

        Set<String> firstNameSet = new Set<String>();
        Set<String> lastNameSet = new Set<String>();
        Set<String> emailSet = new Set<String>();
        firstNameSet.add(NEW_FIRST_NAME);
        lastNameSet.add(NEW_LAST_NAME);
        emailSet.add(NEW_EMAIL);

        List<Contact> contacts = new ContactSelector().selectContactsByEmail(new List<Object>{
            firstNameSet, lastNameSet, emailSet
        }).executeQuery();

        Contact newContact = contacts[0];
        System.assertEquals(NEW_FIRST_NAME, newContact.FirstName);
        System.assertEquals(NEW_LAST_NAME, newContact.LastName);
        System.assertEquals(NEW_EMAIL, newContact.Email);

    }

    @isTest
    private static void testPostContactInfoUpdateContact() {

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseInfo';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', RC_USER_ID);
        params.put('email', USER_EMAIL);
        params.put('firstName', NEW_FIRST_NAME);
        params.put('lastName', NEW_LAST_NAME);
        params.put('phone', NEW_PHONE);
        params.put('contactEmail', USER_EMAIL);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseInfoRestService.postContactInfo();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'response:\n' + RestContext.response.responseBody.toString());
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseInfoAPIController.SUCCESS_MESSAGE_POST),
            RestContext.response.responseBody.toString()
        );

        Set<String> firstNameSet = new Set<String>();
        Set<String> lastNameSet = new Set<String>();
        Set<String> emailSet = new Set<String>();
        firstNameSet.add(NEW_FIRST_NAME);
        lastNameSet.add(NEW_LAST_NAME);
        emailSet.add(USER_EMAIL);

        List<Contact> contacts = new ContactSelector().selectContactsByEmail(new List<Object>{
            firstNameSet, lastNameSet, emailSet
        }).executeQuery();
        if(contacts.size() > 0){
        Contact newContact = contacts[0];
        System.assertEquals(NEW_FIRST_NAME, newContact.FirstName);
        System.assertEquals(NEW_LAST_NAME, newContact.LastName);
        System.assertEquals(USER_EMAIL, newContact.Email);
        }

    }

    @isTest
    private static void testPostContactInfoInsertContactWithoutUser() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseInfo';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', RC_USER_ID);
        params.put('email', USER_EMAIL);
        params.put('firstName', NEW_FIRST_NAME);
        params.put('lastName', NEW_LAST_NAME);
        params.put('phone', NEW_PHONE);
        params.put('contactEmail', NEW_EMAIL);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseInfoRestService.postContactInfo();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseInfoAPIController.SUCCESS_MESSAGE_POST),
            RestContext.response.responseBody.toString()
        );

        Set<String> firstNameSet = new Set<String>();
        Set<String> lastNameSet = new Set<String>();
        Set<String> emailSet = new Set<String>();
        firstNameSet.add(NEW_FIRST_NAME);
        lastNameSet.add(NEW_LAST_NAME);
        emailSet.add(NEW_EMAIL);

        List<Contact> contacts = new ContactSelector().selectContactsByEmail(new List<Object>{
            firstNameSet, lastNameSet, emailSet
        }).executeQuery();

        Contact newContact = contacts[0];
        System.assertEquals(NEW_FIRST_NAME, newContact.FirstName);
        System.assertEquals(NEW_LAST_NAME, newContact.LastName);
        System.assertEquals(NEW_EMAIL, newContact.Email);

    }

    @isTest
    private static void testPostContactInfoUpdateContactWithoutUser() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseInfo';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', RC_USER_ID);
        params.put('email', USER_EMAIL);
        params.put('firstName', NEW_FIRST_NAME);
        params.put('lastName', NEW_LAST_NAME);
        params.put('phone', NEW_PHONE);
        params.put('contactEmail', USER_EMAIL);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseInfoRestService.postContactInfo();
            }
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'response:\n' + RestContext.response.responseBody.toString());
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseInfoAPIController.SUCCESS_MESSAGE_POST),
            RestContext.response.responseBody.toString()
        );

        Set<String> firstNameSet = new Set<String>();
        Set<String> lastNameSet = new Set<String>();
        Set<String> emailSet = new Set<String>();
        firstNameSet.add(NEW_FIRST_NAME);
        lastNameSet.add(NEW_LAST_NAME);
        emailSet.add(USER_EMAIL);

        List<Contact> contacts = new ContactSelector().selectContactsByEmail(new List<Object>{
            firstNameSet, lastNameSet, emailSet
        }).executeQuery();
        if(contacts.size() > 0){
        Contact newContact = contacts[0];
        System.assertEquals(NEW_FIRST_NAME, newContact.FirstName);
        System.assertEquals(NEW_LAST_NAME, newContact.LastName);
        System.assertEquals(USER_EMAIL, newContact.Email);
        }
    }

    @isTest
    private static void testPostContactInfoMissingParams() {

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseInfo';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', RC_USER_ID);
        params.put('email', USER_EMAIL);
        params.put('firstName', NEW_FIRST_NAME);
        params.put('lastName', NEW_LAST_NAME);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseInfoRestService.postContactInfo();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, 
            RestContext.response.responseBody.toString().contains(CaseInfoRestService.BAD_REQUEST_POST),
            RestContext.response.responseBody.toString()
        );
    }
}