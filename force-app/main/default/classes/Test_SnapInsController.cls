@isTest
private class Test_SnapInsController {
    private static final String OFFLINE_API_RESPONSE =
        '{"messages":[{"type":"Availability", "message":{"results":[{"id":"57334000000GnNv"}]}}]}';
    private static final String ONLINE_API_RESPONSE =
        '{"messages":[{"type":"Availability", "message":{"results":[{"id":"57334000000GnNv","isAvailable":true}]}}]}';
    private static final String ERROR_API_RESPONSE =
        '{"messages":[{"type":"Error", "message":{"text":"Temporary system throttling, deployment disabled"}}]}';
    private static final String ERROR_API_RESPONSE_SWITCH_SERVER =
        '{"messages":[{"type":"SwitchServer", "message":{"newUrl":"salesforceliveagent.com/chat"}}]}';
    private static final String CONTACT_EMAIL = 'test@test.com';

    @testSetup
    private static void createTestData() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.AccountId,acc.Id)
            .setField(Contact.Email, CONTACT_EMAIL)
            .setField(Contact.Phone, '1234567890')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .create();

        new SObjectBuilder(SnapInsSettings__c.SObjectType)
            .setField(SnapInsSettings__c.PathForArticleHowToUpgrade__c, 'https://www.test1.com')
            .setField(SnapInsSettings__c.PathForArticleRequireData__c, 'https://www.test2.com')
            .setField(SnapInsSettings__c.PathForSnapInsCoveoSearch__c, 'https://www.test3.com')
            .setField(SnapInsSettings__c.EmailsForErrorNotification__c, 'test@email.com\n' + 
                'test2@email.com')
            .setField(SnapInsSettings__c.IsErrorNotificationSent__c, false)
            .create();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)  
            .setField(Feature_Toggle__c.EnableOmniChannelRouting__c, true)
            .create();
    }

    private static void createTestDataForRouting(String test_RC_Service_name, Decimal test_Number_of_DL_s,
                                                 String test_Offer_Type, String test_RC_Brand, Decimal test_No_of_InContact_Seats) {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'testAcc')
            .setField(Account.RC_Service_name__c, test_RC_Service_name)
            .setField(Account.Number_of_DL_s__c, test_Number_of_DL_s)
            .setField(Account.Offer_Type__c, test_Offer_Type)
            .setField(Account.RC_Brand__c, test_RC_Brand)
            .setField(Account.No_of_InContact_Seats__c, test_No_of_InContact_Seats)
            .create()
            .getRecord();

        new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test Contact')
            .setField(Contact.LastName, 'Test Contact')
            .setField(Contact.AccountId,acc.Id)
            .setField(Contact.Email, CONTACT_EMAIL)
            .setField(Contact.Phone, '1234567890')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .create();
    }

    @isTest static void testSnapInsControllerSearchForContacts() {
        System.assert(SnapInsController.searchContacts(CONTACT_EMAIL).size() > 0,
            'There should be contacts with those email');
    }

    @isTest static void testSnapInsControllerSearchForContactsButNoOneFound() {
        System.assertEquals(SnapInsController.searchContacts('test' + CONTACT_EMAIL).size(), 0,
            'There should be no contacts with those email');
    }

    @isTest static void testGetPicklistValuesForCompanyEmployeeNumberInContact() {
        List<String> picklistValuesOfCompanyEmployeeNumberInContact = new List<String>{
            '1-19', '20-99', '100-399', '400-4999', '5000+'};
        System.assertEquals(picklistValuesOfCompanyEmployeeNumberInContact,
            SnapInsController.getPicklistValues('Contact', 'CompanyEmployeeNumber__c'),
                'The picklist values of CompanyEmployeeNumber in Contact should be different');
    }

    // test sales routing
    private static List<SObject> testDefineSales(String test_RC_Service_name, Decimal test_Number_of_DL_s) {
        createTestDataForRouting(test_RC_Service_name , test_Number_of_DL_s , null , null , null );
        List<SObject> contacts = [SELECT Id, FirstName, LastName, Company__c, NumberOfEmployees__c, Account.Name,
                                    Account.RC_Service_name__c, Account.Total_Account_DL_s__c, Account.Offer_Type__c,
                                    Account.RC_Brand__c, Account.No_of_InContact_Seats__c
                                FROM Contact WHERE LastName = 'Test Contact'];
        return contacts;
    }

    @isTest static void testDefineSalesRCServiceNameFax() {
        System.assertEquals('US_Fax',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales('Fax test', null)),
                'RC_Service_name is not contatints Fax value');
    }

    @isTest static void testDefineSalesRCServiceNamePro() {
        System.assertEquals('US_Pro',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales('Professional test', null)),
                'RC_Service_name is not contatints Professional value');
    }

    @isTest static void testDefineSalesNumberOfDLsEquals1() {
        System.assertEquals('US_Just_Me',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales(null, 1)),
                'Number_of_DL_s is not >= 0 and <= 1');
    }

    @isTest static void testDefineSalesNumberOfDLsEquals3() {
        System.assertEquals('US_2_4',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales(null, 3)),
                'Number_of_DL_s is not >= 2 and <= 4');
    }

    @isTest static void testDefineSalesNumberOfDLsEquals6() {
        System.assertEquals('US_5_9',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales(null, 6)),
                'Number_of_DL_s is not >= 5 and <= 9');
    }

    @isTest static void testDefineSalesNumberOfDLsEquals12() {
        System.assertEquals('US_10_19',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales(null, 12)),
                'Number_of_DL_s is not >= 10 and <= 19');
    }

    @isTest static void testDefineSalesNumberOfDLsEquals30() {
        System.assertEquals('US_20_49',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales(null, 30)),
                'Number_of_DL_s is not >= 20 and <= 49');
    }

    @isTest static void testDefineSalesNumberOfDLsEquals60() {
        System.assertEquals('US_50_99',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales(null, 60)),
                'Number_of_DL_s is not >= 50 and <= 99');
    }

    @isTest static void testDefineSalesNumberOfDLsEquals120() {
        System.assertEquals('US_100_249',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales(null, 120)),
                'Number_of_DL_s is not >= 100 and <= 249');
    }

    @isTest static void testDefineSalesNumberOfDLsEquals260() {
        System.assertEquals('US_250_499',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales(null, 260)),
                'Number_of_DL_s is not >= 250 and <= 499');
    }

    @isTest static void testDefineSalesNumberOfDLsEquals600() {
        System.assertEquals('US_500_999',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales(null, 600)),
               'Number_of_DL_s is not >= 500 and <= 999');
    }

    @isTest static void testDefineSalesNumberOfDLs1001() {
        System.assertEquals('US_1000',
            SnapInsController.defineDeveloperNameChatButtonSales(testDefineSales(null, 1001)),
                'Number_of_DL_s is not > 1000');
    }

    // test support routing
    private static List<SObject> testDefineSupport(String test_RC_Service_name, Decimal test_Number_of_DL_s,
                                                 String test_Offer_Type, String test_RC_Brand, Decimal test_No_of_InContact_Seats) {
        Test.startTest();
        createTestDataForRouting(test_RC_Service_name, test_Number_of_DL_s, test_Offer_Type,
                                    test_RC_Brand, test_No_of_InContact_Seats );
        Test.stopTest();
        List<SObject> contacts = [SELECT Id, FirstName, LastName, Company__c, NumberOfEmployees__c, Account.Name,
                                    Account.RC_Service_name__c, Account.Total_Account_DL_s__c,
                                    Account.Offer_Type__c, Account.RC_Brand__c, Account.No_of_InContact_Seats__c
                                FROM Contact WHERE LastName = 'Test Contact'];
        return contacts;
    }

    @isTest static void testDefineSupportRCServiceNameEqualsRCMeetingAndOfferTypeIsNotFree() {
        System.assertEquals('Support_Inbound_Chat_Freyja',
            SnapInsController.getSupportChatButton(testDefineSupport('RCMeetings', null, 'Not Free', null, null)),
                'RC_Service_name is not RCMeetings or Offer_Type is Free');
    }

    @isTest static void testDefineSupportRCServiceNameContainsUKAndRCBrandContainsUK() {
        System.assertEquals('Support_Inbound_Chat_UK',
            SnapInsController.getSupportChatButton(testDefineSupport('UK Test', null, null, 'UK Test', null)),
                'RC_Service_name is not containts UK or RC_Brand is not containts UK');
    }

    @isTest static void testDefineSupportRCServiceNameContainsAUAndRCBrandContainsAU() {
        System.assertEquals('Support_Inbound_Chat_AU',
            SnapInsController.getSupportChatButton(testDefineSupport('AU Test', null, null, 'AU Test', null)),
                'RC_Service_name is not containts AU or RC_Brand is not containts AU');
    }

   @isTest static void testDefineSupportRCServiceNameFax() {
        System.assertEquals('Support_Inbound_Chat_Fax',
            SnapInsController.getSupportChatButton(testDefineSupport('Fax test', null, null, null, null)),
                'RC_Service_name is not contatints Fax value');
    }

    @isTest static void testDefineSupportRCServiceNamePro() {
        System.assertEquals('Support_Inbound_Chat_Pro',
            SnapInsController.getSupportChatButton(testDefineSupport('Professional test', null, null, null, null)),
                'RC_Service_name is not contatints Professional value');
    }

    @isTest static void testDefineSupportNoOfInContactSeatsIsNotNullAndNumberOfDLsIs10(){
        System.assertEquals('Support_CC_Inbound_Chat_1_99',
            SnapInsController.getSupportChatButton(testDefineSupport(null, 10, null, null, 1)),
                'No_of_InContact_Seats is null OR Number_of_DL_s is not between 1 to 99');
    }

    @isTest static void testDefineSupportNoOfInContactSeatsIsNotNullAndNumberOfDLsIs100(){
        System.assertEquals('Support_CC_Inbound_Chat_100',
            SnapInsController.getSupportChatButton(testDefineSupport(null, 100, null, null, 1)),
                'No_of_InContact_Seats is null OR Number_of_DL_s is not >= 100');
    }

    @isTest static void testDefineSupportNumberOfDLsEquals1() {
        System.assertEquals('Support_Inbound_Chat_0_1',
            SnapInsController.getSupportChatButton(testDefineSupport(null, 1, null, null, null)),
                'Number_of_DL_s is not >= 0 and <= 1');
    }

    @isTest static void testDefineSupportNumberOfDLsEquals5() {
        System.assertEquals('Support_Inbound_Chat_2_19',
            SnapInsController.getSupportChatButton(testDefineSupport(null, 5, null, null, null)),
                'Number_of_DL_s is not >= 2 and <= 19');
    }

    @isTest static void testDefineSupportNumberOfDLsEquals30() {
        System.assertEquals('Support_Inbound_Chat_20_49',
            SnapInsController.getSupportChatButton(testDefineSupport(null, 30, null, null, null)),
                'Number_of_DL_s is not >= 20 and <= 49');
    }

    @isTest static void testDefineSupportNumberOfDLsEquals60() {
        System.assertEquals('Support_Inbound_Chat_50_99',
            SnapInsController.getSupportChatButton(testDefineSupport(null, 60, null, null, null)),
                'Number_of_DL_s is not >= 50 and <= 99');
    }

    @isTest static void testDefineSupportNumberOfDLsEquals120() {
        System.assertEquals('Support_Inbound_Chat_100_999',
            SnapInsController.getSupportChatButton(testDefineSupport(null, 120, null, null, null)),
                'Number_of_DL_s is not >= 100 and <= 999');
    }

    @isTest static void testDefineSupportNumberOfDLsEquals1001() {
        System.assertEquals('Support_Inbound_Chat_1000',
            SnapInsController.getSupportChatButton(testDefineSupport(null, 1001, null, null, null)),
                'Number_of_DL_s is not > 1000');
    }

    // test isFreeRCMeetingCustomer
    @isTest static void testIsFreeRCMeetingCustomerWithOfferTypeNotFree() {
        System.assertEquals('not free',
            SnapInsController.isFreeRCMeetingCustomer(testDefineSupport('RCMeetings', null, 'Not Free', null, null)),
                'RC_Service_name is not RCMeetings or Offer_Type is Free');
    }

    @isTest static void testIsFreeRCMeetingCustomerWithOfferTypeFree() {
        System.assertEquals('free',
            SnapInsController.isFreeRCMeetingCustomer(testDefineSupport('RCMeetings', null, 'Free', null, null)),
                'RC_Service_name is not RCMeetings or Offer_Type is not Free');
    }

    @isTest static void testHelperSnapInsControllerMethods() {
        List<SObject> contacts = testDefineSales(null, 1);
        //testDefineSalesByEmployeeNumber
        System.assertEquals('US_Just_Me', SnapInsController.defineDeveloperNameSalesByEmployeeNumber('Just Me'),
            'EmployeeNumber is not Just Me');
        System.assertEquals('US_2_4', SnapInsController.defineDeveloperNameSalesByEmployeeNumber('2-4'),
            'EmployeeNumber is not 2-4');
        System.assertEquals('US_5_9', SnapInsController.defineDeveloperNameSalesByEmployeeNumber('5-9'),
            'EmployeeNumber is not 5-9');
        System.assertEquals('US_10_19', SnapInsController.defineDeveloperNameSalesByEmployeeNumber('10-19'),
            'EmployeeNumber is not 10-19');
        System.assertEquals('US_20_49', SnapInsController.defineDeveloperNameSalesByEmployeeNumber('20-49'),
            'EmployeeNumber is not 20-49');
        System.assertEquals('US_50_99', SnapInsController.defineDeveloperNameSalesByEmployeeNumber('50-99'),
            'EmployeeNumber is not 50-99');
        System.assertEquals('US_100_249', SnapInsController.defineDeveloperNameSalesByEmployeeNumber('100-249'),
            'EmployeeNumber is not 100-249');
        System.assertEquals('US_250_499', SnapInsController.defineDeveloperNameSalesByEmployeeNumber('250-499'),
            'EmployeeNumber is not 250-499');
        System.assertEquals('US_500_999', SnapInsController.defineDeveloperNameSalesByEmployeeNumber('500-999'),
            'EmployeeNumber is not 500-999');
        System.assertEquals('US_1000', SnapInsController.defineDeveloperNameSalesByEmployeeNumber('1000+'),
            'EmployeeNumber is not 1000+');
        System.assertEquals('US_Just_Me', SnapInsController.defineDeveloperNameSalesByEmployeeNumber('another'),
            'EmployeeNumber is not another');
        
        //testSnapInsSettings
        System.assertEquals('https://www.test1.com',
            SnapInsController.getUrlPathForKA().PathForArticleHowToUpgrade__c,
                'PathForArticleHowToUpgrade is different');
        System.assertEquals('https://www.test2.com',
            SnapInsController.getUrlPathForKA().PathForArticleRequireData__c,
                'PathForArticleRequireData is different');
        System.assertEquals('https://www.test3.com',
            SnapInsController.getUrlPathForKA().PathForSnapInsCoveoSearch__c,
                'PathForSnapInsCoveoSearch is different');
        
        //testSnapInsSettingsPathToSearch
        System.assertEquals('https://www.test3.com?lang=en', SnapInsController.setLanguageForCoveoResultPage('en'),
            'PathForSnapInsCoveoSearch is different');
        
        //testDefineCompanyName
        System.assertEquals('testAcc', SnapInsController.defineCompanyName(contacts), 'Company Name is different');
        
        //testDefineEmployeeNumber
        System.assertEquals('Just Me', SnapInsController.defineEmployeeNumber(contacts), 'Range is not 0-1');
        
        //testEnableChatButton
        System.assertEquals('sales', SnapInsController.defineSales(contacts, 'none'), 'Should be sales');
        System.assertEquals('support', SnapInsController.defineSupport(contacts, 'agent'), 'Should be support'); 
        System.assertEquals('sales', SnapInsController.defineSalesByEmployeeNumber('Just Me', 'none'), 'Should be sales');
        System.assertEquals('sales', SnapInsController.defineSalesByEmployeeNumber('Just Me', 'fax'), 'Should be sales');
        
        //testGetRoutingType
        System.assertEquals('US_Fax', SnapInsController.getRoutingType('fax'), 'Should be US_Fax');
        System.assertEquals('US_Pro', SnapInsController.getRoutingType('pro'), 'Should be US_Pro');
        System.assertEquals('none', SnapInsController.getRoutingType('none'), 'Should be none');
        System.assertEquals('none', SnapInsController.getRoutingType('unknown'), 'Should be none');
    }
    
    @isTest static void testDefineSalesAndSupportInformation() {
        List<SObject> contacts = testDefineSupport(null, null, null, null, null);
        List<String> salesAndSupportInformation = 
            SnapInsController.defineSalesAndSupportInformation(contacts, 'none', 'agent');
        List<String> salesInformation = SnapInsController.defineSalesInformation(contacts, 'fax');
        List<String> supportInformation = SnapInsController.defineSupportInformation(contacts, 'agent');
        
        System.assertEquals('sales', salesAndSupportInformation[0], 'This is a sales');
        System.assertEquals('support', salesAndSupportInformation[1], 'This is a support');
        System.assertEquals('testAcc', salesAndSupportInformation[2], 'Test acc name is a testAcc');
        System.assertEquals('Just Me', salesAndSupportInformation[3], 'Just Me Company');
        System.assertEquals('not free', salesAndSupportInformation[4], 'Not free company');
       
        System.assertEquals('sales', salesInformation[0], 'This is a sales');
        System.assertEquals('testAcc', salesInformation[1], 'Test acc name is testAcc');
        System.assertEquals('Just Me', salesInformation[2], 'Just Me Company');
        
        System.assertEquals('support', supportInformation[0], 'This is support');
        System.assertEquals('testAcc', supportInformation[1], 'Test acc name is testAcc');
        System.assertEquals('Just Me', supportInformation[2], 'Just Me Company');
        System.assertEquals('not free', supportInformation[3], 'Not free company');
    }

    @isTest static void chatButtonOnlineWhenResponseOnline() {
        TestHttpCalloutMock onlineResponse = new TestHttpCalloutMock(200, 'Complete', ONLINE_API_RESPONSE);
        Test.setMock(HttpCalloutMock.class, onlineResponse);

        Test.startTest();

        System.assertEquals(ONLINE_API_RESPONSE, SnapInsController.getCalloutResponseContents('test'), 
            'Body is not the same');
        System.assertEquals('online', SnapInsController.isSalesBucketAgentsOnline(), 
            'Agent should be online');
        System.assert(SnapInsController.isAgentsOnlineForChatButton('developerButtonName'), 
            'Agent should be available');

        Test.stopTest();
    }

    @isTest static void chatButtonOfflineWhenResponseOffline() {
        TestHttpCalloutMock offlineResponse = new TestHttpCalloutMock(200, 'Complete', OFFLINE_API_RESPONSE);
        Test.setMock(HttpCalloutMock.class, offlineResponse);

        Test.startTest();

        System.assertEquals(OFFLINE_API_RESPONSE, SnapInsController.getCalloutResponseContents('test'), 
            'Body is not the same');
        System.assertEquals('offline', SnapInsController.isSalesBucketAgentsOnline(), 
            'Agent should be offline');
        System.assert(!SnapInsController.isAgentsOnlineForChatButton('developerButtonName'), 
            'Agent should be not available');

        Test.stopTest();
    }

    @isTest static void chatButtonOfflineAndErrorEmailNotSentWhenResponseError() {
        TestHttpCalloutMock errorResponse = new TestHttpCalloutMock(200, 'Complete', ERROR_API_RESPONSE);
        Test.setMock(HttpCalloutMock.class, errorResponse);

        Test.startTest();

        System.assertEquals(ERROR_API_RESPONSE, SnapInsController.getCalloutResponseContents('test'), 
            'Body is not the same');
        System.assertEquals('offline', SnapInsController.isSalesBucketAgentsOnline(), 
            'Agent should be offline');
        System.assert(!SnapInsController.isAgentsOnlineForChatButton('developerButtonName'), 
            'Agent should be not available');
        
        SnapInsSettings__c snapInSetting = SnapInsSettings__c.getOrgDefaults();
        System.assert(!snapInSetting.IsErrorNotificationSent__c, 'Error notification should not be sent');
        
        if (!((Organization) new OrganizationSelector().selectOrg().executeQuery().get(0)).IsSandbox) {
            System.assertEquals(0, Limits.getEmailInvocations(), 'Email should not be sent');
        }

        Test.stopTest();
    }

    @isTest static void chatButtonOfflineAndErrorEmailSentWhenResponseSwitchServerError() {
        TestHttpCalloutMock switchServerErrorResponse = 
            new TestHttpCalloutMock(200, 'Complete', ERROR_API_RESPONSE_SWITCH_SERVER);
        Test.setMock(HttpCalloutMock.class, switchServerErrorResponse);

        Test.startTest();

        System.assertEquals(ERROR_API_RESPONSE_SWITCH_SERVER, SnapInsController.getCalloutResponseContents('test'), 
            'Body is not the same');
        System.assertEquals('offline', SnapInsController.isSalesBucketAgentsOnline(), 
            'Agent should be offline');
        System.assert(!SnapInsController.isAgentsOnlineForChatButton('developerButtonName'), 
            'Agent should be not available');
        
        SnapInsSettings__c snapInSetting = SnapInsSettings__c.getOrgDefaults();
        System.assert(snapInSetting.IsErrorNotificationSent__c, 'Error notification should be sent');

        Integer actualLimits = Limits.getEmailInvocations();
        Integer expectedLimits = 1;
        if (!((Organization) new OrganizationSelector().selectOrg().executeQuery().get(0)).IsSandbox) {
            System.assertEquals(expectedLimits, actualLimits, 'Emails should be sent');
        }

        Test.stopTest();
    }
}