public inherited sharing class CurrencyTypeSelector extends SObjectSelector {
    public CurrencyTypeSelector() {
        super();
    }

    public CurrencyTypeSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return CurrencyType.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            CurrencyType.Id,
            CurrencyType.IsoCode,
            CurrencyType.ConversionRate
        };
    }

    public QueryFactory selectActiveCurrencyTypes() {
        return newQueryFactory()
            .setFactoryName('selectActiveCurrencyTypes')
            .withSelectorFieldsIncluded()
            .setCondition('IsActive = true')
            .setQueryCaching(true)
            .withoutSelectorOrderByIncluded();
    }
}