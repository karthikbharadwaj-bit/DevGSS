public class UserAccountMappingTriggerHandler {
    public static void beforeInsertUpdateMethod(List<User_Account_Mapping__c> newList){
        Set<Id> setOfContactIds = new Set<Id>();
        Map<Id,Id> mapOfContactToAccount = new Map<Id,Id>();
        for(User_Account_Mapping__c uam : newList){
            if(uam.Partner_Contact__c != null){
                setOfContactIds.add(uam.Partner_Contact__c);
            }
        }
        List<Contact> listOfContacts = [Select Id, AccountId from Contact where Id In:setOfContactIds];
        for(Contact con : listOfContacts){
            mapOfContactToAccount.put(con.Id, con.AccountId);
        }
        for(User_Account_Mapping__c umap : newList){
            if(umap.Partner_Contact__c != null){
                umap.Partner_Account__c = mapOfContactToAccount.get(umap.Partner_Contact__c);
                system.debug('Partner_Account__c >>'+umap.Partner_Account__c);
            }
        }
    }
    public static void afterInsertUpdateMethod(List<User_Account_Mapping__c> newList, Map<Id,User_Account_Mapping__c> oldMap, Map<Id,User_Account_Mapping__c> newMap){
        Set<Id> setOfUAMIds = new Set<Id>();
        Set<Id> setOfAccountIds = new Set<Id>();
        Set<Id> setOfUserIds = new Set<Id>();
        Map<Id,Id> mapPartnerToUserId = new  Map<Id,Id>();
        List<User_Account_Mapping__Share> listOfUAMSharesToCreate = new List<User_Account_Mapping__Share>();
        List<AccountShare> listOfAccountShareToCreate = new List<AccountShare>();
        Set<String> SetOfUniqueUAMShareIds = new Set<String>();
        Set<String> SetOfUniqueAcctShareIds = new Set<String>();
        
        for(User_Account_Mapping__c uam : newList){
            setOfUAMIds.add(uam.Id);
            setOfAccountIds.add(uam.Partner_Account__c);  
            if(oldMap != null && !oldMap.isEmpty()){
                setOfUserIds.add(oldMap.get(uam.Id).Partner_User__c);                
                setOfAccountIds.add(oldMap.get(uam.Id).Partner_Account__c);
            }
            mapPartnerToUserId .put(uam.Partner_Account__c,uam.Partner_User__c);
            
            if(Trigger.isInsert || (Trigger.isUpdate && ((oldMap.get(uam.Id).Partner_Account__c != newMap.get(uam.Id).Partner_Account__c)
                                                         || newMap.get(uam.Id).Partner_User__c != oldMap.get(uam.Id).Partner_User__c))){
                                                             if(mapPartnerToUserId != null && !mapPartnerToUserId.isEmpty()){
                                                                 Id userId;
                                                                 Id accId;
                                                                 if(uam.Partner_Account__c != null && mapPartnerToUserId.containsKey(uam.Partner_Account__c)){
                                                                     userId = mapPartnerToUserId.get(uam.Partner_Account__c);
                                                                     accId = uam.Partner_Account__c;
                                                                 }
                                                                 listOfUAMSharesToCreate.add(new User_Account_Mapping__Share(ParentId = uam.Id,
                                                                                                                             UserOrGroupId = userId, AccessLevel = 'Edit'));            
                                                                 SetOfUniqueUAMShareIds.add(String.valueOf(uam.Id)+String.valueOf(userId)); 
                                                             }            
                                                         }
        }        
        
        system.debug('mapPartnerToUserId>'+mapPartnerToUserId);
        system.debug('listOfUAMSharesToCreate>'+listOfUAMSharesToCreate);
        system.debug('SetOfUniqueUAMShareIds>'+SetOfUniqueUAMShareIds);
        system.debug('listOfAccountShareToCreate>'+listOfAccountShareToCreate);
        system.debug('SetOfUniqueAcctShareIds>'+SetOfUniqueAcctShareIds);
        
        if(!listOfUAMSharesToCreate.isEmpty()){ 
            List<User_Account_Mapping__Share> listOfUAMShares = [SELECT Id, ParentId, UserOrGroupId
                                                                 FROM User_Account_Mapping__Share
                                                                 WHERE ParentId IN: setOfUAMIds
                                                                 AND UserOrGroupId IN: setOfUserIds
                                                                 AND RowCause = 'Manual'];
            List<User_Account_Mapping__Share> listOfUAMSharesToDel = new List<User_Account_Mapping__Share>();
            List<User_Account_Mapping__Share> listOfUAMShareToInsert = new List<User_Account_Mapping__Share>();   
            Set<String> tmpSetOfUAMShare = new Set<String>();
            
            if(!listOfUAMShares.isEmpty()){
                for(User_Account_Mapping__Share uams : listOfUAMShares){
                    String tmp = String.valueOf(uams.ParentId)+String.valueOf(uams.UserOrGroupId);
                    if(!SetOfUniqueUAMShareIds.contains(tmp)){
                        listOfUAMSharesToDel.add(uams);
                    }else{
                        tmpSetOfUAMShare.add(String.valueOf(uams.ParentId)+'-'+String.valueOf(uams.UserOrGroupId));
                    }
                }
                Database.delete(listOfUAMSharesToDel, false);
            }
            
            if(!tmpSetOfUAMShare.isEmpty()){
                for(User_Account_Mapping__Share eashUAMS : listOfUAMSharesToCreate){
                    String tmp = String.valueOf(eashUAMS.ParentId)+'-'+String.valueOf(eashUAMS.UserOrGroupId);
                    if(!tmpSetOfUAMShare.contains(tmp)) {
                        listOfUAMShareToInsert.add(eashUAMS);
                    }
                }
            }
            system.debug('listOfUAMShares>'+listOfUAMShares);
            system.debug('listOfUAMSharesToDel>'+listOfUAMSharesToDel);
            system.debug('listOfUAMShareToInsert>'+listOfUAMShareToInsert);
            system.debug('tmpSetOfUAMShare>'+tmpSetOfUAMShare);            
            
            if(!listOfUAMShareToInsert.isEmpty()) {
                Database.insert(listOfUAMShareToInsert, false);
            } else {
                Database.insert(listOfUAMSharesToCreate, false);  
            }          
        }
        if(Trigger.isInsert) {
            Sharing_AccountLeadHandler.handleAccountShareFuture(setOfAccountIds);
        }
        if(Trigger.isUpdate){
            Sharing_AccountLeadHandler.handleAccountShareFuture(setOfAccountIds);
        } 
    }
    
    public static void beforeDelete(List<User_Account_Mapping__c> oldList){
        Set<Id> setOfUAMIds = new Set<Id>();
        Set<Id> setOfAccountIds = new Set<Id>();
        Set<Id> setOfUserIds = new Set<Id>();        
        Map<Id,Id> mapOfUAMToUser = new  Map<Id,Id>();
        List<User_Account_Mapping__c> listUAM = new List<User_Account_Mapping__c>();
        for(User_Account_Mapping__c uam : oldList){
            setOfUAMIds.add(uam.Id);            
            setOfAccountIds.add(uam.Partner_Account__c);
            setOfUserIds.add(uam.Partner_User__c);
            mapOfUAMToUser.put(uam.Id, uam.Partner_User__c);
        }
        system.debug('setOfAccountIds>>'+setOfAccountIds);
        system.debug('mapOfUAMToUser>>'+mapOfUAMToUser);
        Sharing_AccountLeadHandler.handleAccountShareFuture(setOfAccountIds);
    }
}