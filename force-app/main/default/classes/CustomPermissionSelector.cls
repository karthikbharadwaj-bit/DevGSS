public inherited sharing class CustomPermissionSelector extends SObjectSelector {
    public CustomPermissionSelector() {
        super();
    }

    public CustomPermissionSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return CustomPermission.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            CustomPermission.Id,
            CustomPermission.DeveloperName
        };
    }

    public QueryFactory selectCustomPermissions() {
        return newQueryFactory()
            .setFactoryName('selectCustomPermissions')
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectCustomPermissionsByDeveloperName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCustomPermissionsByDeveloperName')
            .withSelectorFieldsIncluded()
            .setCondition('DeveloperName = :bind0')
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings);
    }
}