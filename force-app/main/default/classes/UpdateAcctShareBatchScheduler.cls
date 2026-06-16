global class UpdateAcctShareBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        List<Id> allTopMasterAcctIds = CommunityInfo.getAllCommunityTopMastersIds();
        Set<Id> setOfTopMasterIds = new Set<Id>();
        
        System.debug('allTopMasterAcctIds size' + allTopMasterAcctIds.size());
        for(Id topMasterId : allTopMasterAcctIds){
            setOfTopMasterIds.add(topMasterId);
        }
        
        Map<Id,Account> accountMap = new Map<Id,Account>([Select id from Account where Avaya_Partnership_Account__c = true 
                                                          AND partner_Role__c = 'Master Agent' and RC_Brand__c != null AND Id not in :setOfTopMasterIds]);
        
        System.debug('accountMap size '+ accountMap.size());
        List<User> userLst = [SELECT Id, UserRole.DeveloperName, UserRole.Id FROM User WHERE Contact.AccountId IN :accountMap.keySet() 
                              AND Contact.AccountId != null AND (UserRole.Name LIKE '%MANAGER%' or UserRole.Name LIKE '%EXECUTIVE%')];
        
        Set<Id> userRoleIdSet = new Set<Id>();
        for(User eachuser : userLst){
            userRoleIdSet.add(eachuser.UserRole.Id);
        }
        
        Map<Id,Group> mapOfGroups = new Map<Id,Group>([SELECT Id, Name, RelatedId, Type From Group WHERE RelatedId IN : userRoleIdSet AND Type = 'Role' ]);
                     
        UpdateAccountShareBatch updateAccountShareBatch1 = new UpdateAccountShareBatch(mapOfGroups.keySet());
        String batchID1 = database.executeBatch(updateAccountShareBatch1,200);
        
        System.debug('batchID for updateAccountShareBatch in UpdateAcctShareBatchScheduler '+batchID1);
    }
}