public without sharing class OpportunityDiscoveryControllerEBM extends STCControllerHelper {
    public Opportunity opp{get;set;}

    public OpportunityDiscoveryControllerEBM(ApexPages.StandardController controller){
        //property to hold parent view url to solve cross domain issue
        redirectUrl = controller.view().getUrl();
        opp = (Opportunity)controller.getRecord();
        if(opp != null && !String.isBlank(opp.Id) && lq == null){
            System.debug('controllers called');
            allLeadQualList = new List<Lead_Qualification__c>();
            lq = new Lead_Qualification__c();

            allLeadQualList = [
                    SELECT Id,Discovery_notes__c,Motivations__c,Current_Situation__c,Problems__c,Impact__c,
                            Ideal_Situation__c,Benefits__c,Decision_Making_Process__c,Competitive_Landscape__c, Relationship_Building_Extras__c,
                            CoachingNotes__c,NextSteps__c, Mutual_Plan__c, RC_Executive_Alignment__c
                    FROM Lead_Qualification__c
                    WHERE Opportunity__c = :opp.ID ORDER BY LastModifiedDate DESC LIMIT 1];

            if(allLeadQualList.size() >0){
                lq = allLeadQualList.get(0);
                viewMode = 'read';
            }else{
                viewMode = 'edit';
            }
        }
        else{
            lq = new Lead_Qualification__c();
            viewMode = 'edit';
        }
        trackHistory(lq);
    }

    //------------------Override method save----------------------
    public void save(){
        //update opp;
        System.debug('saving...');
        //-----------updating current opportunity record
        opp.Discovery_Manager_Notes__c = lq.CoachingNotes__c;
        opp.Discovery_Next_Steps__c = lq.NextSteps__c;
        update opp;
        //-----------updating or creating leadQualification record
        lq.Opportunity__c = opp.Id;
        System.debug('lq =>> ' + lq);
        upsert lq;
        trackHistory(lq);
        viewMode = 'read';
    }
}