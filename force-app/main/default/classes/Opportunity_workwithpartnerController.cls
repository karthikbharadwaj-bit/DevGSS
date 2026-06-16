/*       
* Created By    : Ranjani N
* Created Date  : 29-05-2020
* Description   : Controller class for Opportunity_workwithpartner lightning components
* Test Class    :      

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/


public class Opportunity_workwithpartnerController {
    
    @AuraEnabled
    public static Opportunity getOpprecord(String recordId){
        Opportunity opp = [Select Id, Account.SM_Employees__c,AccountId,	StageName From Opportunity Where Id = :recordId];
        return opp;
        	
    }
    @AuraEnabled
    public static Boolean getApprovalrecordtype(String recordId){
         Boolean Approvallist;
		list<Approval__c >App = [SELECT Id, recordType.Name FROM Approval__c WHERE opportunity__c =:recordId AND RecordType.Name = 'Channel Cross Sell'];
	      if(App!=null && !App.isEmpty())
	      {
	          Approvallist=true;
	      }
	        else
	        {
	            Approvallist=false;
	        }
	        return Approvallist;
	    }
    @AuraEnabled
    public static Boolean getIsAllForecastedUsersZero(String recordId){
      Opportunity opp = [Select Id, Forecasted_Users__c, Forecast_Contact_Center_Users__c, Forecasted_Global_Office_Users__c, 
                                    ForcastedDimeloUsers__c,  Forecast_Connect_First_Users__c, Forecasted_RingCentral_Video_Users__c From Opportunity Where Id = :recordId];
      return OpportunityHelper.isAllForecastedUsersZero(opp);
    }


}