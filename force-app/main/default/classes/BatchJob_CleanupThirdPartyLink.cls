global class BatchJob_CleanupThirdPartyLink implements Database.Batchable<sObject>,Schedulable {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, SSOProviderId , Provider, UserID, RemoteIdentifier, User.isActive from ThirdPartyAccountLink');
    }
    
    global void execute(Database.BatchableContext BC, List<ThirdPartyAccountLink> scope) {
        for (ThirdPartyAccountLink link : scope) {
            if (link.User.isActive == false) {
                Auth.AuthToken.revokeAccess(link.SSOProviderId, link.Provider, link.UserID, link.RemoteIdentifier);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
    }
    
    public void execute(SchedulableContext context) {
        BatchJob_CleanupThirdPartyLink batchJob = new BatchJob_CleanupThirdPartyLink();
        Database.executeBatch(batchJob);
    }
}