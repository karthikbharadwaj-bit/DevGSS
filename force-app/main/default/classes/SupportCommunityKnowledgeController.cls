public without sharing class SupportCommunityKnowledgeController {
    public static final String ARTICLE_NOT_FOUND_ERROR_MESSAGE = 'Article not found';
    public static final String MORE_THAN_ONE_ARTICLE_WITH_NUMBER = 'More than one article have this number';
    public static final String ARTICLE_KEY_NAME = 'Article';
    public static final String ATTACHED_FILES_KEY_NAME = 'Docs';
    public static final String DEFAULT_KNOWLEDGE_LANGUAGE = 'en_US';
    public static final List<String> SUPPORT_KNOWLEDGE_LANGUAGES = new List<String>{'en_US', 'fr', 'de', 'es'};
    public static final String INVALID_LANG_CODE = 'Invalid language code.';
    public static final String STATISTICS_KEY_NAME = 'Stat';
    public static final String DOC_KEY_NAME = 'doc';

    private static final String NULL_ARTICLE_NUMBER_ERROR_MESSAGE = 'Article number is null';
    private static final Boolean isUserExternalGuest = UserInfo.getUserType() == 'Guest';
    private static final String ERROR_FIELD_NAME = 'error';
    private static final String SUCCESS_FIELD_NAME = 'success';
    private static final String ARTICLE_NUMBER = 'ArticleNumber';
    private static final String URL_NAME = 'UrlName';

    @RemoteAction
    public static Map<String, Object> getKnowledgeInfoByArticleNumber(String articleNumber) {
        Knowledge__kav articleVersion = getKnowledgeArticleVersion(
            ARTICLE_NUMBER,
            articleNumber,
            DEFAULT_KNOWLEDGE_LANGUAGE,
            false
        );
        return new Map<String, Object>{
            ARTICLE_KEY_NAME => articleVersion,
            ATTACHED_FILES_KEY_NAME => getArticleAttachedFiles(articleNumber, '', false)
        };
    }

    @AuraEnabled
    @RemoteAction
    public static Map<String, Object> getKnowledgeInfo(String value) {
        Map<String, Object> income = (Map<String, Object>) JSON.deserializeUntyped(value);
        String urlName = (String) income.get('urlName');
        String jsUID = (String) income.get('jsUID');
        String language = (String) income.get('language');
        String userId = isUserExternalGuest ? null : UserInfo.getUserId();

        try {
            Knowledge__kav article = getKnowledgeArticleVersion(URL_NAME, urlName, language, true);
            RC_Article_Rating__c artStat = getArticleRatingStatistics(article.ArticleNumber);

            if (artStat == null) {
                artStat = new RC_Article_Rating__c(
                    Article_Number__c = article.ArticleNumber,
                    PositiveVotesCount__c = 0,
                    NegativeVotesCount__c = 0
                );
            }

            return new Map<String, Object>{
                ARTICLE_KEY_NAME => article,
                ATTACHED_FILES_KEY_NAME => getArticleAttachedFiles(article.ArticleNumber, language, true),
                'Rating' => getArticleRatingInteger(getLatestUserArticleRating(article.ArticleNumber, jsUID, userId)),
                'Stats' => artStat,
                SUCCESS_FIELD_NAME => true
            };
        } catch (Exception er) {
            return new Map<String, Object>{ERROR_FIELD_NAME => er.getMessage(), SUCCESS_FIELD_NAME => false};
        }
    }
    @TestVisible
    private static Knowledge__kav getKnowledgeArticleVersion(
        String searchField,
        String searchValue,
        String lang,
        Boolean updateViewStat
    ) {
        List<Knowledge__kav> articleVersionList;
        String knowledgeQuery =
            'SELECT Id, Title, UrlName, Language, PublishStatus, RC_Knowledge_Article_Details__c, Summary, ' +
            'RC_Knowledge_Article_Key_Words__c, ArticleTotalViewCount, RC_Knowledge_Article_Issue__c, RC_Knowledge_Article_STR__c, RC_Knowledge_Article_Cause__c, RC_Knowledge_Article_Resolution__c, ' +
            'RC_Knowledge_Article_Question__c, RC_Knowledge_Article_Symptom__c, RC_Knowledge_Article_AffectedEnv__c, RC_Knowledge_Article_Status__c, LastPublishedDate, ArticleNumber, ' +
            'CreatedBy.Name, LastModifiedBy.Name ' +
            'FROM Knowledge__kav WHERE ' +
            'Language = :lang AND ' +
            String.escapeSingleQuotes(searchField) +
            ' = \'' +
            String.escapeSingleQuotes(searchValue) +
            '\' AND ' +
            'PublishStatus = \'online\' AND ' +
            'IsLatestVersion = TRUE ' +
            'LIMIT 1';
        if (updateViewStat) {
            knowledgeQuery += ' UPDATE VIEWSTAT';
        }
        try {
            articleVersionList = Database.query(knowledgeQuery);
        } catch (QueryException ex) {
            if (!ex.getMessage().contains(INVALID_LANG_CODE)) {
                throw ex;
            }
        }
        if (articleVersionList == null || articleVersionList.isEmpty()) {
            if (lang == DEFAULT_KNOWLEDGE_LANGUAGE) {
                throw new KnowledgeException(ARTICLE_NOT_FOUND_ERROR_MESSAGE);
            } else {
                return getKnowledgeArticleVersion(searchField, searchValue, DEFAULT_KNOWLEDGE_LANGUAGE, updateViewStat);
            }
        } else {
            return articleVersionList.get(0);
        }
    }

    @RemoteAction
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

    @AuraEnabled(Cacheable=true)
    public static List<Knowledge__kav> getTopTopics(String value) {
        Integer rowCount = 0;
        try {
            Map<String, Object> income = (Map<String, Object>) JSON.deserializeUntyped(value);
            rowCount = (Integer) income.get('count');
        } catch (Exception e) {
            rowCount = 4;
        }
        return [
            SELECT Id, Title, UrlName, ArticleTotalViewCount
            FROM Knowledge__kav
            WHERE PublishStatus = 'online' AND IsLatestVersion = true
            ORDER BY ArticleTotalViewCount DESC
            LIMIT :rowCount
        ];
    }

    @AuraEnabled
    public static Map<String, Object> saveCommentAndRating(String value) {
        Map<String, Object> res = new Map<String, Object>{ERROR_FIELD_NAME => '', SUCCESS_FIELD_NAME => true};

        try {
            Map<String, Object> income = (Map<String, Object>) (JSON.deserializeUntyped(value));
            if (income == null) {
                res.put(ERROR_FIELD_NAME, 'No info came');
                res.put(SUCCESS_FIELD_NAME, false);
                return res;
            }

            String articleNumber = (String) income.get('artid');

            checkIfArticleWithNumberExists(articleNumber);

            String userId = isUserExternalGuest ? null : UserInfo.getUserId();

            PageReference page = ApexPages.currentPage();
            String jsUID = (String) income.get('jsuid');

            String comment = (String) income.get('comm');
            Object rateObject = income.get('rate');
            if (String.isEmpty(comment) && rateObject == null) {
                throw new KnowledgeException('Comment is empty');
            }

            Boolean isRatingComment = String.isEmpty(comment);

            Decimal rating = isRatingComment ? Decimal.valueOf((Integer) rateObject) : null;

            String ratingType = isUserExternalGuest ? 'Public' : 'Logged In';

            RC_User_Article_Rating__c latestUserArticleRating = getLatestUserArticleRating(
                articleNumber,
                jsUID,
                userId
            );

            Decimal previousRating = getArticleRatingInteger(latestUserArticleRating);

            if (!isRatingComment || previousRating == 0) {
                latestUserArticleRating = new RC_User_Article_Rating__c(
                    RC_Article_Rating__c = rating,
                    RC_User_Id__c = userId,
                    User_UID__c = jsUID,
                    User_Comments__c = comment,
                    RC_User_name__c = UserInfo.getName(),
                    RC_ArticleID__c = articleNumber,
                    RC_Rating_Type__c = ratingType,
                    Is_External__c = true
                );
                insert latestUserArticleRating;
            } else {
                latestUserArticleRating.RC_Article_Rating__c = rating;
                update latestUserArticleRating;
            }

            String versionId = (String) income.get('versionId');
            RC_Article_Rating__c artStat = getArticleRatingStatistics(articleNumber);

            if (artStat == null) {
                artStat = new RC_Article_Rating__c(
                    Article_Number__c = articleNumber,
                    PositiveVotesCount__c = 0,
                    NegativeVotesCount__c = 0
                );
            }

            if (isRatingComment) {
                if (previousRating > 0) {
                    if (previousRating >= 3) {
                        artStat.PositiveVotesCount__c--;
                    } else {
                        artStat.NegativeVotesCount__c--;
                    }
                }
                if (rating > 0) {
                    if (rating >= 3) {
                        artStat.PositiveVotesCount__c++;
                    } else {
                        artStat.NegativeVotesCount__c++;
                    }
                }
            }
            upsert artStat;
            res.put(STATISTICS_KEY_NAME, artStat);
        } catch (Exception e) {
            res.put(ERROR_FIELD_NAME, e.getMessage() + '#####' + e.getStackTraceString());
            res.put(SUCCESS_FIELD_NAME, false);
        }
        return res;
    }

    @testVisible
    private static RC_Article_Rating__c getArticleRatingStatistics(String articleNumber) {
        RC_Article_Rating__c artStat;

        try {
            artStat = [
                SELECT Article_Number__c, NegativeVotesCount__c, PositiveVotesCount__c
                FROM RC_Article_Rating__c
                WHERE Article_Number__c = :articleNumber
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        } catch (Exception e) {
            return null;
        }

        return artStat;
    }

    @AuraEnabled
    public static RC_User_Article_Rating__c getLatestUserArticleRating(
        String articleNumber,
        String jsUID,
        String userId
    ) {
        RC_User_Article_Rating__c latestUserArtileRating;
        String query =
            'SELECT Id, RC_Article_Rating__c, RC_ArticleID__c, RC_User_Id__c,' +
            ' RC_User_name__c, RC_Rating_Type__c,' +
            ' IP_Address__c, User_Comments__c, User_UID__c' +
            ' FROM RC_User_Article_Rating__c' +
            ' WHERE RC_ArticleID__c = :articleNumber' +
            ' AND RC_Article_Rating__c != NUll' +
            ' AND RC_User_Id__c = :userId';

        if (!String.isEmpty(jsUID) && String.isEmpty(userId)) {
            query += ' AND User_UID__c = :jsUID';
        }
        query += ' ORDER BY CreatedDate DESC';
        query += ' LIMIT 1';

        try {
            latestUserArtileRating = Database.query(query);
        } catch (Exception e) {
            return null;
        }
        return latestUserArtileRating;
    }

    private static Integer getArticleRatingInteger(RC_User_Article_Rating__c userArticleRating) {
        if (userArticleRating == null || userArticleRating.RC_Article_Rating__c == null) {
            return 0;
        } else {
            return Integer.valueOf(userArticleRating.RC_Article_Rating__c);
        }
    }

    @testVisible
    private static void checkIfArticleWithNumberExists(String articleNumber) {
        Integer count = [SELECT COUNT() FROM Knowledge__ka WHERE ArticleNumber = :articleNumber];

        if (count == 0) {
            throw new KnowledgeException(ARTICLE_NOT_FOUND_ERROR_MESSAGE);
        } else if (count > 1) {
            throw new KnowledgeException(MORE_THAN_ONE_ARTICLE_WITH_NUMBER);
        }
    }

    @AuraEnabled
    @RemoteAction
    public static Map<String, Object> addFileToArticle(String articleNumber, String contentVersionId) {
        Map<String, Object> res = new Map<String, Object>();
        Boolean success = true;
        try {
            checkIfArticleWithNumberExists(articleNumber);

            ContentVersion contentVersion = [
                SELECT ContentDocumentId, Title
                FROM ContentVersion
                WHERE Id = :contentVersionId
                LIMIT 1
            ];

            res.put('conVer', contentVersion);

            ContentDistribution fileDist = new ContentDistribution();
            fileDist.ContentVersionId = contentVersion.Id;
            fileDist.Name = contentVersion.Title;
            insert fileDist;

            fileDist = [
                SELECT ContentDocumentId, ContentDownloadUrl, DistributionPublicUrl
                FROM ContentDistribution
                WHERE Id = :fileDist.Id
                LIMIT 1
            ];

            Id contentDocumentId = contentVersion.ContentDocumentId;

            SupportCommunityKnowledgeFile__c fileSeq = new SupportCommunityKnowledgeFile__c(
                Name = contentVersion.Title,
                KnowledgeId__c = articleNumber,
                DocumentId__c = contentDocumentId,
                FileTitle__c = contentVersion.Title,
                DownloadUrl__c = fileDist.ContentDownloadUrl,
                DistributionUrl__c = fileDist.DistributionPublicUrl,
                isPublished__c = false
            );
            insert fileSeq;
            res.put(DOC_KEY_NAME, fileSeq);
        } catch (Exception e) {
            success = false;
            res.put(ERROR_FIELD_NAME, e.getMessage() + '######' + e.getStackTraceString());
        }
        res.put(SUCCESS_FIELD_NAME, success);

        return res;
    }

    @AuraEnabled
    @RemoteAction
    public static Map<String, Object> removeFileFromArticle(String articleNumber, String docId) {
        Map<String, Object> res = new Map<String, Object>();
        Boolean success = true;

        try {
            checkIfArticleWithNumberExists(articleNumber);

            List<SupportCommunityKnowledgeFile__c> fileSeq = [
                SELECT Id
                FROM SupportCommunityKnowledgeFile__c
                WHERE DocumentId__c = :docId AND KnowledgeId__c = :articleNumber
            ];

            delete fileSeq;

            List<ContentDistribution> distFiles = [
                SELECT Id, ContentVersionId
                FROM ContentDistribution
                WHERE ContentDocumentId = :docId
            ];

            Set<String> fileIds = new Set<String>();
            for (ContentDistribution conDis : distFiles) {
                fileIds.add(conDis.ContentVersionId);
            }

            delete distFiles;

            //          DELETE IS NOT ALLOWDED ON CONTENT VERSION
            List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE id = :docId];
            delete docs;
        } catch (Exception e) {
            success = false;
            res.put(ERROR_FIELD_NAME, e.getMessage());
        }
        res.put(SUCCESS_FIELD_NAME, success);
        return res;
    }

    @RemoteAction
    public static Map<String, Object> publishFiles(String articleNumber) {
        Map<String, Object> res = new Map<String, Object>();
        Boolean success = true;
        try {
            checkIfArticleWithNumberExists(articleNumber);

            List<SupportCommunityKnowledgeFile__c> files = getArticleAttachedFiles(articleNumber, '', false);

            for (SupportCommunityKnowledgeFile__c fileSeq : files) {
                fileSeq.isPublished__c = true;
            }
            update files;
        } catch (Exception e) {
            success = false;
            res.put(ERROR_FIELD_NAME, e.getMessage());
        }
        res.put(SUCCESS_FIELD_NAME, success);
        return res;
    }

    @TestVisible
    @RemoteAction
    public static Boolean changeFileLang(String value) {
        Map<String, Object> income = (Map<String, Object>) JSON.deserializeUntyped(value);
        String docId = (String) income.get('docId');
        String languages = (String) income.get('languages');
        try {
            SupportCommunityKnowledgeFile__c file = [
                SELECT Id
                FROM SupportCommunityKnowledgeFile__c
                WHERE DocumentId__c = :docId
                LIMIT 1
            ];
            file.Language__c = languages;
            update file;
        } catch (Exception ex) {
            return false;
        }
        return true;
    }
    public class KnowledgeException extends Exception {
    }
}