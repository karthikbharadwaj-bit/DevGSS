public inherited sharing class ContentDocumentLinkSelector extends SObjectSelector {

    public ContentDocumentLinkSelector() {
        super();
    }

    public ContentDocumentLinkSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            ContentDocumentLink.Id,
            ContentDocumentLink.LinkedEntityId,
            ContentDocumentLink.ContentDocumentId
        };
    }

    public List<String> getFieldsForKycApproval() {
        return new List<String>{
            'Id',
            'LinkedEntityId',
            'ContentDocument',
            'ContentDocumentId',
            'ContentDocument.LatestPublishedVersionId'
        };
    }
    
    public List<String> getFieldsForBulkFileDownload() {
        return new List<String>{
            'Id',
            'LinkedEntityId',
            'ContentDocument',
            'ContentDocumentId',
            'ContentDocument.LatestPublishedVersionId',
            'ContentDocument.Title'
        };
    }

    public override Schema.SObjectType getSObjectType() {
        return ContentDocumentLink.SObjectType;
    }

    public QueryFactory selectLinksByLinkedEntityId(Set<Id> linkedEntityIds) {
        return newQueryFactory()
            .setFactoryName('selectLinksByLinkedEntityId')
            .setCondition('LinkedEntityId IN :bind0')
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(new List<Object>{linkedEntityIds});
    }

    public QueryFactory selectLinksByLinkedEntityAndDocumentId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLinksByLinkedEntityAndDocumentId')
            .setCondition('ContentDocumentId IN :bind0 AND LinkedEntityId IN :bind1')
            .selectFields(getFieldsForKycApproval())
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings);
    }

    public QueryFactory selectLinksByDocumentId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLinksByLinkedEntityAndDocumentId')
            .setCondition('ContentDocumentId IN :bind0')
            .selectFields(getFieldsForKycApproval())
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings);
    }
    
    public QueryFactory selectLinksByLinkedEntityIdForBulkDownloads(Set<Id> linkedEntityIds) {
        return newQueryFactory()
            .setFactoryName('selectLinksByLinkedEntityId')
            .setCondition('LinkedEntityId IN :bind0')
            .selectFields(getFieldsForBulkFileDownload())
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(new List<Object>{linkedEntityIds});
    }
    
    /** Subselect from Case for Create Jira payload (matches prior inline SOQL: SELECT Id FROM ContentDocumentLinks). */
    public QueryFactory selectIdsForCreateJiraCaseSubselect() {
        return newQueryFactory()
            .setFactoryName('selectIdsForCreateJiraCaseSubselect')
            .selectField(ContentDocumentLink.Id)
            .withoutSelectorOrderByIncluded();
    }
}