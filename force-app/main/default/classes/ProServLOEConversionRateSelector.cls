public inherited sharing class ProServLOEConversionRateSelector extends SObjectSelector {
    public ProServLOEConversionRateSelector() {
        super();
    }

    public ProServLOEConversionRateSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return ProServ_LOE_Conversion_Rate__mdt.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            ProServ_LOE_Conversion_Rate__mdt.Id,
            ProServ_LOE_Conversion_Rate__mdt.LOE_Conversion_Rate__c,
            ProServ_LOE_Conversion_Rate__mdt.Project_Complexity__c
        };
    }

    public QueryFactory selectProServLOEConversionRates() {
        return newQueryFactory()
            .setFactoryName('selectProServLOEConversionRates')
            .withSelectorFieldsIncluded()
            .setQueryCaching(true)
            .withoutSelectorOrderByIncluded();
    }
}