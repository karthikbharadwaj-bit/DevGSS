public class OpportunityLARHelper {

	public static boolean IS_SOLVE_THEN_SELL_OPPORTUNITY = false;

	public static Map<String, Campaign> assignCampaignToOpportunity(List<Opportunity> oppList) {
		Map<String, Campaign> campaignMap = new Map<String, Campaign>();
		List<CampaignWrapper> camWrapperList = new List<CampaignWrapper>();

		for(Opportunity opportunityObj : oppList) {
			camWrapperList.add(
                    new CampaignWrapper(
                            opportunityObj.AID__c,
                            opportunityObj.BMID__c,
                            opportunityObj.PID__c,
                            opportunityObj.CampaignId,
                            false)
            );
		}

		Map<String, Campaign> criteriaToCamapaignMap = CampaignAssignmentHelper.findCampaings(camWrapperList);
		for(Opportunity opportunityObj :oppList) {
			Campaign campaignObj = CampaignAssignmentHelper.getLeadCampaign(new CampaignWrapper(opportunityObj.AID__c, opportunityObj.BMID__c, opportunityObj.PID__c, opportunityObj.CampaignId, false), criteriaToCamapaignMap);
			if(campaignObj != null) {
				opportunityObj.CampaignId = campaignObj.Id;
				campaignMap.put((String)opportunityObj.CampaignId, campaignObj);
			}
		}
		return campaignMap;
	}
	private static Map<String, String> getOpportunityCustomerSize(List<Opportunity> opportunityList) {
		Set<Id> accountIds = new Set<Id>();
		for(Opportunity opportunityObj : opportunityList) {
			if(String.isBlank(opportunityObj.Number_of_Employees__c)) {
				accountIds.add(opportunityObj.AccountId);
			}
		}
		Boolean doSOQL = false;
		Map<Id, Account> accountMap = new Map<Id, Account>();
		for (Id aId : accountIds){
			if (!OpportunityTriggerHelperRefactored.accountMapStatic.containsKey(aId)){
				doSOQL = true;
			}else{
				accountMap.put(aId, OpportunityTriggerHelperRefactored.accountMapStatic.get(aId));
			}
		}
		if (doSOQL) {
			accountMap = new Map<Id, Account>([SELECT Id, No_of_Employees__c FROM Account WHERE Id IN:accountIds]);
		}
		Map<String, String> empToCustomerSizeMap = new Map<String, String>();
		Set<String> rangesOpp = new Set<String>();
		Set<String> rangesAccount = new Set<String>();
		Schema.DescribeFieldResult numberOfEmployees = Account.No_of_Employees__c.getDescribe();
        List<Schema.PicklistEntry> numberOfEmployeesRange = numberOfEmployees.getPicklistValues();
        for(Schema.PicklistEntry schObj : numberOfEmployeesRange) {
            rangesAccount.add(schObj.getValue());
        }
        numberOfEmployees = Opportunity.Number_of_Employees__c.getDescribe();
        numberOfEmployeesRange = numberOfEmployees.getPicklistValues();
        for(Schema.PicklistEntry schObj : numberOfEmployeesRange) {
            rangesOpp.add(schObj.getValue());
        }
        for(Opportunity opportunityObj : opportunityList) {
            Set<String> ranges = new Set<String>();
            if(!String.isBlank(opportunityObj.Number_of_Employees__c)) {
            	ranges.addAll(rangesOpp);
            } else {
            	ranges.addAll(rangesAccount);
            }
            String customerSize = '2-9';
            String employeeSize = 'DEFAULT';
            if(!String.isBlank(opportunityObj.Number_of_Employees__c)) {
            	customerSize = opportunityObj.Number_of_Employees__c;
            	employeeSize = customerSize;
            } else if(!String.isBlank(accountMap.get(opportunityObj.AccountId).No_of_Employees__c) && ranges.contains(accountMap.get(opportunityObj.AccountId).No_of_Employees__c)) {
                customerSize = accountMap.get(opportunityObj.AccountId).No_of_Employees__c;
                employeeSize = customerSize;
            }
            empToCustomerSizeMap.put(employeeSize, customerSize);
        }
        return empToCustomerSizeMap;
	}
	public static void initialOpportunities(List<Opportunity> opportunityList, Map<Id, User> userMap) {
		String name = UserRC.rcsfSyncUserObj.Name;
        String indiaTeam = UserRC.indiaTeamUserObj.Name;
        String partnerSync = UserRC.rcPartnerSyncUserObj.Name;
        List<Id> finalSkillList = new List<Id>();
        Set<String> skillIds = new Set<String>();
        Map<String, String> empToCustomerSizeMap =  getOpportunityCustomerSize(opportunityList);
        Set<Id> campaignIds = new Set<Id>();
        for(Opportunity opportunityObj : OpportunityList) {
        	if(!String.isBlank(opportunityObj.campaignId)) {
        		campaignIds.add(opportunityObj.campaignId);
        	}
        }
        Map<Id, Campaign> campaignMap = new Map<Id, Campaign>([SELECT Id, Lead_Creation_Score__c, Lead_Entry_Source__c, AID__c,
        PID__c, BMID__c, DNIS__c, /*Team__c,*/ NumberOfLeads, Lead_Score__c, Name FROM Campaign WHERE IsActive=true AND Id IN:campaignIds]);

		Set<Id> accountIds = new Set<Id>();
		for(Opportunity opportunityObj : opportunityList) {
			accountIds.add(opportunityObj.AccountId);
		}

		Boolean doSOQL = false;
		Map<Id, Account> accountMap = new Map<Id, Account>();
		for (Id aId : accountIds){
			if (!OpportunityTriggerHelperRefactored.accountMapStatic.containsKey(aId)){
				doSOQL = true;
			}else{
				accountMap.put(aId, OpportunityTriggerHelperRefactored.accountMapStatic.get(aId));
			}
		}
		if (doSOQL) {
			accountMap = new Map<Id, Account>([SELECT Id, No_of_Employees__c FROM Account WHERE Id IN:accountIds]);
		}
		List<Note> noteList = new List<Note>();
		for(Opportunity opportunityObj : opportunityList) {
				User userObj = userMap.get(opportunityObj.ownerId);
				if(userObj == null || !userObj.isActive || (userObj.Name.equalsIgnoreCase(name) || userObj.Name.equalsIgnoreCase(indiaTeam) ||
					userObj.Name.equalsIgnoreCase(partnerSync) || IS_SOLVE_THEN_SELL_OPPORTUNITY == true)) {
					Campaign campaignObj = campaignMap.get((String) opportunityObj.campaignId);
	                String customerSize = '';
					if(!String.isBlank(opportunityObj.Number_of_Employees__c)) {
		            	customerSize = empToCustomerSizeMap.get(opportunityObj.Number_of_Employees__c);
		            } else if(!String.isBlank(accountMap.get(opportunityObj.AccountId).No_of_Employees__c)) {
		                customerSize = empToCustomerSizeMap.get(accountMap.get(opportunityObj.AccountId).No_of_Employees__c);
		            } else {
		            	customerSize = empToCustomerSizeMap.get('DEFAULT');
					}
	                LARWrapper wrapperObj = new LARWrapper('D', customerSize,opportunityObj.campaignId, opportunityObj.LeadSource, opportunityObj.Lead_Entry_Source__c, '', '','OPPORTUNITY');
	                    opportunityObj.OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ');
	                    opportunityObj.Send_Duplicate_Lead_Email__c = true;
	                	TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
	                	TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
				}
		}
	}
}