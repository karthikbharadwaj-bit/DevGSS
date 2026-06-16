public inherited sharing class ImplementationSelector extends SObjectSelector {

    public ImplementationSelector() {
        super();
    }

    public ImplementationSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public ImplementationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Implementation__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Implementation__c.Id,
            Implementation__c.Account__c,
            Implementation__c.Type__c,
            Implementation__c.Implementation_Status__c
        };
    }

    public List<String> getStatusFieldList() {
        return new List<String> {
            'Id',
            'Name',
            'Implementation_Status__c',
            'Implementation_Status_2__c',
            'Implementation_Type__c',
            'OwnerId',
            'CreatedDate',
            'Account__c',
            'Account__r.Implementation_Status__c',
            'Account__r.RC_Account_Status__c'
        };
    }

    public QueryFactory selectImplementations() {
        return newQueryFactory()
            .setFactoryName('selectImplementations')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectImplementationForAccount() {
        return newQueryFactory()
            .setFactoryName('selectImplementationForAccount')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition(
                'Type__c = \'New\' AND Implementation_Status__c != \'6a. Completed\' ' +
                'AND Implementation_Status__c != \'6b. Completed - No Help Needed\''
            )
            .setLimit(1);
    }

    public QueryFactory selectImplementationsWithStatusFields(List<Object> bindings){
        return newQueryFactory()
            .setFactoryName('selectImplementationsWithStatusFields')
            .withoutSelectorFieldsIncluded()
            .selectFields(getStatusFieldList())
            .setCondition('Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectImplementationsByAccountIds(Set<Id> accIds){
        return selectImplementationsWithStatusFields(new List<Object> {accIds})
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING);
    }
}