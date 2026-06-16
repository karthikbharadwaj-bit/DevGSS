public inherited sharing class OrderItemSelector extends SObjectSelector {
    public static final Set<String> FIELDS_MANUAL_PROVISIONING_CASE_CREATION_PROCESS_MPUB = new Set<String>{
        'Id',
        'Quantity',
        'ChargeTerm__c',
        'UnitPrice',
        'Discount_Number__c',
        'Discount_Type__c',
        'CurrencyIsoCode',
        'Zero_Quantity__c',
        'QuoteLineItemId',
        'QuoteLineItem.Id',
        'QuoteLineItem.Display_Name__c',
        'Product2.InitialOrderType__c',
        'Product2.UpsellType__c',
        'Product2.ExtID__c',
        'Product2.CategoryCode__c',
        'Product2.Description',
        'Order.Account.Payment_Plan__c',
        'Product2.Name'
    };

    public OrderItemSelector() {
        super();
    }

    public OrderItemSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public OrderItemSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public override Schema.SObjectType getSObjectType() {
        return OrderItem.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField>{
            OrderItem.Id,
            OrderItem.QuoteLineItemId,
            OrderItem.OrderId,
            OrderItem.Description,
            OrderItem.PricebookEntryId,
            OrderItem.Product2Id,
            OrderItem.Quantity,
            OrderItem.ServiceDate,
            OrderItem.ListPrice,
            OrderItem.Active__c,
            OrderItem.Asset__c,
            OrderItem.PricebookEntryId,
            OrderItem.Product2Id,
            OrderItem.Quantity,
            OrderItem.TotalPrice,
            OrderItem.UnitPrice,
            OrderItem.UnitPriceWithoutDiscount__c
        };
    }

    public List<String> getFieldsForManualProvisioningCaseCreationProcessMPUB() {
        return new List<String>(FIELDS_MANUAL_PROVISIONING_CASE_CREATION_PROCESS_MPUB);
    }

    public QueryFactory selectOrderItems() {
        return newQueryFactory()
            .setFactoryName('selectOrderItems')
            .withSelectorFieldsIncluded();
    }

    public QueryFactory selectOrderItemsByOrderId(Object orderId) {
        List<Object> bindings = new List<Object>{
            orderId
        };
        return newQueryFactory()
            .setFactoryName('selectOrderItemsByOrderId')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('OrderId = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOrderItemsByOrderIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectOrderItemssByOrderIds')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String>{
                'Quantity',
                'Not_Shipped_Phones__c',
                'QuoteLineItem.MasterQLI__c',
                'QuoteLineItem.Product_Lic_Id__c',
                'QuoteLineItem.Id',
                'QuoteLineItem.Item_Type__c'
            })
            .withoutSelectorOrderByIncluded()
            .setCondition('OrderId IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOrderItemsById(List<Object> orderItemIds) {
        List<Object> bindings = new List<Object>{
            orderItemIds
        };

        return newQueryFactory()
            .setFactoryName('selectOrderItemsById')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String>{
                'Id',
                'TotalPrice',
                'CurrencyIsoCode',
                'Discount_Number__c',
                'QuantityOrThreshold__c',
                'Discount_Type__c',
                'Quantity',
                'Product2Id',
                'Order.Submitted_Date__c',
                'Product2.Sub_Category__c'
            })
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOrderItemsByIdAndExtId(Set<Id> itemIds, String ExtId) {
        return newQueryFactory()
            .setFactoryName('selectOrderItemsByIdAndExtId')
            .selectFields(new List<String>{
                'Quantity',
                'TotalPrice',
                'Product2.ExtID__c',
                'OrderId'
            })
            .setCondition('Id IN :bind0 AND Product2.ExtID__c = :bind1')
            .setQueryBindings(new List<Object>{itemIds, ExtId});
    }

    public QueryFactory selectOrderItemsForManualProvisioningCaseCreationProcessMPUB() {
        return newQueryFactory()
            .setFactoryName('selectOrderItemsForManualProvisioningCaseCreationProcessMPUB')
            .selectFields(getFieldsForManualProvisioningCaseCreationProcessMPUB());
    }

    public QueryFactory selectOrderItemsForPhaseManagement() {
        return newQueryFactory()
            .setFactoryName('selectOrderItemsForPhaseManagement')
            .selectFields(getDefaultFieldList());
    }
}