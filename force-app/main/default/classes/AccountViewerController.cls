public with sharing class AccountViewerController {

    private static final List<String> partnerOperationsProfiles = new List<String>();
    //EU Privacy Phase 3 Changes - END

    public String herokuEndpoint { get; set; }
    public String origin         { get; set; }
    public String sId            { get; set; }
    public String bapLink        { get; set; }
    public String profileWorksWithPartnerOperations { get; set; }
    public String accountRecordTypeMap { get; set; }
    public String billOnBehalfPartnerTypes { get; set; }
    public String wholesalePartnerTypes { get; set; }
    public String currentPartnerOperation { get; set; }
    public Id newSalesOpportunityRecordTypeId {
        get {
            return OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY;
        }
        set;
     }

    public AccountViewerController(ApexPages.StandardController stdController) {
        herokuEndpoint = EndpointsSettingsHandler.uqtServerEndpoint;
        origin = URL.getOrgDomainUrl().toExternalForm();
        sId = SettingsService.getSessionId();
        bapLink = NGBS_Settings__c.getInstance().BAP_Link__c;
        profileWorksWithPartnerOperations = JSON.serialize(isPartnerOperationsAvailable());
        accountRecordTypeMap = JSON.serialize(new Map<Id, String>{
            AccountHelper.RT_ID_CUSTOMER_ACCOUNT => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
            AccountHelper.RT_ID_PARTNER_ACCOUNT => AccountHelper.RT_NAME_PARTNER_ACCOUNT
        });
        billOnBehalfPartnerTypes = JSON.serialize(AccountHelper.ACCOUNT_BILL_ON_BEHALF_PARTNERS);
        wholesalePartnerTypes = JSON.serialize(AccountHelper.ACCOUNT_WHOLESALE_PARTNERS);
        currentPartnerOperation = JSON.serialize(getCurrentPartnerOperation(stdController.getId()));

        List<EU_Component_reference__mdt> profileList = [Select DeveloperName,Values__c from EU_Component_reference__mdt where Apex_Classes__c like '%AccountViewerController%' and DeveloperName='partnerOperationsProfiles'];
        for(EU_Component_reference__mdt profRec:profileList){
            if(String.isNotBlank(profRec.Values__c)){
                partnerOperationsProfiles.addall(profRec.Values__c.split(','));
            }
        }
    }

    @TestVisible
    private static Boolean isPartnerOperationsAvailable() {
        Profile currentUserProfile = ProfileHelper.getCurrentUserProfile();
        return (partnerOperationsProfiles.contains(currentUserProfile.Name));
    }

    @TestVisible
    private static PartnerOperationsHelper.PartnerOperation getCurrentPartnerOperation(Id accountId) {
        return SettingsService.getCurrentPartnerOperation(accountId);
    }
}