global class MedalliaAnniversarySignupBatch_Scheduler implements Schedulable {
    global void execute (SchedulableContext sc){
        ID batchprocessid = Database.executeBatch (new MedalliaAnniversarySignupBatch(), 200);
    }

}