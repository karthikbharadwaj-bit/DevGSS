@isTest
private class Test_RCArticleRatingSelector {
    @testSetup
    static void testSetup() {
        new SObjectBuilder(RC_Article_Rating__c.SObjectType)
            .setField(RC_Article_Rating__c.Article_Number__c, '1234567')
            .setField(
                RC_Article_Rating__c.PositiveVotesCount__c,
                ValueProviderBuilder.provideList(new List<Integer> {4, 1}))
            .setField(
                RC_Article_Rating__c.NegativeVotesCount__c,
                ValueProviderBuilder.provideList(new List<Integer> {3, 2}))
            .quantity(2)
            .create();
    }

    @isTest
    static void testSelectDefaultArticlesRating() {
        List<RC_Article_Rating__c> articleRatings = (List<RC_Article_Rating__c>) new RCArticleRatingSelector()
            .selectDefaultArticlesRating()
            .executeQuery();

        System.assert(articleRatings.size() == 2, 'Not all records were selected');

        System.assert(articleRatings.get(0).PositiveVotesCount__c == 4, 'Wrong like value');
        System.assert(articleRatings.get(0).NegativeVotesCount__c == 3, 'Wrong dislike value');
        System.assert(articleRatings.get(1).PositiveVotesCount__c == 1, 'Wrong like value');
        System.assert(articleRatings.get(1).NegativeVotesCount__c == 2, 'Wrong dislike value');
    }

    @isTest
    static void testSelectArticleRatingByIds() {
        List<RC_Article_Rating__c> articleRatings =
            (List<RC_Article_Rating__c>) new RCArticleRatingSelector(false, false)
            .selectDefaultArticlesRating()
            .executeQuery();

        Decimal articleRatingToFind = articleRatings.get(0).PositiveVotesCount__c;

        List<RC_Article_Rating__c> foundArticleRatings = (List<RC_Article_Rating__c>) new RCArticleRatingSelector()
            .selectArticleRatingByIds(new List<Object>{new List<String>{articleRatings.get(0).Id}})
            .executeQuery();

        System.assertEquals(1, foundArticleRatings.size(), 'No articles were found');
        System.assertEquals(
            articleRatingToFind,
            foundArticleRatings.get(0).PositiveVotesCount__c,
            'Wrong article was found'
        );
    }
}