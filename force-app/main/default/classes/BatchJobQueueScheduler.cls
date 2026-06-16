public with sharing class BatchJobQueueScheduler implements Schedulable {
    private static String NO_SPACE_IN_QUEUE = 'NoSpaceInQueue';
    private static String FAILED_TO_RUN = 'FailedToRun';
    private static String COMPLETED = 'Completed';
    public final static String BATCH_JOB_QUEUE_SCHEDULER = 'Batch Job Queue Scheduler';
    List<BatchJobQueue__c> objectsToProcess = new List<BatchJobQueue__c>();
    List<BatchJobQueue__c> objectsToUpdate = new List<BatchJobQueue__c>();

    /**
    * @description Checks that batch job is allowed to be launched.
    * If yes, executes the batch job and change the status of the BatchJobQueue__c object to 'Completed'.
    * If no, just updates the status of the BatchJobQueue__c object to 'NoSpaceInQueue'
    * Also deletes all scheduled 'Batch Job Queue Scheduler' jobs and schedule a new one
    * (It was created so because we need to run this scheduler every minute)
    * */
    public void execute(SchedulableContext sc) {
        BatchJobQueueSelector bjqSelector = new BatchJobQueueSelector();
        objectsToProcess = bjqSelector
            .selectBatchJobQueueObjects()
            .setCondition('Status__c = \'New\' OR Status__c = \'NoSpaceInQueue\'')
            .addOrdering(BatchJobQueue__c.CreatedDate, QueryFactory.SortOrder.ASCENDING)
            .setLimit(10)
            .executeQuery();

        if (!objectsToProcess.isEmpty()) {
            Map<String,BatchJobsConfiguration__c> batchConfig = BatchJobsConfiguration__c.getAll();
            for (BatchJobQueue__c bjq : objectsToProcess) {
                if (AsyncApexJobSvc.isAllowedToBeLaunched(bjq.BatchJobName__c)) {
                    BatchJobsConfiguration__c bjc = batchConfig.get(bjq.BatchJobName__c);
                    if (bjc == null || !bjc.isBatchJobQueueDisabled__c) {
                        Integer chunkSize = bjc == null ? 200 : (Integer) bjc.ChunkSizeLimit__c;

                        try {
                            Database.executeBatch(
                                (Database.Batchable<SObject>) createInstance(bjq.BatchJobName__c), chunkSize);
                            bjq.Status__c = COMPLETED;
                        } catch (Exception ex) {
                            bjq.Status__c = FAILED_TO_RUN;
                            sendEmailWithFailedRecords(bjq, ex.getMessage());
                        }
                    }
                } else {
                    bjq.Status__c = NO_SPACE_IN_QUEUE;
                }
                objectsToUpdate.add(bjq);
            }

            if (!objectsToUpdate.isEmpty()) {
                update objectsToUpdate;
            }
        }
        deleteBatchJobQueueJobs();
        scheduleBatchJobQueueScheduler();
    }

    /**
    * @param className name of the batch job class name to create instance from
    * @description creates an instance of the batch job class
    * @return Object of the class
    */
    public static Object createInstance(String className) {

        if (String.isBlank(className)) {
            throw new BatchJobQueueException('Class name value is required');
        }

        Type classType = Type.forName(className);
        Object instance;

        if (classType == null) {
            throw new BatchJobQueueException('' +
                'Couldn\'t successfully instantiate an object for class ' + className + '. ' +
                'Please check if Class name is correct, is compilable and current user has access.'
            );
        }

        instance = classType.newInstance();

        return instance;
    }

    /**
    * @param batchJobQueue failed BatchJobQueue__c object
    * @description send Email to the  error email distribution list of the BatchJobQueue__c object
    * */
    public static void sendEmailWithFailedRecords(BatchJobQueue__c batchJobQueue, String exceptionMessage) {

        if (String.isBlank(exceptionMessage)) {
            throw new BatchJobQueueException('Exception message value is required');
        }

        if (batchJobQueue == null) {
            throw new BatchJobQueueException('Batch Job Queue object is required');
        }

        BatchJobsConfiguration__c bjc = BatchJobsConfiguration__c.getValues(batchJobQueue.BatchJobName__c);

        if (bjc == null) {
            bjc = BatchJobsConfiguration__c.getValues(BATCH_JOB_QUEUE_SCHEDULER);
        }

        List<String> emailsToSend = bjc.ErrorEmailDistributionList__c.split(',');

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.saveAsActivity = false;
        mail.setToAddresses(emailsToSend);
        mail.setSubject(batchJobQueue.BatchJobName__c + ' job has failed');
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody('' +
            'Admin:\n' +
            'Batch job record in BatchJobQueue__c failed:\n\n' +
            'BatchJobQueue object id(s): ' + batchJobQueue.Id + '\n' +
            'Exception message: ' + exceptionMessage + '\n\n' +
            'Please review and proceed to rerun and/or fix.\n' +
            'Thanks'
        );

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {mail});
    }

    /**
    * @description deletes all scheduled 'Batch Job Queue Scheduler'
    * */
    public static void deleteBatchJobQueueJobs() {
        List<CronTrigger> listCronTrigger = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :BATCH_JOB_QUEUE_SCHEDULER + '%'
        ];

        if (listCronTrigger.isEmpty()) {
            return;
        }

        try {
            for (Integer i = 0; i < listCronTrigger.size(); i++) {
                if (AsyncApexJobSvc.isJobScheduled(listCronTrigger.get(i).CronJobDetail.Name)) {
                    System.abortJob(listCronTrigger.get(i).Id);
                }
            }
        } catch(Exception ex) {
            throw new BatchJobQueueException(ex.getMessage());
        }
    }

    /**
    * @description schedules 'Batch Job Queue Scheduler' in a minute
    * */
    public static Id scheduleBatchJobQueueScheduler() {
        BatchJobQueueScheduler scheduler = new BatchJobQueueScheduler();
        Integer minuteToRun = System.now().minute() + 1;

        //Because minute value must be between 0 and 59
        if (minuteToRun == 0 || minuteToRun >= 59) {
            minuteToRun = 1;
        }

        String batchJobName = BATCH_JOB_QUEUE_SCHEDULER + (Test.isRunningTest() ? '_test_' : '');
        if (!AsyncApexJobSvc.isJobScheduled(batchJobName)) {
            return System.schedule(batchJobName, '0 ' + minuteToRun + ' * * * ?', scheduler);
        } else {
            return null;
        }
    }
}