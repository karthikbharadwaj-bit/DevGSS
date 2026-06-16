public with sharing class StaticResourceSelector extends SObjectSelector {
    public StaticResourceSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return StaticResource.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField>{ 
            StaticResource.Id, 
            StaticResource.Body, 
            StaticResource.Name 
        };
    }

    public QueryFactory selectStaticResourceByName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectStaticResourceByName')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Name = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }
    
    public QueryFactory selectStaticResourceByNames(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectStaticResourceByName')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Name IN :bind0')
            .setQueryBindings(bindings);
    }
}