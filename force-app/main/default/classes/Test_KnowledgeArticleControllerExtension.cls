@isTest
public class Test_KnowledgeArticleControllerExtension {
    private static final Integer MAX_LEN_COMMENT = 32768;
    private static final Integer MIN_LEN_COMMENT = 20;
    private static final String TEST_COMMENT_TEXT_SHORT = 'Test text';
    private static final String TEST_COMMENT_TEXT = '12345678901234567890';
    private static final String TEST_ARTICLE_TITLE = 'Test title';
    private static final String ADMIN_USERNAME =
        (String) ValueProviderBuilder.provideUniqueEmail('adminTest').getValue();
    private static final String TEST_COMMENT_TEXT_LONG =
        (String) new ValueProvider.UniqueFixedLengthStringProvider(32768).getValue();

    private static User sysAdminUser {
        get {
            if (sysAdminUser == null) {
                sysAdminUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{ADMIN_USERNAME}})
                    .executeQuery()
                    .get(0);
            }
            return sysAdminUser;
        }
        private set;
    }

    @testSetup
    public static void testSetup() {

        KCSDataFactory.setup();
        new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.Username, ADMIN_USERNAME)
            .create();

        System.runAs(KCSDataFactory.expert) {

            Knowledge__kav newArticle =
                (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
                    .setFields(new Map<SObjectField, Object> {
                        Knowledge__kav.Title => TEST_ARTICLE_TITLE,
                        Knowledge__kav.Language => 'en_US',
                        Knowledge__kav.UrlName => 'testURL',
                        Knowledge__kav.RC_Knowledge_Article_Details__c => 'testDetails',
                        Knowledge__kav.Summary => 'testSummary',
                        Knowledge__kav.RC_Knowledge_Article_Key_Words__c => 'test,test_test'
                    })
                    .create()
                    .getRecord();

            List<String> articleIds = new List<String>{newArticle.Id};
            List<Knowledge__kav> articles = new KnowledgeArticleSelector()
                .selectArticlesById(new List<List<String>>{articleIds})
                .executeQuery();

            KbManagement.PublishingService.publishArticle(articles.get(0).KnowledgeArticleId, true);

            List<RC_User_Article_Rating__c> comments =
                (List<RC_User_Article_Rating__c>) new SObjectBuilder(RC_User_Article_Rating__c.SObjectType)
                    .quantity(2)
                    .setFields(new Map<SObjectField, Object> {
                        RC_User_Article_Rating__c.Is_External__c =>
                            ValueProviderBuilder.provideList(new List<Boolean>{true, false}),
                        RC_User_Article_Rating__c.User_Comments__c => TEST_COMMENT_TEXT,
                        RC_User_Article_Rating__c.RC_User_Id__c => UserInfo.getUserId(),
                        RC_User_Article_Rating__c.RC_User_name__c => UserInfo.getName(),
                        RC_User_Article_Rating__c.RC_ArticleID__c => articles.get(0).ArticleNumber
                    })
                    .create()
                    .getRecords();
        }
    }

    @isTest
    public static void testSaveInternalComment() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticles()
            .executeQuery();

        ApexPages.StandardController stdController = new ApexPages.StandardController(articles.get(0));
        KnowledgeArticleControllerExtension controller = new KnowledgeArticleControllerExtension(stdController);

            RC_User_Article_Rating__c internalComment =
                (RC_User_Article_Rating__c) new SObjectBuilder(RC_User_Article_Rating__c.SObjectType)
                    .setField(RC_User_Article_Rating__c.Is_External__c, false)
                    .setField(RC_User_Article_Rating__c.User_Comments__c, TEST_COMMENT_TEXT)
                    .build()
                    .getRecord();
            controller.comment = internalComment;

        controller.saveComment();

                List<RC_User_Article_Rating__c> insertedInternalComments =
                    (List<RC_User_Article_Rating__c>) new RCUserArticleRatingSelector()
                        .selectDefaultRCUserArticleRating()
                        .setQueryBindings(new List<Object>{articles.get(0).ArticleNumber})
                        .setCondition('Is_External__c = false AND RC_ArticleID__c = :bind0')
                        .executeQuery();
                System.assertEquals(2, insertedInternalComments.size(), 'No internal comments inserted');

        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size(), 'There should be at least one page message');
        System.assertEquals(
            Label.ArticleManagement_comment_added,
            pageMessages.get(0).getSummary(),
            'There should be a message that comment was successfully added'
        );
        System.assertEquals(ApexPages.Severity.CONFIRM,
            pageMessages.get(0).getSeverity(),
            'There should be CONFIRM severity'
        );
    }

    @isTest
    public static void testSaveExternalComment() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticles()
            .executeQuery();

        ApexPages.StandardController stdController = new ApexPages.StandardController(articles.get(0));
        KnowledgeArticleControllerExtension controller = new KnowledgeArticleControllerExtension(stdController);

        RC_User_Article_Rating__c externalComment =
            (RC_User_Article_Rating__c) new SObjectBuilder(RC_User_Article_Rating__c.SObjectType)
                .setField(RC_User_Article_Rating__c.Is_External__c, true)
                .setField(RC_User_Article_Rating__c.User_Comments__c, TEST_COMMENT_TEXT)
                .build()
                .getRecord();
        controller.comment = externalComment;
        controller.saveComment();

        List<RC_User_Article_Rating__c> insertedExternalComments =
            (List<RC_User_Article_Rating__c>) new RCUserArticleRatingSelector()
                .selectDefaultRCUserArticleRating()
                .setQueryBindings(new List<Object>{articles.get(0).ArticleNumber})
                .setCondition('Is_External__c = true AND RC_ArticleID__c = :bind0')
                .executeQuery();
        System.assertEquals(2, insertedExternalComments.size(), 'No external comments inserted');

        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size(), 'There should be at least one page message');
        System.assertEquals(
            Label.ArticleManagement_comment_added,
            pageMessages.get(0).getSummary(),
            'There should be a message that comment was successfully added'
        );
        System.assertEquals(ApexPages.Severity.CONFIRM,
            pageMessages.get(0).getSeverity(),
            'There should be CONFIRM severity'
        );
    }

    @isTest
    public static void testSaveCommentWhenCommentIsTooLong() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticles()
            .executeQuery();

        ApexPages.StandardController stdController = new ApexPages.StandardController(articles.get(0));
        KnowledgeArticleControllerExtension controller = new KnowledgeArticleControllerExtension(stdController);

        RC_User_Article_Rating__c internalComment =
            (RC_User_Article_Rating__c) new SObjectBuilder(RC_User_Article_Rating__c.SObjectType)
                .setField(RC_User_Article_Rating__c.Is_External__c, false)
                .setField(RC_User_Article_Rating__c.User_Comments__c, TEST_COMMENT_TEXT_LONG)
                .build()
                .getRecord();

        controller.comment = internalComment;
        controller.saveComment();

        List<RC_User_Article_Rating__c> insertedInternalComments =
            (List<RC_User_Article_Rating__c>) new RCUserArticleRatingSelector()
                .selectDefaultRCUserArticleRating()
                .setQueryBindings(new List<Object>{articles.get(0).ArticleNumber})
                .setCondition('Is_External__c = false AND RC_ArticleID__c = :bind0')
                .executeQuery();

        System.assertEquals(1, insertedInternalComments.size(), 'No internal comments inserted');

        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size(), 'There should be at least one page message');
        String errorMessage = String.format(
            Label.ArticleManagement_too_long_comment,
            new List<String>{String.valueOf(MAX_LEN_COMMENT)});
        System.assertEquals(
            errorMessage,
            pageMessages.get(0).getSummary(),
            'There should be a message about long comment'
        );
        System.assertEquals(ApexPages.Severity.ERROR,
            pageMessages.get(0).getSeverity(),
            'There should be ERROR severity'
        );
    }

    @isTest
    public static void testSaveCommentWhenCommentIsTooShort() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticles()
            .executeQuery();

        ApexPages.StandardController stdController = new ApexPages.StandardController(articles.get(0));
        KnowledgeArticleControllerExtension controller = new KnowledgeArticleControllerExtension(stdController);

        RC_User_Article_Rating__c internalComment =
            (RC_User_Article_Rating__c) new SObjectBuilder(RC_User_Article_Rating__c.SObjectType)
                .setField(RC_User_Article_Rating__c.Is_External__c, false)
                .setField(RC_User_Article_Rating__c.User_Comments__c, TEST_COMMENT_TEXT_SHORT)
                .build()
                .getRecord();

        controller.comment = internalComment;
        controller.saveComment();

        List<RC_User_Article_Rating__c> insertedInternalComments =
            (List<RC_User_Article_Rating__c>) new RCUserArticleRatingSelector()
                .selectDefaultRCUserArticleRating()
                .setQueryBindings(new List<Object>{articles.get(0).ArticleNumber})
                .setCondition('Is_External__c = false AND RC_ArticleID__c = :bind0')
                .executeQuery();

        System.assertEquals(1, insertedInternalComments.size(), 'No internal comments inserted');

        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size(), 'There should be at least one page message');
        String errorMessage = String.format(
            Label.ArticleManagement_too_short_comment,
            new List<String>{String.valueOf(MIN_LEN_COMMENT)});
        System.assertEquals(
            errorMessage,
            pageMessages.get(0).getSummary(),
            'There should be a message about short comment'
        );
        System.assertEquals(ApexPages.Severity.ERROR,
            pageMessages.get(0).getSeverity(),
            'There should be ERROR severity'
        );
    }

    @isTest
    public static void testSaveCommentWhenCommentIsEmpty() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticles()
            .executeQuery();

        ApexPages.StandardController stdController = new ApexPages.StandardController(articles.get(0));
        KnowledgeArticleControllerExtension controller = new KnowledgeArticleControllerExtension(stdController);

        RC_User_Article_Rating__c emptyComment = new RC_User_Article_Rating__c();
        controller.comment = emptyComment;
        controller.saveComment();

        List<RC_User_Article_Rating__c> insertedInternalComments =
            (List<RC_User_Article_Rating__c>) new RCUserArticleRatingSelector()
                .selectDefaultRCUserArticleRating()
                .setQueryBindings(new List<Object>{articles.get(0).ArticleNumber})
                .setCondition('RC_ArticleID__c = :bind0')
                .executeQuery();

        System.assertEquals(2, insertedInternalComments.size(), 'Empty comment should not be inserted');

        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size(), 'There should be at least one page message');
        System.assertEquals(
            Label.ArticleManagement_empty_comment,
            pageMessages.get(0).getSummary(),
            'There should be a message about empty comment'
        );
        System.assertEquals(ApexPages.Severity.ERROR,
            pageMessages.get(0).getSeverity(),
            'There should be ERROR severity'
        );
    }

    @isTest
    public static void testPublishArticleExternally() {

        Knowledge__kav article =
            KCSDataFactory.createAndPublishArticleAsUser(KCSDataFactory.publisher, KnowledgeArticleService.STATUS_INTERNAL);

        Test.startTest();
        System.runAs(KCSDataFactory.publisher) {
            ApexPages.StandardController stdController = new ApexPages.StandardController(article);
            KnowledgeArticleControllerExtension controller = new KnowledgeArticleControllerExtension(stdController);
            controller.articleVersion.IsVisibleInPkb = true;
            controller.publishArticleExternally();
        }
        Test.stopTest();

        List<Knowledge__kav> result = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{article.Title})
            .executeQuery();

        System.assertEquals(1, result.size(), 'Article not found after publishing');
        System.assertEquals(KnowledgeArticleService.STATUS_EXTERNAL, result[0].ValidationStatus, 'Article status was not changed');
    }

    @isTest
    public static void testArticleVersionVariables() {

        Knowledge__kav article =
            KCSDataFactory.createAndPublishArticleAsUser(KCSDataFactory.publisher, KnowledgeArticleService.STATUS_DRAFT);
        Knowledge__kav approvedVer;
        Knowledge__kav draftVer;
        // coach approves then makes changes and publishes them as a new version
        System.runAs(KCSDataFactory.coach) {
            KnowledgeArticleService.approveDraftArticle(article);
            approvedVer = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectOnlineByKnowledgeIdAndLanguage(new List<Object>{
                        new List<String>{article.KnowledgeArticleId},
                        KCSDataFactory.ARTICLE_LANGUAGE
                })
                .selectFields(KnowledgeArticleControllerExtension.EXTRA_FIELDS)
                .executeQuery()[0];

            draftVer = KnowledgeArticleService.editArticleAsDraft(article);
            draftVer.Summary = 'The summary has been changed';
            update draftVer;
            KbManagement.PublishingService.publishArticle(draftVer.KnowledgeArticleId, true);
        }
        System.runAs(KCSDataFactory.expert) {
            KnowledgeArticleService.editArticleAsDraft(draftVer);
        }

        Test.startTest();
        System.runAs(KCSDataFactory.publisher) {
            approvedVer = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArticlesById(new List<Object>{
                        new List<String>{approvedVer.Id}
                })
                .selectFields(KnowledgeArticleControllerExtension.EXTRA_FIELDS)
                .executeQuery()[0];
            ApexPages.StandardController stdController = new ApexPages.StandardController(approvedVer);
            KnowledgeArticleControllerExtension ctrl = new KnowledgeArticleControllerExtension(stdController);
            Test.setCurrentPage(new ApexPages.PageReference('/apex/NewArticlePage?id=' + approvedVer.Id));

            System.assertEquals(
                true,
                ctrl.currentUserCanReviewArticle,
                'Publisher can\'t review articles'
            );
            System.assert(
                ctrl.latestVersionLink.contains('kavVersion=2'),
                'Link to the latest version is missing'
            );
            System.assertEquals(
                false,
                ctrl.isDraft,
                'isDraft is not false for Internal article'
            );
            System.assertEquals(
                true,
                ctrl.isInternal,
                'isInternal is not true for Internal article'
            );
            System.assertEquals(
                false,
                ctrl.isRejected,
                'isRejected is not false for Internal article'
            );
        
            System.assertEquals(
                KCSDataFactory.coach.Name,
                ctrl.decisionMakerName,
                'decisionMakerName does not match'
            );
            System.assert(
                ctrl.decisionMakerLink.contains(KCSDataFactory.coach.Id),
                'decisionMakerLink does not contain proper Enterprise Account id'
            );
            System.assertEquals(
                false,
                ctrl.iAmDraftEditor,
                'iAmDraftEditor is not false when another user edits an article'
            );
            System.assertEquals(
                KCSDataFactory.expert.Name,
                ctrl.draftEditorName,
                'draftEditorName does not match'
            );
            System.assert(
                ctrl.draftEditorLink.contains(KCSDataFactory.expert.Id),
                'draftEditorLink does not contain proper Enterprise Account id'
            );
        }
        Test.stopTest();
    }
}