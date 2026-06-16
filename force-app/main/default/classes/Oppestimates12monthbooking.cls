public with sharing class Oppestimates12monthbooking {
    public class CloseOpportunityParams {
        public Id opportunityId;
        public String rcNumber;
        public String ccNumber;
        public String approvalId;
    }

    ApexPages.StandardController controller;
    public Id oppId { get; set; }
    public Opportunity opportunityRecord { get; set; }
    private ApexPages.StandardController std;

    public Oppestimates12monthbooking(ApexPages.StandardController stdController) {
        opportunityRecord = (Opportunity) stdController.getRecord();
        std = stdController;
        oppId = (Id) ApexPages.currentPage().getParameters().get('id');
    }

    public PageReference Customcancel() {
        PageReference recdet = new PageReference('/' + oppId);
        recdet.setRedirect(true);
        return recdet;
    }

    public PageReference Customsave() {
        try {
            opportunityRecord = (Opportunity) std.getRecord();

            // Code to be used to submitForm
            Map<String, String> params = new Map<String, String>();
            params.put('Id', opportunityRecord.id);
            params.put('wType', DowngradeWizardController.WIZARD_TYPE_DOWNSELL);
            params.put('Downsell_Churn_Reason__c', opportunityRecord.Downsell_Churn_Reason__c);
            params.put('Downsell_Churn_Sub_Reason__c', opportunityRecord.Downsell_Churn_Sub_Reason__c);
            params.put('Downgrade_Reason_Other__c', opportunityRecord.Downgrade_Reason_Other__c);

            DowngradeWizardController.submitForm(params);
            PageReference recdet = new PageReference('/' + oppId);
            recdet.setRedirect(true);
            return recdet;
        } catch (DmlException dmle) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, dmle.getDmlMessage(0)));
            return null;
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
            return null;
        }
    }
}