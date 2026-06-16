public without sharing class KnowledgeArticleAPIController {
    
    public static final String ARTICLE_NOT_FOUND_ERROR_MESSAGE = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': article not found';
    public static final String ARTICLE_NOT_PUBLISHED_EXTERNALLY = CaseAPIUtil.BAD_REQUEST_MESSAGE 
        + ': article is not PublishedExternally. Please use includeInternalArticles parameter';
    public static final String MORE_THAN_ONE_ARTICLE_WITH_NUMBER = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': more than one article have this number';

    public static final String ARTICLE_KEY_NAME = 'Article';
    public static final String ATTACHED_FILES_KEY_NAME = 'Docs';
    public static final String RATING_KEY_NAME = 'Rating';
    public static final String STATS_KEY_NAME = 'Stats';
    public static final List<String> SUPPORT_KNOWLEDGE_LANGUAGES = new List<String>{'en_US', 'fr', 'de', 'es'};
    public static final String STATISTICS_KEY_NAME = 'Stat';
    public static final String SUCCESS_MESSAGE_GET = 'Article\'s info provided.';
    public static final String SUCCESS_MESSAGE_POST ='Has successfully created a new feedback entry';
    public static final String IMAGE_CONTENT_URL_SUFFIX = '.content.force.com';

    private static final String ARTICLE_NUMBER = 'ArticleNumber';
    private static final String URL_NAME = 'UrlName';
    private static final String TEST_URL = 'https://rc--test.my.salesforce.com';
    private static final String PUBLISHED_EXTERNALLY_STATUS = KnowledgeArticleService.STATUS_EXTERNAL;
    private static final String PUBLISHED_INTERNALLY_STATUS = KnowledgeArticleService.STATUS_INTERNAL;
    
    private static final Integer MAX_AMOUNT_RELATED_ARTICLES = 10;

    public static Map<String, Object> getKnowledgeInfo(String value) {

        Map<String, Object> income = (Map<String, Object>) JSON.deserializeUntyped(value);

        String urlName = (String) income.get('urlName');
        String uid = (String) income.get('uid');
        String email = (String) income.get('email');
        String language = (String) income.get('language');
        String brands = (String) income.get('brand');
        Boolean includeInternalArticles = (Boolean) income.get('includeInternalArticles');

        Map<String, Object> res = new Map<String, Object>{
            CaseAPIUtil.MESSAGE_FIELD_NAME => SUCCESS_MESSAGE_GET,
            CaseAPIUtil.SUCCESS_FIELD_NAME => true
        };

        if (String.isNotBlank(uid) && String.isNotBlank(email)) {
            CaseAPIUtil.getContact(uid, email);
        }

        Set<String> selectedBrands = getBrandParameterValues(brands);
        validateLanguageParameter(language);

        Knowledge__kav article = getKnowledgeArticleVersion(URL_NAME, urlName, language, selectedBrands, true, includeInternalArticles);
        RC_Article_Rating__c artStat = getArticleRatingStatistics(article.ArticleNumber);
            
        res.put(ARTICLE_KEY_NAME, article);
        res.put(ATTACHED_FILES_KEY_NAME, getArticleAttachedFiles(article.ArticleNumber, language, true));
        res.put(RATING_KEY_NAME, getArticleRating(getLatestUserArticleRating(article.ArticleNumber, uid)));
        res.put(STATS_KEY_NAME, artStat);
        res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);

        return res;
    }

    private static Set<String> getBrandParameterValues(String brands) {
        if (brands == 'IGNORE') {
            return new Set<String>();
        }

        Set<String> selectedBrands = brands.contains(',') ? 
            new Set<String>(brands.replaceAll(' ', '').split(',')) :
            new Set<String>{brands.trim()};

        Set<String> selectedBrandsFormatted = new Set<String>();

        for (String brand : selectedBrands) {
            selectedBrandsFormatted.add(brand.toLowerCase());
        }

        Set<String> validValuesForBrandParameter = getValidValuesForBrandParameter();

        if (!validValuesForBrandParameter.containsAll(selectedBrandsFormatted)) {
            throw new KnowledgeException(
                CaseAPIUtil.ERROR_MESSAGE_INVALID_BRAND_PARAMETER + ' Valid values: ' + validValuesForBrandParameter
            );
        }

        return selectedBrandsFormatted;
    }

    private static void validateLanguageParameter(String language) {
        Set<String> validValuesForLanguageParameter = getValidValuesForLanguageParameter();

        if (!validValuesForLanguageParameter.contains(language.toLowerCase())) {
            throw new KnowledgeException(
                CaseAPIUtil.ERROR_MESSAGE_INVALID_LANGUAGE_PARAMETER + ' Valid values: ' + validValuesForLanguageParameter
            );
        }
    }

    public static String formatArticleKeys(String res){
        return res.replaceFirst('rCKnowledgeArticleStatus', 'status')
            .replaceFirst('rCKnowledgeArticleSymptom', 'symptom')
            .replaceFirst('rCKnowledgeArticleQuestion', 'question')
            .replaceFirst('rCKnowledgeArticleResolution', 'resolution')
            .replaceFirst('rCKnowledgeArticleCause', 'cause')
            .replaceFirst('rCKnowledgeArticleSTR', 'sTR')
            .replaceFirst('rCKnowledgeArticleIssue', 'issue')
            .replaceFirst('rCKnowledgeArticleKeyWords', 'keyWords')
            .replaceFirst('rCKnowledgeArticleDetails', 'details');
    }

    private static DataCategory[] getAllCategories(DataCategory [] categories){
        if(categories.isEmpty()){
            return new DataCategory[]{};
        } else {
            DataCategory [] categoriesClone = categories.clone();
            DataCategory category = categoriesClone[0];
            DataCategory[] allCategories = new DataCategory[]{category};
            categoriesClone.remove(0);
            categoriesClone.addAll(category.getChildCategories());
            allCategories.addAll(getAllCategories(categoriesClone));
            return allCategories;
        }
    }

    public static Set<String> getValidValuesForBrandParameter() {
        Set<String> validValuesForBrandParameter = new Set<String>();
        List<DescribeDataCategoryGroupResult> describeCategoryResult = Schema.describeDataCategoryGroups(
            new String[]{'KnowledgeArticleVersion'}
        );
        
        List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();
        
        for (DescribeDataCategoryGroupResult singleResult : describeCategoryResult) {
            if (singleResult.getName().equals('Brand')) {
                DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
                p.setSobject(singleResult.getSobject());
                p.setDataCategoryGroupName(singleResult.getName());
                pairs.add(p);
                break;
            }
        }

        List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(
            pairs, 
            false
        );
        
        for (DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult) {
            for (DataCategory dtCategory : getAllCategories(singleResult.getTopCategories())) {
                if (dtCategory.getName() != 'All') {
                    validValuesForBrandParameter.add(dtCategory.getName().toLowerCase().trim());
                }
            }
        }

        return validValuesForBrandParameter;
    }

    public static Set<String> getValidValuesForLanguageParameter() {
        Set<String> pickListValuesList= new Set<String>();
        Schema.DescribeFieldResult fieldResult = Knowledge__kav.Language.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getValue().toLowerCase());
        }     
        return pickListValuesList;
    }

    public static Knowledge__kav getArticle(
        String searchField,
        String searchValue,
        String lang,
        Boolean updateViewStat,
        Set<String> brands,
        Boolean includeInternalArticles
    ) {
        String defaultLanguage = KnowledgeArticleService.LANGUAGE_DEFAULT;
        String whereDefaultLanguage = ' AND Language = :defaultLanguage';
        String whereSearchedLanguage = ' AND Language = :lang';
        String LimitOne = ' LIMIT 1';
        String updateViewStatString = ' UPDATE VIEWSTAT';

        String query =
            'SELECT Id, Title, UrlName, Language, PublishStatus, ValidationStatus, RC_Knowledge_Article_Details__c, Summary, ' +
            'RC_Knowledge_Article_Key_Words__c, ArticleTotalViewCount, RC_Knowledge_Article_Issue__c, RC_Knowledge_Article_STR__c,' + 
            ' RC_Knowledge_Article_Cause__c, RC_Knowledge_Article_Resolution__c,RC_Knowledge_Article_Question__c,' + 
            ' RC_Knowledge_Article_Symptom__c, RC_Knowledge_Article_AffectedEnv__c, RC_Knowledge_Article_Status__c,' +
            ' LastPublishedDate, ArticleNumber, CreatedBy.Name, LastModifiedBy.Name, ' +
            '(Select DataCategoryGroupName, DataCategoryName From DataCategorySelections) ' +
            'FROM Knowledge__kav WHERE ' +
            String.escapeSingleQuotes(searchField) +
            ' = \'' +
            String.escapeSingleQuotes(searchValue) +
            '\' AND ' +
            'PublishStatus = \'online\' AND ' +
            'IsLatestVersion = TRUE';

        List<Knowledge__kav> defaultLanguageArticle = new List<Knowledge__kav>();
        List<Knowledge__kav> searchedLanguageArticle = new List<Knowledge__kav>();

        String finalQuerySearchedLanguage = query + whereSearchedLanguage + LimitOne + (updateViewStat ? updateViewStatString : '');
        String finalQueryDefaultLanguage = query + whereDefaultLanguage + LimitOne + (updateViewStat ? updateViewStatString : '');

        searchedLanguageArticle = Database.query(finalQuerySearchedLanguage);
        defaultLanguageArticle = Database.query(finalQueryDefaultLanguage);

        if (searchedLanguageArticle.isEmpty() && defaultLanguageArticle.isEmpty()) {
            throw new KnowledgeException(ARTICLE_NOT_FOUND_ERROR_MESSAGE);
        }

        if (!defaultLanguageArticle.isEmpty()) {
            validateArticleBelongToBrands(defaultLanguageArticle.get(0), brands);
        } else {
            validateArticleBelongToBrands(searchedLanguageArticle.get(0), brands);
        }

        Knowledge__kav article = searchedLanguageArticle.isEmpty() ? defaultLanguageArticle.get(0) : searchedLanguageArticle.get(0);

        if (!includeInternalArticles && !article.ValidationStatus.equalsIgnoreCase(KnowledgeArticleService.STATUS_EXTERNAL)) {
            throw new KnowledgeException(ARTICLE_NOT_PUBLISHED_EXTERNALLY);
        }

        return  article;
    }

    public static Knowledge__kav getKnowledgeArticleVersion(
        String searchField,
        String searchValue,
        String lang,
        Set<String> brands,
        Boolean updateViewStat,
        Boolean includeInternalArticles
    ) {
        Knowledge__kav article = getArticle(searchField, searchValue, lang, updateViewStat, brands, includeInternalArticles);

        return convertArticleImagesUrl(article);
    }

    private static void validateArticleBelongToBrands(Knowledge__kav article, Set<String> brands) {
        if (!brands.isEmpty()) {
            Set<String> brandsBelongToArticle = new Set<String>();
            Boolean isAValidBrand = false;

            for (Knowledge__DataCategorySelection dcSelection : article.DataCategorySelections) {
                if (dcSelection.DataCategoryGroupName == 'Brand') {
                    String brand = dcSelection.dataCategoryName.toLowerCase();
                    brandsBelongToArticle.add(brand);
                    if (!isAValidBrand && brands.contains(brand)) {
                        isAValidBrand = true;
                    }
                }
            }

            if (!isAValidBrand) {
                throw new KnowledgeException(
                    CaseAPIUtil.ERROR_MESSAGE_ARTICLE_NOT_BELONG_TO_BRAND + ' The urlName belongs to the following brand(s): ' + brandsBelongToArticle
                );
            }
        }
    }

    private static Knowledge__kav convertArticleImagesUrl(Knowledge__kav article) {

        String supportCommunityUrl = '';
        Organization org = [SELECT IsSandbox, InstanceName FROM Organization LIMIT 1];
        String scUrl = RingCentralVariousSettings__c.getInstance().Support_Community_URL__c;

        if (org.IsSandbox && !Test.isRunningTest()) {
            if (String.isBlank(scUrl)) {
                ConnectApi.CommunityPage commPage = ConnectApi.Communities.getCommunities();
                for (ConnectApi.Community comm : commPage.communities) {
                    if (comm.siteUrl.endsWith('/support')) {
                        supportCommunityUrl = comm.siteUrl;
                    }
                }
            } else {
                supportCommunityUrl = scUrl;
            }
        } else {
            if (String.isNotBlank(scUrl)) {
                supportCommunityUrl = scUrl;
            } else {
                AquivaHelper.throwAquivaException(
                    'Support_Community_URL__c field in RingCentralVariousSettings__c is empty.'+
                    ' Set it with the following value: https://support.ringcentral.com'
                    );
            }
        }


        if (String.isNotBlank(supportCommunityUrl)) {
            article.RC_Knowledge_Article_Details__c = convertUrlsInString(article.RC_Knowledge_Article_Details__c, supportCommunityUrl, org);
            article.Summary = convertUrlsInString(article.Summary, supportCommunityUrl, org);
            article.RC_Knowledge_Article_Issue__c = convertUrlsInString(article.RC_Knowledge_Article_Issue__c, supportCommunityUrl, org);
            article.RC_Knowledge_Article_STR__c = convertUrlsInString(article.RC_Knowledge_Article_STR__c, supportCommunityUrl, org);
            article.RC_Knowledge_Article_Cause__c = convertUrlsInString(article.RC_Knowledge_Article_Cause__c, supportCommunityUrl, org);
            article.RC_Knowledge_Article_Resolution__c = convertUrlsInString(article.RC_Knowledge_Article_Resolution__c, supportCommunityUrl, org);
            article.RC_Knowledge_Article_Question__c = convertUrlsInString(article.RC_Knowledge_Article_Question__c, supportCommunityUrl, org);
            article.RC_Knowledge_Article_Symptom__c = convertUrlsInString(article.RC_Knowledge_Article_Symptom__c, supportCommunityUrl, org);
            article.RC_Knowledge_Article_Status__c = convertUrlsInString(article.RC_Knowledge_Article_Status__c, supportCommunityUrl, org);
        }

        return article;
    }

    private static String convertUrlsInString(String fieldValue, String communityUrl, Organization org) {
        String embeddedAmp = '&amp;';
        String convertedString = fieldValue;

        if (String.isNotBlank(convertedString)) {

            String hostUrl = URL.getOrgDomainUrl().getHost(); //example: rc--e2estaging.sandbox.my.salesforce.com
            String hostToReplace = 'https://' + hostUrl.replace('my.salesforce.com', 'file.force.com'); //example: https://rc--e2estaging.sandbox.file.force.com

            if (convertedString.contains(hostToReplace)) {
                //communityUrl example https://eafullbox-rc-portal.cs217.force.com/support
                convertedString = convertedString.replaceAll(hostToReplace, communityUrl);
            }

            if (convertedString.contains(embeddedAmp)) {
                convertedString = convertedString.replaceAll(embeddedAmp, '&');
            }
        }

        return convertedString;
    }

    public static List<SupportCommunityKnowledgeFile__c> getArticleAttachedFiles(
        String articleId,
        String language,
        Boolean isPublic
    ) {

        List<SupportCommunityKnowledgeFile__c> docsInfo;
        try {
            String query =
                'SELECT Id, KnowledgeId__c, DocumentId__c, FileTitle__c, DownloadUrl__c, DistributionUrl__c, Language__c, isPublished__c' +
                ' FROM SupportCommunityKnowledgeFile__c' +
                ' WHERE KnowledgeId__c = :articleId';

            if (language.length() > 0 && SUPPORT_KNOWLEDGE_LANGUAGES.contains(language)) {

                query += ' AND (Language__c includes (:language) OR Language__c = null)';
            }

            if (isPublic) {

                query += ' AND isPublished__c = true';
            }

            query += ' ORDER BY FileTitle__c';
            docsInfo = (List<SupportCommunityKnowledgeFile__c>) Database.query(query);

            if (docsInfo == null || docsInfo.size() == 0) {

                docsInfo = null;
            }

        } catch (Exception e) {

            docsInfo = null;
        }

        return docsInfo;
    }

    public static RC_Article_Rating__c getArticleRatingStatistics(String articleNumber) {
        RC_Article_Rating__c artStat;
        try {
            artStat = [SELECT Article_Number__c, NegativeVotesCount__c, PositiveVotesCount__c
                FROM RC_Article_Rating__c
                WHERE Article_Number__c = :articleNumber
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        } catch(Exception e) {
            artStat = new RC_Article_Rating__c(
                Article_Number__c = articleNumber,
                PositiveVotesCount__c = 0,
                NegativeVotesCount__c = 0
            );
        }
        return artStat;
    }

    public static RC_User_Article_Rating__c getLatestUserArticleRating(
        String articleNumber,
        String uid
    ) {

        RC_User_Article_Rating__c latestUserArtileRating;
        String query =
            'SELECT Id, RC_Article_Rating__c, RC_ArticleID__c, RC_User_Id__c,' +
            ' RC_User_name__c, RC_Rating_Type__c,' +
            ' IP_Address__c, User_Comments__c, User_UID__c' +
            ' FROM RC_User_Article_Rating__c' +
            ' WHERE RC_ArticleID__c = :articleNumber' +
            ' AND RC_Article_Rating__c != NUll' +
            ' AND RC_User_Id__c = :uid';

        query += ' ORDER BY CreatedDate DESC';
        query += ' LIMIT 1';

        try {

            latestUserArtileRating = Database.query(query);

        } catch (Exception e) {

            return null;

        }

        return latestUserArtileRating;
    }

    private static Integer getArticleRating(RC_User_Article_Rating__c userArticleRating) {

        if (userArticleRating == null || userArticleRating.RC_Article_Rating__c == null) {

            return 0;

        } else {

            return Integer.valueOf(userArticleRating.RC_Article_Rating__c);
        }
    }

    public static List<RelatedArticlesWrapper> getRelatedArticles(
        String urlName,
        String keyWords,
        List<String> brands,
        Boolean isSearchPublishExternally
    ) {
    
        List<RelatedArticlesWrapper> wrapperList = new List<RelatedArticlesWrapper>();
    
        if (!CaseAPIUtil.hasBlankString(new String[]{urlName, keyWords})) {
            String[] keys = keyWords.split(',');
            Set<String> formattedKeys = new Set<String>();
            Map<String, List<RelatedArticlesWrapper>> articlesByKeyword = new Map<String, List<RelatedArticlesWrapper>>();
    
            // TODO: KnowledgeArticleService.getGenericKeywords()
            List<String> genericKeywords = new String[]{'ringcentral'};
    
            for (String key : keys) {
                String keyFormatted = key.replaceAll('%', '').trim();
                if (String.isNotBlank(keyFormatted) && !genericKeywords.contains(keyFormatted.toLowerCase())) {
                    formattedKeys.add('%'+keyFormatted+'%');
                    articlesByKeyword.put(keyFormatted, new RelatedARticlesWrapper[]{});
                }
            }
    
            String query = '' +
                'SELECT Title, UrlName, ValidationStatus, RC_Knowledge_Article_Key_Words__c, ' +
                '(Select DataCategoryGroupName, DataCategoryName From DataCategorySelections) ' +
                'FROM Knowledge__kav ' + 
                'WHERE RC_Knowledge_Article_Key_Words__c LIKE :formattedKeys ' +
                'AND UrlName != :urlName ' +
                (isSearchPublishExternally ? 
                    'AND ValidationStatus = :PUBLISHED_EXTERNALLY_STATUS ' : 
                    'AND (ValidationStatus = :PUBLISHED_EXTERNALLY_STATUS OR ValidationStatus = :PUBLISHED_INTERNALLY_STATUS) '
                );
    
            List<Knowledge__kav> relatedArticles = (List<Knowledge__kav>) Database.query(query);
            
            Integer totalArticles = 0;

            for (Knowledge__kav article : relatedArticles) {
                RelatedArticlesWrapper articleWrapper = new RelatedArticlesWrapper();
                articleWrapper.articleTitle = article.Title;
                articleWrapper.urlName = article.UrlName;
    
                for (String key : article.RC_Knowledge_Article_Key_Words__c.replaceAll('%', '').split(',')) {
                    String keyFormatted = key.trim();
    
                    if (articlesByKeyword.containsKey(keyFormatted)) {
                        if (brands.isEmpty()) {
                            articlesByKeyword.get(keyFormatted).add(articleWrapper);
                            totalArticles++;
                        } else {
                            for (Knowledge__DataCategorySelection dcSelection : article.DataCategorySelections) {
                                if (brands.contains(dcSelection.dataCategoryName.toLowerCase()) && !wrapperList.contains(articleWrapper)) {
                                    totalArticles++;
                                    articlesByKeyword.get(keyFormatted).add(articleWrapper);
                                    break;
                                }
                            }
                        }
                        break;
                    }
                }
            }
            
            if (totalArticles > MAX_AMOUNT_RELATED_ARTICLES) {
                do {
                    for (String keyword : articlesByKeyword.keySet()) {
                        List<RelatedArticlesWrapper> articles = articlesByKeyword.get(keyword);
                        if (!articles.isEmpty()) {
                            wrapperList.add(articles.remove(0));
                        }
                    }
                } while (wrapperList.size() < MAX_AMOUNT_RELATED_ARTICLES);
            } else {
                for (String keyword : articlesByKeyword.keySet()) {
                    wrapperList.addAll(articlesByKeyword.get(keyword));
                }
            }
        }
    
        return wrapperList;
    }

    public static Map<String, Object> saveCommentAndRating(String value) {

        Map<String, Object> res = new Map<String, Object>{
            CaseAPIUtil.MESSAGE_FIELD_NAME => SUCCESS_MESSAGE_POST,
            CaseAPIUtil.SUCCESS_FIELD_NAME => true
        };

        try {
            Map<String, Object> income = (Map<String, Object>) JSON.deserializeUntyped(value);
            String articleNumber = (String) income.get('articleNumber');
            String uid = (String) income.get('uid');
            String comment = (String) income.get('comment');
            String email = (String) income.get('email');

            Decimal rating = decimal.valueOf((String) income.get('rate'));

            checkIfArticleWithNumberExists(articleNumber);

            List<Contact> contacts = new List<Contact>();
            String ratingType = 'Public';

            if (String.isNotBlank(uid) && String.isNotBlank(email)){
                contacts.add(CaseAPIUtil.getContact(uid, email));
                ratingType = 'Logged In';
            }

            RC_User_Article_Rating__c latestUserArticleRating = getLatestUserArticleRating(articleNumber, uid);

            Decimal previousRating = getArticleRating(latestUserArticleRating);

            if (previousRating == 0 || contacts.isEmpty()) {

                latestUserArticleRating = new RC_User_Article_Rating__c(
                    RC_Article_Rating__c = rating,
                    User_Comments__c = comment,
                    RC_ArticleID__c = articleNumber,
                    RC_Rating_Type__c = ratingType,
                    Is_External__c = true
                );

                if (!contacts.isEmpty()) {
                    latestUserArticleRating.RC_User_name__c = contacts[0].Name;
                    latestUserArticleRating.RC_User_Id__c = uid;
                }
                insert latestUserArticleRating;
            } else {
                latestUserArticleRating.RC_Article_Rating__c = rating;
                latestUserArticleRating.User_Comments__c = comment;
                update latestUserArticleRating;
            }

            RC_Article_Rating__c artStat = getArticleRatingStatistics(articlenumber);


            if (previousRating > 0) {
                if (previousRating >= 3) {
                    artStat.PositiveVotesCount__c += (artstat.PositiveVotesCount__c > 0) ? (-1) : 0;
                } else {
                    artStat.NegativeVotesCount__c += (artstat.NegativeVotesCount__c > 0) ? (-1) : 0;
                }
            }

            if (rating > 0) {
                if (rating >= 3) {
                    artStat.PositiveVotesCount__c ++;
                } else {
                    artStat.NegativeVotesCount__c ++;
                }
            }

            upsert artStat;

            res.put(STATISTICS_KEY_NAME, artstat);
        } catch (Exception e) {
            CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }

        return res;
    }
    
    private static void checkIfArticleWithNumberExists(String articleNumber) {
        Integer count = [
            SELECT count()
            FROM Knowledge__ka
            WHERE ArticleNumber = :articleNumber
        ];

        if (count == 0) {
            throw new KnowledgeException(ARTICLE_NOT_FOUND_ERROR_MESSAGE);
        } else if(count > 1) {
            throw new KnowledgeException(MORE_THAN_ONE_ARTICLE_WITH_NUMBER);
        }
    }

    public class RelatedArticlesWrapper {

        public String articleTitle;
        public String urlName;

        public Boolean equals(Object obj) {
            return obj != null && 
            obj instanceof RelatedArticlesWrapper && 
            ((RelatedArticlesWrapper) obj).urlName == this.urlName;
        }
    }

    public class KnowledgeException extends Exception {
    }
}