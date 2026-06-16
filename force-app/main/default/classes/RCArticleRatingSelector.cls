public inherited sharing class RCArticleRatingSelector extends SObjectSelector {
    public RCArticleRatingSelector() {
        super();
    }

    public RCArticleRatingSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return RC_Article_Rating__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            RC_Article_Rating__c.Id,
            RC_Article_Rating__c.Article_Number__c,
            RC_Article_Rating__c.PositiveVotesCount__c,
            RC_Article_Rating__c.NegativeVotesCount__c
        };
    }

    public QueryFactory selectDefaultArticlesRating() {
        return newQueryFactory()
            .setFactoryName('selectDefaultArticlesRating')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectArticleRatingByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectArticleRatingByIds')
            .withSelectorFieldsIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }
}