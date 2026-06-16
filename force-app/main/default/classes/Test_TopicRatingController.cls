@isTest
private class Test_TopicRatingController {
    private static final String DRAFT_TITLE_PREFIX = KnowledgeArticleService.DRAFT_PREFIX;
    
    private static final String COMMUNITY_NAME = 'RingCentral Support';
    private static final String BLANK_STR = '';

    private static final String ARTICLE_TITLE = 'Test_title';

    private static final String DOMAIN = 'https://test.ringcentral.com/lc/cms/ES_Recursos';
    private static final Integer LIST_SIZE = 20;

    private static final String ARTICLE_TITLE_1 = 'First Article';
    private static final String ARTICLE_TITLE_2 = 'Second Article';
    private static final String ARTICLE_TITLE_3 = 'Third Article';

    private static final String ARTICLE_URLNAME_1 = 'testUrl-One';
    private static final String ARTICLE_URLNAME_2 = 'testUrl-Two';

    private static final String MAIN_LANGUAGE = 'en_US';
    private static final String SECONDARY_LANGUAGE = 'es';

    private static final String TOPIC_NAME_COVEO_FIRST = 'Topic_1';
    private static final String TOPIC_NAME_COVEO_SECOND = 'Topic_2';
    private static final String TOPIC_NAME_FIXED_THIRD = 'Topic_3';
    private static final String TOPIC_NAME_FIXED_THIRD_ALT_LANG = 'Topic_4';

    private static final String PART_OF_ADMIN_URL_BUILDER =
        'https://{0}/sfsites/picasso/core/config/commeditor.jsp' + '?siteId=';
    private static final String PART_OF_ADMIN_URL_IMAGES = '/o';

