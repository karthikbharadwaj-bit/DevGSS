@isTest
public class Test_CaseIBSCloseScheduler {

    @isTest
    public static void testSheduleBatch() {
        Test.startTest();
            String jobId = System.schedule('Test_ScheduleCaseCloseIBS', '0 0 12 ? * MON,THU *', new CaseIBSCloseScheduler());
        Test.stopTest();
        System.assert(jobId != null, 'Job record is not be empty');
    }
}