@isTest
public class TestLeadClonePageController {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_getLeadClonePage() {
        Lead ld = new Lead(FirstName='TestLead',LastName='TestLead',Company='TestLead',Email = 'TestLead@test.com');
        insert ld;
        ApexPages.StandardController sc = new ApexPages.standardController(ld);
        Test.startTest();
        LeadClonePageController lc = new LeadClonePageController(sc);
        LeadClonePageController.cloneLead();
        Test.stopTest();
    }

}