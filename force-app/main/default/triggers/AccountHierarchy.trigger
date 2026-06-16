trigger AccountHierarchy on Account_Hierarchy__c (
        before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if (bypassTrigger != null && bypassTrigger.Bypass_Company_Trigger__c == true) {
        System.debug('$$$ ByPassTrigger__c Active For Company $$$');
        return;
    }

    new Triggers()
            .bind(Triggers.Evt.beforeinsert, new AccountHierarchyTriggerHelper.CheckCompanyAndTerritoryOwners())
            .bind(Triggers.Evt.beforeinsert, new AccountHierarchyTriggerHelper.AccountHierarchyBefore())
            
            .bind(Triggers.Evt.beforeupdate, new AccountHierarchyTriggerHelper.CheckCompanyAndTerritoryOwners())
            .bind(Triggers.Evt.beforeupdate, new AccountHierarchyTriggerHelper.AccountHierarchyBefore())

            .bind(Triggers.Evt.afterupdate, new AccountHierarchyTriggerHelper.UpdateTargetAccounts())
            .bind(Triggers.Evt.afterupdate, new AccountHierarchyTriggerHelper.UpdateInvoiceRequests())

            .manage();
}