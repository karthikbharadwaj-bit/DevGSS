/*       
        * Created By    : Namitha
        * Created Date  : 20-03-2020
        * Description   : Controller class for Lead_LS_Enrich lightning component
        * Test Class    : Test_LeadLSEnrichController     
        
Change History
********************************************************************************************************************
    SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Lead_LS_Enrich_Controller {
	@AuraEnabled
    public static Lead_LS_Enrich_Wrapper enrichLead(String leadId)
    {
        Boolean result = false;
        Lead_LS_Enrich_Wrapper lw;
        Lead l = [Select firstname,lastname,company from lead where Id = :leadId];
        if((l.firstname != null || l.lastname != null) && l.company != null)
        {
            result = LeadSpaceEnrichmentController.enrichLead(leadId);
        }
        lw = new Lead_LS_Enrich_Wrapper(l,result);
        return lw;
    }
    public class Lead_LS_Enrich_Wrapper{
        @AuraEnabled public Lead l;
        @AuraEnabled public Boolean response;
        public Lead_LS_Enrich_Wrapper(Lead l,Boolean response)
        {
            this.l = l;
            this.response = response;
        }
    }
}