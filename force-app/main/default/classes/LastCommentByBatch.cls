public class LastCommentByBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Integer recordsProcessed = 0;
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'select id, (select CreatedById from Deal_Support_Comments__r order by CreatedDate desc limit 1) from Deal_Support__c where Partner_Account__r.Permitted_Brands__c includes (\'Avaya Cloud Office\')'
        );
    }
    
    public void execute(Database.BatchableContext bc, List<Deal_Support__c> records){
        List<Deal_Support__c> dealSupportListUpdate = new List<Deal_Support__c>();
        for (Deal_Support__c dealsupport : records){
            if (!dealsupport.Deal_Support_Comments__r.isEmpty()){
                dealsupport.Last_Comment_By__c = dealsupport.Deal_Support_Comments__r[0].CreatedById;
                dealSupportListUpdate.add(dealsupport);
                recordsProcessed = recordsProcessed + 1;
            }
        }
        update dealSupportListUpdate;
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug(recordsProcessed + ' records processed. Shazam!');
    }
}