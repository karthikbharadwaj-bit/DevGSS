public inherited sharing class PhaseSelector extends SObjectSelector {

    public PhaseSelector() {
        super();
    }

    public PhaseSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Phase__c.Id,
            Phase__c.Quote__c,
            Phase__c.Order__c,
            Phase__c.RecordTypeId,
            Phase__c.Initial_Payment__c,
            Phase__c.BillingStatus__c,
            Phase__c.Estimated_Completion_Date__c,
            Phase__c.Completion_Date__c,
            Phase__c.Completed_Date__c,
            Phase__c.Phase_Start_Date__c,
            Phase__c.Name,
            Phase__c.Status__c,
            Phase__c.Phase_Number__c,
            Phase__c.AutoNumberName__c,
            Phase__c.PhaseDescription__c,
            Phase__c.Phase_Type__c,
            Phase__c.Suborder__c
        };
    }

    public List<String> getPhaseAndAccountFields() {
        return new List<String> {
            'Id',
            'Initial_Payment__c',
            'BillingStatus__c',
            'MavenlinkIntegrationStatus__c',
            'Account__r.Id',
            'Account__r.Name'
        };
    }

    public override Schema.SObjectType getSObjectType()  {
        return Phase__c.SObjectType;
    }

    public QueryFactory selectPhases() {
        return newQueryFactory()
                .setFactoryName('SelectPhases')
                .withoutSelectorOrderByIncluded()
                .withSelectorFieldsIncluded();
    }

    public QueryFactory selectPhasesByOrdersIdsExcludePhaseIds(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectPhasesByOrdersIdsExcludePhaseIds')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .setCondition('Order__c IN :bind0 AND Id NOT IN :bind1')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectPhaseById(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectPhaseById')
                .withoutSelectorOrderByIncluded()
                .withSelectorFieldsIncluded()
                .selectFields(getPhaseAndAccountFields())
                .setCondition('Id = :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectPhasesForClose(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectPhasesForClose')
                .withSelectorFieldsIncluded()
                .subselect(
                    new HardwareLineItemSelector().selectPhaseLineItemsForClose()
                )
                .withoutSelectorOrderByIncluded()
                .setCondition('Quote__c IN :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectPhasesByQuoteIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPhasesByQuoteIds')
            .selectFields(getDefaultFieldList())
            .subselect(
                new HardwareLineItemSelector().selectPhaseLineItems()
            )
            .withoutSelectorOrderByIncluded()
            .setCondition('Quote__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPhasesByQuoteId(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectPhasesForClose')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .setCondition('Quote__c IN :bind0')
                .setQueryBindings(bindings);
    }
}