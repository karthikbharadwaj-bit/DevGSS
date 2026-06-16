public with sharing class CampaignInfluenceRelatedListController {

    public Opportunity opp {get;set;}
    public List<CampaignInfluenceRelatedItem> cInfluenceRList {get;set;}
    public Boolean shouldRedirect {get;set;}
    public String redirectUrl {get;set;}
    public Boolean isGPAOpportunity {get;set;}

    public class CampaignInfluenceRelatedItem {
        public CampaignInfluence campaignInfluence {get;set;}
        public Campaign campaign {get;set;}
        public Contact contact {get;set;}
        public String contactRole {get;set;}
        public Boolean isPrimaryCampaignSource {get;set;}
        public Boolean isNonAttributable {get;set;}
        public String memberFirstAssociatedDate {get;set;}

        public CampaignInfluenceRelatedItem(CampaignInfluence cInfluence, Opportunity opp, List<CampaignMember> members) {
            this.campaignInfluence = cInfluence;
            this.campaign = cInfluence.Campaign;
            this.contact = cInfluence.Contact;
            this.isPrimaryCampaignSource = (campaign.Id == opp.CampaignId);
            this.isNonAttributable = cInfluence.Campaign.Non_Attributable__c;

            for(CampaignMember cm : members) {
                if(cm.ContactId == cInfluence.ContactId
                    && cm.CampaignId == cInfluence.CampaignId) {
                    this.memberFirstAssociatedDate = cm.CreatedDate.format();
                }
            }

            if(opp.OpportunityContactRoles != null) {
                for(OpportunityContactRole cRole : opp.OpportunityContactRoles) {
                    if(cInfluence.Contact.Id == cRole.ContactId) {
                        this.contactRole = cRole.Role;
                    }
                }
            }
        }
    }

    public CampaignInfluenceRelatedListController(ApexPages.StandardController stdController) {
        String oppId = ApexPages.currentPage().getParameters().get('Id');
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        List<Id> campaignInfluenceContactIds = new List<Id>();

        opp = [
            SELECT Id, Name, CampaignId, Account.GPA_Account__c,
                (SELECT Id, Campaign.Id, Campaign.Name, ContactId, Contact.Name, 
                    Influence, RevenueShare, Campaign.Non_Attributable__c
                FROM CampaignInfluences),
                (SELECT Id, ContactId, Role 
                FROM OpportunityContactRoles)
            FROM Opportunity 
            WHERE Id = :oppId
        ];

        for(CampaignInfluence ci: opp.CampaignInfluences) {
            if (ci.ContactId == null) {
                continue;
            }
            campaignInfluenceContactIds.add(ci.ContactId);
        }

        if(opp.CampaignId != null && !campaignInfluenceContactIds.isEmpty()) {
            campaignMembers = [
                SELECT Id, CreatedDate, ContactId, CampaignId 
                FROM CampaignMember 
                WHERE ContactId = :campaignInfluenceContactIds
                    AND Type = 'Contact'
            ];
        }

        cInfluenceRList = new List<CampaignInfluenceRelatedItem>();
        for(CampaignInfluence ci: opp.CampaignInfluences) {
            CampaignInfluenceRelatedItem cInfluenceRItem = new CampaignInfluenceRelatedItem(ci, opp, campaignMembers);
            cInfluenceRList.add(cInfluenceRItem);
        }

        this.isGPAOpportunity = opp.Account.GPA_Account__c;
    }

    public void newCampaignInfluence() {
        String oppId = ApexPages.currentPage().getParameters().get('Id');

        String url = '/apex/campaigninfluence?retURL='+oppId+'&fromopp='+oppId;
        this.shouldRedirect = true;
        this.redirectUrl = url;
    }

    public void editCampaignInfluence() {
        String cId = ApexPages.currentPage().getParameters().get('cId');
        String oppId = ApexPages.currentPage().getParameters().get('Id');

        String url = '/'+cId+'/e?retURL='+oppId;
        this.shouldRedirect = true;
        this.redirectUrl = url;
    }

    public void deleteCampaignInfluence() {
        String cId = ApexPages.currentPage().getParameters().get('cId');
        String oppId = ApexPages.currentPage().getParameters().get('Id');
        CampaignInfluence ci = [SELECT Id FROM CampaignInfluence WHERE Id =: cId limit 1];
        if(ci !=null && ci.Id !=null){
            delete ci;
        }

        String url = '/'+oppId;
        this.shouldRedirect = true;
        this.redirectUrl = url;
    }
}