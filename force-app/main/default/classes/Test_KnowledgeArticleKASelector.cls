@isTest
private class Test_KnowledgeArticleKASelector {
    @testSetup
    private static void createTestData() {
        KCSDataFactory.setup();
        KCSDataFactory.createAndPublishArticlesAsUser(
            KCSDataFactory.publisher,
            KnowledgeArticleService.STATUS_DRAFT,
            10
        );
    }

    @isTest
    private static void testSelectDefaultArticles() {
        List<Knowledge__ka> articles = (List<Knowledge__ka>) new KnowledgeArticleKASelector()
            .selectDefaultArticles()
            .executeQuery();

        System.assertEquals(10, articles.size(), 'Not all articles were retrieved');
    }

    @isTest
    private static void testSelectArticlesById() {
        List<Knowledge__ka> articles =
            (List<Knowledge__ka>) new KnowledgeArticleKASelector(false, false)
            .selectDefaultArticles()
            .executeQuery();
        System.assertEquals(10, articles.size(), 'Not all articles were retrieved');
        String articleNumberToFind = articles.get(0).ArticleNumber;

        List<Knowledge__ka> foundArticle = (List<Knowledge__ka>) new KnowledgeArticleKASelector()
            .selectArticlesById(new List<Object>{new List<String>{articles.get(0).Id}})
            .executeQuery();

        System.assertEquals(1, foundArticle.size(), 'No articles were found');
        System.assertEquals(articleNumberToFind, foundArticle.get(0).ArticleNumber, 'Wrong article was found');
    }

    @isTest
    private static void testSelectArticleByArticleNumber() {
        List<Knowledge__ka> articles =
            (List<Knowledge__ka>) new KnowledgeArticleKASelector()
                .selectDefaultArticles()
                .executeQuery();
        System.assertEquals(10, articles.size(), 'Not all articles were retrieved');
        String articleNumberToFind = articles.get(0).Id;

        List<Knowledge__ka> foundArticle = (List<Knowledge__ka>) new KnowledgeArticleKASelector()
            .selectArticleByArticleNumber(new List<Object>{articles.get(0).ArticleNumber})
            .executeQuery();

        System.assertEquals(1, foundArticle.size(), 'No articles were found');
        System.assertEquals(articleNumberToFind, foundArticle.get(0).Id, 'Wrong article was found');
    }
}