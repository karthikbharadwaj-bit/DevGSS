@isTest
private class Test_GWRestAPI {

    @isTest
    static void myUnitTest() {    	
		Boolean isSuccess = true;    	
        SalesFunnelStatus__c funelObj = new SalesFunnelStatus__c(Sales_Agent__c=userInfo.getUserId(),IsRequestOpen__c=true);
        insert funelObj;
        
        RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/GWSignupValidator';
		req.httpMethod = 'GET';
		
		req.addParameter('oppId', '');
		req.addParameter('userId',userInfo.getUserId());
		RestContext.request = req;
		RestContext.response = res;
		
        try{
			GWSignupValidator.doGet();            
        }catch(Exception ex){
            isSuccess = false;
        }
		System.assertEquals(isSuccess, true, 'doGet function should be completed successfully');
        
		req.addParameter('oppId', '');
		req.addParameter('userId','');  
		RestContext.request = req;
		RestContext.response = res;
		
        try{
			GWSignupValidator.doGet();            
        }catch(Exception ex){
            isSuccess = false;
        }
		System.assertEquals(isSuccess, true, 'doGet function should be completed successfully');
		
    }

    @isTest
    static void testGetSalesFunnelStatus() {
        User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                Quote.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT
            })
            .create()
            .getRecord();

        SalesFunnelStatus__c testSalesFunnelStatus = (SalesFunnelStatus__c) new SObjectBuilder(SalesFunnelStatus__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    SalesFunnelStatus__c.Opportunity__c => testOpp.Id,
                    SalesFunnelStatus__c.Sales_Agent__c => testUser.Id,
                    SalesFunnelStatus__c.Quote__c => qt.Id
                }
            )
            .create()
            .getRecord();
        List<String> serviceNameFilter = new List<String>{QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT};
        
        Test.startTest();
            SalesFunnelStatus__c salesFunnelStatus = GWSignupValidator.getSalesFunnelStatus(testOpp.Id, testUser.Id, qt.Id);
        Test.stopTest();

        Assert.areEqual(true, salesFunnelStatus != null, 'SalesFunnelStatus should not be null');
        Assert.areEqual(testSalesFunnelStatus.Id, salesFunnelStatus.Id, 'Method should return testSalesFunnelStatus record');
    }

    @isTest
    static void testGetSalesFunnelStatusQuoteNull() {
        User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();

        SalesFunnelStatus__c testSalesFunnelStatus = (SalesFunnelStatus__c) new SObjectBuilder(SalesFunnelStatus__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    SalesFunnelStatus__c.Opportunity__c => testOpp.Id,
                    SalesFunnelStatus__c.Sales_Agent__c => testUser.Id,
                    SalesFunnelStatus__c.Quote__c => qt.Id
                }
            )
            .create()
            .getRecord();
        
        Test.startTest();
            SalesFunnelStatus__c salesFunnelStatus = GWSignupValidator.getSalesFunnelStatus(testOpp.Id, testUser.Id, null);
        Test.stopTest();

        Assert.areEqual(true, salesFunnelStatus != null, 'SalesFunnelStatus should not be null');
        Assert.areEqual(testSalesFunnelStatus.Id, salesFunnelStatus.Id, 'Method should return testSalesFunnelStatus record');
    }

    @isTest
    static void testGetGWSignUpWrapper() {
        User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();

        SalesFunnelStatus__c testSalesFunnelStatus = (SalesFunnelStatus__c) new SObjectBuilder(SalesFunnelStatus__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    SalesFunnelStatus__c.Opportunity__c => testOpp.Id,
                    SalesFunnelStatus__c.Sales_Agent__c => testUser.Id,
                    SalesFunnelStatus__c.Quote__c => qt.Id,
                    SalesFunnelStatus__c.IsRequestOpen__c => true
                }
            )
            .create()
            .getRecord();
        
        Test.startTest();
            GWSignUpWrapper gwSignUpWrapper = GWSignupValidator.getGWSignUpWrapper(testSalesFunnelStatus);
        Test.stopTest();

        Assert.areEqual(true, gwSignUpWrapper != null, 'gwSignUpWrapper should not be null');
        Assert.areEqual(true, gwSignUpWrapper.requestStatus, 'gwSignUpWrapper.requestStatus should be true');
        Assert.areEqual('Valid Request', gwSignUpWrapper.description, 'gwSignUpWrapper.description should be: Valid Request');
        Assert.areEqual(true, gwSignUpWrapper.isRequestValid, 'gwSignUpWrapper.isRequestValid should be true');
        Assert.areEqual(false, gwSignUpWrapper.errorExists, 'gwSignUpWrapper.errorExists should be false');
    }

    @isTest
    static void testGetGWSignUpWrapperSalesFunnelStatusNull() {
        User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();
        
        Test.startTest();
            GWSignUpWrapper gwSignUpWrapper = GWSignupValidator.getGWSignUpWrapper(null);
        Test.stopTest();

        Assert.areEqual(true, gwSignUpWrapper != null, 'gwSignUpWrapper should not be null');
        Assert.areEqual(false, gwSignUpWrapper.isRequestValid, 'gwSignUpWrapper.isRequestValid should be false');
        Assert.areEqual(false, gwSignUpWrapper.requestStatus, 'gwSignUpWrapper.requestStatus should be false');
        Assert.areEqual('Invalid Parameters', gwSignUpWrapper.description, 'gwSignUpWrapper.description should be: Invalid Parameters');
        Assert.areEqual(false, gwSignUpWrapper.errorExists, 'gwSignUpWrapper.errorExists should be false');
    }
}