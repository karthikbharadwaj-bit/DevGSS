@RestResource(urlMapping='/SCApi/v1/caseArticles/*')
global class CaseArticlesRestService {

    public static final Integer MIN_SEARCH_LENGTH = 3;
    public static final String BAD_REQUEST_ARTICLE = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': title and lang are required parameters';
    public static final String BAD_REQUEST_SHORT_TITLE = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Search string too short. Minimum size is ' + MIN_SEARCH_LENGTH;

    @HttpGet
    global static void getRelatedArticles() {
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response); 

        try {

            String title = RestContext.request.params.get('title');
            String lang = RestContext.request.params.get('lang');

            validateGetRequest(res, title, lang);

            Map<String, Object> response = CaseArticlesAPIController.searchArticles(getArticleSearchRequest(title, lang));

            res.responseBody = Blob.valueOf(JSON.serialize(response));
            CaseAPIUtil.validateMessageField(res, response, CaseArticlesAPIController.SUCCESS_MESSAGE_ARTICLE);
        } catch(Exception e) {
            CaseAPIUtil.constructErrorResponse(e,RestContext.request, res);
        }
    }

    private static String getArticleSearchRequest(String title, String lang) {
        SCWrappers.ArticleSearchRequest request = new SCWrappers.ArticleSearchRequest();
        request.langCode = lang;
        request.titlePart = title;
        return JSON.serialize(request);
    }

    private static void validateGetRequest(RestResponse res, String title, String lang) {
        if (CaseAPIUtil.hasBlankString(new String[]{title, lang})) {
            CaseAPIUtil.throwException(res, BAD_REQUEST_ARTICLE);
        }
        if (title.length() < 3) {
            CaseAPIUtil.throwException(res, BAD_REQUEST_SHORT_TITLE);
        }
    }
}