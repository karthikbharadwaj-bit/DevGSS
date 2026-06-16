global class JIRA_Issue_BatchUpdate_Scheduler implements Schedulable{
    global void execute(SchedulableContext SC){
        JIRA_Issue_BatchUpdate jibu = new JIRA_Issue_BatchUpdate();
        database.executebatch(jibu,10);
    }
}