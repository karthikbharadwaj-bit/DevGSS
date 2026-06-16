@isTest
private class Test_ArticleVersionsController {
    private static final Integer ARTICLES_QUANTITY = 1;

    @testSetup
    private static void testSetup() {
        KCSDataFactory.setup();
        KCSDataFactory.createAndPublishArticlesAsUser(
            KCSDataFactory.publisher,
            KnowledgeArticleService.STATUS_DRAFT,
            ARTICLES_QUANTITY
        );
    }

    @isTest
    private static void testArticleVersionsController_AsNotKnowledgeUser() {
        System.runAs(KCSDataFactory.notKnowledgeUser) {
            try {
                ArticleVersionsController controller = new ArticleVersionsController();
                controller.getVersions();
                System.assert(false, 'Exception not thrown when trying to access the page');
            } catch(Exception ex) {
                System.assertEquals(
                    Label.KCS_No_permissions_to_access_page,
                    ex.getMessage(),
                    'Wrong error message');
            }
        }
    }

    @isTest
    private static void testGetKnowledgeArticle_WhenArticleNumberIsValid_AsKnowledgeUser() {
        System.runAs(KCSDataFactory.expert) {
            List<Knowledge__kav> articleKavs =
                (List<Knowledge__kav>) new KnowledgeArticleSelector()
                    .selectArticles()
                    .executeQuery();
            System.assertEquals(1, articleKavs.size(), 'Wrong test data was created');

            PageReference pageRef = Page.ArticleVersions;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage()
                .getParameters()
                .put(ArticleVersionsController.ARTICLE_NUMBER, articleKavs.get(0).ArticleNumber);
            ArticleVersionsController controller = new ArticleVersionsController();
            System.assertEquals(
                articleKavs.get(0).KnowledgeArticleId,
                controller.getLastVersionArticle().KnowledgeArticleId,
                'Wrong Article was found'
            );
        }
    }

    @isTest
    private static void testGetKnowledgeArticle_WhenArticleNumberIsNotValid_AsKnowledgeUser() {
        System.runAs(KCSDataFactory.expert) {
            List<Knowledge__kav> articleKavs =
                (List<Knowledge__kav>) new KnowledgeArticleSelector()
                    .selectArticles()
                    .executeQuery();
            System.assertEquals(1, articleKavs.size(), 'Wrong test data was created');

            PageReference pageRef = Page.ArticleVersions;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put(ArticleVersionsController.ARTICLE_NUMBER, null);
            ArticleVersionsController controller = new ArticleVersionsController();
            System.assertEquals(null, controller.getLastVersionArticle(), 'Wrong Article was found');
        }
    }

    @isTest
    private static void testGetArticleVersions_AsKnowledgeUser() {
        System.runAs(KCSDataFactory.reader) {
            List<Knowledge__kav> articleKavs =
                (List<Knowledge__kav>) new KnowledgeArticleSelector()
                    .selectArticles()
                    .executeQuery();
            System.assertEquals(1, articleKavs.size(), 'Wrong test data was created');

            Knowledge__kav articleKav = articleKavs.get(0);

            PageReference pageRef = Page.ArticleVersions;
            Test.setCurrentPage(pageRef);

            ApexPages.currentPage()
                .getParameters()
                .put(ArticleVersionsController.ARTICLE_NUMBER, articleKav.ArticleNumber);
            ArticleVersionsController controller = new ArticleVersionsController();

            System.assert(!controller.getVersions().isEmpty(), 'At least one Article Version should be found');
            System.assertEquals(1, controller.getVersions().size(), 'Wrong Article Versions were found');
        }
    }

    @isTest
    private static void testGetArticleVersions_WhenIdIsNotValid_AsKnowledgeUser() {
        System.runAs(KCSDataFactory.reader) {
            ArticleVersionsController controller = new ArticleVersionsController();
            System.assert(
                controller.getAllArticleVersions('', 'en_US').isEmpty(), 'Wrong article was found'
            );
        }
    }

    @isTest
    private static void testGetArticleVersions_WhenArticleHasMoreThanOneVersions_AsKnowledgeUser() {
        System.runAs(KCSDataFactory.expert) {
            List<Knowledge__kav> articleKavs =
                (List<Knowledge__kav>) new KnowledgeArticleSelector()
                    .selectArticles()
                    .executeQuery();
            System.assertEquals(1, articleKavs.size(), 'Wrong test data was created');

            Knowledge__kav articleKav = articleKavs.get(0);
            KbManagement.PublishingService.editOnlineArticle(articleKav.KnowledgeArticleId, false);
            KbManagement.PublishingService.publishArticle(articleKav.KnowledgeArticleId, true);

            PageReference pageRef = Page.ArticleVersions;
            Test.setCurrentPage(pageRef);

            ApexPages.currentPage().getParameters().put(ArticleVersionsController.ARTICLE_NUMBER, articleKavs.get(0).ArticleNumber);
            ArticleVersionsController controller = new ArticleVersionsController();

            System.assertEquals(
                2,
                controller.setCon.getRecords().size(),
                'Wrong number of article versions was found'
            );
        }
    }
}