public with sharing class TopicRatingController {
    private static final String BUILDER_URL_PATTERN =
        '' + 'https://{0}/sfsites/picasso/core/config/commeditor.jsp?siteId={1}';
    private static final String IMAGES_URL_PATTERN = 'https://{0}/{1}/o';

    private static final String LANGUAGE_CODE_DEFAULT = 'en_US';
    private static final Set<String> ENGLISH_DERIVATIVE_LANGCODES = new Set<String>{'en_GB', 'en_AU'};
    private static final Integer SEARCH_OUTPUT_LIMIT = 20;
    private static final Integer DEFAULT_TOPIC_LIST_SIZE = 5;
    private static final Integer ARTICLE_NUMBER_SIZE = 9;
    private static final Integer TOPIC_NAME_MAX_SIZE = 80;

    public static final String LABEL_TOPICS = 'topics';
    public static final String LABEL_LIST_SIZE = 'listSize';
    public static final String LABEL_DOMAIN = 'domain';
    public static final String LABEL_FIXED_TOPICS = 'fixedTopics';
    public static final String LABEL_COVEO_TOPICS = 'coveoTopics';
    public static final String LABEL_ADMIN_LINKS = 'links';
    public static final String COMMUNITY_SITE_TYPE = 'ChatterNetworkPicasso';
    public static final String COMMUNITY_NAME = 'RingCentral Support';
    @TestVisible
    private static final List<String> TITLES = new List<String>{'Builder', 'Images Manager'};
    @TestVisible
    private static final List<String> ICONS = new List<String>{'standard:template', 'standard:location'};
    @TestVisible
    private static final List<String> DESCRIPTIONS = new List<String>{
        'Build community pages, add Links components, edit navigation, edit downloads (links), edit url’s',
        'Manage images for carousel, slider, edit downloads (title, image), edit Links components'
    };

    private static Map<String, List<SupportCommunityTopicRating__c>> cachedTopicRatings =
        new Map<String, List<SupportCommunityTopicRating__c>>();

    private static List<SupportCommunityTopicRating__c> getTopicRatingsForLanguage(String langCode) {
        if (!cachedTopicRatings.containsKey(langCode)) {
            cachedTopicRatings.put(
                langCode,
            [
                SELECT Id, TopicId__c, Position__c, Place__c, Active__c, Url__c, Name, Language__c, FullTitle__c
                FROM SupportCommunityTopicRating__c
                WHERE Place__c = 'Trending' AND Language__c = :langCode
                ORDER BY Position__c
            ]
            );
        }
        return cachedTopicRatings.get(langCode);
    }

    public class Topic {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String langCode;
        @AuraEnabled
        public Integer position;
        @AuraEnabled
        public String url;

        public void requireValid(String langCode, Integer listSize) {
            if (listSize == null || listSize <= 0) {
                AquivaHelper.throwAquivaException(
                    'Invalid list size: ' + listSize + ', for language code = ' + langCode);
            }
            if (this.position > listSize) {
                AquivaHelper.throwAquivaException(
                    String.format(
                        'Position ({0}) greater than list size ({1})',
                        new List<Integer>{this.position, listSize}
                    )
                );
            }
            if (this.name == null) {
                AquivaHelper.throwAquivaException('Invalid topic provided: name not specified');
            }
            if (this.id == null) {
                AquivaHelper.throwAquivaException('Invalid topic provided: id not specified');
            }
            if (this.url == null) {
                AquivaHelper.throwAquivaException('Invalid topic provided: url not specified');
            }
        }

        public Topic(SupportCommunityTopicRating__c topicRating) {
            this.id = String.valueOf(topicRating.TopicId__c);
            this.name = topicRating.FullTitle__c;
            this.langCode = topicRating.Language__c;
            this.position = Integer.valueOf(topicRating.Position__c);
            this.url = topicRating.Url__c;
        }

        public Topic(Knowledge__kav article) {
            this.id = String.valueOf(article.KnowledgeArticleId);
            this.name = article.Title;
            this.langCode = article.Language;
            this.url = article.KnowledgeArticleId;
        }

        public SupportCommunityTopicRating__c toSObject(String langCodeOverride) {
            return new SupportCommunityTopicRating__c(
                TopicId__c = this.id,
                FullTitle__c = this.name,
                Name = this.name.length() > TOPIC_NAME_MAX_SIZE ? this.name.left(TOPIC_NAME_MAX_SIZE) : this.name,
                Language__c = String.isEmpty(langCodeOverride) ? this.langCode : langCodeOverride,
                Position__c = this.position,
                Url__c = this.url
            );
        }
    }

    @TestVisible
    private class TopicBundle {
        public String langCode;
        public Integer listSize;
        public List<Topic> topics;
    }

    @TestVisible
    private class TopicSearchRequest {
        public String langCode;
        public String titlePart;
    }

    @TestVisible
    private class LanguageSetting {
        public String country;
        public String domain;
        public Integer listSize;
    }

    @AuraEnabled(Cacheable=true)
    public static Response getTopicData(String langCode, Integer tmp) {
        Response res = new Response();
        try {
            LanguageSetting langSetting = getLanguageSetting(langCode);
            res.setData(LABEL_LIST_SIZE, langSetting.listSize);
            res.setData(LABEL_DOMAIN, langSetting.domain);
            res.setData(LABEL_FIXED_TOPICS, getFixedTrendingTopics(langSetting.listSize, langCode));
            res.setData(LABEL_COVEO_TOPICS, getCoveoTrendingTopics(langCode));
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static Response saveTopicData(String request) {
        Response res = new Response();
        try {
            TopicBundle bundle = (TopicBundle) JSON.deserialize(request, TopicBundle.class);
            saveTopicBundle(bundle);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    @AuraEnabled(Cacheable=true)
    public static Response searchTopicsByTitle(String request) {
        Response res = new Response();
        try {
            TopicSearchRequest topicSearchRequest = (TopicSearchRequest) JSON.deserialize(
                request,
                TopicSearchRequest.class
            );
            List<Topic> foundTopics = searchTopics(topicSearchRequest.titlePart, topicSearchRequest.langCode);
            res.setData(LABEL_TOPICS, foundTopics);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    @AuraEnabled(Cacheable=true)
    public static Response getSupportedLanguages() {
        Response res = new Response();
        Map<String, Object> supportLang = new Map<String, Object>();
        for (SupportCommunityLanguages__c lang : SupportCommunityLanguages__c.getAll().values()) {
            res.setData(lang.Country__c, lang.Language__c);
        }
        return res;
    }

    @AuraEnabled(Cacheable=true)
    public static Response getAdminLinks() {
        Response res = new Response();
        Network netw;
        Site site;
        try {
            netw = [SELECT Id FROM Network WHERE Name = :COMMUNITY_NAME LIMIT 1];
            site = [
                SELECT Id
                FROM Site
                WHERE MasterLabel = :COMMUNITY_NAME AND SiteType = :COMMUNITY_SITE_TYPE
                LIMIT 1
            ];
            Schema.DescribeSObjectResult r = SupportCommunityImagelnk__c.SObjectType.getDescribe();
            String scImages = r.getKeyPrefix();
            String domain = Url.getOrgDomainUrl().getHost();

            List<String> urls = new List<String>();
            urls.add(String.format(BUILDER_URL_PATTERN, new List<String>{domain, site.Id}));
            urls.add(String.format(IMAGES_URL_PATTERN, new List<String>{domain, scImages}));

            List<Object> nav = new List<Object>();
            for (Integer i = 0; i < urls.size(); i++) {
                Object navItem = new Map<String, Object>{
                    'Title' => TITLES[i],
                    'Link' => urls[i],
                    'Icon' => ICONS[i],
                    'Description' => DESCRIPTIONS[i]
                };
                nav.add(navItem);
            }
            res.setData(LABEL_ADMIN_LINKS, nav);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    private static LanguageSetting getLanguageSetting(String langCode) {
        LanguageSetting result;
        String defaultDomain;
        Boolean isCommunity;
        for (SupportCommunityLanguages__c lang : SupportCommunityLanguages__c.getAll().values()) {
            if (LANGUAGE_CODE_DEFAULT == lang.Country__c) {
                defaultDomain = lang.Domain__c;
            }
            if (langCode == lang.Country__c) {
                result = new LanguageSetting();
                result.listSize = lang.TopicListSize__c == null
                    ? DEFAULT_TOPIC_LIST_SIZE
                    : Integer.valueOf(lang.TopicListSize__c);
                result.country = lang.Country__c;
                result.domain = lang.Domain__c;
                isCommunity = lang.isCommunity__c;
            }
            if (result != null && defaultDomain != null) {
                break;
            }
        }
        if (result == null) {
            AquivaHelper.throwAquivaException('Unsupported language code: ' + langCode);
        }
        if (defaultDomain == null) {
            AquivaHelper.throwAquivaException('Could not found domain for default country: ' + LANGUAGE_CODE_DEFAULT);
        }
        if (isCommunity == null || isCommunity == false) {
            result.domain = defaultDomain;
        }
        return result;
    }

    private static void saveTopicBundle(TopicBundle topicBundle) {
        if (topicBundle == null) {
            AquivaHelper.throwAquivaException('Expected topics bundle, but received NULL');
        } else if (topicBundle.langCode == null) {
            AquivaHelper.throwAquivaException('Unspecified language code');
        } else if (topicBundle.topics == null) {
            AquivaHelper.throwAquivaException('Unspecified topics to save');
        }
        if (topicBundle.listSize == null) {
            topicBundle.listSize = getLanguageSetting(topicBundle.langCode).listSize;
        }
        saveTopics(topicBundle.langCode, topicBundle.listSize, topicBundle.topics);
    }

    private static void saveTopics(String langCode, Integer listSize, List<Topic> topics) {
        Map<String, SupportCommunityTopicRating__c> inputTopicRatings = new Map<String, SupportCommunityTopicRating__c>();

        for (Topic topic : topics) {
            topic.requireValid(langCode, listSize);
            inputTopicRatings.put(topic.id, topic.toSObject(langCode));
        }

        Savepoint sp = Database.setSavepoint();

        SupportCommunityLanguages__c langToUpdate;
        for (SupportCommunityLanguages__c lang : SupportCommunityLanguages__c.getAll().values()) {
            if (langCode == lang.Country__c && listSize != lang.TopicListSize__c) {
                lang.TopicListSize__c = listSize;
                langToUpdate = lang;
                break;
            }
        }
        if (langToUpdate != null) {
            update langToUpdate;
        }

        try {
            delete [
                SELECT Id, TopicId__c, Position__c, Place__c, Active__c, Url__c, Name, Language__c
                FROM SupportCommunityTopicRating__c
                WHERE Place__c = 'Trending' AND Active__c = TRUE AND Language__c = :String.escapeSingleQuotes(langCode)
                ORDER BY Position__c
            ];
            insert inputTopicRatings.values();
        } catch (Exception e) {
            Database.rollback(sp);
            AquivaHelper.throwAquivaException(e);
        }
    }

    @TestVisible
    private static List<Topic> getFixedTrendingTopics(Integer listSize, String langCode) {
        if (listSize == null || listSize < 1) {
            AquivaHelper.throwAquivaException('Invalid list size: ' + listSize);
        }
        List<Topic> result = new List<Topic>();
        if (String.isBlank(langCode)) {
            langCode = LANGUAGE_CODE_DEFAULT;
        }
        String escapedLangCode = String.escapeSingleQuotes(langCode);
        for (SupportCommunityTopicRating__c topicRating : getTopicRatingsForLanguage(escapedLangCode)) {
            if (topicRating.Active__c && topicRating.Position__c <= listSize) {
                result.add(new Topic(topicRating));
            }
        }

        return result;
    }

    @TestVisible
    private static List<Topic> getCoveoTrendingTopics(String langCode) {
        List<Topic> result = new List<Topic>();
        if (String.isBlank(langCode)) {
            langCode = LANGUAGE_CODE_DEFAULT;
        }

        String escapedLangCode = String.escapeSingleQuotes(langCode);
        for (SupportCommunityTopicRating__c topicRating : getTopicRatingsForLanguage(escapedLangCode)) {
            if (!topicRating.Active__c) {
                result.add(new Topic(topicRating));
            }
        }
        return result;
    }

    @TestVisible
    private static List<Topic> searchTopics(String titlePart, String langCode) {
        List<Topic> result = new List<Topic>();

        if (String.isBlank(langCode)) {
            langCode = LANGUAGE_CODE_DEFAULT;
        }

        String articleIdCondition;
        try {
            articleIdCondition = ' OR Id = \'' + (Id) titlePart + '\'';
        } catch (Exception e) {
            articleIdCondition = '';
        }
        for (
            Knowledge__kav foundArticle : (List<Knowledge__kav>) Database.query(
            'SELECT Id, UrlName, ArticleNumber,' +
                ' KnowledgeArticleId, Title, Language' +
                ' FROM Knowledge__kav' +
                ' WHERE PublishStatus = \'Online\'' +
                ' AND (Title LIKE \'%' + String.escapeSingleQuotes(titlePart) + '%\'' +
                articleIdCondition + ' OR ArticleNumber = \'' +
                String.escapeSingleQuotes(titlePart.leftPad(ARTICLE_NUMBER_SIZE, '0')) + '\')' +
                ' AND Language = \'' + String.escapeSingleQuotes(langCode) + '\'' + ' ORDER BY Title' +
                ' LIMIT ' + String.escapeSingleQuotes(String.valueOf(SEARCH_OUTPUT_LIMIT)))
        ) {
            result.add(new Topic(foundArticle));
        }
        return result;
    }

    @future(Callout=true)
    public static void updateCommunityTrendingTopics() {
        Boolean success = true;
        try {
            Map<String, Object> trendings;
            try {
                trendings = CoveoApiController.getTrendings();
            } catch (Exception ex) {
                success = false;
                System.debug(ex.getMessage() + ' ##### ' + ex.getStackTraceString());
            }
            delete [SELECT Id FROM SupportCommunityTopicRating__c WHERE Active__c = FALSE];

            Map<String, Object> langs = getSupportedLanguages().data;
            List<Object> trends = (List<Object>) trendings.get('combinations');
            List<SupportCommunityTopicRating__c> trendTopics = generateOrderedTrendingResult(trends, langs.keySet());

            upsert trendTopics;
        } catch (Exception e) {
            success = false;
            System.debug(e.getMessage() + ' ##### ' + e.getStackTraceString());
        }
    }

    @TestVisible
    private static List<SupportCommunityTopicRating__c> generateOrderedTrendingResult(
        List<Object> trends,
        Set<String> langs
    ) {
        Map<Id, SupportCommunityTopicRating__c> trendTopics = new Map<Id, SupportCommunityTopicRating__c>();
        for (Object curTrendObj : trends) {
            try {
                Map<String, Object> curTrend = (Map<String, Object>) curTrendObj;
                String url = (String) curTrend.get('documentURL');
                if (String.isBlank(url)) {
                    continue;
                }
                List<String> parsedUrl = url.split('/');
                String articleIdOrigin = parsedUrl[parsedUrl.size() - 1];
                Id articleId;
                try {
                    articleId = articleIdOrigin.trim();
                } catch (Exception e) {
                    System.debug(e.getMessage() + '####' + e.getStackTraceString());
                    continue;
                }

                trendTopics.put(
                    articleId,
                    new SupportCommunityTopicRating__c(
                        Place__c = 'Trending',
                        Active__c = false,
                        TopicId__c = articleId,
                        Position__c = Decimal.valueOf(trendTopics.size() + 1),
                        Language__c = null
                    )
                );
            } catch (Exception e) {
                System.debug(e.getMessage() + '####' + e.getStackTraceString());
                continue;
            }
        }

        Map<Id, Map<String, Knowledge__kav>> articleEntities = getArticlesInfo(trendTopics.keySet());

        List<SupportCommunityTopicRating__c> topicsToReturn = new List<SupportCommunityTopicRating__c>();
        for (Id topicId : trendTopics.keySet()) {
            if (!articleEntities.containsKey(topicId)) {
                trendTopics.remove(topicId);
                continue;
            }

            for (String langCode : articleEntities.get(topicId).keySet()) {
                Knowledge__kav matchedArticle = articleEntities.get(topicId).get(langCode);
                String arcTitle = matchedArticle.Title;
                SupportCommunityTopicRating__c topic = trendTopics.get(topicId).clone();
                topic.Url__c = matchedArticle.UrlName;
                topic.FullTitle__c = arcTitle;
                topic.Name = arcTitle.length() > TOPIC_NAME_MAX_SIZE ? arcTitle.left(TOPIC_NAME_MAX_SIZE) : arcTitle;
                topic.Language__c = matchedArticle.Language;
                topicsToReturn.add(topic);

                if (matchedArticle.Language == 'en_US') {
                    for (String derivLangCode : ENGLISH_DERIVATIVE_LANGCODES) {
                        SupportCommunityTopicRating__c derivTopic = topic.clone();
                        derivTopic.Language__c = derivLangCode;
                        topicsToReturn.add(derivTopic);
                    }
                }
            }
        }
        return topicsToReturn;
    }

    @TestVisible
    private static Map<Id, Map<String, Knowledge__kav>> getArticlesInfo(Set<Id> articleIds) {
        Map<Id, Map<String, Knowledge__kav>> res = new Map<Id, Map<String, Knowledge__kav>>();
        List<Knowledge__kav> allArticles = [
            SELECT Id, UrlName, ArticleNumber, KnowledgeArticleId, Title, Language
            FROM Knowledge__kav
            WHERE KnowledgeArticleId IN :articleIds AND PublishStatus = 'Online'
        ];
        for (Knowledge__kav article : allArticles) {
            if (!res.containsKey(article.KnowledgeArticleId)) {
                res.put(article.KnowledgeArticleId, new Map<String, Knowledge__kav>());
            }
            res.get(article.KnowledgeArticleId).put(article.Language, article);
        }
        return res;
    }
}