    @TestSetup
    static void setup() {

        KCSDataFactory.setup();
        new SObjectBuilder(Topic.SObjectType)
            .setField(Topic.Name, 'TestTop')
            .setField(Topic.NetworkId, [SELECT Id FROM Network WHERE Name = :COMMUNITY_NAME LIMIT 1].Id)
            .create();

        new SObjectBuilder(SupportCommunityLanguages__c.SObjectType)
            .setField(SupportCommunityLanguages__c.Name, ValueProviderBuilder.provideList(new List<String>{'EN', 'ES'}))
            .setField(
            SupportCommunityLanguages__c.Language__c,
            ValueProviderBuilder.provideList(new List<String>{'en', 'es'})
        )
            .setField(
            SupportCommunityLanguages__c.Country__c,
            ValueProviderBuilder.provideList(new List<String>{MAIN_LANGUAGE, SECONDARY_LANGUAGE})
        )
            .setField(SupportCommunityLanguages__c.TopicListSize__c, LIST_SIZE)
            .setField(SupportCommunityLanguages__c.Domain__c, DOMAIN)
            .setField(SupportCommunityLanguages__c.isCommunity__c, true)
            .setField(SupportCommunityLanguages__c.Position__c, ValueProviderBuilder.provideUniqueNumber(1))
            .quantity(2)
            .create();

        List<Id> articleIds;
        System.runAs(KCSDataFactory.expert) {
            List<Knowledge__kav> articleList = (List<Knowledge__kav>) new SObjectBuilder(
                Knowledge__kav.SObjectType
            )
                .setField(
                    Knowledge__kav.Title,
                    ValueProviderBuilder.provideList(new List<String>{ARTICLE_TITLE_1, ARTICLE_TITLE_2, ARTICLE_TITLE_3})
                )
                .setField(
                    Knowledge__kav.UrlName,
                    ValueProviderBuilder.provideList(
                        new List<String>{ARTICLE_URLNAME_1, ARTICLE_URLNAME_2, ARTICLE_URLNAME_1}
                    )
                )
                .setField(
                    Knowledge__kav.Language,
                    ValueProviderBuilder.provideList(new List<String>{MAIN_LANGUAGE, MAIN_LANGUAGE, SECONDARY_LANGUAGE})
                )
                .quantity(3)
                .create()
                .getRecords();

            Set<Id> articleVersionIds = new Map<Id, Knowledge__kav>(articleList).keySet();
            articleIds = new List<Id>();
            for (Knowledge__kav article : [
                SELECT Id, Title, UrlName, Language, PublishStatus, RC_Knowledge_Article_Details__c, Summary, RC_Knowledge_Article_Key_Words__c,
                    ArticleTotalViewCount, ArticleNumber, KnowledgeArticleId
                FROM Knowledge__kav
                WHERE Id IN :articleVersionIds
            ]) {
                articleIds.add(article.KnowledgeArticleId);
                KbManagement.PublishingService.publishArticle(article.KnowledgeArticleId, true);
            }

        }
        List<SupportCommunityTopicRating__c> lis = new SObjectBuilder(SupportCommunityTopicRating__c.SObjectType)
            .setField(
                SupportCommunityTopicRating__c.Position__c,
                ValueProviderBuilder.provideList(new List<Decimal>{1, 2, 3, 3})
            )
            .setField(SupportCommunityTopicRating__c.TopicId__c, ValueProviderBuilder.provideList(articleIds))
            .setField(
                SupportCommunityTopicRating__c.Active__c,
                ValueProviderBuilder.provideList(new List<Boolean>{false, false, true, true})
            )
            .setField(SupportCommunityTopicRating__c.Place__c, 'Trending')
            .setField(
                SupportCommunityTopicRating__c.Language__c,
                ValueProviderBuilder.provideList(
                    new List<String>{MAIN_LANGUAGE, MAIN_LANGUAGE, MAIN_LANGUAGE, SECONDARY_LANGUAGE}
                )
            )
            .setField(
                SupportCommunityTopicRating__c.Url__c,
                ValueProviderBuilder.provideList(
                    new List<String>{ARTICLE_URLNAME_1, ARTICLE_URLNAME_2, ARTICLE_URLNAME_1, ARTICLE_URLNAME_1}
                )
            )
            .setField(
                SupportCommunityTopicRating__c.Name,
                ValueProviderBuilder.provideList(
                    new List<String>{
                        TOPIC_NAME_COVEO_FIRST,
                        TOPIC_NAME_COVEO_SECOND,
                        TOPIC_NAME_FIXED_THIRD,
                        TOPIC_NAME_FIXED_THIRD_ALT_LANG
                    }
                )
            )
            .setField(
                SupportCommunityTopicRating__c.FullTitle__c,
                ValueProviderBuilder.provideList(
                    new List<String>{
                        TOPIC_NAME_COVEO_FIRST,
                        TOPIC_NAME_COVEO_SECOND,
                        TOPIC_NAME_FIXED_THIRD,
                        TOPIC_NAME_FIXED_THIRD_ALT_LANG
                    }
                )
            )
            .quantity(4)
            .create()
            .getRecords();
    }

    @isTest
    private static void testGetAdminLinks() {
        Test.startTest();

        Response response = TopicRatingController.getAdminLinks();

        Test.stopTest();

        System.assert(response != null, 'Empty response');
        System.assert(!response.data.isEmpty(), 'No data returned for valid request');
        System.assert(response.messages.isEmpty(), 'message returned for invalid request');
        List<Object> diffs = (List<Object>) response.data.get('links');
        String domain = URL.getOrgDomainUrl().getHost();
        System.assertNotEquals(diffs, null, 'Incorrect assignment of admin links.');
        System.assertEquals(diffs.size(), 2, 'Images admin links was not populated.');
        List<Map<String, Object>> links = new List<Map<String, Object>>();
        for (Object link : diffs) {
            links.add((Map<String, Object>) link);
        }
        System.assertEquals(
            (String) links[1].get('Title'),
            TopicRatingController.TITLES[1],
            'Title of admin link is invalid'
        );
        System.assertEquals(
            (String) links[1].get('Icon'),
            TopicRatingController.ICONS[1],
            'Icon of admin link is invalid'
        );
        System.assertEquals(
            (String) links[1].get('Description'),
            TopicRatingController.DESCRIPTIONS[1],
            'Description of admin link is invalid'
        );
        List<String> urls = new List<String>();
        for (Map<String, Object> link : links) {
            urls.add((String) link.get('Link'));
        }
        System.assert(
            urls[0].contains(String.format(PART_OF_ADMIN_URL_BUILDER, new List<String>{domain})),
            'Builder url is invalid'
        );
        System.assert(urls[1].contains(PART_OF_ADMIN_URL_IMAGES), 'Images url is invalid');
    }

