@isTest
private class Test_RCUserArticleRatingSelector {
    private static final String ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT = 'field is not returned correct';
    private static final String USER_COMMENTS =
        (String) new ValueProvider.UniqueFixedLengthStringProvider(25).getValue();
    private static final String RC_USER_ARTICLE_RATING =
        (String) new ValueProvider.UniqueFixedLengthStringProvider(25).getValue();
    private static final String RC_USER_NAME = UserInfo.getName();
    private static final String RC_USER_ID = UserInfo.getUserId();
    private static final Boolean IS_EXTERNAL = false;

    @testSetup
    private static void createTestData() {
        new SObjectBuilder(RC_User_Article_Rating__c.SObjectType)
            .setField(RC_User_Article_Rating__c.User_Comments__c, USER_COMMENTS)
            .setField(RC_User_Article_Rating__c.RC_User_name__c, RC_USER_NAME)
            .setField(RC_User_Article_Rating__c.RC_User_Id__c, RC_USER_ID)
            .setField(RC_User_Article_Rating__c.RC_ArticleID__c, RC_USER_ARTICLE_RATING)
            .setField(RC_User_Article_Rating__c.Is_External__c, IS_EXTERNAL)
            .create();
    }

    @isTest
    private static void testSelectDefaultKCSSettingsReturnDefaultFieldList() {
        RC_User_Article_Rating__c rcUserArticleRating = (RC_User_Article_Rating__c) new RCUserArticleRatingSelector()
            .selectDefaultRCUserArticleRating().executeQuery()[0];

        System.assertEquals(
            USER_COMMENTS,
            rcUserArticleRating.User_Comments__c,
            'User_Comments__c ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT
        );

        System.assertEquals(
            RC_USER_NAME,
            rcUserArticleRating.RC_User_name__c,
            'RC_User_name__c ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT
        );

        System.assertEquals(
            RC_USER_ID,
            rcUserArticleRating.RC_User_Id__c,
            'RC_User_Id__c ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT
        );

        System.assertEquals(
            RC_USER_ARTICLE_RATING,
            rcUserArticleRating.RC_ArticleID__c,
            'RC_ArticleID__c ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT
        );

        System.assertEquals(
            IS_EXTERNAL,
            rcUserArticleRating.Is_External__c,
            'Is_External__c ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT
        );
    }

    @isTest
    private static void testSelectDefaultRCUserArticleRating() {
        List<RC_User_Article_Rating__c> uar = (List<RC_User_Article_Rating__c>) new RCUserArticleRatingSelector()
            .selectDefaultRCUserArticleRating()
            .executeQuery();

        System.assertEquals(1, uar.size(), 'Not all articles were retrieved');
    }

    @isTest
    private static void testSelectArticlesById() {
        List<RC_User_Article_Rating__c> rcUserArticleRatings =
            (List<RC_User_Article_Rating__c>) new RCUserArticleRatingSelector(false, false)
            .selectDefaultRCUserArticleRating()
            .executeQuery();

        String articleIdToFind = rcUserArticleRatings.get(0).RC_User_name__c;

        List<RC_User_Article_Rating__c> foundRCUserArticleRatings =
            (List<RC_User_Article_Rating__c>) new RCUserArticleRatingSelector()
            .selectRCUserArticleRatingByArticleId(
                    new List<Object>{new List<String>{rcUserArticleRatings.get(0).RC_ArticleID__c}})
            .executeQuery();

        System.assertEquals(1, foundRCUserArticleRatings.size(), 'No articles were found');
        System.assertEquals(
            articleIdToFind,
            foundRCUserArticleRatings.get(0).RC_User_name__c,
            'Wrong article was found'
        );
    }
}