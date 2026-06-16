public class DowngradePopUpCtrl {

    public Lead currentLead {get;set;}

    public DowngradePopUpCtrl(ApexPages.StandardController stdController) {
        currentLead = (Lead)stdController.getRecord();
        currentLead = (Lead) new LeadSelector().selectLeadById(new List<Id>{currentLead.Id}).executeQuery().get(0);
        currentLead.Status = LeadHelper.STATUS_DOWNGRADED;
    }

    public void saveLead() {
        try {
            update currentLead;
        } catch (Exception ex) {
            Apexpages.addMessages(ex);
        }
    }
}