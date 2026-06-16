public inherited sharing class SLASelector extends SObjectSelector {

    public SLASelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return SLA__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField>{
            SLA__c.Id,
            SLA__c.Name,
            SLA__c.IsStandardSLA__c,
            SLA__c.EngageLegal__c,
            SLA__c.Account__c,
            SLA__c.UnitSize__c,
            SLA__c.DollarToDollarCalculation__c,
            SLA__c.MaxCredit__c,
            SLA__c.MinDowntime__c,
            SLA__c.AvailabilityUnits__c,
            SLA__c.ServiceType__c,
            SLA__c.MaxCredit__c,
            SLA__c.CalculationFormula__c,
            SLA__c.Trigger__c,
            SLA__c.TriggerRelation__c,
            SLA__c.TriggerValue__c,
            SLA__c.TriggerFormula__c,
            SLA__c.StrikeCount__c,
            SLA__c.StrikePeriod__c,
            SLA__c.StrikeValue__c
        };
    }

    public QueryFactory selectSLAsWithCreditCharts() {
        return newQueryFactory()
            .setFactoryName('getSLAsForAccount')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String>{
                'Account__r.Id', 'Account__r.Name', 'EngageLegal__r.Id', 'EngageLegal__r.Name', 'EngageLegal__r.Approval_ID__c'
            })
            .withoutSelectorOrderByIncluded()
            .subselect(new SLACreditChartSelector().selectSLACreditCharts());
    }

    public QueryFactory selectSLAsForAccount(List<Object> bindings) {
        return selectSLAsWithCreditCharts()
            .setCondition('Account__c = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectSLAsForAccounts(List<Object> bindings) {
        return selectSLAsWithCreditCharts()
            .setCondition('Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectSLAById(List<Object> bindings) {
        return selectSLAsWithCreditCharts()
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectMultipleSLAById(List<Object> bindings) {
        return selectSLAsWithCreditCharts()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }
}