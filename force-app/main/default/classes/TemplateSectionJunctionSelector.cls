public inherited sharing class TemplateSectionJunctionSelector extends SObjectSelector {
    public TemplateSectionJunctionSelector() {
        super();
    }

    public TemplateSectionJunctionSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return TemplateSectionJunction__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            TemplateSectionJunction__c.Id
        };
    }

    public QueryFactory selectSectionJunctions() {
        return newQueryFactory()
            .setFactoryName('selectSectionJunctions')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectByTemplateIdOrExternalId(String idOrExternalId) {
        return newQueryFactory()
            .setCondition('RC_Quote_Template__c = :bind0 OR RC_Quote_Template__r.External_ID__c = :bind0')
            .setQueryBindings(new List<String>{idOrExternalId});
    }
}