    @isTest
    private static void testGetFixedTrendingTopics_pos() {
        Test.startTest();

        List<TopicRatingController.Topic> response = TopicRatingController.getFixedTrendingTopics(5, MAIN_LANGUAGE);

        Test.stopTest();

        System.assert(!response.isEmpty(), 'No Fixed Ratings received');
        System.assertEquals(1, response.size(), 'Fixed Ratings count does not match');
        System.assertEquals(response[0].name, TOPIC_NAME_FIXED_THIRD, 'Topic name does not match');
        System.assertEquals(response[0].langCode, MAIN_LANGUAGE, 'Language does not match');
        System.assertEquals(response[0].position, 3, 'Topic position does not match');
    }

    @isTest
    private static void testGetFixedTrendingTopics_pos_altLang() {
        Test.startTest();

        List<TopicRatingController.Topic> responseAltLang = TopicRatingController.getFixedTrendingTopics(
            5,
            SECONDARY_LANGUAGE
        );

        Test.stopTest();

        System.assert(!responseAltLang.isEmpty(), 'No Fixed Ratings received');
        System.assertEquals(1, responseAltLang.size(), 'Fixed Ratings count does not match');
        System.assertEquals(responseAltLang[0].name, TOPIC_NAME_FIXED_THIRD_ALT_LANG, 'Topic name does not match');
        System.assertEquals(responseAltLang[0].langCode, SECONDARY_LANGUAGE, 'Language does not match');
        System.assertEquals(responseAltLang[0].position, 3, 'Topic position does not match');
    }

    @isTest
    private static void testGetFixedTrendingTopics_pos_narrowListSize() {
        Test.startTest();

        List<TopicRatingController.Topic> responseEmpty = TopicRatingController.getFixedTrendingTopics(
            2,
            MAIN_LANGUAGE
        );

        Test.stopTest();

        System.assert(responseEmpty.isEmpty(), 'Fixed Ratings received when the existing ones are beyond list size');
    }

    @isTest
    private static void testGetCoveoTrendingTopics_pos() {
        Test.startTest();

        List<TopicRatingController.Topic> response = TopicRatingController.getCoveoTrendingTopics(MAIN_LANGUAGE);

        Test.stopTest();

        System.assert(!response.isEmpty(), 'No Coveo Ratings received');
        System.assertEquals(2, response.size(), 'Coveo Ratings count does not match');
        System.assertEquals(response[0].name, TOPIC_NAME_COVEO_FIRST, 'Topic name does not match');
        System.assertEquals(response[0].langCode, MAIN_LANGUAGE, 'Language does not match');
        System.assertEquals(response[0].position, 1, 'Topic position does not match');
        System.assertEquals(response[1].name, TOPIC_NAME_COVEO_SECOND, 'Topic name does not match');
        System.assertEquals(response[1].langCode, MAIN_LANGUAGE, 'Language does not match');
        System.assertEquals(response[1].position, 2, 'Topic position does not match');
    }

    @isTest
    private static void testGetCoveoTrendingTopics_pos_altLang() {
        Test.startTest();

        List<TopicRatingController.Topic> responseAltLang = TopicRatingController.getCoveoTrendingTopics(
            SECONDARY_LANGUAGE
        );

        Test.stopTest();

        System.assert(responseAltLang.isEmpty(), 'Coveo Ratings received when there is no topics for given language');
    }

