/* 
*Class Name 		: Schedule_Batch_createRelationshipSurvey
*Test class Name    : Test_Schedule_BatchRelationshipSurvey
*Business Purpose 	: To Schedule the Batch_createRelationshipSurvey on Specified dates.
					  This class is a controller class for LWC - RelationshipSurveyScheduler

*Developer Name 	: Manovasanth Balasankar

Modification History:
*--------------------------------------------------------------------------------------------------------------------
Date              User Story#                   Developer Name                    Changes done
*-------------------------------------------------------------------------------------------------------------------
24/02/2022                                     Manovasanth Balasankar            New Schedulable Class
15/03/2022                                     Manovasanth Balasankar            changes done to schedule the batch based on date input
14/04/2022                                     Anjana Ravikumar                  Remove completed jobs with DELETED State before scheduling
05/05/2022                                     Manovasanth Balasankar            Execute the medallia package job 
*/
global class Schedule_Batch_createRelationshipSurvey implements  Schedulable {
	public final static String SCHEDULE_BATCH_JOB_RELATIONSHIP_SURVEY = 'BatchJobRelationshipSurvey';
    public final static String SCHEDULE_BATCH_JOB_RELATIONSHIP_SURVEY_MEDALLIA = 'BatchJobRelationshipSurveyMedallia';

    
    global void execute(SchedulableContext ctx) {
        Batch_createRelationshipSurvey batch =new Batch_createRelationshipSurvey();
        database.executebatch(batch, 50);
    }
    
    /**
    * @description Schedule the Batch_createRelationshipSurvey based on the given dates 
    * @Parameter List of String - Dates 
    * @Usage It is called in RelationshipSurveyScheduler LWC Component 
    * */
    @AuraEnabled()
    public static Map<String, Id> scheduleBatchcreateRelationshipSurvey(List<String> dates) {
        //create objects for two batch classes
        Schedule_Batch_createRelationshipSurvey rsBatchSchedular = new Schedule_Batch_createRelationshipSurvey();
        medallia_xm.MedDailySyncJob medalliaBatchSchedular = new medallia_xm.MedDailySyncJob();
        
        Map<String,Decimal> regionTimings = new  Map<String,Decimal>();        
        Map<String, Id>  mapOfDateAndJobId = new Map<String, Id> ();
        Integer BatchCount = [SELECT ID, ApexClass.Name, JobType FROM AsyncApexJob WHERE JobType in ( 'ScheduledApex')  and ApexClass.name = 'Schedule_Batch_createRelationshipSurvey'].size();
        for(Medallia_Region__mdt mr :Medallia_Region__mdt.getAll().values() ){
            regionTimings.put(mr.DeveloperName, mr.GMT__c);
        }
        for(String d : dates){
            Date myDate = Date.valueOf(d);
            BatchCount++;
            DateTime dt = DateTime.newInstanceGmt(myDate.addDays(-1), Time.newInstance((Integer)regionTimings.get('APAC'), 0, 0, 0));
            system.debug('currentTime_PST'+system.now()+'dt'+dt);
            if(system.now() > dt)
            {
                    throw new BatchJobQueueException('Please select a future date.You are not allowed to schedule after '+dt.format('MM/dd/yyyy HH:mm:ss','America/Los_Angeles')+ ' PST for the day.');
            }   
            /*creating cron exp for three batches :
             * Schedule RS BATCH -  10 PST (-1)
             * Schedule Medallia BATCH - 19  PST(-1) , 3 PST 
			*/
            String RS_CRON_EXP = '0 '+String.valueof(dt.minute())+' '+String.valueof(dt.hour())+' '+String.valueof( dt.day())+' '+String.valueof(dt.month())+' ? '+String.valueof(dt.year());                    
            dt = DateTime.newInstanceGmt(myDate, Time.newInstance((Integer)regionTimings.get('North_America'), 0, 0, 0));
            String MEDALLIA_CRON_EXP_NA = '0 '+String.valueof(dt.minute())+' '+String.valueof(dt.hour())+' '+String.valueof( dt.day())+' '+String.valueof(dt.month())+' ? '+String.valueof(dt.year());                    
            Date prevDate = myDate.addDays(-1);
			dt = DateTime.newInstanceGmt(myDate, Time.newInstance((Integer)regionTimings.get('EMEA'), 0, 0, 0));
            String MEDALLIA_CRON_EXP_EMEA  = '0 '+String.valueof(dt.minute())+' '+String.valueof(dt.hour())+' '+String.valueof( dt.day())+' '+String.valueof(dt.month())+' ? '+String.valueof(dt.year());     
            System.debug('MEDALLIA_CRON_EXP_NA ' + MEDALLIA_CRON_EXP_NA);
            System.debug('RS_CRON_EXP ' + RS_CRON_EXP);
            System.debug('MEDALLIA_CRON_EXP_EMEA ' + MEDALLIA_CRON_EXP_EMEA);
            Schedule_Batch_createRelationshipSurvey.abortPreviousBatchJobDeletedJobs(); // Abort jobs with State - 'DELETED'
            // Creating Name for 3 Batch
            String rsBatchJobName = SCHEDULE_BATCH_JOB_RELATIONSHIP_SURVEY + ' ' + BatchCount + (Test.isRunningTest() ? '_test_' : '');
            String medalliaBatchJobName1 = SCHEDULE_BATCH_JOB_RELATIONSHIP_SURVEY_MEDALLIA + 'EMEA ' + BatchCount + (Test.isRunningTest() ? '_test_' : '');
            String medalliaBatchJobName2 = SCHEDULE_BATCH_JOB_RELATIONSHIP_SURVEY_MEDALLIA + 'NorthAmerica ' + BatchCount + (Test.isRunningTest() ? '_test_' : '');            
            try {
            	mapOfDateAndJobId.put(d,System.schedule(medalliaBatchJobName1, MEDALLIA_CRON_EXP_EMEA, medalliaBatchSchedular));// RS Batch
                mapOfDateAndJobId.put(d,System.schedule(rsBatchJobName, RS_CRON_EXP, rsBatchSchedular));// Medallia Package Batch
                mapOfDateAndJobId.put(d,System.schedule(medalliaBatchJobName2, MEDALLIA_CRON_EXP_NA, medalliaBatchSchedular));// Medallia Package Batch
            	// mapOfDateAndJobId.put(d,System.schedule(rsBatchJobName, RS_CRON_EXP, rsBatchSchedular));// RS Batch
                // mapOfDateAndJobId.put(d,System.schedule(medalliaBatchJobName1, MEDALLIA_CRON_EXP_APAC, medalliaBatchSchedular));// Medallia Package Batch
                // mapOfDateAndJobId.put(d,System.schedule(medalliaBatchJobName2, MEDALLIA_CRON_EXP_NA, medalliaBatchSchedular));// Medallia Package Batch
                
            }catch(Exception ex) {
                throw new BatchJobQueueException(ex.getMessage());
            }            
        }
        return mapOfDateAndJobId;
        
    }
    
    /* @description Deletes all the Previously Scheduled Jobs with State - 'DELETED'
     * @Parameter none  
    */
    public static void abortPreviousBatchJobDeletedJobs() {
        List<CronTrigger> listCronTrigger = new List<CronTrigger>();
        listCronTrigger = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :SCHEDULE_BATCH_JOB_RELATIONSHIP_SURVEY + '%' AND State IN ('DELETED') LIMIT 50
        ];
        
        if (listCronTrigger!=null && listCronTrigger.isEmpty()) {
            return;
        }
        
        try {
            for (Integer i = 0; i < listCronTrigger.size(); i++) {
                    system.debug('JOB ABORTED ' + listCronTrigger.get(i).Id);
                    System.abortJob(listCronTrigger.get(i).Id);
            }
        } catch(Exception ex) {
            throw new BatchJobQueueException(ex.getMessage());
        }
    }
    
    /**
    * @description Delete the specific job which is queued in the cron trigger based on Crontrigger Id
    * @Paramter List of ID - crontrigger IDs 
    * @Usage It is called in RelationshipSurveyScheduler LWC Component 
    * */
    @AuraEnabled()
    public static void deleteJobByCronId(List<Id> cronIds){
        try {
            for(Id cronId : cronIds ){
                System.abortJob(cronId);
            }
        }
        catch(Exception ex) {
            throw new BatchJobQueueException(ex.getMessage());
        }
        
    }
    
    /**
    * @description Retrieves all the scheduled jobs 
    * @Parameter none
    * @Usage It is called in RelationshipSurveyScheduler LWC Component 
    * */
    @AuraEnabled()
    public static List<CronTrigger> getRelationshipJobs(){
        List<CronTrigger> returnResult = new List<CronTrigger>();
        for(CronTrigger ct: [
            SELECT Id, CronJobDetail.Name, State,  NextFireTime, TimesTriggered FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :SCHEDULE_BATCH_JOB_RELATIONSHIP_SURVEY + '%'  AND State IN ('WAITING', 'ACQUIRED', 'EXECUTING', 'PAUSED', 'BLOCKED', 'PAUSED_BLOCKED')  order by  NextFireTime desc
        ]){
                returnResult.add(ct);
        }
        return returnResult;
           
    }
}