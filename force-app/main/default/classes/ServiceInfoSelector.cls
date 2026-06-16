public inherited sharing class ServiceInfoSelector extends SObjectSelector {
    public ServiceInfoSelector() {
        super();
    }

    public ServiceInfoSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public ServiceInfoSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public override Schema.SObjectType getSObjectType()  {
        return ServiceInfo__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            ServiceInfo__c.Id,
            ServiceInfo__c.Quote__c,
            ServiceInfo__c.BillingPackage__c,
            ServiceInfo__c.IsProcessOrderSent__c,
            ServiceInfo__c.IsDownsellCaseCreated__c,
            ServiceInfo__c.IsTermination__c
        };
    }

    public List<Schema.SObjectField> getFieldsForClone() {
        return new List<Schema.SObjectField> {
            ServiceInfo__c.BillingPackage__c,
            ServiceInfo__c.ChargeTermStepStatus__c,
            ServiceInfo__c.ContractCancellationStepStatus__c,
            ServiceInfo__c.ContractStepStatus__c,
            ServiceInfo__c.DownsellStepStatus__c,
            ServiceInfo__c.DiscountStepStatus__c,
            ServiceInfo__c.FSCStepStatus__c,
            ServiceInfo__c.ICBProvisioningStepStatus__c,
            ServiceInfo__c.ICBSyncStepStatus__c,
            ServiceInfo__c.Id,
            ServiceInfo__c.InvoiceStepStatus__c,
            ServiceInfo__c.IsProcessOrderSent__c,
            ServiceInfo__c.IsResyncContractAllowed__c,
            ServiceInfo__c.LicenseLimitsStepStatus__c,
            ServiceInfo__c.LogInfo__c,
            ServiceInfo__c.NGBSSyncExecutorInfo__c,
            ServiceInfo__c.OrderDate__c,
            ServiceInfo__c.OrderStepStatus__c,
            ServiceInfo__c.Quote__c,
            ServiceInfo__c.RepriceStepStatus__c,
            ServiceInfo__c.SpendingLimitRetrieveStepStatus__c,
            ServiceInfo__c.SyncInfo__c,
            ServiceInfo__c.IsTermination__c,
            ServiceInfo__c.TerminationStepStatus__c,
            ServiceInfo__c.UpgradeStepStatus__c,
            ServiceInfo__c.UpsellStepStatus__c
        };
    }

    public List<Schema.SObjectField> getNGBSSyncablesFieldList() {
        return new List<Schema.SObjectField> {
            ServiceInfo__c.ChargeTermStepStatus__c,
            ServiceInfo__c.ContractCancellationStepStatus__c,
            ServiceInfo__c.ContractStepStatus__c,
            ServiceInfo__c.DownsellStepStatus__c,
            ServiceInfo__c.DiscountStepStatus__c,
            ServiceInfo__c.FSCStepStatus__c,
            ServiceInfo__c.ICBProvisioningStepStatus__c,
            ServiceInfo__c.ICBSyncStepStatus__c,
            ServiceInfo__c.InvoiceStepStatus__c,
            ServiceInfo__c.IsResyncContractAllowed__c,
            ServiceInfo__c.LicenseLimitsStepStatus__c,
            ServiceInfo__c.NGBSSyncExecutorInfo__c,
            ServiceInfo__c.OrderDate__c,
            ServiceInfo__c.OrderStepStatus__c,
            ServiceInfo__c.RepriceStepStatus__c,
            ServiceInfo__c.SpendingLimitRetrieveStepStatus__c,
            ServiceInfo__c.SyncInfo__c,
            ServiceInfo__c.TerminationStepStatus__c,
            ServiceInfo__c.UpgradeStepStatus__c,
            ServiceInfo__c.UpsellStepStatus__c
        };
    }

    public List<String> selectServiceInfoFieldsForInvoiceSync() {
        return new List<String> {
            'BillingPackage__r.Account_Package_Id__c'
        };
    }

    public List<String> getFieldsForSetPrimaryQuote() {
        return new List<String> {
            'Quote__r.MasterQuote__c'
        };
    }

    public QueryFactory selectServiceInfo() {
        return newQueryFactory()
            .setFactoryName('selectServiceInfo')
            .selectFields(getDefaultFieldList())
            .selectFields(selectServiceInfoFieldsForInvoiceSync());
    }

    public QueryFactory selectServiceInfoForSync(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectServiceInfoForUpsertUB')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .selectFields(selectServiceInfoFieldsForInvoiceSync())
            .setCondition('Quote__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectServiceInfoForClear(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectServiceInfoForClear')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('Quote__c = :bind0 or Quote__r.MasterQuote__c = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectServiceInfoForClone(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectServiceInfoForClone')
            .withSelectorFieldsIncluded()
            .selectFields(getFieldsForClone())
            .selectFields(getFieldsForSetPrimaryQuote())
            .setCondition('Quote__c = :bind0 or Quote__r.MasterQuote__c = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectServiceInfoForTerminationCheck(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectServiceInfoForTerminationCheck')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .selectField('Quote__r.OpportunityId')
            .setCondition('Quote__r.OpportunityId IN :bind0 AND (Quote__r.isPrimary__c = true OR Quote__r.MasterQuote__r.isPrimary__c = true)')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectServiceInfoForNGBSSyncablesByQuoteId(Id quoteId) {
        return newQueryFactory()
            .setFactoryName('selectServiceInfoForNGBSSyncablesByQuoteId')
            .withSelectorFieldsIncluded()
            .selectFields(getNGBSSyncablesFieldList())
            .setCondition('Quote__c IN :bind0')
            .setQueryBindings(new List<Object> {new Set<Id> {quoteId}});
    }

    public QueryFactory selectServiceInfoForNGBSSyncablesById(Id serviceInfoId) {
        return newQueryFactory()
            .setFactoryName('selectServiceInfoForNGBSSyncablesById')
            .selectFields(getNGBSSyncablesFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> {new Set<Id> {serviceInfoId}});
    }
    
}