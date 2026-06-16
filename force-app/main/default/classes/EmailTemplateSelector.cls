public with sharing class EmailTemplateSelector extends SObjectSelector {

    public EmailTemplateSelector() {
        super();
    }

    public EmailTemplateSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return EmailTemplate.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            EmailTemplate.Id,
            EmailTemplate.IsActive,
            EmailTemplate.DeveloperName,
            EmailTemplate.Body,
            EmailTemplate.FolderId,
            EmailTemplate.TemplateType,
            EmailTemplate.Name,
            EmailTemplate.IsActive
        };
    }

    public List<Schema.SObjectField> getOtherFieldList() {
        return new List<Schema.SObjectField> {};
    }

    public List<Schema.SObjectField> getFieldsForApprovalTriger() {
        return new List<Schema.SObjectField>{
            EmailTemplate.HtmlValue,
            EmailTemplate.Subject
        };
    }

    public QueryFactory selectEmailTemplateByDeveloperName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectEmailTemplateByDeveloperName')
            .withSelectorFieldsIncluded()
            .selectFields(getOtherFieldList())
            .selectField('Subject')
            .setCondition('DeveloperName = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectEmailTemplatesByDeveloperNames(List<String> developerNames, Boolean isQueryCaching) {
        List<Object> bindings = new List<Object>{ developerNames };
        return newQueryFactory()
            .setFactoryName('selectEmailTemplatesByDeveloperNames')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .selectFields(getFieldsForApprovalTriger())
            .setCondition('DeveloperName IN :bind0')
            .setQueryCaching(isQueryCaching)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectEmailTemplateById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectEmailTemplateById')
            .withSelectorFieldsIncluded()
            .selectFields(getOtherFieldList())
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public override String getOrderBy()
    {
        return 'CreatedDate DESC';
    }


    public QueryFactory selectEmailTemplates() {
        return newQueryFactory()
            .setFactoryName('SelectEmailTemplates')
            .withSelectorFieldsIncluded()
            .withSelectFieldsSorted()
            .setLimit(1);
    }

    public QueryFactory selectEmailTemplatesByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectEmailTemplatesByIds')
            .withSelectorFieldsIncluded()
            .selectFields(getOtherFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }
}