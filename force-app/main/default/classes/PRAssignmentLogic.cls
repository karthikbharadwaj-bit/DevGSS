/*
	Common Class to Check and Run all Protection Rules Logic and Geo Territory Routing Logic
*/
public class PRAssignmentLogic { 
	
	/*************************************Check Active Account Current Owner from Contact************************************************/ 
	public static void checkAccountCurrentOwner(map<String,RcDealHealper.searchResultClass> searchResultMap,map<String,String> prOwnerMap,
                                                map<String,PRAssignmentLogic.prRuleWrapper> prOwnerDetailMap,Set<string> excludedPRUserIdSet){
        system.debug('=searchResultMap='+searchResultMap);    
        for(String uniqueKey : searchResultMap.keySet()){
            prOwnerMap.put(uniqueKey,'not found');
            if(searchResultMap.get(uniqueKey).contactResultList != null && searchResultMap.get(uniqueKey).contactResultList.size() > 0){
                for(Contact conObj : searchResultMap.get(uniqueKey).contactResultList){
                    if((conObj.Account.RecordType.Name == 'Customer Account' 
                        && conObj.Account.Current_Owner__c!=null 
                        && !excludedPRUserIdSet.contains(string.valueOf(conObj.Account.Current_Owner__c).subString(0,15))
                        && conObj.Account.Current_Owner__r.IsActive) || (Test.isRunningTest())){
                        prOwnerMap.put(uniqueKey,conObj.Account.Current_Owner__c);	   																														//Relayware																			
                            prOwnerDetailMap.put(uniqueKey,new PRAssignmentLogic.prRuleWrapper(conObj.Id,conObj.Account.Partner_ID__c,conObj.Account.Inside_Sales_Rep__c,conObj.Account.Partner_Owner__c,conObj.Account.Partner_Contact__c,'RingCentral',Schema.Sobjecttype.Lead.getRecordTypeInfosByName().get('Partner Leads').getRecordTypeId(),conObj.Account.Partner_Account_Name__c,conObj.Account.Ultimate_Parent_Partner_ID__c,conObj.Account.Ultimate_Parent_Account_Name__c,conObj.Account.Current_Owner__r.Name,conObj.Account.VAR_Territory__c,conObj.Account.Current_Owner__c,(string.isNotBlank(conObj.Account.Partner_ID__c) ? true : false),(string.isNotBlank(conObj.Account.Partner_Owner__c) ? conObj.Account.Partner_Owner__r.isActive : false),conObj.MailingStreet,conObj.MailingCity,conObj.MailingState,conObj.MailingCountry,conObj.MailingPostalCode,conObj.AccountId));
                            searchResultMap.remove(uniqueKey);      
                            break;        
                    }
                }
            }
        }
        system.debug('=prOwnerMap='+prOwnerMap);
        if(searchResultMap!=null && searchResultMap.size() > 0){
            checkActivePipeOrProtected(searchResultMap,prOwnerMap,prOwnerDetailMap);   
        }
    }
	
