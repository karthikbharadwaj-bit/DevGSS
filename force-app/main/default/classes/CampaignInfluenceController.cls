public with sharing class CampaignInfluenceController {
    public CampaignInfluence ci {get;set;}
    public ApexPages.StandardController stdController;

    public CampaignInfluenceController(ApexPages.StandardController stdController) {
        stdController = stdController;
        Id oppId = ApexPages.currentPage().getParameters().get('fromOpp');
        CampaignInfluenceModel cim = [select Id from CampaignInfluenceModel where IsDefaultModel =: true limit 1];
        ci = (CampaignInfluence) stdController.getRecord();
        ci.OpportunityId = oppId;
        ci.ModelId = cim.Id;
    }

    public PageReference save() {
        String retURL = ApexPages.currentPage().getParameters().get('retURL');
        PageReference p = new PageReference(retURL);
                      p.setRedirect(true);

        try {
            insert ci;
        } catch(Exception e) {
            ApexPages.Message pageMess = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(pageMess);
            return null;
        }

        return p;
    }
}