public without sharing class SupportCommunityNewCase {

    public static final String CASE_APINAME = 'Case';
    public static final String ASSISTANCE_FIELD_NAME_1 = 'Product_Assistance__c';
    public static final String ASSISTANCE_FIELD_NAME_2 = 'Product_Assistance_Lvl2__c';
    public static final String ASSISTANCE_FIELD_NAME_3 = 'Product_Assistance_Lvl3__c';

    public static final String LABEL_AREA_OPTIONS = 'areaOptions';
    public static final String LABEL_ARTICLES = 'articles';
    public static final String LABEL_CONTACT_INFO = 'contactInfo';
    public static final String LABEL_CONTACT_ID = 'contactId';
    public static final String LABEL_CREATED_CASE_ID = 'createdCaseId';

    public static final Integer SEARCH_OUTPUT_LIMIT = 50;

    public static final Map<String, Map<String, String>> ARTICLE_CATEGORY_MAPPING = new Map<String, Map<String, String>> {
        'en_US' => new Map<String, String> {
            'Brand' => 'RC_US',
            'RCProductVersion' => 'RC2013'
        },
        'en_GB' => new Map<String, String> {
            'Brand' => 'RC_UK',
            'RCProductVersion' => 'RCUK2013'
        }
    };

    @AuraEnabled(cacheable=true)
    public static String getUrl() {
        return Site.getBaseUrl();
    }

    @AuraEnabled(cacheable=true)
    public static Response getContactInfo() {

        Response res = new Response();
        res.setData(LABEL_CONTACT_INFO, new SCWrappers.ContactInfo(SCUserService.currentUser));
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static Response getAreaPicklistOptions() {

        Response res = new Response();
        try {
            List<SCWrappers.AreaOption> options = retrieveCaseAreaPicklistHierarchy();
            res.setData(LABEL_AREA_OPTIONS, options);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static Response searchArticles(String request) {

        Response res = new Response();
        try {
            SCWrappers.ArticleSearchRequest searchRequest = 
                (SCWrappers.ArticleSearchRequest) JSON.deserialize(request, SCWrappers.ArticleSearchRequest.class);
            List<SCWrappers.Article> articles = searchCaseRelatedArticles(searchRequest);
            res.setData(LABEL_ARTICLES, articles);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static Response createCase(String request) {

        Response res = new Response();
        try {
            SCWrappers.CreateCaseRequest createCaseRequest = (SCWrappers.CreateCaseRequest) JSON.deserialize(request, SCWrappers.CreateCaseRequest.class);
            res.setData(LABEL_CREATED_CASE_ID, buildAndInsertCase(createCaseRequest));
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static Response getContactId(String request) {

        Response res = new Response();
        try {
            SCWrappers.ContactInfo contactInfo = (SCWrappers.ContactInfo) JSON.deserialize(request, SCWrappers.ContactInfo.class);
            res.setData(LABEL_CONTACT_ID, contactInfo.upsertContact());
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    private static List<SCWrappers.AreaOption> retrieveCaseAreaPicklistHierarchy() {

        List<SCWrappers.AreaOption> result = new List<SCWrappers.AreaOption>();

        Map<String, Schema.PicklistEntry> optionsLvl1 = 
            SFDescribeHelper.getOptionsMap(CASE_APINAME, ASSISTANCE_FIELD_NAME_1);
        Map<String, Schema.PicklistEntry> optionsLvl2 = 
            SFDescribeHelper.getOptionsMap(CASE_APINAME, ASSISTANCE_FIELD_NAME_2);
        Map<String, Schema.PicklistEntry> optionsLvl3 = 
            SFDescribeHelper.getOptionsMap(CASE_APINAME, ASSISTANCE_FIELD_NAME_3);

        Map<String,List<String>> dependenciesLvl2 = SFDescribeHelper.getDependentOptions(
            CASE_APINAME,
            ASSISTANCE_FIELD_NAME_1,
            ASSISTANCE_FIELD_NAME_2
        );
        Map<String,List<String>> dependenciesLvl3 = SFDescribeHelper.getDependentOptions(
            CASE_APINAME,
            ASSISTANCE_FIELD_NAME_2,
            ASSISTANCE_FIELD_NAME_3
        );

        List<String> optionList = new List<String>();
        List<PicklistController.Picklist> optionsWrapper = SFDescribeHelper.getPicklistOptions(
            'Case',
            'Support-Case',
            ASSISTANCE_FIELD_NAME_1
        );
        for (PicklistController.Option option : optionsWrapper[0].Options) {
            if (option.Label != '--None--') {
                optionList.add(option.Label);
            }
        }

        for (String optionLabelLvl1 : optionList) {
            SCWrappers.AreaOption optionLvl1 = new SCWrappers.AreaOption(optionsLvl1.get(optionLabelLvl1));
            for (String optionLabelLvl2 : dependenciesLvl2.get(optionLabelLvl1)) {
                SCWrappers.AreaOption optionLvl2 = new SCWrappers.AreaOption(optionsLvl2.get(optionLabelLvl2));
                for (String optionLabelLvl3 : dependenciesLvl3.get(optionLabelLvl2)) {
                    optionLvl2.addSubOption(optionsLvl3.get(optionLabelLvl3));
                }
                optionLvl1.addSubOption(optionLvl2);
            }
            result.add(optionLvl1);
        }
        return result;
    }

    private static List<SCWrappers.Article> searchCaseRelatedArticles(
            SCWrappers.ArticleSearchRequest articleSearchRequest) {

        List<SCWrappers.Article> result = new List<SCWrappers.Article>();

        if (articleSearchRequest.langCode != null 
                && !ARTICLE_CATEGORY_MAPPING.containsKey(articleSearchRequest.langCode)) {
            return result;
        }
        result = KnowledgeArticleService.searchArticlesByTitleOrKeyword(
            articleSearchRequest.titlePart,
            articleSearchRequest.langCode,
            ARTICLE_CATEGORY_MAPPING.get(articleSearchRequest.langCode),
            SEARCH_OUTPUT_LIMIT
        );

        return result;
    }

    private static String buildAndInsertCase(SCWrappers.CreateCaseRequest createCaseRequest) {

        if (String.isBlank(createCaseRequest.caseInfo) || createCaseRequest.ContactId == null) {
            AquivaHelper.throwAquivaException('Invalid request');
        }
        SCWrappers.CaseInfo caseInfoUnwrapped;
        if (createCaseRequest.isGdpr == true) {
            caseInfoUnwrapped = (SCWrappers.GdprInfo) JSON.deserialize(createCaseRequest.caseInfo, SCWrappers.GdprInfo.class);
        } else {
            caseInfoUnwrapped = (SCWrappers.CaseInfo) JSON.deserialize(createCaseRequest.caseInfo, SCWrappers.CaseInfo.class);
        }

        Case caseObj = new Case();
        createCaseRequest.populateCaseContactInfo(caseObj);
        caseInfoUnwrapped.populateCaseInfo(caseObj);
        caseObj = HelperCaseDispatch.assignQueue(caseObj, SCUserService.currentUser);
        insert caseObj;

        return String.valueOf(caseObj.Id);
    }
}