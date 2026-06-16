global without sharing class BatchJobAccountCompanyMatchingScheduler implements Schedulable{

    //Example of scheduling:
    //String everyDayAt12Am = '0 0 12 1/1 * ? *';
    //BatchJobAccountCompanyMatchingScheduler batchToRun = new BatchJobAccountCompanyMatchingScheduler();
    //String jobID = System.schedule('Account Company Matching Batch', everyDayAt12Am, batchToRun);
    //Example to abort
    //System.abortJob(jobID);
    //SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger ORDER BY CreatedDate DESC LIMIT 1

    global void execute(SchedulableContext sc) {
        BatchJobAccountCompanyMatching batchToSchedule = new BatchJobAccountCompanyMatching();
        Database.executeBatch(batchToSchedule);
    }
}