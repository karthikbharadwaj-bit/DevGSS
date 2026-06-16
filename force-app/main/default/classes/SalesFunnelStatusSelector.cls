public inherited sharing class SalesFunnelStatusSelector extends SObjectSelector {

    public SalesFunnelStatusSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return SalesFunnelStatus__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField>{
            SalesFunnelStatus__c.Id,
            SalesFunnelStatus__c.Opportunity__c,
            SalesFunnelStatus__c.Sales_Agent__c,
            SalesFunnelStatus__c.IsRequestOpen__c,
            SalesFunnelStatus__c.Quote__c
        };
    }

    public List<String> getFieldList() {
        return new List<String>{
            'Id',
            'Opportunity__c',
            'Sales_Agent__c',
            'IsRequestOpen__c',
            'Quote__c',
            'Quote__r.RecordTypeId'
        };
    }

    public QueryFactory selectSalesFunnelStatusByOppIdAndSalesAgentId(Id oppId, Id salesAgentId) {
        return newQueryFactory()
            .setFactoryName('selectSalesFunnelStatusByOppId')
            .selectFields(getFieldList())
            .setCondition('Opportunity__c = :bind0 AND Sales_Agent__c = :bind1')
            .setQueryBindings(new List<Object>{oppId, salesAgentId});
    }

    public QueryFactory selectSalesFunnelStatusByOppIdAndSalesAgentIdAndQuoteIds(Id oppId, Id salesAgentId, Set<Id> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectSalesFunnelStatusByOppIdAndQuoteIds')
            .selectFields(getFieldList())
            .setCondition('Opportunity__c = :bind0 AND Sales_Agent__c = :bind1 AND Quote__c IN :bind2')
            .setQueryBindings(new List<Object>{oppId, salesAgentId, quoteIds});
    }

    public QueryFactory selectSalesFunnelStatuses() {
        return newQueryFactory()
            .setFactoryName('selectSalesFunnelStatuses')
            .withSelectorFieldsIncluded()
            .withSelectFieldsSorted();
    }

    public QueryFactory selectSalesFunnelStatusesForGWValidator(Id oppId, Id salesAgentId, Id quoteId) {
        return newQueryFactory()
            .setFactoryName('selectSalesFunnelStatusesForGWValidator')
            .selectFields(getDefaultFieldList())
            .setCondition('Opportunity__c = :bind0 AND Sales_Agent__c = :bind1 AND Quote__c =: bind2')
            .setQueryBindings(new List<Object>{oppId, salesAgentId, quoteId});
    }

    public QueryFactory selectSalesFunnelStatusesForGWValidatorByFilter(Id oppId, Id salesAgentId, List<String> serviceNameFilter) {
        return newQueryFactory()
            .setFactoryName('selectSalesFunnelStatusesForGWValidatorByFilter')
            .selectFields(getDefaultFieldList())
            .setCondition('Opportunity__c = :bind0 AND Sales_Agent__c = :bind1 AND Quote__r.ServiceName__c NOT IN :bind2')
            .setQueryBindings(new List<Object>{oppId, salesAgentId, serviceNameFilter});
    }
}