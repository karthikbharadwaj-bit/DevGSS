@isTest
private class DialogFlowGetSimilarArticlesTest {
    
    
    @isTest
    static void testGetKnowledgeArticlesBySubject_Success() {

    Profile p = [SELECT Id FROM Profile WHERE Name='Support Manager - KB'];
    User testUser = new User(
        Alias = 'tuser',
        Email = 'testuser@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Testing',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testuser@test.com' + System.currentTimeMillis(),
        KCS_Role__c='KCS Coach'
    );
    insert testUser;
    System.runAs(testUser) {
            List<Knowledge__kav> testArticles = new List<Knowledge__kav>();
            
            Knowledge__kav testArticle1 = new Knowledge__kav(
                Title = 'Test Article1',
                URLName = 'Test-Article1',
                Language = 'en_US'
            );      
            testArticles.add(testArticle1);
            
            Knowledge__kav testArticle2 = new Knowledge__kav(
                Title = 'Test Article2',
                URLName = 'Test-Article2',
                Language = 'en_US'
            );      
            testArticles.add(testArticle2);
            insert testArticles;
            
            Test.startTest();
            
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getKnowledgeArticles';
            req.httpMethod = 'POST';
            
            Map<String, Object> requestBody = new Map<String, Object>{
                'salesforceUserId' => testUser.Id,
                    'topic' => 'Article'
                    };
                        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
            
            RestContext.request = req;
            RestContext.response = new RestResponse();
            
            DialogFlowGetSimilarArticles.getKnowledgeArticlesBySubject();
            
            Test.stopTest();
            
            // Assert
            String responseBody = RestContext.response.responseBody.toString();
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            
            System.assertEquals(200, RestContext.response.statusCode, 'Should return success status code');
            System.assertEquals(true, responseMap.get('success'), 'Response should indicate success');
            List<Object> articles = (List<Object>)responseMap.get('Article');
        }
    }
    
}