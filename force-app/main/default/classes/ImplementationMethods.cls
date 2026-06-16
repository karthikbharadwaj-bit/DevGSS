/*************************************************
ImplementationMethods class
This Class is used by Account.trigger.
allowImplementation determinds if the accounts campaign wants an implementation to be created.
createImplementations actually creates an implementation with the information provided.
/************************************************/

public with sharing class ImplementationMethods {

	public static final string IMPLEMENTATION_STATUS2_NEW = 'New';
	public static final string IMPLEMENTATION_STATUS2_SCHEDULED = 'Scheduled';
	public static final string IMPLEMENTATION_STATUS2_CONTACTED = 'Contacted';
	public static final string IMPLEMENTATION_STATUS2_WIP = 'Work In Progress';
    public static final integer SERVICE_ACCOUNT_LICENSES_PURCHASED_COUNT = 9;

    public static final Set<String> ACCOUNT_STATUSES_ACTIVE = new Set<String>{
        'Paid', 'Trial (other)', 'Trial 15 CC', 'Trial 30 CC', '30-Day Office Trial','Trial 30 CC','Trial 30 no-CC'
    };
    public static final Set<String> ACCOUNT_STATUSES_ACTIVE_AND_POC = new Set<String>{
        'Paid', 'Trial (other)', 'Trial 15 CC', 'Trial 30 CC', 'Trial 30 no-CC','PoC', 'Test'
    };

	public static final Set<String> RC_BRANDS = new Set<String>{
        OpportunityHelper.BRAND_RINGCENTRAL_EU,
        OpportunityHelper.BRAND_RINGCENTRAL_UK,
        OpportunityHelper.BRAND_RINGCENTRAL_AU
    };
	// ATT Implementation Creation
     public static final Set<String> attBrand = new Set<String>{
        'AT&T Office@Hand'
    };
       // ATT Implementation Creation

	public static final Set<String> SHORT_BRANDS_LESS_100_DLS = new Set<String>{
		'Vodafone Business with RingCentral', 'RingCentral mit 1&1 Connected Calls', 'Charter'
	};

	public static final Set<String> BRANDS_LESS_100_DLS = new Set<String>{
		'Frontier plus RingCentral',
		'Frontier with RingCentral',
		'Eastlink',
		OpportunityHelper.BRAND_BT_BUSINESS,
		OpportunityHelper.BRAND_TELUS_BUSINESS_CONNECT,
		OpportunityHelper.BRAND_ATOS,
		OpportunityHelper.BRAND_RAINBOW
	};
        
	public static Map<String, Rise_Partner_CRM_Configuration__c> risePartnerSettings = new Map<String, Rise_Partner_CRM_Configuration__c>();

	//Method added for PRM-111, to be called from batch and future calls.
	public static void createImplementations(Set<Id> accIds) {
		createImplementationsOnAccSync(accIds);
	}

	@future
    public static void createImplementationsAsync(Set<Id> accIds) {
		createImplementationsOnAccSync(accIds);
	}

    public static void createImplementationsOnAccSync(Set<Id> accIds) {
        Map<Id, Implementation__c> accountImplementationMap =  new Map<Id, Implementation__c>();
        Map<Id, List<Implementation__c>> implementations = AccountTriggerHelper.getImplementations(accIds);
        Map<Id, Integer> premiumImpAccMap = premiumAccountToOppMap(accIds);
        Map<Id, Account> accounts = new Map<Id, Account>([
            SELECT Id, Name, RC_Tier__c, RC_Signup_Date__c, RC_Brand__c, RC_User_Id__c,
                RC_Account_Status__c, RC_Service_Name__c,Number_of_DL_s__c, Purchased_DL_s__c, Do_Not_Creation_Implementation__c, RC_Signup_Funnel__c,Sub_brand__c,
				(SELECT Account__c, RC_Signup_Funnel__c, Service_Type__c, CreatedDate FROM Service_Accounts__r)
            FROM Account
            WHERE Id IN :accIds
        ]);

		risePartnerSettings = Rise_Partner_CRM_Configuration__c.getAll();

        for (Account acc : accounts.values()) {

            if (!implementations.get(acc.Id).isEmpty() || String.isBlank(acc.RC_Brand__c) || String.isBlank(acc.RC_User_Id__c)) {
                continue;
            }
            final String implementationType = (String.isNotBlank(acc.RC_Account_Status__c) && acc.RC_Account_Status__c.containsIgnoreCase(AccountHelper.ACCOUNT_STATUS_TRIAL))
                ? 'Trial Account'
                : (premiumImpAccMap != null && premiumImpAccMap.get(acc.Id)!= null && premiumImpAccMap.get(acc.Id) > 0)
                    ? 'Premium'
                    : '';

            if (toCreateImplementationOnInsOrUpdRing(acc)) {

                accountImplementationMap.put(
                    acc.Id,
                    new Implementation__c(Type__c = 'New', Implementation_Type__c = implementationType)
                );
            } else if (tocreateImplemetationOnInsOrUpdForBrandsLess100Dls(acc)) {

                accountImplementationMap.put(
                    acc.Id,
                    new Implementation__c(Type__c = 'New', Implementation_Type__c = implementationType)
                );
            }
        }
        createAccountImplementation(accountImplementationMap, accounts, getContactAccountMap(accounts));
    }

    public static Boolean isImplConditionChanged(Account acc, Account oldAccount) {
        return acc.RC_Account_Status__c != oldAccount.RC_Account_Status__c
				|| acc.Purchased_DL_s__c != oldAccount.Purchased_DL_s__c
				|| acc.Do_Not_Creation_Implementation__c != oldAccount.Do_Not_Creation_Implementation__c
            	|| acc.RC_Signup_Date__c != oldAccount.RC_Signup_Date__c
             	|| (acc.RC_User_Id__c != oldAccount.RC_User_Id__c && String.isNotBlank(acc.RC_User_Id__c))
				|| acc.RC_Brand__c != oldAccount.RC_Brand__c
                || acc.RC_Service_name__c != oldAccount.RC_Service_name__c
				|| acc.Sub_Brand__c != oldAccount.Sub_Brand__c;
    }

    public static Boolean toCreateImplementationOnInsOrUpdRing(Account acc) {
        final Decimal newDL = NumberHelper.toNumber(acc.Purchased_DL_s__c);
		final Decimal numberDL = NumberHelper.toNumber(acc.Number_of_DL_s__c);
        if (!acc.Do_Not_Creation_Implementation__c
			&& RC_BRANDS.contains(acc.RC_Brand__c)
            && ACCOUNT_STATUSES_ACTIVE.contains(acc.RC_Account_Status__c)
            && newDL >= 2 && newDL <= 99
		) {
                return true;
        }
		// ATT Implementation creation condition check
		else if (String.valueOf(acc.Number_of_DL_s__c) != null && numberDL < 100 && attBrand.contains(acc.RC_Brand__c) && ACCOUNT_STATUSES_ACTIVE.contains(acc.RC_Account_Status__c)){
							   return true;
	 }
        return false;
    }

    public static boolean tocreateImplemetationOnInsOrUpdForBrandsLess100Dls(Account acc) {
        Boolean isEqualBrand = BRANDS_LESS_100_DLS.contains(acc.RC_Brand__c);
        Rise_Partner_CRM_Configuration__c riseBrandConfig = new Rise_Partner_CRM_Configuration__c();
        Boolean isRiseAcct = false;

        isRiseAcct = risePartnerSettings.containsKey(acc.Sub_brand__c);
        if (isRiseAcct) {
            riseBrandConfig = risePartnerSettings.get(acc.Sub_brand__c);
        }

        for (String brandName : SHORT_BRANDS_LESS_100_DLS) {
            if (acc.RC_Brand__c.containsIgnoreCase(brandName)) {
                isEqualBrand = true;
            }
        }
        final Decimal newDL = NumberHelper.toNumber(acc.Purchased_DL_s__c);
        if (isEqualBrand && newDL < 100 && acc.RC_Account_Status__c == AccountHelper.PAID_STATUS) {
            return true;
        } else if (isRiseAcct && newDL <= riseBrandConfig.Max_Purchase_DL__c && acc.RC_Account_Status__c == riseBrandConfig.Account_Status__c && riseBrandConfig.Implementation_Required__c ==true) {
            return true;
        }
        return false;
    }

	// Account Status = "30-Day Office Trial"
	public boolean toCreateImplementationOnInsOrUpdOfficeTrials(Account newAccount,Map<String,Integer> mapAccountImplementation1) {
		if((!String.isBlank(newAccount.RC_Account_Status__c)
				&& newAccount.RC_Account_Status__c.trim().equalsIgnoreCase('30-Day Office Trial'))
				&& (0 == (mapAccountImplementation1.get(newAccount.Id)== null? 0: mapAccountImplementation1.get(newAccount.Id)))
			)
				{
			return true;
		}
		return false;
	}

	/***********************VAR Survey on Account Activation *********************************/

	public map<string,Account> getPartnerAccountContactMap(List<Account> accountList) {
		map<string,Account> partneraccountMap = new map<string,Account>();
		try {
			Set<string> partnerIdSet = new set<string>();
			for(Account accobj:accountList) {
				if(accobj.Partner_ID__c != null) {
					partnerIdSet.add(accobj.Partner_ID__c);
				}
			}
			if(partnerIdSet != null && partnerIdSet.size()>0) {
				for(Account accObj : [select Partner_ID__c,(select Id,email from contacts) from account
										where Partner_ID__c IN :partnerIdSet and RecordType.Name = 'Partner Account']) {					// type = 'Partner'
				 	partneraccountMap.put(accObj.Partner_ID__c,accObj);
				}
			}
		} catch(Exception ex) {}
		return partneraccountMap;
	}

	public Survey__c createVARSurveyOnAccountActivation(Account accObj,Map<Id,Account> accountMap,list<Contact> contactPartnerList) {
		try {
			Survey__c survObj = new Survey__c();
      		survObj.SurveyType__c = 'VAR Customer';
      		survObj.Account__c = accObj.Id;
      		survObj.Agent__c = accObj.OwnerId;
			survObj.Agent_Email__c = accountMap.get(accObj.id).Owner.Email;
			system.debug('accountMap.get(accObj.id).Owner.Email '+accountMap.get(accObj.id).Owner.Email);
			system.debug('accountMap.get(accObj.id).Owner.Name '+accountMap.get(accObj.id).Owner.Name);
			survObj.Agent_Name__c = accountMap.get(accObj.id).Owner.Name;
			survObj.Agent_Team__c = accountMap.get(accObj.id).Owner.Team__c;
			survObj.Agent_Manager_Name__c = accountMap.get(accObj.id).Owner.Manager.Name;
			survObj.Agent_Manager_Email__c = accountMap.get(accObj.id).Owner.Manager.Email;
			survObj.Name = 'VAR Customer' +' - ' + Datetime.now().format();
      		if(accountMap.get(accObj.id).AccountContactRoles != null &&
      				accountMap.get(accObj.id).AccountContactRoles.size()>0) {
      			AccountContactRole accountContactRoleObj = accountMap.get(accObj.id).AccountContactRoles;
      			if(contactPartnerList != null && contactPartnerList.size()>0) {
      				System.Debug('>>11>>');
      				if(!String.isBlank(accountContactRoleObj.Contact.Email)) {
      					string emaildomain = (accountContactRoleObj.Contact.Email).split('@')[1];
      					boolean domainMatches = false;
      					for(Contact contactObj : contactPartnerList) {
      						if(!string.isBlank(contactObj.email) && contactObj.email.split('@')[1] == emaildomain) {
      							domainMatches = true;
      							break;
      						}
      					}
      					if(!domainMatches) {
      						survObj.Contact__c = accountContactRoleObj.Contact.id;
							survObj.Contact_Email__c = accountContactRoleObj.Contact.Email;
							return survObj;
      					}
	      			}
      			}
      		}
      		if(accountMap.get(accObj.id).Contacts != null &&
      					accountMap.get(accObj.id).Contacts.size()>0) {
      			List<Contact> contList = accountMap.get(accObj.id).Contacts;
      			if(contactPartnerList != null && contactPartnerList.size()>0) {
      				System.Debug('>>22>>');
      				for(Contact contactObjAcc : contList) {
      					if(!string.isBlank(contactObjAcc.Email)) {
      						string emaildomain = (contactObjAcc.Email).split('@')[1];
      						System.Debug('>>23>>'+emaildomain);
      						boolean domainMatches = false;
      						for(Contact contactPartnerObj : contactPartnerList) {
	      						if(!string.isBlank(contactPartnerObj.email) && contactPartnerObj.email.split('@')[1] == emaildomain) {
	      							System.Debug('>>24>>'+ contactPartnerObj.email);
	      							domainMatches = true;
	      							break;
	      						}
      						}
      						if(!domainMatches) {
	      						survObj.Contact__c = contactObjAcc.id;
								survObj.Contact_Email__c = contactObjAcc.Email;
								return survObj;
      						}
      					}
      				}
      			}
      		}
   		} catch(Exception ex) {
   		}
		return null;
	}

	/***********************VAR Survey on Account Activation ********************************/
	/*
	allowImplementation takes an Account and using its attribution fields finds the matching campaign.
	It returns the value of the campaigns Create Implementations checkbox
	If no matching campaign is found then we return true to always create an implementation.
	*/

	public Map<Id,Boolean> allImplementationMap(List<Account> accountList) {
		Map<Id,Boolean> allImpMapRtn = new Map<Id,Boolean>();
		map<string,boolean> partnerIdTOAllImpMap = new  map<string,boolean>();
		try {
			set<Id> accountIdSet = new set<Id>();
			set<String> partnerIdSet = new set<string>();

			for(Account accObj : accountList) {
				accountIdSet.add(accObj.Id);
				if(accObj.Partner_ID__c != null && accObj.Partner_ID__c != '') {
					partnerIdSet.add(accObj.Partner_ID__c);
				}
			}

			List<Account> accListPartner = new List<Account>();
			if(partnerIdSet != null && partnerIdSet.size()>0) {
				RecordType rt = [SELECT Id FROM RecordType WHERE Name = 'Partner Account'];
				accListPartner = [select Id,Do_Not_Creation_Implementation__c,Partner_ID__c from Account
												where Partner_ID__c IN :partnerIdSet AND RecordTypeId =:rt.Id
												AND Do_Not_Creation_Implementation__c = true AND ID NOT IN :accountIdSet];
			}

			for(Account accObj : accListPartner) {
				System.Debug('>>4>>');
				partnerIdTOAllImpMap.put(accObj.Partner_ID__c,accObj.Do_Not_Creation_Implementation__c);
			}

			for(Account accObj : accountList) {
				if(partnerIdTOAllImpMap != null && partnerIdTOAllImpMap.size()>0 && accObj.Partner_ID__c != null && accObj.Partner_ID__c != '' &&
					partnerIdTOAllImpMap.containskey(accObj.Partner_ID__c)) {
					System.Debug('>>1>>');
					boolean allowImp = partnerIdTOAllImpMap.get(accObj.Partner_ID__c);
					if(allowImp == true) {
						allImpMapRtn.put(accObj.Id,false);
					} else if(allowImp == false) {
						allImpMapRtn.put(accObj.Id,true);
					}
				} else {
					System.Debug('>>2>>');
					allImpMapRtn.put(accObj.Id,true);
				}
			}
			accListPartner = null;
		} catch(Exception ex) {}
		return allImpMapRtn;
	}

	public static Map<Id, Integer> premiumAccountToOppMap(Set<Id> accountIds) {
		Map<Id, Integer> premiumImpAccMap = new Map<Id, Integer>();
		try {
			for(Account accObj: [Select (Select Is_Premium_Implementation_Required__c From Opportunities WHERE
								  Is_Premium_Implementation_Required__c=true AND StageName IN : OpportunityHelper.closedStagesSet AND
								  recordTypeId =: OpportunityHelper.getOppRecordTypeMap('Sales Opportunity')) From Account
		  						  WHERE Id IN: accountIds]) {
		  	  		premiumImpAccMap.put(accObj.id, accObj.Opportunities.size());
		  	}
		} catch(Exception e){}
		return premiumImpAccMap;
	}

	/*
		Created on June 14, 2011
		This method is used for reusablity of the lead assignment logic as per in Account And Contact_After Trigger
    	Here we used to set the lead object's data members on the basis of Account and Contact attributes.
    */
 	public Lead createLead(Account acct, Map<Id, Contact> contactMap, Lead newLead) {
    	Contact c = contactMap.get(acct.Id);
	 	if(c != null) {
	        newLead.Phone = c.Phone;
	        newLead.LastName = c.LastName;
	        newLead.FirstName = c.FirstName;
	        newLead.Email = c.Email;

	        //Populate additional field as mentioned in E-mail on 6/2/2011,while creating Lead
	        newLead.Account_Status__c = acct.RC_Account_Status__c;
	        newLead.Account_Number__c = acct.RC_Account_Number__c;
	        newLead.User_ID__c = acct.RC_User_ID__c;
	        newLead.Lead_Tier_Name__c = acct.RC_Tier__c;
	        newLead.RC_Service_name__c = acct.RC_Service_name__c;
	        newLead.Lead_Brand_Name__c = acct.RC_Brand__c;
	        // if the resultant email or last name is null or empty, need to fix it with temp values as fake@email.com and account name respectively.
	        //Below two fields are mandatory on Lead object, so need to provice some value is still unpopulated
	        newLead.Email = ( newLead.Email == null || newLead.Email.trim().length() == 0 ? 'fake@email.com' : newLead.Email );
	        newLead.LastName = ( newLead.LastName == null || newLead.LastName.trim().length() == 0 ? acct.Name : newLead.LastName );
	        newLead.Company = acct.Name;
	        newLead.Status = 'X. Open';
	        if(c.NumberOfEmployees__c != null){
				system.debug('@@@ c.NumberOfEmployees__c >>> '+c.NumberOfEmployees__c);
				newLead.NumberOfEmployees__c = c.NumberOfEmployees__c ;
			}else if(acct.No_of_Employees__c != null){
				system.debug('@@@ acct.No_of_Employees__c  >>> '+acct.No_of_Employees__c );
				newLead.NumberOfEmployees__c = acct.No_of_Employees__c;
			}
	    }
    	return newLead;
    }
	/************************* Canceled trials without hardware return *********************/
	public boolean chkToHardwareRtnOnDeactivation(Account accObjNew, Account accObjOld, Package__c pkg) {
		if(pkg != null && String.isNotBlank(pkg.Service_Type__c) && pkg.Service_Type__c.containsIgnoreCase('Office') &&
			accObjOld.RC_Account_Status__c != accObjNew.RC_Account_Status__c &&
			!string.isBlank(accObjOld.RC_Account_Status__c) && !string.isBlank(accObjNew.RC_Account_Status__c) &&
			(accObjOld.RC_Account_Status__c.equalsIgnoreCase('Trial 7 CC') || accObjOld.RC_Account_Status__c.equalsIgnoreCase('Trial 30 CC') ||
				 accObjOld.RC_Account_Status__c.equalsIgnoreCase('Trial 30 no-CC') || accObjOld.RC_Account_Status__c.equalsIgnoreCase('Trial (other)'))
			&& accObjNew.RC_Account_Status__c.equalsIgnoreCase('Disabled')) {
			return true;
		}
		return false;
	}
	/***************************************************************************************/


	// Optimised method for creating Account Implementation 9th April 2014.
	public static void createAccountImplementation(Map<Id, Implementation__c> accountImplementationMap, Map<Id, Account> accountMap,  Map<Id, Contact> contactMap){
		try{
			// below logic is changed to handle exception raised due to >80 length chars account name
			if(UserCustomSettingHelper.getRCSFSync(UserRC.rcsfSyncUserObj.name) !=null){

				List<Implementation__c>	bucketImplementaionList =  new List<Implementation__c>();
				Id rcsfPrimaryOwnerId = UserRC.getRCSFSyncPrimaryOwnerId;
				Id currentUserId = Userinfo.getUserId();
				//ATT record type get
                Id attRecordTypeId =Schema.SObjectType.Implementation__c.getRecordTypeInfosByName().get('Implementation - ATT').getRecordTypeId();
                Id nonAttRecordTypeId =Schema.SObjectType.Implementation__c.getRecordTypeInfosByName().get('Implementation').getRecordTypeId();

				for(Id accountId : accountImplementationMap.keySet()){
					Account thisAccount = accountMap.get(accountId);
					if(thisAccount != null) {
						String name = thisAccount.Name;
						String str = thisAccount.Name + ' - ' + Datetime.now().format();
						Integer strLength = (str).length();
						if(strLength > 80) {
							Integer dateLength = (' - ' +Datetime.now().format()).length();
							name = (thisAccount.Name).substring(0, (80-dateLength));
						}
						Implementation__c imp =  new Implementation__c();
						if(accountImplementationMap.get(thisAccount.Id) != null){
							imp = accountImplementationMap.get(thisAccount.Id);
						}
						imp.Name = name + ' - ' + Datetime.now().format();
						imp.office_service_change_date__c = Date.today();
						imp.Account__c = thisAccount.Id;
						imp.Brand__c = thisAccount.RC_Brand__c;
						imp.Sub_brand__c = thisAccount.Sub_brand__c;
						imp.Tier__c = thisAccount.RC_Tier__c;
						imp.Service__c = thisAccount.RC_Service_Name__c;
						//ATT Implementation record type update
                        if(thisAccount.RC_Brand__c=='AT&T Office@Hand'){
                            imp.RecordTypeId=attRecordTypeId;
                        }
                        else{
                            imp.RecordTypeId=nonAttRecordTypeId;
                        }

						//Owner assigment implemented to satisfy req. of case #06455352
						imp.OwnerId = (rcsfPrimaryOwnerId == null ? currentUserId : rcsfPrimaryOwnerId);

						imp.Account_Signup_Date__c = thisAccount.RC_Signup_Date__c;
						imp.Contact__c = (contactMap == null || contactMap.get(thisAccount.Id) == null ? null : contactMap.get(thisAccount.Id).Id);

						bucketImplementaionList.add(imp);
					}
				}
				// Flag for bypassing Trigger
				TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
				TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();

				if(bucketImplementaionList != null && !bucketImplementaionList.isEmpty()){
					insert bucketImplementaionList;
				}
			}
		} catch(Exception e) {
			System.debug('createAccountImplementation @ '+e.getlineNumber());
			System.debug('#### createAccountImplementation '+e.getMessage());
		}
	}

	// Optimised code to create Account Lead, 9th April 2014
	public Map<Id, Lead> createAccountLead( Map<Id, Lead> mapAccountLead, Map<Id, Account> mapAccount, Map<Id, Contact> contactMap){

		Map<Id, Lead> newAccountLeadMap =  new Map<Id, Lead>();
		try{
			for(Account thisAccount : mapAccount.values()){
				Lead newLead = new Lead();
				if(mapAccountLead.get(thisAccount.Id) != null){
					newLead = mapAccountLead.get(thisAccount.Id);
				}
				if(contactMap != null && !contactMap.isEmpty() && contactMap.containsKey(thisAccount.Id) && contactMap.get(thisAccount.Id) != null){
					Contact contactObj = contactMap.get(thisAccount.Id);
				 	if(contactObj != null) {
				        newLead.Phone = contactObj.Phone;
				        newLead.LastName = contactObj.LastName;
				        newLead.FirstName =contactObj.FirstName;
				        newLead.Email = contactObj.Email;

				        //Populate additional field as mentioned in E-mail on 6/2/2011,while creating Lead.
				        newLead.Account_Status__c = thisAccount.RC_Account_Status__c;
				        newLead.Account_Number__c = thisAccount.RC_Account_Number__c;
				        newLead.User_ID__c = thisAccount.RC_User_ID__c;
				        newLead.Lead_Tier_Name__c = thisAccount.RC_Tier__c;
				        newLead.RC_Service_name__c = thisAccount.RC_Service_name__c;
				        newLead.Lead_Brand_Name__c = thisAccount.RC_Brand__c;
				        if(contactObj.NumberOfEmployees__c != null){
							newLead.NumberOfEmployees__c = contactObj.NumberOfEmployees__c;
						}else if(contactObj.Account.No_of_Employees__c != null){
							newLead.NumberOfEmployees__c = contactObj.Account.No_of_Employees__c;
				        }
		        		/* If the resultant email or last name is null or empty,
		        		   need to fix it with temp values as fake@email.com and account name respectively.
		         		   Below two fields are mandatory on Lead object, so need to provice some value is still unpopulated */
				        newLead.Email = ( newLead.Email == null || newLead.Email.trim().length() == 0 ? 'fake@email.com' : newLead.Email );
				        newLead.LastName = ( newLead.LastName == null || newLead.LastName.trim().length() == 0 ? thisAccount.Name : newLead.LastName );
				        newLead.Company = thisAccount.Name;
				        newLead.Status = 'X. Open';
				    }
				    newAccountLeadMap.put(thisAccount.Id,newLead);
				}
			}
		}catch (Exception ex){
			System.debug('Error @ createAccountLead line -  '+ex.getlineNumber());
            System.debug('Error @ createAccountLead message - '+ex.getMessage());
		}
		return newAccountLeadMap;
	}

	public static Map<Id, Contact> getContactAccountMap(Map<Id, Account> accountMap) {
		Map<Id, Contact> contactMap = new Map<Id, Contact>();
		try {
			List<Account> selectedAccountsList = [SELECT Id,
													(SELECT Id, accountId, FirstName, LastName, Email, NumberOfEmployees__c,
															Phone,Account.No_of_Employees__c , Account.Name, isCustomer__c, Contact_Status__c,
                    										People_Segment__c, RCService_ContactStatus__c
													FROM Contacts
													ORDER BY CreatedDate DESC
													LIMIT 1)
												  FROM Account
												  WHERE Id in :accountMap.keySet()];
			for (Account currentAcc: selectedAccountsList) {
				for (Contact currentContact: currentAcc.Contacts) {
					contactMap.put(currentAcc.Id, currentContact);
				}
			}
		} catch(Exception e) {}
		return contactMap;
	}
}