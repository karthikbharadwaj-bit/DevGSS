public inherited sharing class NGBSLanguageCodeMappingSelector extends SObjectSelector {

    public NGBSLanguageCodeMappingSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return NGBSLanguageCodeMapping__mdt.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            NGBSLanguageCodeMapping__mdt.IsActive__c,
            NGBSLanguageCodeMapping__mdt.SortOrder__c,
            NGBSLanguageCodeMapping__mdt.MasterLabel,
            NGBSLanguageCodeMapping__mdt.DeveloperName
        };
    }

    public QueryFactory selectActiveLanguageCodeMappings() {
        return newQueryFactory()
            .setFactoryName('selectActiveLanguageCodeMappings')
            .selectFields(this.getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('IsActive__c = true')
            .addOrdering('SortOrder__c', QueryFactory.SortOrder.ASCENDING);
    }
}