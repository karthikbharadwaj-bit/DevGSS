public with sharing class AssetTouchSelector extends SObjectSelector {
	public AssetTouchSelector() {
      super();
  }

  public AssetTouchSelector(Boolean enforceCRUD, Boolean enforceFLS) {
      super(enforceCRUD, enforceFLS);
  }

  public override Schema.SObjectType getSObjectType()  {
      return Asset_Touch__c.SObjectType;
  }

  public override List<Schema.SObjectField> getDefaultFieldList() {
    return new List<Schema.SObjectField> {
      Asset_Touch__c.Id,
      Asset_Touch__c.Marketing_Asset__c,
      Asset_Touch__c.Lead__c,
      Asset_Touch__c.Contact__c,
      Asset_Touch__c.Asset_Touch_DateTime__c
    };
  }

  public QueryFactory selectAssetsForSubquery() {
      return newQueryFactory()
	      .setFactoryName('selectAssetsForSubquery')
        .selectField('Marketing_Asset__r.Asset_ID__c')
	      .addOrdering(new QueryFactory.Ordering('Asset_Touch__c','Asset_Touch_DateTime__c',QueryFactory.SortOrder.DESCENDING))
	     	.setLimit(1)
	      .withSelectorFieldsIncluded();
  }

  public QueryFactory selectAssetsByLead(List<Object> bindings) {
      return newQueryFactory()
	      .setFactoryName('selectAssetsByLead')
	      .withSelectorFieldsIncluded()
	      .setCondition('Lead__c IN :bind0')
	      .setQueryBindings(bindings);
  }
}