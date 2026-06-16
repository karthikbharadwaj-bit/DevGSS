public class Opportunity_SubmitRFP {
    @AuraEnabled
    public static Opportunity getOpportunityDetail(String opportunityId){
        Opportunity opp = [Select Id,Name from Opportunity where Id=:opportunityId];   
        return opp;
    }
}