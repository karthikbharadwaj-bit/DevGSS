@IsTest
private class DialogFlowGetKnowledgeArticlesGCPTest {

    private static final String TEST_ARTICLE_TITLE = 'Test title';
    private static final String ADMIN_USERNAME =
        (String) ValueProviderBuilder.provideUniqueEmail('adminTest').getValue();

    @testSetup
    static void testSetup() {
        KCSDataFactory.setup();

        // Create user
        User adminUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.Username, ADMIN_USERNAME)
            .create()
            .getRecord();

        System.runAs(KCSDataFactory.expert) {
            // Create draft article
            Knowledge__kav newArticle = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Knowledge__kav.Title => TEST_ARTICLE_TITLE,
                    Knowledge__kav.Language => 'en_US',
                    Knowledge__kav.UrlName => 'test-url',
                    Knowledge__kav.RC_Knowledge_Article_Details__c => 'testDetails',
                    Knowledge__kav.Summary => 'testSummary',
                    Knowledge__kav.RC_Knowledge_Article_Key_Words__c => 'test,test_test'
                })
                .create()
                .getRecord();

            // Publish article
            List<String> articleIds = new List<String>{ newArticle.Id };
            List<Knowledge__kav> articles = new KnowledgeArticleSelector()
                .selectArticlesById(new List<List<String>>{articleIds})
                .executeQuery();

            if (!articles.isEmpty()) {
                KbManagement.PublishingService.publishArticle(articles[0].KnowledgeArticleId, true);
            }
        }
    }

    @IsTest
    static void testGetKnowledgeArticlesBySubject() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/getKnowledgeArticlesForGCP';
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            DialogFlowGetKnowledgeArticlesGCP.getKnowledgeArticlesBySubject();
            Test.stopTest();
        }

        // Validate the response
        System.assertEquals(200, RestContext.response.statusCode, 'Expected status code to be 200');
        System.assertNotEquals(null, RestContext.response.responseBody, 'Response body should not be null');

        // Optionally deserialize and check size if applicable
        List<Object> responseBody = (List<Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        System.assert(!responseBody.isEmpty(), 'Response should contain at least one article');
    }

    @IsTest
    static void testExceptionPath() {
        DialogFlowGetKnowledgeArticlesGCP.testThrowException = true;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getKnowledgeArticlesForGCP';
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        DialogFlowGetKnowledgeArticlesGCP.getKnowledgeArticlesBySubject();
        Test.stopTest();

        // Assert 500 error on exception
        System.assertEquals(500, RestContext.response.statusCode, 'Expected status code to be 500 on exception');
    }
}