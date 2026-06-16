public with sharing class HttpHelper {
    public class HttpHelperException extends Exception {}
    public static final Integer MAX_TIMEOUT_MS = 120000;
    public static final Integer DEFAULT_TIMEOUT_MS = 60000;

    public static final String METHOD_GET = 'GET';
    public static final String METHOD_POST = 'POST';
    public static final String METHOD_PUT = 'PUT';
    public static final String METHOD_DELETE = 'DELETE';
    public static final String METHOD_PATCH = 'PATCH';

    public static final Decimal STATUS_CODE_NO_CONTENT = 204;
    public static final String STATUS_NAME_NO_CONTENT = 'No Content';

    public static final String CONTENT_TYPE_APPLICATION_JSON = 'application/json';
    public static final String CONTENT_TYPE_APPLICATION_FORM = 'application/x-www-form-urlencoded';

    public static final String CERT_DEV_NAME_ICB = 'ICB';
    public static final String CERT_DEV_NAME_CCB = 'CCB';

    public static final String ERROR_EMPTY_ENDPOINT = 'Endpoint for HttpRequest should not be empty';
    public static final String ERROR_EMPTY_METHOD = 'Method for HttpRequest should not be empty';

    public static final String RESPONSE_STATUS_COMPLETED = 'Completed';

    /*
    * @description: returns header for basic auth for given username and password
    */
    public static String prepareBasicAuthHeader(String username, String password) {
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        return authorizationHeader;
    }

    public static HttpRequest prepareBasicAuthRequest(String endpoint, String method, String authHeader, String body) {
        return prepareBasicAuthRequest(endpoint, method, authHeader, body, null);
    }

    /*
    * @description: prepares HttpRequest with basic auth header based on authHeader and with body
    */
    public static HttpRequest prepareBasicAuthRequest(String endpoint, String method, String authHeader, String body, String contentTypeValue) {
        StringHelper.validateStrict(authHeader, 'AuthHeader for HttpRequest should not be empty');

        HttpRequest request = prepareHttpRequest(endpoint, method, body, contentTypeValue);
        request.setHeader('Authorization', authHeader);

        return request;
    }

    public static HttpRequest prepareHttpRequest(String endpoint, String method, String body) {
        return prepareHttpRequest(endpoint, method, body, null);
    }

    public static HttpRequest prepareHttpRequest(String endpoint, String method, String body, String contentTypeValue) {
        StringHelper.validateStrict(endpoint, ERROR_EMPTY_ENDPOINT);
        StringHelper.validateStrict(method, ERROR_EMPTY_METHOD);

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setTimeout(DEFAULT_TIMEOUT_MS);

        if (String.isNotBlank(body)) {
            request.setBody(body);
            request.setHeader('Content-Type', CONTENT_TYPE_APPLICATION_JSON);
            if(contentTypeValue != null) {
                request.setHeader('Content-Type', contentTypeValue);
            }
        }

        return request;
    }

    /*
    * @description: prepares HttpRequest with basic auth header based on authHeader
    */
    public static HttpRequest prepareBasicAuthRequest(String endpoint, String method, String authHeader) {
        return prepareBasicAuthRequest(endpoint, method, authHeader, null);
    }

    public static Boolean isSuccess(HttpResponse res) {
        return res != null && res.getStatusCode() >= 200 && res.getStatusCode() < 300;
    }

    public static String prepareJWTAuthHeader(String certDevName) {
        Auth.JWT jwt = new Auth.JWT();
        jwt.setValidityLength(3);
        jwt.setAud(Url.getOrgDomainUrl().toExternalForm());
        Auth.JWS jws = new Auth.JWS(jwt, certDevName);
        String authorizationHeader = 'Bearer ' + jws.getCompactSerialization();
        return authorizationHeader;
    }

    public static String formXTokenId() {
        String source = 'Salesforce';
        String host = URL.getOrgDomainUrl().getHost();
        String userName = UserInfo.getUserName();

        return source + ':' + host + ':' + userName;
    }
}