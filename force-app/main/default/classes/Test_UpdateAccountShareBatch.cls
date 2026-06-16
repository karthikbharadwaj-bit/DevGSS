@isTest
public class Test_UpdateAccountShareBatch { 
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')   
    @isTest
    static void testMethod1(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            UpdateAcctShareBatchScheduler sch = new UpdateAcctShareBatchScheduler();
            String jobID1 = system.schedule('Test Update share', '0 0 * * * ?', sch);
        }
        Test.stopTest();     
    }    

}