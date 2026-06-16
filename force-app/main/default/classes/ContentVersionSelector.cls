public inherited sharing class ContentVersionSelector extends SObjectSelector {

    public ContentVersionSelector() {
        super();
    }

    public ContentVersionSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return ContentVersion.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            ContentVersion.PathOnClient,
            ContentVersion.Title,
            ContentVersion.ContentSize,
            ContentVersion.ContentDocumentId,
            ContentVersion.ContentUrl,
            ContentVersion.FileType,
            ContentVersion.LastModifiedDate,
            ContentVersion.CreatedDate,
            ContentVersion.Knowledge__c,
            ContentVersion.Id
        };
    }

    public QueryFactory selectContentVersions() {
        return newQueryFactory()
            .setFactoryName('selectContentVersions')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectContentVersionByContentDocumentId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContentVersionByContentDocumentId')
            .selectFields(getDefaultFieldList())
            .setCondition('ContentDocumentId IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContentVersionById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContentVersionById')
            .selectFields(getDefaultFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    // New method to query by Knowledge__c
    public QueryFactory selectContentVersionsByKnowledgeIds(Set<Id> knowledgeIds) {
        return newQueryFactory()
            .setFactoryName('selectContentVersionsByKnowledgeIds')
            .selectFields(getDefaultFieldList())
            .setCondition('Knowledge__c IN :bind0')
            .setQueryBindings(new List<Object>{knowledgeIds});
    }
}