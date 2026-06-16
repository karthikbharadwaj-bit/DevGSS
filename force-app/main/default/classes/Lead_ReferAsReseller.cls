/*       
* Created By    : Rajalakshmi
* Created Date  :  18-08-2020
* Description   : Controller class for Refer As Reseller component on Leads
* Test Class    : Test_Lead_ReferAsReseller

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Lead_ReferAsReseller{
    @AuraEnabled
    public static Lead getLeadDetails(String LeadId){
        Lead ldr;
        ldr = [select id,FirstName,LastName,Company,Street,	
                         Email,PostalCode,State,Phone,
                         Country,City From Lead Where Id= :LeadId];
       
        return ldr;
    }

}