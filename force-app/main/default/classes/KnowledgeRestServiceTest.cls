@isTest
public class KnowledgeRestServiceTest {
    private static final String ADMIN_USER_PROFILE_NAME = 'RC Admin User';
    
    private static final String EN_LANG = 'en_US';
    private static final String ARTICLE_URL_NAME = 'urlname';
    private static final String ARTICLE_URL_NAME2 = 'urlname2';
    private static final String ARTICLE_TITLE = 'Test_title';
    private static final String ARTICLE_TITLE_FR = 'Test_title_fr';
    private static final String WRONG_ARTICLE_NUMBER = '1111111';
    private static final String VALIDATION_STATUS = 'validationStatus';

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
	
    private static final String USER_EMAIL = 'useremail@rc.com';
    private static final String USER_FIRST_NAME = 'firstname';
    private static final String USER_LAST_NAME = 'lastname';

    private static final String CONTACT_FIRST_NAME = USER_FIRST_NAME;
    private static final String CONTACT_LAST_NAME = USER_LAST_NAME;
    private static final String CONTACT_PHONE = '77777777';
    private static final Decimal CONTACT_PHONE_EXT = 777;

    private static final String SUPPORT_COMMUNITY_URL = 'https://test.cs41.com/support';
    private static final String DATA_CATEGORY_NAME_RC_US = 'RC_US';
    private static final String DATA_CATEGORY_NAME_RC_AU = 'RC_AU';
    private static final List<String> titles = new List<String>{ARTICLE_TITLE, ARTICLE_TITLE_FR};
    private static final String iName = [SELECT InstanceName FROM Organization LIMIT 1].InstanceName.toLowerCase();
    private static final String articleDetails = 'Test detail with wrong img url src=\"https://rc--test--c.'+iName+'.content.force.com/servlet/rtaImage?eid=ka2550000004Ocz&amp;feoid=00N550000052JrR&amp;refid=0EM55000000oOyA\">';

