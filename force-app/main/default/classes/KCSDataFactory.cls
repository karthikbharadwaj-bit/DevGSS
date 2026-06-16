@isTest
public without sharing class KCSDataFactory {

    public static final String ARTICLE_TITLE = 'Test Article title';
    public static final String ARTICLE_URLNAME = 'Test-Article-unique-url';
    public static final String ARTICLE_SUMMARY = 'Test Article summary';
    public static final String ARTICLE_DETAILS = 'Test Article details';
    public static final String ARTICLE_LANGUAGE = 'en_US';
    public static final String ARTICLE_OMA_TYPE = 'Information';

    public static final IValueProvider emailProvider = ValueProviderBuilder.provideUniqueEmail('Test_KnowledgeArticleService_UserName');

    public static final String ADMIN_USERNAME = (String) emailProvider.getValue();
    public static final String READER_USERNAME = (String) emailProvider.getValue();
    public static final String CANDIDATE_USERNAME = (String) emailProvider.getValue();
    public static final String CONTRIBUTOR_USERNAME = (String) emailProvider.getValue();
    public static final String PUBLISHER_USERNAME = (String) emailProvider.getValue();
    public static final String COACH_USERNAME = (String) emailProvider.getValue();
    public static final String EXPERT_USERNAME = (String) emailProvider.getValue();
    public static final String NOT_KNOWLEDGE_USER_USERNAME = (String) emailProvider.getValue();

    public static final String AGENT_USER_PROFILE_NAME = 'Support T2';
    public static final String ADMIN_USER_PROFILE_NAME = 'System Administrator';
    public static final String USER_LANGUAGE = 'en_US';
    public static final String OVERALL_EMAIL = 'kcs@kcs.com';

    public static final IValueProvider CASE_SUBJECT_PROVIDER =
        ValueProviderBuilder.provideUniqueString('Test_KCSDataFactory_CaseSubj');

    public static User testUser {
        get {
            if (testUser == null) {
                testUser = (User) new UserSelector()
                    .selectUsersByIdNoFields(new List<Object>{new List<String>{UserInfo.getUserId()}})
                    .executeQuery()
                    .get(0);
            }
            return testUser;
        }
        private set;
    }

    public static User reader {
        get {
            if (reader == null) {
                reader = getUserByUsername(READER_USERNAME);
            }
            return reader;
        }
        private set;
    }

    public static User candidate {
        get {
            if (candidate == null) {
                candidate = getUserByUsername(CANDIDATE_USERNAME);
            }
            return candidate;
        }
        private set;
    }

    public static User contributor {
        get {
            if (contributor == null) {
                contributor = getUserByUsername(CONTRIBUTOR_USERNAME);
            }
            return contributor;
        }
        private set;
    }

    public static User publisher {
        get {
            if (publisher == null) {
                publisher = getUserByUsername(PUBLISHER_USERNAME);
            }
            return publisher;
        }
        private set;
    }

    public static User coach {
        get {
            if (coach == null) {
                coach = getUserByUsername(COACH_USERNAME);
            }
            return coach;
        }
        private set;
    }

    public static User expert {
        get {
            if (expert == null) {
                expert = getUserByUsername(EXPERT_USERNAME);
            }
            return expert;
        }
        private set;
    }

    public static User admin {
        get {
            if (admin == null) {
                admin = getUserByUsername(ADMIN_USERNAME);
            }
            return admin;
        }
        private set;
    }

    public static User notKnowledgeUser {
        get {
            if (notKnowledgeUser == null) {
                notKnowledgeUser = getUserByUsername(NOT_KNOWLEDGE_USER_USERNAME);
            }
            return notKnowledgeUser;
        }
        private set;
    }

    public static User getUserByUsername(String username) {
        return (User) new UserSelector()
            .selectUserByUsername(new List<Object>{new List<String>{username}})
            .selectFields(new List<String>{'KCS_Role__c'})
            .executeQuery()
            .get(0);
    }

    public static void setup() {

        System.runAs(testUser) {
            KCSSettings__c featureToggle = KCSSettings__c.getInstance();
            featureToggle.EnableTriggerDefineGroupMembers__c = true;
            featureToggle.OverallEmail__c = OVERALL_EMAIL;
            upsert featureToggle;

            Profile agentProfile = (Profile) new ProfileSelector()
                .selectProfileByName(new List<String>{AGENT_USER_PROFILE_NAME})
                .executeQuery()
                .get(0);

            Profile adminProfile = (Profile) new ProfileSelector()
                .selectProfileByName(new List<String>{ADMIN_USER_PROFILE_NAME})
                .executeQuery()
                .get(0);

            List<User> users = new SObjectBuilder(User.SObjectType)
                .quantity(8)
                .setFields(
                    new Map<SObjectField, Object>{
                        User.LastName => ValueProviderBuilder.provideUniqueString('Test_KnowledgeArticleService_LastName'),
                        User.FirstName => ValueProviderBuilder.provideUniqueString('Test_KnowledgeArticleService_FirstName'),
                        User.Email => ValueProviderBuilder.provideUniqueEmail('Test_KnowledgeArticleService_Email'),
                        User.UserPermissionsKnowledgeUser => ValueProviderBuilder.provideList(new List<Boolean>{
                            true, true, true, true, true, true, true, false
                        }),
                        User.Username => ValueProviderBuilder.provideList(new List<String>{
                            READER_USERNAME,
                            CANDIDATE_USERNAME,
                            CONTRIBUTOR_USERNAME,
                            PUBLISHER_USERNAME,
                            COACH_USERNAME,
                            EXPERT_USERNAME,
                            ADMIN_USERNAME,
                            NOT_KNOWLEDGE_USER_USERNAME
                        }),
                        User.LanguageLocaleKey => USER_LANGUAGE,
                        User.ProfileId => ValueProviderBuilder.provideList(new List<String>{
                            agentProfile.Id,
                            agentProfile.Id,
                            agentProfile.Id,
                            agentProfile.Id,
                            agentProfile.Id,
                            agentProfile.Id,
                            adminProfile.Id,
                            agentProfile.Id
                        }),
                        User.KCS_Role__c => ValueProviderBuilder.provideList(
                            new List<String>{
                                '', 'KCS Candidate', 'KCS Contributor', 'KCS Publisher', 'KCS Coach', 'Knowledge Domain Expert', 'Knowledge Domain Expert', ''
                            }
                        )
                    }
                )
                .create()
                .getRecords();
        }
    }

    public static Case createCase() {

        return (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1,
                    Case.Subject => CASE_SUBJECT_PROVIDER.getValue()
                }
            )
            .create()
            .getRecord();
    }

    public static Knowledge__kav createAndPublishArticleAsUser(User user, String status) {
        return createAndPublishArticlesAsUser(user, status, 1)[0];
    }

    public static Knowledge__kav buildArticle(String status) {
        return buildArticles(status, 1)[0];
    }

    public static List<Knowledge__kav> createAndPublishArticlesAsUser(User user, String status, Integer quantity) {

        KnowledgeArticleTriggerHelper.allowCreation = true;
        List<Knowledge__kav> publishedArticles;
        system.debug('create and Publish Articles As User'+user);
        System.runAs(user) {
            List<Knowledge__kav> articlesToInsert = buildArticles(status, quantity);
            insert articlesToInsert;
            Map<Id, Knowledge__kav> newVersions = new Map<Id, Knowledge__kav>(articlesToInsert);
            publishedArticles = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticlesById(new List<Object>{newVersions.keySet()})
                .executeQuery();
            for (Knowledge__kav articleVersion : publishedArticles) {
                system.debug('K_Article_Id' + articleVersion.KnowledgeArticleId);
                KbManagement.PublishingService.publishArticle(articleVersion.KnowledgeArticleId, false);
            }
        }
        KnowledgeArticleTriggerHelper.allowCreation = false;
        return publishedArticles;
    }

    public static List<Knowledge__kav> buildArticles(String status, Integer quantity) {

        return (List<Knowledge__kav>) new SObjectBuilder(Knowledge__kav.SObjectType)
            .quantity(quantity)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title =>
                        status == KnowledgeArticleService.STATUS_DRAFT
                            ? ValueProviderBuilder.provideUniqueString(KnowledgeArticleService.DRAFT_PREFIX + ARTICLE_TITLE)
                            : ValueProviderBuilder.provideUniqueString(ARTICLE_TITLE),
                    Knowledge__kav.UrlName =>
                        ValueProviderBuilder.provideUniqueString(
                            ARTICLE_URLNAME + Datetime.now().getTime() + Integer.valueOf((Math.random() * 100))
                        ),
                    Knowledge__kav.Summary => ARTICLE_SUMMARY,
                    Knowledge__kav.RC_Knowledge_Article_Details__c => ARTICLE_DETAILS,
                    Knowledge__kav.Language => ARTICLE_LANGUAGE,
                    Knowledge__kav.ValidationStatus => status,
                    Knowledge__kav.IsVisibleInCsp => status == KnowledgeArticleService.STATUS_EXTERNAL,
                    Knowledge__kav.OMA_Types__c => ARTICLE_OMA_TYPE
                }
            )
            .build()
            .getRecords();
    }

}