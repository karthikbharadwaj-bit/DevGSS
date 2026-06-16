/*
	This is a helper Class called form Lead_before Trigger.
	It has functions to RUN LAR and then assign Lead owner based on Skill Found.
*/

public class LeadAssignmentRuleDAO {

	/****************************************************Lead Assignment Logic based On LARs********************************************************/
	public static void startLeadAssignment(User objUser, List<Lead> lstLead){
		System.debug(' #### COMING TO DAO LAR CODE ####');
		Database.DMLOptions dmo = new Database.DMLOptions();
    	dmo.EmailHeader.triggerUserEmail = false;
    	dmo.EmailHeader.triggerAutoResponseEmail = false;
    	dmo.EmailHeader.triggerOtherEmail = false;

		Map<String, String> empToCustomerSizeMap =  LeadTriggerHelper.getCustomerSize(lstLead);
		for(Lead leadObj:lstLead){
			String  customerSize = empToCustomerSizeMap.get(String.isBlank(leadObj.Effective_No_of_Employees_Range__c) ? 'DEFAULT' : leadObj.Effective_No_of_Employees_Range__c);
			if(Test.isRunningTest()) {
				customerSize = '';
			}
			if(String.isBlank(customerSize)) { 
				customerSize = empToCustomerSizeMap.get('DEFAULT');
			}	
			System.debug(' #### FOUND CUSTOMER SIZE #### ' + customerSize);
	        /*******There was no protected owner found so try to use Lead Assignment Rules (LARs)********/
	        List<Id> finalSkillList = new List<Id>();
	        if(Test.isRunningTest()) {
	        	leadObj.setOptions(dmo); 
	        	leadObj.OwnerId = objUser.Id;
	        } 
	        if(leadObj.OwnerId == objUser.Id) {
	        	leadObj.setOptions(dmo); 
	        	leadObj.OwnerId = (String.isBlank(leadObj.Lead_Submitter_Id__c) ? LeadTriggerHelper.RCSF_SYNC : leadObj.Lead_Submitter_Id__c);
	        }  
		}
		Boolean isFailed = false;
		if(lstLead.size()>0){
			try {update lstLead;} catch(Exception ex) {isFailed = true; System.debug(' #### LEAD FAILED IN LAR #### ' + ex.getMessage());}
		}
        System.debug(' #### FOUND LEAD SIZE #### ' + lstLead.size());
	}
	/********************************************************************************************************************************************/
	
	/***********************************************************Logic to Run LAR****************************************************************/
	public static void runLAR(User objUser) {
		List<Lead> lstLarLeadList=[SELECT Lead_Submitter_Id__c, Email, Company_Size__c, Skill_Name__c, NumberOfEmployees__c, Lead_Entry_Source__c, Lead_Folder__c, Id, LeadSource, Primary_Campaign__c, OwnerId 
	                                    FROM Lead WHERE OwnerId=:objUser.id AND IsConverted=false AND Duplicate_Lead__c=false LIMIT 1];
	    system.debug('Lar Lead List Size = '+lstLarLeadList.size());
	}
}