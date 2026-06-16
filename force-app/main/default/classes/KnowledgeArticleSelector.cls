public inherited sharing class KnowledgeArticleSelector extends SObjectSelector {

    public KnowledgeArticleSelector() {
        super();
    }

    public KnowledgeArticleSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Knowledge__kav.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Knowledge__kav.Id,
            Knowledge__kav.Title,
            Knowledge__kav.UrlName,
            Knowledge__kav.PublishStatus,
            Knowledge__kav.RC_Knowledge_Article_Details__c,
            Knowledge__kav.RC_Knowledge_Article_DecisionMaker__c,
            Knowledge__kav.Summary,
            Knowledge__kav.RC_Knowledge_Article_Key_Words__c,
            Knowledge__kav.RC_Knowledge_Article_ReviewedBy__c,
            Knowledge__kav.ArticleTotalViewCount,
            Knowledge__kav.KnowledgeArticleId,
            Knowledge__kav.ArticleNumber,
            Knowledge__kav.CreatedDate,
            Knowledge__kav.Language,
            Knowledge__kav.KnowledgeArticleId,
            Knowledge__kav.VersionNumber,
            Knowledge__kav.ValidationStatus,
            Knowledge__kav.FileAttachmentsLink__c,
            Knowledge__kav.IsVisibleInPrm,
            Knowledge__kav.isVisibleInCsp,
            Knowledge__kav.isVisibleInPkb,
            Knowledge__kav.TimeSinceSubmission__c,
            Knowledge__kav.TimeSinceSubmission_ms__c,
            Knowledge__kav.RC_Knowledge_Article_ReviewDateTime__c,
            Knowledge__kav.ArticleCreatedDate,
            Knowledge__kav.RC_Knowledge_Article_Knowledge_Article10__c,
            Knowledge__kav.LastPublishedDate,
            Knowledge__kav.LastModifiedDate
        };
    }

    public List<String> getArticleFields() {
        return new List<String> {
            'Id',
            'Title',
            'KnowledgeArticleId',
            'ArticleNumber',
            'AssignedToId',
            'AssignedTo.Name',
            'ValidationStatus',
            'TimeSinceSubmission__c',
            'RC_Knowledge_Article_DecisionMaker__c',
            'TimeSinceSubmission_ms__c',
            'ArticleCreatedDate',
            'ArticleCreatedDate',
            'CreatedBy.Id',
            'CreatedBy.Name',
            'CreatedBy.Email',
            'RC_Knowledge_Article_ReviewedBy__r.Id',
            'RC_Knowledge_Article_ReviewedBy__r.Name',
            'RC_Knowledge_Article_ReviewedBy__r.Email',
            'RC_Knowledge_Article_DecisionMaker__r.Id',
            'RC_Knowledge_Article_DecisionMaker__r.Name',
            'RC_Knowledge_Article_DecisionMaker__r.Email',
            'RC_Knowledge_Article_Knowledge_Article10__c',
            'LastModifiedBy',
            'LastModifiedBy.Name'
        };
    }

    public List<String> getFieldsForEmailNotifications() {
        return new List<String> {
            'Id',
            'RC_Knowledge_Article_Knowledge_Article10__c',
            'KnowledgeArticleId',
            'RC_Knowledge_Article_EmailOfArticleCre11__c',
            'RC_Knowledge_Article_Old_ValidationSta24__c'
        };
    }

    public QueryFactory selectArticles() {
        return newQueryFactory()
            .setFactoryName('selectArticles')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectArticlesById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectArticlesById')
            .withSelectorFieldsIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectArticleById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectArticleById')
            .withSelectorFieldsIncluded()
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectArticleByTitle(List<Object> bindings) {
        system.debug('Query framed here is>>>:'+newQueryFactory()
            .setFactoryName('selectArticleByTitle')
            .withSelectorFieldsIncluded()
            .setCondition('Title = :bind0')
            .setQueryBindings(bindings));
        
        return newQueryFactory()
            .setFactoryName('selectArticleByTitle')
            .withSelectorFieldsIncluded()
            .setCondition('Title = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectArticleByArticleNumber(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectArticleByArticleNumber')
            .withSelectorFieldsIncluded()
            .selectFields(getArticleFields())
            .setCondition('ArticleNumber IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectArticlesByValidationAndPublishStatuses(
        List<Object> bindings, Boolean checkPublishStatus, Boolean forCurrentUser) {
        QueryFactory qf = newQueryFactory()
            .setFactoryName('selectArticlesByValidationAndPublishStatuses')
            .withoutSelectorFieldsIncluded()
            .selectFields(getArticleFields())
            .withoutSelectorOrderByIncluded();

        String condition = 'ValidationStatus IN :bind0';
        condition += checkPublishStatus ? ' AND PublishStatus = \'Archived\'' : '';
        condition += forCurrentUser ? ' AND CreatedBy.Id =:bind1' : '';
        condition += forCurrentUser ? ' AND Language =:bind2' : ' AND Language =:bind1';

        qf.setCondition(condition);
        qf.setQueryBindings(bindings);

        return qf;
    }

    public QueryFactory selectDraftsByKnowledgeId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDraftsByKnowledgeId')
            .withSelectorFieldsIncluded()
            .selectFields(getArticleFields())
            .setCondition('KnowledgeArticleId IN :bind0 AND PublishStatus = \'Draft\' AND IsLatestVersion = TRUE')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOnlineByKnowledgeIdAndLanguage(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOnlineByKnowledgeIdAndLanguage')
            .withSelectorFieldsIncluded()
            .selectFields(getArticleFields())
            .setCondition('KnowledgeArticleId IN :bind0 AND PublishStatus = \'Online\' AND IsLatestVersion = TRUE AND Language = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectArticlesByIdsWithNullKnowledgeArticleURL(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectArticlesByIdsWithNullKnowledgeArticleURL')
            .selectFields(getFieldsForEmailNotifications())
            .setCondition('Id IN :bind0 AND RC_Knowledge_Article_Knowledge_Article10__c = null')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectArticlesWithFieldsForEmailNotifications() {
        return newQueryFactory()
            .setFactoryName('selectArticlesWithFieldsForEmailNotifications')
            .selectFields(getFieldsForEmailNotifications())
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectArchivedByKnowledgeId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectArchivedByKnowledgeId')
            .withSelectorFieldsIncluded()
            .selectFields(getArticleFields())
            .setCondition('KnowledgeArticleId IN :bind0 AND PublishStatus = \'Archived\' AND IsLatestVersion = TRUE')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectArticlesForToReviewPage(
        List<Object> bindings, Boolean checkPublishStatus, Boolean forCurrentUser) {
        QueryFactory qf = newQueryFactory()
            .setFactoryName('selectArticlesByValidationAndPublishStatuses')
            .withoutSelectorFieldsIncluded()
            .selectFields(getArticleFields())
            .withoutSelectorOrderByIncluded();

        String condition = 'ValidationStatus IN :bind0';
        condition += checkPublishStatus ? ' AND PublishStatus = \'Archived\'' : '';
        condition += ' AND PublishStatus = \'Online\'';
        condition += forCurrentUser ? ' AND CreatedBy.Id =:bind1' : '';
        condition += forCurrentUser ? ' AND Language =:bind2' : ' AND Language =:bind1';

        qf.setCondition(condition);
        qf.setQueryBindings(bindings);

        return qf;
    }
}