public class ContactLeadQualificationController extends STCControllerHelper{
    public Contact contact{get;set;}
    private String userProfileName;
    private Set<String> insideSalesProfiles;
    public Boolean isInsideSalesProfile {get; private set;}
    public Boolean isSalesProfile {get; private set;}

    public ContactLeadQualificationController(ApexPages.StandardController controller){

        contact = (Contact)controller.getRecord();
        redirectUrl = controller.view().getUrl();
        if(contact != null && !String.isBlank(contact.Id) && lq == null){
            allLeadQualList = new List<Lead_Qualification__c>();
            lq = new Lead_Qualification__c();

            allLeadQualList = [
                    SELECT Id,Discovery_notes__c,Motivations__c,Current_Situation__c,Problems__c,Impact__c,
                    Ideal_Situation__c,Benefits__c,Decision_Making_Process__c,Competitive_Landscape__c, Relationship_Building_Extras__c,
                    CoachingNotes__c, NextSteps__c
                    FROM Lead_Qualification__c
                    WHERE contact__c = :contact.ID LIMIT 1
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
        insideSalesProfiles = new Set<String>();//-----created to store above profiles and its eu restricted ones
        List<EU_Component_reference__mdt> profileList = [Select DeveloperName,Values__c from EU_Component_reference__mdt where Apex_Classes__c like '%ContactLeadQualificationController%' and DeveloperName='ContactLeadQualification'];
        for(EU_Component_reference__mdt profRec:profileList){
            if(String.isNotBlank(profRec.Values__c)){
            	insideSalesProfiles.addall(profRec.Values__c.split(','));
            }
        }
        //EU Privacy Phase 3 Sales Profile Changes - END 
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
        update contact;
        lq.Contact__c = contact.Id;
        upsert lq;
        trackHistory(lq);
        viewMode = 'read';
    }
}