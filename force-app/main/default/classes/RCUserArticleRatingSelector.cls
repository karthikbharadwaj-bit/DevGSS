public inherited sharing class RCUserArticleRatingSelector extends SObjectSelector {

    public RCUserArticleRatingSelector() {
        super();
    }

    public RCUserArticleRatingSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return RC_User_Article_Rating__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            RC_User_Article_Rating__c.Id,
            RC_User_Article_Rating__c.User_Comments__c,
            RC_User_Article_Rating__c.RC_User_name__c,
            RC_User_Article_Rating__c.RC_User_Id__c,
            RC_User_Article_Rating__c.RC_ArticleID__c,
            RC_User_Article_Rating__c.CreatedDate,
            RC_User_Article_Rating__c.Is_External__c,
            RC_User_Article_Rating__c.Knowledge_Article_URL__c,
            RC_User_Article_Rating__c.EmailToNotifyAboutNewComment__c,
            RC_User_Article_Rating__c.RC_Article_Rating_ID__c,
            RC_User_Article_Rating__c.RC_Rating_Type__c,
            RC_User_Article_Rating__c.RC_Article_Rating__c
        };
    }

    public QueryFactory selectDefaultRCUserArticleRating() {
        return newQueryFactory()
            .setFactoryName('selectDefaultRCUserArticleRating')
            .withSelectorFieldsIncluded();
    }


    public QueryFactory selectRCUserArticleRatingByArticleId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectRCUserArticleRatingByArticleId')
            .withSelectorFieldsIncluded()
            .setCondition('RC_ArticleID__c = :bind0')
            .addOrdering(RC_User_Article_Rating__c.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }
}