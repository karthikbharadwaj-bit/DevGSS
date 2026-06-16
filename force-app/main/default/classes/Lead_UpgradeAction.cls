/*       
        * Created By    : Ishwarya.
        * Created Date  : 20-03-2020
        * Description   : Controller class for Lead_Upgrade lightning component
        * Test Class    : Test_LeadUpgradeAction     
        
Change History
********************************************************************************************************************
    SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/

public class Lead_UpgradeAction {
 @AuraEnabled
    public static String upgradeLead(String LeadID){
        List<Lead> leadList=new List<Lead>();
        String status;
        String query='select Id,Name,Status from Lead where Id=' +'\''+LeadID+'\'';
        leadList=Database.query(query); 
        try{
        if(leadList.get(0).Status=='0. Downgraded'){
            Lead lead=new Lead();
            lead.Id=LeadID;
            lead.Status='.5 Re-New';
            update lead;
            return 'SUCCESS';
        }
        else{
            return 'Cannot upgrade';
        }
        }
        catch(Exception ex){
            return 'Error';
        }
        
    }
}