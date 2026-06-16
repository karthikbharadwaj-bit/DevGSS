public with sharing class ArticleReviewControllerExtension {
    public static final String ASCENDING = 'ASC';
    public static final String DESCENDING = 'DESC';
    public static final String DEFAULT_SORT_FIELD = 'ArticleCreatedDate';
    public static final Integer DEFAULT_PAGE_SIZE = 25;

    public ApexPages.StandardSetController con { get; set; }
    public String sortDir { get; set; }
    public String sortField { get; set; }
    public String lang { get; set; }

    public Boolean hasNext {
        get {
            return this.con.getHasNext();
        }
        set;
    }

    public Boolean hasPrevious {
        get {
            return this.con.getHasPrevious();
        }
        set;
    }

    public Integer pageNumber {
        get {
            this.pageNumber = this.con.getPageNumber();
            return this.pageNumber;
        }
        set;
    }

    public ArticleReviewControllerExtension() {

        if (!KnowledgeArticleService.isCurrentUserKCSRoleAtLeast(KnowledgeArticleService.KCSRole.CONTRIBUTOR)) {
            AquivaHelper.throwAquivaException(Label.KCS_No_permissions_to_access_page);
        }

        this.lang = lang == null ? KnowledgeArticleService.ENGLISH : lang;
        this.sortDir = sortDir == null ? ASCENDING : sortDir;
        this.sortField = sortField == null ? DEFAULT_SORT_FIELD : sortField;
        refresh();
        getLanguages();
        getAllArticles();
    }

    public List<Knowledge__kav> getArticles() {
        return (List<Knowledge__kav>) this.con.getRecords();
    }

    public PageReference getAllArticles() {
        this.lang = lang == null ? KnowledgeArticleService.ENGLISH : lang;
        this.sortField = sortField;
        this.sortDir = sortDir;
        getArticles();
        return null;
    }

    public void refresh() {
        QueryFactory qf = new KnowledgeArticleSelector().selectArticlesForToReviewPage(
            new List<Object> {
                new List<String> {KnowledgeArticleService.STATUS_DRAFT},
                KnowledgeArticleService.LANGUAGES_BY_FILTER.get(lang)
            }, false, false);

        sortField = sortField == null ? DEFAULT_SORT_FIELD : sortField;
        QueryFactory.SortOrder sortOrder = sortDir == ASCENDING
            ? QueryFactory.SortOrder.ASCENDING
            : QueryFactory.SortOrder.DESCENDING;
        qf.addOrdering(sortField, sortOrder);

        List<Knowledge__kav> allArticles = (List<Knowledge__kav>) qf.executeQuery();

        this.con = new ApexPages.StandardSetController(allArticles);
        this.con.setPageSize(DEFAULT_PAGE_SIZE);
    }

    public void toggleSort() {
        sortDir = sortDir == ASCENDING ? DESCENDING : ASCENDING;

        if (!String.isBlank(sortField) && sortField.equalsIgnoreCase('TimeSinceSubmission__c')) {
            sortField = 'TimeSinceSubmission_ms__c';
        }
        refresh();
    }

    public Integer getTotalPages() {
        Decimal totalSize = this.con.getResultSize();
        Decimal pageSize = this.con.getPageSize();
        Decimal pages = (pageSize == 0 || pageSize == null) ? 0 : totalSize / pageSize;
        return (Integer) pages.round((RoundingMode) System.RoundingMode.CEILING);
    }

    public List<SelectOption> getLanguages() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(KnowledgeArticleService.ENGLISH, KnowledgeArticleService.ENGLISH));
        options.add(new SelectOption(KnowledgeArticleService.FRENCH, KnowledgeArticleService.FRENCH));
        options.add(new SelectOption(KnowledgeArticleService.GERMAN, KnowledgeArticleService.GERMAN));
        options.add(new SelectOption(KnowledgeArticleService.SPANISH, KnowledgeArticleService.SPANISH));
        return (List<System.SelectOption>) options;
    }

    public void first() {
        this.con.first();
    }

    public void last() {
        this.con.last();
    }

    public void previous() {
        this.con.previous();
    }

    public void next() {
        this.con.next();
    }
}