@isTest
private class CaseCreateRCEventsRestServiceTest {

    private static final String API_ONLY_PROFILE_NAME = 'API Only';
    private static final String USER_USERNAME = 'RCEvents_SupportCommunityCaseListTestUser@rc.com';
    private static final String USER_EMAIL = 'useremail@rc.com';
    private static final String USER_FIRST_NAME = 'firstname';
    private static final String USER_LAST_NAME = 'lastname';
    private static final String USER_LANGUAGE = 'en_US';

    private static final String CONTACT_EMAIL = 'contactemail@rc.com';
    private static final String CONTACT_FIRST_NAME = 'firstname';
    private static final String CONTACT_LAST_NAME = 'lastname';
    private static Account defaultAccount;
    private static Contact defaultContact;
    private static Contact testContact;

    private static Contact testUser = null;

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
        
        
        // Create the default Account
        defaultAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account',
                        Account.RC_User_ID__c => '278834020',
                        Account.BillingCountry => 'United Kingdom',
                        Account.Website => 'ab-soft.com',
                        Account.RC_Brand__c => 'RingCentral'
                        }
            )
            .create()
            .getRecord();
        
        // Create the default Contact
        defaultContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Rc_events',
                    Contact.LastName => 'Attendee',
                    Contact.Email => 'rc_events.attendee@ringcentral.com',
                    Contact.AccountId => defaultAccount.Id,
                    Contact.Phone => '9988778898'
                    })
            .create()
            .getRecord();

        testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_LAST_NAME,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.AccountId => defaultAccount.Id,
                    Contact.Phone => '9988778898'
                    })
            .create()
            .getRecord();
        
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
        }     
        
    }

    @IsTest
    private static void createCaseValidContact() {

        RestRequest request = new RestRequest();
        request.requestURI = System.URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-events-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('firstName', CONTACT_FIRST_NAME);
        params.put('lastName', CONTACT_LAST_NAME);
        params.put('email', CONTACT_EMAIL);
        params.put('isRingCentralEventsAccount', 'Yes');
        params.put('role', 'An Attendee');
        params.put('paymentPlan', 'Events 100');
        params.put('myEventIs', '');
        params.put('subject', 'Test case');
        params.put('description', 'Test case data created inside apex tests');
        params.put('severityLevel', 'Level 4 - Medium');
        params.put('selectedProduct', 'Events');
        params.put('selectedProduct2', 'Stage');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            CaseCreateRCEventsRestService.createCase();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        System.assertEquals(true,
        RestContext.response.responseBody.toString().contains(CaseCreateAPIController.SUCCESS_MESSAGE_POST),
        RestContext.response.responseBody.toString()
        ); 
        System.assertEquals(200, RestContext.response.statusCode,'Expected status code 200 for valid payload');

        String caseId = responseMap.get(CaseCreateAPIController.CASE_ID).toString();

        List<Case> caseDetail = [Select id, contact.name, contact.email, RecordTypeName__c,OwnerId, Owner.Name from Case where Id = :caseId];

            
            System.assert(caseDetail.size() > 0, 'No case created');

            System.assertEquals(CONTACT_FIRST_NAME + ' ' + CONTACT_LAST_NAME, caseDetail[0].Contact.Name, 'Contact name should match');
            System.assertEquals(CONTACT_EMAIL, caseDetail[0].Contact.Email, 'Contact email should match');
            System.assertEquals('Support_Case', caseDetail[0].RecordTypeName__c, 'Record type should be Support Case');
        
    }

    @IsTest
    private static void createCaseInvalidContact() {

        RestRequest request = new RestRequest();
        request.requestURI = System.URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-events-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('firstName', 'Test');
        params.put('lastName', 'test');
        params.put('email', 'testinvalid@test.com');
        params.put('isRingCentralEventsAccount', 'Yes');
        params.put('role', 'An Event Organizer');
        params.put('paymentPlan', 'Events 100');
        params.put('myEventIs', 'Live');
        params.put('subject', 'Test case');
        params.put('description', 'Test case data created inside apex tests');
        params.put('severityLevel', 'Level 4 - Medium');
        params.put('selectedProduct', 'Events');
        params.put('selectedProduct2', 'Stage');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            CaseCreateRCEventsRestService.createCase();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        System.assertEquals(true,
        RestContext.response.responseBody.toString().contains(CaseCreateAPIController.SUCCESS_MESSAGE_POST),
        RestContext.response.responseBody.toString()
        ); 
        System.assertEquals(200, RestContext.response.statusCode,'Expected status code 200 for valid payload');

        
        String caseId = responseMap.get(CaseCreateAPIController.CASE_ID).toString();

        List<Case> caseDetail = [Select id,contactid,accountid, contact.name, contact.email, RecordTypeName__c,OwnerId, Owner.Name from Case where Id = :caseId];

            
        System.assert(caseDetail.size() > 0, 'No case created');

        System.assert(caseDetail[0].ContactId != null, 'Default Contact should be mapped');
        System.assert(caseDetail[0].AccountId != null, 'Account should be mapped');
        System.assertEquals('Support_Case', caseDetail[0].RecordTypeName__c, 'Record type should be Support Case');
    
    }

    @IsTest
    private static void createCaseWithInvalidPayload() {
        RestRequest request = new RestRequest();
        request.requestURI = System.URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-events-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        // Invalid payload
        RestContext.request.requestBody = Blob.valueOf('{"invalidField":"invalidValue"}');

        // Call the method to test
        Test.startTest();
            CaseCreateRCEventsRestService.createCase();
        Test.stopTest();

        System.assert(RestContext.response.responseBody.toString().contains('error'), 'Expected error response but actual - ' + RestContext.response.responseBody.toString());
        System.assertEquals(400, RestContext.response.statusCode, 'Expected status code 400 for invalid payload');
    }

    @IsTest
    private static void createCaseWithMissingFields() {
        RestRequest request = new RestRequest();
        request.requestURI = System.URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-events-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        // Missing required fields
        Map<String, Object> params = new Map<String, Object>();
        params.put('firstName', 'test');
        params.put('lastName', 'test');
        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            CaseCreateRCEventsRestService.createCase();
        Test.stopTest();

        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());

        System.assert(resMap.get('errorMessage').toString().contains(CaseCreateAPIController.ERROR_MESSAGE_NAME_EMAIL_ARE_REQUIRED), 'Expected missing fields error but actual - ' + resMap.get('errorMessage'));
        System.assertEquals(400, RestContext.response.statusCode,'Expected status code 400 for invalid payload');
    }
    
}