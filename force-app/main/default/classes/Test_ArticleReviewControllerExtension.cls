@isTest
private class Test_ArticleReviewControllerExtension {
    private static final Integer ARTICLES_QUANTITY = 30;
    private static final String ERROR_NO_ACCESS = 'Wrong exception message when trying to access the page';
    private static final String ERROR_NO_EXCEPTION = 'Wrong exception message when trying to access the page';

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
    private static void testArticleReviewControllerExtension_AsReader_ShouldFailNoAccess() {
        System.runAs(KCSDataFactory.reader) {
            try {
                ArticleReviewControllerExtension controller = new ArticleReviewControllerExtension();
                System.assert(false, ERROR_NO_EXCEPTION);
            } catch (Exception ex) {
                System.assertEquals(Label.KCS_No_permissions_to_access_page, ex.getMessage(), ERROR_NO_ACCESS);
            }
        }
    }

    @isTest
    private static void testArticleReviewControllerExtension_AsCandidate_ShouldFailNoAccess() {
        System.runAs(KCSDataFactory.candidate) {
            try {
                ArticleReviewControllerExtension controller = new ArticleReviewControllerExtension();
                System.assert(false, ERROR_NO_EXCEPTION);
            } catch (Exception ex) {
                System.assertEquals(Label.KCS_No_permissions_to_access_page, ex.getMessage(), ERROR_NO_ACCESS);
            }
        }
    }

    @isTest
    private static void testArticleReviewControllerExtension_AsContributor() {
        System.runAs(KCSDataFactory.contributor) {
            ArticleReviewControllerExtension controller = new ArticleReviewControllerExtension();
            System.assertEquals(
                ArticleReviewControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleReviewControllerExtension.DEFAULT_SORT_FIELD);
            System.assertEquals(
                ArticleReviewControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleReviewControllerExtension.ASCENDING);
        }
    }

    @isTest
    private static void testArticleReviewControllerExtension_AsPublisher() {
        System.runAs(KCSDataFactory.publisher) {
            ArticleReviewControllerExtension controller = new ArticleReviewControllerExtension();
            System.assertEquals(
                ArticleReviewControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleReviewControllerExtension.DEFAULT_SORT_FIELD);
            System.assertEquals(
                ArticleReviewControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleReviewControllerExtension.ASCENDING);
        }
    }

    @isTest
    private static void testArticleReviewControllerExtension_AsCoach() {
        System.runAs(KCSDataFactory.coach) {
            ArticleReviewControllerExtension controller = new ArticleReviewControllerExtension();
            System.assertEquals(
                ArticleReviewControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleReviewControllerExtension.DEFAULT_SORT_FIELD);
            System.assertEquals(
                ArticleReviewControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleReviewControllerExtension.ASCENDING);
        }
    }

    @isTest
    private static void testArticleReviewControllerExtension_AsExpert() {
        System.runAs(KCSDataFactory.expert) {
            ArticleReviewControllerExtension controller = new ArticleReviewControllerExtension();
            System.assertEquals(
                ArticleReviewControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleReviewControllerExtension.DEFAULT_SORT_FIELD);
            System.assertEquals(
                ArticleReviewControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleReviewControllerExtension.ASCENDING);
        }
    }

    @isTest
    private static void testArticleReviewControllerExtension_DefaultValues() {
        System.runAs(KCSDataFactory.publisher) {
            ArticleReviewControllerExtension controller = new ArticleReviewControllerExtension();
            System.assertEquals(
                ArticleReviewControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleReviewControllerExtension.DEFAULT_SORT_FIELD);
            System.assertEquals(
                KnowledgeArticleService.ENGLISH,
                controller.lang,
                'Language filter is not ' + KnowledgeArticleService.ENGLISH);
            System.assertEquals(
                ArticleReviewControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleReviewControllerExtension.ASCENDING);
            System.assertEquals(2, controller.getTotalPages(), 'There are less/more than 2 pages');
        }
    }

    @isTest
    private static void testArticleReviewControllerExtension_Pagination() {
        System.runAs(KCSDataFactory.publisher) {
            ArticleReviewControllerExtension controller = new ArticleReviewControllerExtension();
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
    private static void testArticleReviewControllerExtension_ToggleSort() {
        System.runAs(KCSDataFactory.publisher) {
            ArticleReviewControllerExtension controller = new ArticleReviewControllerExtension();
            System.assertEquals(
                ArticleReviewControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleReviewControllerExtension.ASCENDING);

            controller.sortField = 'TimeSinceSubmission__c';
            controller.toggleSort();
            System.assertEquals(
                ArticleReviewControllerExtension.DESCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleReviewControllerExtension.DESCENDING);
            System.assertEquals(
                'TimeSinceSubmission_ms__c',
                controller.sortField,
                'Sort field is not TimeSinceSubmission_ms__c');

            controller.sortField = null;
            controller.toggleSort();
            System.assertEquals(
                ArticleReviewControllerExtension.ASCENDING,
                controller.sortDir,
                'Sort direction is not ' + ArticleReviewControllerExtension.ASCENDING);
            System.assertEquals(
                ArticleReviewControllerExtension.DEFAULT_SORT_FIELD,
                controller.sortField,
                'Sort field is not ' + ArticleReviewControllerExtension.DEFAULT_SORT_FIELD);

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

    @isTest
    private static void testArticleReviewControllerExtension_LanguageFilterChanges() {
        System.runAs(KCSDataFactory.publisher) {
            ArticleReviewControllerExtension controller = new ArticleReviewControllerExtension();

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
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testForArticleCategorySelectorClass(){
        Test.startTest();
        ArticleCategorySelector selector  = new ArticleCategorySelector();
        selector.getSObjectType();
        selector.selectArticleCategoryByArticleTitleOrKeyword(new List<String>{'US', 'time'});
        new ArticleCategorySelector(false, false);
        Test.stopTest();
    }
}