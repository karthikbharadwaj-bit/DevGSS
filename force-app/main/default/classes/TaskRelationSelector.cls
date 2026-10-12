public inherited sharing class TaskRelationSelector extends SObjectSelector {

    public TaskRelationSelector() {
        super();
    }

    public TaskRelationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return TaskRelation.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            TaskRelation.TaskId,
            TaskRelation.RelationId,
            TaskRelation.IsWhat
        };
    }

    /**
     * Who relations (contacts and leads) of the given tasks; the What relation is left out.
     */
    public QueryFactory selectWhoRelationsByTaskIds(Set<Id> taskIds, Integer rowLimit) {
        return newQueryFactory()
            .setFactoryName('selectWhoRelationsByTaskIds')
            .withoutSelectorOrderByIncluded()
            .setCondition('TaskId IN :bind0 AND IsWhat = false')
            .setQueryBindings(new List<Object> { taskIds })
            .setLimit(rowLimit);
    }
}
