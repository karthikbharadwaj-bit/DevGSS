public inherited sharing class GroupSelector extends SObjectSelector {

    public GroupSelector() {
        super();
    }

    public GroupSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Group.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Group.Id,
            Group.DeveloperName,
            Group.Name
        };
    }

    public QueryFactory selectGroups() {
        return newQueryFactory()
            .setFactoryName('selectGroups')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectGroupBasedOnDeveloperNames(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectGroupBasedOnDeveloperNames')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('DeveloperName IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQueueByName(String name) {
        return newQueryFactory()
            .setFactoryName('selectQueueByName')
            .selectFields(getDefaultFieldList())
            .setCondition('Type = :bind0 AND Name = :bind1')
            .setQueryBindings(new List<Object>{ GroupHelper.GROUP_TYPE_QUEUE, name })
            .setLimit(1);
    }

    public QueryFactory selectQueueByDeveloperName(String name) {
        return newQueryFactory()
            .setFactoryName('selectQueueByDeveloperName')
            .selectFields(getDefaultFieldList())
            .setCondition('Type = :bind0 AND DeveloperName = :bind1')
            .setQueryBindings(new List<Object>{ GroupHelper.GROUP_TYPE_QUEUE, name })
            .setLimit(1);
    }

    public QueryFactory selectQueuesById(List<String> ids) {
        return newQueryFactory()
            .setFactoryName('selectQueuesById')
            .selectFields(getDefaultFieldList())
            .setCondition('Type = :bind0 AND Id IN :bind1')
            .setQueryBindings(new List<Object>{ GroupHelper.GROUP_TYPE_QUEUE, ids });
    }
}