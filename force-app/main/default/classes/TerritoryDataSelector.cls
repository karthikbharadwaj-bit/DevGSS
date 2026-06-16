public inherited sharing class TerritoryDataSelector extends SObjectSelector {

    public TerritoryDataSelector() {
        super();
    }

    public TerritoryDataSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override SObjectType getSObjectType() {
        return Territory_Data__c.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Territory_Data__c.Id,
            Territory_Data__c.Name,
            Territory_Data__c.CreatedDate,
            Territory_Data__c.LastModifiedDate
        };
    }

    public List<SObjectField> getFieldListToCheckCompanyAndTerritoryOwners() {
        return new List<Schema.SObjectField> {
            Territory_Data__c.Id,
            Territory_Data__c.Name,
            Territory_Data__c.Territory_Owner__c,
            Territory_Data__c.Alternate_Owner__c,
            Territory_Data__c.Country__c,
            Territory_Data__c.State_Province__c,
            Territory_Data__c.Postal_Begin__c,
            Territory_Data__c.Postal_End__c,
            Territory_Data__c.Segment__c,
            Territory_Data__c.Industry__c
        };
    }



    public QueryFactory selectTerritoryDataByCountryStateSegment(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectTerritoryDataByCountryStateSegment')
            .withSelectorFieldsIncluded()
            .selectFields(getFieldListToCheckCompanyAndTerritoryOwners())
            .setCondition('Country__c IN :bind0 AND State_Province__c IN :bind1 AND Segment__c IN :bind2')
            .setQueryBindings(bindings);
    }
}