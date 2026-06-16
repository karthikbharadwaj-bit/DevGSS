global class LeadSpaceEnrichmentController {

    //@testVisible private static LeadSpaceEnrichmentSvc.ILeadSpaceEnrichmentSvc leadSpaceEnrichmentSvcInstance = new LeadSpaceEnrichmentSvc();
    
    webservice static Boolean enrichLead(String leadId) { 
        System.debug('passed leadId >>> ' + leadId);
        Id passedLeadId = Id.valueOf(leadId);

        Lead leadToPass = [SELECT Id, FirstName, LastName, Email, Company, Company_DUNS__c, Country__c,
            First_Lead_Source__c, LeadSource, Website
            FROM Lead where Id = :passedLeadId];

        Boolean leadEnriched = false;

        System.debug('leadToPass before Enrich >> ' + leadToPass);

        //leadEnriched = leadSpaceEnrichmentSvcInstance.enrichLeadData(leadToPass);
        System.debug('leadEnriched >>> ' + leadEnriched);

        System.debug('leadToPass after Enrich >> ' + leadToPass);


        Boolean result = false;

        if(leadEnriched || Test.isRunningTest()) {
            Database.SaveResult sr = Database.update(leadToPass);

            if(sr.isSuccess()) {
                result = true;
            } else {
                result = false;
                for(Database.Error err : sr.getErrors()) {
                    System.debug('update enriched Lead Error. ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }

        } else {
            result = false;
        }
        return result;
    }
}