    @isTest
    private static void testGetTopicData_pos() {
        Test.startTest();

        Response response = TopicRatingController.getTopicData(MAIN_LANGUAGE, null);

        Test.stopTest();

        System.assert(response != null, 'Empty response');
        System.assert(!response.data.isEmpty(), 'No data returned for valid request');
        System.assertEquals(
            (Integer) response.data.get(TopicRatingController.LABEL_LIST_SIZE),
            LIST_SIZE,
            'Returned invalid list size from custom settings'
        );
        System.assertEquals(
            (String) response.data.get(TopicRatingController.LABEL_DOMAIN),
            DOMAIN,
            'Returned invalid domain from custom settings'
        );
        List<TopicRatingController.Topic> topics = (List<TopicRatingController.Topic>) response.data.get(
            TopicRatingController.LABEL_FIXED_TOPICS
        );

        System.assertEquals(topics[0].name, TOPIC_NAME_FIXED_THIRD, 'Topic name does not match');
        System.assertEquals(topics[0].langCode, MAIN_LANGUAGE, 'Language does not match');
        System.assertEquals(topics[0].position, 3, 'Topic position does not match');
    }

    @isTest
    private static void testGetTopicData_neg_invalidLanguage() {
        Test.startTest();

        Response response = TopicRatingController.getTopicData('el', null);

        Test.stopTest();

        System.assert(response != null, 'Empty response');
        System.assert(response.data.isEmpty(), 'Data returned for invalid request');
        System.assert(!response.messages.isEmpty(), 'No message returned for invalid request');
        System.assert(response.messages[0].message.contains('Unsupported language code'), 'Wrong error message');
    }

    @isTest
    private static void testGetTopicData_neg_noDefaultDomain() {
        SupportCommunityLanguages__c languageSetting = [
            SELECT Id, Country__c
            FROM SupportCommunityLanguages__c
            WHERE Country__c = :MAIN_LANGUAGE
        ];
        languageSetting.Country__c = 'SK';
        update languageSetting;

        Test.startTest();

        Response response = TopicRatingController.getTopicData(SECONDARY_LANGUAGE, null);

        Test.stopTest();

        System.assert(response != null, 'Empty response');
        System.assert(response.data.isEmpty(), 'Data returned for invalid request');
        System.assert(!response.messages.isEmpty(), 'No message returned for invalid request');
        System.assert(
            response.messages[0].message.contains('Could not found domain for default country'),
            'Wrong error message'
        );
    }

    @isTest
    private static void testSaveTopicData_pos() {
        List<Knowledge__kav> articles = (List<Knowledge__kav>) Database.query(
            'SELECT Id, UrlName, ArticleNumber, KnowledgeArticleId, Title, Language' +
                ' FROM Knowledge__kav WHERE Language = :MAIN_LANGUAGE' +
                ' AND PublishStatus = \'Online\''
        );

        final String newTopicName = 'newTopic';
        final String newUrl = 'newTopicUrl';

        TopicRatingController.Topic newTopic = new TopicRatingController.Topic(
            (SupportCommunityTopicRating__c) new SObjectBuilder(SupportCommunityTopicRating__c.SObjectType)
                .setField(SupportCommunityTopicRating__c.TopicId__c, articles[0].KnowledgeArticleId)
                .setField(SupportCommunityTopicRating__c.Name, newTopicName)
                .setField(SupportCommunityTopicRating__c.FullTitle__c, newTopicName)
                .setField(SupportCommunityTopicRating__c.Language__c, MAIN_LANGUAGE)
                .setField(SupportCommunityTopicRating__c.Position__c, 10)
                .setField(SupportCommunityTopicRating__c.Url__c, newUrl)
                .build()
                .getRecord()
        );

        List<TopicRatingController.Topic> newTopics = new List<TopicRatingController.Topic>();
        newTopics.add(newTopic);

        TopicRatingController.TopicBundle bundle = new TopicRatingController.TopicBundle();
        bundle.langCode = MAIN_LANGUAGE;
        bundle.listSize = 19;
        bundle.topics = newTopics;

        Test.startTest();

        Response res = TopicRatingController.saveTopicData(JSON.serialize(bundle));

        Test.stopTest();

        System.assert(res != null, 'Empty response');
        System.assertEquals(res.status, Response.STATUS_SUCCESS, 'Error returned for valid request');
    }

