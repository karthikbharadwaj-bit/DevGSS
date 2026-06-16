public without sharing class KnowledgeArticleService {

    public static final Integer MIN_SEARCH_LENGTH = 3;
    public static final String LANGUAGE_DEFAULT = 'en_US';
    public static final String LANGUAGE_FRENCH = 'fr';
    public static final String LANGUAGE_GERMAN = 'de';
    public static final String LANGUAGE_SPANISH = 'es';

    public static final String ENGLISH = 'English';
    public static final String FRENCH = 'French';
    public static final String GERMAN = 'German';
    public static final String SPANISH = 'Spanish';

    public static final String ALL_ACTIVE = 'All Active';
    public static final String DRAFTS = 'Drafts';
    public static final String PUBLISHED = 'Published';
    public static final String REJECTED = 'Rejected';

    public static final String STATUS_INTERNAL = 'PublishedInternally';
    public static final String STATUS_COMPLIANCE = 'PublishedInternallyCompliance';
    public static final String STATUS_EXTERNAL = 'PublishedExternally';
    public static final String STATUS_DRAFT = 'Draft';
    public static final String STATUS_REJECTED = 'Rejected';

    public static final String DRAFT_PREFIX = '[Draft] ';

    public static final String ERROR_NOT_A_KCS_USER = 'You are not a KCS User';
    public static final String ERROR_NO_ACCESS_TO_PUBLISH = 'You have no permission to publish articles';
    public static final String ERROR_NO_ACCESS_TO_PUBLISH_EXT = 'You have no permission to publish articles externally';
    public static final String ERROR_NULL_ARTICLE = 'Received null article';
    public static final String ERROR_NO_TITLE = 'Article must have a title';
    public static final String ERROR_NO_URLNAME = 'Article must have a urlName';
    public static final String ERROR_NO_SUMMARY = 'Article must have a summary';
    public static final String ERROR_ALREADY_PUBLISHED = 'Please use the article comment section to request an edit';

    private static List<String> ARTICLE_SEARCH_FIELDS = new List<String>{
        'Id',
        'Title',
        'UrlName',
        'Summary',
        'LastPublishedDate'
    };

    public enum KCSRole {
        READER,
        CANDIDATE,
        CONTRIBUTOR,
        PUBLISHER,
        COACH,
        EXPERT
    }

    public static final Map<String, List<String>> VALIDATION_STATUSES_BY_FILTER = new Map<String, List<String>> {
        ALL_ACTIVE => new List<String> { STATUS_DRAFT, STATUS_INTERNAL, STATUS_EXTERNAL },
        DRAFTS => new List<String> { STATUS_DRAFT },
        PUBLISHED => new List<String> { STATUS_INTERNAL, STATUS_EXTERNAL },
        REJECTED => new List<String> { STATUS_REJECTED }
    };

    public static final Map<String, String> LANGUAGES_BY_FILTER = new Map<String, String> {
        ENGLISH => LANGUAGE_DEFAULT,
        FRENCH => LANGUAGE_FRENCH,
        GERMAN => LANGUAGE_GERMAN,
        SPANISH => LANGUAGE_SPANISH
    };

    private static final Map<String, KCSRole> ROLE_MAP = new Map<String, KCSRole>{
        'KCS Candidate' => KCSRole.CANDIDATE,
        'KCS Contributor' => KCSRole.CONTRIBUTOR,
        'KCS Publisher' => KCSRole.PUBLISHER,
        'KCS Coach' => KCSRole.COACH,
        'Knowledge Domain Expert' => KCSRole.EXPERT
    };

    public static Knowledge__kav getDraftVersion(Id knowledgeId) {
        List<Knowledge__kav> result = (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectDraftsByKnowledgeId(new List<Object>{new List<Id>{knowledgeId}})
            .executeQuery();
        if (!result.isEmpty()) {
            return result[0];
        } else {
            return null;
        }
    }

    private static KCSRole currentUserKCSRole {
        get {
            if (currentUserKCSRole == null || Test.isRunningTest()) {
                User currentUser = (User) new UserSelector()
                    .selectUsersByIdNoFields(new List<Object>{new List<String>{UserInfo.getUserId()}})
                    .selectFields(new List<String>{'KCS_Role__c'})
                    .executeQuery()
                    .get(0);

                if (String.IsBlank(currentUser.KCS_Role__c) || !ROLE_MAP.containsKey(currentUser.KCS_Role__c)) {
                    currentUserKCSRole = KCSRole.READER;
                } else {
                    currentUserKCSRole = ROLE_MAP.get(currentUser.KCS_Role__c);
                }
            }
            return currentUserKCSRole;
        }
        private set;
    }

    public static Integer currentUserKCSLevel {
        get {
            if (currentUserKCSLevel == null) {
                currentUserKCSLevel = currentUserKCSRole.ordinal();
            }
            return currentUserKCSLevel;
        }
        private set;
    }

    public static Boolean isCurrentUserKCSRoleAtLeast(KCSRole requiredRole) {
        return currentUserKCSRole.ordinal() >= requiredRole.ordinal();
    }

    public static void requireKCSRoleAtLeast(KCSRole requiredRole, String errorMessage) {
        if (!isCurrentUserKCSRoleAtLeast(requiredRole)) {
            AquivaHelper.throwAquivaException(errorMessage);
        }
    }

    public static void approveDraftArticle(Knowledge__kav articleVersion) {

        requireKCSRoleAtLeast(KnowledgeArticleService.KCSRole.CONTRIBUTOR, ERROR_NO_ACCESS_TO_PUBLISH);

        KnowledgeArticleTriggerHelper.allowCreation = true;
        Knowledge__kav draftVersion = editArticleAsDraft(articleVersion);
        KnowledgeArticleTriggerHelper.allowCreation = false;

        draftVersion.ValidationStatus = STATUS_INTERNAL;
        draftVersion.Title = draftVersion.Title.removeStart(DRAFT_PREFIX);
        draftVersion.RC_Knowledge_Article_ReviewDateTime__c = System.now();
        draftVersion.RC_Knowledge_Article_DecisionMaker__c = UserInfo.getUserId();

        KnowledgeArticleTriggerHelper.allowReview = true;
        update draftVersion;
        KnowledgeArticleTriggerHelper.allowReview = false;

        KbManagement.PublishingService.publishArticle(articleVersion.KnowledgeArticleId, false);
    }

    public static void rejectDraftArticle(Knowledge__kav articleVersion, String rejectionComment) {

        requireKCSRoleAtLeast(KnowledgeArticleService.KCSRole.PUBLISHER, ERROR_NO_ACCESS_TO_PUBLISH);

        KnowledgeArticleTriggerHelper.allowCreation = true;
        Knowledge__kav draftVersion = editArticleAsDraft(articleVersion);
        KnowledgeArticleTriggerHelper.allowCreation = false;

        draftVersion.ValidationStatus = STATUS_REJECTED;
        draftVersion.RC_Knowledge_Article_ReviewDateTime__c = System.now();
        draftVersion.RC_Knowledge_Article_DecisionMaker__c = UserInfo.getUserId();
        draftVersion.RC_Knowledge_Article_RejectionReason__c = rejectionComment;

        KnowledgeArticleTriggerHelper.allowReview = true;
        update draftVersion;
        KnowledgeArticleTriggerHelper.allowReview = false;

        KbManagement.PublishingService.publishArticle(articleVersion.KnowledgeArticleId, false);
        KbManagement.PublishingService.archiveOnlineArticle(articleVersion.KnowledgeArticleId, null);
    }

    public static void changeArticleValidationStatus(Knowledge__kav articleVersion) {

        requireKCSRoleAtLeast(KnowledgeArticleService.KCSRole.CONTRIBUTOR, ERROR_NO_ACCESS_TO_PUBLISH);

        KnowledgeArticleTriggerHelper.allowCreation = true;
        Knowledge__kav draftVersion = editArticleAsDraft(articleVersion);
        KnowledgeArticleTriggerHelper.allowCreation = false;

        if (draftVersion.ValidationStatus == STATUS_DRAFT) {
            draftVersion.RC_Knowledge_Article_ReviewDateTime__c = System.now();
        }
        draftVersion.IsVisibleInPrm = articleVersion.IsVisibleInPrm;
        draftVersion.IsVisibleInPkb = articleVersion.IsVisibleInPkb;
        draftVersion.IsVisibleInCsp = articleVersion.IsVisibleInCsp;
        draftVersion.ValidationStatus = articleVersion.ValidationStatus;
        draftVersion.RC_Knowledge_Article_DecisionMaker__c = UserInfo.getUserId();

        KnowledgeArticleTriggerHelper.allowReview = true;
        update draftVersion;
        KnowledgeArticleTriggerHelper.allowReview = false;

        KbManagement.PublishingService.publishArticle(articleVersion.KnowledgeArticleId, false);
    }

    public static Knowledge__kav editArticleAsDraft(Knowledge__kav articleVersion) {

        if (null == articleVersion) {
            return null;
        }
        return editArticlesAsDrafts(new List<Knowledge__kav>{articleVersion}).get(articleVersion.KnowledgeArticleId);
    }

    public static Map<Id, Knowledge__kav> editArticlesAsDrafts(List<Knowledge__kav> articleVersions) {

        requireKCSRoleAtLeast(KnowledgeArticleService.KCSRole.CONTRIBUTOR, ERROR_NO_ACCESS_TO_PUBLISH);

        KnowledgeArticleTriggerHelper.allowCreation = true;
        Map<Id, Knowledge__kav> result = new Map<Id, Knowledge__kav>();

        Set<Id> knowledgeIds = new Set<Id>();
        for (Knowledge__kav artVer : articleVersions) {
            knowledgeIds.add(artVer.KnowledgeArticleId);
        }
        if (knowledgeIds.isEmpty()) {
            return result;
        }

        for (Knowledge__kav existingDraft : (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectDraftsByKnowledgeId(new List<Object>{knowledgeIds})
                .executeQuery()) {

            result.put(existingDraft.KnowledgeArticleId, existingDraft);
        }

        Set<Id> newlyEditedVersionIds = new Set<Id>();
        for (Id knowledgeId : knowledgeIds) {
            if (!result.containsKey(knowledgeId)) {
                newlyEditedVersionIds.add(
                    KbManagement.PublishingService.editOnlineArticle(knowledgeId, false)
                );
            }
        }
        if (!newlyEditedVersionIds.isEmpty()) {
            for (Knowledge__kav newlyEditedVersion : (List<Knowledge__kav>) new KnowledgeArticleSelector()
                    .selectArticlesById(new List<Object>{newlyEditedVersionIds})
                    .executeQuery()) {

                result.put(newlyEditedVersion.KnowledgeArticleId, newlyEditedVersion);
            }
        }

        KnowledgeArticleTriggerHelper.allowCreation = false;
        return result;
    }

    public static Id publishNewArticle(Knowledge__kav newVersion, Map<String, String> categories, Id caseIdToAttachTo) {

        requireKCSRoleAtLeast(KCSRole.CANDIDATE, ERROR_NOT_A_KCS_USER);

        if (newVersion == null) {
            AquivaHelper.throwAquivaException(ERROR_NULL_ARTICLE);
        }
        if (String.isBlank(newVersion.Title)) {
            AquivaHelper.throwAquivaException(ERROR_NO_TITLE);
        }
        if (String.isBlank(newVersion.UrlName)) {
            AquivaHelper.throwAquivaException(ERROR_NO_URLNAME);
        }
        if (String.isBlank(newVersion.Summary)) {
            AquivaHelper.throwAquivaException(ERROR_NO_SUMMARY);
        }
        if (String.isBlank(newVersion.Language)) {
            newVersion.Language = LANGUAGE_DEFAULT;
        }
        if (String.isBlank(newVersion.ValidationStatus)) {
            newVersion.ValidationStatus = STATUS_DRAFT;
        }
        if (newVersion.ValidationStatus == STATUS_INTERNAL) {
            requireKCSRoleAtLeast(KCSRole.CONTRIBUTOR, ERROR_NO_ACCESS_TO_PUBLISH);
        }
        if (newVersion.ValidationStatus == STATUS_EXTERNAL) {
            requireKCSRoleAtLeast(KCSRole.PUBLISHER, ERROR_NO_ACCESS_TO_PUBLISH_EXT);
        }
        if (newVersion.ValidationStatus == STATUS_DRAFT && !newVersion.ValidationStatus.startsWith(DRAFT_PREFIX)) {
            newVersion.Title = DRAFT_PREFIX + newVersion.Title;
        }
        if (!String.isBlank(newVersion.KnowledgeArticleId)) {
            AquivaHelper.throwAquivaException(ERROR_ALREADY_PUBLISHED);
        }

        KnowledgeArticleTriggerHelper.allowCreation = true;
        insert newVersion;
        KnowledgeArticleTriggerHelper.allowCreation = false;

        Knowledge__kav publishedArticle =
            (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArticleById(new List<String>{newVersion.Id})
                .executeQuery()
                .get(0);

        KbManagement.PublishingService.publishArticle(publishedArticle.KnowledgeArticleId, true);

        if (categories != null && categories.size() > 0) {
            insert new SObjectBuilder(Knowledge__DataCategorySelection.SObjectType)
                .quantity(categories.size())
                .setFields(
                    new Map<Schema.SObjectField, Object>{
                        Knowledge__DataCategorySelection.ParentId =>
                            publishedArticle.Id,
                        Knowledge__DataCategorySelection.DataCategoryGroupName =>
                            new ValueProvider.ListProvider(new List<String>(categories.keySet())),
                        Knowledge__DataCategorySelection.DataCategoryName =>
                            new ValueProvider.ListProvider(categories.values())
                    }
                )
                .build()
                .getRecords();
        }

        if (caseIdToAttachTo != null) {
            attachArticleToCase(publishedArticle.KnowledgeArticleId, caseIdToAttachTo);
        }

        return publishedArticle.KnowledgeArticleId;
    }

    public static void attachArticleToCase(Id articleId, Id caseId) {

        insert new SObjectBuilder(CaseArticle.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    CaseArticle.KnowledgeArticleId => articleId,
                    CaseArticle.CaseId => caseId
                }
            )
            .build()
            .getRecord();
    }

    public static List<SCWrappers.Article> searchArticlesByTitleOrKeyword(
        String titlePart,
        String langCode,
        Map<String, String> allowedCategories,
        Integer searchLimit) {

        if (String.isBlank(titlePart) || String.isBlank(langCode)) {
            AquivaHelper.throwAquivaException('Invalid article search request');
        }
        if (titlePart.length() < MIN_SEARCH_LENGTH) {
            AquivaHelper.throwAquivaException('Search string too short. Minimum size is ' + MIN_SEARCH_LENGTH);
        }

        List<SCWrappers.Article> result = new List<SCWrappers.Article>();

        String searchExpression = 'Language =  \'' + String.escapeSingleQuotes(langCode) + '\''
            + ' AND PublishStatus = \'Online\''
            + ' AND ValidationStatus = \'PublishedExternally\''
            + ' AND (RC_Knowledge_Article_Key_Words__c LIKE \'%' + String.escapeSingleQuotes(titlePart) + '%\''
            + ' OR Title LIKE \'%' + String.escapeSingleQuotes(titlePart) + '%\') ';
        if (allowedCategories != null && !allowedCategories.isEmpty()) {
            searchExpression += ' WITH DATA CATEGORY';
            for (String categoryGroupName : allowedCategories.keySet()) {
                searchExpression += ' ' + String.escapeSingleQuotes(categoryGroupName) + '__c AT '
                    + String.escapeSingleQuotes(allowedCategories.get(categoryGroupName)) + '__c AND';
            }
            searchExpression = searchExpression.removeEnd('AND');
        }

        QueryFactory qf = new KnowledgeArticleSelector()
            .selectArticles()
            .withoutSelectorFieldsIncluded()
            .selectFields(ARTICLE_SEARCH_FIELDS)
            .setCondition(searchExpression);

        if (searchLimit != null) {
            qf.setLimit(searchLimit);
        }
        for (Knowledge__kav articleVersion :
            (List<Knowledge__kav>) qf.executeQuery()) {

            result.add(
                new SCWrappers.Article(
                    String.valueOf(articleVersion.Id),
                    articleVersion.Title,
                    articleVersion.UrlName,
                    articleVersion.Summary,
                    articleVersion.LastPublishedDate.format('yyyy-MM-dd')
                )
            );
        }
        return result;
    }

    public static Boolean isKnowledgeUser(Id userId) {
        List<User> users = (List<User>) new UserSelector()
            .selectUsers()
            .selectField('Id')
            .setCondition('UserPermissionsKnowledgeUser = TRUE AND Id =:bind0')
            .setQueryBindings(new List<Object>{userId})
            .executeQuery();

        return !users.isEmpty();
    }
}