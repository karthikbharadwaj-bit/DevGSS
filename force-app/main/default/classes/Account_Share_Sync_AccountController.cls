/*       
        * Created By    : Namitha
        * Created Date  : 22-05-2020
        * Description   : Controller class for Account_Share_Sync_Account lightning component
        * Test Class    :Test_Account_RC_AccountController      
        
Change History
********************************************************************************************************************
    SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/

public class Account_Share_Sync_AccountController {
 	@AuraEnabled
    public static String shareSyncAccount(String accountId)
    {
        try
        {
            String response = syncAccountUpdateSharingRule.updateSingleAccountSharingRule(accountId);
            return response;
        }
        catch(Exception ex)
        {
            return 'Error';
        }
    }
}