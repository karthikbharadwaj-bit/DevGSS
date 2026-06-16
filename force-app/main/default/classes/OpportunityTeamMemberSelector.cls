public inherited sharing class OpportunityTeamMemberSelector extends SObjectSelector {
    
    public OpportunityTeamMemberSelector() {
        super();
    }

    public OpportunityTeamMemberSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return OpportunityTeamMember.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            OpportunityTeamMember.Id
        };
    }

    private static List<String> getTeamMemberUserDetails() {
        return new List<String> {
            'TeamMemberRole',
            'OpportunityId',    
            'opportunity.stagename',
            'UserId',
            'user.Email',
            'user.Manager.email',
            'User.IsActive',
            'User.Manager.IsActive'
        };
    }

    public QueryFactory selectByOpportunityIdsAndRoles(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectByOpportunityIdsAndRoles')
            .selectField(OpportunityTeamMember.UserId)
            .selectFields(getTeamMemberUserDetails())
            .setCondition('OpportunityId IN :bind0 AND TeamMemberRole IN :bind1')
            .setQueryBindings(bindings);
    }
}