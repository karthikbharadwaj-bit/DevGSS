public inherited sharing class PSIntegrationSelector extends SObjectSelector {

    public PSIntegrationSelector() {
        super();
    }

    public PSIntegrationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return PS_Integration__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            PS_Integration__c.Id,
            PS_Integration__c.PSIntegrationNumber__c,
            PS_Integration__c.Phase__c,
            PS_Integration__c.Order__c,
            PS_Integration__c.Status__c,
            PS_Integration__c.MostRecentSuborder__c
        };
    }

    public List<String> getSubOrderFieldList() {
        return new List<String> {
            'MostRecentSuborder__r.Id',
            'MostRecentSuborder__r.Status__c',
            'MostRecentSuborder__r.SuborderNumber__c'
        };
    }

    public List<String> getProservProjectFieldList() {
        return new List<String> {
            'ProServProject__r.Id',
            'ProServProject__r.Name',
            'ProServProject__r.Account__c',
            'ProServProject__r.Quote__r.QuoteNumber',
            'ProServProject__r.Opportunity__c'
        };
    }

    public QueryFactory selectPSIntegrationsBySubOrderIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPSIntegrationsBySubOrderIds')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('MostRecentSuborder__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPSIntegrationsByOrderIds(Set<Id> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPSIntegrationsByOrderIds')
            .withSelectorFieldsIncluded()
            .setCondition('Order__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPSIntegrationsByProjectIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPSIntegrationsByProjectIds')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .selectFields(getSubOrderFieldList())
            .selectFields(getProservProjectFieldList())
            .setCondition('ProServProject__c IN :bind0 AND Status__c IN :bind1')
            .setQueryBindings(bindings);
    }
}