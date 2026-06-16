public without sharing class NewArticle {

    public static final String EXCEPTION_DUPLICATE = 'DUPLICATE_VALUE';
    public static final String ERROR_TITLE_REQUIRED = 'Please populate Title field';
    public static final String ERROR_TITLE_DUPLICATE = 'Article with the specified title already exists';
    public static final String ERROR_URLNAME_DUPLICATE = 'Article with the specified UrlName already exists';
    public static final String ERROR_URLNAME_INVALID = 'The URL name can include only unicode characters and hyphens, '
        + 'and it can\'t begin or end with a hyphen';
    public static final String ERROR_NO_PERMISSION = 'Only KCS users can create new articles';

    public String errorMessage {get;set;}

    public String title {get;set;}
    public String urlName {get;set;}
    public String summary {get;set;}
    public String issue {get;set;}
    public String details {get;set;}
    public String symptom {get;set;}
    public String question {get;set;}
    public String affectedEnv {get;set;}
    public String status {get;set;}
    public String stepsToReproduce {get;set;}
    public String resolution {get;set;}
    public String cause {get;set;}
    public String categoryField {get;set;}
    public String product {get;set;}
    public String keywords {get;set;}
    public String confidence {get;set;}

    public Boolean isVisibleInPrm {get;set;}
    public Boolean isVisibleInCsp {get;set;}
    public Boolean isVisibleInPkb {get;set;}

    private static final Map<String, String> CATEGORY_GROUP_NAMES = new Map<String, String>{
        'topicCategory' => 'Topic',
        'brandCategory' => 'Brand',
        'serviceCategory' => 'Service',
        'RCProductVersionCategory' => 'RCProductVersion',
        'Security_CategoriesCategory' => 'Security_Categories'
    };

    public Case caseObj {
        get {
            if (caseObj == null) {
                caseObj = (Case) new CaseSelector()
                    .selectCasesForApproval(
                        new List<Object>{new List<Id>{(Id) ApexPages.currentPage().getParameters().get('id')}}
                    )
                    .executeQuery()[0];
            }
            return caseObj;
        }
        private set;
    }
    
    public String language {
        get {
            if(language==null) {
                language='en_US';
            }
            return language;
        }
        set;
    }

    public Integer kcsAccessLevel {
        get {
            return KnowledgeArticleService.currentUserKCSLevel;
        }
        private set;
    }

    public List<SelectOption> categoryFieldSelectOptions {
        get {
            if (categoryFieldSelectOptions == null) {
                categoryFieldSelectOptions = new List<SelectOption>();
                categoryFieldSelectOptions.add(new SelectOption('',''));
                for(Schema.PicklistEntry ple : Knowledge__kav.RC_Knowledge_Article_Category__c.getDescribe().getPicklistValues()) {
                    categoryFieldSelectOptions.add(new SelectOption(ple.getValue(), ple.getLabel()));
                }
            }
            return categoryFieldSelectOptions;
        }
        private set;
    }

    public List<SelectOption> productSelectOptions {
        get {
            if (productSelectOptions == null) {
                productSelectOptions = new List<SelectOption>();
                productSelectOptions.add(new SelectOption('',''));
                for(Schema.PicklistEntry ple : Knowledge__kav.RC_Knowledge_Article_Product__c.getDescribe().getPicklistValues()) {
                    productSelectOptions.add(new SelectOption(ple.getValue(), ple.getLabel()));
                }
            }
            return productSelectOptions;
        }
        private set;
    }

    public List<SelectOption> allowedLanguages {
        get {
            if (allowedLanguages == null) {
                allowedLanguages = new List<SelectOption>();
                Schema.DescribeFieldResult fieldResult = Knowledge__kav.Language.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for (Schema.PicklistEntry pickListVal : ple){
                    if (pickListVal.isActive()) {
                        allowedLanguages.add(new SelectOption(pickListVal.getValue(), pickListVal.getLabel()));
                    }
                }
            }
            return allowedLanguages;
        }
        private set;
    }

    public List<SelectOption> confidenceItems {
        get {
            if (confidenceItems == null) {
                confidenceItems = new List<SelectOption>();
                Schema.DescribeFieldResult fieldResult = Knowledge__kav.RC_Knowledge_Article_Confidence__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for (Schema.PicklistEntry pickListVal : ple){
                    if (pickListVal.isActive()) {
                        confidenceItems.add(new SelectOption(pickListVal.getValue(), pickListVal.getLabel()));
                    }
                }
            }
            return confidenceItems;
        }
        private set;
    }

    public NewArticle(ApexPages.StandardController stdController) {
        if (!KnowledgeArticleService.isCurrentUserKCSRoleAtLeast(KnowledgeArticleService.KCSRole.CANDIDATE)) {
            AquivaHelper.throwAquivaException(ERROR_NO_PERMISSION);
        }
        this.errorMessage = '';
        this.isVisibleInPrm = false;
        this.isVisibleInCsp = false;
        this.isVisibleInPkb = false;
    }

    private Knowledge__kav buildArticle() {

        return (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
            .setFields(
                new Map<Schema.SObjectField, Object>{
                    Knowledge__kav.Title => this.title,
                    Knowledge__kav.UrlName => this.urlName == null
                        ? this.title.escapeHtml4().trim().replace(' ', '_').replaceAll('[^\\w\\s]','').replace('_','-').removeEnd('-')
                        : this.urlName,
                    Knowledge__kav.Summary => this.summary,
                    Knowledge__kav.RC_Knowledge_Article_Details__c => this.details,
                    Knowledge__kav.RC_Knowledge_Article_Issue__c => this.issue,
                    Knowledge__kav.RC_Knowledge_Article_Symptom__c => this.symptom,
                    Knowledge__kav.RC_Knowledge_Article_Question__c => this.question,
                    Knowledge__kav.RC_Knowledge_Article_AffectedEnv__c => this.affectedEnv,
                    Knowledge__kav.RC_Knowledge_Article_Status__c => this.status,
                    Knowledge__kav.RC_Knowledge_Article_STR__c => this.stepsToReproduce,
                    Knowledge__kav.RC_Knowledge_Article_Resolution__c => this.resolution,
                    Knowledge__kav.RC_Knowledge_Article_Cause__c => this.cause,
                    Knowledge__kav.RC_Knowledge_Article_Category__c => this.categoryField,
                    Knowledge__kav.RC_Knowledge_Article_Confidence__c => this.confidence,
                    Knowledge__kav.RC_Knowledge_Article_Product__c => this.product,
                    Knowledge__kav.RC_Knowledge_Article_Key_Words__c => this.keywords,
                    Knowledge__kav.ValidationStatus => KnowledgeArticleService.STATUS_DRAFT,
                    Knowledge__kav.isVisibleInPrm => this.isVisibleInPrm,
                    Knowledge__kav.isVisibleInCsp => this.isVisibleInCsp,
                    Knowledge__kav.isVisibleInPkb => this.isVisibleInPkb,
                    Knowledge__kav.Language => this.language
                }
            )
            .build()
            .getRecord();
    }

    private Id publishArticle(Knowledge__kav article) {

        Map<String, String> categoryMapping = new Map<String, String>();
        for (String categoryName : CATEGORY_GROUP_NAMES.keySet()) {
            String category = System.currentPageReference().getParameters().get(categoryName);
            if (!String.isBlank(category)) {
                categoryMapping.put(CATEGORY_GROUP_NAMES.get(categoryName), category);
            }
        }

        return KnowledgeArticleService.publishNewArticle(
            article,
            categoryMapping,
            (Id) ApexPages.currentPage().getParameters().get('id')
        );
    }

    public PageReference createArticle() {

        this.errorMessage = '';
        try {
            Knowledge__kav article = buildArticle();
            article.ValidationStatus = this.isVisibleInPrm || this.isVisibleInCsp || this.isVisibleInPkb
                ? KnowledgeArticleService.STATUS_EXTERNAL
                : KnowledgeArticleService.STATUS_INTERNAL;
            return new PageReference('/apex/NewArticlePage?id=' + publishArticle(article));
        } catch (Exception ex) {
            this.errorMessage = ex.getMessage();
            if (this.errorMessage.contains(EXCEPTION_DUPLICATE)) {
                this.errorMessage = this.kcsAccessLevel < 3 ? ERROR_TITLE_DUPLICATE : ERROR_URLNAME_DUPLICATE;
            } else if (this.errorMessage.contains(ERROR_URLNAME_INVALID)) {
                this.errorMessage = ERROR_URLNAME_INVALID;
            }
            return null;
        }
    }

    public PageReference createArticleAsDraft() {

        this.errorMessage = '';
        try {
            Knowledge__kav article = buildArticle();
            return new PageReference('/apex/NewArticlePage?id=' + publishArticle(article));
        } catch (Exception ex) {
            this.errorMessage = ex.getMessage();
            if (this.errorMessage.contains(EXCEPTION_DUPLICATE)) {
                this.errorMessage = this.kcsAccessLevel < 3 ? ERROR_TITLE_DUPLICATE : ERROR_URLNAME_DUPLICATE;
            } else if (this.errorMessage.contains(ERROR_URLNAME_INVALID)) {
                this.errorMessage = ERROR_URLNAME_INVALID;
            }
            return null;
        }
    }
}