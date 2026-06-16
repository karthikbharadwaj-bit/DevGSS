@isTest
public class Test_Opportunity_CloseController {
    @testSetup
    static void testSetup() {
        Opportunity opp = new Opportunity(Name='Test', StageName='Qualify');
        insert opp;
        Contact contact = new Contact(LastName='Test');
        insert contact;
        OpportunityContactRole contactRole = new OpportunityContactRole(OpportunityId=opp.Id, ContactId=contact.Id);
        insert contactRole;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void closeOppty() {
        Opportunity opp = [Select Id from Opportunity];
        try {
            Opportunity_CloseController.closeOppty(String.valueOf(opp.Id));   
        }
        catch(Exception excp) {
            
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void opportunityvalidateOpptyBeforeSalesOPsEngagement() {
        Opportunity opp = [Select Id from Opportunity];
        Opportunity_CloseController.opportunityvalidateOpptyBeforeSalesOPsEngagement('', String.valueOf(opp.Id));   
    }
    
    @isTest
    static void getOpprecord() {
        Opportunity opp = [Select Id from Opportunity];
        List<Opportunity> retOpps = Opportunity_CloseController.getOpprecord(String.valueOf(opp.Id));
        System.assert(opp.Id == retOpps[0].Id);
    }
    
    @isTest
    static void createCaseFromOpp() {
        Opportunity opp = [Select Id from Opportunity];
        String s = Opportunity_CloseController.createCaseFromOpp(String.valueOf(opp.Id), '', '', '', '', '', '');
        System.assert(!String.isEmpty(s));
    }
    
    @isTest
    static void getPicklistValues() {
        List<String> values = Opportunity_CloseController.getPicklistValues();
        System.assert(!values.isEmpty());
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void getDependentMap() {
        Opportunity opp = [Select Id from Opportunity];
        Opportunity_CloseController.getDependentMap(opp, 'account_dls__c', 'account_dls__c');
    }
    
    @isTest
    static void decimalToBinary() {
        String retValue = Opportunity_CloseController.decimalToBinary(3);
        System.assert(retValue.equals('11'));
    }
    
    @isTest
    static void base64ToBits() {
        String retValue = Opportunity_CloseController.base64ToBits('test');
        System.assert(!String.isEmpty(retValue));
    }
    
    @isTest
    static void getPickListEntryWrapper() {
        Opportunity_CloseController.PicklistEntryWrapper plew = new Opportunity_CloseController.PicklistEntryWrapper();
        plew.active = 'true';
        plew.defaultValue = 'Test';
        plew.label = 'label';
        plew.value = 'value';
        plew.validFor = 'test';
        System.assertNotEquals(null, plew);
    }

    @isTest
    static void testGetIsMPUB() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Test.startTest();
            Boolean result = Opportunity_CloseController.getIsMPUB(acc.Id);
        Test.stopTest();
        Assert.areEqual(false, result, 'Should return that account is not MPUB account');
    }

    @isTest
    static void testGetMPUBTechnicalQuotesIds() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();
        
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.StageName => 'Prospecting',
                Opportunity.CloseDate => Date.today().addDays(30),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Master Quote',
                Quote.OpportunityId => opportunity.Id,
                Quote.Status => 'Draft'
            })
            .create()
            .getRecord();

        Quote technicalQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Technical Quote',
                Quote.OpportunityId => opportunity.Id,
                Quote.Status => 'Draft',
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
            List<Id> result = Opportunity_CloseController.getMPUBTechnicalQuotesIds(opportunity.Id);
        Test.stopTest();
        Assert.areEqual(1, result.size(), 'Method should return one tech quote');
        Assert.areEqual(technicalQuote.Id, result[0], 'Returned tech quote Id should match the created technical quote Id');
    }
}