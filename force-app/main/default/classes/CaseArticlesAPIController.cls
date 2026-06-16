public with sharing class CaseArticlesAPIController {
    
    public static final String SUCCESS_MESSAGE_ARTICLE = 'Articles list provided';
    public static final Integer SEARCH_OUTPUT_LIMIT = 50;
    public static final String LABEL_ARTICLES = 'articles';
    

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

    public static Map<String, Object> searchArticles(String request) {

        Map<String, Object> res = new Map<String, Object>();

        try {
            Map<String, Object> req = CaseAPIUtil.deserializeRequest(request);

            res.put(LABEL_ARTICLES, searchCaseRelatedArticles(req));
            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, SUCCESS_MESSAGE_ARTICLE);
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
        } catch (Exception e) {
            CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }

        return res;
    }

    private static List<SCWrappers.Article> searchCaseRelatedArticles(Map<String, Object> req) {

        List<SCWrappers.Article> result = new List<SCWrappers.Article>();
        String title = (String) req.get('titlePart');
        String langCode = (String) req.get('langCode');

        if (langCode != null && !ARTICLE_CATEGORY_MAPPING.containsKey(langCode)) {
            return result;
        }

        result = KnowledgeArticleService.searchArticlesByTitleOrKeyword(
            title,
            langCode,
            ARTICLE_CATEGORY_MAPPING.get(langCode),
            SEARCH_OUTPUT_LIMIT
        );

        return result;
    }
}