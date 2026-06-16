public inherited sharing class QueueSelector extends SObjectSelector {

    public QueueSelector() {
        super();
    }

    public QueueSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return QueueSObject.getSObjectType();
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            QueueSObject.Id,
            QueueSObject.QueueId,
            QueueSObject.SObjectType
        };
    }

    public QueryFactory selectQueueForDFRBySObjectType(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectQueueForDFRBySObjectType')
                .withSelectorFieldsIncluded()
                .selectFields(new List<String>{'Queue.Name'})
                .withoutSelectorOrderByIncluded()
                .setCondition('SObjectType = :bind0')
                .setQueryCaching(true)
                .setQueryBindings(bindings);
    }

    public QueryFactory selectQueueByName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQueueByName')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String>{'QueueId'})
            .withoutSelectorOrderByIncluded()
            .setCondition('Queue.Name = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQueuesByNames(Set<String> queueNames) {
        return newQueryFactory()
            .setFactoryName('selectQueuesByNames')
            .withoutSelectorOrderByIncluded()
            .selectFields(new List<String> {'QueueId', 'Queue.Name'})
            .setCondition('Queue.Name IN :bind0')
            .setQueryBindings(new List<Object> {queueNames});
    }
}