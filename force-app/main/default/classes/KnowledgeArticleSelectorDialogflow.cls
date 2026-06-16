public inherited sharing class KnowledgeArticleSelectorDialogflow {
    private static KnowledgeArticleSelectorDialogflow instance;
    
    public static KnowledgeArticleSelectorDialogflow getInstance() {
        if (instance == null) {
            instance = new KnowledgeArticleSelectorDialogflow();
        }
        return instance;
    }
    
    // Fields used across multiple queries
    private static final List<String> BASE_FIELDS = new List<String>{
        'Id',
        'Title',
        'ArticleNumber',
        'Summary',
        'PublishStatus',
        'Language'
    };
    
    // Get article by article number
    public Knowledge__kav getArticleByNumber(String articleNumber) {
        if (String.isBlank(articleNumber)) {
            throw new KnowledgeArticleSelectorException('Article number cannot be empty');
        }
        
        List<Knowledge__kav> articles = [
            SELECT Id, Title, ArticleNumber, Summary
            FROM Knowledge__kav 
            WHERE ArticleNumber = :articleNumber 
            AND Language = 'en_US'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        return !articles.isEmpty() ? articles[0] : null;
    }
    
    // Get similar articles by topic
    public List<Knowledge__kav> getSimilarArticles(String topic, Integer limitCount) {
        if (String.isBlank(topic)) {
            throw new KnowledgeArticleSelectorException('Topic cannot be empty');
        }
        
        if (limitCount == null) {
            limitCount = 5; // Default limit
        }
        
        String searchKey = '%' + topic + '%';
        return [
            SELECT Id, Title, ArticleNumber, Summary
            FROM Knowledge__kav
            WHERE Title LIKE :searchKey
            WITH SECURITY_ENFORCED
            LIMIT :limitCount
        ];
    }
    
    // Get user record access for articles
    public Map<Id, UserRecordAccess> getArticleAccessByUser(Id userId, Set<Id> articleIds) {
        if (articleIds.isEmpty()) {
            return new Map<Id, UserRecordAccess>();
        }
        
        Map<Id, UserRecordAccess> accessMap = new Map<Id, UserRecordAccess>();
        for (UserRecordAccess ura : [
            SELECT RecordId, HasReadAccess
            FROM UserRecordAccess 
            WHERE UserId = :userId 
            AND RecordId IN :articleIds
            WITH SECURITY_ENFORCED
        ]) {
            accessMap.put(ura.RecordId, ura);
        }
        
        return accessMap;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getArticleIdsByArticleNumbers(List<String> articleNumbers) {
        Map<String, String> result = new Map<String, String>();
        for (Knowledge__kav k : [
            SELECT Id, ArticleNumber 
            FROM Knowledge__kav 
            WHERE ArticleNumber IN :articleNumbers
        ]) {
            result.put(k.ArticleNumber, k.Id);
        }
        return result;
    }

    public List<Knowledge__kav> getAllPublishedArticles() {
        return [
            SELECT Id, ArticleNumber, Title, Summary, UrlName, RC_Knowledge_Article_Details__c
            FROM Knowledge__kav
            WHERE Language = 'en_US' AND PublishStatus='Online'
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC LIMIT 10000
        ];
    }

    public class KnowledgeArticleSelectorException extends Exception {}
}