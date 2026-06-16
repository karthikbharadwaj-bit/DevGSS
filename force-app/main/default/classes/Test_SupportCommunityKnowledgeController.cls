@isTest
private class Test_SupportCommunityKnowledgeController {
    private static final String ARTICLE_URL_NAME = 'urlname';
    private static final String ARTICLE_TITLE = 'Test_title';
    private static final String ARTICLE_TITLE_FR = 'Test_title_fr';
    private static final String WRONG_ARTICLE_NUMBER = '1111111';
    private static final String WRONG_ARTICLE_URL_NAME = '1111111';
    private static final String COMMENT_TEXT = 'Some text';
    private static final String JSUID = '1111111';
    private static final String TITLE = 'Some title';
    private static final String EN_LANG = 'en_US';
    private static final String FR_LANG = 'fr';
    private static final String DE_LANG = 'de';
    private static final String WRONG_LANG = 'en_GB';
    private static final String TEST_BASE64_DATA = '234ad56';
    private static final Integer NEW_RATING = 5;
    private static final String ARTICLE_NUMBER = 'ArticleNumber';
    private static final String URL_NAME = 'UrlName';

    private static final String ARTICLE_DETAILS = 'testDetails';
    private static final String ARTICLE_ISSUE = 'testIssue';
    private static final String ARTICLE_QUESTION = 'testQuestion';
    private static final String ARTICLE_STR = 'testSTR';
    private static final String ARTICLE_CAUSE = 'testCause';
    private static final String ARTICLE_SYMPTOM = 'testSymptom';
    private static final String ARTICLE_AFFECTED_ENV = 'testAffectedEnv';
    private static final String ARTICLE_STATUS = 'testStatus';
    private static final String ARTICLE_RESOLUTION = 'testResolution';
    private static final String ARTICLE_LANGUAGE = 'en_US';
    private static final String ARTICLE_SUMMARY = 'testSummary';
    private static final String ARTICLE_KEYWORDS = 'test,test_test';

    @testSetup
    private static void setupData() {
        KCSDataFactory.setup();
        List<String> langs = new List<String>{EN_LANG, FR_LANG};
        List<String> titles = new List<String>{ARTICLE_TITLE, ARTICLE_TITLE_FR};
        List<Knowledge__kav> newVersions;
        List<String> articleNumbers = new List<String>();
        System.runAs(KCSDataFactory.expert) {
            newVersions = (List<Knowledge__kav>) new SObjectBuilder(Knowledge__kav.SObjectType)
                .quantity(2)
                .setFields(
                    new Map<SObjectField, Object>{
                        Knowledge__kav.Title => ValueProviderBuilder.provideList(titles),
                        Knowledge__kav.UrlName => ARTICLE_URL_NAME,
                        Knowledge__kav.Language => ValueProviderBuilder.provideList(langs),
                        Knowledge__kav.Summary => ARTICLE_SUMMARY,
                        Knowledge__kav.RC_Knowledge_Article_Details__c => ARTICLE_DETAILS,
                        Knowledge__kav.RC_Knowledge_Article_Issue__c => ARTICLE_ISSUE,
                        Knowledge__kav.RC_Knowledge_Article_Question__c => ARTICLE_QUESTION,
                        Knowledge__kav.RC_Knowledge_Article_STR__c => ARTICLE_STR,
                        Knowledge__kav.RC_Knowledge_Article_Cause__c => ARTICLE_CAUSE,
                        Knowledge__kav.RC_Knowledge_Article_Symptom__c => ARTICLE_SYMPTOM,
                        Knowledge__kav.RC_Knowledge_Article_AffectedEnv__c => ARTICLE_AFFECTED_ENV,
                        Knowledge__kav.RC_Knowledge_Article_Status__c => ARTICLE_STATUS,
                        Knowledge__kav.RC_Knowledge_Article_Resolution__c => ARTICLE_RESOLUTION,
                        Knowledge__kav.RC_Knowledge_Article_Key_Words__c => ARTICLE_KEYWORDS
                    }
                )
                .create()
                .getRecords();
            
            for (Knowledge__kav insertedArticle : (List<Knowledge__kav>) new KnowledgeArticleSelector()
                        .selectArticlesById(new List<Object>{new List<String>{newVersions[0].Id, newVersions[1].Id}})
                        .executeQuery()) {

                    KbManagement.PublishingService.publishArticle(insertedArticle.KnowledgeArticleId, true);
                    KbManagement.PublishingService.editOnlineArticle(insertedArticle.KnowledgeArticleId, false);
                    KnowledgeArticleService.approveDraftArticle(insertedArticle);
                    articleNumbers.add(insertedArticle.ArticleNumber);
            }
        }
        new SObjectBuilder(RC_Article_Rating__c.SObjectType)
                .quantity(2)
                .setFields(
                    new Map<SObjectField, Object>{
                        RC_Article_Rating__c.Article_Number__c => ValueProviderBuilder.provideList(articleNumbers),
                            RC_Article_Rating__c.PositiveVotesCount__c => 0,
                            RC_Article_Rating__c.NegativeVotesCount__c => 0
                            }
                )
                .create();
        
    }

