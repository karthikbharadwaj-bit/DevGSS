/**
* Service class with methods to check if there are any running or scheduled batch jobs and the amount of them
* */
public with sharing class AsyncApexJobSvc {
    private static final Set<String> ASYNC_JOB_STATUS_PROGRESS = new Set<String>{
        'HOLDING', 'QUEUED', 'PREPARING', 'PROCESSING'
    };
    private static final Set<String> SCHEDULED_JOB_STATUS_PROGRESS = new Set<String>{
        'WAITING', 'ACQUIRED', 'EXECUTING', 'PAUSED', 'BLOCKED', 'PAUSED_BLOCKED'
    };

    /**
    * @param batchJobName name of the batch job to be checked
    * @description checks if there is a space in queue to run this batch job
    * and that this batch job is not running and is not scheduled
    * @return true if this batch job is allowed to be launched, false if not
    */
    public static Boolean isAllowedToBeLaunched(String batchJobName) {
        return String.isNotBlank(batchJobName) && hasSpaceInQueue()
            && !isJobRunning(batchJobName) && !isJobScheduled(batchJobName);
    }

    /**
    * @param batchJobName name of the job to be checked
    * @description checks if job is running
    * @return true if job is running, false if not
    */
    public static Boolean isJobRunning(String batchJobName) {

        if (String.isBlank(batchJobName)) {
            return false;
        }

        Boolean isJobRunning = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE ApexClass.Name = :batchJobName AND Status IN :ASYNC_JOB_STATUS_PROGRESS
            LIMIT 1] > 0;

        return isJobRunning;
    }

    /**
    * @param batchJobName name of the job to be checked
    * @description checks if job is scheduled
    * @return true if job is scheduled, false if not
    */
    public static Boolean isJobScheduled(String batchJobName) {

        if (String.isBlank(batchJobName)) {
            return false;
        }

        batchJobName = batchJobName + '%';
        Boolean isJobScheduled = [
            SELECT CronJobDetail.Name, State FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :batchJobName AND State IN :SCHEDULED_JOB_STATUS_PROGRESS
        ].size() > 0;

        return isJobScheduled;
    }

    /**
    * @description since Salesforce only allows you to have 5 apex jobs run at one time, each time we want to run
    * a batchjob, we need to make sure there is 1 slot available for LeanData. In this way, if there are more than 3
    * (that is, if 4 slots or more are occupied) we should NOT run a new batch job and wait until there is a slot
    * available that wouldn’t be occupied by LeanData 1 min into the future)
    * @return true if there is an available slot, false if not
    */
    public static Boolean hasSpaceInQueue() {
        Boolean hasSpaceInQueue = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex' AND Status IN :ASYNC_JOB_STATUS_PROGRESS] < 4;
        return hasSpaceInQueue && !Test.isRunningTest();
    }
}