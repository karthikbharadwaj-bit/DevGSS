@isTest
public with sharing class CaseCreateRestService_Test {

    private static final String SUCCESS_MESSAGE = 'Picklist values provided';
    private static final String API_ONLY_PROFILE_NAME = 'API Only';

    private static final String USER_USERNAME = 'RC_SupportCommunityCaseListTestUser@rc.com';
    private static final String USER_EMAIL = 'useremail@rc.com';
    private static final String USER_FIRST_NAME = 'firstname';
    private static final String USER_LAST_NAME = 'lastname';
    private static final String USER_LANGUAGE = 'en_US';

    private static final String UID = '554432213';

    private static final String CONTACT_FIRST_NAME = USER_FIRST_NAME;
    private static final String CONTACT_LAST_NAME = USER_LAST_NAME;
    private static final String CONTACT_EMAIL = USER_EMAIL;
    private static final String CONTACT_PHONE = '77777777';
    private static final Decimal CONTACT_PHONE_EXT = 777;

    public static final String CASE_APINAME = 'Case';
    public static final String BILLING_QUEUE_NAME = 'Billing Inquiries';

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
                Account.RC_User_ID__c => UID,
                Account.RC_Account_Number__c => UID
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
        
        // Add BT Support Account and Contact using SObjectBuilder
        List<Account> btSupportAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'BT Support Test Account',
                Account.RC_Brand__c => 'BT Business',
                Account.BillingStreet => '123 BT Road',
                Account.BillingCity => 'London',
                Account.BillingPostalCode => 'EC1A 1BB',
                Account.BillingState => 'England',
                Account.BillingCountry => 'United Kingdom',
                Account.RC_User_ID__c => '504432213',
                Account.RC_Account_Number__c => '504432213'
            })
            .create()
            .getRecords();

        List<Contact> btSupportContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'BT',
                Contact.LastName => 'Support',
                Contact.Email => 'bt_support@rc.com',
                Contact.Phone => '88888888',
                Contact.AccountId => btSupportAccounts[0].Id
            })
            .create()
            .getRecords();
        

        Rise_Partner_CRM_Configuration__c riseSetting = new Rise_Partner_CRM_Configuration__c();
        riseSetting.Name = '2000.Sincrone';
        riseSetting.Max_Purchase_DL__c = 99;
        riseSetting.Account_Status__c = 'Paid';
        riseSetting.Is_Case_ReRouting__c=true;
        riseSetting.Brand__c= 'Rise International';
        riseSetting.Queue_Name__c= 'Sofia_EMEA_Cases';
        insert riseSetting;
    }
    
    
    @isTest
    private static void testBTSupportPicklistHierarchy() {
        // Setup the request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/SCApi/v1/case-new/getCaseAreaPicklistHierarchy';
        request.params.put('uid', '504432213'); // Matching UID
        request.params.put('email', 'bt_support@rc.com'); // Matching email
        request.httpMethod = 'GET';
        RestContext.request = request;
        
        // Execute the method
        Test.startTest();
        Map<String, Object> response = CaseCreateAPIController.retrieveCaseAreaPicklistHierarchy(JSON.serialize(RestContext.request.params));
        Test.stopTest();
        
        // Assertions
        System.assertEquals(true, response.get(CaseAPIUtil.SUCCESS_FIELD_NAME), 'Success should be true');
    }
    
    @isTest
    private static void testBTSupportPicklistHierarchynegative() {
        // Setup the request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/SCApi/v1/case-new/getCaseAreaPicklistHierarchy';
        request.params.put('uid', '50443213'); // Matching UID
        request.params.put('email', 'bt_support@rc.com'); // Matching email
        request.httpMethod = 'GET';
        RestContext.request = request;
        
        // Execute the method
        Test.startTest();
        Map<String, Object> response = CaseCreateAPIController.retrieveCaseAreaPicklistHierarchy(JSON.serialize(RestContext.request.params));
        Test.stopTest();
        
        // Assertions
        System.assertEquals(false, response.get(CaseAPIUtil.SUCCESS_FIELD_NAME), 'Success should be true');

    }
    


    @isTest
    private static void getCaseAreaPicklistHierarchy() {

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new CaseCreateMockCallout());

        SCWrappers.PicklistAPIOptions res = CaseCreateAPIController.getAPIResponse(
            CaseHelper.RT_ID_SUPPORT_CASE,
            CaseCreateAPIController.ASSISTANCE_FIELD_NAME_1,
            new Map<String, String>()
        );

        Test.stopTest();

        //Verify response received contains fake values
        System.assertEquals(res.controllerValues, new Map<String,Integer>());
        System.assertEquals(res.defaultValue, null);
        System.assertEquals(res.url, '/services/data/v51.0/ui-api/object-info/Case/picklist-values/01280000000UIfJAAW/Product_Assistance__c');
        System.assertEquals(res.values.size(), 8);

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.params.put(CaseCreateAPIController.LANG_KEY, 'es');
        request.params.put('uid', UID); // Add the UID
        request.params.put('email', USER_EMAIL); // Add the email
        request.httpMethod = 'GET';
        RestContext.request = request;
        CaseCreateRestService.getCaseAreaPicklistHierarchy();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    private static void postCaseSuccess() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('selectedProduct', 'Active Directory');
        params.put('selectedProduct2', 'General Product Inquiry and Features');
        params.put('severityLevel', 'Level 3 - High');
        params.put('alternateEmail', 'test@email.com');
        params.put('callbackPhone', '1234123123');
        params.put('timezone', '(GMT+03:00) Baghdad, Kuwait, Moscow, St. Petersburg, Nairobi');
        params.put('isGdpr', false);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        CaseCreateRestService.createCase();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseCreateAPIController.SUCCESS_MESSAGE_POST),
            RestContext.response.responseBody.toString()
        );
    }

    @isTest
    private static void postCaseSuccess_WithBillingQueueOwner() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;
        Case caseObj = new Case();

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('selectedProduct', 'Billing');
        params.put('selectedProduct2', 'Credit Card Inquiry');
        params.put('severityLevel', 'Level 3 - High');
        params.put('alternateEmail', 'test@email.com');
        params.put('callbackPhone', '1234123123');
        params.put('timezone', '(GMT+03:00) Baghdad, Kuwait, Moscow, St. Petersburg, Nairobi');
        params.put('isGdpr', false);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        CaseCreateRestService.createCase();
        Test.stopTest();

        Map <String, Object> responseMap = (Map <String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        caseObj = (Case) new CaseSelector()
            .selectCasesForApproval(new List<Object>{new List<Id>{(Id) responseMap.get('caseId')}})
            .selectFields(new List<String> {'OwnerId', 'Owner.Name'})
            .executeQuery()[0];

        QueueSObject billingQueue = (QueueSObject) new QueueSelector()
            .selectQueueByName(new List<Object> {BILLING_QUEUE_NAME})
            .executeQuery()
            .get(0);

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseCreateAPIController.SUCCESS_MESSAGE_POST),
            RestContext.response.responseBody.toString()
        );
        System.assertEquals(billingQueue.QueueId, caseObj.OwnerId, 'Incorrect Owner Id: '+ caseObj.OwnerId);
    }

    @isTest
    private static void postCaseWrongUser() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', 'wrong@email.com');
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('selectedProduct', 'Active Directory');
        params.put('selectedProduct2', 'General Product Inquiry and Features');
        params.put('severityLevel', 'Level 3 - High');
        params.put('alternateEmail', 'test@email.com');
        params.put('callbackPhone', '1234123123');
        params.put('isGdpr', false);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            RestContext.response.responseBody.toString()
        );

    }

    @isTest
    private static void postCaseGdprRequired() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('selectedProduct', 'Active Directory');
        params.put('selectedProduct2', 'General Product Inquiry and Features');
        params.put('severityLevel', 'Level 3 - High');
        params.put('alternateEmail', 'test@email.com');
        params.put('callbackPhone', '1234123123');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseCreateAPIController.ERROR_MESSAGE_GDPR_REQUIRED),
            RestContext.response.responseBody.toString()
        );

    }

    @isTest
    private static void postCaseGdprFalseRequired() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('selectedProduct', 'Active Directory');
        params.put('selectedProduct2', 'General Product Inquiry and Features');
        params.put('severityLevel', 'Level 3 - High');
        params.put('alternateEmail', 'test@email.com');
        params.put('callbackPhone', '1234123123');
        params.put('isGdpr', false);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseCreateAPIController.ERROR_MESSAGE_NOT_GDPR),
            RestContext.response.responseBody.toString()
        );

    }

    @isTest
    private static void postCaseGdprTrueRequired() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('isGdpr', true);
        params.put('selectedProduct', HelperCaseDispatch.PRODUCT_ASSISTANCE_GDPR);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseCreateAPIController.ERROR_MESSAGE_ISGDPR),
            RestContext.response.responseBody.toString()
        );

    }

    @isTest
    private static void postCaseGdprSuccess() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('isGdpr', true);
        params.put('firstName', USER_FIRST_NAME);
        params.put('lastName', USER_LAST_NAME);
        params.put('gdprEmail', USER_EMAIL);
        params.put('euCitizen', true);
        params.put('selectedProduct', HelperCaseDispatch.PRODUCT_ASSISTANCE_GDPR);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        CaseCreateRestService.createCase();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseCreateAPIController.SUCCESS_MESSAGE_POST),
            RestContext.response.responseBody.toString()
        );

    }

    @isTest
    private static void postCaseNoUser() {

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            RestContext.response.responseBody.toString()
        );

    }

    @isTest
    private static void postCaseWithoutTimezone() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('selectedProduct', 'Active Directory');
        params.put('selectedProduct2', 'General Product Inquiry and Features');
        params.put('severityLevel', 'Level 3 - High');
        params.put('alternateEmail', 'test@email.com');
        params.put('callbackPhone', '1234123123');
        params.put('isGdpr', false);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseCreateAPIController.ERROR_MESSAGE_NOT_GDPR),
            RestContext.response.responseBody.toString()
        );

    }

    @isTest
    private static void postCaseWithInvalidRequest() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.request.requestBody = Blob.valueOf('Invalid request');
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            RestContext.response.responseBody.toString()
        );

    }

    @isTest
    private static void postCase_WhenRecordTypeIdIsSalesCustomForm_ShouldBeOk() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        String caseCategory = 'Sales - Account Cancellation';
        String escalateTo = 'CERT';

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('caseCategory', caseCategory);
        params.put('escalateTo', escalateTo);
        params.put('recordTypeId', CaseHelper.RT_ID_SALES_CUST_FORM);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        CaseCreateRestService.createCase();
        Test.stopTest();


        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());

        System.assert(resMap.containsKey(CaseCreateAPIController.CASE_ID), 'Response should contains: ' + CaseCreateAPIController.CASE_ID);

        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCaseForEscalating(new Object[]{resMap.get(CaseCreateAPIController.CASE_ID)})
            .selectFields(new String[]{
                'Case_Category__c',
                'Support_Escalate_To__c',
                'RecordTypeId'
            })
            .executeQuery();

        System.assertEquals(1, cases.size(), 'Should find a case with the id: ' + resMap.get(CaseCreateAPIController.CASE_ID));

        System.assertEquals(caseCategory, cases[0].Case_Category__c, 'Case_Category__c was wrongly populated');
        System.assertEquals(escalateTo, cases[0].Support_Escalate_To__c, 'Support_Escalate_To__c was wrongly populated');
        System.assertEquals(CaseHelper.RT_ID_SALES_CUST_FORM, cases[0].recordtypeId, 'recordtypeId was wrongly populated');

    }

    @isTest
    private static void postCase_WhenRecordTypeIsSalesCustomForm_ShouldBeOk() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        String caseCategory = 'Sales - Account Cancellation';
        String escalateTo = 'CERT';

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('caseCategory', caseCategory);
        params.put('escalateTo', escalateTo);
        params.put('recordType', CaseHelper.RT_NAME_SALES_CUST_FORM);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        CaseCreateRestService.createCase();
        Test.stopTest();


        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());

        System.assert(resMap.containsKey(CaseCreateAPIController.CASE_ID), 'Response should contains: ' + CaseCreateAPIController.CASE_ID);

        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCaseForEscalating(new Object[]{resMap.get(CaseCreateAPIController.CASE_ID)})
            .selectFields(new String[]{
                'Case_Category__c',
                'Support_Escalate_To__c',
                'RecordTypeId'
            })
            .executeQuery();

        System.assertEquals(1, cases.size(), 'Should find a case with the id: ' + resMap.get(CaseCreateAPIController.CASE_ID));

        System.assertEquals(caseCategory, cases[0].Case_Category__c, 'Case_Category__c was wrongly populated');
        System.assertEquals(escalateTo, cases[0].Support_Escalate_To__c, 'Support_Escalate_To__c was wrongly populated');
        System.assertEquals(CaseHelper.RT_ID_SALES_CUST_FORM, cases[0].recordtypeId, 'recordtypeId was wrongly populated');

    }
    @isTest
    private static void postCase_WhenRecordTypeIsSalesCustomFormAndTimezoneIsValidValue_ShouldBeOk() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        String caseCategory = 'Sales - Account Cancellation';
        String escalateTo = 'CERT';
        String timezone = AquivaHelper.getPicklistValues('Case', 'timezone__c')[0];

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('caseCategory', caseCategory);
        params.put('escalateTo', escalateTo);
        params.put('recordType', CaseHelper.RT_NAME_SALES_CUST_FORM);
        params.put('timezone', timezone);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        CaseCreateRestService.createCase();
        Test.stopTest();


        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());

        System.assert(resMap.containsKey(CaseCreateAPIController.CASE_ID), 'Response should contains: ' + CaseCreateAPIController.CASE_ID);

        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCaseForEscalating(new Object[]{resMap.get(CaseCreateAPIController.CASE_ID)})
            .selectFields(new String[]{
                'Case_Category__c',
                'Support_Escalate_To__c',
                'Timezone__c',
                'RecordTypeId'
            })
            .executeQuery();

        System.assertEquals(1, cases.size(), 'Should find a case with the id: ' + resMap.get(CaseCreateAPIController.CASE_ID));

        System.assertEquals(caseCategory, cases[0].Case_Category__c, 'Case_Category__c was wrongly populated');
        System.assertEquals(escalateTo, cases[0].Support_Escalate_To__c, 'Support_Escalate_To__c was wrongly populated');
        System.assertEquals(timezone, cases[0].timezone__c, 'timezone__c was wrongly populated');
        System.assertEquals(CaseHelper.RT_ID_SALES_CUST_FORM, cases[0].recordtypeId, 'recordtypeId was wrongly populated');

    }
    @isTest
    private static void postCase_WhenRecordTypeIsSalesCustomFormAndTimezoneIsInvalidValue_ShouldThrowError() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        String caseCategory = 'Sales - Account Cancellation';
        String escalateTo = 'CERT';

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('caseCategory', caseCategory);
        params.put('escalateTo', escalateTo);
        params.put('recordType', CaseHelper.RT_NAME_SALES_CUST_FORM);
        params.put('timezone', 'invalid value');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        CaseCreateRestService.createCase();
        Test.stopTest();
        System.assert(
            RestContext.response.responseBody.toString().contains(CaseCreateAPIController.ERROR_MESSAGE_INVALID_TIMEZONE_VALUE),
            'It should contains ' + CaseCreateAPIController.ERROR_MESSAGE_INVALID_TIMEZONE_VALUE
        );
    }
    @isTest
    private static void postCase_WhenRecordTypeIdIsInvalid_ShouldThrowError() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        String caseCategory = 'Sales - Account Cancellation';
        String escalateTo = 'CERT';
        String timezone = AquivaHelper.getPicklistValues('Case', 'timezone__c')[0];

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('caseCategory', caseCategory);
        params.put('escalateTo', escalateTo);
        params.put('recordTypeId', 'bad recordtypeid');
        params.put('timezone', timezone);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();
        System.assert(
            RestContext.response.responseBody.toString().contains(CaseAPIUtil.BAD_REQUEST_MESSAGE),
            'It should contains ' + CaseAPIUtil.BAD_REQUEST_MESSAGE
        );

    }
    @isTest
    private static void postCase_WhenRecordTypeIdIsDeveloperPlatform_ShouldBeOk() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        String useCaseType = 'Apppermissionsandconfiguration';
        String origin = 'Web';
        String priority = 'Medium';
        String caseAccountNumber = UID;
        String type = 'NewDeveloperRequest';
        String ownerId = apiOnlyTestUser.Id;

        Map<String, Object> params = new Map<String, Object>();
        params.put('email', USER_EMAIL);
        params.put('origin', Origin);
        params.put('useCaseType', useCaseType);
        params.put('description', 'Test description');
        params.put('priority', priority);
        params.put('subject', 'Test Subject');
        params.put('uid', caseAccountNumber);
        params.put('type', type);
        params.put('ownerId', ownerId);
        params.put('recordTypeId', CaseHelper.RT_ID_DEVELOPER_PORTAL);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        CaseCreateRestService.createCase();
        Test.stopTest();


        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());

        System.assert(resMap.containsKey(CaseCreateAPIController.CASE_ID), 'Response should contains: ' + CaseCreateAPIController.CASE_ID);

        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCaseForEscalating(new Object[]{resMap.get(CaseCreateAPIController.CASE_ID)})
            .selectFields(new String[]{
                'Origin',
                'Use_Case_Type__c',
                'Description',
                'Priority',
                'Subject',
                'Case_Account_Number__c',
                'Type',
                'OwnerId',
                'recordTypeId'
            })
            .executeQuery();

        System.assertEquals(1, cases.size(), 'Should find a case with the id: ' + resMap.get(CaseCreateAPIController.CASE_ID));

        System.assertEquals(origin, cases[0].Origin, 'Origin was wrongly populated');
        System.assertEquals(useCaseType, cases[0].Use_Case_Type__c, 'Use_Case_Type__c was wrongly populated');
        System.assertEquals(priority, cases[0].Priority, 'Priority was wrongly populated');
        System.assertEquals(caseAccountNumber, cases[0].Case_Account_Number__c, 'Case_Account_Number__c was wrongly populated');
        System.assertEquals(type, cases[0].Type, 'Type was wrongly populated');
        System.assertEquals(ownerId, cases[0].OwnerId, 'OwnerId was wrongly populated');
        System.assertEquals(CaseHelper.RT_ID_DEVELOPER_PORTAL, cases[0].recordTypeId, 'recordTypeId was wrongly populated');

    }

    @isTest
    private static void postCase_WhenRecordTypeIsDeveloperPlatform_ShouldBeOk() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        String useCaseType = 'Apppermissionsandconfiguration';
        String origin = 'Web';
        String priority = 'Medium';
        String caseAccountNumber = UID;
        String type = 'NewDeveloperRequest';
        String ownerId = apiOnlyTestUser.Id;

        Map<String, Object> params = new Map<String, Object>();
        params.put('email', USER_EMAIL);
        params.put('origin', Origin);
        params.put('useCaseType', useCaseType);
        params.put('description', 'Test description');
        params.put('priority', priority);
        params.put('subject', 'Test Subject');
        params.put('uid', caseAccountNumber);
        params.put('type', type);
        params.put('ownerId', ownerId);
        params.put('recordType', CaseHelper.RT_NAME_DEVELOPER_PLATFORM);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        CaseCreateRestService.createCase();
        Test.stopTest();


        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());

        System.assert(resMap.containsKey(CaseCreateAPIController.CASE_ID), 'Response should contains: ' + CaseCreateAPIController.CASE_ID);

        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCaseForEscalating(new Object[]{resMap.get(CaseCreateAPIController.CASE_ID)})
            .selectFields(new String[]{
                'Origin',
                'Use_Case_Type__c',
                'Description',
                'Priority',
                'Subject',
                'Case_Account_Number__c',
                'Type',
                'OwnerId',
                'recordTypeId'
            })
            .executeQuery();

        System.assertEquals(1, cases.size(), 'Should find a case with the id: ' + resMap.get(CaseCreateAPIController.CASE_ID));

        System.assertEquals(origin, cases[0].Origin, 'Origin was wrongly populated');
        System.assertEquals(useCaseType, cases[0].Use_Case_Type__c, 'Use_Case_Type__c was wrongly populated');
        System.assertEquals(priority, cases[0].Priority, 'Priority was wrongly populated');
        System.assertEquals(caseAccountNumber, cases[0].Case_Account_Number__c, 'Case_Account_Number__c was wrongly populated');
        System.assertEquals(type, cases[0].Type, 'Type was wrongly populated');
        System.assertEquals(ownerId, cases[0].OwnerId, 'OwnerId was wrongly populated');
        System.assertEquals(CaseHelper.RT_ID_DEVELOPER_PORTAL, cases[0].recordTypeId, 'recordTypeId was wrongly populated');

    }

    @isTest
    private static void postCase_WhenRecordTypeIsGDPR_ShouldBeOk() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('firstName', USER_FIRST_NAME);
        params.put('lastName', USER_LAST_NAME);
        params.put('gdprEmail', USER_EMAIL);
        params.put('euCitizen', true);
        params.put('recordType', CaseHelper.RT_NAME_GDPR_REQUEST);
        params.put('selectedProduct', HelperCaseDispatch.PRODUCT_ASSISTANCE_GDPR);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        CaseCreateRestService.createCase();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, RestContext.response.responseBody.toString());
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseCreateAPIController.SUCCESS_MESSAGE_POST), RestContext.response.responseBody.toString());

    }

    @isTest
    private static void postCase_WhenRecordTypeIsGDPRAndSelectedProductIsInvalid_ShouldThrowAnError() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('firstName', USER_FIRST_NAME);
        params.put('lastName', USER_LAST_NAME);
        params.put('gdprEmail', USER_EMAIL);
        params.put('euCitizen', true);
        params.put('recordType', CaseHelper.RT_NAME_GDPR_REQUEST);
        params.put('selectedProduct', 'Invalid value');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, RestContext.response.responseBody.toString());
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseCreateAPIController.ERROR_MESSAGE_INVALID_SELECTED_PRODUCT), RestContext.response.responseBody.toString());
    }

    @isTest
    private static void postCase_WhenRecordTypeIsGDPRAndEuCitizenIsNull_ShouldThrowAnError() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('firstName', USER_FIRST_NAME);
        params.put('lastName', USER_LAST_NAME);
        params.put('gdprEmail', USER_EMAIL);
        params.put('recordType', CaseHelper.RT_NAME_GDPR_REQUEST);
        params.put('selectedProduct', 'Invalid value');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, RestContext.response.responseBody.toString());
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseCreateAPIController.ERROR_MESSAGE_ISGDPR), RestContext.response.responseBody.toString());

    }

    @isTest
    private static void testGetDependenciesMap() {
        List<SCWRappers.PicklistAPIValues> picklistValues = new List<SCWRappers.PicklistAPIValues>();
        SCWRappers.PicklistAPIValues picklistBillingValue1 = new SCWRappers.PicklistAPIValues();
        picklistBillingValue1.validFor = new Integer[]{1};
        picklistBillingValue1.label = 'Billing information update';
        picklistBillingValue1.value = 'Billing information update';
        SCWRappers.PicklistAPIValues picklistBillingValue2 = new SCWRappers.PicklistAPIValues();
        picklistBillingValue2.validFor = new Integer[]{1};
        picklistBillingValue2.label = 'Taxes and fees inquiry';
        picklistBillingValue2.value = 'Taxes and fees inquiry';

        picklistValues.add(picklistBillingValue1);
        picklistValues.add(picklistBillingValue2);

        SCWRappers.PicklistAPIOptions picklistOptions = new SCWRappers.PicklistAPIOptions();
        picklistOptions.controllerValues = new Map<String,Integer>{
            'Billing' => 1
        };

        picklistOptions.values = picklistValues;
        Map<Integer,List<SCWrappers.BaseOption>> validForMap = CaseCreateAPIController.fillValidForMap(picklistOptions);
        Map<String,List<SCWrappers.BaseOption>> dependenciesMap = CaseCreateAPIController.getDependenciesMap(picklistOptions, validForMap);

        system.assertEquals(2, validForMap.get(1).size(), 'size should be 2');
        system.assertEquals(2, dependenciesMap.get('Billing').size(), 'size should be 2');
    }


    @isTest
    private static void postCase_WhenIsGDPRParameterIsTrueAndSelectedProductIsNotGDPR_ShouldThrowAnError() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('firstName', USER_FIRST_NAME);
        params.put('lastName', USER_LAST_NAME);
        params.put('gdprEmail', USER_EMAIL);
        params.put('euCitizen', true);
        params.put('isGdpr', true);
        params.put('selectedProduct', 'Invalid value');

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, RestContext.response.responseBody.toString());
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseCreateAPIController.ERROR_MESSAGE_INVALID_SELECTED_PRODUCT), RestContext.response.responseBody.toString());
    }

    @isTest
    private static void postCase_WhenRecordTypeIdIsDeveloperPlatformAndUIDInvalidAndAccountIdForOrphanCasesIsNotConfigured_ShouldThrowError() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        String useCaseType = 'Apppermissionsandconfiguration';
        String origin = 'Web';
        String priority = 'Medium';
        String type = 'NewDeveloperRequest';
        String ownerId = apiOnlyTestUser.Id;

        Map<String, Object> params = new Map<String, Object>();
        params.put('email', USER_EMAIL);
        params.put('origin', Origin);
        params.put('useCaseType', useCaseType);
        params.put('description', 'Test description');
        params.put('priority', priority);
        params.put('subject', 'Test Subject');
        params.put('uid', 'invalid uid');
        params.put('type', type);
        params.put('ownerId', ownerId);
        params.put('recordTypeId', CaseHelper.RT_ID_DEVELOPER_PORTAL);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        System.runAs(apiOnlyTestUser) {
            CaseCreateRestService.createCase();
        }
        Test.stopTest();


        system.assertEquals(
            true,
            RestContext.response.responseBody.toString().contains(CaseCreateAPIController.ERROR_MESSAGE_UID_INVALID),
            'response body should contains: ' + CaseCreateAPIController.ERROR_MESSAGE_UID_INVALID + 'but it is: ' +
            RestContext.response.responseBody.toString()
        );

    }
    @isTest
    private static void postCase_WhenRecordTypeIdIsDeveloperPlatformAndUIDInvalidAndAccountIdForOrphanCasesIsConfigured_ShouldBeOk() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        String useCaseType = 'Apppermissionsandconfiguration';
        String origin = 'Web';
        String priority = 'Medium';
        String type = 'NewDeveloperRequest';
        String ownerId = apiOnlyTestUser.Id;

        SnapInsSettings__c setting = new SnapInsSettings__c();
        setting.IdAccountForOrphanCases__c = new AccountSelector()
            .selectAccountsByUserIds(new Object[]{new String[]{
                uid
            }})
            .executeQuery()[0].Id;
        insert setting;


        Map<String, Object> params = new Map<String, Object>();
        params.put('email', USER_EMAIL);
        params.put('origin', Origin);
        params.put('useCaseType', useCaseType);
        params.put('description', 'Test description');
        params.put('priority', priority);
        params.put('subject', 'Test Subject');
        params.put('uid', 'invalid uid');
        params.put('type', type);
        params.put('ownerId', ownerId);
        params.put('recordTypeId', CaseHelper.RT_ID_DEVELOPER_PORTAL);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
        CaseCreateRestService.createCase();
        Test.stopTest();
        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());

        System.assert(resMap.containsKey(CaseCreateAPIController.CASE_ID), 'Response should contains: ' + CaseCreateAPIController.CASE_ID);

        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCaseForEscalating(new Object[]{resMap.get(CaseCreateAPIController.CASE_ID)})
            .selectFields(new String[]{
                'Origin',
                'Use_Case_Type__c',
                'Priority',
                'Subject',
                'Case_Account_Number__c',
                'Type',
                'OwnerId',
                'recordTypeId',
                'BizServ_Developer_Comments__c'
            })
            .executeQuery();

        System.assertEquals(1, cases.size(), 'Should find a case with the id: ' + resMap.get(CaseCreateAPIController.CASE_ID));

        System.assertEquals(origin, cases[0].Origin, 'Origin was wrongly populated');
        System.assertEquals(useCaseType, cases[0].Use_Case_Type__c, 'Use_Case_Type__c was wrongly populated');
        System.assertEquals(priority, cases[0].Priority, 'Priority was wrongly populated');
        System.assertEquals(type, cases[0].Type, 'Type was wrongly populated');
        System.assertEquals(ownerId, cases[0].OwnerId, 'OwnerId was wrongly populated');
        System.assertEquals(true, cases[0].BizServ_Developer_Comments__c.contains('invalid uid'),
            'BizServ_Developer_Comments__c should contains "invalid uid" ' + cases[0].BizServ_Developer_Comments__c);
        System.assertEquals(true, cases[0].BizServ_Developer_Comments__c.contains(USER_EMAIL),
            'BizServ_Developer_Comments__c should contains "'+ USER_EMAIL +'" ' + cases[0].BizServ_Developer_Comments__c);
        System.assertEquals(CaseHelper.RT_ID_DEVELOPER_PORTAL, cases[0].recordTypeId, 'recordTypeId was wrongly populated');
    }

    @isTest
    private static void postCase_WhenRecordTypeIdIsDeveloperPlatformAndUidIsNotValidAndEmailIsValid_ShouldCreateCaseAndCreateTask() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        String useCaseType = 'Apppermissionsandconfiguration';
        String origin = 'Web';
        String priority = 'Medium';
        String type = 'NewDeveloperRequest';
        String ownerId = apiOnlyTestUser.Id;

        SnapInsSettings__c setting = new SnapInsSettings__c();
        setting.IdAccountForOrphanCases__c = new AccountSelector()
            .selectAccountsByUserIds(new Object[]{new String[]{
                uid
            }})
            .executeQuery()[0].Id;
        insert setting;


        Map<String, Object> params = new Map<String, Object>();
        params.put('email', USER_EMAIL);
        params.put('origin', Origin);
        params.put('useCaseType', useCaseType);
        params.put('description', 'Test description');
        params.put('priority', priority);
        params.put('subject', 'Test Subject');
        params.put('uid', 'invalid uid');
        params.put('type', type);
        params.put('ownerId', ownerId);
        params.put('recordTypeId', CaseHelper.RT_ID_DEVELOPER_PORTAL);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
        CaseCreateRestService.createCase();
        Test.stopTest();
        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());

        System.assert(resMap.containsKey(CaseCreateAPIController.CASE_ID),
            'Response should contains: ' + CaseCreateAPIController.CASE_ID +
            ' current response: ' + RestContext.response.responseBody.toString()
        );

        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCaseForEscalating(new Object[]{resMap.get(CaseCreateAPIController.CASE_ID)})
            .selectFields(new String[]{
                'Origin',
                'Use_Case_Type__c',
                'Priority',
                'Subject',
                'Case_Account_Number__c',
                'Type',
                'OwnerId',
                'recordTypeId',
                'BizServ_Developer_Comments__c'
            })
            .executeQuery();

        System.assertEquals(1, cases.size(), 'Should find a case with the id: ' + resMap.get(CaseCreateAPIController.CASE_ID));

        System.assertEquals(origin, cases[0].Origin, 'Origin was wrongly populated');
        System.assertEquals(useCaseType, cases[0].Use_Case_Type__c, 'Use_Case_Type__c was wrongly populated');
        System.assertEquals(priority, cases[0].Priority, 'Priority was wrongly populated');
        System.assertEquals(type, cases[0].Type, 'Type was wrongly populated');
        System.assertEquals(ownerId, cases[0].OwnerId, 'OwnerId was wrongly populated');
        System.assertEquals(true, cases[0].BizServ_Developer_Comments__c.contains('invalid uid'),
            'BizServ_Developer_Comments__c should contains "invalid uid" ' + cases[0].BizServ_Developer_Comments__c);
        System.assertEquals(true, cases[0].BizServ_Developer_Comments__c.contains(USER_EMAIL),
            'BizServ_Developer_Comments__c should contains "'+ USER_EMAIL +'" ' + cases[0].BizServ_Developer_Comments__c);
        System.assertEquals(CaseHelper.RT_ID_DEVELOPER_PORTAL, cases[0].recordTypeId, 'recordTypeId was wrongly populated');
        System.assertEquals(
            1,
            Database.countQuery('SELECT COUNT() FROM Task WHERE WhatId = \''+ cases[0].Id +'\''),
            'There should be 1 task created related to the case.'
        );
    }
    
    @isTest
    private static void postCase_WhenProductIsPhoneAndCategoryPorting_shouldCreateAPortingPhoneCase() {
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('selectedProduct', 'Phone');
        params.put('selectedProduct2', 'Porting/Number transfer');
        params.put('severityLevel', 'Level 3 - High');
        params.put('alternateEmail', 'test@email.com');
        params.put('callbackPhone', '1234123123');
        params.put('timezone', '(GMT+03:00) Baghdad, Kuwait, Moscow, St. Petersburg, Nairobi');
        params.put('isGdpr', false);

        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        // Call the method to test
        Test.startTest();
        CaseCreateRestService.createCase();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true,
            RestContext.response.responseBody.toString().contains(CaseCreateAPIController.SUCCESS_MESSAGE_POST),
            RestContext.response.responseBody.toString()
        );

        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());

        System.assert(resMap.containsKey(CaseCreateAPIController.CASE_ID),
            'Response should contains: ' + CaseCreateAPIController.CASE_ID +
            ' current response: ' + RestContext.response.responseBody.toString()
        );

        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCaseForEscalating(new Object[]{resMap.get(CaseCreateAPIController.CASE_ID)})
            .selectFields(new String[]{
                'RecordTypeId'
            })
            .executeQuery();

        System.assertEquals(1, cases.size(), 'Should find a case with the id: ' + resMap.get(CaseCreateAPIController.CASE_ID));
        System.assertEquals(CaseHelper.RT_ID_PORTING_PHONE, cases[0].recordTypeId, 'The created case should be a porting phone case');
    }

    @isTest
    private static void postCase_WhenContactCenterConditionsMet_ShouldAssignToContactCenterQueue() {
        // Setup test data for Contact Center routing

        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE RC_User_ID__c = :UID LIMIT 1];
        testAccount.Service_Status__c = AccountHelper.SERVICE_STATUS_CONTRACT_COMPLETE;
        testAccount.IsRingCx__c = true;
        update testAccount;
        
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/case-new';
        request.httpMethod = 'POST';
        RestContext.request = request;
        
        // Get the existing Manila Contact Center Queue from org
        Group contactCenterQueue = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Manila_Contact_Center_Queue' LIMIT 1];
        
        // If queue doesn't exist (shouldn't happen in your case), create it
        if(contactCenterQueue == null) {
            contactCenterQueue = new Group(
                Name = System.Label.Contact_Center_Queue,
                DeveloperName = 'Manila_Contact_Center_Queue',
                Type = 'Queue'
            );
            insert contactCenterQueue;
            
            // Assign queue to Case object if newly created
            System.runAs(new User(Id = UserInfo.getUserId())) {
                QueueSObject q = new QueueSObject(
                    QueueId = contactCenterQueue.Id,
                    SobjectType = 'Case'
                );
                insert q;
            }
        }
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('uid', UID);
        params.put('userEmail', USER_EMAIL);
        params.put('subject', 'Test Subject');
        params.put('description', 'Test description');
        params.put('selectedProduct', 'Active Directory');
        params.put('selectedProduct2', 'General Product Inquiry and Features');
        params.put('severityLevel', 'Level 3 - High');
        params.put('alternateEmail', 'test@email.com');
        params.put('callbackPhone', '1234123123');
        params.put('timezone', '(GMT+03:00) Baghdad, Kuwait, Moscow, St. Petersburg, Nairobi');
        params.put('isGdpr', false);
        params.put('origin', CaseHelper.CASE_ORIGIN_WEB);
        
        String requestBody = JSON.serialize(params);
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        CaseCreateRestService.createCase();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
        
        Map<String, Object> resMap = (Map<String, Object>) Json.deserializeUntyped(RestContext.response.responseBody.toString());
        Case testCase = [SELECT OwnerId, RecordTypeId, Owner.Name, Owner.Type FROM Case WHERE Id = :(Id)resMap.get('caseId')];
        
        // Verify the case is assigned to the correct queue by DeveloperName
        Group assignedQueue = [SELECT Id, DeveloperName FROM Group WHERE Id = :testCase.OwnerId];
        System.assertEquals('Manila_Contact_Center_Queue', assignedQueue.DeveloperName, 
                            'Case should be assigned to Manila Contact Center queue');
        
        System.assertEquals(CaseHelper.RT_ID_SUPPORT_CASE, testCase.RecordTypeId, 'Case should have Support Case record type');
    }
 @isTest
