public with sharing class DocuSignStatusSelector extends SObjectSelector {

    public DocuSignStatusSelector() {
        super();
    }

    public DocuSignStatusSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            dsfs__DocuSign_Status__c.Id,
            dsfs__DocuSign_Status__c.Name,
            dsfs__DocuSign_Status__c.dsfs__Company__c,
            dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c,
            dsfs__DocuSign_Status__c.dfsq__Quote__c
        };
    }

    public override Schema.SObjectType getSObjectType()  {
        return dsfs__DocuSign_Status__c.SObjectType;
    }

    public QueryFactory selectDocuSignStatuses() {
        return newQueryFactory()
            .setFactoryName('SelectContractsLimit10')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setLimit(10);
    }

    public QueryFactory selectDocuSignStatusesByAttachments(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDocuSignStatusesByAttachments')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('dsfs__Envelope_Status__c = :bind0 AND Id IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDocuSignStatusesByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDocuSignStatusesByIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDocuSignStatusForSignUp(Object target) {
        return newQueryFactory()
            .setFactoryName('SelectDocuSignStatusForSignUp')
            .selectFields(getDefaultFieldList())
            .setCondition('dfsq__Quote__c = :bind0 AND dsfs__Envelope_Status__c = \'Completed\'')
            .setQueryBindings(new List<Object>{ target });
    }

    public QueryFactory selectCompletedDocuSignStatusesForNdaById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCompletedDocuSignStatusesForNdaById')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('dsfs__Envelope_Status__c = \'Completed\' AND dfsq__Quote__c = null '
                + ' AND dsfs__Opportunity__c = null AND dsfs__Company__c != null AND Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public Set<Id> selectQuotesForCompletedDocuSignStatus(List<Object> bindings) {
        Set<Id> completedDocuSignStatusQuoteIds = new Set<Id>();
        for (AggregateResult result : (List<AggregateResult>) new DocuSignStatusSelector().newQueryFactory()
                .setFactoryName('selectQuotesForCompletedDocuSignStatus')
                .setAggregateFunction(QueryFactory.AggregateFunction.COUNT, dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c)
                .setCondition('dfsq__Quote__c IN :bind0 AND dsfs__Envelope_Status__c = \'Completed\'')
                .setGroupBy(dsfs__DocuSign_Status__c.dfsq__Quote__c)
                .setQueryBindings(bindings)
                .executeQuery()
        ) {
            completedDocuSignStatusQuoteIds.add((Id) result.get('dfsq__Quote__c'));
        }
        return completedDocuSignStatusQuoteIds;
    }
}