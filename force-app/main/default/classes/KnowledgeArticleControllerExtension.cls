public class KnowledgeArticleControllerExtension {
    public final Integer MAX_LEN_COMMENT = 32768;
    public final Integer MIN_LEN_COMMENT = 20;
    public final String ARTICLE_DRAFT_STATUS = 'Draft';

    public String printParameters {
        get {
            return (articleVersion != null && articleVersion.PublishStatus == ARTICLE_DRAFT_STATUS)
                ? '&pubstatus=d&preview=true'
                : '';
        }
        set;
    }

    public Knowledge__kav articleVersion {get;set;}
    public RC_User_Article_Rating__c comment {get;set;}
    public List<Object> externalComments {get;set;}
    public List<Object> internalComments {get;set;}
    public List<String> FIELDS_TO_RETRIEVE = new List<String> {'SmallPhotoUrl', 'Email'};
    public static List<String> EXTRA_FIELDS = new List<String> {
        'PublishStatus',
        'IsLatestVersion',
        'Language',
        'IsVisibleInPrm',
        'IsVisibleInPkb',
        'IsVisibleInCsp',
        'RC_Knowledge_Article_RejectionReason__c',
        'RC_Knowledge_Article_DecisionMaker__c',
        'RC_Knowledge_Article_DecisionMaker__r.Name'
    };

    public String rejectionComment {get;set;}

    public String latestVersionLink {
        get {
            if (articleVersion.IsLatestVersion) {
                return null;
            }
            List<Knowledge__kav> latestVersions = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectOnlineByKnowledgeIdAndLanguage(
                    new List<Object>{new List<String>{articleVersion.KnowledgeArticleId}, articleVersion.Language}
                )
                .executeQuery();
            List<Knowledge__kav> archivedVersions = (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArchivedByKnowledgeId(
                    new List<Object>{new List<String>{articleVersion.KnowledgeArticleId}}
                )
                .executeQuery();
            if (latestVersions.size() > 0 && latestVersions[0].Id != articleVersion.Id) {
                PageReference tempPage = ApexPages.currentPage();
                tempPage.getParameters().put('kavVersion', String.valueOf(latestVersions[0].VersionNumber));
                return tempPage.getUrl();
            } else if (archivedVersions.size() > 0 && archivedVersions[0].Id != articleVersion.Id) {
                PageReference tempPage = ApexPages.currentPage();
                tempPage.getParameters().put('kavVersion', String.valueOf(archivedVersions[0].VersionNumber));
                return tempPage.getUrl();
            } else {
                return null;
            }
        }
        private set;
    }

    public Boolean isDraft {
        get {
            return articleVersion.ValidationStatus == KnowledgeArticleService.STATUS_DRAFT;
        }
        private set;
    }

    public Boolean isInternal {
        get {
            return articleVersion.ValidationStatus == KnowledgeArticleService.STATUS_INTERNAL;
        }
        private set;
    }

    public Boolean isRejected {
        get {
            return articleVersion.ValidationStatus == KnowledgeArticleService.STATUS_REJECTED;
        }
        private set;
    }

    public Boolean iAmDecisionMaker {
        get {
            if (articleVersion.RC_Knowledge_Article_DecisionMaker__c == null) {
                return null;
            }
            return UserInfo.getUserId().equals(articleVersion.RC_Knowledge_Article_DecisionMaker__c);
        }
        private set;
    }

    public String decisionMakerName {
        get {
            if (articleVersion.RC_Knowledge_Article_DecisionMaker__c == null) {
                return null;
            }
            return articleVersion.RC_Knowledge_Article_DecisionMaker__r.Name;
        }
        private set;
    }

    public String decisionMakerLink {
        get {
            if (articleVersion.RC_Knowledge_Article_DecisionMaker__c == null) {
                return null;
            }
            return System.URL.getOrgDomainUrl().toExternalForm() + '/' + articleVersion.RC_Knowledge_Article_DecisionMaker__c;
        }
        private set;
    }

    public Boolean iAmDraftEditor {
        get {
            if (draftVersion == null || draftVersion.AssignedToId == null) {
                return null;
            }
            return UserInfo.getUserId().equals(draftVersion.AssignedToId);
        }
        private set;
    }

    public String draftEditorName {
        get {
            if (draftVersion == null || draftVersion.AssignedToId == null) {
                return null;
            }
            return draftVersion.AssignedTo.Name;
        }
        private set;
    }

    public String draftEditorLink {
        get {
            if (draftVersion == null || draftVersion.AssignedToId == null) {
                return null;
            }
            return System.URL.getOrgDomainUrl().toExternalForm() + '/' + draftVersion.AssignedToId;
        }
        private set;
    }

    public Boolean currentUserCanReviewArticle {
        get {
            return KnowledgeArticleService.isCurrentUserKCSRoleAtLeast(KnowledgeArticleService.KCSRole.CONTRIBUTOR);
        }
        private set;
    }

    public Knowledge__kav draftVersion {
        get {
            if (draftVersion == null) {
                draftVersion = KnowledgeArticleService.getDraftVersion(articleVersion.KnowledgeArticleId);
            }
            return draftVersion;
        }
        private set;
    }

    public KnowledgeArticleControllerExtension(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(EXTRA_FIELDS);
        }
        articleVersion = (Knowledge__kav) stdController.getRecord();
        comment = new RC_User_Article_Rating__c();

        List<RC_User_Article_Rating__c> comments = new RCUserArticleRatingSelector()
            .selectRCUserArticleRatingByArticleId(new List<String>{articleVersion.ArticleNumber})
            .executeQuery();

        List<String> commentUserIds = new List<String>();
        for (RC_User_Article_Rating__c comment : comments) {
            commentUserIds.add(comment.RC_User_Id__c);
        }

        List<User> users = new UserSelector().newQueryFactory()
            .setQueryBindings(new List<Object>{commentUserIds})
            .selectFields(FIELDS_TO_RETRIEVE)
            .setCondition('Id IN :bind0')
            .executeQuery();

        Map<Id, User> idToUser = new Map<Id, User>(users);
        externalComments = new List<Object>();
        internalComments = new List<Object>();

        for (RC_User_Article_Rating__c comment : comments) {
            if (comment.User_Comments__c != null) {
                User user = idToUser.get(comment.RC_User_Id__c);
                Map<String, Object> commentWrapper = new Map<String, Object>();
                commentWrapper.put('comment', comment);
                if (user != null) {
                    commentWrapper.put('user', user);
                } else {
                    commentWrapper.put('user', '{}');
                }
                if (comment.Is_External__c) {
                    externalComments.add(commentWrapper);
                } else {
                    internalComments.add(commentWrapper);
                }
            }
        }
    }

    public void saveComment() {
        if (comment.User_Comments__c != null) {
            comment.User_Comments__c = comment.User_Comments__c.trim();
        }

        if (String.isBlank(comment.User_Comments__c)) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                Label.ArticleManagement_empty_comment)
            );
            return;
        }

        if (comment.User_Comments__c.length() < MIN_LEN_COMMENT) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(
                Label.ArticleManagement_too_short_comment,
                new List<String>{String.valueOf(MIN_LEN_COMMENT)}))
            );
            return;
        }

        if (comment.User_Comments__c.length() >= MAX_LEN_COMMENT) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(
                Label.ArticleManagement_too_long_comment,
                new List<String>{String.valueOf(MAX_LEN_COMMENT)}))
            );
            return;
        }

        RC_User_Article_Rating__c comment =
            (RC_User_Article_Rating__c) new SObjectBuilder(RC_User_Article_Rating__c.SObjectType)
            .setField(RC_User_Article_Rating__c.Is_External__c, comment.Is_External__c)
            .setField(RC_User_Article_Rating__c.RC_User_Id__c, UserInfo.getUserId())
            .setField(RC_User_Article_Rating__c.RC_User_name__c, UserInfo.getName())
            .setField(RC_User_Article_Rating__c.RC_ArticleID__c, articleVersion.ArticleNumber)
            .setField(RC_User_Article_Rating__c.User_Comments__c, comment.User_Comments__c)
            .create()
            .getRecord();

        List<String> userIds = new List<String>{UserInfo.getUserId()};
        List<User> currentUser = new UserSelector().newQueryFactory()
            .setQueryBindings(new List<Object>{userIds})
            .selectFields(FIELDS_TO_RETRIEVE)
            .setCondition('Id IN :bind0')
            .setLimit(1)
            .executeQuery();

        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.ArticleManagement_comment_added));
        Map<String, Object> commentWrapper = new Map<String, Object>();
        commentWrapper.put('comment', comment);
        commentWrapper.put('user', currentUser.get(0));

        if (comment.Is_External__c) {
            if (externalComments.isEmpty()) {
                externalComments.add(commentWrapper);
            } else {
                externalComments.add(0, commentWrapper);
            }
        } else {
            if (internalComments.isEmpty()) {
                internalComments.add(commentWrapper);
            } else {
                internalComments.add(0, commentWrapper);
            }
        }

        comment = new RC_User_Article_Rating__c();
    }

    public PageReference approveArticle() {

        if (currentUserCanReviewArticle) {
            KnowledgeArticleService.approveDraftArticle(articleVersion); 
        }
        PageReference tempPage = ApexPages.currentPage();
        tempPage.setRedirect(true);
        return tempPage;
    }

    public PageReference publishArticleExternally() {

        if (currentUserCanReviewArticle) {
            articleVersion.ValidationStatus = KnowledgeArticleService.STATUS_EXTERNAL;
            KnowledgeArticleService.changeArticleValidationStatus(articleVersion); 
        }
        PageReference tempPage = ApexPages.currentPage();
        tempPage.setRedirect(true);
        return tempPage;
    }

    public PageReference rejectArticle() {

        if (currentUserCanReviewArticle) {
            KnowledgeArticleService.rejectDraftArticle(articleVersion, rejectionComment);
        }
        PageReference tempPage = new PageReference('/apex/NewArticlePage?id=' + ApexPages.currentPage().getParameters().get('id'));
        tempPage.setRedirect(true);
        return tempPage;
    }

    public PageReference goToEditArticle() {

        if (currentUserCanReviewArticle) {  
            return new PageReference(
                '/knowledge/publishing/articleEdit.apexp?id='
                + KnowledgeArticleService.editArticleAsDraft(articleVersion).KnowledgeArticleId
            );
        } else {
            return null;
        }
    }
}