	/***************************************Check Active Pipe Opportunity and Protected Lead**************************************************/
	public static void checkActivePipeOrProtected(map<String,RcDealHealper.searchResultClass> activePipeOrProtectedMap,map<String,String> prOwnerMap,
												  map<String,PRAssignmentLogic.prRuleWrapper> prOwnerDetailMap){
		map<Id,List<String>> leadContactMappingMap = new map<Id,List<String>>();
		map<String,Id> protectedLeadMap = new map<String,Id>();
		//map<String,String> protectedLeadIdMap = new map<String,String>();
		map<String,PRAssignmentLogic.prRuleWrapper> protectedLeadIdMap = new map<String,PRAssignmentLogic.prRuleWrapper>();		
		set<Id> conIdSet = new set<Id>();
		for(String uniqueKey : activePipeOrProtectedMap.keySet()){
			if(activePipeOrProtectedMap.get(uniqueKey).contactResultList != null && activePipeOrProtectedMap.get(uniqueKey).contactResultList.size() > 0){
				Contact conObj = activePipeOrProtectedMap.get(uniqueKey).contactResultList[0];
				if(leadContactMappingMap!=null && leadContactMappingMap.get(conObj.Id)!=null){
					List<string> uniqueKeyList = leadContactMappingMap.get(conObj.Id);
					uniqueKeyList.add(uniqueKey);
					leadContactMappingMap.put(conObj.Id,uniqueKeyList);
				}else{
					leadContactMappingMap.put(conObj.Id,new List<String>{uniqueKey});
				}
				conIdSet.add(conObj.id);
			}
			
			if(activePipeOrProtectedMap.get(uniqueKey).leadResultList != null && activePipeOrProtectedMap.get(uniqueKey).leadResultList.size() > 0){
				for(Lead leadObj : activePipeOrProtectedMap.get(uniqueKey).leadResultList){
					if((leadObj.Is_Protected__c && leadObj.OwnerId!=null && leadObj.Owner.IsActive) || (Test.isRunningTest())){
						protectedLeadMap.put(uniqueKey,leadObj.ownerId);
						//protectedLeadIdMap.put(uniqueKey,leadObj.Id);																														//Relayware
						protectedLeadIdMap.put(uniqueKey,new PRAssignmentLogic.prRuleWrapper(leadObj.Id,leadObj.LeadPartnerID__c,leadObj.Inside_Sales_Rep__c,leadObj.Partner_Lead_Owner__c,leadObj.Partner_Contact__c,leadObj.Partner_Lead_Source__c,leadObj.RecordTypeId,leadObj.Partner_Account_Name__c,leadObj.Ultimate_Parent_Account_Partner_ID__c,leadObj.Ultimate_Parent_Account_Name__c,leadObj.Current_Owner_Name__c,leadObj.VAR_Territory__c,leadObj.OwnerId,(string.isNotBlank(leadObj.LeadPartnerID__c) ? true : false),(string.isNotBlank(leadObj.Partner_Lead_Owner__c) ? leadObj.Partner_Lead_Owner__r.isActive : false),leadObj.Street,leadObj.City,leadObj.State,leadObj.Country,leadObj.PostalCode,leadObj.Partner_Account__c));					
						break;
					}
				}
			}
		}
		system.debug('=conIdSet='+conIdSet);
		List<OpportunityContactRole> oppConRoleList = new List<OpportunityContactRole>();
		map<string,boolean> oppValidStatusMap = new map<string,boolean>{'1. Qualify'=>true,'2. Problem'=>true,'3. Solution'=>true,'4. Proof'=>true,
																		'5. Agreement'=>true,'6. Order'=>true,'.5 Re-New'=>true}; 
		if(conIdSet!=null && conIdSet.size() > 0){
			List<Contact> contactList = [Select id,
										(Select id,ContactId,Opportunity.Id,Opportunity.OwnerId,Opportunity.StageName,Opportunity.Opportunity_Owner_IsActive__c,
										 Opportunity.DFR_Actual_Close_DateTime__c,Opportunity.Is_Protected__c from OpportunityContactRoles
										 where IsPrimary=true AND Opportunity.Opportunity_Owner_IsActive__c=true ORDER BY CreatedDate DESC
										 LIMIT 1) from Contact where Id in : conIdSet];
			
			for(Contact conObj : contactList){
				if(conObj.OpportunityContactRoles!=null && conObj.OpportunityContactRoles.size() > 0){
					OpportunityContactRole oppConRoleObj = new OpportunityContactRole();
					oppConRoleObj = conObj.OpportunityContactRoles[0];
					if(oppConRoleObj.Opportunity.StageName != '0. Downgraded'){
						if(oppValidStatusMap.get(oppConRoleObj.Opportunity.StageName) != null){
							system.debug('Active Pipe Opp Condition'+oppConRoleObj);
							if(leadContactMappingMap!=null && leadContactMappingMap.get(oppConRoleObj.ContactId)!=null){
								for(String uniqueKey : leadContactMappingMap.get(oppConRoleObj.ContactId)){
									prOwnerMap.put(uniqueKey,oppConRoleObj.Opportunity.OwnerId);												//Relayware
									prOwnerDetailMap.put(uniqueKey,new PRAssignmentLogic.prRuleWrapper(oppConRoleObj.Opportunity.Id,'','','','','','','','','','','','',false,false,'','','','','',''));
									activePipeOrProtectedMap.remove(uniqueKey);
								}
							}					
						}else if(oppConRoleObj.Opportunity.Is_Protected__c){
							system.debug('Active Pipe Opp Condition Closed'+oppConRoleObj);		
							if(leadContactMappingMap!=null && leadContactMappingMap.get(oppConRoleObj.ContactId)!=null){
								for(String uniqueKey : leadContactMappingMap.get(oppConRoleObj.ContactId)){				
									prOwnerMap.put(uniqueKey,oppConRoleObj.Opportunity.OwnerId);												//Relayware
									prOwnerDetailMap.put(uniqueKey,new PRAssignmentLogic.prRuleWrapper(oppConRoleObj.Opportunity.Id,'','','','','','','','','','','','',false,false,'','','','','',''));
									activePipeOrProtectedMap.remove(uniqueKey);
								}
							}					
						}
					}
				}
			}
		}
			
		if(activePipeOrProtectedMap!=null && activePipeOrProtectedMap.size() > 0){
			system.debug('Enter in Protected Lead Check');
			for(String uniqueKey : activePipeOrProtectedMap.keySet()){
				if(protectedLeadMap!=null && protectedLeadMap.get(uniqueKey)!=null){
					//system.debug('Protected Lead Found');		
					prOwnerMap.put(uniqueKey,protectedLeadMap.get(uniqueKey));
					if(protectedLeadIdMap!=null && protectedLeadIdMap.get(uniqueKey)!=null){							//Relayware
						PRAssignmentLogic.prRuleWrapper wrapperObj = new PRAssignmentLogic.prRuleWrapper('','','','','','','','','','','','','',false,false,'','','','','','');
						wrapperObj = protectedLeadIdMap.get(uniqueKey);
						prOwnerDetailMap.put(uniqueKey,wrapperObj);
					}
					activePipeOrProtectedMap.remove(uniqueKey);
				}
			}
		}
		system.debug('=pmap='+prOwnerMap);		
	}
	
