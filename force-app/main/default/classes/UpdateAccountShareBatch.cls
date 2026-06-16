public class UpdateAccountShareBatch implements Database.Batchable<sObject>{
    
    public final String Query;
    
    public UpdateAccountShareBatch(Set<Id> setOfGroupIds){
        
        //Query = 'Select id from AccountShare where Rowcause = \'Manual\' and AccountId in (Select id from ' 
          //  + 'Account where Avaya_Partnership_Account__c = true and RC_Brand__c like \'%' + brandName + '%\'' 
            //+ ') and userorgroup.type = \'Queue\'';
        String tempQuery = 'Select id, AccountId from AccountShare where RowCause = \'Manual\' and '
            				+ 'AccountId in (Select Id from Account where Avaya_Partnership_Account__c = true '
            				+ 'and RC_Brand__c != null) and UserOrGroupId in (';
        for(Id eachId : setOfGroupIds){
            tempQuery = tempQuery + '\'' + eachId + '\',';
        }
        tempQuery = tempQuery.removeEnd(',');
        tempQuery = tempQuery + ')';
        Query = tempQuery;
        System.debug('Query '+Query); 
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(Query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> objLst){
        update objLst;
    }
    
    public void finish(Database.BatchableContext BC){
    }
}