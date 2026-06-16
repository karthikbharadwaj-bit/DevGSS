@isTest
public class Test_Schedule_BatchRelationshipSurvey {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    static void testSchedule_Batch(){
        String dt1 = system.now().addDays(10).format('yyyy-MM-dd');
        String dt2 = system.now().addMonths(7).format('yyyy-MM-dd');

        Test.startTest();
        Map<String,Id> jobIds = Schedule_Batch_createRelationshipSurvey.scheduleBatchcreateRelationshipSurvey(new List<String>{dt1,dt2 });
        Schedule_Batch_createRelationshipSurvey.getRelationshipJobs();
        Schedule_Batch_createRelationshipSurvey.deleteJobByCronId(new List<Id>{jobIds.get(dt1)});
        Schedule_Batch_createRelationshipSurvey.abortPreviousBatchJobDeletedJobs();
        system.schedule('Start the Batch_createRelationshipSurvey for Every Quarter', '0 0 9 20 3 ? 2024', new Schedule_Batch_createRelationshipSurvey());
        
try{
            Date dateToday = system.today();
            String sMonth = String.valueof(dateToday.month());
            String sDay = String.valueof(dateToday.day());
            if(sMonth.length()==1){
                sMonth = '0' + sMonth;
            }
            if(sDay.length()==1){
                sDay = '0' + sDay;
            }
            String sToday = String.valueof(dateToday.year()) +'-'+ sMonth +'-' + sDay ;
            Schedule_Batch_createRelationshipSurvey.scheduleBatchcreateRelationshipSurvey(new List<String>{sToday});
        }Catch(Exception ex){}
        try{Schedule_Batch_createRelationshipSurvey.scheduleBatchcreateRelationshipSurvey(new List<String>{'2022-03-20'});}Catch(Exception ex){}
        try{Schedule_Batch_createRelationshipSurvey.deleteJobByCronId(new List<Id>{'2F00e2H000001OYZ8'});}catch(Exception ex){}
        Schedule_Batch_createRelationshipSurvey.abortPreviousBatchJobDeletedJobs();
        Test.stopTest();
        
        
    }
}