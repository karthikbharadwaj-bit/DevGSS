/*       
* Created By    : Ranjani N
* Created Date  : 05-10-2020
* Description   : Controller class for opportunity_Expert_support lightning component
* Test Class    :

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/

public class Opportunity_Expert_supportcontroller {
    
     @AuraEnabled
    public static opportunity getopprecord(String recordid){
      opportunity opp = [SELECT Id,name,AccountId,Account.name, CreatedDate from opportunity WHERE Id =: recordid];
      return opp;

    }
     

}