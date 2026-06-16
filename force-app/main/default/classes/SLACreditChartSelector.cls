public inherited sharing class SLACreditChartSelector extends SObjectSelector {
    public SLACreditChartSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return SLACreditChart__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            SLACreditChart__c.Id,
            SLACreditChart__c.MinAvailability__c,
            SLACreditChart__c.MaxAvailability__c,
            SLACreditChart__c.SLACredit__c
        };
    }

    public QueryFactory selectSLACreditCharts() {
        return newQueryFactory()
            .setFactoryName('GetSLACreditCharts')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .addOrdering(SLACreditChart__c.MaxAvailability__c, QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectSLACreditChartsForSLA(List<Object> bindings) {
        return selectSLACreditCharts()
            .setFactoryName('GetSLACreditChartsForSLA')
            .setCondition('SLA__c = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectSLACreditChartsForMultipleSLA(List<Object> bindings) {
        return selectSLACreditCharts()
            .setFactoryName('GetSLACreditChartsForMultipleSLA')
            .setCondition('SLA__c IN :bind0')
            .setQueryBindings(bindings);
    }
}