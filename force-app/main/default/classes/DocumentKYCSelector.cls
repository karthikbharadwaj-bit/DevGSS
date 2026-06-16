public inherited sharing class DocumentKYCSelector extends SObjectSelector {

    public DocumentKYCSelector() {
        super();
    }

    public DocumentKYCSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Document__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Document__c.Approval__c,
            Document__c.DateOfIssue__c,
            Document__c.DocumentNo__c,
            Document__c.IssuingAuthority__c,
            Document__c.PlaceOfIssue__c,
            Document__c.Type__c
        };
    }

    public QueryFactory selectDocuments() {
        return newQueryFactory()
            .setFactoryName('selectDocuments')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectDocumentsByApprovalId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDocumentsByApprovalId')
            .selectFields(getDefaultFieldList())
            .setCondition('Approval__c IN :bind0')
            .setQueryBindings(bindings);
    }
}