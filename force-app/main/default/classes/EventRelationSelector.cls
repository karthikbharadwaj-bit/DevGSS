public inherited sharing class EventRelationSelector extends SObjectSelector {

    public EventRelationSelector() {
        super();
    }

    public EventRelationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return EventRelation.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            EventRelation.EventId,
            EventRelation.RelationId,
            EventRelation.IsInvitee
        };
    }

    public QueryFactory selectRelationsByEventIds(Set<Id> eventIds, Integer rowLimit) {
        return newQueryFactory()
            .setFactoryName('selectRelationsByEventIds')
            .withoutSelectorOrderByIncluded()
            .setCondition('EventId IN :bind0')
            .setQueryBindings(new List<Object> { eventIds })
            .setLimit(rowLimit);
    }
}
