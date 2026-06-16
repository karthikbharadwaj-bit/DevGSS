@isTest
public class Test_Opportunity_StageDependencyCtr {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void opportunitystagedep(){

        Account testAcc = TestDataFactory.createAccount();
        Contact testCont = TestDataFactory.createContact(testAcc);
        Opportunity testOpp = TestDataFactory.createOppty(testAcc, testCont);
        Opportunity_StageDependancyController.getOppDetails(testOpp.id);
        Id recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Sales Opportunity').getRecordTypeId();
        Opportunity_StageDependancyController.getOptions(recTypeId,false);
        Opportunity_StageDependancyController.getDependentPicklistValuesWithOptions('opportunity','Sub_Stage__c');
        Opportunity_StageDependancyController.updateOpp(testOpp.id,
        '7. Closed Won','Closed','','','','','','','','');
    }
}