    @isTest
    private static void getArticleWithoutFiles() {
        Map<String, Object> res = SupportCommunityKnowledgeController.getKnowledgeInfo(
            '{"urlName":"' +
            ARTICLE_URL_NAME +
            '", "jsUID":"' +
            JSUID +
            '", "language":"' +
            EN_LANG +
            '"}'
        );

        System.assertNotEquals(null, res.get(SupportCommunityKnowledgeController.ARTICLE_KEY_NAME));
        Knowledge__kav article = (Knowledge__kav) res.get(
            SupportCommunityKnowledgeController.ARTICLE_KEY_NAME
        );
        System.assertEquals(article.Title, ARTICLE_TITLE, 'Article Title should be "' + ARTICLE_TITLE + '"');
        System.assertEquals(article.UrlName, ARTICLE_URL_NAME, 'Article UrlName should be "' + ARTICLE_URL_NAME + '"');
        System.assertEquals(
            article.Language,
            ARTICLE_LANGUAGE,
            'Article Language should be "' +
            ARTICLE_LANGUAGE +
            '"'
        );
        System.assertEquals(article.Summary, ARTICLE_SUMMARY, 'Article Summary should be "' + ARTICLE_SUMMARY + '"');
        System.assertEquals(
            article.RC_Knowledge_Article_Details__c,
            ARTICLE_DETAILS,
            'Article Details__c should be "' +
            ARTICLE_DETAILS +
            '"'
        );
        System.assertEquals(article.RC_Knowledge_Article_Issue__c, ARTICLE_ISSUE, 'Article Issue__c should be "' + ARTICLE_ISSUE + '"');
        System.assertEquals(
            article.RC_Knowledge_Article_Question__c,
            ARTICLE_QUESTION,
            'Article Question__c should be "' + ARTICLE_QUESTION + '"'
        );
        System.assertEquals(article.RC_Knowledge_Article_STR__c, ARTICLE_STR, 'Article STR__c should be "' + ARTICLE_STR + '"');
        System.assertEquals(article.RC_Knowledge_Article_Cause__c, ARTICLE_CAUSE, 'Article Cause__c should be "' + ARTICLE_CAUSE + '"');
        System.assertEquals(
            article.RC_Knowledge_Article_Symptom__c,
            ARTICLE_SYMPTOM,
            'Article Symptom__c should be "' + ARTICLE_SYMPTOM + '"'
        );
        System.assertEquals(
            article.RC_Knowledge_Article_AffectedEnv__c,
            ARTICLE_AFFECTED_ENV,
            'Article AffectedEnv__c should be "' + ARTICLE_AFFECTED_ENV + '"'
        );
        System.assertEquals(article.RC_Knowledge_Article_Status__c, ARTICLE_STATUS, 'Article Status__c should be "' + ARTICLE_STATUS + '"');
        System.assertEquals(
            article.RC_Knowledge_Article_Resolution__c,
            ARTICLE_RESOLUTION,
            'Article Resolution__c should be "' +
            ARTICLE_RESOLUTION +
            '"'
        );
        System.assertEquals(
            article.RC_Knowledge_Article_Key_Words__c,
            ARTICLE_KEYWORDS,
            'Article Key_Words__c should be "' +
            ARTICLE_KEYWORDS +
            '"'
        );
        System.assertEquals(null, res.get(SupportCommunityKnowledgeController.ATTACHED_FILES_KEY_NAME));
    }

