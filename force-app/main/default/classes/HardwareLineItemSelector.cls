public inherited sharing class HardwareLineItemSelector extends SObjectSelector {
    public HardwareLineItemSelector() {
        super();
    }

    public HardwareLineItemSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Hardware_Line_Item__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Hardware_Line_Item__c.Id,
            Hardware_Line_Item__c.RingCentral_Hardware_Phase__c,
            Hardware_Line_Item__c.Address_Validated__c,
            Hardware_Line_Item__c.Total_Price__c
        };
    }

    public List<String> getFieldsForClose() {
        return new List<String>{
            'Id',
            'Quote_Line_Item__c',
            'Quote_Line_Item__r.Product2.Name',
            'Quantity__c',
            'CurrencyIsoCode',
            'Order_Line_Item__c',
            'Quote_Line_Item__r.Product2.Family',
            'Quote_Line_Item__r.UnitPrice'
        };
    }

    public List<String> getFieldsForPhaseLineItemService() {
        return new List<String>{
            'Id',
            'Name',
            'Quote_Line_Item__c',
            'Quote_Line_Item__r.Product_Lic_Id__c',
            'Quantity__c',
            'ExistingQuantity__c'
        };
    }

    public QueryFactory selectHardwareLineItems() {
        return newQueryFactory()
            .setFactoryName('selectHardwareLineItems')
            .withSelectorFieldsIncluded()
            .withSelectFieldsSorted();
    }

    public QueryFactory selectPhaseLineItemsByPhaseIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectPhaseLineItemsByPhaseIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('RingCentral_Hardware_Phase__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPhaseLineItemsForClose() {
        return newQueryFactory()
            .setFactoryName('selectPhaseLineItemsForClose')
            .selectFields(getFieldsForClose());
    }

    public QueryFactory selectAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAllFieldsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('Hardware_Line_Item__c'))
            .setCondition('Quote_Line_Item__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPhaseLineItemsForDeleting(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPhaseLineItemsForDeleting')
            .selectFields(getDefaultFieldList())
            .setCondition('Id NOT IN :bind0 AND RingCentral_Hardware_Phase__r.Quote__c IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPhaseLineItemsByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPhaseLineItemsByIds')
            .selectFields(getFieldsForPhaseLineItemService())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPhaseLineItems() {
        return newQueryFactory()
            .setFactoryName('selectPhaseLineItems')
            .selectFields(getFieldsForPhaseLineItemService())
            .withoutSelectorOrderByIncluded();
    }
}