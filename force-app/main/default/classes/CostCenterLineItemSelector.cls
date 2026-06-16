public inherited sharing class CostCenterLineItemSelector extends SObjectSelector {

    public CostCenterLineItemSelector() {
        super();
    }

    public CostCenterLineItemSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Cost_Center_Line_Item__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Cost_Center_Line_Item__c.Id,
            Cost_Center_Line_Item__c.Cost_Center__c,
            Cost_Center_Line_Item__c.Quantity__c,
            Cost_Center_Line_Item__c.Quote_Line_Item__c
        };
    }

    public List<String> getFieldListForCloning() {
        return new List<String> {
            'AreaCode__c',
            'BundleElementId__c',
            'Cost_Center__c',
            'ElementId__c',
            'Parent__c',
            'Quantity__c',
            'SortOrder__c',
            'Quote_Line_Item__c',
            'Quote_Line_Item__r.IsMultiProductTechnicalQLI__c',
            'Quote_Line_Item__r.MasterQLI__c'
        };
    }

    public List<String> getFieldList() {
        return new List<String>{
            'Id',
            'Cost_Center__c',
            'Quantity__c',
            'Quote_Line_Item__c',
            'Cost_Center__r.AddressId__c',
            'Cost_Center__r.Billing_Code_Path__c',
            'Cost_Center__r.BillingId__c',
            'Cost_Center__r.Cost_Center_Parent__c',
            'Cost_Center__r.Country__c',
            'Cost_Center__r.Parent_Billing_Id__c',
            'Cost_Center__r.Quote__c',
            'Cost_Center__r.Tax_Location__c'
        };
    }

    public List<String> getFieldListForOrderAPI() {
        return new List<String>{
            'Id',
            'Cost_Center__c',
            'Quantity__c',
            'Quote_Line_Item__c',
            'Parent__c',
            'Parent__r.Quantity__c',
            'Cost_Center__r.AddressId__c',
            'Cost_Center__r.Billing_Code_Path__c',
            'Cost_Center__r.BillingId__c',
            'Cost_Center__r.Cost_Center_Parent__c',
            'Cost_Center__r.Country__c',
            'Cost_Center__r.Parent_Billing_Id__c',
            'Cost_Center__r.Quote__c',
            'Cost_Center__r.Tax_Location__c'
        };
    }

    public List<String> getFieldsForCloseValidation() {
        return new List<String>{
            'Id',
            'Quantity__c',
            'Parent__c',
            'Quote_Line_Item__c',
            'Quote_Line_Item__r.Product2Id',
            'Quote_Line_Item__r.Product2.Feature__c',
            'Quote_Line_Item__r.Product2.Family'
        };
    }

    public QueryFactory selectCostCentersLineItemsData() {
        return newQueryFactory()
            .setFactoryName('selectCostCentersLineItemsData')
            .selectFields(getFieldListForOrderAPI());
    }

    public QueryFactory selectCostCentersLineItemsForCloseValidation(Set<Id> qlIdSet) {
        return newQueryFactory()
            .setFactoryName('selectCostCentersLineItemsForCloseValidation')
            .selectFields(getFieldsForCloseValidation())
            .setCondition('Quote_Line_Item__c IN :bind0')
            .setQueryBindings(new List<Object>{ qlidSet });
    }

    public QueryFactory selectAllFieldsForCloning(Set<Id> qlIdSet) {
        return newQueryFactory()
            .setFactoryName('selectAllFieldsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('Cost_Center_Line_Item__c'))
            .setCondition('Quote_Line_Item__c IN :bind0')
            .setQueryBindings(new List<Object>{ qlidSet });
    }

    public QueryFactory selectCostCentersLineItems() {
        return newQueryFactory()
            .setFactoryName('selectCostCentersLineItems')
            .selectFields(getFieldList());
    }

    public QueryFactory selectMasterItemsAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectMasterItemsAllFieldsForCloning')
            .selectFields(getFieldListForCloning())
            .setCondition('Id IN :bind0 and Quote_Line_Item__r.IsMultiProductTechnicalQLI__c = false')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectTechnicalItemsByMasterQliId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectTechnicalItemsByMasterQliId')
            .selectFields(getFieldListForCloning())
            .setCondition('Quote_Line_Item__r.MasterQLI__c IN :bind0 AND Quote_Line_Item__r.IsMultiProductTechnicalQLI__c = true')
            .setQueryBindings(bindings);
    }
}