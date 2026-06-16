@IsTest
private class CaseCreateDataSubjectRestServiceTest {

    private static final String API_ONLY_PROFILE_NAME = 'API Only';

    private static final String USER_USERNAME = 'GDPRIntegrationTestUser@rc.com';
    private static final String USER_EMAIL = 'useremail@rc.com';
    private static final String USER_FIRST_NAME = 'firstname';
    private static final String USER_LAST_NAME = 'lastname';
    private static final String USER_LANGUAGE = 'en_US';

    private static final String DSR_UID = null;

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
        
        
        // Create the fixed Account
        Account dsrAccounts = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Fixed DSR Account',
                        Account.RC_User_ID__c => '1822028005',
                        Account.BillingCountry => 'United Kingdom',
                        Account.Website => 'ab-soft.com',
                        Account.RC_Brand__c => 'RingCentral'
                        }
            )
            .create()
            .getRecord();
        
        // Create the fixed Contact
        Contact dsrContacts = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Fixed',
                    Contact.LastName => 'DSR Contact',
                    Contact.Email => 'form-script@ringcentral.com',
                    Contact.AccountId => dsrAccounts.Id,
                    Contact.Phone => '9988778898'
                    })
            .create()
            .getRecord();
        
        // Ensure the Custom Metadata record exists (manually created in org)
        System.assertNotEquals(null, [
            SELECT Fixed_Account_UID__c, Fixed_Contact_Email__c 
            FROM DSR_Fixed_Records__mdt 
            LIMIT 1
        ]);
        
        
        
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
                .selectPermissionSetsByName(new Object[]{new String[]{'GDPR_Permissions'}})
                .executeQuery().get(0);
            
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
    private static void createCaseRingCentralUser() {

        RestRequest request = new RestRequest();
        request.requestURI = System.URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-dsr-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('firstName', USER_FIRST_NAME);
        params.put('lastName', USER_LAST_NAME);
        params.put('email', USER_EMAIL);
        params.put('privacyFirstName', 'privacy ' + USER_FIRST_NAME);
        params.put('privacyLastName', 'privacy ' + USER_LAST_NAME);
        params.put('privacyEmail', 'privacy@mail.com');
        params.put('action', 'Download');
        params.put('changeAdditionalInformation', 'Yes');
        params.put('country', 'Argentina');
        params.put('state', 'CABA');
        params.put('additionalInformation', 'Additional Information');
        params.put('roleName', 'admin');
        params.put('relation',CaseCreateDataSubjectRestService.USER_ROLE_RINGCENTRAL_USER);
        params.put('isRingCentralEventsAccount', 'Yes');
        params.put('isNiceContactCenterAccount', 'Yes');
        params.put('niceCCContactIds', '12344');
        params.put('niceCCAdditionalInfo', 'Hey testing contact');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            CaseCreateDataSubjectRestService.createCase();
            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());

        List<Account> accountRecords = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<String>{ 'Id' })
            .executeQuery();

        System.assertEquals(1, accountRecords.size(), 'We should not create any new account'); 

        Account dsrAccountRecord = accountRecords.get(0);

        List<Contact> contactRecords = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectFields(new List<String>{ 'FirstName', 'LastName', 'Email', 'MailingCountry', 'MailingState', 'AccountId' })
            .executeQuery();

        System.assertEquals(1, contactRecords.size(), 'Only one contact record should be created'); 

        Contact dsrContactRecord = contactRecords.get(0);

       
        System.assertEquals(dsrAccountRecord.Id, dsrContactRecord.AccountId, 'Got wrong account'); 

        List<Case> dsrCaseRecords = (List<Case>) new CaseSelector()
            .selectCasesForApproval(new List<Object>{ new List<Id>{ (Id) responseMap.get('caseId') } })
            .selectFields(new List<String>{
                'ContactId', 'AccountId', 'Subject', 'OwnerId', 'Case_Severity__c', 'Priority',
                'Case_Contact_Email__c', 'Description', 'RecordTypeId', 'IsVisibleInSelfService'
            })
            .executeQuery();

        System.assertEquals(1, dsrCaseRecords.size(), 'Only one case should be created'); 

        Case dsrCaseRecord = dsrCaseRecords.get(0);
        
        String description = 'Relation : RingCentral User'
        + '\nFirst Name : ' + USER_FIRST_NAME
        + '\nLast Name : ' + USER_LAST_NAME
        + '\nEmail : ' + USER_EMAIL
        + '\nPrivacy First Name : privacy ' + USER_FIRST_NAME
        + '\nPrivacy Last Name : privacy ' + USER_LAST_NAME
        + '\nPrivacy Email : privacy@mail.com'
        + '\nForm Type: admin'
        + '\nAction : Change personal information'
        + '\nChange Details : Please update my details'
        + '\nRingCentral Events Account: Yes'
        + '\nNICE Contact Center account : Yes'
        + '\nNICE Contact Center account contact IDs : 12344'
        + '\nNICE Contact Center account additional information : Testing contact center additional info'
        + '\nCountry : Argentina'
        + '\nState : CABA'
        + '\nAdditional Information : Testing additional information';

        System.assertEquals(dsrContactRecord.Id, dsrCaseRecord.ContactId, 'Got wrong contact');
        System.assertEquals(dsrAccountRecord.Id, dsrCaseRecord.AccountId, 'Got wrong account');
        System.assertEquals('Data Subject Request by ' + USER_EMAIL + ' requesting admin', dsrCaseRecord.Subject, 'Got wrong subject');
        System.assertEquals('Medium', dsrCaseRecord.Priority, 'Got wrong priority');
        System.assertEquals(USER_EMAIL, dsrCaseRecord.Case_Contact_Email__c, 'Got wrong case contact email');
        System.assertEquals(CaseHelper.RT_ID_GDPR_REQUEST, dsrCaseRecord.RecordTypeId, 'Got wrong record type');
        System.assertEquals(1, emailInvocations, 'We should send one email'); 
    }
    
 
    @IsTest
    private static void createRingCentralEmployeeOrContractor() {

        RestRequest request = new RestRequest();
        request.requestURI = System.URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-dsr-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('firstName', USER_FIRST_NAME);
        params.put('lastName', USER_LAST_NAME);
        params.put('email', USER_EMAIL);
        params.put('privacyFirstName', 'privacy ' + USER_FIRST_NAME);
        params.put('privacyLastName', 'privacy ' + USER_LAST_NAME);
        params.put('privacyEmail', 'privacy@mail.com');
        params.put('action', 'Change personal information');
        params.put('changeAdditionalInformation', 'Yes');
        params.put('country', 'Argentina');
        params.put('state', 'CABA');
        params.put('additionalInformation', 'Additional Information');
        params.put('roleName', 'admin');
        params.put('relation',CaseCreateDataSubjectRestService.USER_ROLE_EMPLOYEE_OR_CONTRACTOR);
        params.put('isRingCentralEventsAccount', 'Yes');
        params.put('isNiceContactCenterAccount', 'Yes');
        params.put('niceCCContactIds', '12344');
        params.put('niceCCAdditionalInfo', 'Hey testing contact');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            CaseCreateDataSubjectRestService.createCase();
            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());

        List<Account> accountRecords = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<String>{ 'Id' })
            .executeQuery();

        System.assertEquals(1, accountRecords.size(), 'We should not create any new account'); 

        Account dsrAccountRecord = accountRecords.get(0);

        List<Contact> contactRecords = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectFields(new List<String>{ 'FirstName', 'LastName', 'Email', 'MailingCountry', 'MailingState', 'AccountId' })
            .executeQuery();

        System.assertEquals(1, contactRecords.size(), 'Only one contact record should be created'); 

        Contact dsrContactRecord = contactRecords.get(0);

       
        System.assertEquals(dsrAccountRecord.Id, dsrContactRecord.AccountId, 'Got wrong account'); 

        List<Case> dsrCaseRecords = (List<Case>) new CaseSelector()
            .selectCasesForApproval(new List<Object>{ new List<Id>{ (Id) responseMap.get('caseId') } })
            .selectFields(new List<String>{
                'ContactId', 'AccountId', 'Subject', 'OwnerId', 'Case_Severity__c', 'Priority',
                'Case_Contact_Email__c', 'Description', 'RecordTypeId', 'IsVisibleInSelfService'
            })
            .executeQuery();

        System.assertEquals(1, dsrCaseRecords.size(), 'Only one case should be created'); 

        Case dsrCaseRecord = dsrCaseRecords.get(0);
        
         String description = 'Relation : RingCentral User'
        + '\nFirst Name : ' + USER_FIRST_NAME
        + '\nLast Name : ' + USER_LAST_NAME
        + '\nEmail : ' + USER_EMAIL
        + '\nPrivacy First Name : privacy ' + USER_FIRST_NAME
        + '\nPrivacy Last Name : privacy ' + USER_LAST_NAME
        + '\nPrivacy Email : privacy@mail.com'
        + '\nForm Type: admin'
        + '\nAction : Change personal information'
        + '\nChange Details : Please update my details'
        + '\nRingCentral Events Account: Yes'
        + '\nNICE Contact Center account : Yes'
        + '\nNICE Contact Center account contact IDs : 12344'
        + '\nNICE Contact Center account additional information : Testing contact center additional info'
        + '\nCountry : Argentina'
        + '\nState : CABA'
        + '\nAdditional Information : Testing additional information';

        System.assertEquals(dsrContactRecord.Id, dsrCaseRecord.ContactId, 'Got wrong contact');
        System.assertEquals(dsrAccountRecord.Id, dsrCaseRecord.AccountId, 'Got wrong account');
        System.assertEquals('Data Subject Request by ' + USER_EMAIL + ' requesting admin', dsrCaseRecord.Subject, 'Got wrong subject');
        System.assertEquals('Medium', dsrCaseRecord.Priority, 'Got wrong priority');
        System.assertEquals(USER_EMAIL, dsrCaseRecord.Case_Contact_Email__c, 'Got wrong case contact email');
        System.assertEquals(CaseHelper.RT_ID_GDPR_REQUEST, dsrCaseRecord.RecordTypeId, 'Got wrong record type');
        System.assertEquals(1, emailInvocations, 'We should send one email'); 
    }
    
    @IsTest
    private static void createJobApplicant() {

        RestRequest request = new RestRequest();
        request.requestURI = System.URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-dsr-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('firstName', USER_FIRST_NAME);
        params.put('lastName', USER_LAST_NAME);
        params.put('email', USER_EMAIL);
        params.put('privacyFirstName', 'privacy ' + USER_FIRST_NAME);
        params.put('privacyLastName', 'privacy ' + USER_LAST_NAME);
        params.put('privacyEmail', 'privacy@mail.com');
        params.put('action', 'Download');
        params.put('additionalAction', 'Download Add');
        params.put('changeAdditionalInformation', 'Yes');
        params.put('country', 'Argentina');
        params.put('state', 'CABA');
        params.put('additionalInformation', 'Additional Information');
        params.put('roleName', 'admin');
        params.put('relation',CaseCreateDataSubjectRestService.USER_ROLE_JOB_APPLICANT);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            CaseCreateDataSubjectRestService.createCase();
            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());

        List<Account> accountRecords = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<String>{ 'Id' })
            .executeQuery();

        System.assertEquals(1, accountRecords.size(), 'We should not create any new account'); 

        Account dsrAccountRecord = accountRecords.get(0);

        List<Contact> contactRecords = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectFields(new List<String>{ 'FirstName', 'LastName', 'Email', 'MailingCountry', 'MailingState', 'AccountId' })
            .executeQuery();

        System.assertEquals(1, contactRecords.size(), 'Only one contact record should be created'); 

        Contact dsrContactRecord = contactRecords.get(0);

       
        System.assertEquals(dsrAccountRecord.Id, dsrContactRecord.AccountId, 'Got wrong account'); 

        List<Case> dsrCaseRecords = (List<Case>) new CaseSelector()
            .selectCasesForApproval(new List<Object>{ new List<Id>{ (Id) responseMap.get('caseId') } })
            .selectFields(new List<String>{
                'ContactId', 'AccountId', 'Subject', 'OwnerId', 'Case_Severity__c', 'Priority',
                'Case_Contact_Email__c', 'Description', 'RecordTypeId', 'IsVisibleInSelfService'
            })
            .executeQuery();

        System.assertEquals(1, dsrCaseRecords.size(), 'Only one case should be created'); 

        Case dsrCaseRecord = dsrCaseRecords.get(0);

        String description = 'Privacy First Name: ' + 'privacy ' + USER_FIRST_NAME
            + 'Privacy Last Name: ' + 'privacy ' + USER_LAST_NAME
            + 'Privacy Email: privacy@mail.com'
            + 'Action: Download'
            + 'Additional Action: Download Add'
            + 'Change Additional Information: Yes'
            + 'Additional Information: Additional Information'
            + 'Form Type: admin'
            + 'Relation: RingCentral User';

        System.assertEquals(dsrContactRecord.Id, dsrCaseRecord.ContactId, 'Got wrong contact');
        System.assertEquals(dsrAccountRecord.Id, dsrCaseRecord.AccountId, 'Got wrong account');
        System.assertEquals('Data Subject Request by ' + USER_EMAIL + ' requesting admin', dsrCaseRecord.Subject, 'Got wrong subject');
        System.assertEquals('Medium', dsrCaseRecord.Priority, 'Got wrong priority');
        System.assertEquals(USER_EMAIL, dsrCaseRecord.Case_Contact_Email__c, 'Got wrong case contact email');
        System.assertEquals(CaseHelper.RT_ID_GDPR_REQUEST, dsrCaseRecord.RecordTypeId, 'Got wrong record type');
        System.assertEquals(1, emailInvocations, 'We should send one email'); 
    }
    
    @IsTest
    private static void createCaseWithInvalidAccount() {
        
        List<Account> accounts = new AccountSelector()
            .selectAccountsByUserIds(new List<Object>{new String[]{'1822028005'}})
            .executeQuery();
        
        // Ensure the account exists before deletion
        if (!accounts.isEmpty()) {
            // Delete the account to simulate the negative scenario
            delete accounts[0];
        }
        
        RestRequest request = new RestRequest();
        request.requestURI = System.URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-dsr-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('firstName', USER_FIRST_NAME);
        params.put('lastName', USER_LAST_NAME);
        params.put('email', USER_EMAIL);
        params.put('privacyFirstName', 'privacy ' + USER_FIRST_NAME);
        params.put('privacyLastName', 'privacy ' + USER_LAST_NAME);
        params.put('privacyEmail', 'privacy@mail.com');
        params.put('action', 'Download');
        params.put('additionalAction', 'Download Add');
        params.put('changeAdditionalInformation', 'Yes');
        params.put('country', 'Argentina');
        params.put('state', 'CABA');
        params.put('additionalInformation', 'Additional Information');
        params.put('roleName', 'admin');
        params.put('relation',CaseCreateDataSubjectRestService.USER_ROLE_JOB_APPLICANT);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            CaseCreateDataSubjectRestService.createCase();
            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        
        System.assertEquals(500, RestContext.response.statusCode, 'Expected failure with invalid account');

    }
    
    @IsTest
    private static void createCaseWithInvalidContact() {
        
        
        List<Contact> contacts = new ContactSelector()
                .selectContactForAPI(new List<Object>{ '1822028005', 'form-script@ringcentral.com' }, new String[]{ 'Id' })
                .executeQuery();
        
        // Ensure the contact exists before deletion
        if (!contacts.isEmpty()) {
            // Delete the contact to simulate the negative scenario
            delete contacts[0];
        }
        
        RestRequest request = new RestRequest();
        request.requestURI = System.URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-dsr-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('firstName', USER_FIRST_NAME);
        params.put('lastName', USER_LAST_NAME);
        params.put('email', USER_EMAIL);
        params.put('privacyFirstName', 'privacy ' + USER_FIRST_NAME);
        params.put('privacyLastName', 'privacy ' + USER_LAST_NAME);
        params.put('privacyEmail', 'privacy@mail.com');
        params.put('action', 'Change personal information');
        params.put('additionalAction', 'Download Add');
        params.put('changeAdditionalInformation', 'Yes');
        params.put('country', 'Argentina');
        params.put('state', 'CABA');
        params.put('additionalInformation', 'Additional Information');
        params.put('roleName', 'admin');
        params.put('relation',CaseCreateDataSubjectRestService.USER_ROLE_JOB_APPLICANT);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            CaseCreateDataSubjectRestService.createCase();
            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode, 'Expected failure for invalid contact');
    }
    
    @IsTest
    private static void createCaseWithInvalidRole() {
        
        
        List<Contact> contacts = new ContactSelector()
                .selectContactForAPI(new List<Object>{ '1822028005', 'form-script@ringcentral.com' }, new String[]{ 'Id' })
                .executeQuery();
        
        // Ensure the contact exists before deletion
        if (!contacts.isEmpty()) {
            // Delete the contact to simulate the negative scenario
            delete contacts[0];
        }
        
        RestRequest request = new RestRequest();
        request.requestURI = System.URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-dsr-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('firstName', USER_FIRST_NAME);
        params.put('lastName', USER_LAST_NAME);
        params.put('email', USER_EMAIL);
        params.put('privacyFirstName', 'privacy ' + USER_FIRST_NAME);
        params.put('privacyLastName', 'privacy ' + USER_LAST_NAME);
        params.put('privacyEmail', 'privacy@mail.com');
        params.put('action', 'Download');
        params.put('additionalAction', 'Download Add');
        params.put('changeAdditionalInformation', 'Yes');
        params.put('country', 'Argentina');
        params.put('state', 'CABA');
        params.put('additionalInformation', 'Additional Information');
        params.put('roleName', 'admin');
        params.put('relation','InvalidRole');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the method to test
        Test.startTest();
            CaseCreateDataSubjectRestService.createCase();
            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode, 'Expected failure for invalid role');

    }
    
    @IsTest
    private static void createCaseWithForcedException() {
        // Prepare a faulty request
        RestRequest request = new RestRequest();
        request.requestURI = System.URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-dsr-new';
        request.httpMethod = 'POST';
        RestContext.request = request;
        
        // Simulate a malformed request body
        String invalidRequestBody = 'Invalid JSON Structure';
        RestContext.request.requestBody = Blob.valueOf(invalidRequestBody);
        
        // Test the method
        Test.startTest();
        CaseCreateDataSubjectRestService.createCase();
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode, 'Expected failure due to invalid JSON structure');
    }

}