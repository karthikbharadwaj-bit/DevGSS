@isTest
public class Test_OpportunityCloseController {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void opportunityClose(){
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testCont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();  
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => testCont.Id
                }
            )
            .create()
            .getRecord();
        Id recTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('ProServ Quote').getRecordTypeId();
        system.debug('recTypeId' +recTypeId);
        Quote testQuote = new Quote(
            Name = 'quotetest',
            OpportunityId = testOpp.id,
            ProServ_Status__c ='Created',
            Total_Number_of_Digital_Lines__c = 10, Account__c = testOpp.AccountId,RecordTypeId=recTypeId);
        insert testQuote;
        Map<String, String> opptyMap = new Map<String, String>();
        opptyMap.put('opportunityId',testOpp.Id);
        String str = JSON.serialize(opptyMap);
        system.debug('str>>>'+str);
        
        Test.startTest();
        	Opportunity_CloseController.closeOppty(str);
        Test.stopTest();
        //system.assertNotEquals(testQuote.ProServ_Status__c, 'Cancelled');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void opportunityCloseATT(){
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testATTAcc',
    		  Account.RC_Brand__c => 'AT&T Office@Hand'
                }
            )
            .create()
            .getRecord();
        Contact testCont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();  
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => testCont.Id
                }
            )
            .create()
            .getRecord();
        Id recTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('ProServ Quote').getRecordTypeId();
        system.debug('recTypeId' +recTypeId);
        Quote testQuote = new Quote(
            Name = 'quotetest',
            OpportunityId = testOpp.id,
            ProServ_Status__c ='Created',
            Total_Number_of_Digital_Lines__c = 10, Account__c = testOpp.AccountId,RecordTypeId=recTypeId);
        insert testQuote;
        Map<String, String> opptyMap = new Map<String, String>();
        opptyMap.put('opportunityId',testOpp.Id);
        String str = JSON.serialize(opptyMap);
        system.debug('str>>>'+str);
        
        Test.startTest();
        	Opportunity_CloseController.closeOppty(str);
        Test.stopTest();
    }
    
}