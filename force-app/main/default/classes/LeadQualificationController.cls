public with sharing class LeadQualificationController extends STCControllerHelper{
    public Lead lead{get;set;}
    private String userProfileName;
    private Set<String> insideSalesProfiles;
    public Boolean isInsideSalesProfile {get; private set;}
    public Boolean isSalesProfile {get; private set;}

    public LeadQualificationController(ApexPages.StandardController controller){

        lead = (Lead)controller.getRecord();
        redirectUrl = controller.view().getUrl();
        if(lead != null && !String.isBlank(lead.Id) && lq == null){
            allLeadQualList = new List<Lead_Qualification__c>();
            lq = new Lead_Qualification__c();

            allLeadQualList = [
                    SELECT Id,Discovery_notes__c,Motivations__c,Current_Situation__c,Problems__c,Impact__c,
                    Ideal_Situation__c,Benefits__c,Decision_Making_Process__c,Competitive_Landscape__c, Relationship_Building_Extras__c,
                    CoachingNotes__c, NextSteps__c
                    FROM Lead_Qualification__c
                    WHERE Lead__c = :lead.ID LIMIT 1
            ];

            if(allLeadQualList.size() > 0){
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
        //EU Privacy Phase 3 Sales Profile Changes - START
        insideSalesProfiles = new Set<String>();//-----created to store above profiles and its eu restricted ones
        List<EU_Component_reference__mdt> profileList = [Select DeveloperName,Values__c from EU_Component_reference__mdt where Apex_Classes__c like '%LeadQualificationController%' and DeveloperName='ContactLeadQualification'];
        for(EU_Component_reference__mdt profRec:profileList){
            if(String.isNotBlank(profRec.Values__c)) {
            	insideSalesProfiles.addall(profRec.Values__c.split(','));
            }
        }
        //EU Privacy Phase 3 Sales Profile changes - END
        userProfileName = [
                            SELECT Name
                            FROM Profile
                            WHERE Id =: UserInfo.getProfileId()
                            ].Name;
        isInsideSalesProfile = false;
        Boolean hasCustomPermissionSalesEngineer = FeatureManagement.checkPermission('Sales_Engineer_Permission');
        //added as part of  Profile  consolidation for Support Implementations
        if (ProfileHelper.ALL_SALES_PROFILES.contains(userProfileName) || hasCustomPermissionSalesEngineer) {
            if (insideSalesProfiles.contains(userProfileName)) {
                isInsideSalesProfile = true;
                isSalesProfile = false;
            } else {
                isSalesProfile = true;
            }
        } else {
            isSalesProfile = false;
        }
        trackHistory(lq);

    }

    //------------------Override method save----------------------
    public void save(){
        //update opp;
        //-----------updating current opportunity record
        update lead;
        //-----------updating or creating leadQualification record
        lq.Lead__c = lead.Id;
        upsert lq;
        trackHistory(lq);
        viewMode = 'read';
    }
}