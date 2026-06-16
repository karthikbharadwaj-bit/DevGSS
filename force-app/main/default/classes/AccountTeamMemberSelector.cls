public inherited sharing class AccountTeamMemberSelector extends SObjectSelector {
    
    public AccountTeamMemberSelector(){
        super();
    }
    
    public AccountTeamMemberSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }
    
    public override Schema.SObjectType getSObjectType()  {
        return AccountTeamMember.SObjectType;
    }
    
    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            AccountTeamMember.Id,
            AccountTeamMember.AccountId,
            AccountTeamMember.UserId,
            AccountTeamMember.TeamMemberRole    
        };
    }
    public QueryFactory selectAccountTeamMemberByAccountId(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectAccountTeamMemberByAccountId')
                .withSelectorFieldsIncluded()
                .selectFields(getDefaultFieldList())
                .withoutSelectorOrderByIncluded()
                .setCondition('AccountId IN :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountTeamMembers() {
        return newQueryFactory()
            .setFactoryName('selectAccountTeamMembers')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(new List<String>{
                'UserId', 'TeamMemberRole', 'AccountId'
            });
    }
    
    public QueryFactory selectAccountTeamMemberByAccountIdAndRole(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectAccountTeamMemberByAccountIdAndRole')
                .withSelectorFieldsIncluded()
                .selectFields(getDefaultFieldList())
                .withoutSelectorOrderByIncluded()
                .setCondition('AccountId IN :bind0 AND TeamMemberRole = :bind1')
                .setQueryBindings(bindings);
    }
}