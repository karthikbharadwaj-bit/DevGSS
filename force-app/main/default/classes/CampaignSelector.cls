public inherited sharing class CampaignSelector extends SObjectSelector {

    public CampaignSelector() {
        super();
    }

    public CampaignSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override SObjectType getSObjectType() {
        return Campaign.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Campaign.Id,
            Campaign.BMID__c,
            Campaign.Non_Attributable__c,
            Campaign.Shared_Lead_Campaign__c,
            Campaign.Channel__c,
            Campaign.Sub_Channel__c,
            Campaign.Name
        };
    }

    public List<String> getLeadSearchExtensionFields(){
        return new List<String> {
            'DNIS__c',
            'AID__c',
            'PID__c',
            'Description',
            'Name',
            'Intended_Product__c'
        };
    }

    public QueryFactory selectCampaignForLeadSearch_ByCreatedDate(List<Object> bindings){
        return newQueryFactory()
                        .setFactoryName('selectCampaignForLeadSearchByCreatedDate')
                        .withSelectorFieldsIncluded()
                        .selectFields(getLeadSearchExtensionFields())
                        .setCondition('DNIS__c = :bind0')
                        .withoutSelectorOrderByIncluded()
                        .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
                        .setQueryBindings(bindings);
    }

    public QueryFactory selectCampaignsByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCampaignsByIds')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCampaignsByName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCampaignsByName')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .selectFields(getLeadSearchExtensionFields())
            .setCondition('Name = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCampaignsByNameLike(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCampaignsByNameLike')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .selectFields(getLeadSearchExtensionFields())
            .setCondition('Name LIKE :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCampaignsByBMID(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCampaignsByBMID')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('BMID__c = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCampaignByBMID(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCampaignByBMID')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .selectFields(getLeadSearchExtensionFields())
            .selectField(Campaign.LastModifiedDate)
            .setCondition('BMID__c = :bind0')
            .withoutSelectorOrderByIncluded()
            .addOrdering('LastModifiedDate',QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }
    
    public QueryFactory selectCampaignByDNIS(List<Object> bindings){
        return newQueryFactory()
            .setFactoryName('selectCampaignByDNIS')
            .withSelectorFieldsIncluded()
            .selectFields(getLeadSearchExtensionFields())
            .setCondition('DNIS__c = :bind0')
            .withoutSelectorOrderByIncluded()
            .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings)
            .setLimit(1);
    }

    public QueryFactory selectActiveCampaignByBMID(List<Object> bindings){
        return newQueryFactory()
            .setFactoryName('selectActiveCampaignByBMID')
            .withSelectorFieldsIncluded()
            .selectFields(getLeadSearchExtensionFields())
            .setCondition('IsActive = true AND BMID__c = :bind0')
            .withoutSelectorOrderByIncluded()
            .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings)
            .setLimit(1);
    }
}