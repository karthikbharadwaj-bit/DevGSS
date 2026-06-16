/*       
* Created By    : Madhumita
* Created Date  :  02-06-2020
* Description   : Controller class for opportunity_CreateSalesAgreement lightning component
* Test Class    : 

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Opportunity_CreateSalesAgreement {
	@AuraEnabled
    public static Opportunity getContact(String OppId){
        Opportunity Opp;
        try{
            
            Opp = [Select Primary_Opportunity_Contact__c,AccountId,Id,(Select ContactId,Contact.Email From OpportunityContactRoles where isPrimary = true)
                   from Opportunity where Id=:OppId];
             
        }
        catch(Exception ex){
            system.debug('Error:'+ex.getmessage());
        }
        
        return Opp;
    }
}