    @isTest
    private static void testSaveTopicData_neg() {

        List<Knowledge__kav> articles = (List<Knowledge__kav>)
            Database.query('SELECT Id, UrlName, ArticleNumber, KnowledgeArticleId, Title, Language'
                + ' FROM Knowledge__kav WHERE Language = :MAIN_LANGUAGE'
                + ' AND PublishStatus = \'Online\'');

        final String newTopicName = 'newTopic';
        final String newUrl = 'newTopicUrl';

        TopicRatingController.Topic newTopic = new TopicRatingController.Topic(
            (SupportCommunityTopicRating__c) new SObjectBuilder(SupportCommunityTopicRating__c.SObjectType)
                .setField(SupportCommunityTopicRating__c.TopicId__c, articles[0].KnowledgeArticleId)
                .setField(SupportCommunityTopicRating__c.Name, newTopicName)
                .setField(SupportCommunityTopicRating__c.FullTitle__c, newTopicName)
                .setField(SupportCommunityTopicRating__c.Language__c, MAIN_LANGUAGE)
                .setField(SupportCommunityTopicRating__c.Position__c, 10)
                .setField(SupportCommunityTopicRating__c.Url__c, newUrl)
                .build()
                .getRecord()
        );

        List<TopicRatingController.Topic> newTopics = new List<TopicRatingController.Topic>();
        newTopics.add(newTopic);

        TopicRatingController.TopicBundle bundle = new TopicRatingController.TopicBundle();
        bundle.langCode = MAIN_LANGUAGE;
        bundle.listSize = 6;
        bundle.topics = newTopics;

        Test.startTest();

        Response res = TopicRatingController.saveTopicData(JSON.serialize(bundle));

        Test.stopTest();

        System.assert(res != null, 'Empty response');
        System.assert(res.data.isEmpty(), 'Data returned for invalid request');
        System.assert(!res.messages.isEmpty(), 'No message returned for invalid request');
        System.assert(
            res.messages[0].message.contains('Position (10) greater than list size (6)'),
            'Wrong error message'
        );
    }

    @isTest
    private static void testSearchTopicsByTitle_titlePart() {
        TopicRatingController.TopicSearchRequest req = new TopicRatingController.TopicSearchRequest();
        req.titlePart = ARTICLE_TITLE_1.left(6);
        req.langCode = MAIN_LANGUAGE;
        Test.startTest();

        Response res = TopicRatingController.searchTopicsByTitle(JSON.serialize(req));

        Test.stopTest();

        System.assert(res != null, 'Empty response');
        System.assertEquals(res.status, Response.STATUS_SUCCESS, 'Error returned for valid request');
        List<TopicRatingController.Topic> foundTopics = (List<TopicRatingController.Topic>) res.data.get(
            TopicRatingController.LABEL_TOPICS
        );
        System.assert(!foundTopics.isEmpty(), 'Search found nothing');
        /*System.assertEquals(foundTopics[0].name, ARTICLE_TITLE_1, 'Topic name does not match');
        System.assertEquals(foundTopics[0].langCode, MAIN_LANGUAGE, 'Language does not match');
        System.assertEquals(foundTopics[0].position, null, 'Topic position should be null for found topics');*/
    }

