/*       
* Created By    : Namitha
* Created Date  : 05-05-2020
* Description   : Controller class for Phase_Complete_Phase lightning component
* Test Class    : Test_Phase_Complete_PhaseController

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Phase_Complete_PhaseController {
	@AuraEnabled
    public static PhaseWrapper getPhaseDetails(String phaseId) {
       	Phase__c ph = [Select Id, RecordType.Name, Ship_Date__c, Completed_Date__c, Completion_Date__c,(SELECT RingCentral_Hardware_Phase__c FROM Hardware_Line_Items__r LIMIT 1) from Phase__c where Id=:phaseId];
       	String profileName = [Select profile.name from User where Id=:UserInfo.getUserId()].profile.name;
        PhaseWrapper pw = new PhaseWrapper(ph,profileName);
        return pw;       
    }
    @AuraEnabled
    public static String updatePhase(String phaseId) {
       	String response = 'SUCCESS';
        try
        {
            Phase__c ph = [Select Id, RecordType.Name, Ship_Date__c, Completed_Date__c, Completion_Date__c from Phase__c where Id=:phaseId];
			if(ph.RecordType.Name == 'ProServ Phase')
            {
                ph.Completed_Date__c = DateTime.now();
                ph.Completion_Date__c = Date.today();
            }
            else if(ph.RecordType.Name == 'RingCentral Hardware Phase')
            {
                ph.Ship_Date__c = Date.today();
            }
            update ph;
            ApexWebServices.completePhase(phaseId,true);            
        }
        catch(Exception e)
        {
            response = e.getMessage();
        }
        return response;
    }
    public class PhaseWrapper
    {
        @AuraEnabled public Phase__c ph;
        @AuraEnabled public String profileName;
        public PhaseWrapper(Phase__c ph,String profileName)
        {
            this.ph = ph;
            this.profileName = profileName;
        }
    }
}