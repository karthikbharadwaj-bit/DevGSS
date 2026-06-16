public inherited sharing class StdEntitlementSelector extends SObjectSelector {
    public StdEntitlementSelector() {
        super();
    }

    public StdEntitlementSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Entitlement.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Entitlement.Id,
            Entitlement.Name,
            Entitlement.SlaProcessId,
            Entitlement.AccountId
        };
    }

    public QueryFactory selectStdEntitlements() {
        return newQueryFactory().setFactoryName('selectStdEntitlements');
    }
}