public class ArticleVersionsController {
    public static String ARTICLE_NUMBER = 'ArticleNumber';
    public Knowledge__kav article { get; set; }
    private List<Knowledge__kav> allVersions = new List<Knowledge__kav>();
    private String CURRENT_VERSION = ' (current version)';
    private String ARTICLE_KAV_CONDITION = 'ArticleNumber =:bind0 AND Language =:bind1';
    private String ARTICLE_VERSIONS_CONDITION =
        'PublishStatus = \'Archived\' AND IsLatestVersion = false AND KnowledgeArticleId =:bind0 AND Language =:bind1';
    private List<String> ARTICLE_KAV_FIELDS = new List<String>{
        'KnowledgeArticleId', 'VersionNumber', 'Title', 'LastModifiedBy', 'LastModifiedBy.Name',
        'LastPublishedDate', 'LastModifiedDate', 'CreatedDate', 'Language'
    };

    public ArticleVersionsController() {
        if (!KnowledgeArticleService.isKnowledgeUser(UserInfo.getUserId())) {
            AquivaHelper.throwAquivaException(Label.KCS_No_permissions_to_access_page);
        }

        this.article = getLastVersionArticle();

        if (article != null) {
            allVersions.addAll(getAllArticleVersions(article.KnowledgeArticleId, article.Language));
        }
        this.setCon = setCon;
    }

    public ApexPages.StandardSetController setCon {
        get {
            if (setCon == null) {
                setCon = new ApexPages.StandardSetController(allVersions);
            }
            return setCon;
        }
        set;
    }

    public List<Knowledge__kav> getVersions() {
        return (List<Knowledge__kav>) setCon.getRecords();
    }

    public List<Knowledge__kav> getAllArticleVersions(String articleId, String language) {
        return (List<Knowledge__kav>) new KnowledgeArticleSelector()
            .selectArticles()
            .selectFields(ARTICLE_KAV_FIELDS)
            .setCondition(ARTICLE_VERSIONS_CONDITION)
            .setQueryBindings(new List<Object>{articleId, language})
            .addOrdering(Knowledge__kav.VersionNumber, QueryFactory.SortOrder.DESCENDING)
            .withoutSelectorFieldsIncluded()
            .executeQuery();
    }

    public Knowledge__kav getLastVersionArticle() {
        String articleNumber = ApexPages.currentPage().getParameters().get(ARTICLE_NUMBER);

        if (String.isNotBlank(articleNumber)) {
            List<Knowledge__kav> archivedArticleKavs =
                (List<Knowledge__kav>) new KnowledgeArticleSelector()
                    .selectArticleByArticleNumber(new List<Object>{articleNumber})
                    .setCondition('ArticleNumber =:bind0 AND PublishStatus = \'Archived\'')
                    .selectFields(ARTICLE_KAV_FIELDS)
                    .withoutSelectorFieldsIncluded()
                    .withoutSelectorOrderByIncluded()
                    .executeQuery();

            if (!archivedArticleKavs.isEmpty()) {
                Knowledge__kav latestVersionArticle = archivedArticleKavs.get(0);
                allVersions.add(archivedArticleKavs.get(0));
                return latestVersionArticle;
            }

            List<Knowledge__ka> onlineArticleKas =
                (List<Knowledge__ka>) new KnowledgeArticleKASelector()
                .selectArticleByArticleNumber(new List<Object>{articleNumber})
                .executeQuery();

            if (!onlineArticleKas.isEmpty()) {
                String language = onlineArticleKas.get(0).MasterLanguage == null
                    ? KnowledgeArticleService.LANGUAGE_DEFAULT : onlineArticleKas.get(0).MasterLanguage;

                List<Knowledge__kav> articleKavs =
                    (List<Knowledge__kav>) new KnowledgeArticleSelector()
                        .selectArticles()
                        .withoutSelectorFieldsIncluded()
                        .selectFields(ARTICLE_KAV_FIELDS)
                        .setCondition(ARTICLE_KAV_CONDITION)
                        .setQueryBindings(new List<Object>{articleNumber, language})
                        .executeQuery();

                if (!articleKavs.isEmpty()) {
                    Knowledge__kav latestVersionArticle = articleKavs.get(0);
                    latestVersionArticle.Title = latestVersionArticle.Title + CURRENT_VERSION;
                    allVersions.add(latestVersionArticle);
                    return latestVersionArticle;
                }
            }
        }
        return null;
    }
}