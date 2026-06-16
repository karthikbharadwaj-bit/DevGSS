public inherited sharing class DocumentSelector extends SObjectSelector {

    public DocumentSelector() {
        super();
    }

    public DocumentSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Document.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Document.Body,
            Document.BodyLength,
            Document.ContentType,
            Document.Url,
            Document.Name
        };
    }

    public QueryFactory selectDocumentsByNames(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDocumentsByNames')
            .withSelectorFieldsIncluded()
            .setCondition('Name LIKE :bind0')
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings);
    }
}