@isTest
private class Test_EmailHelperIgnite {

    @isTest
    static void testProServIgniteInitiate() {
        Email_Configuration__c settings = new Email_Configuration__c(
            CC_Emails_Ignite_Quote_Creation__c = 'test_partners.sales@ringcentral.com'
        );
        insert settings;

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();
        Opportunity testOppNB = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.PartnerProgram__c => 'Ignite'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.PartnerProgram__c => 'Ignite'
            })
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate()
            })
            .quantity(1)
            .create()
            .getRecords();

        Test.startTest();
            EmailHelperIgnite.proServIgnite(testQuotes[0].Id, 'testReason', 'engageProServIgnite');
            Integer numOfEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(1, numOfEmailInvocations, 'Email should be sent');
    }

    @isTest
    static void testProServIgniteCancel() {
        Email_Configuration__c settings = new Email_Configuration__c(
            CC_Emails_Ignite_Quote_Creation__c = 'test_partners.sales@ringcentral.com'
        );
        insert settings;

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();
        Opportunity testOppNB = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.PartnerProgram__c => 'Ignite'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.PartnerProgram__c => 'Ignite'
            })
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate()
            })
            .quantity(1)
            .create()
            .getRecords();

        Test.startTest();
            EmailHelperIgnite.proServIgnite(testQuotes[0].Id, 'testReason', 'cancelProServIgnite');
            Integer numOfEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(1, numOfEmailInvocations, 'Email should be sent');
    }
}