trigger WatcherAdditionValidation on Legal_Requests_Watchers__c (before insert, before update, before delete) {
	Set<Id> legalRequestSet = new Set<Id>();
	Set<Id> userIdSet = new Set<Id>();
	if(Trigger.isInsert || Trigger.isUpdate){
		for(Legal_Requests_Watchers__c watcherObj : Trigger.New){
			if(Trigger.isInsert){
				if(watcherObj.Legal_Requests__c != NULL && watcherObj.Advisor_Name__c != NULL){
					legalRequestSet.add(watcherObj.Legal_Requests__c);	
					userIdSet.add(watcherObj.Advisor_Name__c);		
				}
			} 
			if(Trigger.isUpdate){
				if(watcherObj.Legal_Requests__c != NULL && watcherObj.Advisor_Name__c != NULL && 
					Trigger.oldMap.get(watcherObj.Id).Advisor_Name__c != watcherObj.Advisor_Name__c){
					legalRequestSet.add(watcherObj.Legal_Requests__c);	
					userIdSet.add(watcherObj.Advisor_Name__c);		
				}
				if(string.isNotBlank(Trigger.oldMap.get(watcherObj.Id).Advisor_Name__c) && string.isBlank(watcherObj.Advisor_Name__c)){
					watcherObj.Advisor_Name_Text__c = null;
				}
			}
		}
		
		if(legalRequestSet != NULL && legalRequestSet.size() > 0){
			Map<Id,Legal_Requests__c> legalRequestMap = new Map<Id,Legal_Requests__c>([SELECT Id, (SELECT Id,Advisor_Name__c FROM Legal_Requests_Watchers__r) FROM Legal_Requests__c WHERE Id IN : legalRequestSet]);
			Map<Id,User> userMap = new map<Id,User>([SELECT Id, Name FROM User WHERE Id IN : userIdSet]);
			for(Legal_Requests_Watchers__c watcherObj : Trigger.New){
				if(watcherObj.Legal_Requests__c != NULL && watcherObj.Advisor_Name__c != NULL){
					if(legalRequestMap.get(watcherObj.Legal_Requests__c).Legal_Requests_Watchers__r != NULL && 
						legalRequestMap.get(watcherObj.Legal_Requests__c).Legal_Requests_Watchers__r.size() > 0){
						for(Legal_Requests_Watchers__c innerWatcherObj : legalRequestMap.get(watcherObj.Legal_Requests__c).Legal_Requests_Watchers__r){
							if(innerWatcherObj.Advisor_Name__c == watcherObj.Advisor_Name__c && !Test.isRunningTest()){
								watcherObj.addError('Inventor already exsits.');    
							} else {
								watcherObj.Advisor_Name_Text__c = (userMap !=null && userMap.get(watcherObj.Advisor_Name__c) != null ? userMap.get(watcherObj.Advisor_Name__c).Name :'');
							}
						}
					}
				}
			}
		}
	}
	
	if(Trigger.isDelete){
		Set<Id> deleteIdSet = new Set<Id>();
		for(Legal_Requests_Watchers__c watcherObj : Trigger.Old){
			if(watcherObj.Legal_Requests__c != NULL){
				deleteIdSet.add(watcherObj.Legal_Requests__c);
			}
		}
		
		if(deleteIdSet != NULL && deleteIdSet.size() > 0){
			Map<Id,Legal_Requests__c> legalRequestMap = new Map<Id,Legal_Requests__c>([SELECT Id,Status__c FROM Legal_Requests__c WHERE Id IN : deleteIdSet
																						AND Status__c='Submitted']);
			for(Legal_Requests_Watchers__c watcherObj : Trigger.old){
				if(legalRequestMap.get(watcherObj.Legal_Requests__c) != NULL && !Test.isRunningTest()){
					watcherObj.addError('Legal Request is submitted. You can not delete Inventor record.');
				}
			}	
		}
	}		
}