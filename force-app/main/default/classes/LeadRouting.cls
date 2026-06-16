global class LeadRouting {

	public LeadRouting() {
	}


	public static List<Lead> PreprotectionRouting(List<Lead> leads, Map<String, Campaign> campaignMap){

		if( campaignMap == null || campaignMap.isEmpty() ) {
			campaignMap = LeadTriggerHelperExt.assignCampaigns(leads);
		}
		
		Map<String,Campaign_Subtype_Mapping__c> campaignSubTypeQueueMap = new Map<String,Campaign_Subtype_Mapping__c>();
		for(String campaignType : Campaign_Subtype_Mapping__c.getAll().keySet()){
			campaignSubTypeQueueMap.put(campaignType.toUpperCase(),Campaign_Subtype_Mapping__c.getAll().get(campaignType));
		}

		// B-1247
		List<Lead> leadsToRunSkillRouting = new List<Lead>();


		List<Lead> notAssignedLeads = new List<Lead>();

		for (Lead leadObj : leads){
			System.debug('inside loop');
			System.debug('campaigns: ' + campaignMap);
			System.debug('campaign: ' + campaignMap.get(leadObj.Primary_Campaign__c));
			
			Boolean assignedByPreProtection = false;
			Boolean runSkillRouting = false;

			if(leadObj.Primary_Campaign__c != null
				&& campaignMap != null
				&& campaignMap.containsKey(leadObj.Primary_Campaign__c)
				&& campaignMap.get(leadObj.Primary_Campaign__c) != null
				&& campaignMap.get(leadObj.Primary_Campaign__c).type != null) {

				if( campaignMap.get(leadObj.Primary_Campaign__c).type.containsIgnoreCase('CPL') ) {

					String campaignSubType = campaignMap.get(leadObj.Primary_Campaign__c).type.toUpperCase();
					if(campaignSubTypeQueueMap.get(campaignSubType) != null){
						if(!string.isBlank(campaignSubTypeQueueMap.get(campaignSubType).Queue_Id__c)){
							leadObj.ownerId = campaignSubTypeQueueMap.get(campaignSubType).Queue_Id__c;
							// ownerFoundBasedOnPreProtection = true;
							leadObj.Assignment_Source_hidden__c = 'PRE-PROTECTION RULE';
							assignedByPreProtection = true;
						}
					}

					if ( !assignedByPreProtection ) {
						notAssignedLeads.add(leadObj);
					}

				} else {

					// B-1247(run skill routing)
					leadsToRunSkillRouting.add(leadObj);
					runSkillRouting = true;

				}

			}

			if( !assignedByPreProtection && !runSkillRouting ) {
				notAssignedLeads.add(leadObj);
			}

		}

		// B-1247
		if( leadsToRunSkillRouting.size() > 0 ) {

			Map<String, String> empToCustomerSizeMap =  LeadTriggerHelper.getCustomerSize(leadsToRunSkillRouting);

			for(Lead leadObj : leadsToRunSkillRouting) {

				String key = (String.isBlank(leadObj.Effective_No_of_Employees_Range__c) ? 'DEFAULT' : leadObj.Effective_No_of_Employees_Range__c);
				String customerSize = empToCustomerSizeMap.get(key);

				List<Id> finalSkillList = new List<Id>();
			}

		}

		return notAssignedLeads;
	}

	public static void prepareDataForPreprotection(Map<Id, Lead> leads,
											Map<String,Campaign_Subtype_Mapping__c> campaignSubTypeQueueMap,
											Map<String, Campaign> campaignMap) {
		campaignMap = LeadTriggerHelperExt.assignCampaigns(leads.values());
		System.debug('campaignmap: ' + campaignMap);
		for(String campaignType : Campaign_Subtype_Mapping__c.getAll().keySet()){
			campaignSubTypeQueueMap.put(campaignType.toUpperCase(),Campaign_Subtype_Mapping__c.getAll().get(campaignType));
		}
	}



	public static List<Lead> GeoRouting(List<Lead> leads, Map<string,Map<String,String>> segmentDataMap, Map<String,Map<String,List<Territory_Data__c>>> territoryDataMap){
		
		if( segmentDataMap == null || segmentDataMap.isEmpty() ) {
				segmentDataMap = PRAssignmentLogic.createSegmentDataMap();
		}
		if( territoryDataMap == null || territoryDataMap.isEmpty() ) {
			territoryDataMap = PRAssignmentLogic.createTerritoryDataMap();
		}

		List<string> employeeSizeList = new List<String>();
		employeeSizeList = Label.Territory_Employee_Size.split(';');
		Set<string> employeeSizeSet = new set<string>();
		for(String str : employeeSizeList){
			employeeSizeSet.add(str.trim());
		}

		List<string> leadSourceList = new List<String>();
		leadSourceList = Label.Territory_Lead_Source.split(';');
		Set<string> leadSourceSet = new set<string>();
		for(String str : leadSourceList){
			leadSourceSet.add(str.trim());
		}


		List<Lead> notAssignedLeads = new List<Lead>();

		for (Lead leadObj : leads){
			Boolean territoryUserFound = PRAssignmentLogic.runGeoTerritoryRouting(leadObj,
																					segmentDataMap,
																					territoryDataMap,
																		  			employeeSizeSet,
																					leadSourceSet);
			if( !territoryUserFound ) {
				notAssignedLeads.add(leadObj);
			}
		}

		return notAssignedLeads;

	}



	public static List<Lead> ProtectionRouting(List<Lead> leads, Map<String,RcDealHealper.searchResultClass> leadContactSearchMap, Map<String,User> userEmailOwnerMap, Map<String,Contact> contactEmailOwnerMap) {
		Map<String,String> prOwnerMap = new Map<String,String>();
		Map<String,PRAssignmentLogic.prRuleWrapper> prOwnerDetailMap = new Map<String,PRAssignmentLogic.prRuleWrapper>();
		
		
		Map<String, Boolean> resultMap = LeadTriggerHelper.getLeadOwnerRCSFsync(leads);

		List<string> excludedUserList = new List<String>();
	    excludedUserList = Label.Excluded_PR_User_IDs.split(';');
	    Set<string> excludedPRUserIdSet = new set<string>();
	    for(String str : excludedUserList){
	        excludedPRUserIdSet.add(str.trim());
	    }

		User loggedInUser = new User();
	    User VarContactUser = new User();

	    for(User users : [SELECT Id,Email,Name,Profile.Name,ProfileId,Systems_Integration_Users__c From User WHERE UserType='Standard' AND
	    IsActive=true AND (Id=: UserInfo.getUserId() OR Name=: 'DO NOT CONTACT - VAR')]) {
	        if(users.Id == UserInfo.getUserId()){
	            loggedInUser = users;
	        }else if(users.Name == 'DO NOT CONTACT - VAR'){
	            VarContactUser = users;
	        }
	    }

	    if( leadContactSearchMap == null || leadContactSearchMap.isEmpty() ) {
			leadContactSearchMap = RcDealHealper.LeadContactSearch(leads,prOwnerMap,resultMap,excludedPRUserIdSet);
		}

		PRAssignmentLogic.checkAccountCurrentOwner(leadContactSearchMap,prOwnerMap,prOwnerDetailMap,excludedPRUserIdSet);
		
		if( userEmailOwnerMap == null || userEmailOwnerMap.isEmpty() ) {
			userEmailOwnerMap = PRAssignmentLogic.createEmailOwnerMap(leads);
		}

		if( contactEmailOwnerMap == null || contactEmailOwnerMap.isEmpty() ) {
			contactEmailOwnerMap = PRAssignmentLogic.createEmailContactMap(leads);
		}


		List<Lead> notAssignedLeads = new List<Lead>();

		for (Lead leadObj : leads){
			String uniqueKey = ( !String.isBlank(leadObj.Email) ? leadObj.Email : '') + ( !String.isBlank(leadObj.Phone) ? leadObj.Phone : '');
			if ( (leadObj.Bypass_PR__c == false || leadObj.Bypass_PR__c == NULL) && leadObj.LeadSource != 'Other' && leadObj.RecordTypeName__c != 'Partner_Leads' ) {
				
				Boolean prUserFound = PRAssignmentLogic.runPRLogic(leadObj, uniqueKey, prOwnerMap, prOwnerDetailMap, userEmailOwnerMap, contactEmailOwnerMap, loggedInUser,VarContactUser, true);
				
				if ( !prUserFound ) {
					notAssignedLeads.add(leadObj);
				}
			}else{
				// these leads must be processed by geo routing too
				notAssignedLeads.add(leadObj);
			}
		}

		return notAssignedLeads;
	}


	public static Map<Id, Boolean> LarRouting(Map<Id, Lead> leads){
		return prepareAndRunLarRouting(leads.values());
	}

	public static Map<Id, Boolean> LarRouting(List<Lead> leads){
		return prepareAndRunLarRouting(leads);
	}

	private static Map<Id, Boolean> prepareAndRunLarRouting(List<Lead> leads) {
		User userObj = [SELECT Id,Email,Name,Profile.Name,ProfileId,Systems_Integration_Users__c
						FROM User
						WHERE UserType='Standard'
						AND IsActive=true
						AND Name=: 'LAR System User' LIMIT 1];

		LeadAssignmentRuleDAO.startLeadAssignment(userObj, leads);

		return null;
	}

	webservice static void runPreprotection(String leadId) {
		Lead leadObj = [SELECT Id, Email, Phone, Assignment_Source_hidden__c, Country,
								State, City, PostalCode, Lead_Brand_Name__c, CurrencyIsoCode,
								LeadSource, BMID__c, Account__c, User_ID__c, Primary_Campaign__c,
								Lead_Score__c, Original_Phone_Number__c, FirstName, LastName,
								RecordTypeId, Duplicate_Lead__c, Bypass_PR__c, RecordTypeName__c,
								OwnerId, Lead_Submitter_Id__c, LAR_Source__c, Last_Touched_Date__c,
								Last_Touched_By__c, Responded_Date__c, Responded_By__c, Status,
								Eligible_Protection_Period__c, Lead_System_Source__c, NumberOfEmployees__c,
								Assignment_Source__c, AID__c, PID__c,
								Five9_DNIS__c, Most_Recent_Campaign__c, Employee_Size_History__c, Industry,
								Job_Function__c, Purchase_Timeframe__c, IsConverted, ConvertedOpportunityId,
								ConvertedAccountId, LS_Company_Country__c,
								LS_Company_Zipcode__c, Is_Protected__c, LeadPartnerID__c, Inside_Sales_Rep__c,
								Partner_Lead_Owner__c, Partner_Contact__c, Partner_Lead_Source__c,
								Partner_Account_Name__c, Ultimate_Parent_Account_Partner_ID__c,
								Ultimate_Parent_Account_Name__c, Current_Owner_Name__c, VAR_Territory__c,
								Lead_Owner_Email_Address__c, Sales_Agent_Email__c, Employees_Override__c,
								LS_Company_Size_Range__c FROM Lead WHERE Id = :leadId];

		List<Lead> notAssignedLeads = PreprotectionRouting(new List<Lead>{ leadObj }, null);

		Boolean leadAssignedByPreProtection = ( notAssignedLeads.size() > 0 ) ? false : true;

		System.debug('leadAssignedByPreProtection: ' + leadAssignedByPreProtection);
	}

	webservice static void runGeo(String leadId){
		Lead leadObj = [SELECT Id, Email, Phone, Assignment_Source_hidden__c, Country,
								State, City, PostalCode, Lead_Brand_Name__c, CurrencyIsoCode,
								LeadSource, BMID__c, Account__c, User_ID__c, Primary_Campaign__c,
								Lead_Score__c, Original_Phone_Number__c, FirstName, LastName,
								RecordTypeId, Duplicate_Lead__c, Bypass_PR__c, RecordTypeName__c,
								OwnerId, Lead_Submitter_Id__c, LAR_Source__c, Last_Touched_Date__c,
								Last_Touched_By__c, Responded_Date__c, Responded_By__c, Status,
								Eligible_Protection_Period__c, Lead_System_Source__c, NumberOfEmployees__c,
								Assignment_Source__c, AID__c, PID__c,
								Five9_DNIS__c, Most_Recent_Campaign__c, Employee_Size_History__c, Industry,
								Job_Function__c, Purchase_Timeframe__c, IsConverted, ConvertedOpportunityId,
								ConvertedAccountId, LS_Company_Country__c,
								LS_Company_Zipcode__c, Is_Protected__c, LeadPartnerID__c, Inside_Sales_Rep__c,
								Partner_Lead_Owner__c, Partner_Contact__c, Partner_Lead_Source__c,
								Partner_Account_Name__c, Ultimate_Parent_Account_Partner_ID__c,
								Ultimate_Parent_Account_Name__c, Current_Owner_Name__c, VAR_Territory__c,
								Lead_Owner_Email_Address__c, Sales_Agent_Email__c, Employees_Override__c,
								LS_Company_Size_Range__c, LS_Primary_NAIC__c, Geo_Country__c
								FROM Lead WHERE Id = :leadId];

		
		List<Lead> notAssignedLeads = GeoRouting(new List<Lead>{ leadObj }, null, null);

		Boolean leadAssignedByGeo = ( notAssignedLeads.size() > 0 ) ? false : true;

		System.debug('leadAssignedByGeo: ' + leadAssignedByGeo);

	}

	webservice static void runProtection(String leadId) {
		Lead leadObj = [SELECT Id, Email, Phone, Assignment_Source_hidden__c, Country,
								State, City, PostalCode, Lead_Brand_Name__c, CurrencyIsoCode,
								LeadSource, BMID__c, Account__c, User_ID__c, Primary_Campaign__c,
								Lead_Score__c, Original_Phone_Number__c, FirstName, LastName,
								RecordTypeId, Duplicate_Lead__c, Bypass_PR__c, RecordTypeName__c,
								OwnerId, Lead_Submitter_Id__c, LAR_Source__c, Last_Touched_Date__c,
								Last_Touched_By__c, Responded_Date__c, Responded_By__c, Status,
								Eligible_Protection_Period__c, Lead_System_Source__c, NumberOfEmployees__c,
								Assignment_Source__c, AID__c, PID__c,
								Five9_DNIS__c, Most_Recent_Campaign__c, Employee_Size_History__c, Industry,
								Job_Function__c, Purchase_Timeframe__c, IsConverted, ConvertedOpportunityId,
								ConvertedAccountId, LS_Company_Country__c,
								LS_Company_Zipcode__c, Is_Protected__c, LeadPartnerID__c, Inside_Sales_Rep__c,
								Partner_Lead_Owner__c, Partner_Contact__c, Partner_Lead_Source__c,
								Partner_Account_Name__c, Ultimate_Parent_Account_Partner_ID__c,
								Ultimate_Parent_Account_Name__c, Current_Owner_Name__c, VAR_Territory__c,
								Lead_Owner_Email_Address__c, Sales_Agent_Email__c, Employees_Override__c,
								LS_Company_Size_Range__c, LS_Primary_NAIC__c, Geo_Country__c
								FROM Lead WHERE Id = :leadId];

		List<Lead> notAssignedLeads = ProtectionRouting(new List<Lead>{ leadObj }, null, null, null);

		Boolean leadAssignedByProtection = ( notAssignedLeads.size() > 0 ) ? false : true;

		System.debug('leadAssignedByProtection: ' + leadAssignedByProtection);
	}

	webservice static void runLAR(String leadId) {
		Lead leadObj = [SELECT Id, Email, Phone, Assignment_Source_hidden__c, Country,
								State, City, PostalCode, Lead_Brand_Name__c, CurrencyIsoCode,
								LeadSource, BMID__c, Account__c, User_ID__c, Primary_Campaign__c,
								Lead_Score__c, Original_Phone_Number__c, FirstName, LastName,
								RecordTypeId, Duplicate_Lead__c, Bypass_PR__c, RecordTypeName__c,
								OwnerId, Lead_Submitter_Id__c, LAR_Source__c, Last_Touched_Date__c,
								Last_Touched_By__c, Responded_Date__c, Responded_By__c, Status,
								Eligible_Protection_Period__c, Lead_System_Source__c, NumberOfEmployees__c,
								Assignment_Source__c, AID__c, PID__c,
								Five9_DNIS__c, Most_Recent_Campaign__c, Employee_Size_History__c, Industry,
								Job_Function__c, Purchase_Timeframe__c, IsConverted, ConvertedOpportunityId,
								ConvertedAccountId, LS_Company_Country__c,
								LS_Company_Zipcode__c, Is_Protected__c, LeadPartnerID__c, Inside_Sales_Rep__c,
								Partner_Lead_Owner__c, Partner_Contact__c, Partner_Lead_Source__c,
								Partner_Account_Name__c, Ultimate_Parent_Account_Partner_ID__c,
								Ultimate_Parent_Account_Name__c, Current_Owner_Name__c, VAR_Territory__c,
								Lead_Owner_Email_Address__c, Sales_Agent_Email__c, Employees_Override__c,
								LS_Company_Size_Range__c, LS_Primary_NAIC__c, Geo_Country__c,
								Effective_No_of_Employees_Range__c, Lead_Entry_Source__c
								FROM Lead WHERE Id = :leadId];
		Map<Id, Lead> leadsMap = new Map<Id, Lead>();
		leadsMap.put(leadObj.Id, leadObj);
		Map<Id, Boolean> result = LarRouting(leadsMap);
		System.debug('results: ' + result);
	}


	public static Boolean isUseNewRouting() {
		LeadRoutingSettings__c defaultRoutingSettings = LeadRoutingSettings__c.getOrgDefaults();

        Boolean useNewRouting = false;

        if(defaultRoutingSettings.Id != null) {
            useNewRouting = defaultRoutingSettings.UseNewRouting__c;
        }else{
            System.debug('defaultRoutingSettings is null!!! use standart lead rounting.');
        }
        
        return useNewRouting;
	}

}