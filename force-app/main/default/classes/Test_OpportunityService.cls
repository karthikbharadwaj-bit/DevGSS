@isTest
private class Test_OpportunityService {

    @TestSetup
    static void prepare() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => testAccount.Id,
                Contact.LastName => 'John',
                Contact.FirstName => 'Doe',
                Contact.Email => 'contact1@ringcentral.tld'
            })
            .create()
            .getRecord();
    }

    static Account selectTestAccount() {
        List<Account> listAccounts = new AccountSelector()
            .selectAccounts()
            .selectFields(new List<SObjectField>{
                Account.Id, Account.Name, Account.OwnerId
            })
            .subselect(
                new ContactSelector()
                    .selectContacts()
                    .selectFields(new List<SObjectField>{
                        Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email
                    })
            )
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object>{
                'My Account'
            })
            .setLimit(1)
            .executeQuery();

        return listAccounts.size() == 0 ? null : listAccounts.get(0);
    }

    static List<Opportunity> selectTestOpportunities() {
        return new OpportunitySelector()
            .selectOpportunities()
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<SObjectField>{
                Opportunity.Id, Opportunity.Name, Opportunity.Type, Opportunity.CurrencyIsoCode,
                Opportunity.Brand_Name__c, Opportunity.Tier_Name__c, Opportunity.isFedRamp__c,
                Opportunity.ForcastedDimeloUsers__c, Opportunity.Forecast_Connect_First_Users__c,
                Opportunity.Forecasted_Users__c, Opportunity.Forecast_Contact_Center_Users__c,
                Opportunity.Forecasted_Global_Office_Users__c, Opportunity.Forecasted_RingCentral_Video_Users__c, Opportunity.Is_Billing_Opportunity__c, Opportunity.CloseDate, Opportunity.StageName
            })
            .executeQuery();
    }

    static BillingWrappers.OpportunityWrapper createOpportunityWrapper(String opportunityName, String brand, String service, String currencyCode) {
        BillingWrappers.OpportunityWrapper wrapper = new BillingWrappers.OpportunityWrapper();

        Account testAccount = selectTestAccount();
        Date closeDate = Date.today().addDays(30);

        wrapper.name = opportunityName;
        wrapper.currencyCode = currencyCode;
        wrapper.brand = brand;
        wrapper.service = service;
        wrapper.accId = testAccount.Id;
        wrapper.contId = testAccount.Contacts[0].Id;
        wrapper.contactRole = 'Signatory';
        wrapper.closedDate = String.valueOf(closeDate.year()) + '-' + String.valueOf(closeDate.month()) + '-' + String.valueOf(closeDate.day());
        wrapper.recordTypeId = Opportunity.SObjectType.getDescribe()
            .getRecordTypeInfosByName()
            .get('New Sales Opportunity').getRecordTypeId();
        wrapper.leadSource = 'Call';
        wrapper.type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS;
        wrapper.provisioningDetails = 'details';
        wrapper.isFedRamp = false;

        return wrapper;
    }

    static RestRequest createRequest(String action, BillingWrappers.OpportunityWrapper opportunityWrapper) {
        BillingWrappers.OpportunityServiceParams params = new BillingWrappers.OpportunityServiceParams();

        params.action = action;
        params.opportunityWrapper = opportunityWrapper;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        return request;
    }

    static RestRequest createRequest(String action, BillingWrappers.DQParams dealQualificationParams) {
        BillingWrappers.OpportunityServiceParams params = new BillingWrappers.OpportunityServiceParams();

        params.action = action;
        params.dealQualificationParams = dealQualificationParams;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        return request;
    }

    private static User createTestUser() {
        return (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();
    }

    @isTest
    static void testOpportunityCreation() {
        BillingWrappers.OpportunityWrapper wrapper = createOpportunityWrapper('Test', 'RingCentral', 'Office', 'AUD');

        RestContext.request = createRequest(OpportunityService.ACTION_CREATE_OPPORTUNITY, wrapper);

        Test.startTest();
            OpportunityService.doPost();
        Test.stopTest();

        List<Opportunity> opps = selectTestOpportunities();

        System.assertEquals(1, opps.size());
        System.assertEquals('Test', opps[0].Name);
        System.assertEquals('RingCentral', opps[0].Brand_Name__c);
        System.assertEquals('Office', opps[0].Tier_Name__c);
        System.assertEquals('Existing Business', opps[0].Type);
        System.assertEquals('AUD', opps[0].CurrencyIsoCode);
    }

    @isTest
    static void testOpportunityCreationShouldThrowException() {
        BillingWrappers.OpportunityWrapper wrapper = createOpportunityWrapper('Test', 'RingCentral', 'Office', 'AUD');

        RestContext.request = createRequest(OpportunityService.ACTION_CONFIRM_AND_CLOSE_OPPORTUNITY, wrapper);

        Test.startTest();
            OpportunityService.doPost();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        System.assert(
            body.contains('Confirm and close request invalid'),
            'Response should contain info about invalid request'
        );
    }

    @isTest
    static void testOpportunityCreationWithFedRamp() {
        BillingWrappers.OpportunityWrapper wrapper = createOpportunityWrapper('Test', 'RC FedRAMP', 'Office', 'USD');
        wrapper.type = OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS;
        wrapper.isFedRamp = true;

        RestContext.request = createRequest(OpportunityService.ACTION_CREATE_OPPORTUNITY, wrapper);

        Test.startTest();
            OpportunityService.doPost();
        Test.stopTest();

        List<Opportunity> opps = selectTestOpportunities();

        System.assertEquals(1, opps.size(), 'Opportunity was not created');
        System.assertEquals('Test', opps[0].Name, 'Opportunity was created with invalid Name');
        System.assertEquals('RC FedRAMP', opps[0].Brand_Name__c, 'Opportunity was created with invalid Brand');
        System.assertEquals('Office', opps[0].Tier_Name__c, 'Opportunity was created with invalid Service');
        System.assertEquals('New Business', opps[0].Type, 'Opportunity was created with invalid Type');
        System.assertEquals('USD', opps[0].CurrencyIsoCode, 'Opportunity was created with invalid Currency');
        System.assertEquals(true, opps[0].isFedRamp__c, 'Opportunity should be created with FedRamp = true');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testOpportunityCreationWithFromContact() {
        BillingWrappers.OpportunityWrapper wrapper = createOpportunityWrapper('Test', 'RC FedRAMP', 'Office', 'USD');
        wrapper.type = OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS;
        wrapper.fromContact = '1';
        wrapper.fromContactId = wrapper.contId;
        wrapper.contactCenterUsers = '10';
        wrapper.engageDigitalUsers = '20';
        wrapper.engageVoiceUsers = '30';
        wrapper.globalOfficeUsers = '40';
        wrapper.officeUsers = '50';
        wrapper.rcVideoUsers = '60';
        wrapper.rcEventUsers = '0';

        Task tsk = new Task(WhoId = wrapper.contId);
        insert tsk;

        Lead_Qualification__c lq = new Lead_Qualification__c(Contact__c =  wrapper.contId);
        insert lq;

        RestContext.request = createRequest(OpportunityService.ACTION_CREATE_OPPORTUNITY, wrapper);

        Test.startTest();
            OpportunityService.doPost();
        Test.stopTest();

        List<Opportunity> opps = selectTestOpportunities();

        /*System.assertEquals(1, opps.size(), 'Opportunity was not created');
        System.assertEquals('Test', opps[0].Name, 'Opportunity was created with invalid Name');
        System.assertEquals('RC FedRAMP', opps[0].Brand_Name__c, 'Opportunity was created with invalid Brand');
        System.assertEquals('Office', opps[0].Tier_Name__c, 'Opportunity was created with invalid Service');
        System.assertEquals('New Business', opps[0].Type, 'Opportunity was created with invalid Type');
        System.assertEquals('USD', opps[0].CurrencyIsoCode, 'Opportunity was created with invalid Currency');
        System.assertEquals(20, opps[0].ForcastedDimeloUsers__c, 'Opportunity should be created with Forecasted Engage Digital Users with 20');
        System.assertEquals(30, opps[0].Forecast_Connect_First_Users__c, 'Opportunity should be created with Forecasted Engage Voice Users with 30');
        System.assertEquals(50, opps[0].Forecasted_Users__c, 'Opportunity should be created with Forecasted Office Users with 50');
        System.assertEquals(10, opps[0].Forecast_Contact_Center_Users__c, 'Opportunity should be created with Forecasted Contact Center Users with 10');
        System.assertEquals(40, opps[0].Forecasted_Global_Office_Users__c, 'Opportunity should be created with Forecasted Global Office Users with 40');
        System.assertEquals(60, opps[0].Forecasted_RingCentral_Video_Users__c, 'Opportunity should be created with Forecasted RingCentral Video Users with 60');*/
    }

    @isTest
    static void testGetDealQualification() {
        RestContext.request = createRequest(OpportunityService.ACTION_GET_DEAL_QUALIFICATION, new BillingWrappers.DQParams());

        Test.startTest();
            OpportunityService.doPost();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(body, DQServiceHelper.DQResponse.class);
        BillingWrappers.DealQualification dqRecord = resp.dqRecord;
        System.assertEquals(
            null,
            resp.dqRecord,
            'service should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if DQ_Deal_Qualification__c is not exist for opportunity'
        );

        // other unit tests for this action can be found in Test_DQServiceHelper
    }

    @isTest
    static void testSyncDealQualification() {
        RestContext.request = createRequest(OpportunityService.ACTION_SYNC_DEAL_QUALIFICATION, new BillingWrappers.DQParams());

        Test.startTest();
            OpportunityService.doPost();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(body, DQServiceHelper.DQResponse.class);
        BillingWrappers.DealQualification dqRecord = resp.dqRecord;
        System.assertEquals(
            null,
            resp.dqRecord,
            'service should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if DQ_Deal_Qualification__c is not exist for opportunity'
        );

        //other unit tests for this action can be found in Test_DQServiceHelper
    }

    @isTest
    static void testUpdateDQStatus() {
        RestContext.request = createRequest(OpportunityService.ACTION_UPDATE_DQ_STATUS, new BillingWrappers.DQParams());

        Test.startTest();
            OpportunityService.doPost();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(body, DQServiceHelper.DQResponse.class);
        BillingWrappers.DealQualification dqRecord = resp.dqRecord;
        System.assertEquals(
            null,
            resp.dqRecord,
            'service should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if DQ_Deal_Qualification__c is not exist for opportunity'
        );

        // other unit tests for this action can be found in Test_DQServiceHelper
    }

    @isTest
    static void testSaveDealQualification() {

        RestContext.request = createRequest(OpportunityService.ACTION_SAVE_DEAL_QUALIFICATION, new BillingWrappers.DQParams());

        Test.startTest();
            OpportunityService.doPost();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(body, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'service should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if passed argument is null'
        );

        // other unit tests for this action can be found in Test_DQServiceHelper
    }

    @isTest
    static void testReviseDealQualification() {

        RestContext.request = createRequest(OpportunityService.ACTION_REVISE_DQ, new BillingWrappers.DQParams());

        Test.startTest();
            OpportunityService.doPost();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(body, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'service should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if passed argument is null'
        );
    }

    @isTest
    static void testCreateDQApprover() {

        RestContext.request = createRequest(OpportunityService.ACTION_CREATE_DQ_APPROVER, new BillingWrappers.DQParams());

        Test.startTest();
            OpportunityService.doPost();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(body, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'service should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if passed argument is null'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetApproversForDq() {

        User testApprover = createTestUser();
        User testOppOwner = createTestUser();

        DQ_Approval_Step__c dqApprovalStep = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step__c.Name => 'Level 1',
                    DQ_Approval_Step__c.Step_Order__c => 1
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type__c dqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_SPECIAL_TERM,
                    DQ_Approval_Type__c.Special_Terms__c => '6 Free Months of Service',
                    DQ_Approval_Type__c.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type_Step__c approvalTypeStep =
            (DQ_Approval_Type_Step__c) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type_Step__c.DQ_Approval_Type__c => dqApprovalType.Id,
                    DQ_Approval_Type_Step__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                    DQ_Approval_Type_Step__c.Region__c => 'US',
                    DQ_Approval_Type_Step__c.Segment__c => 'Default',
                    DQ_Approval_Type_Step__c.Deal_Type__c => 'Direct',
                    DQ_Approval_Type_Step__c.Brand__c => 'Default',
                    DQ_Approval_Type_Step__c.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Step_Approver__c approvalStepApprover =
            (DQ_Approval_Step_Approver__c) new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step_Approver__c.Approval_Type__c => 'Approval',
                    DQ_Approval_Step_Approver__c.OwnerId => testApprover.Id,
                    DQ_Approval_Step_Approver__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                    DQ_Approval_Step_Approver__c.Region__c => 'US',
                    DQ_Approval_Step_Approver__c.Segment__c => 'Default',
                    DQ_Approval_Step_Approver__c.Deal_Type__c => 'Direct',
                    DQ_Approval_Step_Approver__c.Brand__c => 'Default',
                    DQ_Approval_Step_Approver__c.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.OwnerId => testOppOwner.Id,
                Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Opportunity.RecordTypeId => Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                    Quote.isPrimary__c => true,
                    Quote.Initial_Term_Months__c => '12'
                }
            )
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id,
                DQ_Deal_Qualification__c.Quote__c => testQuote.Id,
                DQ_Deal_Qualification__c.Special_Terms__c => '6 Free Months of Service'
            })
            .create()
            .getRecord();

        BillingWrappers.DQParams params = new BillingWrappers.DQParams();
        params.dqOrOppId = testDqRecord.Id;

        Test.startTest();
            RestContext.request = createRequest(OpportunityService.ACTION_GET_APPROVERS_FOR_DQ, params);
            OpportunityService.doPost();
            String body = RestContext.response.responseBody.toString();
        Test.stopTest();

        /*List<DQGoa.ApproverData> approversList = (List<DQGoa.ApproverData>) JSON.deserialize(body, List<DQGoa.ApproverData>.class);
        System.assertEquals(
            2,
            approversList.size(),
            '2 approver for special terms should be returned'
        );
        DQGoa.ApproverData approver = approversList.get(0);
        System.assert(approver.approvalReason.contains(testDqRecord.Special_Terms__c), 'approvalReason should contains specified Special_Terms__c');
        System.assertEquals(DQGoa.APPROVER_NOTIFICATION_TYPE_APPROVAL, approver.notificationType, 'notification type should be "Approval"');*/
        }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testInsertion() {
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Sales Agent SDR w Insidesales'];
        User usr = new User(
            ProfileId = prof.Id,
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser757@example.com',
            Alias = 'tuser',
            Username = 'testuser757@example.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert usr;

        System.runAs(usr) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            Task tsk = new Task(
                Subject = 'Test Task',
                WhatId = acc.Id,
                Status = 'Not Started'
            );
            Test.startTest();
            insert tsk;
            Test.stopTest();
        }
    }

    @isTest
    static void testPSChangeOrderOpportunityCreation() {
        Account testAccount = selectTestAccount();
        BillingWrappers.OpportunityWrapper wrapper = createOpportunityWrapper('Test', OpportunityHelper.BRAND_RINGCENTRAL, OpportunityHelper.TIER_PROFESSIONAL_SERVICES, 'USD');
        wrapper.type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS;
        wrapper.accOwnerId = testAccount.OwnerId;

        RestContext.request = createRequest(OpportunityService.ACTION_CREATE_CHANGE_ORDER_OPPORTUNITY, wrapper);

        Test.startTest();
            OpportunityService.doPost();
        Test.stopTest();

        Opportunity opp = selectTestOpportunities().get(0);

        System.assertNotEquals(null, opp, 'Opportunity was not created');
        System.assertEquals('Test', opp.Name, 'Opportunity was created with invalid Name');
        System.assertEquals(OpportunityHelper.BRAND_RINGCENTRAL, opp.Brand_Name__c, 'Opportunity was created with invalid Brand');
        System.assertEquals(OpportunityHelper.TIER_PROFESSIONAL_SERVICES, opp.Tier_Name__c, 'Opportunity was created with invalid Service');
        System.assertEquals(OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS, opp.Type, 'Opportunity was created with invalid Type');
        System.assertEquals(true, opp.Is_Billing_Opportunity__c, 'Opportunity was created with incorrect Billing Opportunity field');
        System.assertEquals('1. Qualify', opp.StageName, 'Opportunity was created with incorrect StageName field');
        System.assertEquals(System.today(), opp.CloseDate, 'Opportunity was created with incorrect CloseDate field');   
    }
}