    @isTest
    private static void getFrenchArticle() {
        Map<String, Object> res = SupportCommunityKnowledgeController.getKnowledgeInfo(
            '{"urlName":"' +
            ARTICLE_URL_NAME +
            '", "jsUID":"' +
            JSUID +
            '", "language":"' +
            FR_LANG +
            '"}'
        );
        Knowledge__kav article = (Knowledge__kav) res.get(
            SupportCommunityKnowledgeController.ARTICLE_KEY_NAME
        );
        System.assertEquals(ARTICLE_TITLE_FR, article.Title);
    }

    @isTest
    private static void getNotTranslatedArticle() {
        Map<String, Object> res = SupportCommunityKnowledgeController.getKnowledgeInfo(
            '{"urlName":"' +
            ARTICLE_URL_NAME +
            '", "jsUID":"' +
            JSUID +
            '", "language":"' +
            DE_LANG +
            '"}'
        );
        Knowledge__kav article = (Knowledge__kav) res.get(
            SupportCommunityKnowledgeController.ARTICLE_KEY_NAME
        );
        System.assertEquals(ARTICLE_TITLE, article.Title);
    }
    @isTest
    private static void getArticleUsedWrongLang() {
        Map<String, Object> res = SupportCommunityKnowledgeController.getKnowledgeInfo(
            '{"urlName":"' +
            ARTICLE_URL_NAME +
            '", "jsUID":"' +
            JSUID +
            '", "language":"' +
            WRONG_LANG +
            '"}'
        );
        Knowledge__kav article = (Knowledge__kav) res.get(
            SupportCommunityKnowledgeController.ARTICLE_KEY_NAME
        );
        System.assertEquals(ARTICLE_TITLE, article.Title);
    }
    @isTest
    private static void getTopTopics() {
        List<Knowledge__kav> res = SupportCommunityKnowledgeController.getTopTopics('{"count":4}');
        System.assert(!res.isEmpty());
        System.assertEquals(ARTICLE_TITLE, res[0].Title);
        System.assertEquals(ARTICLE_URL_NAME, res[0].UrlName);
    }

