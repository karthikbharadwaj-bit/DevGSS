/**
 * @description Test class for ScheduleJob_FLSandObjCngsFileGenerator
 * Tests scheduling functionality for FLS and Object Changes File Generator batch job
 */
@isTest
private class ScheduleJob_FLSandObjFileGenerator_Test {
    
    /**
     * @description Test execute method - verifies batch job is executed
     */
    @isTest
    static void testExecute_BatchJobStarted() {
        Test.startTest();
        ScheduleJob_FLSandObjCngsFileGenerator scheduler = new ScheduleJob_FLSandObjCngsFileGenerator();
        scheduler.execute(null);
        Test.stopTest();
        
        // Verify batch job was queued
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ApexClass.Name, JobType
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BatchJob_FLSandObjChangesFileGenerator'
            AND JobType = 'BatchApex'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        System.assertEquals(1, jobs.size(), 'Batch job should have been queued');
        System.assertNotEquals(null, jobs[0].Id, 'Batch job ID should not be null');
    }
    
    /**
     * @description Test scheduling the job using System.schedule
     */
    @isTest
    static void testSchedule_JobScheduledSuccessfully() {
        String cronExp = '0 0 1 * * ?'; // Daily at 1 AM
        String jobName = 'Test FLS and Object Changes File Generator Job';
        
        Test.startTest();
        String jobId = System.schedule(
            jobName, 
            cronExp, 
            new ScheduleJob_FLSandObjCngsFileGenerator()
        );
        Test.stopTest();
        
        // Verify scheduled job was created
        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
        
        // Query for the scheduled job
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression, State, NextFireTime
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        System.assertEquals(1, scheduledJobs.size(), 'Scheduled job should exist');
        System.assertEquals(cronExp, scheduledJobs[0].CronExpression, 'Cron expression should match');
    }
    
    /**
     * @description Test multiple executions don't cause issues
     */
    @isTest
    static void testExecute_MultipleExecutions() {
        ScheduleJob_FLSandObjCngsFileGenerator scheduler = new ScheduleJob_FLSandObjCngsFileGenerator();
        
        Test.startTest();
        // Execute multiple times
        scheduler.execute(null);
        scheduler.execute(null);
        Test.stopTest();
        
        // Verify both batch jobs were queued
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BatchJob_FLSandObjChangesFileGenerator'
            AND JobType = 'BatchApex'
        ];
        
        System.assertEquals(2, jobs.size(), 'Two batch jobs should have been queued');
    }
    
    /**
     * @description Test that correct batch size is used
     */
    @isTest
    static void testExecute_CorrectBatchSize() {
        // Note: We can't directly verify batch size from AsyncApexJob
        // This test ensures the execute method completes successfully
        Test.startTest();
        ScheduleJob_FLSandObjCngsFileGenerator scheduler = new ScheduleJob_FLSandObjCngsFileGenerator();
        scheduler.execute(null);
        Test.stopTest();
        
        // Verify execution completed without errors
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BatchJob_FLSandObjChangesFileGenerator'
            AND JobType = 'BatchApex'
            LIMIT 1
        ];
        
        System.assertEquals(1, jobs.size(), 'Batch job should be queued');
        System.assertEquals(0, jobs[0].NumberOfErrors, 'Batch job should have no errors');
    }
    
    /**
     * @description Test with valid SchedulableContext
     */
    @isTest
    static void testExecute_WithSchedulableContext() {
        String cronExp = '0 0 4 * * ?';
        String jobName = 'Test Context FLS Changes Job';
        
        Test.startTest();
        String jobId = System.schedule(
            jobName, 
            cronExp, 
            new ScheduleJob_FLSandObjCngsFileGenerator()
        );
        Test.stopTest();
        
        // Verify the job was scheduled (context will be provided by Salesforce)
        System.assertNotEquals(null, jobId, 'Job should be scheduled with context');
        
        List<CronTrigger> ct = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, ct.size(), 'Scheduled job should exist');
    }
    
    /**
     * @description Test scheduling at different times
     */
    @isTest
    static void testSchedule_DifferentCronExpressions() {
        // Test weekly schedule
        String weeklyExp = '0 0 1 ? * MON'; // Every Monday at 1 AM
        String jobName = 'Test Weekly FLS Changes Job';
        
        Test.startTest();
        String jobId = System.schedule(
            jobName, 
            weeklyExp, 
            new ScheduleJob_FLSandObjCngsFileGenerator()
        );
        Test.stopTest();
        
        // Verify scheduled job was created with correct cron expression
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        System.assertEquals(1, scheduledJobs.size(), 'Scheduled job should exist');
        System.assertEquals(weeklyExp, scheduledJobs[0].CronExpression, 'Cron expression should match weekly schedule');
    }
}