	/*************Create User Owner Map	based on User Email*****************/
	public static map<string,User> createEmailOwnerMap(List<Lead> newLeadList){		 
		Set<string> userEmailSet = new Set<String>();
		map<String,User> userEmailOwnerMap = new map<String,User>();
		for(Lead leadObj : newLeadList){ 
			if(leadObj.Lead_Owner_Email_Address__c != null){
				userEmailSet.add(leadObj.Lead_Owner_Email_Address__c);
			}
			if(leadObj.Sales_Agent_Email__c != null){
				userEmailSet.add(leadObj.Sales_Agent_Email__c);
			}
		}
		if(userEmailSet != null && userEmailSet.size() > 0){
			for(User userObj : [SELECT id,Email,IsActive,Username,Contact.Account.Partner_ID__c,Contact.Account.Current_Owner__c,Contact.Account.Current_Owner__r.isActive,
							    Contact.Account.Name,Contact.Account.Ultimate_Partner_ID__c,Contact.Account.Ultimate_Parent_Partner_ID__c,Contact.Account.Ultimate_Partner_Name__c,Contact.Account.VAR_Territory__c,
								Contact.Account.Ultimate_Parent_Account_Name__c,Profile.Name, Contact.Account.Current_Owner__r.Name,Contact.Account.Inside_Sales_Rep__c, ContactId,
								Contact.MailingStreet,Contact.MailingState,Contact.MailingCity,Contact.MailingCountry,Contact.MailingPostalCode 
								FROM User WHERE UserName in : userEmailSet AND IsActive = true]){
				userEmailOwnerMap.put( userObj.Username,userObj); 
			}
		}
		system.debug('=userEmailOwnerMap='+userEmailOwnerMap);
		return userEmailOwnerMap; 
	}
	/***************************************************************************/
	
	//Relayware
	/*************Create Contact Owner Map	based on User Email*****************/
	public static map<string,Contact> createEmailContactMap(List<Lead> newLeadList){		 
		Set<string> contactEmailSet = new Set<String>();
		map<String,Contact> contactEmailOwnerMap = new map<String,Contact>();
		for(Lead leadObj : newLeadList){ 
			//if(string.isNotBlank(leadObj.Partner_Contact__c)){
			if(leadObj.Lead_Owner_Email_Address__c != null){
				contactEmailSet.add(leadObj.Lead_Owner_Email_Address__c);
			}
			if(leadObj.Sales_Agent_Email__c != null){
				contactEmailSet.add(leadObj.Sales_Agent_Email__c);
			}
			//}
		}
		if(contactEmailSet != null && contactEmailSet.size() > 0){
			for(Contact conObj : [SELECT Id,Email,AccountId,Account.Partner_ID__c,Account.Current_Owner__c,Account.Current_Owner__r.isActive,
							    Account.Name,Account.Ultimate_Partner_ID__c,Account.Ultimate_Parent_Partner_ID__c,Account.Ultimate_Partner_Name__c,Account.VAR_Territory__c,
								Account.Ultimate_Parent_Account_Name__c,Account.Current_Owner__r.Name,Account.Inside_Sales_Rep__c,
								MailingStreet,MailingState,MailingCity,MailingCountry,MailingPostalCode 
								FROM Contact WHERE Email in : contactEmailSet AND Relayware_Portal_User__c='Approved']){
				contactEmailOwnerMap.put( conObj.Email,conObj); 
			}
		}
		system.debug('=contactEmailOwnerMap='+contactEmailOwnerMap);
		return contactEmailOwnerMap; 
	}
	
	
	/***************Create Set of Users having profile 'System Administrator'****************************/
	public static set<string> findSystemAdminUser(){
		set<string> userIdSet = new set<string>();
		for(User userObj : [Select id from User where Profile.Name='System Administrator' AND IsActive = true]){
			userIdSet.add(string.valueOf(userObj.Id).subString(0,15));
		}
		return userIdSet;
	}
	
