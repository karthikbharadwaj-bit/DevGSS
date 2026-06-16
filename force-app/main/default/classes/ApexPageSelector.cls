public inherited sharing class ApexPageSelector extends SObjectSelector {
    public ApexPageSelector() {
        super();
    }

    public ApexPageSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return ApexPage.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            ApexPage.Id,
            ApexPage.Name
        };
    }

    public QueryFactory selectApexPageByNameAndIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectApexPagesByName')
            .withSelectorFieldsIncluded()
            .setCondition('Name =:bind0 AND Id IN :bind1')
            .setQueryBindings(bindings);
    }
}