@RestResource(urlMapping='/getKnowledgeArticles')    
global with sharing class DialogFlowGetSimilarArticles {
    
    private static final Set<String> REQUIRED_PARAMS = new Set<String>{
        'salesforceUserId',
        'topic'
    };
    
    private static final Integer DEFAULT_LIMIT = 5;

    @HttpPost
    global static void getKnowledgeArticlesBySubject() {
        try {
            // Parse request
            RestRequest req = RestContext.request;
            Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            
            // Extract parameters
            Map<String, String> params = new Map<String, String>{
                'salesforceUserId' => (String)bodyMap.get('salesforceUserId'),
                'topic' => (String)bodyMap.get('topic')
            };
            
            // Validate required parameters
            DialogflowResponseHandler.validateRequiredParams(params, REQUIRED_PARAMS);
            
            // Get similar articles using selector
            List<Knowledge__kav> articles = KnowledgeArticleSelectorDialogFlow.getInstance().getSimilarArticles(params.get('topic'), DEFAULT_LIMIT);
            
            // Check article access
            Set<Id> articleIds = new Set<Id>();
            for (Knowledge__kav article : articles) {
                articleIds.add(article.Id);
            }
            
            Map<Id, UserRecordAccess> accessMap = KnowledgeArticleSelectorDialogFlow.getInstance().getArticleAccessByUser(params.get('salesforceUserId'), articleIds);
            
            // Filter articles based on access and convert to wrappers
            List<DialogflowWrapper.KnowledgeArticleWrapper> responseList = new List<DialogflowWrapper.KnowledgeArticleWrapper>();
            for (Knowledge__kav article : articles) {
                if (accessMap.containsKey(article.Id) && accessMap.get(article.Id).HasReadAccess) {
                    responseList.add(new DialogflowWrapper.KnowledgeArticleWrapper(article));
                }
            }
            
            // Send success response
            DialogflowResponseHandler.sendSuccess(
                'Knowledge articles retrieved successfully',
                responseList
            );
            
        } catch (Exception e) {
            DialogflowResponseHandler.handleException(e);
        }
    }
}