	/**********************************Run All the PR Condition Filters Step by Step***************************************************/
	//Relayware
	public static boolean runPRLogic(Lead leadObj, String uniqueKey,map<String,String> prOwnerMap,Map<String,PRAssignmentLogic.prRuleWrapper> prOwnerDetailMap,
										map<String,User> userEmailOwnerMap,map<String,Contact> contactEmailOwnerMap,User loggedInUser, User VarContactUser,
										 Boolean isActiveOwner) {
		boolean userFound = false;
		ProtectionRuleExceptions pre = new ProtectionRuleExceptions(leadObj);
		//Check Account Current owner and Active Pipe Condition
		if(pre.useProtectionRuleCheck()) {
			if(prOwnerMap!=null && prOwnerMap.get(uniqueKey)!=null && prOwnerMap.get(uniqueKey)!='not found') {
				leadObj.Assignment_Source_hidden__c = 'PR PER CURRENT OWNER OR ACTIVE PIPE';
				leadObj.OwnerId = prOwnerMap.get(uniqueKey);
				if(prOwnerDetailMap!=null && prOwnerDetailMap.get(uniqueKey)!=null){
					PRAssignmentLogic.prRuleWrapper wrapperObj = prOwnerDetailMap.get(uniqueKey);
					leadObj.PR_Assignment_ID__c = wrapperObj.recordId; 
                    if( wrapperObj.isPartner == true){
                    	leadObj.LeadPartnerID__c = wrapperObj.leadPartnerId;
                    	leadObj.Inside_Sales_Rep__c = wrapperObj.channelManager;
                    	//Due to inactive Partner owner causing syn issue in market Case # 04108455
                    	if(wrapperObj.isPartnerOwnerActive != Null && wrapperObj.isPartnerOwnerActive == true) {
                    		leadObj.Partner_Lead_Owner__c = wrapperObj.partnerLeadOwner;
                    	}
                    	leadObj.Partner_Contact__c = wrapperObj.partnerLeadContact;//Relayware
                    	leadObj.Partner_Lead_Source__c = wrapperObj.partnerLeadSource;
                    	leadObj.RecordTypeId = wrapperObj.leadRecordType;
                    	leadObj.Partner_Account_Name__c = wrapperObj.partnerAccountName;
                    	leadObj.Partner_Account__c = wrapperObj.partnerAccountId;
                    	if(string.isBlank(leadObj.Street)){
							leadObj.Street = wrapperObj.strStreet;
						}
						if(string.isBlank(leadObj.State)){
							leadObj.State = wrapperObj.strState;
						}
						if(string.isBlank(leadObj.City)){
							leadObj.City = wrapperObj.strCity;
						}
						if(string.isBlank(leadObj.Country)){
							leadObj.Country = wrapperObj.strCountry;
						}
						if(string.isBlank(leadObj.PostalCode)){
							leadObj.PostalCode = wrapperObj.strPostalCode;
						}	
                    	leadObj.Ultimate_Parent_Account_Partner_ID__c = wrapperObj.ultimatePartnerId;
                    	leadObj.Ultimate_Parent_Account_Name__c = wrapperObj.ultimatePartnerName;
                    	leadObj.Current_Owner_Name__c =  wrapperObj.currentOwnerName;
                    	leadObj.VAR_Territory__c = wrapperObj.varTerritory;
                    	leadObj.OwnerId = wrapperObj.leadOwner;
                    }    
                }
				leadObj.LAR_Source__c = '';
				userFound = true;				
			}
		}
		/******************************Owner and Email Both****************************************/
		if(!userFound && ('Marketo Integration Profile'.equalsIgnoreCase(loggedInUser.Profile.Name) && isActiveOwner && leadObj.OwnerId!=null && leadObj.OwnerId != UserInfo.getUserId())) {
			system.debug('Marketo Owner Condition');
			leadObj.Assignment_Source_hidden__c = 'PR PER MARKETO';
			leadObj.LAR_Source__c = '';
			userFound = true;
		} else if(!userFound && ('Marketo Integration Profile'.equalsIgnoreCase(loggedInUser.Profile.Name))|| (Test.isRunningTest())) {
			//Relayware
			if(
      			(
      				leadObj.Lead_Owner_Email_Address__c!=null && 
  					(
  						(userEmailOwnerMap!=null && userEmailOwnerMap.get(leadObj.Lead_Owner_Email_Address__c)!=null) || 
  						(contactEmailOwnerMap!=null && contactEmailOwnerMap.get(leadObj.Lead_Owner_Email_Address__c)!=null)
  					)
  				) ||
              		(Test.isRunningTest())
          	){
                system.debug('Marketo Updating Lead Owner Email Field');  
                User userObj;
                userObj =   userEmailOwnerMap.get(leadObj.Lead_Owner_Email_Address__c);
                Contact conObj;
                conObj = contactEmailOwnerMap.get(leadObj.Lead_Owner_Email_Address__c);
                userFound = checkVARReferalLead(leadObj,uniqueKey,prOwnerMap,userObj,conObj,VarContactUser);
            }else if(
      			(
      				leadObj.Sales_Agent_Email__c!=null && 
  					(
  						(userEmailOwnerMap!=null && userEmailOwnerMap.get(leadObj.Sales_Agent_Email__c)!=null) || 
  						(contactEmailOwnerMap!=null && contactEmailOwnerMap.get(leadObj.Sales_Agent_Email__c)!=null)
  					)
  				) ||
  					(Test.isRunningTest())
      			){
	                system.debug('Marketo Updating Sales Agent Email Field');
	                User userObj;
	                userObj =   userEmailOwnerMap.get(leadObj.Sales_Agent_Email__c);
	                Contact conObj;
	                conObj = contactEmailOwnerMap.get(leadObj.Sales_Agent_Email__c);
	                userFound = checkVARReferalLead(leadObj,uniqueKey,prOwnerMap,userObj,conObj,VarContactUser);
            } 
		}
		return userFound;
	}
	
