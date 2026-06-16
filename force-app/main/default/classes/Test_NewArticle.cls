@isTest
private class Test_NewArticle {

    private static final String USER_LANGUAGE = 'en_US';
    private static final String CONTRIBUTOR_USERNAME = (String) ValueProviderBuilder.provideUniqueEmail('Test_NewArticle_UserName').getValue();

    private static final String ARTICLE_TITLE = 'Never knows best';
    private static final String ARTICLE_SUMMARY = 'No one can prohibit anime articles in unit test';

    private static final String ARTICLE_TITLE_UNDERSCORES = 'These are un_der_scores';
    private static final String ARTICLE_URLNAME_INVALID = 'whi te spa ces';

    private static Map<String, String> CATEGORY_SELECTION = new Map<String, String>{
        'serviceCategory' => 'Professional',
        'topicCategory' => ''
    };

    private static NewArticle initPageAsUser(User u) {
        NewArticle result;
        System.runAs(u) {
            Case caseObj = KCSDataFactory.createCase();
            PageReference pageRef = Page.NewArticle;
            pageRef.getParameters().put('id', caseObj.Id);
            for (String categoryGroupName : CATEGORY_SELECTION.keySet()) {
                pageRef.getParameters().put(categoryGroupName, CATEGORY_SELECTION.get(categoryGroupName));
            }
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stdCaseCtrl = new ApexPages.StandardController(caseObj);
            result = new NewArticle(stdCaseCtrl);
        }
        return result;
    }

    private static NewArticle initPageAsUser(User u, Case caseObj) {
        NewArticle result;
        System.runAs(u) {
            PageReference pageRef = Page.NewArticle;
            pageRef.getParameters().put('id', caseObj.Id);
            for (String categoryGroupName : CATEGORY_SELECTION.keySet()) {
                pageRef.getParameters().put(categoryGroupName, CATEGORY_SELECTION.get(categoryGroupName));
            }
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stdCaseCtrl = new ApexPages.StandardController(caseObj);
            result = new NewArticle(stdCaseCtrl);
        }
        return result;
    }

    @testSetup
    static void setup() {
        KCSDataFactory.setup();
    }

