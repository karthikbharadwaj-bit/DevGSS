@isTest
 class CaseArticlesRestService_Test {

    private static final String API_ONLY_PROFILE_NAME = 'API Only';

    private static final String USER_USERNAME = 'RC_SupportCommunityCaseListTestUser@rc.com';
    private static final String USER_EMAIL = 'useremail@rc.com';
    private static final String USER_FIRST_NAME = 'firstname';
    private static final String USER_LAST_NAME = 'lastname';
    private static final String USER_LANGUAGE = 'en_US';

    private static final String CASE_INFO_SUBJECT = 'test Subject';
    private static final String CASE_CLOSED_STATUS = 'Closed';
    private static final String CASE_INFO_DESCRIPTION = 'test Description';
    private static final String CASE_INFO_SELECTED_PRODUCT = 'test product one';
    private static final String CASE_INFO_SELECTED_PRODUCT2 = 'test product two';
    private static final String CASE_INFO_SELECTED_PRODUCT3 = 'test product three';
    private static final String CASE_INFO_SEVERITY_LEVEL = 'Level 4 - Medium';
    private static final Datetime CASE_INFO_CREATED_DATE = Datetime.newInstanceGmt(2007, 1, 1);

    private static final String EN_LANG = 'en_US';
    private static final String FR_LANG = 'fr';
    private static final String ARTICLE_URL_NAME = 'urlname';
    private static final String ARTICLE_URL_NAME2 = 'urlname2';
    private static final String ARTICLE_TITLE = 'Test_title';
    private static final String ARTICLE_TITLE_FR = 'Test_title_fr';
    private static final String WRONG_ARTICLE_NUMBER = '1111111';

    private static final String ARTICLE_DETAILS = 'testDetails';
    private static final String ARTICLE_ISSUE = 'testIssue';
    private static final String ARTICLE_QUESTION = 'testQuestion';
    private static final String ARTICLE_STR = 'testSTR';
    private static final String ARTICLE_CAUSE = 'testCause';
    private static final String ARTICLE_SYMPTOM = 'testSymptom';
    private static final String ARTICLE_AFFECTED_ENV = 'testAffectedEnv';
    private static final String ARTICLE_STATUS = 'testStatus';
    private static final String ARTICLE_RESOLUTION = 'testResolution';
    private static final String ARTICLE_LANGUAGE = 'en_US';
    private static final String ARTICLE_SUMMARY = 'testSummary';
    private static final String ARTICLE_KEYWORDS = 'test,test_test';

    private static Map<String, String> CATEGORY_SELECTION = new Map<String, String>{
        'Brand' => 'RC_US',
        'RCProductVersion' => 'RC2013'
    };

    private static User apiOnlyTestUser {
        get {
            if (apiOnlyTestUser == null) {
                apiOnlyTestUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{USER_USERNAME}})
                    .selectFields(new List<String>{'ContactId', 'AccountId'})
                    .executeQuery()
                    .get(0);
            }
            return apiOnlyTestUser;
        }
        private set;
    }
    
    @testSetup
    private static void setupData() {
        KCSDataFactory.setup();
        List<String> langs = new List<String>{EN_LANG, FR_LANG};
        List<String> titles = new List<String>{ARTICLE_TITLE, ARTICLE_TITLE_FR};
        List<Knowledge__kav> articles;
        
        System.runAs(KCSDataFactory.admin) {
            articles = (List<Knowledge__kav>) new SObjectBuilder(Knowledge__kav.SObjectType)
                .quantity(1)
                .setFields(
                    new Map<SObjectField, Object>{
                        Knowledge__kav.Title => ValueProviderBuilder.provideList(titles),
                        Knowledge__kav.UrlName => ARTICLE_URL_NAME,
                        Knowledge__kav.Language => ValueProviderBuilder.provideList(langs),
                        Knowledge__kav.Summary => ARTICLE_SUMMARY,
                        Knowledge__kav.RC_Knowledge_Article_Details__c => ARTICLE_DETAILS,
                        Knowledge__kav.RC_Knowledge_Article_Issue__c => ARTICLE_ISSUE,
                        Knowledge__kav.RC_Knowledge_Article_Question__c => ARTICLE_QUESTION,
                        Knowledge__kav.RC_Knowledge_Article_STR__c => ARTICLE_STR,
                        Knowledge__kav.RC_Knowledge_Article_Cause__c => ARTICLE_CAUSE,
                        Knowledge__kav.RC_Knowledge_Article_Symptom__c => ARTICLE_SYMPTOM,
                        Knowledge__kav.RC_Knowledge_Article_AffectedEnv__c => ARTICLE_AFFECTED_ENV,
                        Knowledge__kav.RC_Knowledge_Article_Status__c => ARTICLE_STATUS,
                        Knowledge__kav.RC_Knowledge_Article_Resolution__c => ARTICLE_RESOLUTION,
                        Knowledge__kav.RC_Knowledge_Article_Key_Words__c => ARTICLE_KEYWORDS
                    }
                )
                .create()
                .getRecords();

            //Create other record with diferent urlName
            articles.add((Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
                .quantity(1)
                .setFields(
                    new Map<SObjectField, Object>{
                        Knowledge__kav.Title => ValueProviderBuilder.provideList(titles),
                        Knowledge__kav.UrlName => ARTICLE_URL_NAME2,
                        Knowledge__kav.Language => ValueProviderBuilder.provideList(langs),
                        Knowledge__kav.Summary => ARTICLE_SUMMARY,
                        Knowledge__kav.RC_Knowledge_Article_Details__c => ARTICLE_DETAILS,
                        Knowledge__kav.RC_Knowledge_Article_Issue__c => ARTICLE_ISSUE,
                        Knowledge__kav.RC_Knowledge_Article_Question__c => ARTICLE_QUESTION,
                        Knowledge__kav.RC_Knowledge_Article_STR__c => ARTICLE_STR,
                        Knowledge__kav.RC_Knowledge_Article_Cause__c => ARTICLE_CAUSE,
                        Knowledge__kav.RC_Knowledge_Article_Symptom__c => ARTICLE_SYMPTOM,
                        Knowledge__kav.RC_Knowledge_Article_AffectedEnv__c => ARTICLE_AFFECTED_ENV,
                        Knowledge__kav.RC_Knowledge_Article_Status__c => ARTICLE_STATUS,
                        Knowledge__kav.RC_Knowledge_Article_Resolution__c => ARTICLE_RESOLUTION,
                        Knowledge__kav.RC_Knowledge_Article_Key_Words__c => ARTICLE_KEYWORDS
                    }
                )
                .create()
                .getRecords()[0]);
            
            for (Knowledge__kav insertedArticle : (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticlesById(new List<Object>{new List<String>{articles[0].Id, articles[1].Id}})
                .executeQuery()
            ) {
                insertedArticle.ValidationStatus = KnowledgeArticleService.STATUS_EXTERNAL;
                insertedArticle.IsVisibleInPkb = true;
                KnowledgeArticleService.changeArticleValidationStatus(insertedArticle);
            }

            Knowledge__kav publishedArticle = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArticleById(new List<String>{articles[0].Id})
                .executeQuery()
                .get(0);

            List<Knowledge__DataCategorySelection> category = (List<Knowledge__DataCategorySelection>) new SObjectBuilder(Knowledge__DataCategorySelection.SObjectType)
                .quantity(2)
                .setFields(
                    new Map<Schema.SObjectField, Object>{
                        Knowledge__DataCategorySelection.ParentId => publishedArticle.Id,
                        Knowledge__DataCategorySelection.DataCategoryGroupName => new ValueProvider.ListProvider(new List<String>(CATEGORY_SELECTION.keySet())),
                        Knowledge__DataCategorySelection.DataCategoryName => new ValueProvider.ListProvider(CATEGORY_SELECTION.values())
                    }
                )
                .create()
                .getRecords();
        }

        Profile apiOnlyProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{API_ONLY_PROFILE_NAME})
            .executeQuery()
            .get(0);

        new SObjectBuilder(User.SObjectType).setFields(new Map<SObjectField, Object>{
            User.LastName => USER_LAST_NAME,
            User.FirstName => USER_FIRST_NAME,
            User.CommunityNickname => USER_LAST_NAME,
            User.Email => USER_EMAIL,
            User.Username => USER_USERNAME,
            User.LanguageLocaleKey => USER_LANGUAGE,
            User.ProfileId => apiOnlyProfile.Id
        })
        .create();

        new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1,
                        Case.Subject => CASE_INFO_SUBJECT,
                        Case.Case_Severity__c => CASE_INFO_SEVERITY_LEVEL,
                        Case.Description => CASE_INFO_DESCRIPTION,
                        Case.Status => CASE_CLOSED_STATUS
                        }
            )
            .create();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testGetCaseArticles() {

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/SCApi/v1/caseArticles';
        request.httpMethod = 'GET';
        request.params.put('title', ARTICLE_TITLE);
        request.params.put('lang', EN_LANG);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseArticlesRestService.getRelatedArticles();
            }
        Test.stopTest();

        /*System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseArticlesAPIController.SUCCESS_MESSAGE_ARTICLE));
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(ARTICLE_TITLE));*/
    }

    @isTest
    private static void testGetCaseArticlesMissingParam() {

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseArticles';
        request.httpMethod = 'GET';
        request.params.put('title', ARTICLE_TITLE);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseArticlesRestService.getRelatedArticles();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseArticlesRestService.BAD_REQUEST_ARTICLE));
    }

    @isTest
    private static void testGetCaseArticlesShortTitle() {

        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/caseArticles';
        request.httpMethod = 'GET';
        request.params.put('title', 'a');
        request.params.put('lang', EN_LANG);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            System.runAs(apiOnlyTestUser) {
                CaseArticlesRestService.getRelatedArticles();
            }
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseArticlesRestService.BAD_REQUEST_SHORT_TITLE));
    }
}