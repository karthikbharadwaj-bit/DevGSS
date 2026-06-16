public with sharing class AccountLeadQualificationController extends STCControllerHelper{
    public Account acc{get;set;}

    public AccountLeadQualificationController(ApexPages.StandardController controller){
        //property to hold parent view url to solve cross domain issue
        redirectUrl = controller.view().getUrl();
        acc = (Account)controller.getRecord();
        if(acc != null && !String.isBlank(acc.Id) && lq == null){
            List<Opportunity> opps = [
                    SELECT id, LastModifiedDate
                    FROM Opportunity
                    WHERE AccountId = :acc.Id ORDER BY LastModifiedDate DESC
            ];
            if(!opps.isEmpty()) {
                Opportunity opp = opps.get(0);
                allLeadQualList = new List<Lead_Qualification__c>();
                lq = new Lead_Qualification__c();

                allLeadQualList = [
                        SELECT Id,Discovery_notes__c,Motivations__c,Current_Situation__c,Problems__c,Impact__c,
                                Ideal_Situation__c,Benefits__c,Decision_Making_Process__c,Competitive_Landscape__c, Relationship_Building_Extras__c,
                                CoachingNotes__c, NextSteps__c
                        FROM Lead_Qualification__c
                        WHERE Opportunity__c = :opp.ID
                        ORDER BY LastModifiedDate DESC LIMIT 1
                ];

                if(allLeadQualList.size() >0){
                    lq = allLeadQualList.get(0);
                    viewMode = 'read';
                }else{
                    viewMode = 'edit';
                }
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
        update acc;
        //-----------updating or creating leadQualification record
        lq.Account__c = acc.Id;
        System.debug('lq =>> ' + lq);
        upsert lq;
        trackHistory(lq);
        viewMode = 'read';
    }
}