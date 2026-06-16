public with sharing class MarketingAssetSelector extends SObjectSelector {

    public MarketingAssetSelector() {
        super();
    }

    public MarketingAssetSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Marketing_Asset__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Marketing_Asset__c.Id,
            Marketing_Asset__c.Asset_ID__c,
            Marketing_Asset__c.Name,
            Marketing_Asset__c.Type__c,
            Marketing_Asset__c.Name
        };
    }

    public List<Schema.SObjectField> getOtherFieldList() {
        return new List<Schema.SObjectField> {};
    }

    public QueryFactory selectMarketingAssetById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectMarketingAssetById')
            .withSelectorFieldsIncluded()
            .selectFields(getOtherFieldList())
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectMarketingAssetByName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectMarketingAssetByName')
            .withSelectorFieldsIncluded()
            .selectFields(getOtherFieldList())
            .setCondition('Name = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectMarketingAssetByAssetId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectMarketingAssetByAssetId')
            .withSelectorFieldsIncluded()
            .selectFields(getOtherFieldList())
            .setCondition('Asset_ID__c = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public override String getOrderBy()
    {
        return 'CreatedDate DESC';
    }


    public QueryFactory selectMarketingAssets() {
        return newQueryFactory()
            .setFactoryName('SelectMarketingAssets')
            .withSelectorFieldsIncluded()
            .withSelectFieldsSorted()
            .setLimit(1);
    }

    public QueryFactory selectMarketingAssetsByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectMarketingAssetsByIds')
            .withSelectorFieldsIncluded()
            .selectFields(getOtherFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectActiveMarketingAssetsByAssetIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectMarketingAssetsByIds')
            .withSelectorFieldsIncluded()
            .selectFields(getOtherFieldList())
            .setCondition('Active__c = true AND Asset_ID__c IN :bind0')
            .setQueryBindings(bindings);
    }



}