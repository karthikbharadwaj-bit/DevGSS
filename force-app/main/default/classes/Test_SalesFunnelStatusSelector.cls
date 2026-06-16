@isTest
private class Test_SalesFunnelStatusSelector {
    @isTest
    static void testSelectSalesFunnelStatusByOppId() {
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

        SalesFunnelStatus__c testSalesFunnelStatus = (SalesFunnelStatus__c) new SObjectBuilder(SalesFunnelStatus__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    SalesFunnelStatus__c.Opportunity__c => testOpp.Id,
                    SalesFunnelStatus__c.Sales_Agent__c => testUser.Id
                }
            )
            .create()
            .getRecord();
        List<SalesFunnelStatus__c> salesFunnelStatuses = new List<SalesFunnelStatus__c>();
        Test.startTest();
            salesFunnelStatuses = new SalesFunnelStatusSelector()
                .selectSalesFunnelStatusByOppIdAndSalesAgentId(testOpp.Id, testUser.Id)
                .executeQuery();
        Test.stopTest();
        System.assertEquals(salesFunnelStatuses.isEmpty(), false, 'Selector should return SalesFunnelStatus__c record');
    }

    @isTest
    static void testSelectSalesFunnelStatuses() {
        QueryFactory qf = new SalesFunnelStatusSelector()
            .selectSalesFunnelStatuses()
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    static void testSelectSalesFunnelStatusesForGWValidator() {
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
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER
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
            List<SalesFunnelStatus__c> salesFunnelStatuses = new SalesFunnelStatusSelector()
                .selectSalesFunnelStatusesForGWValidator(testOpp.Id, testUser.Id, qt.Id)
                .executeQuery();
        Test.stopTest();

        Assert.areEqual(salesFunnelStatuses.isEmpty(), false, 'Selector should return SalesFunnelStatus__c record');
    }

    @isTest
    static void testSalesFunnelStatusesForGWValidatorByFilter() {
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
        List<String> serviceNameFilter = new List<String>{QuoteHelper.NGBS_OFFICE_PRODUCT};
        
        Test.startTest();
            List<SalesFunnelStatus__c> salesFunnelStatuses = new SalesFunnelStatusSelector()
                .selectSalesFunnelStatusesForGWValidatorByFilter(testOpp.Id, testUser.Id, serviceNameFilter)
                .executeQuery();
        Test.stopTest();

        Assert.areEqual(salesFunnelStatuses.isEmpty(), false, 'Selector should return SalesFunnelStatus__c record');
    }
}