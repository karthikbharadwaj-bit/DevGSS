/*       
* Created By    : Vishal
* Created Date  : 19-05-2020
* Description   : Controller class for Implementation_Network_Information lightning component
* Test Class    : Test_Implementation_Network_InfoCntr    

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/

public class Implementation_Network_InfoController {
    
    @AuraEnabled
    public static Implementation__c getImplementationDetails(String recordid){
     Implementation__c impdata = new Implementation__c();
	 impdata =   [select id, name , Account__c from Implementation__c where id = :recordid];
    
    return impdata;
        
    }

}