private static void postCase_WhenisDataSubjectRequestIsTrue() {
    Test.startTest();
    Account acc = new Account(Name = 'Fixed Acc', RC_User_ID__c = '1822028005');
    insert acc;

    Contact con = new Contact(
        FirstName = 'Fixed',
        LastName = 'Contact',
        Email = 'form-script@ringcentral.com',
        AccountId = acc.Id
    );
    insert con;
    RestRequest request = new RestRequest();
    request.requestUri = URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/case-new';
    request.httpMethod = 'POST';
    RestContext.request = request;

    Map<String, Object> params = new Map<String, Object>{
        'uid' => acc.RC_User_ID__c,
        'userEmail' => con.Email,
        'subject' => 'Test Subject',
        'description' => 'Test description',
        'selectedProduct' => 'Phone',
        'selectedProduct2' => 'Porting/Number transfer',
        'severityLevel' => 'Level 3 - High',
        'alternateEmail' => 'test@email.com',
        'callbackPhone' => '1234123123',
        'timezone' => '(GMT+03:00) Baghdad, Kuwait, Moscow, St. Petersburg, Nairobi',
        'isGdpr' => false,
        'isDataSubjectRequest' => true,

        // Required fields for DSR logic
        'firstName' => 'John',
        'lastName' => 'Doe',
        'email' => 'john.doe@example.com',
        'privacyFirstName' => 'J.',
        'privacyLastName' => 'D.',
        'privacyEmail' => 'j.d@example.com',
        'action' => 'Change personal information',
        'ChangeAdditionalInformation' => 'Correct DOB',
        'country' => 'USA',
        'state' => 'California',
        'additionalInformation' => 'Extra info',
        'roleName' => 'Customer',
        'relation' => 'Self',
        'isRingCentralEventsAccount' => 'Yes',
        'isNiceContactCenterAccount' => 'Yes',
        'niceCCContactIds' => 'ID1;ID2',
        'niceCCAdditionalInfo' => 'Some additional NICE info'
    };

    String requestBody = JSON.serialize(params);
    RestContext.request.requestBody = Blob.valueOf(requestBody);
    CaseCreateRestService.createCase();
    Test.stopTest();
    List<Case> cases = [SELECT Id, Subject, Description FROM Case WHERE Subject LIKE 'Data Subject Request%' LIMIT 1];
    system.debug(cases[0].Subject);
    System.assert(!cases.isEmpty(), 'A case should have been created for DSR');
    System.assert(cases[0].Description.contains('Privacy First Name'), 'Description should include privacy fields');
 }
}