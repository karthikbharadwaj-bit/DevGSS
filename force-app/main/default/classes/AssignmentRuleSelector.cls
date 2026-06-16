public inherited sharing class AssignmentRuleSelector extends SObjectSelector {
    public AssignmentRuleSelector() {
        super();
    }

    public AssignmentRuleSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return AssignmentRule.getSObjectType();
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            AssignmentRule.Id
        };
    }

    public QueryFactory selectAssignmentRuleBySObject(String objectString) {
        return newQueryFactory()
            .setFactoryName('selectAssignmentRuleBySObject')
            .selectFields(getDefaultFieldList())
            .setCondition('SobjectType = :bind0 AND Active = true')
            .setQueryBindings(new List<Object>{objectString});
    }
}