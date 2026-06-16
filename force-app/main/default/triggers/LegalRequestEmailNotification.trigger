trigger LegalRequestEmailNotification on Legal_Requests__c (before insert,before update,after update) {
	
	/*if(Trigger.isBefore){
		set<Id> legalRequestIdSet = new set<Id>();
		for(Legal_Requests__c requestObj : Trigger.New){
			if(requestObj.Status__c !=NULL && requestObj.Status__c != trigger.oldMap.get(requestObj.id).Status__c && requestObj.Status__c == 'Submitted'){
				legalRequestIdSet.add(requestObj.Id);
			}
		}
		
		if(legalRequestIdSet!=null && legalRequestIdSet.size() > 0){
			Map<Id,Legal_Requests__c> submittedLegalRequestMap = new Map<Id,Legal_Requests__c>([SELECT id,OwnerId,Owner.Email,Owner.Name,Status__c,recordType.Name,
                                                          		(SELECT id,Advisor_Name__c FROM Legal_Requests_Watchers__r where Advisor_Name__c=:UserInfo.getUserId() LIMIT 1)                                                          
                                                           		FROM Legal_Requests__c WHERE ID In : legalRequestIdSet]);     
       		system.debug('==Map=='+submittedLegalRequestMap);
       		for(Legal_Requests__c requestObj : Trigger.New){
       			if(submittedLegalRequestMap.get(requestObj.Id)!=null &&
       				submittedLegalRequestMap.get(requestObj.Id).Legal_Requests_Watchers__r != null && 
       				submittedLegalRequestMap.get(requestObj.Id).Legal_Requests_Watchers__r.size() > 0){
       				system.debug('=Enter=');
       				requestObj.addError('You do not have privilege to Submit this Legal Request.');
       			}
       		}
		}
	}*/
	
	Set<Id> userIdSet = new Set<Id>();
	
	if(Trigger.isBefore){
		if(Trigger.isUpdate){
			for(Legal_Requests__c requestObj : Trigger.New){
				if(Trigger.isInsert){
					if(requestObj.Inventor_Name__c != NULL){
						userIdSet.add(requestObj.Inventor_Name__c);
					}
				}
				if(Trigger.isUpdate){
					if(string.isNotBlank(Trigger.oldMap.get(requestObj.Id).Inventor_Name__c) && string.isBlank(requestObj.Inventor_Name__c)){
						requestObj.Inventor_Name_Text__c = null;
					}
					if(requestObj.Inventor_Name__c != NULL && 
						Trigger.oldMap.get(requestObj.Id).Inventor_Name__c != requestObj.Inventor_Name__c){
						userIdSet.add(requestObj.Inventor_Name__c);
					}
				}
			}
			
			if(userIdSet != NULL && userIdSet.size() > 0){
				Map<Id,User> userMap = new map<Id,User>([SELECT Id, Name FROM User WHERE Id IN : userIdSet]);
				for(Legal_Requests__c requestObj : Trigger.New){
					if(requestObj.Inventor_Name__c != NULL && 
					Trigger.oldMap.get(requestObj.Id).Inventor_Name__c != requestObj.Inventor_Name__c){
						requestObj.Inventor_Name_Text__c = (userMap !=null && userMap.get(requestObj.Inventor_Name__c) != null ? userMap.get(requestObj.Inventor_Name__c).Name :'');
					}
				}
			}
		}
	}
	
	if(Trigger.isAfter){
		set<Id> legalRequestIdSet = new Set<Id>();
		
		for(Legal_Requests__c requestObj : Trigger.New){
			legalRequestIdSet.add(requestObj.Id);	  	
		}
		
		if(legalRequestIdSet != null && legalRequestIdSet.size() > 0){
			EmailNotificationHelper.sendEmailNotification(legalRequestIdSet, trigger.oldMap);
		}
	}
}