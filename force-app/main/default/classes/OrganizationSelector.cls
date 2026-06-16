public inherited sharing class OrganizationSelector extends SObjectSelector {
    public OrganizationSelector() {
        super();
    }

    public OrganizationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return Organization.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Organization.Id,
            Organization.IsSandbox
        };
    }

    public QueryFactory selectOrg() {
        return newQueryFactory()
            .setFactoryName('SelectOrganization')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setLimit(1);
    }
}