public inherited sharing class Pricebook2Selector extends SObjectSelector {

    public Pricebook2Selector() {
        super();
    }

    public Pricebook2Selector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Pricebook2.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Pricebook2.Id
        };
    }

    public List<Schema.SObjectField> getFieldsForLeadConvert() {
        return new List<Schema.SObjectField> {
            Pricebook2.Edition__c,
            Pricebook2.Plan__c,
            Pricebook2.Brand__c,
            Pricebook2.Service__c
        };
    }

    public QueryFactory getStandardPricebook() {
        return newQueryFactory()
            .setCondition('IsStandard = TRUE')
            .setLimit(1);
    }

    public QueryFactory getPricebookForLeadConvert(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('GetPricebookForLeadConvert')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted()
            .selectFields(getFieldsForLeadConvert())
            .selectFields(new List<String>{'Brand__r.Name'})
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPricebooks() {
        return newQueryFactory()
            .setFactoryName('SelectPricebooks')
            .withSelectorFieldsIncluded()
            .withSelectFieldsSorted();
    }

    public QueryFactory selectUniversalProservPricebook(String oppCurrency) {
        return newQueryFactory()
            .setFactoryName('selectUniversalProservPricebook')
            .withSelectorFieldsIncluded()
            .setCondition(
                'IsActive = true AND ' +
                'ExtID__c LIKE \'ProServ_Universal%\' AND ' +
                'CurrencyIsoCode = :bind0 '
            )
            .setQueryBindings(new List<Object>{oppCurrency});
    }

    public QueryFactory selectUniversalCCProservPricebook(String oppCurrency) {
        return newQueryFactory()
            .setFactoryName('selectUniversalCCProservPricebook')
            .withSelectorFieldsIncluded()
            .setCondition(
                'IsActive = true AND ' +
                'ExtID__c LIKE \'CC_ProServ_Universal%\' AND ' +
                'CurrencyIsoCode = :bind0 '
            )
            .setQueryBindings(new List<Object>{oppCurrency});
    }
}