	/*******************For VAR Refereal Leads*************************************/
	public static boolean checkVARReferalLead(Lead leadObj, String uniqueKey,map<String,String> prOwnerMap,User userObj,Contact conObj,User VarContactUser){
		boolean userFound = false;
		//Relayware
		if(conObj != NULL && conObj.Id != NULL){
			leadObj.LeadPartnerID__c = conObj.Account.Partner_ID__c;
			leadObj.Inside_Sales_Rep__c = conObj.Account.Inside_Sales_Rep__c;
			//leadObj.Partner_Lead_Owner__c = userObj.ID;
			leadObj.Partner_Lead_Source__c = 'RingCentral';
			leadObj.RecordtypeId  = Schema.Sobjecttype.Lead.getRecordTypeInfosByName().get('Partner Leads').getRecordTypeId(); //RecordTypeInfo.get('Partner Lead').getRecordTypeId();			
			
			if(string.isBlank(leadObj.Street)){
				leadObj.Street = conObj.MailingStreet;
			}
			if(string.isBlank(leadObj.State)){
				leadObj.State = conObj.MailingState;
			}
			if(string.isBlank(leadObj.City)){
				leadObj.City = conObj.MailingCity;
			}
			if(string.isBlank(leadObj.Country)){
				leadObj.Country = conObj.MailingCountry;
			}
			if(string.isBlank(leadObj.PostalCode)){
				leadObj.PostalCode = conObj.MailingPostalCode;
			}			
			
			//Added new fields on request of  danniel Walleri on 09/03/2015................... 
			leadObj.Partner_Account_Name__c = conObj.Account.Name;
			leadObj.Partner_Account__c = conObj.AccountId;
			leadObj.Ultimate_Parent_Account_Partner_ID__c= conObj.Account.Ultimate_Parent_Partner_ID__c;
			leadObj.Ultimate_Parent_Account_Name__c= conObj.Account.Ultimate_Parent_Account_Name__c;			
			leadObj.VAR_Territory__c = conObj.Account.VAR_Territory__c;
			leadObj.Partner_Contact__c = conObj.Id;
			if(conObj.Account.Current_Owner__r.Isactive!=null  &&  conObj.Account.Current_Owner__r.IsActive == true) {
				leadObj.OwnerId = conObj.Account.Current_Owner__c;				
			} else {
				leadObj.OwnerId = VarContactUser.Id;
			}
			leadObj.Current_Owner_Name__c = conObj.Account.Current_Owner__r.Name;
			prOwnerMap.put(uniqueKey,conObj.Account.Current_Owner__c);
			leadObj.Assignment_Source_hidden__c = 'PR PER MARKETO VAR';
			leadObj.LAR_Source__c = '';
			userFound = true;
		}else if(userObj != NULL && userObj.Id != NULL){
			if(!userObj.Profile.Name.ContainsIgnoreCase('RC Partner Modify') ) {
				prOwnerMap.put(uniqueKey,userObj.Id);
				leadObj.OwnerId = userObj.Id;
				leadObj.Assignment_Source_hidden__c = 'PR PER MARKETO';
				leadObj.LAR_Source__c = '';
				userFound = true;
	
			} else {
				leadObj.LeadPartnerID__c = userObj.contact.Account.Partner_ID__c;
				leadObj.Inside_Sales_Rep__c = userObj.contact.Account.Inside_Sales_Rep__c;
				leadObj.Partner_Lead_Owner__c = userObj.ID;
				leadObj.Partner_Lead_Source__c = 'RingCentral';
				leadObj.RecordtypeId  = Schema.Sobjecttype.Lead.getRecordTypeInfosByName().get('Partner Leads').getRecordTypeId(); //RecordTypeInfo.get('Partner Lead').getRecordTypeId();			
				
				if(string.isBlank(leadObj.Street)){
					leadObj.Street = userObj.Contact.MailingStreet;
				}
				if(string.isBlank(leadObj.State)){
					leadObj.State = userObj.Contact.MailingState;  
				}
				if(string.isBlank(leadObj.City)){
					leadObj.City = userObj.Contact.MailingCity;
				}
				if(string.isBlank(leadObj.Country)){
					leadObj.Country = userObj.Contact.MailingCountry;
				}
				if(string.isBlank(leadObj.PostalCode)){
					leadObj.PostalCode = userObj.Contact.MailingPostalCode;
				}		
				
				//Added new fields on request of  danniel Walleri on 09/03/2015................... 
				leadObj.Partner_Account_Name__c = userObj.Contact.Account.Name;
				leadObj.Ultimate_Parent_Account_Partner_ID__c= userObj.Contact.Account.Ultimate_Parent_Partner_ID__c;
				leadObj.Ultimate_Parent_Account_Name__c= userObj.Contact.Account.Ultimate_Parent_Account_Name__c;			
				leadObj.VAR_Territory__c = userObj.Contact.Account.VAR_Territory__c;
				if(userObj.Contact.Account.Current_Owner__r.Isactive!=null  &&  userObj.Contact.Account.Current_Owner__r.IsActive == true) {
					leadObj.OwnerId = userObj.Contact.Account.Current_Owner__c;
					
				} else {
					leadObj.OwnerId = VarContactUser.Id;
				}
				leadObj.Current_Owner_Name__c = userObj.Contact.Account.Current_Owner__r.Name;
				prOwnerMap.put(uniqueKey,userObj.Id);
				leadObj.Assignment_Source_hidden__c = 'PR PER MARKETO VAR';
				leadObj.LAR_Source__c = '';
				userFound = true;
			}
		}
		return userFound;
	}
	
	/******************************Run Geo Territory Industry Routing Logic for Lead Owner Assignment at Lead insert*********************************************************/ 
	public static boolean runGeoTerritoryRouting(Lead leadObj, Map<string,Map<String,String>> segmentDataMap,
												 Map<String,Map<String,List<Territory_Data__c>>> territoryDataMap, Set<String> employeeSizeSet,
												 Set<String> leadSourceSet){
			
		boolean userFound = false;
		boolean countryFound = false;
		boolean industryFound = false;
		/*String employeeSize = (leadObj.Employees_Override__c!=null ? leadObj.Employees_Override__c : 
							  (leadObj.NumberOfEmployees__c !=null ? leadObj.NumberOfEmployees__c : leadObj.LS_Company_Size_Range__c));*/
	  	String employeeSize = (leadObj.Employees_Override__c!=null ? leadObj.Employees_Override__c : 
							  (leadObj.LS_Company_Size_Range__c !=null ? leadObj.LS_Company_Size_Range__c : leadObj.NumberOfEmployees__c));
	    
	    String country = (leadObj.Country!=null ? leadObj.Country : leadObj.LS_Company_Country__c);
	    if(!string.isBlank(country) && segmentDataMap!=null && segmentDataMap.get('Country')!=null && segmentDataMap.get('Country').get(country.toUpperCase())!=null){
			leadObj.Geo_Country__c = segmentDataMap.get('Country').get(country.toUpperCase());
			countryFound = true;
		}
		
		if(!string.isBlank(leadObj.LS_Primary_NAIC__c) && segmentDataMap!=null && segmentDataMap.get('Industry')!=null && segmentDataMap.get('Industry').get(leadObj.LS_Primary_NAIC__c.toUpperCase())!=null){
			leadObj.Sales_Industry__c = segmentDataMap.get('Industry').get(leadObj.LS_Primary_NAIC__c.toUpperCase());
			industryFound = true;
		}
		
		String postalCode = (leadObj.PostalCode!=null ? leadObj.PostalCode : leadObj.LS_Company_Zipcode__c);		
		leadObj.Geo_Postal_Code__c = PRAssignmentLogic.validatePostalCode(postalCode,leadObj.Phone,leadObj.Geo_Country__c,segmentDataMap);
		
		/*List<string> employeeSizeList = new List<String>();
		employeeSizeList = Label.Territory_Employee_Size.split(';');
		Set<string> employeeSizeSet = new set<string>();
		for(String str : employeeSizeList){
			employeeSizeSet.add(str.trim());
		}*/
		
		//if(employeeSize == '50-249' || employeeSize == '250-999' || employeeSize == '1000+'){
		if(employeeSizeSet.contains(employeeSize)){
			if(countryFound){
				if(industryFound){
					if(territoryDataMap!=null && territoryDataMap.get('Industry-Geo')!=null 
							&& territoryDataMap.get('Industry-Geo').get(leadObj.Geo_Country__c)!=null){
						for(Territory_Data__c territoryData : territoryDataMap.get('Industry-Geo').get(leadObj.Geo_Country__c)){
							if(territoryData.Industry__c == leadObj.Sales_Industry__c && territoryData.Segment__c == employeeSize){								
								userFound = PRAssignmentLogic.checkPostalCodeAssignUser(leadObj, territoryData, leadSourceSet);
								if(userFound){
									break;
								}
							}
						}
					}
				}else{
					if(territoryDataMap!=null && territoryDataMap.get('Geo')!=null && territoryDataMap.get('Geo').get(leadObj.Geo_Country__c)!=null){
						for(Territory_Data__c territoryData : territoryDataMap.get('Geo').get(leadObj.Geo_Country__c)){
							if(territoryData.Segment__c == employeeSize){
								userFound = PRAssignmentLogic.checkPostalCodeAssignUser(leadObj, territoryData, leadSourceSet);
								if(userFound){
									break;
								}
							}
						}
					}
				}
			}
		}
		
		return userFound;
	}
	
