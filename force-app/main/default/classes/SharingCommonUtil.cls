global class SharingCommonUtil {
    
    webservice static void sharingRecalculateContact(List<Id> contacts){
        system.debug('contact from button>>'+contacts);
        Set<Id> accIds = new Set<Id>();      
        Map<Id,Id> mapOfUAMToUser = new Map<Id,Id>();
        List<Contact> cont = new List<Contact>([Select Account.Id 
                                                From Contact 
                                                Where Id =: contacts.get(0) and Account.Id != null 
                                                And Avaya_Partnership_Contact__c = true]);
        
        List<User> usrs = new List<User>([Select Id, ProfileId, UserRoleId, Name, IsActive 
                                          From User 
                                          Where Contact.Id IN :contacts 
                                          And IsActive = true 
                                          And Profile.Name like '%Partner Admin']);
        
        List<User_Account_Mapping__c> listOfUAM = new List<User_Account_Mapping__c>([Select Id,Partner_Account__c,Partner_User__c,Partner_Contact__c
                                                                                     From User_Account_Mapping__c 
                                                                                     Where Partner_Contact__c IN: contacts]);
        
        system.debug('contacts>>'+cont);
        system.debug('users>>'+usrs);
        system.debug('listOfUAM>>'+listOfUAM);
        
        if(cont != null && !cont.isEmpty() && (usrs != null && !usrs.isEmpty()) || (listOfUAM != null && !listOfUAM.isEmpty()) && cont.size()>0){
            for(Contact con : cont){ 
                accIds.add(con.Account.Id);
            }
            if(listOfUAM != null && !listOfUAM.isEmpty()){
                for(User_Account_Mapping__c uam : listOfUAM){
                    mapOfUAMToUser.put(uam.Id, uam.Partner_User__c);
                }
            }
        }
        if(!accIds.isEmpty() && accIds != null){           	
            getAccountPartnerShareFuture(accIds);
            getAccountCustomerShareFuture(accIds);
            getAccountDealRegShareFuture(accIds,contacts);
            getAccountLeadShareFuture(accIds,contacts);
            getAccountDealSupportShareFuture(accIds,contacts);
        }   
        if(!mapOfUAMToUser.isEmpty() && mapOfUAMToUser != null){
            getSharingForUAM(mapOfUAMToUser);
        }
    }
    
    @future
    public static void getSharingForUAM(Map<Id,Id> mapOfUAMToUser){
        List<User_Account_Mapping__Share> listOfUAMSharesToCreate = new List<User_Account_Mapping__Share>();
        Set<String> SetOfUniqueUAMShareIds = new Set<String>();
        Set<Id> userIds = new Set<Id>();
        if(mapOfUAMToUser != null && !mapOfUAMToUser.isEmpty()){
            for(Id uamId : mapOfUAMToUser.keySet()){
                userIds.add(mapOfUAMToUser.get(uamId));
                listOfUAMSharesToCreate.add(new User_Account_Mapping__Share(ParentId = uamId,UserOrGroupId = mapOfUAMToUser.get(uamId), 
                                                                            AccessLevel = 'Edit'));            
                SetOfUniqueUAMShareIds.add(String.valueOf(uamId)+String.valueOf(mapOfUAMToUser.get(uamId)));
            }
        }
        if(!listOfUAMSharesToCreate.isEmpty()){ 
            List<User_Account_Mapping__Share> listOfUAMShares = [SELECT Id, ParentId, UserOrGroupId
                                                                 FROM User_Account_Mapping__Share
                                                                 WHERE ParentId IN: mapOfUAMToUser.keySet()
                                                                 AND UserOrGroupId IN: userIds
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
    }
    
    @future
    public static void getAccountPartnerShareFuture(Set<Id> accIds){
        Map<Id,Account> MapOfPartnerAccountIds = new Map<Id,Account>([SELECT Id FROM Account WHERE Id IN :accIds 
                                                                      AND Avaya_Partnership_Account__c = true 
                                                                      AND type = 'Partner']);
        if(MapOfPartnerAccountIds != null && !MapOfPartnerAccountIds.isEmpty() && MapOfPartnerAccountIds.keySet() != null){
            Sharing_AccountLeadHandler.handleAccountShare(MapOfPartnerAccountIds.keySet());
            Quote_SharingHandler.handlePartnerQuoteSharingForAccount(MapOfPartnerAccountIds.keySet());
        }
    }
    @future
    public static void getAccountCustomerShareFuture(Set<Id> accIds){
        Map<Id,Account> MapOfCustAccountIds = new Map<Id,Account>([SELECT Id FROM Account WHERE Partner_Account__c IN :accIds 
                                                                   AND Avaya_Partnership_Account__c = true 
                                                                   AND type = 'Customer']);
        if(MapOfCustAccountIds != null && !MapOfCustAccountIds.isEmpty() && MapOfCustAccountIds.keySet() != null){            
            Sharing_AccountLeadHandler.handleAccountShare(MapOfCustAccountIds.keySet());
            Quote_SharingHandler.handlePartnerQuoteSharingForAccount(MapOfCustAccountIds.keySet());
        }
    }
    @future
    public static void getAccountDealRegShareFuture(Set<Id> accIds, List<Id> contacts){
        Map<Id,Deal_Registration__c> mapOfDealReg = new Map<Id,Deal_Registration__c>([SELECT Id FROM Deal_Registration__c WHERE 
                                                                                      Partner_Account__c IN :accIds 
                                                                                      AND Partner_Contact__c IN :contacts
                                                                                      AND Avaya_Partnership_Deal__c = true]);
        if(mapOfDealReg != null && !mapOfDealReg.isEmpty() && mapOfDealReg.keySet() != null){
            Quote_SharingHandler.handleDealRegistrationShareFuture(mapOfDealReg.keySet());
        }
    }
    @future
    public static void getAccountLeadShareFuture(Set<Id> accIds, List<Id> contacts){
        Map<Id,Lead> mapOfLeads = new Map<Id,Lead>([SELECT Id FROM Lead WHERE Avaya_Partnership_Lead__c = true 
                                                    AND Partner_Contact__c IN :contacts
                                                    AND Partner_Account__c IN :accIds]);
        if(mapOfLeads != null && !mapOfLeads.isEmpty() && mapOfLeads.keySet() != null){
            Sharing_AccountLeadHandler.handleLeadShare(mapOfLeads.keySet());
        }
    }
    @future
    public static void getAccountDealSupportShareFuture(Set<Id> accIds, List<Id> contacts){
        Map<Id,Deal_support__c> mapOfDealSupport = new Map<Id,Deal_support__c>([SELECT Id FROM Deal_support__c WHERE 
                                                                                (Lead__r.Partner_Contact__c IN :contacts
                                                                                 OR Customer_Account__r.Partner_Contact__c IN :contacts
                                                                                 OR Partner_Contact__r.Id IN :contacts)
                                                                                AND (Lead__r.Partner_Account__c IN :accIds 
                                                                                     OR Customer_Account__r.Partner_Account__c IN :accIds
                                                                                     OR Partner_Account__r.Id IN :accIds)]);
        if(mapOfDealSupport != null && !mapOfDealSupport.isEmpty() && mapOfDealSupport.keySet() != null){
            Quote_SharingHandler.handleDealSupportShare(mapOfDealSupport.keySet());
        }
    }
}