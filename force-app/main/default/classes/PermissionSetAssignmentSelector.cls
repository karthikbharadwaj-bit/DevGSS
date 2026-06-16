public inherited sharing class PermissionSetAssignmentSelector extends SObjectSelector {

    public PermissionSetAssignmentSelector() {
        super();
    }

    public PermissionSetAssignmentSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            PermissionSetAssignment.PermissionSetId,
            PermissionSetAssignment.AssigneeId
        };
    }

    public override Schema.SObjectType getSObjectType()  {
        return PermissionSetAssignment.SObjectType;
    }

    public QueryFactory selectPermissionSetAssignmentByLabel(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPermissionSetAssignmentByLabel')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('PermissionSet.Label = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPermissionSetAssignmentByName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPermissionSetAssignmentByName')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('PermissionSet.Name = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPSABasedOnAssigneeAndLabel(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPermissionSetAssignmentByLabel')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('AssigneeId = :bind0 AND PermissionSet.Label = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPSABasedOnAssigneeAndPermissionSet(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPSABasedOnAssigneeAndPermissionSet')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('AssigneeId IN :bind0 AND PermissionSetId IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPSABasedOnAssignee(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPSABasedOnAssignee')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('AssigneeId =:bind0')
            .setQueryBindings(bindings);
    }
}