/**
 * Created by asuszb on 08.08.2016.
 */

@isTest
private class QuoteTriggerHelperPrimaryQuoteTest {

    private static Quote testQuote;
    private static Quote testQuote2;
    private static Quote testQuote3;
    private static Quote testQuote4;
    private static Quote newQuote;
    private static Account testAccount;
    private static Opportunity testOpportunity;
    private static PriceBook2 testPriceBook;
    private static User salesrepUser = createUser('sr'); // salesrepUser

    private static User createUser(String name){
        User user = new User(
                Username = name+'!user@gmail.com',
                LastName = 'Test'+name,
                Email = name+'_user@gmail.com',
                Alias = 'test'+name,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                LanguageLocaleKey = 'en_US'
        );
        insert user;
        return user;
    }

    @isTest static void primaryQuoteTest(){

        system.runAs(salesrepUser){
            Triggers.switchOff();

            testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5);
            insert testPriceBook;

            testAccount = new Account(Name='Opty test account',
                    Partner_ID__c='testID',
                    Permitted_Brands__c='RingCentral');
            insert testAccount;

            testOpportunity = new Opportunity(Name = 'Test Opportunity 2016', Type = 'Syndicated - New', StageName = 'Planning', CloseDate = system.today(), AccountId = testAccount.Id);
            insert testOpportunity;

            Triggers.switchOn();
            Test.startTest();
            testQuote = new Quote (Name = 'qoutetest' , OpportunityId = testOpportunity.id ,
                    Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10,
                    isPrimary__c=true);
            insert testQuote;
            newQuote = new Quote (Name = 'qoutetest' , OpportunityId = testOpportunity.id ,
                    Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
            insert newQuote;
            newQuote.isPrimary__c = true;
            update newQuote;
        }
        Test.stopTest();
        Quote ntq = [SELECT isPrimary__c FROM Quote WHERE Id=:newQuote.Id];
        Quote tq = [SELECT isPrimary__c FROM Quote WHERE Id=:testQuote.Id];
        System.assertEquals(tq.isPrimary__c, false);
        System.assertEquals(ntq.isPrimary__c, true);
    }

    @isTest static void primaryQuoteAutoSetUpFirstAddedQuote() {
        Test.startTest();
        system.runAs(salesrepUser) {
            testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5);
            insert testPriceBook;

            testAccount = new Account(Name='Opty test account',
                    Partner_ID__c='testID',
                    Permitted_Brands__c='RingCentral');
            insert testAccount;

            testOpportunity = new Opportunity(Name = 'Test Opportunity 201611', Type = 'Syndicated - New', StageName = 'Planning', CloseDate = system.today(), AccountId = testAccount.Id);
            insert testOpportunity;

            testQuote = new Quote (Name = 'qoutetest' , OpportunityId = testOpportunity.id ,
                    Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
            insert testQuote;

            testQuote2 = new Quote (Name = 'qoutetest2' , OpportunityId = testOpportunity.id ,
                    Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
            insert testQuote2;
        }
        Test.stopTest();
        Quote tq = [SELECT isPrimary__c FROM Quote WHERE Id=:testQuote.Id];
        Quote stq = [SELECT isPrimary__c FROM Quote WHERE Id=:testQuote2.Id];
        //System.debug('#!! TestQuote.isPrimary = ' + tq.isPrimary__c);
        System.assertEquals(tq.isPrimary__c, true);
        System.assertEquals(stq.isPrimary__c, false);
    }

    @isTest static void primaryQuoteSetLastModifiedPrimaryAfterDeletePrimaryQuote() {
        system.runAs(salesrepUser) {
            Triggers.switchOff();
            testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5);
            insert testPriceBook;

            testAccount = new Account(Name='Opty test account',
                    Partner_ID__c='testID',
                    Permitted_Brands__c='RingCentral');
            insert testAccount;

            testOpportunity = new Opportunity(Name = 'Test Opportunity 201611', Type = 'Syndicated - New', StageName = 'Planning', CloseDate = system.today(), AccountId = testAccount.Id);
            insert testOpportunity;
            Triggers.switchOn();

            testQuote = new Quote (Name = 'qoutetest' , OpportunityId = testOpportunity.id ,
                    Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
            insert testQuote;

            testQuote2 = new Quote (Name = 'qoutetest2' , OpportunityId = testOpportunity.id ,
                    Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
            insert testQuote2;

            testQuote3 = new Quote (Name = 'qoutetest3' , OpportunityId = testOpportunity.id ,
                    Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
            insert testQuote3;

            testQuote4 = new Quote (Name = 'qoutetest4' , OpportunityId = testOpportunity.id ,
                    Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
            insert testQuote4;
            Test.startTest();
            testQuote2.Name = 'NewName';
            update testQuote2;
            delete testQuote;
            Test.stopTest();
        }
        Quote pq = [SELECT isPrimary__c FROM Quote WHERE Id=:testQuote2.Id];
        Quote anyPq = [SELECT  isPrimary__c FROM Quote WHERE isPrimary__c=True];
        System.assertEquals(anyPq.isPrimary__c, true);
        if (anyPq.Id == pq.Id) {
            System.debug('#!! QuteTriggerHelper.SetLastModifiedPrimaryOnDeletingPrimaryQuote working');
            System.assertEquals(pq.isPrimary__c, true);
        }

    }

    @isTest static void primaryQuoteUncheckPrimary() {
        system.runAs(salesrepUser) {
            testPriceBook = new Pricebook2(Name = 'Test Price Book332', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5);
            insert testPriceBook;

            testAccount = new Account(Name='Opty test account123',
                    Partner_ID__c='testID',
                    Permitted_Brands__c='RingCentral');
            insert testAccount;

            testOpportunity = new Opportunity(Name = 'Test Opportunity 201611', Type = 'Syndicated - New', StageName = 'Planning', CloseDate = system.today(), AccountId = testAccount.Id);
            insert testOpportunity;

            testQuote4 = new Quote (Name = 'qoutetest111' , OpportunityId = testOpportunity.id ,
                    Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
            insert testQuote4;

            testQuote = new Quote (Name = 'qoutetest2222' , OpportunityId = testOpportunity.id ,
                    Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
            insert testQuote;
        }
        Test.startTest();
        testQuote4.isPrimary__c = false;
        Database.SaveResult result = Database.update(testQuote4, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assertEquals('You should always have a Primary Quote. If you want to change it just make another Quote a Primary one', result.getErrors()[0].getMessage());
        Quote checkQuote = [SELECT isPrimary__c FROM Quote WHERE Id=:testQuote4.Id];
        System.assertEquals(checkQuote.isPrimary__c, true);
        //try {
        //    update testQuote;
        //} catch (DmlException e) {
        //    System.assert(e.getMessage().contains('You should always have a Primary Quote. If you want to change it just make another Quote a Primary one'),
        //        e.getMessage());
        //}
    }

}