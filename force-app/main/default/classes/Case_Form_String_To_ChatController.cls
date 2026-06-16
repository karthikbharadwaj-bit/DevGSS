/*       
* Created By    : Rajalakshmi
* Created Date  : 07-05-2020
* Description   : Controller class for Case_Form_String_ChangeSet, Case_Form_String_To_Chat lightning components
* Test Class    :      

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Case_Form_String_To_ChatController {
    @AuraEnabled
    public static case getCase(String recordId){
        Case c = [Select Id, CaseNumber,Subject,Status,Jeopardy_Code__c,contact.name,AccountId From Case Where Id = :recordId];
        return c;
    }
    
    
}