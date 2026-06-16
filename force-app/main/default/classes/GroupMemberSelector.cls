public inherited sharing class GroupMemberSelector extends SObjectSelector {

    public GroupMemberSelector() {
        super();
        defaultOrder = 'Id';
    }

    public GroupMemberSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
        defaultOrder = 'Id';
    }

    public override Schema.SObjectType getSObjectType()  {
        return GroupMember.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            GroupMember.Id,
            GroupMember.UserOrGroupId,
            GroupMember.GroupId
        };
    }

    public List<String> getFieldListForSelectGroupMemberBasedOnUserAndGroupName() {
        return new List<String> {
            'UserOrGroupId',
            'Group.Type',
            'Group.Name'
        };
    }

    public QueryFactory selectExistGroupMembersBasedOnUserIdAndGroupId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectExistGroupMembersBasedOnUserIdAndGroupId')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('UserOrGroupId IN :bind0 AND GroupId IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectGroupMembersByGroupName(String name) {
        return newQueryFactory()
            .setFactoryName('selectGroupMembersByGroupName')
            .selectField('UserOrGroupId')
            .setCondition('Group.Name = :bind0')
            .setQueryBindings(new List<Object>{ name });
    }

    public QueryFactory selectGroupMembersByGroupIds(Set<Id> groupIdSet) {
        return newQueryFactory()
            .setFactoryName('selectGroupMembersByGroupIds')
            .setCondition('GroupId IN :bind0')
            .setQueryBindings(new List<Object>{ groupIdSet });
    }

    public QueryFactory selectByGroupDeveloperName(String developerName) {
        return newQueryFactory()
            .setFactoryName('selectByGroupDeveloperName')
            .setCondition('Group.DeveloperName = :bind0')
            .setQueryBindings(new List<Object> {developerName});
    }

    public QueryFactory selectGroupMemberBasedOnUserAndGroupName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectGroupMemberBasedOnUserAndGroupName')
            .withSelectorFieldsIncluded()
            .selectFields(getFieldListForSelectGroupMemberBasedOnUserAndGroupName())
            .setCondition('UserOrGroupId =:bind0 AND Group.Type =:bind1 AND Group.Name IN:bind2')
            .setQueryBindings(bindings);
    }
}