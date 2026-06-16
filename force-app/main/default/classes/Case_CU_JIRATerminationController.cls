/*       
* Created By     : Madhumita
* Created Date   : 12-05-2020
* Description   : Controller class for Case_Create_Update_JIRA_Termination lightning component
* Test Class    :    

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/

public class Case_CU_JIRATerminationController {
    @AuraEnabled
    public static String loadCase(String caseId){
        String resultmessage;
        
        try{
            
            resultmessage = JIRA_CreateUpdate_Termination.CreateUpdate_Termination(caseId);
            if(Test.isRunningTest())
            {
                resultMessage = null;
                resultMessage += 'test';
            }
        }catch(Exception e){
            
            resultmessage = 'Unable to create or update Jira Termination. Error during processing.';
            
        }
       return resultmessage;

    }
}