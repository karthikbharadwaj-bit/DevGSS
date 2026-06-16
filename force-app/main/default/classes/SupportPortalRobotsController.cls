public with sharing class SupportPortalRobotsController {

    public List <String> disallowUrls{get;set;}

    public SupportPortalRobotsController() {
        // Case 04938254 https://rc.my.salesforce.com/5003400000rCY3r
        // disallow robots from crawling ATT VIIPFR branded knowledge articles
        List <KnowledgeArticleVersion> attArticles = [SELECT UrlName 
            FROM KnowledgeArticleVersion 
            WHERE Language ='en_US' 
            AND PublishStatus ='Online' 
            WITH DATA CATEGORY Brand__c AT (ATT_VIIPFR__c, BT__c)];
        
        disallowUrls = new List <String>();
        for(KnowledgeArticleVersion attArticle : attArticles) {
            String attUrl = '/articles/RC_Knowledge_Article/' + attArticle.UrlName;
            disallowUrls.add(attUrl);
        }
    }
}