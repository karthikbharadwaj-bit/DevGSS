@isTest
private class Test_RCUserArticleRatingTriggerHelper {
    private static final String USER_COMMENTS =
        (String) new ValueProvider.UniqueFixedLengthStringProvider(25).getValue();
    private static final String RC_USER_NAME = UserInfo.getName();
    private static final Boolean IS_EXTERNAL = false;

    @testSetup
    private static void createTestData() {
        KCSDataFactory.setup();
        KCSDataFactory.createAndPublishArticleAsUser(KCSDataFactory.publisher, KnowledgeArticleService.STATUS_DRAFT);
    }

    @isTest
    private static void testPopulateKnowledgeArticleURL_WhenCommentIsInternal() {
        List<Knowledge__kav> articles = new KnowledgeArticleSelector()
            .selectArticles()
            .executeQuery();

        createCommentForArticle(articles.get(0).ArticleNumber, false);

        List<RC_User_Article_Rating__c> articleRatings = new RCUserArticleRatingSelector()
            .selectRCUserArticleRatingByArticleId(new List<Object>{
                articles.get(0).ArticleNumber})
            .executeQuery();

        System.assert(!articleRatings.isEmpty(), 'No RC_User_Article_Rating__c were found');
        System.assertEquals(
            System.Url.getOrgDomainUrl().toExternalForm() + '/' + articles.get(0).KnowledgeArticleId,
            articleRatings.get(0).Knowledge_Article_URL__c,
            'Knowledge Article URL was populated incorrectly');
        KCSSettings__c kcsSettings = KCSSettings__c.getInstance();
        System.assertEquals(
            kcsSettings.OverallEmail__c,
            articleRatings.get(0).EmailToNotifyAboutNewComment__c,
            'Email to notify was populated incorrectly');
    }

    @isTest
    private static void testPopulateKnowledgeArticleURL_WhenCommentIsExternal() {
        List<Knowledge__kav> articles = new KnowledgeArticleSelector()
            .selectArticles()
            .executeQuery();

        createCommentForArticle(articles.get(0).ArticleNumber, true);

        List<RC_User_Article_Rating__c> articleRatings = new RCUserArticleRatingSelector()
            .selectRCUserArticleRatingByArticleId(new List<Object>{
                articles.get(0).ArticleNumber})
            .executeQuery();

        System.assert(!articleRatings.isEmpty(), 'No RC_User_Article_Rating__c were found');
        System.assertEquals(
            null,
            articleRatings.get(0).Knowledge_Article_URL__c,
            'Knowledge Article URL was populated after external comment');
        System.assertEquals(
            null,
            articleRatings.get(0).EmailToNotifyAboutNewComment__c,
            'Email to notify was populated was populated after external comment');
    }

    private static void createCommentForArticle(String articleNumber, Boolean isExternal) {
        new SObjectBuilder(RC_User_Article_Rating__c.SObjectType)
            .setField(RC_User_Article_Rating__c.User_Comments__c, USER_COMMENTS)
            .setField(RC_User_Article_Rating__c.RC_User_name__c, RC_USER_NAME)
            .setField(RC_User_Article_Rating__c.RC_ArticleID__c, articleNumber)
            .setField(RC_User_Article_Rating__c.Is_External__c, isExternal)
            .create();
    }
}