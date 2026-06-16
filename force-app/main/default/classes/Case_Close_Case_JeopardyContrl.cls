/*
* Created By     : Vishal
* Created Date   : 05-06-2020
* Description    : Controller for Case_Close_Case component on case in lightning experience

Change History
*******************************************************************************************************************************************
SCRUM/Jira ModifiedBy      Date        Description Tag
*******************************************************************************************************************************************

*******************************************************************************************************************************************
*/

public class Case_Close_Case_JeopardyContrl {
    
     @AuraEnabled
    public static case getCaseId(String recordId){
        // Added RecordType.DeveloperName for ITPMO-2515 
        Case c = [Select Id, CaseNumber,Subject,Status,Jeopardy_Code__c,contact.name,AccountId,RecordType.DeveloperName From Case Where Id = :recordId];
        return c;
    }
    

     //Called from Lightning Case_Close_Case component to insert solution records
    @AuraEnabled
    public static String createSolutionRecord(String soltitle, String solDetails, String caseId){
        Solution solforCase = new Solution();
        String response;
        solforCase.SolutionName= soltitle;
        solforCase.SolutionNote = solDetails;        
        try{
            insert solforCase;

            CaseSolution caseSol = new CaseSolution();
            caseSol.SolutionId = solforCase.Id;
            caseSol.CaseId = caseId;
            insert caseSol;

            response = solforCase.Id;
            return response;
        }catch(Exception e){
			system.debug(e.getMessage());   
            response = 'error';
            return response;
        }        
    }
    // Added for ITPMO-2515 checking Logged in user having ATT Sales related Permissions
    @AuraEnabled
    public static Boolean checkAttPermissionset (){
        Boolean hasATTCustomPermission = FeatureManagement.checkPermission('ATT_Sales_Permission');
    system.debug('&&&'+hasATTCustomPermission);
    return hasATTCustomPermission;
    }
    
}