    @isTest
    private static void testSearchTopicsByTitle_fiveDigitArticleNumber() {
        TopicRatingController.TopicSearchRequest req = new TopicRatingController.TopicSearchRequest();
        Knowledge__kav articleToSearchFor = (Knowledge__kav) new KnowledgeArticleSelector()
            .selectArticleByTitle(new List<Object>{DRAFT_TITLE_PREFIX + ARTICLE_TITLE_1})
            .executeQuery()[0];
        req.titlePart = articleToSearchFor.ArticleNumber;
        while (req.titlePart.startsWith('0')) {
            req.titlePart = req.titlePart.removeStart('0');
        }
        req.langCode = MAIN_LANGUAGE;
        Test.startTest();

        Response res = TopicRatingController.searchTopicsByTitle(JSON.serialize(req));

        Test.stopTest();

        System.assert(res != null, 'Empty response');
        System.assertEquals(res.status, Response.STATUS_SUCCESS, 'Error returned for valid request');
        List<TopicRatingController.Topic> foundTopics = (List<TopicRatingController.Topic>) res.data.get(
            TopicRatingController.LABEL_TOPICS
        );
        System.assert(!foundTopics.isEmpty(), 'Search found nothing');
        System.assertEquals(foundTopics[0].name, DRAFT_TITLE_PREFIX + ARTICLE_TITLE_1, 'Topic name does not match');
        System.assertEquals(foundTopics[0].langCode, MAIN_LANGUAGE, 'Language does not match');
        System.assertEquals(foundTopics[0].position, null, 'Topic position should be null for found topics');
    }

    @isTest
    private static void testGetSupportedLanguages() {
        final String COUNTRY = 'en_GB';
        final String LANG = 'EN';
        new SObjectBuilder(SupportCommunityLanguages__c.SObjectType)
            .setField(SupportCommunityLanguages__c.Name, 'Test_01')
            .setField(SupportCommunityLanguages__c.Language__c, LANG)
            .setField(SupportCommunityLanguages__c.Country__c, COUNTRY)
            .create();

        Test.startTest();
        Map<String, Object> langs = TopicRatingController.getSupportedLanguages().data;
        Test.stopTest();

        System.assertEquals(
            (String) langs.get(COUNTRY),
            LANG,
            'Languages from Custom Settings was updated incorrectly.'
        );

        System.assertEquals(
            (String) langs.get(MAIN_LANGUAGE),
            'en',
            'Languages from Custom Settings was updated incorrectly.'
        );

        System.assertEquals(
            (String) langs.get(SECONDARY_LANGUAGE),
            'es',
            'Languages from Custom Settings was updated incorrectly.'
        );
    }

    @isTest
    private static void testGenerateOrderedTrendingResult() {
        Map<String, Object> trendings = getCoveoResponseMock();
        List<Object> trends = (List<Object>) trendings.get('combinations');
        Set<String> langs = new Set<String>{MAIN_LANGUAGE, SECONDARY_LANGUAGE};

        Test.startTest();
        List<SupportCommunityTopicRating__c> ratings = TopicRatingController.generateOrderedTrendingResult(
            trends,
            langs
        );
        Test.stopTest();

        System.assertEquals(ratings.size(), 3, 'Trending Topics was retrieved incorrectly.');

        System.assertEquals(
            ratings[0].Name,
            [SELECT Title, KnowledgeArticleId FROM Knowledge__kav LIMIT 1].Title,
            'Trending Topic has invalid name'
        );
    }

    private static Map<String, Object> getCoveoResponseMock() {
        return new Map<String, Object>{
            'cached' => 'true',
            'combinations' => new List<Object>{
                new Map<String, Object>{
                    'DocumentView' => '23',
                    'documentSysUriHash' => 'testHash',
                    'documentTitle' => 'Fax Troubleshooting Checklist and Frequently Asked Questions',
                    'documentURL' => 'https://salesforce.com/' +
                        [SELECT KnowledgeArticleId FROM Knowledge__kav LIMIT 1].KnowledgeArticleId,
                    'searchHubName' => 'Box16SupportCommunity',
                    'sourceName' => 'Box16Knowledge'
                }
            }
        };
    }
}