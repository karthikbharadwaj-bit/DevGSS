public inherited sharing class SupportEntitlementSelector extends SObjectSelector {

    public static final List<String> DEFAULT_SUPPORT_ENTITLEMENT_FIELDS = new List<String> {
        'Id',
        'AccountId',
        'Type',
        'Status',
        'StartDate',
        'EndDate',
        'Name',
        'Product__c'
    };

    public SupportEntitlementSelector() {
        super();
    }

    public SupportEntitlementSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Entitlement.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {};
    }

    public QueryFactory selectSupportEntitlements() {
        return newQueryFactory()
            .setFactoryName('selectSupportEntitlements')
            .selectField(Entitlement.Id)
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectSupportEntitlementsByAccountIds(Set<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectSupportEntitlementsByAccountIds')
            .selectFields(DEFAULT_SUPPORT_ENTITLEMENT_FIELDS)
            .addCondition('AccountId IN :bind0 AND StartDate <= TODAY AND EndDate = null')
            .setQueryBindings(new List<Object>{accountIds})
            .withoutSelectorOrderByIncluded();
    }
}