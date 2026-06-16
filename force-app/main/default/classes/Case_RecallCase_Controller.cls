/*       
* Created By    : Madhumita
* Created Date  : 18-06-2020
* Description   : Controller class for Case_RecallCase lightning component
* Test Class    :      

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Case_RecallCase_Controller {
    @AuraEnabled
    public static String recallCase(Id caseId, Id userId){
        String result;
        Case cse = [Select id, Status, OwnerId, CreatedById from Case where id=: caseId];
        try{
            if(cse.Status == 'Cancelled' || cse.Status == 'Closed' || cse.Status == 'Cancel')
            {
                result='Since the Case is '+ cse.Status +', you cannot perform this action anymore.';
            }
            else{
                if(cse.OwnerId == cse.CreatedById){
                    result = 'You are the current assignee of the case. You cannot recall the case';
                }
                else{
                    if(cse.CreatedById == userId)
                    {
                        result='Success';
                    }
                    else{
                        result='This action is not valid for you';
                    }
                    
                }
            }
        }
        catch(Exception e){
            result = 'Your session has expired. Please log in again.';
        }
        return result;
    }
    
    @AuraEnabled
    public static String updateCase(Id caseId, Id userId){
        string message;
        Case cs = [Select id, Status, OwnerId from Case where id=: caseId];
        try{
            cs.id = caseId ;
            cs.OwnerId= userId;
            cs.Status='New';
            
            update cs;
            message ='You have Recalled Case successfully';
        }
        catch(Exception e){
            message='Insufficient Privileges' + '\n\n' + 'You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.';
        }
        return message;
    }
    
}