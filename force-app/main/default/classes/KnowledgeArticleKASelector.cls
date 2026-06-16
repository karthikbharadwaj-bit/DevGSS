public inherited sharing class KnowledgeArticleKASelector extends SObjectSelector {
    public KnowledgeArticleKASelector() {
        super();
    }

    public KnowledgeArticleKASelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Knowledge__ka.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Knowledge__ka.Id,
            Knowledge__ka.ArticleNumber,
            Knowledge__ka.CreatedDate,
            Knowledge__ka.MasterLanguage
        };
    }

    public QueryFactory selectDefaultArticles() {
        return newQueryFactory()
            .setFactoryName('selectDefaultArticles')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectArticlesById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectArticlesById')
            .withSelectorFieldsIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectArticleByArticleNumber(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectArticlesByArticleNumber')
            .withSelectorFieldsIncluded()
            .setCondition('ArticleNumber =:bind0')
            .setQueryBindings(bindings);
    }
}