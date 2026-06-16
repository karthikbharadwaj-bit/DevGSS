public inherited sharing class ProfileSelector extends SObjectSelector {

    public ProfileSelector() {
        super();
    }

    public ProfileSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Profile.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Profile.Id,
            Profile.Name
        };
    }

    public QueryFactory selectAllProfiles() {
        return newQueryFactory()
            .setFactoryName('selectAllProfiles')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectProfileByName(String profileName) {
        return selectProfileByName(new List<Object> {profileName});
    }

    public QueryFactory selectProfileByName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectProfileByName')
            .withSelectorFieldsIncluded()
            .setCondition('Name = :bind0')
            .setQueryBindings(bindings)
            .setLimit(1);
    }
    public QueryFactory selectProfilesByNames(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectProfileByName')
            .withSelectorFieldsIncluded()
            .setCondition('Name = :bind0')
            .setQueryBindings(bindings);
    }
    public QueryFactory selectProfileById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectProfileById')
            .selectFields(getDefaultFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings)
            .setLimit(1);
    }

    public QueryFactory selectProfiles() {
        return newQueryFactory()
            .setFactoryName('selectProfiles')
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }
}