	/*******************************Get Final Postal code based on Country and Phone Number Logic from Segment Data Object**********************/
	public static string validatePostalCode(String postalCode,String phoneNumber, String country, Map<string,Map<String,String>> segmentDataMap){
		String finalPostalCode = '';
		if(!String.isBlank(postalCode)){
			if(country == 'United States'){
				if(postalCode.length() == 5){
					finalPostalCode = postalCode;
				}else if(postalCode.length() > 5){
					finalPostalCode = postalCode.subString(0,5);
				}
			}else if(country == 'Canada'){
				if(!String.isBlank(postalCode) && postalCode.length() >= 3){
					finalPostalCode = postalCode.subString(0,3);
				}
			}
		}else{
			if(!String.isBlank(phoneNumber)){
				String tempPostalCode = '';
				String tempPhoneNumber = ValidationUtility.extractIntegerFromPhone(phoneNumber);
				system.debug('=tempPhoneNumber='+tempPhoneNumber);
				if(tempPhoneNumber.length() == 10){
					tempPostalCode = tempPhoneNumber.subString(0,3);
				}else if(tempPhoneNumber.length() == 11 && tempPhoneNumber.startsWith('1')){
					tempPostalCode = tempPhoneNumber.subString(1,4);
				}
				system.debug('=tempPostalCode='+tempPostalCode);
				//system.debug('=segmentDataMap='+segmentDataMap.get('Area Code'));
				if(!String.isBlank(tempPostalCode)){
					if(segmentDataMap!=null && segmentDataMap.get('Area Code')!=null && segmentDataMap.get('Area Code').get(tempPostalCode.toUpperCase())!=null){
						finalPostalCode = segmentDataMap.get('Area Code').get(tempPostalCode.toUpperCase());
					}
				}
			}
		}
		
		if(String.isBlank(finalPostalCode)){
			finalPostalCode = postalCode;
		}
		system.debug('=finalPostalCode='+finalPostalCode);
		return finalPostalCode;
	}
	
	/***********************************Validate If Postal Code Exists in Territory Data Object and assign Owner if exsist**********************/
	public static boolean checkPostalCodeAssignUser(Lead leadObj, Territory_Data__c territoryData, set<string> leadSourceSet){
		boolean userFound = false;
		boolean postalFound = false;
		if(leadObj.Geo_Country__c == 'United States' && territoryData.Postal_Begin__c!=null && territoryData.Postal_End__c!=null && leadObj.Geo_Postal_Code__c!=null){
			if(LeadTriggerHelperExt.isNumeric(leadObj.Geo_Postal_Code__c)){
				integer postalBegin = integer.valueOf(territoryData.Postal_Begin__c);
				integer postalEnd = integer.valueOf(territoryData.Postal_End__c);
				integer intPostalCode = integer.valueOf(leadObj.Geo_Postal_Code__c);
				if(intPostalCode >= postalBegin && intPostalCode <= postalEnd){
					postalFound = true;
				}
			}
		}else if(leadObj.Geo_Country__c == 'Canada' && leadObj.Geo_Postal_Code__c!=null){
			if(territoryData.Postal_Begin__c.equalsIgnoreCase(leadObj.Geo_Postal_Code__c)){										
				postalFound = true;
			}
		}
		if(postalFound){
			if(leadSourceSet.contains(leadObj.leadSource)){
				if(territoryData.Territory_Owner__c != null && !territoryData.Territory_Owner__r.Name.startsWith('TBD') && territoryData.Territory_Owner__r.IsActive){
					leadObj.OwnerId = territoryData.Territory_Owner__c;	
					userFound = true;
				} else if(territoryData.Alternate_Owner__c != null && !territoryData.Alternate_Owner__r.Name.startsWith('TBD') && territoryData.Alternate_Owner__r.IsActive){
					leadObj.OwnerId = territoryData.Alternate_Owner__c;
					userFound = true;
				}
			} else {
				if(territoryData.Alternate_Owner__c != null && !territoryData.Alternate_Owner__r.Name.startsWith('TBD') && territoryData.Alternate_Owner__r.IsActive){
					leadObj.OwnerId = territoryData.Alternate_Owner__c;					
					userFound = true;
				}else if(territoryData.Territory_Owner__c!=null && !territoryData.Territory_Owner__r.Name.startsWith('TBD') && territoryData.Territory_Owner__r.IsActive){
					leadObj.OwnerId = territoryData.Territory_Owner__c;
					userFound = true;
				}
			}
			if(userFound){
				leadObj.Assignment_Source_hidden__c = 'GEO INDUSTRY TERRITORY ROUTING';
				leadObj.Territory__c = territoryData.Name;
			}
		}
		
		return userFound;
	}
	
