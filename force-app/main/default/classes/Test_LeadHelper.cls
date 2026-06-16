@isTest
private class Test_LeadHelper {

    @testSetup static void setup(){

        User marketingUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestmarketingUser',
                    User.Username => 'marketingUser!user@gmail.com',
                    User.Email => 'marketingUser_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.UserPermissionsMarketingUser => true
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => ValueProviderBuilder.provideList(new List<String> {'rcsfsyncuser', 'suniluser'}),
                    Emails__c.Email_Address__c => ValueProviderBuilder.provideList(new List<String> {'rcsf@fakemail.com', 'sunil@fakemail.com'})
                }
            )
            .quantity(2)
            .create();

        System.runAs(marketingUser) {
            Campaign testCampaign = (Campaign) new SObjectBuilder(Campaign.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Campaign.Name => 'fakeCampaign',
                        Campaign.DNIS__c => '1111',
                        Campaign.AID__c => '2222',
                        Campaign.BMID__c => '3333',
                        Campaign.Pid__c => '4444'
                    }
                )
                .create()
                .getRecord();
        }

        Lead testSetupLead1 = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .build()
            .getRecord();

        Lead testSetupLead2 = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'testLead2@test.com',
                    Lead.LastName => 'test2',
                    Lead.Phone => '22222',
                    Lead.Company => 'fakeCompany',
                    Lead.LeadSource => 'Inbound Call',
                    Lead.OwnerId => String.valueOf(UserInfo.getUserId() )
                }
            )
            .build()
            .getRecord();
        insert new List<Lead>{testSetupLead1,testSetupLead2};
    }

    @isTest static void testPopulateNewPhoneExistingPhoneNumber(){

        Lead testLead = [   SELECT Id, Name, Phone
                            FROM Lead
                            WHERE LastName = 'test2'
                            LIMIT 1];
        Campaign testCampaign = [   SELECT Id, Name, DNIS__c, BMID__c
                                    FROM Campaign
                                    WHERE Name = 'fakeCampaign'
                                    LIMIT 1];

        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = (INVOCA_FOR_SF__Invoca_Call_Log__c) new SObjectBuilder(INVOCA_FOR_SF__Invoca_Call_Log__c.SObjectType)
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__transaction_id__c , '123456')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c , testCampaign.BMID__C)
            .create()
            .getRecord();


        PageReference pageRef = Page.LeadSearchExtension;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('dnis', '1234');
        ApexPages.currentPage().getParameters().put('ani', '22222');
        ApexPages.currentPage().getParameters().put('claimedUpLeadId', testLead.Id);
        ApexPages.currentPage().getParameters().put('claimedUpLeadDnis', testCampaign.DNIS__c);
        ApexPages.currentPage().getParameters().put('claimedUpLeadIsConsole', 'false');
        ApexPages.currentPage().getParameters().put('source', 'Invoca');
        ApexPages.currentPage().getParameters().put('InvocaID', String.valueOf(invocaRecord.INVOCA_FOR_SF__transaction_id__c));

        ApexPages.StandardController standardLeadController = new ApexPages.StandardController(testLead );
        LeadSearchExtension testController = new LeadSearchExtension(standardLeadController);

        Test.startTest();
            testController.claimUnprotectedLeadOwnership();
        Test.stopTest();

        List<Lead> assertLead = new List<Lead>([SELECT Id, Name, Phone, MobilePhone
                                                FROM Lead
                                                WHERE LastName = 'fakeLastName'
                                                LIMIT 1]);

        System.assertEquals(null, assertLead[0].MobilePhone, 'Phone Number should not be added to Lead');
    }

    @isTest static void testPopulateNewPhoneAllPhoneNumberOccupied(){

        Lead testLead = [   SELECT Id, Name, Phone
                            FROM Lead
                            WHERE LastName = 'test2'
                            LIMIT 1];
        testLead.MobilePhone = '123';
        update testLead;

        Campaign testCampaign = [   SELECT Id, Name, DNIS__c, BMID__c
                                    FROM Campaign
                                    WHERE Name = 'fakeCampaign'
                                    LIMIT 1];

        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = (INVOCA_FOR_SF__Invoca_Call_Log__c) new SObjectBuilder(INVOCA_FOR_SF__Invoca_Call_Log__c.SObjectType)
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__transaction_id__c , '123456')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c , testCampaign.BMID__C)
            .create()
            .getRecord();
        PageReference pageRef = Page.LeadSearchExtension;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('dnis', '1234');
        ApexPages.currentPage().getParameters().put('ani', '78901');
        ApexPages.currentPage().getParameters().put('claimedUpLeadId', testLead.Id);
        ApexPages.currentPage().getParameters().put('claimedUpLeadDnis', testCampaign.DNIS__c);
        ApexPages.currentPage().getParameters().put('claimedUpLeadIsConsole', 'false');
        ApexPages.currentPage().getParameters().put('source', 'Invoca');
        ApexPages.currentPage().getParameters().put('InvocaID', invocaRecord.INVOCA_FOR_SF__transaction_id__c);

        ApexPages.StandardController standardLeadController = new ApexPages.StandardController(testLead );
        LeadSearchExtension testController = new LeadSearchExtension(standardLeadController);

        Test.startTest();
            testController.claimUnprotectedLeadOwnership();
        Test.stopTest();

        List<Lead> assertLead = new List<Lead>([SELECT Id, Name, Phone, MobilePhone
                                                FROM Lead
                                                WHERE LastName = 'test2'
                                                LIMIT 1]);

        System.assertNotEquals('78901', assertLead[0].Phone, 'Phone Number should not be added to Lead');
        System.assertNotEquals('78901', assertLead[0].MobilePhone, 'Phone Number should not be added to Lead');
        List<String> listOfStatusLessThan2Contacted = LeadHelper.listOfStatusLessThan2Contacted;
    }

    @IsTest
    private static void testGetLeadNameById() {
        Response testResp = new Response();
        Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'test@email.com',
                    Lead.LastName => 'TestLastName',
                    Lead.Company => 'TestCompany',
                    Lead.Status => '1. New'
                }
            )
            .create()
            .getRecord();

        testResp.setData('Name', testLead.LastName);

        Test.startTest();
        Response result = LeadHelper.getLeadNameById(testLead.Id);
        Test.stopTest();

        System.assertEquals(Response.STATUS_SUCCESS, result.status, 'Response statuses are not equal');
        System.assertEquals(testResp.data, result.data, 'Actual response data are not equal with actual response data expected');
    }

    @IsTest
    private static void testIsAvaya() {
        Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany',
                    Lead.Lead_Brand_Name__c => RingCentralHelper.BRAND_AVAYA
                }
            )
            .build()
            .getRecord();

        Test.startTest();
        Boolean result = LeadHelper.isAvaya(testLead);
        Test.stopTest();

        System.assertEquals(result, true, 'Lead should created with Avaya brand');
    }

    @isTest
    private static void testLeadWebsiteValidation() {
        String validWebsite ='https://example.com/page';
        String invalidWebsite = 'example.com';
        Test.startTest();
        	Boolean resultValid = LeadHelper.isValidWebsite(validWebsite);
        	Boolean resultInvalid = LeadHelper.isValidWebsite(invalidWebsite);
        Test.stopTest();
        Assert.areEqual(true, resultValid, 'Website validation is correct');
        Assert.areEqual(false, resultInvalid, 'Website validation is correct');
    }
}