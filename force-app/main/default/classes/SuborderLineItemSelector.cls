public inherited sharing class SuborderLineItemSelector extends SObjectSelector {

    public SuborderLineItemSelector() {
        super();
    }

    public SuborderLineItemSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public SuborderLineItemSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return SuborderLineItem__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            SuborderLineItem__c.Id,
            SuborderLineItem__c.SalesAgreementLineItem__c,
            SuborderLineItem__c.Suborder__c,
            SuborderLineItem__c.Quantity__c,
            SuborderLineItem__c.LocationDetails__c
        };
    }

    public List<String> getDefaultProServFieldList() {
        return new List<String> {
            'Id',
            'Suborder__c',
            'Quantity__c',
            'SalesAgreementLineItem__c',
            'SalesAgreementLineItem__r.Product_Lic_Id__c',
            'SalesAgreementLineItem__r.ChargeTerm__c',
            'SalesAgreementLineItem__r.EffectivePriceNew__c',
            'SalesAgreementLineItem__c.Product2Id',
            'LocationDetails__c',
            'CurrencyIsoCode',
            'SalesAgreementLineItem__r.EffectivePrice__c',
            'SalesAgreementLineItem__r.UnitPrice'
        };
    }

    public QueryFactory selectSuborderLineItems() {
        return newQueryFactory()
            .setFactoryName('selectSuborderLineItems')
            .withSelectorFieldsIncluded();
    }

    public QueryFactory selectSuborderLineItemsForProServ() {
        return newQueryFactory()
            .setFactoryName('selectSuborderLineItemsForProServ')
            .selectFields(getDefaultProServFieldList());
    }

    public QueryFactory selectSuborderLineItemsBySuborderIds(Set<Id> ordersIds) {
        return newQueryFactory()
            .setFactoryName('selectSuborderLineItemsBySuborderIds')
            .selectFields(getDefaultProServFieldList())
            .setCondition('Suborder__c IN :bind0')
            .setQueryBindings(new List<Object>{ordersIds});
    }

    public QueryFactory selectSuborderLineItemsForDeleting(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectSuborderLineItemsForDeleting')
            .selectFields(getDefaultFieldList())
            .setCondition('Id NOT IN :bind0 AND Suborder__r.Order__c IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectSuborderLineItemsByIds(List<Id> ids) {
        return newQueryFactory()
            .setFactoryName('selectSuborderLineItemsByIds')
            .selectFields(getDefaultProServFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{ids});
    }
}