@isTest
private class Test_KnowledgeArticleService {

    private static final String ARTICLE_TITLE = 'Test Article title';
    private static final String ARTICLE_URLNAME = 'Test-Article-url';
    private static final String ARTICLE_SUMMARY = 'Test Article summary';
    private static final String ARTICLE_DETAILS = 'Test Article details';
    private static final String ARTICLE_LANGUAGE = 'en_US';
    private static Map<String, String> CATEGORY_SELECTION = new Map<String, String>{
        'Service' => 'Professional'
    };

    private static final String REJECTION_REASON = 'Not good enough';

    private static final IValueProvider emailProvider =
        ValueProviderBuilder.provideUniqueEmail('Test_KnowledgeArticleService_UserName');

    private static final String READER_USERNAME = (String) emailProvider.getValue();
    private static final String CANDIDATE_USERNAME = (String) emailProvider.getValue();
    private static final String CONTRIBUTOR_USERNAME = (String) emailProvider.getValue();
    private static final String PUBLISHER_USERNAME = (String) emailProvider.getValue();
    private static final String COACH_USERNAME = (String) emailProvider.getValue();
    private static final String EXPERT_USERNAME = (String) emailProvider.getValue();

    private static final String USER_LANGUAGE = 'en_US';

    @testSetup
    static void setup() {
        KCSDataFactory.setup();
    }

    @isTest
    static void testApproveDraftArticle_asReader_failNoPermission() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        System.runAs(KCSDataFactory.reader) {
            try {
                KnowledgeArticleService.approveDraftArticle(publishedArticle);
                System.assert(false, 'Reader approved an article');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_ACCESS_TO_PUBLISH),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testApproveDraftArticle_asCandidate_failNoPermission() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        System.runAs(KCSDataFactory.candidate) {
            try {
                KnowledgeArticleService.approveDraftArticle(publishedArticle);
                System.assert(false, 'Candidate approved an article');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_ACCESS_TO_PUBLISH),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testApproveDraftArticle_asContributor() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.contributor) {
            KnowledgeArticleService.approveDraftArticle(publishedArticle);
            result = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{publishedArticle.Title.removeStart(KnowledgeArticleService.DRAFT_PREFIX)})
                .executeQuery()
                .get(0);
        }
        Test.stopTest();

