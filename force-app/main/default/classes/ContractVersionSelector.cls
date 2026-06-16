public with sharing class ContractVersionSelector  extends SObjectSelector {

    public ContractVersionSelector() {
        super();
    }

    public ContractVersionSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return ContractVersion__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            ContractVersion__c.Name,
            ContractVersion__c.Contract__c,
            ContractVersion__c.AutoRenewal__c,
            ContractVersion__c.StartDate__c,
            ContractVersion__c.EndDate__c,
            ContractVersion__c.InitialTerm__c,
            ContractVersion__c.RenewalTerm__c,
            ContractVersion__c.Status__c,
            ContractVersion__c.VersionNumber__c,
            ContractVersion__c.CreatedDate,
            ContractVersion__c.LastModifiedDate
        };
    }

    public QueryFactory selectContractVersions() {
        return newQueryFactory()
            .setFactoryName('selectContractVersions')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectContractVersionByAccountId(Set<Id> accountIdSet, Integer offSetSize, Integer queryLimit) {
        return newQueryFactory()
                .setFactoryName('selectContractVersionByAccountId')
                .selectFields(getDefaultFieldList())
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .setQueryBindings(accountIdSet)
                .setCondition('Contract__r.AccountId IN :bind0')
                .addOrdering(ContractVersion__c.VersionNumber__c, QueryFactory.SortOrder.DESCENDING, true)
                .setLimit(queryLimit)
                .setOffset(offSetSize);
    }

    public QueryFactory selectContractVersionByAccountId(Set<Id> accountIdSet) {
        return newQueryFactory()
                .setFactoryName('selectContractVersionByAccountId')
                .selectFields(getDefaultFieldList())
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .setQueryBindings(accountIdSet)
                .setCondition('Contract__r.AccountId IN :bind0')
                .addOrdering(ContractVersion__c.VersionNumber__c, QueryFactory.SortOrder.DESCENDING, true);
    }

}