    @isTest
    static void testCreateArticle_candidate() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.candidate);
        System.runAs(KCSDataFactory.candidate) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            PageReference resultRef = ctrl.createArticleAsDraft();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
            System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');
            System.assertEquals(KnowledgeArticleService.STATUS_DRAFT, articles[0].ValidationStatus, 'Article status does not match');
        }
    }

    @isTest
    static void testCreateArticle_contributor() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.contributor);
        System.runAs(KCSDataFactory.contributor) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            PageReference resultRef = ctrl.createArticleAsDraft();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
            System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');
            System.assertEquals(KnowledgeArticleService.STATUS_DRAFT, articles[0].ValidationStatus, 'Article status does not match');
        }
    }

    @isTest
    static void testCreateArticle_publisher() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.publisher);
        System.runAs(KCSDataFactory.publisher) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            PageReference resultRef = ctrl.createArticleAsDraft();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
            System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');
            System.assertEquals(KnowledgeArticleService.STATUS_DRAFT, articles[0].ValidationStatus, 'Article status does not match');
        }
    }

    @isTest
    static void testCreateArticle_coach() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.coach);
        System.runAs(KCSDataFactory.coach) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            PageReference resultRef = ctrl.createArticleAsDraft();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
            System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');
            System.assertEquals(KnowledgeArticleService.STATUS_DRAFT, articles[0].ValidationStatus, 'Article status does not match');
        }
    }

    @isTest
    static void testCreateArticle_expert() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.expert);
        System.runAs(KCSDataFactory.expert) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            PageReference resultRef = ctrl.createArticleAsDraft();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
            System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');
            System.assertEquals(KnowledgeArticleService.STATUS_DRAFT, articles[0].ValidationStatus, 'Article status does not match');
        }
    }

    @isTest
    static void testCreateArticle_titleWithUnderscores_shouldBeReplacedByHyphens() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.expert);
        System.runAs(KCSDataFactory.candidate) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE_UNDERSCORES;
            ctrl.summary = ARTICLE_SUMMARY;
            PageReference resultRef = ctrl.createArticleAsDraft();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE_UNDERSCORES})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assertEquals(ARTICLE_TITLE_UNDERSCORES.replaceAll('_', '-').replaceAll(' ', '-'), articles[0].UrlName, 'UrlName invalid');
        }
    }

    @isTest
    static void testCreateArticle_invalidUrlName() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.expert);
        System.runAs(KCSDataFactory.expert) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            ctrl.urlName = ARTICLE_URLNAME_INVALID;
            PageReference resultRef = ctrl.createArticleAsDraft();
            Test.stopTest();
			system.debug(ctrl.errorMessage.contains(NewArticle.ERROR_URLNAME_INVALID));
            System.assert(ctrl.errorMessage.contains(NewArticle.ERROR_URLNAME_INVALID), 'Created draft with invalid urlName');
        }
    }

    @isTest
    static void testCreateArticle_asDraft_withChannels() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.expert);
        System.runAs(KCSDataFactory.expert) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            ctrl.isVisibleInPrm = true;
            PageReference resultRef = ctrl.createArticleAsDraft();
            Test.stopTest();

            System.assert(ctrl.errorMessage.contains(KnowledgeArticleTriggerHelper.ERROR_CHANNELS_SELECTED), 'Created draft with channels');
        }
    }

    @isTest
    static void testCreateArticle_internal_withChannels() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.expert);
        System.runAs(KCSDataFactory.expert) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            ctrl.isVisibleInPrm = true;
            PageReference resultRef = ctrl.createArticleAsDraft();
            Test.stopTest();

            System.assert(ctrl.errorMessage.contains(KnowledgeArticleTriggerHelper.ERROR_CHANNELS_SELECTED), 'Created internal article with channels');
        }
    }

    @isTest
    static void testCreateArticle_publisher_internal() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.publisher);
        System.runAs(KCSDataFactory.publisher) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            ctrl.summary = ARTICLE_SUMMARY;
            PageReference resultRef = ctrl.createArticle();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
            System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');
            System.assertEquals(KnowledgeArticleService.STATUS_INTERNAL, articles[0].ValidationStatus, 'Article status does not match');
        }
    }

    @isTest
    static void testCreateArticle_coach_internal() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.coach);
        System.runAs(KCSDataFactory.coach) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            PageReference resultRef = ctrl.createArticle();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
            System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');
            System.assertEquals(KnowledgeArticleService.STATUS_INTERNAL, articles[0].ValidationStatus, 'Article status does not match');
        }
    }

    @isTest
    static void testCreateArticle_expert_internal() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.expert);
        System.runAs(KCSDataFactory.expert) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            PageReference resultRef = ctrl.createArticle();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
            System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');
            System.assertEquals(KnowledgeArticleService.STATUS_INTERNAL, articles[0].ValidationStatus, 'Article status does not match');
        }
    }

    @isTest
    static void testCreateArticle_publisher_external() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.publisher);
        System.runAs(KCSDataFactory.publisher) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            ctrl.isVisibleInPrm = true;
            PageReference resultRef = ctrl.createArticle();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
            System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');
            System.assertEquals(KnowledgeArticleService.STATUS_EXTERNAL, articles[0].ValidationStatus, 'Article status does not match');
        }
    }

    @isTest
    static void testCreateArticle_coach_external() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.coach);
        System.runAs(KCSDataFactory.coach) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            ctrl.isVisibleInPrm = true;
            PageReference resultRef = ctrl.createArticle();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
            System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');
            System.assertEquals(KnowledgeArticleService.STATUS_EXTERNAL, articles[0].ValidationStatus, 'Article status does not match');
        }
    }

    @isTest
    static void testCreateArticle_expert_external() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.expert);
        System.runAs(KCSDataFactory.expert) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            ctrl.isVisibleInPrm = true;
            PageReference resultRef = ctrl.createArticle();
            Test.stopTest();

            List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
                .executeQuery();

            System.assert(!articles.isEmpty(), 'Article was not created');
            System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
            System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');
            System.assertEquals(KnowledgeArticleService.STATUS_EXTERNAL, articles[0].ValidationStatus, 'Article status does not match');
        }
    }

    @isTest
    static void testCreateArticle_neg_duplicateTitle() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.contributor);
        System.runAs(KCSDataFactory.contributor) {
            Test.startTest();
            ctrl.title = ARTICLE_TITLE;
            ctrl.summary = ARTICLE_SUMMARY;
            ctrl.createArticleAsDraft();
            ctrl.createArticleAsDraft();
            Test.stopTest();

            System.assertEquals(NewArticle.ERROR_TITLE_DUPLICATE, ctrl.errorMessage, 'Created articles with same title');
        }
    }

    @isTest
    static void testPermissions_reader() {
        Test.startTest();
        try {
            NewArticle ctrl = initPageAsUser(KCSDataFactory.reader);
            System.assert(false, 'Reader got access to NewArticle page');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(NewArticle.ERROR_NO_PERMISSION), 'Wrong exception message');
        }
        Test.stopTest();
    }

    @isTest
    static void testPermissions_candidate() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.candidate);
        System.runAs(KCSDataFactory.candidate) {
            Test.startTest();
            System.assertEquals(1, ctrl.kcsAccessLevel, 'Permission invalid');
            Test.stopTest();
        }
    }

    @isTest
    static void testPermissions_contributor() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.contributor);
        System.runAs(KCSDataFactory.contributor) {
            Test.startTest();
            System.assertEquals(2, ctrl.kcsAccessLevel, 'Permission invalid');
            Test.stopTest();
        }
    }

    @isTest
    static void testPermissions_publisher() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.publisher);
        System.runAs(KCSDataFactory.publisher) {
            Test.startTest();
            System.assertEquals(3, ctrl.kcsAccessLevel, 'Permission invalid');
            Test.stopTest();
        }
    }

    @isTest
    static void testPermissions_coach() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.coach);
        System.runAs(KCSDataFactory.coach) {
            Test.startTest();
            System.assertEquals(4, ctrl.kcsAccessLevel, 'Permission invalid');
            Test.stopTest();
        }
    }

    @isTest
    static void testPermissions_expert() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.expert);
        System.runAs(KCSDataFactory.expert) {
            Test.startTest();
            System.assertEquals(5, ctrl.kcsAccessLevel, 'Permission invalid');
            Test.stopTest();
        }
    }

    @isTest
    static void testProductSelectOptions() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.publisher);
        System.runAs(KCSDataFactory.publisher) {
            Test.startTest();
            List<SelectOption> productSelectOptions = ctrl.productSelectOptions;
            Test.stopTest();

            System.assertEquals(
                Knowledge__kav.RC_Knowledge_Article_Product__c.getDescribe().getPicklistValues().size() + 1,
                productSelectOptions.size(),
                'Number of product values does not match'
            );
        }
    }

    @isTest
    static void testCategoryFieldSelectOptions() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.publisher);
        System.runAs(KCSDataFactory.publisher) {
            Test.startTest();
            List<SelectOption> categoryFieldSelectOptions = ctrl.categoryFieldSelectOptions;
            Test.stopTest();

            System.assertEquals(
                Knowledge__kav.RC_Knowledge_Article_Category__c.getDescribe().getPicklistValues().size() + 1,
                categoryFieldSelectOptions.size(),
                'Number of category values does not match'
            );
        }
    }

    @isTest
    static void testConfidenceSelectOptions() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.publisher);
        System.runAs(KCSDataFactory.publisher) {
            Test.startTest();
            List<SelectOption> confidenceSelectOptions = ctrl.confidenceItems;
            Test.stopTest();

            System.assertEquals(
                Knowledge__kav.RC_Knowledge_Article_Confidence__c.getDescribe().getPicklistValues().size(),
                confidenceSelectOptions.size(),
                'Number of confidence values does not match'
            );
        }
    }

    @isTest
    static void testAllowedLanguages() {
        NewArticle ctrl = initPageAsUser(KCSDataFactory.publisher);
        System.runAs(KCSDataFactory.publisher) {
            Test.startTest();
            List<SelectOption> allowedLanguages = ctrl.allowedLanguages;
            Test.stopTest();
            System.assertEquals(
                Knowledge__kav.Language.getDescribe().getPicklistValues().size(),
                allowedLanguages.size(),
                'Number of laguages does not match'
            );
        }
    }
}