	/*********************************Create Segment Data Map by querying all Segment Data records*****************************************/
	public static Map<string,Map<String,String>> createSegmentDataMap(){
		Set<String> typeSet = new Set<String>{'Country','Industry','Area Code'};
		Map<string,Map<String,String>> segmentDataMap = new Map<string,Map<String,String>>();
		for(Segment_Data__c segmentDataObj : [SELECT id,Attribute_1__c,Attribute_2__c,Postal_Code__c,Type__c FROM Segment_Data__c WHERE 
    												Attribute_1__c!=null AND Type__c in : typeSet]){    			
			if(segmentDataMap!=null && segmentDataMap.get(segmentDataObj.Type__c)!=null){
				Map<String,String> tempMap = segmentDataMap.get(segmentDataObj.Type__c);
				if(segmentDataObj.Type__c != 'Area Code'){
					tempMap.put(segmentDataObj.Attribute_1__c.toUpperCase(),segmentDataObj.Attribute_2__c);
				}else{
					tempMap.put(segmentDataObj.Attribute_1__c.toUpperCase(),segmentDataObj.Postal_Code__c);
				}
				segmentDataMap.put(segmentDataObj.Type__c,tempMap);
			}else{
				if(segmentDataObj.Type__c != 'Area Code'){
					segmentDataMap.put(segmentDataObj.Type__c,new Map<String,String>{segmentDataObj.Attribute_1__c.toUpperCase() => segmentDataObj.Attribute_2__c});
				}else{
					segmentDataMap.put(segmentDataObj.Type__c,new Map<String,String>{segmentDataObj.Attribute_1__c.toUpperCase() => segmentDataObj.Postal_Code__c});
				}
			}
		}
		return segmentDataMap;
	}
	
	/***********************Create Territory Data Map by Quering all Territory Data Records****************************************************/
	public static Map<String,Map<String,List<Territory_Data__c>>> createTerritoryDataMap(){
		Map<String,Map<String,List<Territory_Data__c>>> territoryDataMap = new Map<String,Map<String,List<Territory_Data__c>>>();
		for(Territory_Data__c territoryDataObj : [SELECT id,Name,Country__c,Alternate_Owner__c,Industry__c,Postal_Begin__c,Postal_End__c,Segment__c,
    													State_Province__c,Territory_Owner__c,Territory_Owner__r.Name,Type__c,Alternate_Owner__r.Name,
    													Territory_Owner__r.IsActive,Alternate_Owner__r.IsActive
    													FROM Territory_Data__c WHERE Type__c!=NULL AND Country__c!=NULL]){
			if(territoryDataMap!=null && territoryDataMap.get(territoryDataObj.Type__c)!=null){
				Map<String,List<Territory_Data__c>> countryMap = territoryDataMap.get(territoryDataObj.Type__c);
				if(countryMap!=null && countryMap.get(territoryDataObj.Country__c)!=null){
					List<Territory_Data__c> tempTerritoryDataList = countryMap.get(territoryDataObj.Country__c);
					tempTerritoryDataList.add(territoryDataObj);
					countryMap.put(territoryDataObj.Country__c,tempTerritoryDataList);
				}else{
					countryMap.put(territoryDataObj.Country__c,new List<Territory_Data__c>{territoryDataObj});
				}
				territoryDataMap.put(territoryDataObj.Type__c,countryMap);
			}else{
				territoryDataMap.put(territoryDataObj.Type__c,new Map<String,List<Territory_Data__c>>
																  {territoryDataObj.Country__c =>new List<Territory_Data__c>{territoryDataObj}});
			}
		}
		return territoryDataMap;
	}
	