        System.assertEquals(
            KnowledgeArticleService.STATUS_INTERNAL,
            result.ValidationStatus,
            'Status is not Internal after approval'
        );
        System.assert(
            result.RC_Knowledge_Article_ReviewDateTime__c != null,
            'ReviewDateTime__c has not been populated'
        );
        System.assertEquals(
            KCSDataFactory.contributor.Id,
            result.RC_Knowledge_Article_DecisionMaker__c,
            'DecisionMaker__c does not match approver id'
        );
    }

    @isTest
    static void testApproveDraftArticle_asPublisher() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.publisher) {
            KnowledgeArticleService.approveDraftArticle(publishedArticle);
            result = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{publishedArticle.Title.removeStart(KnowledgeArticleService.DRAFT_PREFIX)})
                .executeQuery()
                .get(0);
        }
        Test.stopTest();

        System.assertEquals(
            KnowledgeArticleService.STATUS_INTERNAL,
            result.ValidationStatus,
            'Status is not Internal after approval'
        );
        System.assert(
            result.RC_Knowledge_Article_ReviewDateTime__c != null,
            'ReviewDateTime__c has not been populated'
        );
        System.assertEquals(
            KCSDataFactory.publisher.Id,
            result.RC_Knowledge_Article_DecisionMaker__c,
            'DecisionMaker__c does not match approver id'
        );
    }

    @isTest
    static void testApproveDraftArticle_asCoach() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.coach) {
            KnowledgeArticleService.approveDraftArticle(publishedArticle);
            result = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{publishedArticle.Title.removeStart(KnowledgeArticleService.DRAFT_PREFIX)})
                .executeQuery()
                .get(0);
        }
        Test.stopTest();

        System.assertEquals(
            KnowledgeArticleService.STATUS_INTERNAL,
            result.ValidationStatus,
            'Status is not Internal after approval'
        );
        System.assert(
            result.RC_Knowledge_Article_ReviewDateTime__c != null,
            'ReviewDateTime__c has not been populated'
        );
        System.assertEquals(
            KCSDataFactory.coach.Id,
            result.RC_Knowledge_Article_DecisionMaker__c,
            'DecisionMaker__c does not match approver id'
        );
    }

    @isTest
    static void testApproveDraftArticle_asExpert() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.expert) {
            KnowledgeArticleService.approveDraftArticle(publishedArticle);
            result = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArticleByTitle(new List<String>{publishedArticle.Title.removeStart(KnowledgeArticleService.DRAFT_PREFIX)})
                .executeQuery()
                .get(0);
        }
        Test.stopTest();

        System.assertEquals(
            KnowledgeArticleService.STATUS_INTERNAL,
            result.ValidationStatus,
            'Status is not Internal after approval'
        );
        System.assert(
            result.RC_Knowledge_Article_ReviewDateTime__c != null,
            'ReviewDateTime__c has not been populated'
        );
        System.assertEquals(
            KCSDataFactory.expert.Id,
            result.RC_Knowledge_Article_DecisionMaker__c,
            'DecisionMaker__c does not match approver id'
        );
    }

    @isTest
    static void testRejectDraftArticle_asReader_failNoPermission() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        System.runAs(KCSDataFactory.reader) {
            try {
                KnowledgeArticleService.rejectDraftArticle(publishedArticle, REJECTION_REASON);
                System.assert(false, 'Reader rejected an article');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_ACCESS_TO_PUBLISH),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testRejectDraftArticle_asCandidate_failNoPermission() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        System.runAs(KCSDataFactory.candidate) {
            try {
                KnowledgeArticleService.rejectDraftArticle(publishedArticle, REJECTION_REASON);
                System.assert(false, 'Candidate rejected an article');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_ACCESS_TO_PUBLISH),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testRejectDraftArticle_asContributor_failNoPermission() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        System.runAs(KCSDataFactory.contributor) {
            try {
                KnowledgeArticleService.rejectDraftArticle(publishedArticle, REJECTION_REASON);
                System.assert(false, 'Contributor rejected an article');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_ACCESS_TO_PUBLISH),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testRejectDraftArticle_asPublisher() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.publisher) {
            KnowledgeArticleService.rejectDraftArticle(publishedArticle, REJECTION_REASON);
            result = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArchivedByKnowledgeId(new List<Object>{new List<String>{publishedArticle.KnowledgeArticleId}})
                .executeQuery()
                .get(0);
        }
        Test.stopTest();

        System.assertEquals(
            KnowledgeArticleService.STATUS_REJECTED,
            result.ValidationStatus,
            'Status is not Rejected after rejection'
        );
        System.assert(
            result.RC_Knowledge_Article_ReviewDateTime__c != null,
            'ReviewDateTime__c has not been populated'
        );
        System.assertEquals(
            KCSDataFactory.publisher.Id,
            result.RC_Knowledge_Article_DecisionMaker__c,
            'DecisionMaker__c does not match approver id'
        );
    }

    @isTest
    static void testRejectDraftArticle_asCoach() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.coach) {
            KnowledgeArticleService.rejectDraftArticle(publishedArticle, REJECTION_REASON);
            result = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArchivedByKnowledgeId(new List<Object>{new List<String>{publishedArticle.KnowledgeArticleId}})
                .executeQuery()
                .get(0);
        }
        Test.stopTest();

        System.assertEquals(
            KnowledgeArticleService.STATUS_REJECTED,
            result.ValidationStatus,
            'Status is not Rejected after rejection'
        );
        System.assert(
            result.RC_Knowledge_Article_ReviewDateTime__c != null,
            'ReviewDateTime__c has not been populated'
        );
        System.assertEquals(
            KCSDataFactory.coach.Id,
            result.RC_Knowledge_Article_DecisionMaker__c,
            'DecisionMaker__c does not match approver id'
        );
    }

    @isTest
    static void testRejectDraftArticle_asExpert() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.expert) {
            KnowledgeArticleService.rejectDraftArticle(publishedArticle, REJECTION_REASON);
            result = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArchivedByKnowledgeId(new List<Object>{new List<String>{publishedArticle.KnowledgeArticleId}})
                .executeQuery()
                .get(0);
        }
        Test.stopTest();

        System.assertEquals(
            KnowledgeArticleService.STATUS_REJECTED,
            result.ValidationStatus,
            'Status is not Rejected after rejection'
        );
        System.assert(
            result.RC_Knowledge_Article_ReviewDateTime__c != null,
            'ReviewDateTime__c has not been populated'
        );
        System.assertEquals(
            KCSDataFactory.expert.Id,
            result.RC_Knowledge_Article_DecisionMaker__c,
            'DecisionMaker__c does not match approver id'
        );
    }

    @isTest
    static void testEditArticlesAsDrafts_asReader_failNoPermission() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        System.runAs(KCSDataFactory.reader) {
            try {
                KnowledgeArticleService.editArticleAsDraft(publishedArticle);
                System.assert(false, 'Reader checked out an article for edit');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_ACCESS_TO_PUBLISH),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testEditArticlesAsDrafts_asCandidate_failNoPermission() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        System.runAs(KCSDataFactory.candidate) {
            try {
                KnowledgeArticleService.editArticleAsDraft(publishedArticle);
                System.assert(false, 'Candidate checked out an article for edit');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_ACCESS_TO_PUBLISH),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testEditArticlesAsDrafts_asContributor() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.contributor) {
            result = KnowledgeArticleService.editArticleAsDraft(publishedArticle);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'New draft not returned for the article'
        );
        System.assertEquals(
            publishedArticle.KnowledgeArticleId,
            result.KnowledgeArticleId,
            'Knowledge Id does not match'
        );
    }

    @isTest
    static void testEditArticleAsDraft_nullArticle_returnsNull() {

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.expert) {
            result = KnowledgeArticleService.editArticleAsDraft(null);
        }
        Test.stopTest();

        System.assertEquals(
            null,
            result,
            'Null not returned for null article'
        );
    }

    @isTest
    static void testEditArticleAsDraft_newDraft_asPublisher() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.publisher) {
            result = KnowledgeArticleService.editArticleAsDraft(publishedArticle);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'New draft not returned for the article'
        );
        System.assertEquals(
            publishedArticle.KnowledgeArticleId,
            result.KnowledgeArticleId,
            'Knowledge Id does not match'
        );
    }

    @isTest
    static void testEditArticleAsDraft_newDraft_asCoach() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.coach) {
            result = KnowledgeArticleService.editArticleAsDraft(publishedArticle);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'New draft not returned for the article'
        );
        System.assertEquals(
            publishedArticle.KnowledgeArticleId,
            result.KnowledgeArticleId,
            'Knowledge Id does not match'
        );
    }

    @isTest
    static void testEditArticleAsDraft_newDraft_asExpert() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.expert) {
            result = KnowledgeArticleService.editArticleAsDraft(publishedArticle);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'New draft not returned for the article'
        );
        System.assertEquals(
            publishedArticle.KnowledgeArticleId,
            result.KnowledgeArticleId,
            'Knowledge Id does not match'
        );
    }

    @isTest
    static void testEditArticleAsDraft_existingDraft_asPublisher() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );
        Id publishedArticleInEditingId;
        System.runAs(KCSDataFactory.expert) {
            publishedArticleInEditingId =
                KbManagement.PublishingService.editOnlineArticle(publishedArticle.knowledgeArticleId, false);
        }

        Test.startTest();
        Knowledge__kav result;
        System.runAs(KCSDataFactory.publisher) {
            result = KnowledgeArticleService.editArticleAsDraft(publishedArticle);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'Draft not returned for the article'
        );
        System.assertEquals(
            publishedArticle.KnowledgeArticleId,
            result.KnowledgeArticleId,
            'Knowledge Id does not match'
        );
        System.assertEquals(
            publishedArticleInEditingId,
            result.Id,
            'Draft returned for the article is not the existing one'
        );
    }

    @isTest
    static void testEditArticlesAsDrafts_asPublisher() {

        List<Knowledge__kav> publishedArticles = KCSDataFactory.createAndPublishArticlesAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT,
            2
        );
        Id publishedArticleInEditingId;
        System.runAs(KCSDataFactory.expert) {
            publishedArticleInEditingId =
                KbManagement.PublishingService.editOnlineArticle(publishedArticles[1].knowledgeArticleId, false);
        }

        Test.startTest();
        Map<Id, Knowledge__kav> result;
        System.runAs(KCSDataFactory.expert) {
            result = KnowledgeArticleService.editArticlesAsDrafts(
                new List<Knowledge__kav>{publishedArticles[0], publishedArticles[1]}
            );
        }
        Test.stopTest();

        System.assertEquals(
            2,
            result.size(),
            'Result size does not match'
        );
        Knowledge__kav draftVersion1 = result.get(publishedArticles[0].KnowledgeArticleId);
        Knowledge__kav draftVersion2 = result.get(publishedArticles[1].KnowledgeArticleId);
        System.assertNotEquals(
            null,
            draftVersion1,
            'Draft not returned for the first article'
        );
        System.assertNotEquals(
            null,
            draftVersion2,
            'Draft not returned for the second article'
        );
        System.assertEquals(
            publishedArticleInEditingId,
            draftVersion2.Id,
            'Draft returned for the second article is not the existing one'
        );
    }

    @isTest
    static void testEditArticlesAsDrafts_asCoach() {

        List<Knowledge__kav> publishedArticles = KCSDataFactory.createAndPublishArticlesAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT,
            2
        );
        Id publishedArticleInEditingId;
        System.runAs(KCSDataFactory.expert) {
            publishedArticleInEditingId =
                KbManagement.PublishingService.editOnlineArticle(publishedArticles[1].knowledgeArticleId, false);
        }

        Test.startTest();
        Map<Id, Knowledge__kav> result;
        System.runAs(KCSDataFactory.coach) {
            result = KnowledgeArticleService.editArticlesAsDrafts(
                new List<Knowledge__kav>{publishedArticles[0], publishedArticles[1]}
            );
        }
        Test.stopTest();

        System.assertEquals(
            2,
            result.size(),
            'Result size does not match'
        );
        Knowledge__kav draftVersion1 = result.get(publishedArticles[0].KnowledgeArticleId);
        Knowledge__kav draftVersion2 = result.get(publishedArticles[1].KnowledgeArticleId);
        System.assertNotEquals(
            null,
            draftVersion1,
            'Draft not returned for the first article'
        );
        System.assertNotEquals(
            null,
            draftVersion2,
            'Draft not returned for the second article'
        );
        System.assertEquals(
            publishedArticleInEditingId,
            draftVersion2.Id,
            'Draft returned for the second article is not the existing one'
        );
    }

    @isTest
    static void testEditArticlesAsDrafts_asExpert() {

        List<Knowledge__kav> publishedArticles = KCSDataFactory.createAndPublishArticlesAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT,
            2
        );
        Id publishedArticleInEditingId;
        System.runAs(KCSDataFactory.expert) {
            publishedArticleInEditingId =
                KbManagement.PublishingService.editOnlineArticle(publishedArticles[1].knowledgeArticleId, false);
        }

        Test.startTest();
        Map<Id, Knowledge__kav> result;
        System.runAs(KCSDataFactory.expert) {
            result = KnowledgeArticleService.editArticlesAsDrafts(
                new List<Knowledge__kav>{publishedArticles[0], publishedArticles[1]}
            );
        }
        Test.stopTest();

        System.assertEquals(
            2,
            result.size(),
            'Result size does not match'
        );
        Knowledge__kav draftVersion1 = result.get(publishedArticles[0].KnowledgeArticleId);
        Knowledge__kav draftVersion2 = result.get(publishedArticles[1].KnowledgeArticleId);
        System.assertNotEquals(
            null,
            draftVersion1,
            'Draft not returned for the first article'
        );
        System.assertNotEquals(
            null,
            draftVersion2,
            'Draft not returned for the second article'
        );
        System.assertEquals(
            publishedArticleInEditingId,
            draftVersion2.Id,
            'Draft returned for the second article is not the existing one'
        );
    }

    @isTest
    static void testPublishNewArticle_nullArticle_throwsException() {

        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            try {
                KnowledgeArticleService.publishNewArticle(null, null, null);
                System.assert(false, 'Published null article');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NULL_ARTICLE),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testPublishNewArticle_untitledArticle_throwsException() {

        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => null,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY
                }
            )
            .build()
            .getRecord();

        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            try {
                KnowledgeArticleService.publishNewArticle(article, null, null);
                System.assert(false, 'Published untitled article');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_TITLE),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testPublishNewArticle_noUrlName_throwsException() {

        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => null,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY
                }
            )
            .build()
            .getRecord();

        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            try {
                KnowledgeArticleService.publishNewArticle(article, null, null);
                System.assert(false, 'Published article without urlName');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_URLNAME),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testPublishNewArticle_noSummary_throwsException() {

        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => null
                }
            )
            .build()
            .getRecord();

        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            try {
                KnowledgeArticleService.publishNewArticle(article, null, null);
                System.assert(false, 'Published article without summary');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_SUMMARY),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testPublishNewArticle_alreadyPublished_throwsException() {

        Knowledge__kav publishedArticle = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            try {
                KnowledgeArticleService.publishNewArticle(publishedArticle, null, null);
                System.assert(false, 'Published article which already has a published version');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_ALREADY_PUBLISHED),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testPublishNewArticle_draft_asReader_throwsException() {

        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_DRAFT
                }
            )
            .build()
            .getRecord();

        Test.startTest();
        System.runAs(KCSDataFactory.reader) {
            try {
                KnowledgeArticleService.publishNewArticle(article, null, null);
                System.assert(false, 'Published article as reader');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NOT_A_KCS_USER),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testPublishNewArticle_draft_asCandidate() {

        Case caseObj;
        System.runAs(KCSDataFactory.candidate) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_DRAFT
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.candidate) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(KnowledgeArticleService.STATUS_DRAFT, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_draft_asContributor() {

        Case caseObj;
        System.runAs(KCSDataFactory.contributor) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_DRAFT
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.contributor) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(KnowledgeArticleService.STATUS_DRAFT, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_draft_asPublisher() {

        Case caseObj;
        System.runAs(KCSDataFactory.publisher) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_DRAFT
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.publisher) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(KnowledgeArticleService.STATUS_DRAFT, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_draft_asCoach() {

        Case caseObj;
        System.runAs(KCSDataFactory.coach) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_DRAFT
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.coach) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(KnowledgeArticleService.STATUS_DRAFT, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_draft_asExpert() {

        Case caseObj;
        System.runAs(KCSDataFactory.expert) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_DRAFT
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.expert) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(KnowledgeArticleService.STATUS_DRAFT, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_noStatus_defaultsToDraft() {

        Case caseObj;
        System.runAs(KCSDataFactory.publisher) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.publisher) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(KnowledgeArticleService.STATUS_DRAFT, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_internally_asCandidate_throwsException() {

        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_INTERNAL
                }
            )
            .build()
            .getRecord();

        Test.startTest();
        System.runAs(KCSDataFactory.candidate) {
            try {
                KnowledgeArticleService.publishNewArticle(article, null, null);
                System.assert(false, 'Published new article internally as a candidate');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_ACCESS_TO_PUBLISH),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testPublishNewArticle_internally_asContributor() {

        Case caseObj;
        System.runAs(KCSDataFactory.contributor) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_INTERNAL
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.contributor) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(KnowledgeArticleService.STATUS_INTERNAL, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_internally_asPublisher() {

        Case caseObj;
        System.runAs(KCSDataFactory.publisher) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_INTERNAL
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.publisher) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(KnowledgeArticleService.STATUS_INTERNAL, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_internally_asCoach() {

        Case caseObj;
        System.runAs(KCSDataFactory.coach) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_INTERNAL
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.coach) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(KnowledgeArticleService.STATUS_INTERNAL, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_internally_asExpert() {

        Case caseObj;
        System.runAs(KCSDataFactory.expert) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_INTERNAL
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.expert) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(KnowledgeArticleService.STATUS_INTERNAL, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_externally_asCandidate_throwsException() {

        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_EXTERNAL,
                    Knowledge__kav.IsVisibleInCsp => true
                }
            )
            .build()
            .getRecord();

        Test.startTest();
        System.runAs(KCSDataFactory.candidate) {
            try {
                KnowledgeArticleService.publishNewArticle(article, null, null);
                System.assert(false, 'Published new article externally as a candidate');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_ACCESS_TO_PUBLISH),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testPublishNewArticle_externally_asContributor_throwsException() {

        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_EXTERNAL,
                    Knowledge__kav.IsVisibleInCsp => true
                }
            )
            .build()
            .getRecord();

        Test.startTest();
        System.runAs(KCSDataFactory.contributor) {
            try {
                KnowledgeArticleService.publishNewArticle(article, null, null);
                System.assert(false, 'Published new article externally as a candidate');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_ACCESS_TO_PUBLISH_EXT),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }
    
    @isTest
    static void testPublishNewArticle_externally_asPublisher() {

        Case caseObj;
        System.runAs(KCSDataFactory.publisher) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_EXTERNAL,
                    Knowledge__kav.IsVisibleInCsp => true
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.publisher) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(KnowledgeArticleService.STATUS_EXTERNAL, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_externally_asCoach() {

        Case caseObj;
        System.runAs(KCSDataFactory.coach) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_EXTERNAL,
                    Knowledge__kav.IsVisibleInCsp => true
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.coach) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(KnowledgeArticleService.STATUS_EXTERNAL, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testPublishNewArticle_externally_asExpert() {

        Case caseObj;
        System.runAs(KCSDataFactory.expert) {
            caseObj = KCSDataFactory.createCase();
        }
        Knowledge__kav article = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => ARTICLE_TITLE,
                    Knowledge__kav.UrlName => ARTICLE_URLNAME,
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_EXTERNAL,
                    Knowledge__kav.IsVisibleInCsp => true
                }
            )
            .build()
            .getRecord();


        Test.startTest();
        Id resultId;
        System.runAs(KCSDataFactory.expert) {
            resultId = KnowledgeArticleService.publishNewArticle(article, CATEGORY_SELECTION, caseObj.Id);
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            resultId,
            'No Knowledge Id for the new article or it was not created'
        );

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{ARTICLE_TITLE})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article was not created');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(ARTICLE_URLNAME, articles[0].UrlName, 'Article urlName does not match');
        System.assertEquals(KnowledgeArticleService.STATUS_EXTERNAL, articles[0].ValidationStatus, 'Article Validation Status does not match');
        System.assertEquals(ARTICLE_SUMMARY, articles[0].Summary, 'Article summary does not match');

        Case caseWithArticleAttached = (Case) new CaseSelector()
            .selectCasesWithArticlesById(new List<Object>{new List<String>{caseObj.Id}})
            .executeQuery()
            .get(0);
        System.assertEquals(1, caseWithArticleAttached.CaseArticles.size(), 'Article was not attached to case');
        System.assertEquals(resultId, caseWithArticleAttached.CaseArticles[0].KnowledgeArticleId, 'Wrong article was attached to case');
    }

    @isTest
    static void testChangeArticleValidationStatus_toExternal_asCandidate() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_INTERNAL
        );

        Test.startTest();
        article.ValidationStatus = KnowledgeArticleService.STATUS_EXTERNAL;
        article.IsVisibleInCsp = true;
        System.runAs(KCSDataFactory.candidate) {
            try {
                KnowledgeArticleService.changeArticleValidationStatus(article);
                System.assert(false, 'Candidate changed status internal -> external');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleService.ERROR_NO_ACCESS_TO_PUBLISH),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testChangeArticleValidationStatus_toExternal_asPublisher() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.publisher,
            KnowledgeArticleService.STATUS_INTERNAL
        );

        Test.startTest();
        article.ValidationStatus = KnowledgeArticleService.STATUS_EXTERNAL;
        article.IsVisibleInCsp = true;
        System.runAs(KCSDataFactory.publisher) {
            KnowledgeArticleService.changeArticleValidationStatus(article);
        }
        Test.stopTest();

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{article.Title})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article not found');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(
            KnowledgeArticleService.STATUS_EXTERNAL,
            articles[0].ValidationStatus,
            'Article Validation Status was not updated'
        );
    }

    @isTest
    static void testChangeArticleValidationStatus_toExternal_asCoach() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.coach,
            KnowledgeArticleService.STATUS_INTERNAL
        );

        Test.startTest();
        article.ValidationStatus = KnowledgeArticleService.STATUS_EXTERNAL;
        article.IsVisibleInCsp = true;
        System.runAs(KCSDataFactory.coach) {
            KnowledgeArticleService.changeArticleValidationStatus(article);
        }
        Test.stopTest();

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{article.Title})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article not found');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(
            KnowledgeArticleService.STATUS_EXTERNAL,
            articles[0].ValidationStatus,
            'Article Validation Status was not updated'
        );
    }

    @isTest
    static void testChangeArticleValidationStatus_toExternal_asExpert() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_INTERNAL
        );

        Test.startTest();
        article.ValidationStatus = KnowledgeArticleService.STATUS_EXTERNAL;
        article.IsVisibleInCsp = true;
        System.runAs(KCSDataFactory.expert) {
            KnowledgeArticleService.changeArticleValidationStatus(article);
        }
        Test.stopTest();

        List<Knowledge__kav> articles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<String>{article.Title})
            .executeQuery();

        System.assert(!articles.isEmpty(), 'Article not found');
        System.assert(articles[0].KnowledgeArticleId != null, 'Article was not published');
        System.assertEquals(
            KnowledgeArticleService.STATUS_EXTERNAL,
            articles[0].ValidationStatus,
            'Article Validation Status was not updated'
        );
    }

    @isTest
    static void testIsKnowledgeUser() {
        System.assert(
            KnowledgeArticleService.isKnowledgeUser(KCSDataFactory.expert.Id), 'User is not KnowledgeUser'
        );
        System.assert(
            !KnowledgeArticleService.isKnowledgeUser(KCSDataFactory.notKnowledgeUser.Id), 'User is KnowledgeUser'
        );
    }
    
    @isTest
    static void testSearchArticlesByTitleOrKeyword() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_INTERNAL
        );
        List<SCWrappers.Article> resultInternal = new List<SCWrappers.Article>();
        resultInternal = KnowledgeArticleService.searchArticlesByTitleOrKeyword(
            ARTICLE_TITLE,
            ARTICLE_LANGUAGE,
            CaseArticlesAPIController.ARTICLE_CATEGORY_MAPPING.get(ARTICLE_LANGUAGE),
            CaseArticlesAPIController.SEARCH_OUTPUT_LIMIT
        );

        System.assert(resultInternal.isEmpty(), 'Article  found');

        Test.startTest();
        article.ValidationStatus = KnowledgeArticleService.STATUS_EXTERNAL;
        article.IsVisibleInCsp = true;
        System.runAs(KCSDataFactory.expert) {
            KnowledgeArticleService.changeArticleValidationStatus(article);
        }
        Test.stopTest();

        List<SCWrappers.Article> resultExternal = new List<SCWrappers.Article>();
        resultExternal = KnowledgeArticleService.searchArticlesByTitleOrKeyword(
            ARTICLE_TITLE,
            ARTICLE_LANGUAGE,
            CaseArticlesAPIController.ARTICLE_CATEGORY_MAPPING.get(ARTICLE_LANGUAGE),
            CaseArticlesAPIController.SEARCH_OUTPUT_LIMIT
        );

        //System.assert(!resultExternal.isEmpty(), 'Article not found');
    }
}