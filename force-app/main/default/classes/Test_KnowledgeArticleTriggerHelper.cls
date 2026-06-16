@isTest
private class Test_KnowledgeArticleTriggerHelper {

    public static final String DEFAULT_KNOWLEDGE_NO_ACCESS_EXCEPTION = 
        'You can\'t perform this action. Be sure the action is valid for the current state of the article, '
        + 'and that you have permission to perform it.';

    @testSetup
    private static void createTestData() {
        KCSDataFactory.setup();
    }
    @isTest
    private static void testFillFieldsForEmailNotificationsForArticle() {
        KCSDataFactory.createAndPublishArticlesAsUser(
            KCSDataFactory.publisher,
            KnowledgeArticleService.STATUS_DRAFT,
            1
        );
        Knowledge__kav article = (Knowledge__kav) new KnowledgeArticleSelector()
            .selectArticlesWithFieldsForEmailNotifications()
            .executeQuery()
            .get(0);
        
        System.assertEquals(KnowledgeArticleTriggerHelper.baseURL + article.KnowledgeArticleId,
            article.RC_Knowledge_Article_Knowledge_Article10__c, 'Knowledge_Article_URL__c is different');
        System.assertEquals(null, article.RC_Knowledge_Article_EmailOfArticleCre11__c,
            'EmailOfArticleCreatorManager__c is different');
        System.assertEquals('Draft', article.RC_Knowledge_Article_Old_ValidationSta24__c, 'Old_ValidationStatus__c is different');
    }

