public with sharing class CaseIBSCloseScheduler  Implements Schedulable {
    public void execute(SchedulableContext sc) {
        BatchJob_CloseIBSCases closeIBSCases = new BatchJob_CloseIBSCases();
        Database.executeBatch(closeIBSCases, 5); 
    }
}