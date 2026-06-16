/*       
* Created By    : Ranjani N
* Created Date  : 03-09-2020
* Description   : Controller class for AgentCredit_RequestTransfer lightning component
* Test Class    :      

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/

public class AgentCredit_RequesttransferController {
    
      @AuraEnabled
    public static Integer getCount(String recordId){
        Integer Agc = [SELECT count() from Agent_Credit__c where id= :recordId AND Past_Due_Date__c = true];
        return Agc;
    }
     @AuraEnabled
    public static list<string> getrecord(String recordId){
        Id AppRecordTypeId = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get('Agent Credit Transfers').getRecordTypeId();
        Agent_Credit__c Ac = [SELECT Account__c,Name,Account__r.Name,id from Agent_Credit__c where id= :recordId];
        list<string> Acrecord = new list<string>();
        string rid = string.valueOf(AppRecordTypeId);
        Acrecord.add(rid);
        Acrecord.add(Ac.Account__c);
        Acrecord.add(Ac.Account__r.Name);
        return Acrecord;
    }
    
    

}