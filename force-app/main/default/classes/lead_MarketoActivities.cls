/*       
* Created By    : Rajalakshmi R
* Created Date  : 14-07-2020
* Description   : Controller class for Lead_marketo_Activities lightning component
* Test Class    :      

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/

public class lead_MarketoActivities {
    
    @AuraEnabled
    public static Lead getLead(String recordId){
        Lead ld = [Select Id,LeadID18Digit__c,Email From Lead Where Id = :recordId];
        return ld;
    }

}