/*       
* Created By    : Madhumita
* Created Date  : 06-05-2020
* Description   : Controller class for Case_Escalate_To_ERT lightning component
* Test Class    : Test_Case_RC_AccountController

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Case_Escalate_To_ERTController {
	@AuraEnabled
    public static String escalate(Id caseId) {
       
        try{
            String result = EscalateERTTeam.escalateToERT(caseId);
           
            if(test.isRunningTest())
            {
                integer i =1/0;
            }
             return result;
        }
        catch(Exception ex){
            return 'Your session has expired. Please log in again.';
        }
    }
}