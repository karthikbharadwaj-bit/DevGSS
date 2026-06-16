@RestResource(urlMapping='/getKnowledgeArticlesForGCP')
global with sharing class DialogFlowGetKnowledgeArticlesGCP {

     public static Boolean testThrowException = false;
    
    @HttpGet
    global static void getKnowledgeArticlesBySubject() {
        try {
            if (Test.isRunningTest() && testThrowException) {
                throw new DialogflowResponseHandler.DialogflowException('Simulated exception');
            }

            List<Knowledge__kav> allPublishedArticles = KnowledgeArticleSelectorDialogflow.getInstance().getAllPublishedArticles();

            List<Map<String, String>> responseList = new List<Map<String, String>>();
            for (Knowledge__kav ka : allPublishedArticles) {
                    responseList.add(new Map<String, String>{
                        'article_number' => ka.ArticleNumber,
                        'title' => ka.Title,
                        'summary' => ka.Summary
                    });
            }

            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serialize(responseList));
            res.statusCode = 200;

        } catch (Exception e) {
            DialogflowResponseHandler.handleException(e);
        }
    }
}