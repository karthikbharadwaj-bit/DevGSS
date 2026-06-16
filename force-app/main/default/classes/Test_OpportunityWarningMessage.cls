@IsTest
public with sharing class Test_OpportunityWarningMessage {
    @isTest
    static void testComponentNotShown() {
        OpportunityWarningMessageController.ResponseWrapper result;

        LeadConversionConfiguration__c setting = (LeadConversionConfiguration__c) new SobjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                LeadConversionConfiguration__c.Name => 'Test brand',
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => true
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Brand_Name__c => 'Test brand',
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create()
            .getRecord();

        Test.startTest();
            result = (OpportunityWarningMessageController.ResponseWrapper) JSON.deserialize(OpportunityWarningMessageController.getData(opp.Id), OpportunityWarningMessageController.ResponseWrapper.class);
        Test.stopTest();

        System.assert(String.isEmpty(result.message), 'OpportunityWarningMessage aura component should not be displayed');
     }

    @isTest
    static void testComponentShownForNotCountedForecasting() {
        OpportunityWarningMessageController.ResponseWrapper result;

        LeadConversionConfiguration__c setting = (LeadConversionConfiguration__c) new SobjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                LeadConversionConfiguration__c.Name => 'Test brand',
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => false
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Account.Name => 'Test account'
        })
        .create()
        .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Brand_Name__c => 'Test brand',
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_SOLUTION
            })
            .create()
            .getRecord();

        Test.startTest();
            result = (OpportunityWarningMessageController.ResponseWrapper) JSON.deserialize(OpportunityWarningMessageController.getData(opp.Id), OpportunityWarningMessageController.ResponseWrapper.class);
        Test.stopTest();

        System.assert(String.isNotEmpty(result.message), 'OpportunityWarningMessage aura component is displayed');
    }

    @isTest
    static void testComponentShownForVerizon() {
        OpportunityWarningMessageController.ResponseWrapper result;

        LeadConversionConfiguration__c setting = (LeadConversionConfiguration__c) new SobjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                LeadConversionConfiguration__c.Name => 'Test brand',
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => true
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Account.Name => 'Test account'
        })
        .create()
        .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Brand_Name__c => RingCentralHelper.BRAND_VERIZON,
                Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"47"}'
            })
            .create()
            .getRecord();

        Test.startTest();
            result = (OpportunityWarningMessageController.ResponseWrapper) JSON.deserialize(OpportunityWarningMessageController.getData(opp.Id), OpportunityWarningMessageController.ResponseWrapper.class);
        Test.stopTest();

        System.assert(String.isNotEmpty(result.message), 'OpportunityWarningMessage aura component is displayed');
        System.assert(result.message.contains(Label.VerizonOnlyForProServ), 'Wrong message');
        System.assert(result.message.contains(Label.VerizonPipelineNotAutoPopulated), 'Wrong message');
    }

    @isTest
    static void testComponentShownForRise() {
        OpportunityWarningMessageController.ResponseWrapper result;

        LeadConversionConfiguration__c setting = (LeadConversionConfiguration__c) new SobjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                LeadConversionConfiguration__c.Name => 'Test brand',
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => true
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RISE_AMERICA
            })
            .create()
            .getRecord();

        Test.startTest();
        result = (OpportunityWarningMessageController.ResponseWrapper) JSON.deserialize(OpportunityWarningMessageController.getData(opp.Id), OpportunityWarningMessageController.ResponseWrapper.class);
        Test.stopTest();

        System.assert(String.isNotEmpty(result.message), 'OpportunityWarningMessage aura component is displayed');
        System.assert(result.message.contains(Label.RiseOnlyForProServ), 'Should be Rise message');
    }
    
    @isTest
    static void testComponentShownForGSPParnterOnlyProServ() {
        OpportunityWarningMessageController.ResponseWrapper result;

        LeadConversionConfiguration__c setting = (LeadConversionConfiguration__c) new SobjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                LeadConversionConfiguration__c.Name => 'Test brand',
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => true
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
        .create()
        .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Brand_Name__c, 'Apple')
            .setField(Opportunity.BusinessIdentity__c, '{"currency":"USD","biId":"4"}')
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();
        
        GSP_Partner_Setup__c gspPartnerSetup = (GSP_Partner_Setup__c) new SObjectBuilder(GSP_Partner_Setup__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                GSP_Partner_Setup__c.Name => 'Apple',
                GSP_Partner_Setup__c.Validate_by_Brand__c => true,
                GSP_Partner_Setup__c.Has_NGBS_Packages__c => true,
                GSP_Partner_Setup__c.Disable_Commercial_Quoting__c => true,
                GSP_Partner_Setup__c.Validation_name__c => 'Apple'
            })
            .create()
            .getRecord();
    

        Test.startTest();
        result = (OpportunityWarningMessageController.ResponseWrapper) JSON.deserialize(OpportunityWarningMessageController.getData(opp.Id), OpportunityWarningMessageController.ResponseWrapper.class);
        Test.stopTest();

        System.assert(String.isNotEmpty(result.message), 'OpportunityWarningMessage aura component is displayed');
        System.assert(result.message.contains(Label.GSPPartnerOnlyForProServ), 'Should be Only ProServ message');
    }

    @isTest
    static void testComponentShownForGSPParnterOnlyCommertialQuoting() {
        OpportunityWarningMessageController.ResponseWrapper result;

        LeadConversionConfiguration__c setting = (LeadConversionConfiguration__c) new SobjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                LeadConversionConfiguration__c.Name => 'Test brand',
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => true
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
        .create()
        .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Brand_Name__c, 'Apple')
            .setField(Opportunity.BusinessIdentity__c, '{"currency":"USD","biId":"4"}')
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();
        
        GSP_Partner_Setup__c gspPartnerSetup = (GSP_Partner_Setup__c) new SObjectBuilder(GSP_Partner_Setup__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                GSP_Partner_Setup__c.Name => 'Apple',
                GSP_Partner_Setup__c.Validate_by_Brand__c => true,
                GSP_Partner_Setup__c.Disable_ProServ__c => true,
                GSP_Partner_Setup__c.Validation_name__c => 'Apple'
            })
            .create()
            .getRecord();
    

        Test.startTest();
        result = (OpportunityWarningMessageController.ResponseWrapper) JSON.deserialize(OpportunityWarningMessageController.getData(opp.Id), OpportunityWarningMessageController.ResponseWrapper.class);
        Test.stopTest();

        System.assert(String.isNotEmpty(result.message), 'OpportunityWarningMessage aura component is displayed');
        System.assert(result.message.contains(Label.GSPPartnerOnlyForCommercialQuoting), 'Should be Only Commertial Quoting message');
    }

    @isTest
    static void testComponentShownForGSPParnterQuotingNotSupported() {
        OpportunityWarningMessageController.ResponseWrapper result;

        LeadConversionConfiguration__c setting = (LeadConversionConfiguration__c) new SobjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                LeadConversionConfiguration__c.Name => 'Test brand',
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => true
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
        .create()
        .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Brand_Name__c, 'Apple')
            .setField(Opportunity.BusinessIdentity__c, '{"currency":"USD","biId":"4"}')
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();
        
        GSP_Partner_Setup__c gspPartnerSetup = (GSP_Partner_Setup__c) new SObjectBuilder(GSP_Partner_Setup__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                GSP_Partner_Setup__c.Name => 'Apple',
                GSP_Partner_Setup__c.Validate_by_Brand__c => true,
                GSP_Partner_Setup__c.Disable_ProServ__c => true,
                GSP_Partner_Setup__c.Disable_Commercial_Quoting__c => true,
                GSP_Partner_Setup__c.Disable_PDF__c => true,
                GSP_Partner_Setup__c.Disable_POC__c => true,
                GSP_Partner_Setup__c.Has_NGBS_Packages__c => true,
                GSP_Partner_Setup__c.Validation_name__c => 'Apple'
            })
            .create()
            .getRecord();
    

        Test.startTest();
        result = (OpportunityWarningMessageController.ResponseWrapper) JSON.deserialize(OpportunityWarningMessageController.getData(opp.Id), OpportunityWarningMessageController.ResponseWrapper.class);
        Test.stopTest();

        System.assert(String.isNotEmpty(result.message), 'OpportunityWarningMessage aura component is displayed');
        System.assert(result.message.contains(Label.QuotingNotSupported), 'Should be Quoting Not Supported message');
    }

    @isTest
    static void testStageWarningMessage() {
		OpportunityWarningMessageController.ResponseWrapper result;
        User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields( new Map<SObjectField, Object>{
                User.LastName => 'testtestuser',
                User.Username => 'testuser!user@gmail.com',
                User.Email => 'testuser@gmail.com',
                User.Alias => 'test',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.LocaleSidKey => 'en_US',
                User.EmailEncodingKey => 'UTF-8',
                User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name =: ProfileHelper.PROFILE_NAME_CHANNEL_SALES_MANAGER_LIGHTNING].Id,
                User.LanguageLocaleKey => 'en_US'
            })
            .create()
            .getRecord();
        
        Segment_Master__c segment = (Segment_Master__c) new SobjectBuilder(Segment_Master__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Segment_Master__c.Name => UserHelper.SEGMENT_MID_MARKET,
                Segment_Master__c.Max__c => 399,
                Segment_Master__c.Min__c => 100,
                Segment_Master__c.Country__c => 'United States',
                Segment_Master__c.Start_Date__c => Date.today()
            })
            .create()
            .getRecord();
        System.runAs(testUser) {
            Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Acc 1',
                Account.Segment_Name__c => segment.Id    
            })
            .create()
            .getRecord();
       
            Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Oppty 1',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_PROBLEM,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create()
            .getRecord();

            Test.startTest();
                result = (OpportunityWarningMessageController.ResponseWrapper) JSON.deserialize(
                    OpportunityWarningMessageController.getStageValidationMessage(opp.Id), 
                    OpportunityWarningMessageController.ResponseWrapper.class
                );
            Test.stopTest();
        
            Assert.areEqual(result.message, '', 'Error with the Stage Validation for deal size 0');
            Assert.areEqual(result.nextStage, 'Stage 0', 'Error in the assignment of the default Stage number'); 
        }        
    }
}