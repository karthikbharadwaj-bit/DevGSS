public inherited sharing class DatedConversionRateSelector extends SObjectSelector {
    public DatedConversionRateSelector() {
        super();
    }

    public DatedConversionRateSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return DatedConversionRate.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            DatedConversionRate.Id, 
            DatedConversionRate.IsoCode, 
            DatedConversionRate.ConversionRate, 
            DatedConversionRate.StartDate, 
            DatedConversionRate.NextStartDate
        };
    }

    public QueryFactory selectConversionRateByDate(Date minDate, Date maxDate) {
        return newQueryFactory()
            .setFactoryName('selectConversionRateByDate')
            .withSelectorFieldsIncluded()
            .setCondition('StartDate <= :bind1 AND NextStartDate >= :bind0')
            .setQueryBindings(new List<Object>{minDate, maxDate});
    }

    public QueryFactory selectLatestConversionsRates() {
        return newQueryFactory()
            .setFactoryName('selectConversionRateByDate')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING);
    }

}