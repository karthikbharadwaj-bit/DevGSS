public with sharing class ValidateLeadDuplicacy {
	private static Id partnerRCTypeId = LeadHelper.RT_ID_PARTNER_LEADS;
    public static List<Lead> validatePerToday(List<Lead> upcomingLeads) {
    	List<Lead> leadObjList = new List<Lead>();
    	List<Lead> newLeadObjs = new List<Lead>();
        Map<String, Id> emailLeadMap = new Map<String, Id>();   
        Map<Id, Id> newToExistingMap = new Map<Id, Id>();                    
        List<String> emails = new List<String>();
        try {   
	    	for(Lead leadObj : upcomingLeads) {
	    		if(!hasExceptionRules(leadObj)) {
	    			leadObjList.add(leadObj);
	    		}
	    		leadObj.isDuplicate__c = 'false';
	    		leadObj.Duplicate_Lead__c = false;
	    	}
	    	
	        for(Lead leadObj : leadObjList) {
	            emails.add(leadObj.Email);
		        System.debug('####### Lead Object=> '+leadObj.Id);
	        }
	        // finding the duplicated associated to provided emails
	        /*List<Lead> dupLead = [SELECT Id, Email FROM Lead WHERE Email IN: emails AND CreatedDate = TODAY 
	        AND Email != 'fake@email.com' AND Email != 'fake@fake.com' AND Status != '0. Downgraded' 
	        AND isDuplicate__c = 'false' AND IsConverted = false ORDER BY CreatedDate DESC];
	        */
	        List<Lead> dupLead = [SELECT Id, Email FROM Lead WHERE Email IN: emails AND CreatedDate = TODAY 
	        AND Email != 'fake@email.com' AND Email != 'fake@fake.com' AND Status != '0. Downgraded' 
	        AND (Duplicate_Lead__c=null OR Duplicate_Lead__c = false) AND IsConverted = false ORDER BY CreatedDate DESC];
	        
	        
	        for(Lead obj: dupLead) {
	        	if(emailLeadMap.get(obj.Email) == null) {
	            	emailLeadMap.put(obj.Email, obj.Id);
				}
	        }
	        // preveting the duplicate leads to be created
	        for(Lead leadObj : leadObjList){
	            if(emailLeadMap.containsKey(leadObj.Email)) {
	                 leadObj.isDuplicate__c = 'true';
	                 leadObj.Duplicate_Lead__c = true;
	                 leadObj.existingLeadId__c = emailLeadMap.get(leadObj.Email);
	                 leadObj.LeadExistingSource__c = 'Lead';
	            } else {
	            	newLeadObjs.add(leadObj);
	            }
	        }
        } catch(Exception e) {
			ExceptionHelper.createExceptionAndNotificacionHistory(e, upcomingLeads, 'Lead Exception');
		}
        if(newLeadObjs.size() != 0) {
        	System.debug('##### => Checking with Status');
        	newLeadObjs = new List<Lead>(validatePerStatus(newLeadObjs));
        }
       
        return newLeadObjs;
    }
    public static List<Lead> validatePerStatus(List<Lead> leadObjList) {
    	List<Lead> newLeadObjs = new List<Lead>();
        Map<String, String> emailLeadMap = new Map<String, String>();                        
        List<String> emails = new List<String>();   
        try {
	        for(Lead leadObj : leadObjList){
	            emails.add(leadObj.Email);
	        }
	        List<Lead> dupLead = [SELECT Id, Email FROM Lead WHERE Email IN: emails 
	        AND Email != 'fake@email.com' AND Email != 'fake@fake.com' AND (Duplicate_Lead__c = null OR Duplicate_Lead__c = false) AND IsConverted = false
	        AND Status IN ('1.5 Call Out','2. Contacted') ORDER BY CreatedDate DESC];
	        for(Lead obj: dupLead) {
	            emailLeadMap.put(obj.Email, obj.Id);
	        }
	        for(Lead leadObj : leadObjList){
	            if(emailLeadMap.containsKey(leadObj.Email)) {
	                 leadObj.isDuplicate__c = 'true';
	                 leadObj.Duplicate_Lead__c = true;
	                 leadObj.existingLeadId__c = emailLeadMap.get(leadObj.Email);
	                 leadObj.LeadExistingSource__c = 'Lead';
	            } else {
	            	newLeadObjs.add(leadObj);
	            }
	        }
        } catch(Exception e) {}
        if(newLeadObjs.size() != 0) {
        	System.debug('##### => Checking with Stages');
        	newLeadObjs = new List<Lead>(validatePerStages(newLeadObjs));
        }
        return newLeadObjs;
    }

    public static List<Lead> validatePerStages(List<Lead> leadObjList) {
    	List<Lead> newLeadObjs = new List<Lead>();
        Map<String, Id> emailLeadMap = new Map<String, Id>();                        
        List<String> emails = new List<String>();
		Map<String, List<Contact>> accIdToContactsMap = new Map<String, List<Contact>>();
		Set<String> alteredStages = OpportunityHelper.alteredStages;

        try {   
	        for (Lead leadObj : leadObjList) {
	            emails.add(leadObj.Email);
	        }
	        List<Contact> contactList = (List<Contact>) new ContactSelector()
				.selectContactsWithAccountByEmail(new List<Object> {emails})
				.executeQuery();
			for (Contact c : contactList) {
				if (c.Account.RC_Account_Status__c == 'Paid' 
					&& !emailLeadMap.containsKey(c.Email)) {
						emailLeadMap.put(c.Email, c.Id);
				} else {
					if (accIdToContactsMap.get(c.AccountId) != null) {
						List<Contact> contacts = accIdToContactsMap.get(c.AccountId);
						contacts.add(c);
						accIdToContactsMap.put(c.AccountId, contacts);
					} else {
						accIdToContactsMap.put(c.AccountId, new List<Contact> {c});
					}		
				}
			}
	        List<Opportunity> oppList = (List<Opportunity>) new OpportunitySelector()
				.selectOpportunitiesByStagesAndAccountId(new List<Object> {accIdToContactsMap.keySet(), alteredStages})
				.executeQuery();
			for (Opportunity oppObj : oppList) {
				List<Contact> contacts = accIdToContactsMap.get(oppObj.AccountId);
				for (Contact ct : contacts) {
					if (!emailLeadMap.containsKey(ct.email)) {
						emailLeadMap.put(ct.email, ct.Id);
					}
				}
	        }
	        
	        for (Lead leadObj : leadObjList) {
	            if (emailLeadMap.containsKey(leadObj.Email)) {
	                 leadObj.isDuplicate__c = 'true';
	                 leadObj.Duplicate_Lead__c = true;
	                 leadObj.existingLeadId__c = emailLeadMap.get(leadObj.Email);
	                 leadObj.LeadExistingSource__c = 'Opportunity';
	            } else {
	            	newLeadObjs.add(leadObj);
	            }
	        }
        } catch (Exception e) {
			ExceptionHelper.createExceptionAndNotificacionHistory(e, leadObjList, 'Lead Exception');
		}
        return newLeadObjs;
    }

    public static Boolean compare(String str, String value) {
    	if(str == null || str == ''){
    		return false;
    	}
    	if(str.equalsIgnoreCase(value)) {
    		return true;
    	}
    	return false;
    }

    public static Boolean hasExceptionRules(Lead leadObj) {
    	if(compare(leadObj.Email,'fake@email.com')) {
    		return true;
    	}
    	if(compare(leadObj.FirstName,'Something') && compare(leadObj.LastName, 'New')){
    		return true;
    	}
        if(compare(leadObj.FirstName,'rctu') && compare(leadObj.LastName,'2calls4me')){
        	return true;
        }
        if(compare(leadObj.LeadSource,'About To Be Cancelled') || compare(leadObj.LeadSource, 'About To Be Cancelled UK')) {
			return true;	
		}
		// Bypass Partner Lead Duplicacy check : Case# 02364068  
		system.debug('@@@@@@@@@@@@@@ leadObj.RecordType.developername  '+ partnerRCTypeId);
		if((leadObj.RecordTypeId != null) && (String.valueOf(leadObj.RecordTypeId).trim() == partnerRCTypeId)){
			return true;
		}
		return false;
    }
}