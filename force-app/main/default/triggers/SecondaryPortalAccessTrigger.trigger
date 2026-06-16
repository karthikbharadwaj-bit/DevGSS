trigger SecondaryPortalAccessTrigger on Portal_Access__c (after insert,after update,after delete) {
    Set<Id> setOfAccountIds = new Set<Id>();
    Set<String> setOfBrandName = new Set<String>();
    Set<String> setOfCountry = new Set<String>();
    Set<String> setOfGroupName = new Set<String>();
    if (Trigger.isInsert) {
        for (Portal_Access__c acc : (List<Portal_Access__c>) Trigger.new) {            
            if((acc.Brand_Name__c != null && acc.Brand_Name__c != '') && 
                        (acc.Country__c != null && acc.Country__c != '') && 
                        (acc.Group_Developer_Name__c != null && acc.Group_Developer_Name__c != '')){
                setOfBrandName.add(acc.Brand_Name__c);
                setOfCountry.add(acc.Country__c);
            }else if(acc.Account__c != null && acc.Contact__c != null){
                setOfAccountIds.add(acc.Account__c);
            }
        }                        
    }
    if (Trigger.isUpdate) {
        Map<Id,Portal_Access__c> newMap = (Map<Id,Portal_Access__c>)Trigger.newMap;
        Map<Id,Portal_Access__c> oldMap = (Map<Id,Portal_Access__c>)Trigger.oldMap;
        for(Id eachAccessId : newMap.keySet()) {
            Portal_Access__c objNewAccess = newMap.get(eachAccessId);
            if(objNewAccess.Brand_Name__c != oldMap.get(eachAccessId).Brand_Name__c || 
                    objNewAccess.Country__c != oldMap.get(eachAccessId).Country__c || 
                    objNewAccess.Group_Developer_Name__c != oldMap.get(eachAccessId).Group_Developer_Name__c){
                setOfBrandName.add(objNewAccess.Brand_Name__c);
                setOfCountry.add(objNewAccess.Country__c);
                setOfBrandName.add(oldMap.get(eachAccessId).Brand_Name__c);
                setOfCountry.add(oldMap.get(eachAccessId).Country__c);
            }else if(objNewAccess.Account__c != oldMap.get(eachAccessId).Account__c || 
                        objNewAccess.Contact__c != oldMap.get(eachAccessId).Contact__c){
                setOfAccountIds.add(objNewAccess.Account__c);   
            }
        }
    }        
    if (Trigger.isDelete) {
        for (Portal_Access__c acc : (List<Portal_Access__c>) Trigger.old) { 
            if((acc.Brand_Name__c != null && acc.Brand_Name__c != '') && 
                        (acc.Country__c != null && acc.Country__c != '') && 
                        (acc.Group_Developer_Name__c != null && acc.Group_Developer_Name__c != '')){  
                setOfBrandName.add(acc.Brand_Name__c);
                setOfCountry.add(acc.Country__c);
            }else if(acc.Account__c != null && acc.Contact__c != null){
                setOfAccountIds.add(acc.Account__c);
            }
        }        
    }
    if(!setOfBrandName.isEmpty() && !setOfCountry.isEmpty()){
       	SecondaryPortalAccessUtil.calculateSecondaryPartnerAcctShareFuture(setOfBrandName,setOfCountry);
        SecondaryPortalAccessUtil.calculateSecondaryCustomerAcctShareFuture(setOfBrandName,setOfCountry,'Both');
		SecondaryPortalAccessUtil.calculateSecondaryLeadShareFuture(setOfBrandName,setOfCountry);           
        SecondaryPortalAccessUtil.calculateSecondaryDealRegShareFuture(setOfBrandName,setOfCountry);
        SecondaryPortalAccessUtil.calculateSecondaryDealSupportShareFuture(setOfBrandName,setOfCountry); 
    }
    if(!setOfAccountIds.isEmpty()){
        Sharing_AccountLeadHandler.handleAccountShare(setOfAccountIds);
        Sharing_AccountLeadHandler.handleSharingOnCAMChangeFuture(setOfAccountIds,'Customer Accounts');
        Sharing_AccountLeadHandler.handleSharingOnCAMChangeFuture(setOfAccountIds,'Leads');
        Sharing_AccountLeadHandler.handleSharingOnCAMChangeFuture(setOfAccountIds,'Deal Registration');
        Sharing_AccountLeadHandler.handleSharingOnCAMChangeFuture(setOfAccountIds,'Deal Support');
    }
}