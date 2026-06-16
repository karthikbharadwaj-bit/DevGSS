global with sharing class ProServChangeOrderController {

    public String herokuEndpoint                { get; set; }
    public String origin                        { get; set; }
    public String sessionId                     { get; set; }
    public String accountId                     { get; set; }
    public String currentOrderId                { get; set; }
    public String currentOppName                { get; set; }
    public String contactId                     { get; set; }
    public Boolean isLegacyFlow                 { get; set; }
    public String existingOppId                 { get; set; }
    public Boolean isNotCreateNewChangeOrderOpp { get; set; }

    /**
     * Page Controller
     * @param  stdController
     */
    public ProServChangeOrderController(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>{ 'Account__c' });
        }
        ProServ_Project__c proservProjectRecord = (ProServ_Project__c) stdController.getRecord();
        herokuEndpoint = EndpointsSettingsHandler.uqtServerEndpoint;
        origin = URL.getOrgDomainUrl().toExternalForm();
        sessionId = SettingsService.getSessionId();
        accountId = proservProjectRecord.Account__c;
        Order currentOrder = OrderHelper.getLastCreatedChangeOrder(proservProjectRecord.Id);
        currentOrderId = currentOrder.Id;
        currentOppName = currentOrder.opportunity.Name.toString().escapeHtml4();
        contactId = getContactId(accountId);
        Opportunity existingOpp = OpportunityHelper.getPSChangeOrderOpportunityRecord(currentOrder.Id);
        existingOppId = existingOpp?.Id;
        List<Suborder__c> suborders = getSuborders(currentOrderId);
        isLegacyFlow = suborders.isEmpty();
        isNotCreateNewChangeOrderOpp = SuborderHelper.filterNonBilledSuborders(suborders).isEmpty();
    }


    public String getContactId(String accountId) {
        List<AccountContactRole> primaryAcrList = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRolesByAccountIds(new List<Object>{ accountId })
            .executeQuery();

        if (!primaryAcrList.isEmpty()) {
            return primaryAcrList[0]?.contactId;
        }
        return null;
    }


    public List<Suborder__c> getSuborders(String currentOrderId) {
        return (List<Suborder__c>) new SuborderSelector()
            .selectSubordersByOrdersIds(new Set<Id>{ currentOrderId })
            .executeQuery();
    }
}