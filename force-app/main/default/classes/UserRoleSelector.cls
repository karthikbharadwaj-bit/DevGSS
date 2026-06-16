public inherited sharing class UserRoleSelector extends SObjectSelector {

    public UserRoleSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType()  {
        return UserRole.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            UserRole.Id,
            UserRole.Name
        };
    }

    public QueryFactory selectUserRoleById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUserRoleById')
            .selectFields(getDefaultFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings)
            .setLimit(1);
    }
    
}