@isTest
private class Test_ArticleSubmissionsControllerExt {
    private static final Integer ARTICLES_QUANTITY = 30;

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
    private static void testArticleSubmissionsController_AsReader_ShouldFailNoAccess() {
        System.runAs(KCSDataFactory.reader) {
            try {
                ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();
                System.assert(false, 'Exception not thrown when trying to access the page');
            } catch (Exception ex) {
                System.assertEquals(
                    Label.KCS_No_permissions_to_access_page,
                    ex.getMessage(),
                    'Wrong exception message when trying to access the page'
                );
            }
        }
    }

    @isTest
    private static void testArticleSubmissionsController_AsCandidate() {
        System.runAs(KCSDataFactory.candidate) {
            ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();
            System.assertEquals(
                KnowledgeArticleService.ALL_ACTIVE,
                controller.filter,
                'Page filter is not ' + KnowledgeArticleService.ALL_ACTIVE);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleSubmissionsControllerExtension.ASCENDING);
        }
    }

    @isTest
    private static void testArticleSubmissionsController_AsContributor() {
        System.runAs(KCSDataFactory.contributor) {
            ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();
            System.assertEquals(
                KnowledgeArticleService.ALL_ACTIVE,
                controller.filter,
                'Page filter is not ' + KnowledgeArticleService.ALL_ACTIVE);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleSubmissionsControllerExtension.ASCENDING);
        }
    }

    @isTest
    private static void testArticleSubmissionsController_AsPublisher() {
        System.runAs(KCSDataFactory.publisher) {
            ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();
            System.assertEquals(
                KnowledgeArticleService.ALL_ACTIVE,
                controller.filter,
                'Page filter is not ' + KnowledgeArticleService.ALL_ACTIVE);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleSubmissionsControllerExtension.ASCENDING);
        }
    }

    @isTest
    private static void testArticleSubmissionsController_AsCoach() {
        System.runAs(KCSDataFactory.coach) {
            ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();
            System.assertEquals(
                KnowledgeArticleService.ALL_ACTIVE,
                controller.filter,
                'Page filter is not ' + KnowledgeArticleService.ALL_ACTIVE);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleSubmissionsControllerExtension.ASCENDING);
        }
    }

    @isTest
    private static void testArticleSubmissionsController_AsExpert() {
        System.runAs(KCSDataFactory.expert) {
            ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();
            System.assertEquals(
                KnowledgeArticleService.ALL_ACTIVE,
                controller.filter,
                'Page filter is not ' + KnowledgeArticleService.ALL_ACTIVE);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleSubmissionsControllerExtension.ASCENDING);
        }
    }

    @isTest
    private static void testArticleSubmissionsController_DefaultValues() {
        System.runAs(KCSDataFactory.publisher) {
            ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();
            System.assertEquals(
                KnowledgeArticleService.ALL_ACTIVE,
                controller.filter,
                'Page filter is not ' + KnowledgeArticleService.ALL_ACTIVE);
            System.assertEquals(
                KnowledgeArticleService.ENGLISH,
                controller.lang,
                'Language filter is not ' + KnowledgeArticleService.ENGLISH);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleSubmissionsControllerExtension.ASCENDING);
            System.assertEquals(2, controller.getTotalPages(), 'There are less/more than 2 pages');
        }
    }

    @isTest
    private static void testArticleSubmissionsController_Pagination() {
        System.runAs(KCSDataFactory.publisher) {
            ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();
            System.assertEquals(1, controller.pageNumber, 'Current page is not first');
            System.assert(controller.hasNext, 'No next page was found');
            System.assert(!controller.hasPrevious, 'Previous page was found');

            controller.next();
            System.assertEquals(2, controller.pageNumber, 'Current page is not second');
            System.assert(!controller.hasNext, 'Next page was found');
            System.assert(controller.hasPrevious, 'No previous page was found');

            controller.previous();
            System.assertEquals(1, controller.pageNumber, 'Current page is not first');
            System.assert(controller.hasNext, 'No next page was found');
            System.assert(!controller.hasPrevious, 'Previous page was found');

            controller.last();
            System.assertEquals(2, controller.pageNumber, 'Current page is not second');
            System.assert(!controller.hasNext, 'Next page was found');
            System.assert(controller.hasPrevious, 'No previous page was found');

            controller.first();
            System.assertEquals(1, controller.pageNumber, 'Current page is not first');
            System.assert(controller.hasNext, 'No next page was found');
            System.assert(!controller.hasPrevious, 'Previous page was found');
        }
    }

    @isTest
    private static void testArticleSubmissionsController_ListViewFilterChanges_Published() {
        System.runAs(KCSDataFactory.publisher) {
            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticles()
                .executeQuery();

            ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();

            KnowledgeArticleService.approveDraftArticle(articles.get(0));
            controller.filter = KnowledgeArticleService.PUBLISHED;
            System.assertEquals(
                KnowledgeArticleService.PUBLISHED,
                controller.filter,
                'Page filter is not ' + KnowledgeArticleService.PUBLISHED);
            controller.refresh();
            System.assertEquals(1, controller.con.getResultSize(), 'The number of articles found is not equal 1');
            System.assert(!controller.hasNext, 'Next page was found');
        }
    }

    @isTest
    private static void testArticleSubmissionsController_ListViewFilterChanges_Rejected() {
        System.runAs(KCSDataFactory.publisher) {
            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticles()
                .executeQuery();

            ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();

            KnowledgeArticleService.rejectDraftArticle(articles.get(1), '');
            controller.filter = KnowledgeArticleService.REJECTED;
            System.assertEquals(
                KnowledgeArticleService.REJECTED,
                controller.filter,
                'Page filter is not ' + KnowledgeArticleService.REJECTED);
            controller.refresh();
            System.assertEquals(1, controller.con.getResultSize(), 'The number of articles found is not equal 1');
            System.assert(!controller.hasNext, 'Next page was found');
        }
    }

    @isTest
    private static void testArticleSubmissionsController_LanguageFilterChanges() {
        System.runAs(KCSDataFactory.publisher) {
            ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();

            controller.lang = KnowledgeArticleService.FRENCH;
            System.assertEquals(
                KnowledgeArticleService.FRENCH,
                controller.lang,
                'Language filter is not ' + KnowledgeArticleService.FRENCH);
            controller.refresh();
            System.assertEquals(
                0,
                controller.con.getResultSize(),
                'The number of articles found is not equal ' + ARTICLES_QUANTITY);
            System.assert(!controller.hasNext, 'Next page was found');

            controller.lang = KnowledgeArticleService.GERMAN;
            System.assertEquals(
                KnowledgeArticleService.GERMAN,
                controller.lang,
                'Language filter is not ' + KnowledgeArticleService.GERMAN);
            controller.refresh();
            System.assertEquals(
                0,
                controller.con.getResultSize(),
                'The number of articles found is not equal ' + ARTICLES_QUANTITY);
            System.assert(!controller.hasNext, 'Next page was found');

            controller.lang = KnowledgeArticleService.SPANISH;
            System.assertEquals(
                KnowledgeArticleService.SPANISH,
                controller.lang,
                'Language filter is not ' + KnowledgeArticleService.SPANISH);
            controller.refresh();
            System.assertEquals(
                0,
                controller.con.getResultSize(),
                'The number of articles found is not equal ' + ARTICLES_QUANTITY);
            System.assert(!controller.hasNext, 'Next page was found');
        }
    }

    @isTest
    private static void testArticleSubmissionsController_ToggleSort() {
        System.runAs(KCSDataFactory.publisher) {
            ArticleSubmissionsControllerExtension controller = new ArticleSubmissionsControllerExtension();
            System.assertEquals(
                ArticleSubmissionsControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleSubmissionsControllerExtension.ASCENDING);

            controller.sortField = 'TimeSinceSubmission__c';
            controller.toggleSort();
            System.assertEquals(
                ArticleSubmissionsControllerExtension.DESCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleSubmissionsControllerExtension.DESCENDING);
            System.assertEquals(
                'TimeSinceSubmission_ms__c',
                controller.sortField,
                'Sort field is not TimeSinceSubmission_ms__c');

            controller.sortField = null;
            controller.toggleSort();
            System.assertEquals(
                ArticleSubmissionsControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleSubmissionsControllerExtension.ASCENDING);
            System.assertEquals(
                ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleSubmissionsControllerExtension.DEFAULT_SORT_FIELD);

            controller.sortField = 'WrongField';
            try {
                controller.toggleSort();
                System.assert(false, 'Exception not thrown when trying to retrieve wrong fields');
            } catch (Exception ex) {
                System.assertEquals(
                    'Invalid field \'WrongField\' for object \'Knowledge__kav\'',
                    ex.getMessage(),
                    'Wrong exception message on toggle sort'
                );
            }
        }
    }
}