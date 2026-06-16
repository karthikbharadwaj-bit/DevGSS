public inherited sharing class PermissionSetSelector extends SObjectSelector {

    public PermissionSetSelector() {
        super();
    }

    public PermissionSetSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            PermissionSet.Id,
            PermissionSet.Label,
            PermissionSet.Name,
            PermissionSet.ProfileId
        };
    }

    public override Schema.SObjectType getSObjectType()  {
        return PermissionSet.SObjectType;
    }

    public QueryFactory selectPermissionSetByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPermissionSetByIds')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPermissionSetByLabel(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectPermissionSetByLabel')
                .withSelectorFieldsIncluded()
                .selectFields(getDefaultFieldList())
                .withoutSelectorOrderByIncluded()
                .setCondition('Label = :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectPermissionSetsByName(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectPermissionSetsByName')
                .withSelectorFieldsIncluded()
                .selectFields(getDefaultFieldList())
                .withoutSelectorOrderByIncluded()
                .setCondition('Name IN :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectPermissionSetsByPSAssignment(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPermissionSetsByPSAssignment')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }
}