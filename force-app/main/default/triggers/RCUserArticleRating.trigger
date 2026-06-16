trigger RCUserArticleRating on RC_User_Article_Rating__c (before insert, before update) {
    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new RCUserArticleRatingTriggerHelper.RCUserArticleRatingCreateHandler())
        .manage();
}