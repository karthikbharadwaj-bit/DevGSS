@RestResource(urlMapping='/SCApi/v1/knowledgeRestService/*')
global class KnowledgeRestService {

    public static final String SUCCESS_MESSAGE = 'successMessage';
    private static final String DEFAULT_BRAND = 'RC_US';
    public static final String BAD_REQUEST_GET = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': urlName is a required parameter.';
    public static final String BAD_REQUEST_POST = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': articleNumber and rate are required parameters.';
    public static final String BAD_REQUEST_RATE_PARAM_POST = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': rate parameter must be numeric and cannot be greater than 5';

    @HttpGet
    global static void getKnowledgeInfo() {
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);

        try {
            String urlName = RestContext.request.params.get('urlName');
            String uid = RestContext.request.params.get('uid');
            String email = RestContext.request.params.get('email');
            String language = RestContext.request.params.get('language');
            String brand = RestContext.request.params.get('brand');
            Boolean includeInternalArticles = BooleanHelper.toBoolean(RestContext.request.params.get('includeInternalArticles'));

            validateGetRequest(res, urlName);

            Map<String,Object>  responseInfo = getKnowledgeInfoFromController(urlName, uid, email,  language, brand, includeInternalArticles);
            
            CaseAPIUtil.validateMessageField(res, responseInfo, KnowledgeArticleAPIController.SUCCESS_MESSAGE_GET);

            responseInfo = convertResponseToCamelCase(responseInfo);
            responseInfo = formatNameInResponse(responseInfo);
            res.responseBody = Blob.valueOf(KnowledgeArticleAPIController.formatArticleKeys(JSON.serialize(responseInfo)));
        } catch (Exception ex) {
            CaseAPIUtil.constructErrorResponse(ex,RestContext.request, res);
        }
    }

    @HttpPost
    global static void setKnowledgeFeedback() {

        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);

        try {
            Map<String,Object> income = (Map<String,Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
            String articleNumber = (String) income.get('articleNumber');
            String rate = (String) income.get('rate');
            String comment = (String) income.get('comment');
            String uid = (String) income.get('uid');
            String email = (String) income.get('email');

            validatePostRequest(res, articleNumber, rate);

            FeedbackRequestWrapper paramsWrapper = new FeedbackRequestWrapper(articleNumber, rate, comment, uid, email);

            Map<String, Object> response = KnowledgeArticleAPIController.saveCommentAndRating(JSON.serialize(paramsWrapper));

            CaseAPIUtil.validateMessageField(res, response, KnowledgeArticleAPIController.SUCCESS_MESSAGE_POST);

            res.responseBody = Blob.valueOf(JSON.serialize(response));
        } catch (Exception ex) {
            CaseAPIUtil.constructErrorResponse(ex,RestContext.request, res);
        }
    }

    private static void validateGetRequest(RestResponse res, String urlName) {
        if (CaseAPIUtil.hasBlankString(new String[]{urlName})) {
            CaseAPIUtil.throwException(res, BAD_REQUEST_GET);
        }
    }

    private static void validatePostRequest(RestResponse res, String articleNumber, string rate) {
        if (CaseAPIUtil.hasBlankString(new String[]{articleNumber, rate})) {
            CaseAPIUtil.throwException(res, BAD_REQUEST_POST);
        }
        
        if (!rate.isNumeric() || rate.isNumeric() && decimal.valueOf(rate) > 5) {
            CaseAPIUtil.throwException(res, BAD_REQUEST_RATE_PARAM_POST);
        }
    }

    private static Map<String,Object> formatNameInResponse(Map<String,Object> responseInfo) {

        Map<String,Object> articleMap = (Map<String,Object>) responseInfo.get('article');
        Map<String,Object> lastModifiedByMap = (Map<String,Object>) articleMap.get('lastModifiedBy');
        Map<String,Object> createdByMap = (Map<String,Object>) articleMap.get('createdBy');

        if (articleMap != null) {
            formatNameValue(lastModifiedByMap);
            formatNameValue(createdByMap);
        }

        return responseInfo;
    }

    private static void formatNameValue(Map<String,Object> containerMap) {

        String fullName = (String) containerMap.get('name');
        if (String.isNotBlank(fullName)) {
            String[] splittedName = fullName.split(' ');
            String originalName = '';
            String lastName;

            if (splittedName.size() > 1) {
                for (Integer i = 0; i < splittedName.size(); i++) {
                    if (i == (splittedName.size() - 1)) {
                        lastName = splittedName[i];
                    } else {
                        originalName += splittedName[i] +' ';
                    }
                }
                containerMap.put('name', originalName+lastName.substring(0,1).toUpperCase()+'.');  
            }
        }
    }


    private static Map<String,Object> getKnowledgeInfoFromController(String urlName, String uid, String email, String language, String brands, Boolean includeInternalArticles) {
        Map<String,Object> response = new Map<String,Object>();

        try {
            KnowledgeInfoWrapper wrapperItem = new KnowledgeInfoWrapper();
            wrapperItem.urlName = urlName;
            wrapperItem.uid = uid;
            wrapperItem.email = email;
            wrapperItem.language = String.isNotBlank(language) ? language : KnowledgeArticleService.LANGUAGE_DEFAULT;
            wrapperItem.brand = String.isNotBlank(brands) ? brands : DEFAULT_BRAND;
            wrapperItem.includeInternalArticles = includeInternalArticles;
    
            String params = JSON.serialize(wrapperItem);
    
            response = KnowledgeArticleAPIController.getKnowledgeInfo(params);
    
            String keyWords = ((Knowledge__kav) response.get(
                KnowledgeArticleAPIController.ARTICLE_KEY_NAME)
            )?.RC_Knowledge_Article_Key_Words__c;
    
            Boolean isSearchPublishExternally = ((Knowledge__kav) response.get(
                KnowledgeArticleAPIController.ARTICLE_KEY_NAME)
            )?.ValidationStatus?.equals(KnowledgeArticleService.STATUS_EXTERNAL) == true;

            List<Knowledge__DataCategorySelection> dataCategorySelections = ((Knowledge__kav) 
                response.get(KnowledgeArticleAPIController.ARTICLE_KEY_NAME)
            )?.DataCategorySelections;

            List<String> brandsToFilterRelatedArticles = new List<String>();

            for (Knowledge__DataCategorySelection dcSelection : dataCategorySelections) {
                if (dcSelection.DataCategoryGroupName == 'Brand') {
                    brandsToFilterRelatedArticles.add(dcSelection.dataCategoryName.toLowerCase());
                }
            }
    
            List<KnowledgeArticleAPIController.RelatedArticlesWrapper> relatedArticles = KnowledgeArticleAPIController.getRelatedArticles(
                urlName,
                keyWords,
                brandsToFilterRelatedArticles,
                isSearchPublishExternally
            );
    
            if (!relatedArticles.isEmpty()) {
                response.put('relatedArticles', relatedArticles);
            }
        } catch(Exception e) {
            CaseAPIUtil.addErrorMessage(response, e.getMessage());
        }

        return response;
    }


    private static Map<String,Object> convertResponseToCamelCase(Map<String,Object> response) {

        Map<String,Object> camelCaseMap = new Map<String,Object>();

        for (String key : response.keySet()) {

            Object obj = response.get(key);

            if (isMapObject(obj)) {

                Map<String,Object> objectMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(response.get(key)));

                if (objectMap != null) {

                    Map<String,Object> objectCamelCaseMap = convertMapKeysToCamelCase(objectMap);
                    camelCaseMap.put(convertStringToCamelCase(key), objectCamelCaseMap);

                }

            } else if (isCollectionObject(obj)) {

                List<Object> objectList = (List<Object>) response.get(key);
                List<Object> convertedList = new List<Object>();

                for (Object listItem : objectList) {

                    Map<String,Object> objectMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(listItem));

                    if (objectMap != null) {

                        Map<String,Object> objectCamelCaseMap = convertMapKeysToCamelCase(objectMap);
                        convertedList.add(objectCamelCaseMap);

                    }

                }

                camelCaseMap.put(convertStringToCamelCase(key), convertedList);

            } else {

                camelCaseMap.put(convertStringToCamelCase(key), response.get(key));

            }

        }

        return camelCaseMap;

    }

    private static Map<String,Object> convertMapKeysToCamelCase(Map<String,Object> originalMap) {

        Map<String,Object> camelCaseMap = new Map<String,Object>();
        Map<String,Object> innerCamelCaseMap = new Map<String,Object>();

        if (originalMap != null) {

            for (String key : originalMap.keySet()) {

                String formattedKey = convertStringToCamelCase(key);
                Object obj = originalMap.get(key);

                if (isMapObject(obj)) {
                    Map<String,Object> objectMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                    innerCamelCaseMap = convertMapKeysToCamelCase(objectMap);
                    camelCaseMap.put(formattedKey, innerCamelCaseMap);

                } else {
                    camelCaseMap.put(formattedKey, originalMap.get(key));

                }
            }
        }

        return camelCaseMap;

    }

    private static String convertStringToCamelCase(String originalString) {

        if (originalString.endsWith('__c')){

            originalString = originalString.removeEnd('__c');

        }

        if (originalString.substring(0,1).isAllUpperCase()) {

            originalString = originalString.replaceFirst(originalString.substring(0,1), originalString.substring(0,1).toLowerCase());

        }

        if (originalString.contains('_')) {

            originalString = originalString.replaceAll('_', '');

        }

        return originalString;

    }

    private static Boolean isMapObject(Object obj) {

        Map<String,Object> objectMap = null;

        try {

            objectMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(obj));
            return true;

        } catch (Exception e) {}

        return false;
    }

    private static Boolean isCollectionObject(Object input) {

        Object test;

        try{
            test = (List<Object>) input;
            return true;
        } catch(System.TypeException ex){}

        return false;
    }

    global class KnowledgeInfoWrapper {

        global String urlName;
        global String uid;
        global String email;
        global String language;
        global String brand;
        global Boolean includeInternalArticles;

    }

    global class FeedbackRequestWrapper {

        global String articleNumber;
        global String comm;
        global String rate;
        global String uid;
        global String email;

        public FeedbackRequestWrapper(String articleNumber, String rate, String comment, String uid, String email) {
            this.articleNumber = articleNumber;
            this.rate = rate;
            this.comm = comment;
            this.uid = uid;
            this.email = email;
        }
    }
}