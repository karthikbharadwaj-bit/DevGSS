@IsTest
public with sharing class Test_BatchJob_AgreementDeactivation {

    private static Quote testQuote;
    private static Account testAccount;
    private static Opportunity testOpportunity;
    private static PriceBook2 testPriceBook;
    private static User admin = createUser('admin');

    private static User createUser(String name) {
        User user = new User(
                Username = name + datetime.now().format('yyyyMMddHHmmss') + 'user@gmail.com',
                LastName = 'Test' + name,
                Email = name + '_user@test.com',
                Alias = 't' + name,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                CommunityNickname = name + 'commnick',
                LanguageLocaleKey = 'en_US',
                ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id
        );
        insert user;
        return user;
    }

    @IsTest
    static void testBatchJobInactiveStatusRenewal() {
        Test.startTest();

        System.runAs(admin) {
            testPriceBook = new Pricebook2(
                    Name = 'Test Price Book',
                    Description = 'Test Price Book Products',
                    IsActive = true,
                    Line_Range_Min__c = 5
            );
            insert testPriceBook;

            testAccount = new Account(
                    Name = 'Test Account',
                    Partner_ID__c = 'testID',
                    Permitted_Brands__c = 'RingCentral',
                    RC_Account_Status__c = 'Canceled'
            );
            insert testAccount;

            testOpportunity = new Opportunity(
                    Name = 'Test Opportunity',
                    Type = 'New Business',
                    StageName = 'Planning',
                    CloseDate = System.today(),
                    AccountId = testAccount.Id
            );
            insert testOpportunity;

            testQuote = new Quote(
                    Name = 'Test Quote',
                    OpportunityId = testOpportunity.Id,
                    Pricebook2Id = testPriceBook.Id,
                    Total_Number_of_Digital_Lines__c = 10,
                    isPrimary__c = true,
                    Start_Date__c = System.today().addDays(-20),
                    End_Date__c = System.today(),
                    QuoteType__c = 'Agreement',
                    Status = 'Active',
                    Auto_Renewal__c = false
            );
            insert testQuote;
        }

        BatchJob_AgreementDeactivation batchJob = new BatchJob_AgreementDeactivation();
        Database.executeBatch(batchJob);

        Test.stopTest();

        Quote tq = [SELECT Status FROM Quote WHERE Id = :testQuote.Id];
        System.assertEquals(tq.Status, 'Inactive');
    }
}