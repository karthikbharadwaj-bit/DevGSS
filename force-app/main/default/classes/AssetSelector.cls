public inherited sharing class AssetSelector extends SObjectSelector {
    public AssetSelector() {
        super();
    }

    public AssetSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Asset.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Asset.Id,
            Asset.Delivered_Quantity__c,
            Asset.Product2Id,
            Asset.Quantity
        };
    }

    public QueryFactory selectAssetsByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectAssetsByIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }
}