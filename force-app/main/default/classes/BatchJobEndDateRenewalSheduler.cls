global with sharing class BatchJobEndDateRenewalSheduler implements Schedulable{

    // example of sheduling:
    //String everyDayAt1Am = '0 0 1 * * ?';
    //String jobID = System.schedule('End Date renewal for Active  ', '0 0 1 * * ?', new BatchJobEndDateRenewalSheduler());

    global void execute(SchedulableContext sc) {
        BatchJobEndDateRenewal b = new BatchJobEndDateRenewal();
        Database.executebatch(b, 50);
    }
}