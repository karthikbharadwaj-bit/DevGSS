public inherited sharing class AttachmentSelector extends SObjectSelector {

    public AttachmentSelector() {
        super();
    }

    public AttachmentSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Attachment.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Attachment.Id,
            Attachment.Name,
            Attachment.ParentId,
            Attachment.BodyLength,
            Attachment.ContentType
        };
    }

    public List<String> getExtendedFieldList() {
        return new List<String> {
            'Id',
            'Name',
            'ParentId',
            'BodyLength',
            'ContentType',
            'LastModifiedDate',
            'LastModifiedBy.Name'
        };
    }

    public List<Schema.SObjectField> getFieldsForCLM() {
        return new List<Schema.SObjectField>{
            Attachment.Name,
            Attachment.Body
        };
    }

    public List<Schema.SObjectField> getFieldsForMsaCopy() {
        return new List<Schema.SObjectField>{
            Attachment.Id,
            Attachment.Name,
            Attachment.Body,
            Attachment.ParentId,
            Attachment.BodyLength,
            Attachment.ContentType
        };
    }

    public QueryFactory selectAttachmentsDefault() {
        return newQueryFactory()
            .setFactoryName('selectAttachmentsDefault')
            .selectFields(getExtendedFieldList());
    }

    public QueryFactory selectAttachmentsByParentId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAttachmentsByParentId')
            .withSelectorFieldsIncluded()
            .setCondition('ParentId = :bind0')
            .withoutSelectorOrderByIncluded()
            .addOrdering(Attachment.CreatedDate, QueryFactory.SortOrder.ASCENDING)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAttachmentsByParentIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAttachmentsByParentIds')
            .withSelectorFieldsIncluded()
            .setCondition('ParentId IN :bind0')
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAttachmentsById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAttachmentsById')
            .withSelectorFieldsIncluded()
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAttachmentsForCLM(Set<Id> attachmentIds) {
        return newQueryFactory()
            .setFactoryName('selectAttachmentsForCLM')
            .withSelectorFieldsIncluded()
            .selectFields(getFieldsForCLM())
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{ attachmentIds });
    }

    public QueryFactory selectAttachmentsByListOfParentIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAttachmentsByListOfParentIds')
            .withSelectorFieldsIncluded()
            .setCondition('ParentId IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectMsaByParentId(Set<Id> parentIds) {
        return newQueryFactory()
            .setFactoryName('selectAttachmentsByParentId')
            .withSelectorFieldsIncluded()
            .selectFields(getFieldsForMsaCopy())
            .setCondition('ParentId IN :bind0 AND (Name LIKE \'%MSA%\' OR Name LIKE \'%Master Service Agreement%\')')
            .addOrdering(Attachment.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object>{ parentIds });
    }
}