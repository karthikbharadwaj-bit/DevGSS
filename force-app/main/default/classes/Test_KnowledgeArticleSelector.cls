@isTest
private class Test_KnowledgeArticleSelector {
    private static final String DRAFT_TITLE_PREFIX = KnowledgeArticleService.DRAFT_PREFIX;
    private static final String ERROR_MESSAGE_FIELD_IS_NOT_RETURNED_CORRECT = 'field is not returned correct';
    private static final String ERROR_MESSAGE_SHOULD_BE_EXCEPTION = 'Should throw an SObjectException';
    private static final String ERROR_MESSAGE_SOBJECT_EXCEPTION =
        'SObject row was retrieved via SOQL without querying the requested field: ';
    private static final String ERROR_MESSAGE_SHOULD_BE_DIFFERENT_EXCEPTION_MESSAGE =
        'Error message should be different';

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
    private static void testSelectArticles() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticles()
            .executeQuery();

        System.assertEquals(10, articles.size(), 'There should be ' + articles.size() + ' article(s)');
        System.assert(
            articles[0].Title.contains(DRAFT_TITLE_PREFIX + KCSDataFactory.ARTICLE_TITLE),
            'Title ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNED_CORRECT);
        System.assertEquals(
            KCSDataFactory.ARTICLE_LANGUAGE,
            articles[0].Language,
            'Language ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNED_CORRECT);
        System.assertEquals(
            KCSDataFactory.ARTICLE_SUMMARY,
            articles[0].Summary,
            'Summary ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNED_CORRECT);
    }

    @isTest
    private static void testSelectArticleByTitle() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String> {
                DRAFT_TITLE_PREFIX + KCSDataFactory.ARTICLE_TITLE + '1'
            })
            .executeQuery();

        System.assertEquals(1, articles.size(), 'There should be ' + articles.size() + ' article(s)');
        System.assert(
            articles[0].Title.contains(DRAFT_TITLE_PREFIX + KCSDataFactory.ARTICLE_TITLE),
            'Title ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNED_CORRECT);
        System.assertEquals(
            KCSDataFactory.ARTICLE_LANGUAGE,
            articles[0].Language,
            'Language ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNED_CORRECT);
        System.assertEquals(
            KCSDataFactory.ARTICLE_SUMMARY,
            articles[0].Summary,
            'Summary ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNED_CORRECT);
    }

    @isTest
    private static void testSelectArticleById() {
        List<Knowledge__kav> articles =
            (List<Knowledge__kav>) new KnowledgeArticleSelector(false, false)
            .selectArticles()
            .executeQuery();
        System.assertEquals(10, articles.size(), 'There should be ' + articles.size() + ' article(s)');
        String articleId = articles.get(0).Id;
        String articleTitleToFind = articles.get(0).Title;

        List<Knowledge__kav> foundArticle = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleById(new List<Object>{new List<String>{articleId}})
            .executeQuery();

        System.assertEquals(1, foundArticle.size(), 'No articles were found');
        System.assertEquals(articleTitleToFind, foundArticle.get(0).Title, 'Wrong article was found');
    }

    @isTest
    private static void testSelectArticleByArticleNumber() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticles()
            .executeQuery();
        System.assertEquals(10, articles.size(), 'There should be ' + articles.size() + ' article(s)');
        String articleNumber = articles.get(0).ArticleNumber;
        String articleTitleToFind = articles.get(0).Title;

        List<Knowledge__kav> foundArticle = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByArticleNumber(new List<Object>{new List<String>{articleNumber}})
            .executeQuery();

        System.assertEquals(1, foundArticle.size(), 'No articles were found');
        System.assertEquals(articleTitleToFind, foundArticle.get(0).Title, 'Wrong article was found');
    }

    @isTest
    private static void testSelectArticlesNotReturnNotDefaultFieldList() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticles()
            .executeQuery();
        System.assertEquals(10, articles.size(), 'There should be ' + articles.size() + ' article(s)');

        try {
            String fieldWhichWasNotRetrieved = articles[0].RC_Knowledge_Article_Legacy_Article_ID__c;
            System.assert(false, ERROR_MESSAGE_SHOULD_BE_EXCEPTION);
        } catch (SObjectException ex) {
            System.assertEquals(ERROR_MESSAGE_SOBJECT_EXCEPTION + 'Knowledge__kav.RC_Knowledge_Article_Legacy_Article_ID__c',
                ex.getMessage(), ERROR_MESSAGE_SHOULD_BE_DIFFERENT_EXCEPTION_MESSAGE);
        }
    }

    @isTest
    private static void testSelectDraftArticles() {
        List<Knowledge__kav> draftArticles =
            (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticlesByValidationAndPublishStatuses(
                    new List<Object> {
                        KnowledgeArticleService.VALIDATION_STATUSES_BY_FILTER.get(KnowledgeArticleService.DRAFTS),
                        KnowledgeArticleService.LANGUAGE_DEFAULT
                    }, false, false)
                .executeQuery();

        System.assertEquals(10, draftArticles.size(), 'The number of articles found is not equal 10');
    }

    @isTest
    private static void testSelectPublishedArticles() {
        System.runAs(KCSDataFactory.publisher) {
            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticles()
                .executeQuery();

            KnowledgeArticleService.approveDraftArticle(articles.get(0));

            List<Knowledge__kav> publishedArticles =
                (List<Knowledge__kav>) new KnowledgeArticleSelector()
                    .selectArticlesByValidationAndPublishStatuses(
                        new List<Object> {
                            KnowledgeArticleService.VALIDATION_STATUSES_BY_FILTER.get(KnowledgeArticleService.PUBLISHED),
                            KnowledgeArticleService.LANGUAGE_DEFAULT
                        }, false, false)
                    .executeQuery();

            System.assertEquals(1, publishedArticles.size(), 'The number of articles found is not equal 1');
        }
    }

    @isTest
    private static void testSelectRejectedArticles() {
        System.runAs(KCSDataFactory.publisher) {
            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticles()
                .executeQuery();

            KnowledgeArticleService.rejectDraftArticle(articles.get(0), '');

            List<Knowledge__kav> rejectedArticles =
                (List<Knowledge__kav>) new KnowledgeArticleSelector()
                    .selectArticlesByValidationAndPublishStatuses(
                        new List<Object> {
                            KnowledgeArticleService.VALIDATION_STATUSES_BY_FILTER.get(KnowledgeArticleService.REJECTED),
                            KnowledgeArticleService.LANGUAGE_DEFAULT
                        }, true, false)
                    .executeQuery();

            System.assertEquals(1, rejectedArticles.size(), 'The number of articles found is not equal 1');
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testArticlesByIdsWithNullKnowledgeArticleURL() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticles()
            .executeQuery();

        List<Knowledge__kav> rcKAList = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticlesByIdsWithNullKnowledgeArticleURL(new List<Object>{articles})
            .executeQuery();
        
        //System.assertEquals(10, rcKAList.size(), 'The number of articles without filled URL is 0');
    }
    
    @isTest
    private static void testArticlesWithFieldsForEmailNotifications() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticlesWithFieldsForEmailNotifications()
            .executeQuery();
        
        System.assertEquals(10, articles.size(), 'The number of articles is 10');
        for (Knowledge__kav article : articles) {
            System.assertEquals(KnowledgeArticleTriggerHelper.baseURL + article.KnowledgeArticleId, 
                article.RC_Knowledge_Article_Knowledge_Article10__c, 'Knowledge_Article_URL__c is different');
            System.assertEquals(null, article.RC_Knowledge_Article_EmailOfArticleCre11__c, 
                'EmailOfArticleCreatorManager__c is different');
            System.assertEquals('Draft', article.RC_Knowledge_Article_Old_ValidationSta24__c, 'Old_ValidationStatus__c is different');
        }
    }
}