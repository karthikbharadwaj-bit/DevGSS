public inherited sharing class SetupEntityAccessSelector extends SObjectSelector {
    public SetupEntityAccessSelector() {
        super();
    }

    public SetupEntityAccessSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return SetupEntityAccess.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            SetupEntityAccess.Id,
            SetupEntityAccess.ParentId,
            SetupEntityAccess.SetupEntityType,
            SetupEntityAccess.SetupEntityId
        };
    }

    public QueryFactory selectSetupEntityAccessByParentId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectSetupEntityAccessByParentId')
            .withSelectorFieldsIncluded()
            .setCondition('SetupEntityId =:bind0 AND ParentId IN :bind1')
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings);
    }

    public QueryFactory selectSetupEntityAccessByCustomPermissionName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectSetupEntityAccessByCustomPermissionName')
            .withSelectorFieldsIncluded()
            .setCondition('SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName = :bind0)')
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings);
    }
}