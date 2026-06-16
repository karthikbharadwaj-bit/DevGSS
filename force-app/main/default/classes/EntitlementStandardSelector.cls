public with sharing class EntitlementStandardSelector extends SObjectSelector {
    public EntitlementStandardSelector() {
        super();
    }
    public EntitlementStandardSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Entitlement.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Entitlement.Name,
            Entitlement.Type,
            Entitlement.AccountId,
            Entitlement.SlaProcessId,
            Entitlement.StartDate,
            Entitlement.Status,
            Entitlement.BusinessHoursId
        };
    }

    public QueryFactory selectEntitlementsUnderAccounts(Set<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectEntitlementsUnderAccounts')
            .setCondition('Name =:bind0')
            .withSelectorFieldsIncluded()
            .setQueryCaching(true)
            .setQueryBindings(new List<Object>{accountIds});
    }
}