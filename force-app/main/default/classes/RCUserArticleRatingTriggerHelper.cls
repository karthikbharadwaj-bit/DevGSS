public class RCUserArticleRatingTriggerHelper {
    public class RCUserArticleRatingCreateHandler extends Triggers.TriggerHandlerBase {
        override public void handle() {
            KCSSettings__c kcsSettings = KCSSettings__c.getInstance();

            Map<String, RC_User_Article_Rating__c> ratingMap = new Map<String, RC_User_Article_Rating__c>();
            for (RC_User_Article_Rating__c articleRating : (List<RC_User_Article_Rating__c>) triggerRecords) {
                if (!articleRating.Is_External__c) {
                    ratingMap.put(articleRating.RC_ArticleID__c, articleRating);
                }
            }

            List<Knowledge__kav> articlesToCheck =
                (List<Knowledge__kav>) new KnowledgeArticleSelector()
                    .selectArticleByArticleNumber(new List<Object> {ratingMap.keySet()})
                    .executeQuery();

            Map<String, Knowledge__kav> articleKavMap = new Map<String, Knowledge__kav>();
            for (Knowledge__kav article : articlesToCheck) {
                articleKavMap.put(article.ArticleNumber, article);
            }

            for (RC_User_Article_Rating__c articleRating : ratingMap.values()) {
                if (articleKavMap.containsKey(articleRating.RC_ArticleID__c)) {
                    Knowledge__kav articleKav = articleKavMap.get(articleRating.RC_ArticleID__c);
                    populateKnowledgeArticleURL(articleRating, articleKav);
                    populateEmailToNotify(articleRating, articleKav, kcsSettings);
                }
            }
        }
    }

    private static void populateEmailToNotify(
        RC_User_Article_Rating__c articleRating, Knowledge__kav articleKav, KCSSettings__c kcsSettings) {

        if (articleKav.RC_Knowledge_Article_DecisionMaker__c != null && UserInfo.getUserId().equals(articleKav.RC_Knowledge_Article_DecisionMaker__r.Id) ||
            articleKav.RC_Knowledge_Article_ReviewedBy__c != null && UserInfo.getUserId().equals(articleKav.RC_Knowledge_Article_ReviewedBy__r.Id)) {
            articleRating.EmailToNotifyAboutNewComment__c = articleKav.CreatedBy.Email;
        } else {
            if (articleKav.RC_Knowledge_Article_DecisionMaker__c != null) {
                articleRating.EmailToNotifyAboutNewComment__c = articleKav.RC_Knowledge_Article_DecisionMaker__r.Email;
            } else if (articleKav.RC_Knowledge_Article_ReviewedBy__c != null) {
                articleRating.EmailToNotifyAboutNewComment__c = articleKav.RC_Knowledge_Article_ReviewedBy__r.Email;
            } else if (kcsSettings.OverallEmail__c != null) {
                articleRating.EmailToNotifyAboutNewComment__c = kcsSettings.OverallEmail__c;
            }
        }
    }

    private static void populateKnowledgeArticleURL(
        RC_User_Article_Rating__c articleRating, Knowledge__kav articleKav) {
        String baseURL = System.Url.getOrgDomainUrl().toExternalForm() + '/';
        if (articleKav.RC_Knowledge_Article_Knowledge_Article10__c != null) {
            articleRating.Knowledge_Article_URL__c = articleKav.RC_Knowledge_Article_Knowledge_Article10__c;
        } else {
            articleRating.Knowledge_Article_URL__c = baseURL + articleKav.KnowledgeArticleId;
        }
    }
}