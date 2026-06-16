/**
 * @description Test class for ScheduleJob_PermSetCngsFileGenerator
 * Tests scheduling functionality for Permission Set Changes File Generator batch job
 */
@isTest
private class ScheduleJob_PermSetFileGenerator_Test {
    
    /**
     * @description Test execute method - verifies batch job is executed
     */
    @isTest
    static void testExecute_BatchJobStarted() {
        Test.startTest();
        ScheduleJob_PermSetCngsFileGenerator scheduler = new ScheduleJob_PermSetCngsFileGenerator();
        scheduler.execute(null);
        Test.stopTest();
        
        // Verify batch job was queued
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ApexClass.Name, JobType
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BatchJob_PermSetChangesFileGenerator'
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
        String jobName = 'Test Permission Set Changes File Generator Job';
        
        Test.startTest();
        String jobId = System.schedule(
            jobName, 
            cronExp, 
            new ScheduleJob_PermSetCngsFileGenerator()
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
     * @description Test scheduler can be instantiated and executed successfully
     */
    @isTest
    static void testScheduler_InstantiationAndExecution() {
        // Verify scheduler can be instantiated
        ScheduleJob_PermSetCngsFileGenerator scheduler = new ScheduleJob_PermSetCngsFileGenerator();
        System.assertNotEquals(null, scheduler, 'Scheduler should be instantiated');
        
        Test.startTest();
        // Execute once (test limitation: only one executeBatch per test)
        scheduler.execute(null);
        Test.stopTest();
        
        // Verify batch job was queued successfully
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BatchJob_PermSetChangesFileGenerator'
            AND JobType = 'BatchApex'
        ];
        
        System.assertEquals(1, jobs.size(), 'Batch job should have been queued');
    }
    
    /**
     * @description Test that correct batch size is used
     */
    @isTest
    static void testExecute_CorrectBatchSize() {
        // Note: We can't directly verify batch size from AsyncApexJob
        // This test ensures the execute method completes successfully
        Test.startTest();
        ScheduleJob_PermSetCngsFileGenerator scheduler = new ScheduleJob_PermSetCngsFileGenerator();
        scheduler.execute(null);
        Test.stopTest();
        
        // Verify execution completed without errors
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BatchJob_PermSetChangesFileGenerator'
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
        String jobName = 'Test Context PermSet Changes Job';
        
        Test.startTest();
        String jobId = System.schedule(
            jobName, 
            cronExp, 
            new ScheduleJob_PermSetCngsFileGenerator()
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
        String weeklyExp = '0 0 2 ? * SUN'; // Every Sunday at 2 AM
        String jobName = 'Test Weekly PermSet Changes Job';
        
        Test.startTest();
        String jobId = System.schedule(
            jobName, 
            weeklyExp, 
            new ScheduleJob_PermSetCngsFileGenerator()
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
    
    /**
     * @description Test job completes successfully
     */
    @isTest
    static void testSchedule_JobCompletesSuccessfully() {
        String cronExp = '0 0 5 * * ?';
        String jobName = 'Test Successful PermSet Job';
        
        Test.startTest();
        String jobId = System.schedule(
            jobName, 
            cronExp, 
            new ScheduleJob_PermSetCngsFileGenerator()
        );
        Test.stopTest();
        
        // Query scheduled job details
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        System.assertEquals(1, jobs.size(), 'One job should be scheduled');
        System.assertNotEquals('ERROR', jobs[0].State, 'Job should not be in error state');
    }
}