    @testSetup
    private static void setupData() {
        KCSDataFactory.setup();
        List<String> langs = new List<String>{EN_LANG};
        List<Knowledge__kav> newVersions;
        List<String> articleNumbers = new List<String>();

        System.runAs(KCSDataFactory.admin) {
            newVersions = (List<Knowledge__kav>) new SObjectBuilder(Knowledge__kav.SObjectType)
                .quantity(1)
                .setFields(
                    new Map<SObjectField, Object>{
                        Knowledge__kav.Title => ValueProviderBuilder.provideList(titles),
                        Knowledge__kav.UrlName => ARTICLE_URL_NAME,
                        Knowledge__kav.Language => ValueProviderBuilder.provideList(langs),
                        Knowledge__kav.Summary => ARTICLE_SUMMARY,
                        Knowledge__kav.RC_Knowledge_Article_Details__c => articleDetails,
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
            newVersions.addAll((List<Knowledge__kav>) new SObjectBuilder(Knowledge__kav.SObjectType)
                .quantity(2)
                .setFields(
                    new Map<SObjectField, Object>{
                        Knowledge__kav.Title => ValueProviderBuilder.provideList(titles),
                        Knowledge__kav.UrlName => ValueProviderBuilder.provideList(new String[]{ARTICLE_URL_NAME2, ARTICLE_URL_NAME2 + 'test'}),
                        Knowledge__kav.Language => ValueProviderBuilder.provideList(langs),
                        Knowledge__kav.Summary => ARTICLE_SUMMARY,
                        Knowledge__kav.RC_Knowledge_Article_Details__c => articleDetails,
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
                .getRecords()
            );

            for (Knowledge__kav insertedArticle : (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticlesById(new List<Object>{new List<String>{newVersions[0].Id, newVersions[1].Id,newVersions[2].Id}})
                .executeQuery()
            ) {
                articleNumbers.add(insertedArticle.articleNumber);
                insertedArticle.ValidationStatus = KnowledgeArticleService.STATUS_EXTERNAL;
                insertedArticle.IsVisibleInPkb = true;
                KnowledgeArticleService.changeArticleValidationStatus(insertedArticle);
            }
        }        
        List<Knowledge__DataCategorySelection> kADCSLst = new List<Knowledge__DataCategorySelection>();
        for (Knowledge__kav kak: newVersions) {
            Knowledge__DataCategorySelection kADCS = new Knowledge__DataCategorySelection();
            kADCS.ParentId = kak.Id;
            kADCS.DataCategoryGroupName = 'Brand';
            kADCS.DataCategoryName = DATA_CATEGORY_NAME_RC_US;
            kADCSLst.add(kADCS);
        }
            
        if (kADCSLst.size() > 0) {
            insert(kADCSLst);
        }

        RingCentralVariousSettings__c setting = new RingCentralVariousSettings__c();
        setting.Support_Community_URL__c = SUPPORT_COMMUNITY_URL;
        insert setting;

        new SObjectBuilder(RC_Article_Rating__c.SObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    RC_Article_Rating__c.Article_Number__c => ValueProviderBuilder.provideList(articleNumbers),
                    RC_Article_Rating__c.PositiveVotesCount__c => 0,
                    RC_Article_Rating__c.NegativeVotesCount__c => 0
                }
            )
            .create();

         List<Account> portalAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'Unted States',
                Account.RC_User_ID__c => '123456789'
            })
            .create()
            .getRecords();

        List<Contact> portalContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_LAST_NAME,
                    Contact.Email => USER_EMAIL,
                    Contact.Phone => CONTACT_PHONE,
                    Contact.Phone_Ext__c => CONTACT_PHONE_EXT,
                    Contact.AccountId => portalAccounts[0].Id
                }
            )
            .create()
            .getRecords();

        List<AccountContactRole> accountCR = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => portalAccounts[0].Id,
                AccountContactRole.ContactId => portalContacts[0].Id,
                AccountContactRole.Role => ADMIN_USER_PROFILE_NAME,
                AccountContactRole.IsPrimary => false
            })
            .create()
            .getRecords();
    }

    @isTest
    private static void restServiceGet(){

        Knowledge__kav articleVersion = [
            SELECT Id, UrlName, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', articleVersion.UrlName);
        request.params.put('language', EN_LANG);
        request.params.put('brand', DATA_CATEGORY_NAME_RC_US);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        String responseString = RestContext.response.responseBody.toString();
        System.assertEquals(true, responseString.contains(VALIDATION_STATUS));
        System.assertEquals(true, responseString.contains('relatedArticles'));
        String fullName = KCSDataFactory.admin.FirstName +' '+KCSDataFactory.admin.LastName.substring(0,1).toUpperCase()+'.';
        System.assertEquals(true, responseString.contains(fullName));
        System.assertEquals(true, responseString.contains(EN_LANG));
    }
    @isTest
    private static void restServiceGet_whenBrandParameterIsIgnore_ItShouldFetchTheArticleCorrectly(){
        Knowledge__kav articleVersion = [
            SELECT Id, UrlName, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', articleVersion.UrlName);
        request.params.put('language', EN_LANG);
        request.params.put('brand', 'IGNORE');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        String responseString = RestContext.response.responseBody.toString();
        System.assertEquals(true, responseString.contains(VALIDATION_STATUS));
        System.assertEquals(true, responseString.contains('relatedArticles'));
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseString);
        System.assertEquals(2, ((List<Object>) response.get('relatedArticles')).size(), 'It must be 2 because only two articles are PublishExternally.');
    }
    @isTest
    private static void restServiceGet_whenBrandParameterIsInvalid_ItShouldThrowAnError(){
        Knowledge__kav articleVersion = [
            SELECT Id, UrlName, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', articleVersion.UrlName);
        request.params.put('language', EN_LANG);
        request.params.put('brand', 'IncorrectParameter');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseAPIUtil.ERROR_MESSAGE_INVALID_BRAND_PARAMETER));
    }
    @isTest
    private static void restServiceGet_whenLanguageParameterIsInvalid_ItShouldThrowAnError(){
        Knowledge__kav articleVersion = [
            SELECT Id, UrlName, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', articleVersion.UrlName);
        request.params.put('language', 'IncorrectParameter');
        request.params.put('brand', 'IGNORE');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseAPIUtil.ERROR_MESSAGE_INVALID_LANGUAGE_PARAMETER));
    }
    @isTest
    private static void restServiceGet_whenUrlNameDoesntExist_ItShouldThrowAnError(){
        Knowledge__kav articleVersion = [
            SELECT Id, UrlName, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', articleVersion.UrlName + 'Invalid');
        request.params.put('language', EN_LANG);
        request.params.put('brand', DATA_CATEGORY_NAME_RC_US);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(KnowledgeArticleAPIController.ARTICLE_NOT_FOUND_ERROR_MESSAGE));
    }
    @isTest
    private static void restServiceGet_whenArticleDoesntBelongToBrand_ItShouldThrowAnError(){
        Knowledge__kav articleVersion = [
            SELECT Id, UrlName, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', articleVersion.UrlName);
        request.params.put('language', EN_LANG);
        request.params.put('brand', DATA_CATEGORY_NAME_RC_AU);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseAPIUtil.ERROR_MESSAGE_ARTICLE_NOT_BELONG_TO_BRAND));
    }
    @isTest
    private static void restServiceGet_whenArticleIsPublishedExternally_ItShouldFetchOnlyPublishedExternallyRelatedArticles(){
        Knowledge__kav kArticle;
        System.runAs(KCSDataFactory.admin) {
            kArticle = (Knowledge__kav) new SObjectBuilder(Knowledge__kav.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Knowledge__kav.Title => ValueProviderBuilder.provideList(titles),
                        Knowledge__kav.UrlName => ARTICLE_URL_NAME2 + 'test2',
                        Knowledge__kav.Language => EN_LANG,
                        Knowledge__kav.Summary => ARTICLE_SUMMARY,
                        Knowledge__kav.RC_Knowledge_Article_Details__c => articleDetails,
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
                .getRecord();
        
            for (Knowledge__kav insertedArticle : (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticlesById(new Object[]{new String[]{kArticle.Id}})
                .executeQuery()
            ) {
                insertedArticle.ValidationStatus = KnowledgeArticleService.STATUS_INTERNAL;
                KnowledgeArticleService.changeArticleValidationStatus(insertedArticle);
            }
        }

        Knowledge__kav articleVersion = [
            SELECT Id, UrlName, ArticleNumber
            FROM Knowledge__kav
            WHERE Id != :kArticle.Id
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', articleVersion.UrlName);
        request.params.put('language', EN_LANG);
        request.params.put('brand', DATA_CATEGORY_NAME_RC_US);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        String responseString = RestContext.response.responseBody.toString();
        System.assertEquals(true, responseString.contains(VALIDATION_STATUS));
        System.assertEquals(true, responseString.contains('relatedArticles'));
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseString);
        System.assertEquals(2, ((List<Object>) response.get('relatedArticles')).size(), 'It must be 2 because only two articles are PublishExternally.');
    }
    @isTest
    private static void restServiceGet_whenSearchMultipleBrands_ItShouldFetchTheArticleCorrectly() {
        Knowledge__kav articleVersion = [
            SELECT Id, UrlName, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', articleVersion.UrlName);
        request.params.put('language', EN_LANG);
        request.params.put('brand', DATA_CATEGORY_NAME_RC_AU + ' , ' + DATA_CATEGORY_NAME_RC_US);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
            KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        String responseString = RestContext.response.responseBody.toString();
        System.assertEquals(true, responseString.contains(VALIDATION_STATUS));
        System.assertEquals(true, responseString.contains('relatedArticles'));
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseString);
        System.assertEquals(2, ((List<Object>) response.get('relatedArticles')).size(), 'It must be 2 because only two articles are PublishExternally.');
    }
	
	@isTest    
    private static void restServiceGetWithContact() {
        Knowledge__kav articleVersion = [
            SELECT Id, UrlName, ArticleNumber
            FROM Knowledge__kav
            WHERE Language = 'en_US'
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', articleVersion.UrlName);
        request.params.put('language', EN_LANG);
        request.params.put('uid', '123456789');
        request.params.put('email', USER_EMAIL);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
        KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        String responseString = RestContext.response.responseBody.toString();
        System.assertEquals(true, responseString.contains(VALIDATION_STATUS));
        String fullName = KCSDataFactory.admin.FirstName +' '+KCSDataFactory.admin.LastName.substring(0,1).toUpperCase()+'.';
        System.assertEquals(true, responseString.contains('relatedArticles'));
        System.assertEquals(true, responseString.contains(fullName));
        System.assertEquals(true, responseString.contains(EN_LANG));
    }

    @isTest
    private static void restServiceGetWithWrongContact() {

         Knowledge__kav articleVersion = [
            SELECT Id, UrlName, ArticleNumber
            FROM Knowledge__kav
            WHERE Language = 'en_US'
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', articleVersion.UrlName);
        request.params.put('language', EN_LANG);
        request.params.put('uid', '145687');
        request.params.put('email', USER_EMAIL);
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
        KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(404, RestContext.response.statusCode);
        String responseString = RestContext.response.responseBody.toString();
        System.assertEquals(true, responseString.contains(CaseAPIUtil.ERROR_MESSAGE_INVALID_USERID_OR_EMAIL));
    }

    @isTest
    private static void testGetArticleRatingStatistics() {
        Knowledge__kav articleVersion = [
            SELECT Id, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        Test.startTest();
        RC_Article_Rating__c articlerating = KnowledgeArticleAPIController.getArticleRatingStatistics(articleVersion.ArticleNumber);
        Test.stopTest();

        System.assertNotEquals(null, articlerating);
    }

    @isTest
    private static void testGetArticleRatingStatisticsWrongNumber() {
        Knowledge__kav articleVersion = [
            SELECT Id, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        Test.startTest();
        RC_Article_Rating__c articlerating = KnowledgeArticleAPIController.getArticleRatingStatistics(WRONG_ARTICLE_NUMBER);
        Test.stopTest();

        System.assertEquals(0, articlerating.NegativeVotesCount__c);
        System.assertEquals(0, articlerating.PositiveVotesCount__c);
    }

    @isTest
    private static void testKnowledgeFeedbackSuccess() {

        Knowledge__kav articleVersion = [
            SELECT Id, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        Map<String, Object> params = new Map<String, Object>();
        params.put('articleNumber', articleVersion.ArticleNumber);
        params.put('comment', 'This is a test comment');
        params.put('rate', '5');
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);

        String body = JSON.serialize(params);

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;

        Test.startTest();
        KnowledgeRestService.setKnowledgeFeedback();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(KnowledgeArticleAPIController.SUCCESS_MESSAGE_POST));
    }

     @isTest
    private static void testKnowledgeFeedbackSuccessWithContact() {

         Knowledge__kav articleVersion = [
            SELECT Id, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        Map<String, Object> params = new Map<String, Object>();
        params.put('articleNumber', articleVersion.ArticleNumber);
        params.put('comment', 'This is a test comment');
        params.put('rate', '2');
        params.put('uid', '123456789');
        params.put('email', USER_EMAIL);

        String body = JSON.serialize(params);

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;

        Test.startTest();
        KnowledgeRestService.setKnowledgeFeedback();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(KnowledgeArticleAPIController.SUCCESS_MESSAGE_POST));
        System.assertEquals(3, [SELECT COUNT() FROM RC_Article_Rating__c]);
    }

    @isTest
    private static void testKnowledgeFeedbackSuccessWithoutCreds() {

          Knowledge__kav articleVersion = [
            SELECT Id, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        Map<String, Object> params = new Map<String, Object>();
        params.put('articleNumber', articleVersion.ArticleNumber);
        params.put('comment', 'This is a test comment');
        params.put('rate', '2');

        String body = JSON.serialize(params);

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;

        Test.startTest();
        KnowledgeRestService.setKnowledgeFeedback();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(KnowledgeArticleAPIController.SUCCESS_MESSAGE_POST));
    }

    @isTest
    private static void testKnowledgeFeedbackErrorWithContact() {

          Knowledge__kav articleVersion = [
            SELECT Id, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        Map<String, Object> params = new Map<String, Object>();
        params.put('articleNumber', articleVersion.ArticleNumber);
        params.put('comment', 'This is a test comment');
        params.put('rate', '5');
        params.put('uid', '123');
        params.put('email', USER_EMAIL);

        String body = JSON.serialize(params);

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;

        Test.startTest();
        KnowledgeRestService.setKnowledgeFeedback();
        Test.stopTest();
        System.assertEquals(404, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(CaseAPIUtil.ERROR_MESSAGE_INVALID_USERID_OR_EMAIL));
    }

    @isTest
    private static void testKnowledgeFeedbackIncompleteRequest() {

        Knowledge__kav articleVersion = [
            SELECT Id, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> incompleteParams = new Map<String, Object>();
        incompleteParams.put('comm', 'This is a test comment');
        incompleteParams.put('rate', '5');
        incompleteParams.put('uid', UserInfo.getUserId());

        String incompleteBody = JSON.serialize(incompleteParams);
        RestContext.request.requestBody = Blob.valueOf(incompleteBody);

        Test.startTest();
        KnowledgeRestService.setKnowledgeFeedback();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(KnowledgeRestService.BAD_REQUEST_POST));
    }

    @isTest
    private static void testKnowledgeFeedbackWrongParams() {

        Knowledge__kav articleVersion = [
            SELECT Id, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> wrongParams = new Map<String, Object>();
        wrongParams.put('articleNumber', articleVersion.ArticleNumber);
        wrongParams.put('comm', 'This is a test comment');
        wrongParams.put('rate', 'Wrong value');
        wrongParams.put('uid', UserInfo.getUserId());

        String wrongBody = JSON.serialize(wrongParams);

        RestContext.request.requestBody = Blob.valueOf(wrongBody);
        Test.startTest();
        KnowledgeRestService.setKnowledgeFeedback();
        Test.stopTest();
        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains(KnowledgeRestService.BAD_REQUEST_RATE_PARAM_POST));

    }

    @isTest
    private static void testKnowledgeFeedbackWrongUserIdAndEmail() {

        Knowledge__kav articleVersion = [
            SELECT Id, ArticleNumber
            FROM Knowledge__kav
            LIMIT 1
        ];

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Map<String, Object> wrongParams = new Map<String, Object>();
        wrongParams.put('articleNumber', articleVersion.ArticleNumber);
        wrongParams.put('comment', 'This is a test comment');
        wrongParams.put('rate', '5');
        wrongParams.put('uid', '123');
        wrongParams.put('email', 'test@test.com');

        String wrongBody = JSON.serialize(wrongParams);

        RestContext.request.requestBody = Blob.valueOf(wrongBody);
        Test.startTest();
        KnowledgeRestService.setKnowledgeFeedback();
        Test.stopTest();
        System.assertEquals(404, RestContext.response.statusCode);
        String stringResponseBody = RestContext.response.responseBody.toString();
        System.assertEquals(true, stringResponseBody.contains(CaseAPIUtil.ERROR_MESSAGE_INVALID_USERID_OR_EMAIL));

    }

	@isTest    
    private static void restServiceGet_whenSearchTranslatedArticle_ItShouldResponseTranslatedArticle() {
        List<Knowledge__kav> newVersions;
        System.runAs(KCSDataFactory.admin) {
            newVersions = (List<Knowledge__kav>) new SObjectBuilder(Knowledge__kav.SObjectType)
                .quantity(1)
                .setFields(
                    new Map<SObjectField, Object>{
                        Knowledge__kav.Title => ValueProviderBuilder.provideList(titles),
                        Knowledge__kav.UrlName => ARTICLE_URL_NAME,
                        Knowledge__kav.Language => ValueProviderBuilder.provideList(new String[]{'es'}),
                        Knowledge__kav.Summary => ARTICLE_SUMMARY,
                        Knowledge__kav.RC_Knowledge_Article_Details__c => articleDetails,
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

            for (Knowledge__kav insertedArticle : (List<Knowledge__kav>) new KnowledgeArticleSelector()
                .selectArticlesById(new List<Object>{new List<String>{newVersions[0].Id}})
                .executeQuery()
            ) {
                insertedArticle.ValidationStatus = KnowledgeArticleService.STATUS_EXTERNAL;
                insertedArticle.IsVisibleInPkb = true;
                KnowledgeArticleService.changeArticleValidationStatus(insertedArticle);
            }
        }

        new SObjectBuilder(RC_Article_Rating__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    RC_Article_Rating__c.Article_Number__c => newVersions[0].articleNumber,
                    RC_Article_Rating__c.PositiveVotesCount__c => 0,
                    RC_Article_Rating__c.NegativeVotesCount__c => 0
                }
            )
            .create();

        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', newVersions[0].UrlName);
        request.params.put('language', 'es');
        request.params.put('brand', 'IGNORE');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
        KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        String responseString = RestContext.response.responseBody.toString();
        System.assertEquals(true, responseString.contains(VALIDATION_STATUS),'It doesnt include: ' + VALIDATION_STATUS);
        String fullName = KCSDataFactory.admin.FirstName +' '+KCSDataFactory.admin.LastName.substring(0,1).toUpperCase()+'.';
        System.assertEquals(true, responseString.contains(fullName));
        System.assertEquals(true, responseString.contains('es'));
    }

	@isTest    
    private static void restServiceGet_whenSearchTranslatedArticleButArticleIsNotTranslated_ItShouldResponseTheDefaultLanguageForThatArticle() {

        Knowledge__kav articleVersion = [
            SELECT Id, UrlName
            FROM Knowledge__kav
            LIMIT 1
        ];
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = URL.getOrgDomainUrl().toExternalForm() +'/services/apexrest/SCApi/v1/knowledgeRestService';
        request.httpMethod = 'GET';
        request.params.put('urlName', articleVersion.UrlName);
        request.params.put('language', 'es');
        request.params.put('brand', 'IGNORE');
        RestContext.request = request;
        // Call the method to test
        Test.startTest();
        KnowledgeRestService.getKnowledgeInfo();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        String responseString = RestContext.response.responseBody.toString();
        System.assertEquals(true, responseString.contains(VALIDATION_STATUS),'It doesnt include: ' + VALIDATION_STATUS);
        String fullName = KCSDataFactory.admin.FirstName +' '+KCSDataFactory.admin.LastName.substring(0,1).toUpperCase()+'.';
        System.assertEquals(true, responseString.contains(fullName));
        System.assertEquals(true, responseString.contains(KnowledgeArticleService.LANGUAGE_DEFAULT));
    }
}