public inherited sharing class CostCenterSelector extends SObjectSelector {

    public CostCenterSelector() {
        super();
    }

    public CostCenterSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Cost_Center__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Cost_Center__c.Id,
            Cost_Center__c.Name,
            Cost_Center__c.AddressId__c,
            Cost_Center__c.Billing_Code_Path__c,
            Cost_Center__c.BillingId__c,
            Cost_Center__c.Cost_Center_Parent__c,
            Cost_Center__c.Country__c,
            Cost_Center__c.Parent_Billing_Id__c,
            Cost_Center__c.Quote__c,
            Cost_Center__c.Tax_Location__c
        };
    }

    public List<String> getFieldsForSyncWithNGBS() {
        return new List<String>{
            'Id'
        };
    }

    public QueryFactory selectCostCentersData(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCostCentersData')
            .selectFields(getDefaultFieldList())
            .setCondition('Quote__c =:bind0 AND Cost_Center_Parent__c = null')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCostCentersByQuoteId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCostCentersByQuoteId')
            .selectFields(getDefaultFieldList())
            .setCondition('Quote__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAllFieldsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('Cost_Center__c'))
            .setCondition('Quote__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCostCentersForSyncWithNGBSByQuoteId(Id quoteId) {
        return newQueryFactory()
            .setFactoryName('selectCostCentersForSyncWithNGBSByQuoteId')
            .selectFields(getFieldsForSyncWithNGBS())
            .setCondition('Quote__c = :bind0')
            .setQueryBindings(new List<Object>{quoteId});
    }
}