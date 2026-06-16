global class PublishArticleBatch implements Database.Batchable<SObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT KnowledgeArticleId
            FROM Knowledge__kav
            WHERE CreatedDate > 2025-12-29T07:49:17.000+0000
            AND PublishStatus = 'Draft'
            ORDER BY CreatedDate DESC
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Knowledge__kav> scope) {
        for (Knowledge__kav article : scope) {
            try {
                KbManagement.PublishingService.publishArticle(article.KnowledgeArticleId, true);
            } catch (Exception e) {
                System.debug('Failed to publish: ' + article.KnowledgeArticleId + ' - ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}