public without sharing class ArticleSubmissionsControllerExtension {
    public static final String ASCENDING = 'ASC';
    public static final String DESCENDING = 'DESC';
    public static final String DEFAULT_SORT_FIELD = 'ArticleCreatedDate';
    public static final Integer DEFAULT_PAGE_SIZE = 25;

    public ApexPages.StandardSetController con { get; set; }
    public String filter { get; set; }
    public String lang { get; set; }
    public String sortDir { get; set; }
    public String sortField { get; set; }

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

    public ArticleSubmissionsControllerExtension() {

        if (!KnowledgeArticleService.isCurrentUserKCSRoleAtLeast(KnowledgeArticleService.KCSRole.CANDIDATE)) {
            AquivaHelper.throwAquivaException(Label.KCS_No_permissions_to_access_page);
        }

        this.filter = filter == null ? KnowledgeArticleService.ALL_ACTIVE : filter;
        this.lang = lang == null ? KnowledgeArticleService.ENGLISH : lang;
        this.sortDir = sortDir == null ? ASCENDING : sortDir;
        this.sortField = sortField == null ? DEFAULT_SORT_FIELD : sortField;
        refresh();
        getFilters();
        getLanguages();
        getAllArticles();
    }

    public List<Knowledge__kav> getArticles() {
        return (List<Knowledge__kav>) this.con.getRecords();
    }

    public PageReference getAllArticles() {
        this.filter = filter;
        this.lang = lang;
        this.sortField = sortField;
        this.sortDir = sortDir;
        getArticles();
        return null;
    }

    public void refresh() {
        QueryFactory qf;

        if (filter.equalsIgnoreCase(KnowledgeArticleService.REJECTED)) {
            qf = new KnowledgeArticleSelector().selectArticlesByValidationAndPublishStatuses(
                new List<Object> {
                    KnowledgeArticleService.VALIDATION_STATUSES_BY_FILTER.get(filter),
                    UserInfo.getUserId(),
                    KnowledgeArticleService.LANGUAGES_BY_FILTER.get(lang)
                }, true, true
            );
        } else {
            qf = new KnowledgeArticleSelector().selectArticlesByValidationAndPublishStatuses(
                new List<Object> {
                    KnowledgeArticleService.VALIDATION_STATUSES_BY_FILTER.get(filter),
                    UserInfo.getUserId(),
                    KnowledgeArticleService.LANGUAGES_BY_FILTER.get(lang)
                }, false, true
            );
        }

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

    public List<SelectOption> getFilters() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(KnowledgeArticleService.ALL_ACTIVE, KnowledgeArticleService.ALL_ACTIVE));
        options.add(new SelectOption(KnowledgeArticleService.DRAFTS, KnowledgeArticleService.DRAFTS));
        options.add(new SelectOption(KnowledgeArticleService.PUBLISHED, KnowledgeArticleService.PUBLISHED));
        options.add(new SelectOption(KnowledgeArticleService.REJECTED, KnowledgeArticleService.REJECTED));
        return (List<System.SelectOption>) options;
    }

    public List<SelectOption> getLanguages() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(KnowledgeArticleService.ENGLISH, KnowledgeArticleService.ENGLISH));
        options.add(new SelectOption(KnowledgeArticleService.FRENCH, KnowledgeArticleService.FRENCH));
        options.add(new SelectOption(KnowledgeArticleService.GERMAN, KnowledgeArticleService.GERMAN));
        options.add(new SelectOption(KnowledgeArticleService.SPANISH, KnowledgeArticleService.SPANISH));
        return (List<System.SelectOption>) options;
    }

    public Integer getTotalPages() {
        Decimal totalSize = this.con.getResultSize();
        Decimal pageSize = this.con.getPageSize();
        Decimal pages = (pageSize == 0 || pageSize == null) ? 0 : totalSize / pageSize;
        return (Integer) pages.round((RoundingMode) System.RoundingMode.CEILING);
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