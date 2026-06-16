@isTest
private class Test_SalesAgreementsRelatedList
{
    private static Account testAccount;
    private static Opportunity testOpportunity;
    private static Quote testQuote;

    private static void CreateTestData(){
        
        // create test account
        testAccount = new Account(Name='Opty test account',
                                  Partner_ID__c='testID',
                                  Permitted_Brands__c='RingCentral',
                                  RC_User_ID__c = '1234');
        insert testAccount;

        // create test quote
        testOpportunity = new Opportunity (Name = 'test Oppty',
                                           StageName = '1. Qualify',
                                           AccountId = testAccount.Id);
        insert testOpportunity;

        // create test quote
        testQuote = new Quote (Name='test Quote', OpportunityId=testOpportunity.Id);
        insert testQuote;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void itShould()
    {
        // Given
        CreateTestData();

        // When
        Test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpportunity);
        SalesAgreementsRelatedListController ctr = new SalesAgreementsRelatedListController(sc);

        PageReference pageRef = Page.SalesAgreementsRelatedList;
        pageRef.getParameters().put('id', String.valueOf(testOpportunity.Id));
        Test.setCurrentPage(pageRef);

        Test.stopTest();

        // Then
        // TODO

    }
}