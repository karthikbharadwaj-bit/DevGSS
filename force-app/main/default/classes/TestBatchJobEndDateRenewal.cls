/**
 * Created by asuszb on 08.09.2016.
 */

@IsTest
public with sharing class TestBatchJobEndDateRenewal {

    private static Quote testQuote;
    private static Quote testQuote2;
    private static Quote testQuote3;
    private static Quote testQuote4;
    private static Quote newQuote;
    private static Account testAccount;
    private static Opportunity testOpportunity;
    private static PriceBook2 testPriceBook;
    private static User admin = createUser('admin'); // salesrepUser
    public static String TermMonths = '2';
    public static Date EndDate = System.today().addDays(-5);


    private static User createUser(String name){
        User user = new User(
                Username = name+datetime.now().format('yyyyMMddHHmmss')+'user@gmail.com',
                LastName = 'Test'+name,
                Email = name+'_user@test.com',
                Alias = 't'+name,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                CommunityNickname = name+'commnick',
                LanguageLocaleKey = 'en_US',
                ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id
        );
        insert user;
        return user;
    }

    @isTest static void testEndDateRenewal(){
        Test.startTest();
            system.runAs(admin) {
                testPriceBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5);
                insert testPriceBook;

                testAccount = new Account(Name = 'Opty test account',
                        Partner_ID__c = 'testID',
                        Permitted_Brands__c = 'RingCentral');
                insert testAccount;

                testOpportunity = new Opportunity(Name = 'Test Opportunity 2016', Type = 'New Business', StageName = 'Planning', CloseDate = system.today(), AccountId = testAccount.Id);
                insert testOpportunity;

                testQuote = new Quote(Name = 'qoutetest', OpportunityId = testOpportunity.id, Account__c = testAccount.Id,
                        Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10,
                        isPrimary__c = true, Start_Date__c = System.today().addDays(-20), End_Date__c = EndDate, Initial_Term_months__c = '12',
                        QuoteType__c = 'Agreement', Status = 'Active', Term_months__c = TermMonths, Auto_Renewal__c = True);

                System.debug('##! Start_Date__c = ' + String.valueOf(testQuote.Start_Date__c));
                System.debug('##! Term_months__c = ' + String.valueOf(testQuote.Term_months__c));
                System.debug('##! End_Date__c = ' + String.valueOf(testQuote.End_Date__c));

                insert testQuote;
            }

            BatchJobEndDateRenewal batchJob = new BatchJobEndDateRenewal();
            ID batchprocessid = Database.executeBatch(batchJob);

        Test.stopTest();

        Quote tq = [SELECT Initial_Term_months__c, Start_Date__c, End_Date__c FROM Quote WHERE Id=:testQuote.Id];
        System.debug('##! Start_Date__c = ' + String.valueOf(tq.Start_Date__c));
        System.debug('##! End_Date__c = ' + String.valueOf(tq.End_Date__c));
        Date correctDate = EndDate.addMonths(Integer.valueOf(TermMonths));
        System.assertEquals(tq.End_Date__c, correctDate);
    }

    @isTest static void testSheduledBatchJob(){

        Test.startTest();

            BatchJobEndDateRenewalSheduler shed = new BatchJobEndDateRenewalSheduler();
            String jobId = System.schedule('testBasicScheduledApex', '0 0 1 * * ?', shed);
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals('0 0 1 * * ?', ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
    }


    @isTest 
    static void testBatchJobEndDateRenewal_excludeAgreementsInStatus_Disabled() {
        Test.startTest();
            System.runAs(admin) {
                testPriceBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5);
                insert testPriceBook;

                testAccount = new Account(Name = 'Opty test account',
                        Partner_ID__c = 'testID',
                        Permitted_Brands__c = 'RingCentral',
                        RC_Account_Status__c = 'Disabled');
                insert testAccount;

                testOpportunity = new Opportunity(Name = 'Test Opportunity 2016', Type = 'New Business', StageName = 'Planning', CloseDate = System.today(), AccountId = testAccount.Id);
                insert testOpportunity;

                testQuote = new Quote(Name = 'qoutetest', OpportunityId = testOpportunity.id,
                        Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10,
                        isPrimary__c = true, Start_Date__c = System.today().addDays(-20), End_Date__c = EndDate, Initial_Term_months__c = '12',
                        QuoteType__c = 'Agreement', Status = 'Active', Term_months__c = TermMonths, Auto_Renewal__c = True);

                System.debug('##! Start_Date__c = ' + String.valueOf(testQuote.Start_Date__c));
                System.debug('##! Term_months__c = ' + String.valueOf(testQuote.Term_months__c));
                System.debug('##! End_Date__c = ' + String.valueOf(testQuote.End_Date__c));

                insert testQuote;
            }

            BatchJobEndDateRenewal batchJob = new BatchJobEndDateRenewal();
            ID batchprocessid = Database.executeBatch(batchJob);

        Test.stopTest();

        Quote tq = [SELECT Initial_Term_months__c, Start_Date__c, End_Date__c, Account.RC_Account_Status__c FROM Quote WHERE Id=:testQuote.Id];
        System.debug('##! Start_Date__c = ' + String.valueOf(tq.Start_Date__c));
        System.debug('##! End_Date__c = ' + String.valueOf(tq.End_Date__c));
        
        System.debug('##! Account.RC_Account_Status__c = ' + String.valueOf(tq.Account.RC_Account_Status__c));
        
        // this quote must be excluded from process because it has RC_Account_Status__c = 'Disabled'
        Date correctDate = EndDate;
        System.assertEquals(tq.End_Date__c, correctDate);
    }

    @isTest 
    static void testBatchJobEndDateRenewal_excludeAgreementsInStatus_Cancelled() {
        Test.startTest();
            System.runAs(admin) {
                testPriceBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5);
                insert testPriceBook;

                testAccount = new Account(Name = 'Opty test account',
                        Partner_ID__c = 'testID',
                        Permitted_Brands__c = 'RingCentral',
                        RC_Account_Status__c = 'Canceled');
                insert testAccount;

                testOpportunity = new Opportunity(Name = 'Test Opportunity 2016', Type = 'New Business', StageName = 'Planning', CloseDate = System.today(), AccountId = testAccount.Id);
                insert testOpportunity;

                testQuote = new Quote(Name = 'qoutetest', OpportunityId = testOpportunity.id,
                        Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10,
                        isPrimary__c = true, Start_Date__c = System.today().addDays(-20), End_Date__c = EndDate, Initial_Term_months__c = '12',
                        QuoteType__c = 'Agreement', Status = 'Active', Term_months__c = TermMonths, Auto_Renewal__c = True);

                System.debug('##! Start_Date__c = ' + String.valueOf(testQuote.Start_Date__c));
                System.debug('##! Term_months__c = ' + String.valueOf(testQuote.Term_months__c));
                System.debug('##! End_Date__c = ' + String.valueOf(testQuote.End_Date__c));

                insert testQuote;
            }

            BatchJobEndDateRenewal batchJob = new BatchJobEndDateRenewal();
            ID batchprocessid = Database.executeBatch(batchJob);

        Test.stopTest();

        Quote tq = [SELECT Initial_Term_months__c, Start_Date__c, End_Date__c, Account.RC_Account_Status__c FROM Quote WHERE Id=:testQuote.Id];
        System.debug('##! Start_Date__c = ' + String.valueOf(tq.Start_Date__c));
        System.debug('##! End_Date__c = ' + String.valueOf(tq.End_Date__c));
        
        System.debug('##! Account.RC_Account_Status__c = ' + String.valueOf(tq.Account.RC_Account_Status__c));
        
        // this quote must be excluded from process because it has RC_Account_Status__c = 'Cancelled'
        Date correctDate = EndDate;
        System.assertEquals(tq.End_Date__c, correctDate);
    }

    @isTest static void testBatchJobInactiveStatusRenewal(){
        Test.startTest();

        system.runAs(admin) {
            testPriceBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5);
            insert testPriceBook;

            testAccount = new Account(Name = 'Opty test account',
                    Partner_ID__c = 'testID',
                    Permitted_Brands__c = 'RingCentral');
            insert testAccount;

            testOpportunity = new Opportunity(Name = 'Test Opportunity 2016', Type = 'New Business', StageName = 'Planning', CloseDate = system.today(), AccountId = testAccount.Id);
            insert testOpportunity;

            testQuote = new Quote(Name = 'qoutetest', OpportunityId = testOpportunity.id,
                    Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10,
                    isPrimary__c = true, Start_Date__c = System.today().addDays(-20), End_Date__c = EndDate,
                    QuoteType__c = 'Agreement', Status = 'Active', Auto_Renewal__c = False);

            insert testQuote;
        }

        BatchJobEndDateRenewal batchJob = new BatchJobEndDateRenewal();
        ID batchprocessid = Database.executeBatch(batchJob);

        Test.stopTest();

        Quote tq = [SELECT Status FROM Quote WHERE Id=:testQuote.Id];
        System.assertEquals(tq.Status, 'Inactive');
    }
}