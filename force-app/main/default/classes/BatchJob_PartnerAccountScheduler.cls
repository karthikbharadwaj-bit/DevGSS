/*
    This class is used as a temporary solution to schedule BatchJob_PartnerAccount with different chunk size 
    To schedule batch execute following code in developer console:

    String startTime = '0 0 1 * * ?';
    Integer size = 15;
    String jobID = System.schedule('BatchJob_PartnerAccount', startTime, new BatchJob_PartnerAccountScheduler(size));
*/

global class BatchJob_PartnerAccountScheduler implements Schedulable {
    Integer size;

    global BatchJob_PartnerAccountScheduler(Integer size) {
        this.size = size;
    }

    global void execute(SchedulableContext sc) {
        BatchJob_PartnerAccount job = new BatchJob_PartnerAccount();
        Database.executeBatch(job, size);
    }
}