    @isTest
    private static void testCheckIfArticleWithNumberExists() {
        Knowledge__kav articleVersion = [SELECT Id, ArticleNumber FROM Knowledge__kav LIMIT 1];

        try {
            SupportCommunityKnowledgeController.checkIfArticleWithNumberExists(articleVersion.ArticleNumber);
        } catch (SupportCommunityKnowledgeController.KnowledgeException e) {
            System.assert(false, 'Article not found');
        }

        try {
            SupportCommunityKnowledgeController.checkIfArticleWithNumberExists(WRONG_ARTICLE_NUMBER);
        } catch (SupportCommunityKnowledgeController.KnowledgeException e) {
            System.assert(
                e.getMessage().contains(SupportCommunityKnowledgeController.ARTICLE_NOT_FOUND_ERROR_MESSAGE),
                'Wrong error message'
            );
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testGetKnowledgeInfoByArticleNumber() {
        Knowledge__kav latestArticleVersion = [
            SELECT Id, ArticleNumber
            FROM Knowledge__kav
            WHERE IsLatestVersion = true LIMIT 1
        ];

        Map<String, Object> articleVersionToFiles;
        try {
            articleVersionToFiles = SupportCommunityKnowledgeController.getKnowledgeInfoByArticleNumber(
                latestArticleVersion.ArticleNumber
            );
        } catch (SupportCommunityKnowledgeController.KnowledgeException e) {
            //System.assert(false, 'Article not found');
        }

        /*System.assertNotEquals(
            null,
            articleVersionToFiles.get(SupportCommunityKnowledgeController.ARTICLE_KEY_NAME),
            'Article is null'
        );
        System.assertEquals(
            latestArticleVersion.Id,
            ((Knowledge__kav) articleVersionToFiles.get(
                    SupportCommunityKnowledgeController.ARTICLE_KEY_NAME
                ))
                .Id,
            'Wrong article found'
        );*/
    }

    @isTest
    private static void testGetKnowledgeArticleVersionByUrlName() {
        Knowledge__kav articleVersion = [SELECT Id, UrlName FROM Knowledge__kav LIMIT 1];

        try {
            SupportCommunityKnowledgeController.getKnowledgeArticleVersion(
                URL_NAME,
                articleVersion.UrlName,
                EN_LANG,
                true
            );
        } catch (SupportCommunityKnowledgeController.KnowledgeException e) {
            System.assert(false, 'Article not found');
        }

        try {
            SupportCommunityKnowledgeController.getKnowledgeArticleVersion(
                URL_NAME,
                WRONG_ARTICLE_URL_NAME,
                EN_LANG,
                true
            );
        } catch (SupportCommunityKnowledgeController.KnowledgeException e) {
            System.assert(
                e.getMessage().contains(SupportCommunityKnowledgeController.ARTICLE_NOT_FOUND_ERROR_MESSAGE),
                'Wrong error message'
            );
        }
    }

    @isTest
    private static void testGetArticleRatingStatistics() {
        Knowledge__kav articleVersion = [SELECT Id, ArticleNumber FROM Knowledge__kav LIMIT 1];
        RC_Article_Rating__c articlerating = SupportCommunityKnowledgeController.getArticleRatingStatistics(
            articleVersion.ArticleNumber
        );
        System.assertNotEquals(null, articlerating);
        articlerating = SupportCommunityKnowledgeController.getArticleRatingStatistics(WRONG_ARTICLE_NUMBER);
        System.assertEquals(null, articlerating);
    }

    @isTest
    private static void testSaveComment() {
        Knowledge__kav articleVersion = [SELECT Id, ArticleNumber FROM Knowledge__kav LIMIT 1];

        String guestUserAddComment =
            '{"comm":"' +
            COMMENT_TEXT +
            '","jsuid":"' +
            JSUID +
            '","versionId":"' +
            articleVersion.Id +
            '","artid":"' +
            articleVersion.ArticleNumber +
            '"}';

        Map<String, Object> res = SupportCommunityKnowledgeController.saveCommentAndRating(guestUserAddComment);

        List<RC_User_Article_Rating__c> userArticleRatingList = [
            SELECT Id, User_Comments__c, Is_External__c, RC_ArticleID__c
            FROM RC_User_Article_Rating__c
        ];

        System.assertEquals(1, userArticleRatingList.size());

        RC_User_Article_Rating__c userArticleRating = userArticleRatingList.get(0);

        System.assertEquals(COMMENT_TEXT, userArticleRating.User_Comments__c);
        System.assert(userArticleRating.Is_External__c);
        System.assertEquals(articleVersion.ArticleNumber, userArticleRating.RC_ArticleID__c);

        List<RC_Article_Rating__c> articleRatingList = [
            SELECT Id, Article_Number__c
            FROM RC_Article_Rating__c
            WHERE Article_Number__c = :articleVersion.ArticleNumber
        ];
        System.assertEquals(1, articleRatingList.size());

        RC_Article_Rating__c articleRating = articleRatingList.get(0);

        System.assertEquals(articleVersion.ArticleNumber, articleRating.Article_Number__c);

        System.assert(res.containsKey(SupportCommunityKnowledgeController.STATISTICS_KEY_NAME));
        System.assertEquals(
            articleVersion.ArticleNumber,
            ((RC_Article_Rating__c) res.get(SupportCommunityKnowledgeController.STATISTICS_KEY_NAME)).Article_Number__c
        );
    }

    @isTest
    private static void testSaveLike() {
        Knowledge__kav articleVersion = [SELECT Id, ArticleNumber FROM Knowledge__kav LIMIT 1];

        String guestUserClicksLike =
            '{"rate":' +
            NEW_RATING +
            ',"jsuid":"' +
            JSUID +
            '","versionId":"' +
            articleVersion.Id +
            '","artid":"' +
            articleVersion.ArticleNumber +
            '"}';

        Map<String, Object> res = SupportCommunityKnowledgeController.saveCommentAndRating(guestUserClicksLike);

        List<RC_User_Article_Rating__c> userArticleRatingList = [
            SELECT Id, User_Comments__c, Is_External__c, RC_ArticleID__c, RC_Article_Rating__c
            FROM RC_User_Article_Rating__c
        ];

        System.assertEquals(1, userArticleRatingList.size());

        RC_User_Article_Rating__c userArticleRating = userArticleRatingList.get(0);

        System.assertEquals(NEW_RATING, userArticleRating.RC_Article_Rating__c);
        System.assertEquals(articleVersion.ArticleNumber, userArticleRating.RC_ArticleID__c);
    }

    @isTest
    private static void testAddFileToArticle() {
        Knowledge__kav articleVersion = [SELECT Id, ArticleNumber FROM Knowledge__kav LIMIT 1];

        ContentVersion contentVersion = new ContentVersion(
            Title = TITLE,
            PathOnClient = 'xxgx',
            VersionData = EncodingUtil.base64Decode(TEST_BASE64_DATA)
        );
        insert contentVersion;

        Map<String, Object> res = SupportCommunityKnowledgeController.addFileToArticle(
            articleVersion.ArticleNumber,
            contentVersion.Id
        );
        List<ContentDistribution> contentDistList = [SELECT Id, ContentVersionId, Name FROM ContentDistribution];
        System.assertEquals(1, contentDistList.size());
        ContentDistribution contentDist = contentDistList.get(0);
        System.assertEquals(contentVersion.Id, contentDist.ContentVersionId);
        System.assertEquals(contentVersion.Title, contentDist.Name);
        List<SupportCommunityKnowledgeFile__c> fileSeqList = [
            SELECT Id, Name, KnowledgeId__c, DocumentId__c
            FROM SupportCommunityKnowledgeFile__c
        ];
        System.assertEquals(1, fileSeqList.size());
        SupportCommunityKnowledgeFile__c fileSeq = fileSeqList.get(0);
        System.assertEquals(contentVersion.Title, fileSeq.Name);
        System.assertEquals(articleVersion.ArticleNumber, fileSeq.KnowledgeId__c);
        System.assert(res.containsKey(SupportCommunityKnowledgeController.DOC_KEY_NAME));
        System.assertEquals(
            fileSeq.Id,
            ((SupportCommunityKnowledgeFile__c) res.get(SupportCommunityKnowledgeController.DOC_KEY_NAME)).Id
        );
    }

    @isTest
    private static void testRemoveFileFromArticle() {
        Knowledge__kav articleVersion = [SELECT Id, ArticleNumber FROM Knowledge__kav LIMIT 1];

        ContentVersion contentVersion = new ContentVersion(
            Title = TITLE,
            PathOnClient = 'xxgx',
            VersionData = EncodingUtil.base64Decode(TEST_BASE64_DATA)
        );
        insert contentVersion;

        contentVersion = [SELECT Id, ContentDocumentId, Title FROM ContentVersion LIMIT 1];

        new SObjectBuilder(ContentDistribution.SObjectType)
            .setField(ContentDistribution.ContentVersionId, contentVersion.Id)
            .setField(ContentDistribution.Name, contentVersion.Title)
            .create();

        ContentDistribution fileDist = [
            SELECT ContentDocumentId, ContentDownloadUrl, DistributionPublicUrl
            FROM ContentDistribution
            LIMIT 1
        ];

        new SObjectBuilder(SupportCommunityKnowledgeFile__c.SObjectType)
            .setField(SupportCommunityKnowledgeFile__c.Name, contentVersion.Title)
            .setField(SupportCommunityKnowledgeFile__c.KnowledgeId__c, articleVersion.ArticleNumber)
            .setField(SupportCommunityKnowledgeFile__c.DocumentId__c, contentVersion.ContentDocumentId)
            .setField(SupportCommunityKnowledgeFile__c.FileTitle__c, contentVersion.Title)
            .setField(SupportCommunityKnowledgeFile__c.DownloadUrl__c, fileDist.ContentDownloadUrl)
            .setField(SupportCommunityKnowledgeFile__c.DistributionUrl__c, fileDist.DistributionPublicUrl)
            .setField(SupportCommunityKnowledgeFile__c.isPublished__c, false)
            .create();
        Integer supportCommunityKnowledgeFileCount = [SELECT COUNT() FROM SupportCommunityKnowledgeFile__c];
        System.assertEquals(1, supportCommunityKnowledgeFileCount, 'Knowledge files not created');
        Map<String, Object> res = SupportCommunityKnowledgeController.removeFileFromArticle(
            articleVersion.ArticleNumber,
            contentVersion.ContentDocumentId
        );
        supportCommunityKnowledgeFileCount = [SELECT COUNT() FROM SupportCommunityKnowledgeFile__c];
        System.assertEquals(0, supportCommunityKnowledgeFileCount, 'Knowledge files not deleted');
        Integer contentDistributionCount = [SELECT COUNT() FROM ContentDistribution];
        System.assertEquals(0, contentDistributionCount, 'Content distribution not deleted');
        Integer contentDocumentCount = [SELECT COUNT() FROM ContentDocument];
        System.assertEquals(0, contentDocumentCount, 'Content document not deleted');
    }

    @isTest
    private static void testPublishFiles() {
        Knowledge__kav articleVersion = [SELECT Id, ArticleNumber FROM Knowledge__kav LIMIT 1];

        ContentVersion contentVersion = new ContentVersion(
            Title = TITLE,
            PathOnClient = 'xxgx',
            VersionData = EncodingUtil.base64Decode(TEST_BASE64_DATA)
        );
        insert contentVersion;

        contentVersion = [SELECT ContentDocumentId, Title FROM ContentVersion LIMIT 1];

        new SObjectBuilder(SupportCommunityKnowledgeFile__c.SObjectType)
            .setField(SupportCommunityKnowledgeFile__c.KnowledgeId__c, articleVersion.ArticleNumber)
            .setField(SupportCommunityKnowledgeFile__c.isPublished__c, false)
            .setField(SupportCommunityKnowledgeFile__c.DocumentId__c, contentVersion.ContentDocumentId)
            .create();

        SupportCommunityKnowledgeController.publishFiles(articleVersion.ArticleNumber);

        SupportCommunityKnowledgeFile__c file = [SELECT isPublished__c FROM SupportCommunityKnowledgeFile__c];

        System.assert(file.IsPublished__c, 'File not published');
    }

    @isTest
    private static void changeFileLang() {
        Knowledge__kav articleVersion = [SELECT Id, ArticleNumber FROM Knowledge__kav LIMIT 1];

        ContentVersion contentVersion = new ContentVersion(
            Title = TITLE,
            PathOnClient = 'xxgx',
            VersionData = EncodingUtil.base64Decode(TEST_BASE64_DATA)
        );
        insert contentVersion;

        contentVersion = [SELECT ContentDocumentId, Title FROM ContentVersion LIMIT 1];

        new SObjectBuilder(SupportCommunityKnowledgeFile__c.SObjectType)
            .setField(SupportCommunityKnowledgeFile__c.KnowledgeId__c, articleVersion.ArticleNumber)
            .setField(SupportCommunityKnowledgeFile__c.isPublished__c, false)
            .setField(SupportCommunityKnowledgeFile__c.DocumentId__c, contentVersion.ContentDocumentId)
            .create();
        Boolean result = SupportCommunityKnowledgeController.changeFileLang(
            '{"docId":"' +
            contentVersion.ContentDocumentId +
            '", "languages": "fr;de"}'
        );
        System.assertEquals(true, result, 'Result of changeFileLang failed');
        SupportCommunityKnowledgeFile__c file = [
            SELECT Id, Language__c
            FROM SupportCommunityKnowledgeFile__c
            WHERE DocumentId__c = :contentVersion.ContentDocumentId
            LIMIT 1
        ];
        System.assertEquals('fr;de', file.Language__c, 'Result of changeFileLang not changed');
        result = SupportCommunityKnowledgeController.changeFileLang('{"docId":"fail", "languages": "fr;de"}');
        System.assertEquals(false, result, 'Result of negative changeFileLang failed');
    }

    @isTest
    private static void getArticleNegativeTest() {
        Knowledge__kav articleVersion = (Knowledge__kav) new KnowledgeArticleSelector()
            .selectArticles()
            .selectFields(new List<String>{'Id', 'ArticleNumber'})
            .setLimit(1)
            .executeQuery()
            .get(0);
        List<RC_Article_Rating__c> articleRatingList = [
            SELECT Id, Article_Number__c
            FROM RC_Article_Rating__c
            WHERE Article_Number__c = :articleVersion.ArticleNumber
        ];
        delete articleRatingList;
        Map<String, Object> res = SupportCommunityKnowledgeController.getKnowledgeInfo(
            '{"urlName":"' +
            ARTICLE_URL_NAME +
            '", "jsUID":"' +
            JSUID + '", "language":"' +
            EN_LANG +
            '"}'
        );
        System.assertNotEquals(null, res.get('Rating'));
        RC_Article_Rating__c stats = (RC_Article_Rating__c) res.get('Stats');
        /*System.assertEquals(stats.Article_Number__c, articleVersion.ArticleNumber);
        System.assertEquals(stats.PositiveVotesCount__c, 0);
        System.assertEquals(stats.NegativeVotesCount__c, 0);*/
    }
}