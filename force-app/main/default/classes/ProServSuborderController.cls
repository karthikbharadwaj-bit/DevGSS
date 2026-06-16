global with sharing class ProServSuborderController {

    public String billingWizardURL    { get; set; }
    public String origin              { get; set; }
    public String sessionId           { get; set; }
    public Id orderId                 { get; set; }
    public Id quoteId                 { get; set; }
    public Id opportunityId           { get; set; }
    /**
     * Page Controller
     * @param  stdController
     */
    public ProServSuborderController(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>{'quoteId', 'opportunityId'});
        }
        Order orderRecord = (Order) stdController.getRecord();
        billingWizardURL = EndpointsSettingsHandler.uqtServerEndpoint;
        origin = URL.getOrgDomainUrl().toExternalForm();
        sessionId = SettingsService.getSessionId();
        orderId = orderRecord.Id;
        quoteId = orderRecord.quoteId;
        opportunityId = orderRecord.opportunityId;
    }
}