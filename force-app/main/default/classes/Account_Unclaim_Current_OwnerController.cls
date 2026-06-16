/*       
* Created By    : Madhumita
* Created Date  : 05-05-2020
* Description   : Controller class for Account_Unclaim_Current_Owner lightning component
* Test Class    : Test_Acc_Claim_Current_OwnerController

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Account_Unclaim_Current_OwnerController {
    @AuraEnabled
    public static String deOwn(Id accId) {
       
        try{
            String result = AccountDeOwner.deOwn(accId);
            return result;
        }
        catch(Exception ex){
            return 'Unable to unclaim current owner. Error during processing.';
        }
    }
}