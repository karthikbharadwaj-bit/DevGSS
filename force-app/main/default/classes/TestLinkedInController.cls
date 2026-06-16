@isTest
private class TestLinkedInController {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
        LinkedInController linkedInCon = new LinkedInController();
        linkedInCon.companyName = 'test';
        linkedInCon.searchCompany();
    }
}