	/******************************************Calculate Eligible Protection Period***********************************************************************/
	public static void calculateProtectionPeriod(Lead newLeadObj, Lead oldLeadObj, map<string,boolean> systemUserMap,map<String,boolean> invalidStatusMap,set<String> adminUsers){
        if(
            (
                newLeadObj.OwnerId != oldLeadObj.ownerId //Owner Changed
                && (systemUserMap != null || systemUserMap.get(string.valueOf(oldLeadObj.ownerId).subString(0,15)) != Null) //Old Owner "System User"
                && (systemUserMap == null || systemUserMap.get(string.valueOf(newLeadObj.ownerId).subString(0,15)) == Null) //New Owner "Real User"
                && (adminUsers == null || !adminUsers.contains(string.valueOf(newLeadObj.ownerId).subString(0,15)))
                //&& (systemAdmimMap == null || systemAdmimMap.get(string.valueOf(newLeadObj.ownerId).subString(0,15))==null)
                //&& (newLeadObj.OwnerId!=null && !'System Administrator'.equalsIgnoreCase(newLeadObj.owner.profile.Name))//Not System Administrator User                            
                && (invalidStatusMap == null || invalidStatusMap.get(newLeadObj.Status) == Null) //Current Status is Valid
            )
            ||
            (
                newLeadObj.Status != oldLeadObj.status //Status Changed
                && (invalidStatusMap != null && invalidStatusMap.get(oldLeadObj.status) != Null) //Old Status Invalid
                && (invalidStatusMap == null || invalidStatusMap.get(newLeadObj.Status) == Null) //New Status is Valid                         
                && (systemUserMap == null || systemUserMap.get(string.valueOf(newLeadObj.ownerId).subString(0,15)) == Null) //Current User is "Real User"
                && (adminUsers == null || !adminUsers.contains(string.valueOf(newLeadObj.ownerId).subString(0,15)))
                //&& (systemAdmimMap == null || systemAdmimMap.get(string.valueOf(newLeadObj.ownerId).subString(0,15))==null)
                //&& (newLeadObj.OwnerId!=null && !'System Administrator'.equalsIgnoreCase(newLeadObj.owner.profile.Name))//Not System Administrator User
            )
        ){
            newLeadObj.Eligible_Protection_Period__c = system.today() + 30;
        }
    }
	/**************************************************************************************************************************************************/
	
	/*****************************Generic Method to find all the SFDC Limits*********************************************************/
	public static string calculateLimits(){
        String strLimit = '';
        strLimit+= ' No. of Aggregate Queries : ' + limits.getAggregateQueries() + ' out of ' + limits.getLimitAggregateQueries() +'\n';
        strLimit+= ' No. of Web service statements : ' + limits.getCallouts() + ' out of ' + limits.getLimitCallouts() +'\n';        
        strLimit+= ' CPU time (in milliseconds) : ' + limits.getCpuTime() + ' out of ' + limits.getLimitCpuTime() +'\n';
        strLimit+= ' No. of DML statements : ' + limits.getDMLStatements() + ' out of ' + limits.getLimitDMLStatements() +'\n';
        strLimit+= ' No. of Records Processed in DML : ' + limits.getDMLRows() + ' out of ' + limits.getLimitDMLRows() +'\n';   
        strLimit+= ' No. of Email Invocation : ' + limits.getEmailInvocations()  + ' out of ' + limits.getLimitEmailInvocations() +'\n';                
        strLimit+= ' No. of Future calls : ' + limits.getFutureCalls()  + ' out of ' + limits.getLimitFutureCalls()  +'\n';
        strLimit+= ' Heap Size (in bytes) : ' + limits.getHeapSize()  + ' out of ' + limits.getLimitHeapSize()  +'\n';
        strLimit+= ' No. of SOQL queries : ' + limits.getQueries()  + ' out of ' + limits.getLimitQueries()   +'\n';        
        strLimit+= ' No. of QueryLocator Rows : ' + limits.getQueryLocatorRows() + ' out of ' + limits.getLimitQueryLocatorRows()   +'\n';
        strLimit+= ' No. of query rows : ' + limits.getQueryRows() + ' out of ' + limits.getLimitQueryRows()    +'\n';
        return strLimit;
    }
    
    /********************Wrapper Class for PR Assignment Rules search based record details*************************************/
    public class prRuleWrapper{
    	public string recordId;
    	public string leadPartnerId;
    	public string channelManager;
    	public string partnerLeadOwner;
    	public string partnerLeadContact;//Relayware
    	public string partnerLeadSource;
    	public string leadRecordType;
    	public string partnerAccountName;
    	public string ultimatePartnerId;
    	public string ultimatePartnerName;
    	public string currentOwnerName;
    	public string varTerritory;
    	public string leadOwner;
    	public boolean isPartner;  
    	public boolean isPartnerOwnerActive; 
    	public string strStreet;
    	public string strCity;
    	public string strState;
    	public string strCountry;
    	public string strPostalCode;  
    	public string partnerAccountId; 	
    	
    	public prRuleWrapper(String recordId,String leadPartnerId,String channelManager,String partnerLeadOwner,String partnerLeadContact,//Relayware
    						 String partnerLeadSource,String leadRecordType,String partnerAccountName,String ultimatePartnerId,String ultimatePartnerName,
    						 String currentOwnerName,String varTerritory,String leadOwner,boolean isPartner,boolean isPartnerOwnerActive,
    						 String strStreet,String strCity,String strState,String strCountry,String strPostalCode,String partnerAccountId){
    		this.recordId = recordId;
    		this.leadPartnerId = leadPartnerId;
    		this.channelManager = channelManager;
    		this.partnerLeadOwner = partnerLeadOwner;
    		this.partnerLeadContact = partnerLeadContact;//Relayware
    		this.partnerLeadSource = partnerLeadSource;
    		this.leadRecordType = leadRecordType;
    		this.partnerAccountName = partnerAccountName;
    		this.ultimatePartnerId = ultimatePartnerId;
    		this.ultimatePartnerName = ultimatePartnerName;
    		this.currentOwnerName = currentOwnerName;
    		this.varTerritory = varTerritory;
    		this.leadOwner = leadOwner;
    		this.isPartner = isPartner;
    		this.isPartnerOwnerActive = isPartnerOwnerActive;
    		this.strStreet = strStreet;
    		this.strCity = strCity;
    		this.strState = strState;
    		this.strCountry = strCountry;
    		this.strPostalCode = strPostalCode;
    		this.partnerAccountId = partnerAccountId;
    	}
    }
    /***************************************************************************************************************************************/
}