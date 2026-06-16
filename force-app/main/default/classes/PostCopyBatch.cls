public class PostCopyBatch implements Database.Batchable<PostCopyTasks__c>, Database.Stateful {
    
    private SandboxContext context;
    public PostCopyBatch (SandboxContext context) {
        this.context = context;
    }
    public Iterable<PostCopyTasks__c> start(Database.BatchableContext context) {
        return PostCopyUtil.getListOfPostrefreshTasks(true);
    }

    public void execute(Database.BatchableContext BC, List<PostCopyTasks__c> tasks) {

        for (PostCopyTasks__c currentTask : tasks) {
            PostCopyWorker currentWorker = PostCopyUtil.createWorkerObjectFromString(currentTask.DeveloperName__c, context);
            if (currentWorker != null) {
                currentWorker.process();
            }
        }
    }

    public void finish(Database.BatchableContext BC) { }
}