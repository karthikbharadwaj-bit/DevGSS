global with sharing class BatchJob_AgreementDeactivationScheduler implements Schedulable {

    // Example of scheduling:
    // String everyDayAt1Am = '0 0 1 * * ?';
    // String jobID = System.schedule('Deactivating Agreements of Canceled Accounts... ', '0 0 1 * * ?', new BatchJob_AgreementDeactivationScheduler());

    global void execute(SchedulableContext sc) {
        BatchJob_AgreementDeactivation b = new BatchJob_AgreementDeactivation();
        Database.executeBatch(b);
    }
}