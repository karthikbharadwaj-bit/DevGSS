public without sharing class BatchJob_DeleteMainData implements Database.Batchable<SObject>, Database.Stateful {

    private List<GDPRHelper> gdprRequestsQueue;
    private GDPRHelper currentRequest;

    public BatchJob_DeleteMainData () {
        this(false);
    }

    public BatchJob_DeleteMainData (Boolean testRun) {
        this(GDPRHelper.getRequestsQueue(testRun));
    }

    public BatchJob_DeleteMainData (List<GDPRHelper> queue) {
        this.gdprRequestsQueue = queue;
        init();
    }

    private void init () {
        if (!gdprRequestsQueue.isEmpty()) {
            currentRequest = gdprRequestsQueue[0];
            gdprRequestsQueue.remove(0);
        }
    }

    public Integer getScope() {
        return currentRequest != null ? currentRequest.scopeLimit : 200;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if(currentRequest != null) {
            if(currentRequest.shouldLogSuccess()) {
                currentRequest.deleteSimilarCase();
            }
            return currentRequest.getQueryLocator();
        } else {
            return null;
        }
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        this.currentRequest.processRequest(scope);
        this.currentRequest.logAsCsv(false);
    }

    public void finish(Database.BatchableContext bc) {
        this.currentRequest.logAsCsv(true);
        if(!gdprRequestsQueue.isEmpty()) {
            BatchJob_DeleteMainData nextStep = new BatchJob_DeleteMainData(gdprRequestsQueue);
            Database.executeBatch(nextStep, nextStep.getScope());
        }
    }
}