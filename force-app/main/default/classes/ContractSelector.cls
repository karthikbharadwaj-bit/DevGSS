public with sharing class ContractSelector extends SObjectSelector {

    public ContractSelector() {
        super();
    }

    public ContractSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Contract.Id,
            Contract.Name,
            Contract.AccountId,
            Contract.Status,
            Contract.Previous_Contract__c,
            Contract.Original_Auto_Renewal__c,
            Contract.Original_Start_Date__c,
            Contract.Original_End_Date__c,
            Contract.Original_Initial_Term__c,
            Contract.Original_Renewal_Term__c
        };
    }

    public override Schema.SObjectType getSObjectType()  {
        return Contract.SObjectType;
    }

    public List<Schema.SObjectField> getFieldsForContractManagementBatch() {
        return new List<Schema.SObjectField> {
            Contract.Id,
            Contract.Status,
            Contract.Start_Date__c,
            Contract.End_Date__c,
            Contract.Renewal_Term__c,
            Contract.Original_Contract__c,
            Contract.Previous_Contract__c,
            Contract.AccountId,
            Contract.Original_Signed_Date__c,
            Contract.Source__c,
            Contract.Auto_Renewal__c,
            Contract.Start_Date__c,
            Contract.End_Date__c,
            Contract.Renewal_Term__c,
            Contract.Initial_Term__c,
            Contract.Original_Auto_Renewal__c,
            Contract.Original_Start_Date__c,
            Contract.Original_End_Date__c,
            Contract.Original_Initial_Term__c,
            Contract.Original_Renewal_Term__c
        };
    }

    public List<Schema.SObjectField> getFieldsForCreateNewContract() {
        return new List<Schema.SObjectField> {
            Contract.Id,
            Contract.Status,
            Contract.AccountId,
            Contract.Start_Date__c,
            Contract.End_Date__c,
            Contract.Auto_Renewal__c,
            Contract.Initial_Term__c,
            Contract.Renewal_Term__c,
            Contract.Original_Contract__c,
            Contract.Original_Auto_Renewal__c,
            Contract.Original_End_Date__c,
            Contract.Original_Initial_Term__c,
            Contract.Original_Renewal_Term__c,
            Contract.Original_Start_Date__c,
            Contract.Previous_Contract__c,
            Contract.Original_Signed_Date__c
        };
    }

    public List<String> getRelatedAccountFields() {
        return new List<String>{
            'AccountId',
            'Account.Name'
        };
    }

    public QueryFactory selectContracts() {
        return newQueryFactory()
                .setFactoryName('SelectContractsLimit10')
                .selectFields(getDefaultFieldList())
                .withSelectorFieldsIncluded()
				.withoutSelectorOrderByIncluded()
                .setLimit(10);
    }

    public QueryFactory selectContractsByAccountIds(List<Object> bindings) {
		return newQueryFactory()
				.setFactoryName('selectContractsByAccountIds')
                .withSelectorFieldsIncluded()
				.withoutSelectorOrderByIncluded()
                .setCondition('Status = :bind0 AND Original_Signed_Date__c != NULL AND AccountId IN :bind1')
				.addOrdering('AccountId', QueryFactory.SortOrder.DESCENDING, true)
				.addOrdering('Original_Signed_Date__c', QueryFactory.SortOrder.DESCENDING, true)
                .setQueryBindings(bindings);
    }

    public QueryFactory selectActiveContracts() {
        return newQueryFactory()
            .setFactoryName('selectActiveContracts')
            .selectFields(getDefaultFieldList())
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Status =' + '\'' + DocuSignHelper.CONTRACT_STATUS_ACTIVE + '\'')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING, true);
    }

    public QueryFactory selectActiveContractsWithOriginalSignedDate() {
        return newQueryFactory()
            .setFactoryName('selectActiveContractsWithOriginalSignedDate')
            .selectFields(getDefaultFieldList())
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Status =' + '\'' + DocuSignHelper.CONTRACT_STATUS_ACTIVE + '\'' +
                ' AND Original_Signed_Date__c != NULL')
            .addOrdering('Original_Signed_Date__c', QueryFactory.SortOrder.DESCENDING, true);
    }

    public QueryFactory selectContractsForContractManagementBatch() {
        return newQueryFactory()
            .setFactoryName('selectContractsForContractManagementBatch')
            .selectFields(getFieldsForContractManagementBatch())
            .selectFields(getRelatedAccountFields())
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .subselect(
                new ContractVersionSelector()
                    .selectContractVersions()
                    .addOrdering(ContractVersion__c.VersionNumber__c, QueryFactory.SortOrder.DESCENDING, true)
            )
            .setCondition(
                'Status =' + '\'' + DocuSignHelper.CONTRACT_STATUS_ACTIVE + '\' AND ' +
                'End_Date__c <= TODAY'
            )
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING, true);
    }

    public QueryFactory selectActiveContractsByAccountId(Set<Id> accountIdSet) {
        return newQueryFactory()
            .setFactoryName('selectActiveContractsByAccountId')
            .selectFields(getFieldsForCreateNewContract())
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .subselect(
                new ContractVersionSelector()
                    .selectContractVersions()
                    .addOrdering(ContractVersion__c.VersionNumber__c, QueryFactory.SortOrder.DESCENDING, true)
            )
            .setCondition(
                'Status =' + '\'' + DocuSignHelper.CONTRACT_STATUS_ACTIVE + '\' AND ' +
                'AccountId IN :bind0'
            )
            .setQueryBindings(new List<Object>{ accountIdSet });
    }

    public QueryFactory selectContractsByAccountId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContractsByAccountId')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId IN :bind0')
            .setQueryBindings(bindings);
    }
}