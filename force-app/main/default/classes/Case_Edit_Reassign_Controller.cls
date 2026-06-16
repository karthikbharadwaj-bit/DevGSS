/*       
* Created By    : Madhumita
* Created Date  : 17-06-2020
* Description   : Controller class for Case_Edit_Reassign lightning component
* Test Class    :      

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Case_Edit_Reassign_Controller {
	@AuraEnabled
    public static String updateCase(Id caseId, Id userId, String buttonName){
		String result;
        Case cse = [Select id, Status, OwnerId, CreatedById from Case where id=: caseId];
        try{
                
                if(cse.Status == 'Cancelled' || cse.Status == 'Closed' || cse.Status == 'Cancel')
                {
                    result='Since the Case is '+ cse.Status +', you cannot perform this action anymore.';
                }
                else if(cse.OwnerId == userId )
                {
                    result='Success';
                }
                else if(cse.CreatedById == userId && buttonName == 'Edit'){
                    result='You do not own this case. To edit it, please Recall the case.';
				}else{
					result='Since you are not the assignee of the case, you cannot edit or reassign the case.';
				}
        }
        catch(Exception e){
            result = 'Your session has expired. Please log in again.';
            
        }
        return result;
    }
}