    @isTest
    static void testCheckout_fromPublishedAsDraft_asReader_throwsException() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.publisher,
            KnowledgeArticleService.STATUS_DRAFT
        );
        Test.startTest();
        System.runAs(KCSDataFactory.reader) {
            try {
                KbManagement.PublishingService.editOnlineArticle(article.KnowledgeArticleId, false);
                System.assert(false, 'Checked out PublishedAsDraft article as a reader');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(DEFAULT_KNOWLEDGE_NO_ACCESS_EXCEPTION),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testCheckout_fromPublishedAsDraft_asCandidate_throwsException() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.publisher,
            KnowledgeArticleService.STATUS_DRAFT
        );
        Test.startTest();
        System.runAs(KCSDataFactory.candidate) {
            try {
                KbManagement.PublishingService.editOnlineArticle(article.KnowledgeArticleId, false);
                System.assert(false, 'Checked out PublishedAsDraft article as a candidate');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(DEFAULT_KNOWLEDGE_NO_ACCESS_EXCEPTION),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testCheckout_fromPublishedAsDraft_asContributor() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.publisher,
            KnowledgeArticleService.STATUS_DRAFT
        );
        Test.startTest();
        System.runAs(KCSDataFactory.contributor) {
            KbManagement.PublishingService.editOnlineArticle(article.KnowledgeArticleId, false);
        }
        Test.stopTest();

        List<Knowledge__kav> result = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectDraftsByKnowledgeId(new List<Object>{new List<String>{article.KnowledgeArticleId}})
            .executeQuery();

        System.assertEquals(1, result.size(), 'Checked out article not found');
    }

    @isTest
    static void testCheckout_fromPublishedAsDraft_asPublisher() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.publisher,
            KnowledgeArticleService.STATUS_DRAFT
        );
        Test.startTest();
        System.runAs(KCSDataFactory.publisher) {
            KbManagement.PublishingService.editOnlineArticle(article.KnowledgeArticleId, false);
        }
        Test.stopTest();

        List<Knowledge__kav> result = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectDraftsByKnowledgeId(new List<Object>{new List<String>{article.KnowledgeArticleId}})
            .executeQuery();

        System.assertEquals(1, result.size(), 'Checked out article not found');
    }

    @isTest
    static void testCheckout_fromPublishedAsDraft_asCoach() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.coach,
            KnowledgeArticleService.STATUS_DRAFT
        );
        Test.startTest();
        System.runAs(KCSDataFactory.coach) {
            KbManagement.PublishingService.editOnlineArticle(article.KnowledgeArticleId, false);
        }
        Test.stopTest();

        List<Knowledge__kav> result = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectDraftsByKnowledgeId(new List<Object>{new List<String>{article.KnowledgeArticleId}})
            .executeQuery();

        System.assertEquals(1, result.size(), 'Checked out article not found');
    }

    @isTest
    static void testCheckout_fromPublishedAsDraft_asExpert() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );
        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            KbManagement.PublishingService.editOnlineArticle(article.KnowledgeArticleId, false);
        }
        Test.stopTest();

        List<Knowledge__kav> result = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectDraftsByKnowledgeId(new List<Object>{new List<String>{article.KnowledgeArticleId}})
            .executeQuery();

        System.assertEquals(1, result.size(), 'Checked out article not found');
    }

    @isTest
    static void testCreateInternal_autoReviewDateTimePopulation() {

        Knowledge__kav article = KCSDataFactory.buildArticle(KnowledgeArticleService.STATUS_INTERNAL);
        Test.startTest();
        System.runAs(KCSDataFactory.publisher) {
            KnowledgeArticleTriggerHelper.allowCreation = true;
            insert article;
            KnowledgeArticleTriggerHelper.allowCreation = false;
        }
        Test.stopTest();

        article = (Knowledge__kav) new KnowledgeArticleSelector()
            .selectArticleById(new List<String>{article.Id})
            .executeQuery()[0];

        System.assert(
            System.now().getTime() - article.RC_Knowledge_Article_ReviewDateTime__c.getTime() < 10000,
            'Article ReviewDateTime__c was set incorrectly'
        );
    }

    @isTest
    static void testCreateInternal_pickingChannel_throwsException() {

        Knowledge__kav article = KCSDataFactory.buildArticle(KnowledgeArticleService.STATUS_INTERNAL);
        article.IsVisibleInCsp = true;
        Test.startTest();
        System.runAs(KCSDataFactory.publisher) {
            try {
                KnowledgeArticleTriggerHelper.allowCreation = true;
                insert article;
                KnowledgeArticleTriggerHelper.allowCreation = false;
                System.assert(false, 'Inserted internal article shared by channels');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleTriggerHelper.ERROR_CHANNELS_SELECTED),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateExternal_notPickingChannel_throwsException() {

        Knowledge__kav article = KCSDataFactory.buildArticle(KnowledgeArticleService.STATUS_EXTERNAL);
        article.IsVisibleInCsp = false;
        Test.startTest();
        System.runAs(KCSDataFactory.publisher) {
            try {
                KnowledgeArticleTriggerHelper.allowCreation = true;
                insert article;
                KnowledgeArticleTriggerHelper.allowCreation = false;
                System.assert(false, 'Inserted external article not shared by any channel');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleTriggerHelper.ERROR_CHANNELS_NOT_SELECTED),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testCheckoutRejected_asPublisher_throwsException() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        System.runAs(KCSDataFactory.expert) {
            KnowledgeArticleService.rejectDraftArticle(article, 'Rejection comment');
        }
        Knowledge__kav rejectedVersion = (Knowledge__kav) new KnowledgeArticleSelector()
            .selectArchivedByKnowledgeId(new List<Object>{new List<String>{article.KnowledgeArticleId}})
            .executeQuery()[0];

        Test.startTest();
        System.runAs(KCSDataFactory.publisher) {
            try {
                KbManagement.PublishingService.editArchivedArticle(article.KnowledgeArticleId);
                System.assert(false, 'Publisher successfully restored article from archive');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(DEFAULT_KNOWLEDGE_NO_ACCESS_EXCEPTION),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testCheckoutRejected_asCoach_throwsException() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        System.runAs(KCSDataFactory.expert) {
            KnowledgeArticleService.rejectDraftArticle(article, 'Rejection comment');
        }
        Knowledge__kav rejectedVersion = (Knowledge__kav) new KnowledgeArticleSelector()
            .selectArchivedByKnowledgeId(new List<Object>{new List<String>{article.KnowledgeArticleId}})
            .executeQuery()[0];

        Test.startTest();
        System.runAs(KCSDataFactory.coach) {
            try {
                KbManagement.PublishingService.editArchivedArticle(article.KnowledgeArticleId);
                System.assert(false, 'Coach successfully restored article from archive');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(DEFAULT_KNOWLEDGE_NO_ACCESS_EXCEPTION),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testCheckoutRejected_asExpert_defaultsToInternalStatus() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );

        System.runAs(KCSDataFactory.expert) {
            KnowledgeArticleService.rejectDraftArticle(article, 'Rejection comment');
        }
        Knowledge__kav rejectedVersion = (Knowledge__kav) new KnowledgeArticleSelector()
            .selectArchivedByKnowledgeId(new List<Object>{new List<String>{article.KnowledgeArticleId}})
            .executeQuery()[0];

        Id draftVersionId;
        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            draftVersionId = KbManagement.PublishingService.editArchivedArticle(article.KnowledgeArticleId);
        }
        Test.stopTest();

        Knowledge__kav newVersion = (Knowledge__kav) new KnowledgeArticleSelector()
            .selectArticleById(new List<String>{draftVersionId})
            .executeQuery()[0];

        System.assertEquals(
            KnowledgeArticleService.STATUS_INTERNAL,
            newVersion.ValidationStatus,
            'Status did not default to internal'
        );
    }

    @isTest
    static void testUpdateToRejectedManually_throwsException() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_INTERNAL
        );
        System.runAs(KCSDataFactory.expert) {
            article = KnowledgeArticleService.editArticleAsDraft(article);
        }
        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            try {
                article.ValidationStatus = KnowledgeArticleService.STATUS_REJECTED;
                update article;
                System.assert(false, 'Updated internal article status to Rejected');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleTriggerHelper.ERROR_CHANGE_TO_REJECTED),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateToInternalManually_throwsException() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );
        System.runAs(KCSDataFactory.expert) {
            article = KnowledgeArticleService.editArticleAsDraft(article);
        }
        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            try {
                article.ValidationStatus = KnowledgeArticleService.STATUS_INTERNAL;
                update article;
                System.assert(false, 'Updated draft article status to Internal');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleTriggerHelper.ERROR_MANUAL_REVIEW),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateToComplianceManually_throwsException() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_DRAFT
        );
        System.runAs(KCSDataFactory.expert) {
            article = KnowledgeArticleService.editArticleAsDraft(article);
        }
        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            try {
                article.ValidationStatus = KnowledgeArticleService.STATUS_COMPLIANCE;
                update article;
                System.assert(false, 'Updated draft article status to Internal (Policies/Compliance)');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleTriggerHelper.ERROR_CHANGE_STATUS_TO_COMPLIANCE),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateFromComplianceManually_throwsException() {

        Knowledge__kav article = KCSDataFactory.createAndPublishArticleAsUser(
            KCSDataFactory.expert,
            KnowledgeArticleService.STATUS_COMPLIANCE
        );
        System.runAs(KCSDataFactory.expert) {
            article = KnowledgeArticleService.editArticleAsDraft(article);
        }
        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            try {
                article.ValidationStatus = KnowledgeArticleService.STATUS_DRAFT;
                update article;
                System.assert(false, 'Updated draft article status from Internal (Policies/Compliance)');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleTriggerHelper.ERROR_CHANGE_STATUS_FROM_COMPLIANCE),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateInternalCompliance_pickingChannel_throwsException() {

        Knowledge__kav article = KCSDataFactory.buildArticle(KnowledgeArticleService.STATUS_COMPLIANCE);
        article.IsVisibleInCsp = true;
        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            try {
                KnowledgeArticleTriggerHelper.allowCreation = true;
                insert article;
                System.assert(false, 'Inserted compliance-based article shared by channels');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleTriggerHelper.ERROR_CHANNELS_SELECTED),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateInternalCompliance_pickingChannel_throwsException() {

        Knowledge__kav article = KCSDataFactory.buildArticle(KnowledgeArticleService.STATUS_COMPLIANCE);
        Test.startTest();
        System.runAs(KCSDataFactory.expert) {
            try {
                KnowledgeArticleTriggerHelper.allowCreation = true;
                KnowledgeArticleTriggerHelper.allowReview = true;
                insert article;
                article.IsVisibleInCsp = true;
                update article;
                System.assert(false, 'Inserted compliance-based article shared by channels');
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage().contains(KnowledgeArticleTriggerHelper.ERROR_CHANNELS_SELECTED),
                    'Wrong exception thrown'
                );
            }
        }
        Test.stopTest();
    }

    private static final String PROFILE_NAME = 'Com Integration Profile';
    private static final String LANGUAGE_EN_US = 'en_US';
    
    // Utility method to create a User with a specific KCS role
    private static User createKCSUser(String firstName, String lastName, String email, String kcsRole) {
        String uniqueSuffix = String.valueOf(System.currentTimeMillis());
        return (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.FirstName => firstName,
                    User.LastName => lastName,
                    User.Email => email,
                    User.Username => email + System.currentTimeMillis(),
                    User.Alias => email.substring(0, 5),
                    User.CommunityNickname => firstName + lastName + uniqueSuffix,
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => LANGUAGE_EN_US,
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => LANGUAGE_EN_US,
                    User.ProfileId => [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME LIMIT 1].Id,
                    User.KCS_Role__c => kcsRole
                    })
            .create()
            .getRecord();
    }  
   
    @isTest
    static void testHandleAfterUpdate() {
        
        // Create a test user with KCS Coach role
        User testUser = createKCSUser('Test', 'User', 'testuser@example.com', 'KCS Coach');
        
        System.runAs(testUser) {
            //Create a draft Knowledge__kav record
            List<Knowledge__kav> draftArticles = KCSDataFactory.buildArticles(
                KnowledgeArticleService.STATUS_DRAFT, 1
            );
            insert draftArticles;
            Knowledge__kav draftArticle = draftArticles[0];
            
            //Insert a ContentVersion linked to the Knowledge__kav record
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Test Version',
                PathOnClient = 'testPath.txt',
                VersionData = Blob.valueOf('Sample Data'),
                Knowledge__c = draftArticle.Id
            );
            insert contentVersion;
            
            // Query ContentVersion and ensure it's retrieved
            List<ContentVersion> contentVersions = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Knowledge__c = :draftArticle.Id
                LIMIT 1
            ];
            System.assert(!contentVersions.isEmpty(), 'No ContentVersion record found.');
            ContentVersion insertedVersion = contentVersions[0];
            
            //Update the Knowledge__kav record to trigger the logic
            draftArticle.RC_Knowledge_Article_Details__c = 'Updated details';
            update draftArticle;
            
            //Verify the associated ContentDocument is deleted
            List<ContentDocument> deletedDocuments = [
                SELECT Id
                FROM ContentDocument
                WHERE Id = :insertedVersion.ContentDocumentId
            ];
            System.assertEquals(0, deletedDocuments.size(), 'The associated content document should be deleted.');
        }
    }

}