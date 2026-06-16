public inherited sharing class ProductDetailSelector extends SObjectSelector {

    public ProductDetailSelector() {
        super();
    }

    public ProductDetailSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return ProductDetail__c.SObjectType;
    }

    public List<String> getFieldList() {
        return new List<String>{
            'Id',
            'Name',
            'QuantityOrThreshold__c',
            'ProductDetail__c',
            'RampUpStartDate__c',
            'Entitlement__c',
            'OrderItem__c',
            'OrderItem__r.RC_Entitlement__c',
            'OrderItem__r.Product2.Sub_Category__c',
            'OrderItem__r.Order.Submitted_Date__c',
            'RampUp__c'
        };
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            ProductDetail__c.Id,
            ProductDetail__c.Entitlement__c,
            ProductDetail__c.OrderItem__c,
            ProductDetail__c.QuantityOrThreshold__c,
            ProductDetail__c.RampUp__c,
            ProductDetail__c.RampUpStartDate__c,
            ProductDetail__c.ProductDetail__c
        };
    }

    public QueryFactory selectProductDetails() {
        return newQueryFactory()
            .setFactoryName('selectProductDetails')
            .withSelectorFieldsIncluded();
    }

    public QueryFactory selectEntitlementProductDetailsByAccountIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectEntitlementProductDetailsByAccountIds')
            .selectFields(new List<String>{
                'LastModifiedDate',
                'Entitlement__r.Name',
                'Entitlement__r.Price__c',
                'Entitlement__r.CurrencyIsoCode',
                'Entitlement__r.Discount__c',
                'Entitlement__r.Discount_Type__c',
                'Entitlement__r.Quantity__c',
                'Entitlement__r.Product__c',
                'Entitlement__r.Product__r.Name',
                'Entitlement__r.Product__r.Family',
                'Entitlement__r.Product__r.Product_Type__c',
                'Entitlement__r.Product__r.Parent__c',
                'Entitlement__r.Product__r.ExtId__c'
            })
            .setCondition('Entitlement__c IN (SELECT Id FROM Entitlement__c WHERE Account__c IN :bind0 '
                + 'AND Active__c = true AND Product__r.Charge_Term__c != \'One - Time\') AND isActive__c = true')
            .withSelectorFieldsIncluded()
            .addOrdering('Entitlement__c', QueryFactory.SortOrder.ASCENDING)
            .addOrdering('RampUpStartDate__c', QueryFactory.SortOrder.DESCENDING)
            .addOrdering('Name', QueryFactory.SortOrder.ASCENDING)
            .setQueryBindings(bindings);
        }
            
        public QueryFactory selectOrderProductDetailsByOrderIds(List<Object> bindings) {
            return newQueryFactory()
            .setFactoryName('selectOrderProductDetailsByOrderIds')
            .selectFields(new List<String>{
                'ProductDetail__c',
                'ProductDetail__r.Entitlement__c',
                'ProductDetail__r.LastModifiedDate',
                'OrderItem__r.TotalPrice',
                'OrderItem__r.CurrencyIsoCode',
                'OrderItem__r.Discount_Number__c',
                'OrderItem__r.Discount_Type__c',
                'OrderItem__r.Quantity',
                'OrderItem__r.Product2Id',
                'OrderItem__r.Product2.Family',
                'OrderItem__r.Product2.Name',
                'OrderItem__r.Product2.Product_Type__c',
                'OrderItem__r.Product2.Parent__c',
                'OrderItem__r.Active__c',
                'OrderItem__r.RC_Entitlement__c',
                'OrderItem__r.Product2.ExtId__c',
                'OrderItem__r.Order.CC_Order_Type__c',
                'OrderItem__r.Order.Opportunity.Brand_Name__c'
            })
            .setCondition('OrderItem__r.OrderId IN :bind0 '
                + 'AND OrderItem__r.Product2.Charge_Term__c != \'One - Time\'')
            .withSelectorFieldsIncluded()
            .setQueryBindings(bindings);
    }
}