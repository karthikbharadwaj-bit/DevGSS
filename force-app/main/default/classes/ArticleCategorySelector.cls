public inherited sharing class ArticleCategorySelector extends SObjectSelector {

    public ArticleCategorySelector() {
        super();
    }

    public ArticleCategorySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return Knowledge__DataCategorySelection.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Knowledge__DataCategorySelection.Id,
            Knowledge__DataCategorySelection.DataCategoryName,
            Knowledge__DataCategorySelection.DataCategoryGroupName
        };
    }

    public List<String> getArticleFields() {
        return new List<String> {
            'Parent.Id',
            'Parent.Title',
            'Parent.Summary',
            'Parent.Language',
            'Parent.UrlName',
            'Parent.LastModifiedDate',
            'Parent.LastPublishedDate',
            'Parent.PublishStatus',
            'Parent.RC_Knowledge_Article_Key_Words__c'
        };
    }

    public QueryFactory selectArticleCategoryByArticleTitleOrKeyword(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectArticleCategoryByArticleTitleOrKeyword')
            .withSelectorFieldsIncluded()
            .selectFields(getArticleFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Parent.Language = :bind0 AND Parent.PublishStatus = \'Online\''
                + ' AND (Parent.RC_Knowledge_Article_Key_Words__c LIKE :bind1 OR Parent.Title LIKE :bind1)')
            .setQueryBindings(bindings);
    }
}