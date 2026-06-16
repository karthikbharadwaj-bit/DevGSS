@isTest 
private class Test_CreateCoopsJiraController {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testPostCallout() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Case cs = new Case(
            Subject = 'Test Case',
            AccountId = testAccount.Id
        );
        insert cs;

        Test.setMock(HttpCalloutMock.class, new MockTest_CreateCoopsJiraController());  

        Test.startTest();
        String strResp = CreateCoopsJiraController.createJira(cs.Id);
        Test.stopTest();
    }
}