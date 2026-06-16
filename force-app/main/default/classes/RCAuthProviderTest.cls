@isTest
public class RCAuthProviderTest {
    private static final String OAUTH_TOKEN = 'testToken';
    private static final String STATE = 'mocktestState';
    private static final String REFRESH_TOKEN = 'refreshToken';
    private static final String LOGIN_ID = 'testLoginId';
    private static final String USERNAME = 'testUsername';
    private static final String FIRST_NAME = 'testFirstName';
    private static final String LAST_NAME = 'testLastName';
    private static final String EMAIL_ADDRESS = 'testEmailAddress';
    private static final String LOCALE_NAME = 'testLocalName';
    private static final String FULL_NAME = FIRST_NAME + ' ' + LAST_NAME;
    private static final String PROVIDER = 'Custom OpenID';
    private static final String REDIRECT_URL = 'https://redirect_to_me';
    private static final String KEY = 'testKey';
    private static final String SECRET = 'testSecret';
    private static final String STATE_TO_PROPOGATE  = 'testState';
    private static final String ACCESS_TOKEN_URL = 'https://token_is_here';
    private static final String AUTH_URL = 'https://auth_here';
    private static final String USER_INFO_URL = 'https://user_info_openid';
    private static final String API_USER_URL = 'https://more_info_here';
    private static final String SCOPES = 'openid email';


    private static Map<String,String> setupAuthProviderConfig () {
        Map<String,String> authProviderConfiguration = new Map<String,String>();
        authProviderConfiguration.put('UserAuthURL__c', AUTH_URL);
        authProviderConfiguration.put('OpenIdScopes__c', SCOPES);
        authProviderConfiguration.put('ClientID__c', KEY);
        authProviderConfiguration.put('ClientSecret__c', SECRET);
        authProviderConfiguration.put('AccessTokenURL__c',ACCESS_TOKEN_URL);
        authProviderConfiguration.put('UserInfoUrl__c',USER_INFO_URL);
        authProviderConfiguration.put('UserAdditionalInfoUrl__c',API_USER_URL);
        authProviderConfiguration.put('RedirectUrl__c',REDIRECT_URL);
        return authProviderConfiguration;
    }

    @isTest
    private static void verifyGenerationAuthUrl() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        RCAuthProvider provider = new RCAuthProvider();
        String actual = provider.initiate(authProviderConfiguration, STATE).getUrl();
        String expected = new PageReference(AUTH_URL + '?client_id=' + KEY +'&scope=' + SCOPES + '&redirect_uri=' + REDIRECT_URL + '&state=' + STATE + '&response_type=code&force=true').getUrl();

        System.assertEquals(expected, actual, 'User redirect urls generated incorrectly');
    }

    @isTest
    private static void validateAnswerFromTokenIdentifier() {
        //Get token and refresh token
        Test.setMock(HttpCalloutMock.class, new AccessTokenHttpCalloutMock());
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        RCAuthProvider provider = new RCAuthProvider();
        String testState = 'test_state';

        Map<String,String> queryParameters = new Map<String,String> {
            'state' => testState,
            'code' => 'testCode'
        };

        Test.startTest();

        Auth.AuthProviderCallbackState state = new Auth.AuthProviderCallbackState( new Map<String,String>(), JSON.serialize(queryParameters), queryParameters);
        Auth.AuthProviderTokenResponse resp = provider.handleCallback(authProviderConfiguration, state );

        Test.stopTest();

        System.assertEquals('TEST_token_123_321', resp.oauthToken);
        System.assertEquals('TEST_refresh_token_123_321', resp.oauthSecretOrRefreshToken);
        System.assertEquals(testState, resp.state);
    }

    @isTest
    private static void getUserInfoTest() {
        //Get user info from OpenId protocol and additional info from API
        Map<String, HttpCalloutMock> requests = new  Map<String, HttpCalloutMock> {
            USER_INFO_URL => new UserInfoHttpCalloutMock(),
            API_USER_URL => new AdditionalUserInfoHttpCalloutMock()
        };

        UserInfoMultiRequesMock multimock = new UserInfoMultiRequesMock(requests);

        Test.setMock(HttpCalloutMock.class, multimock);
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        RCAuthProvider provider = new RCAuthProvider();

        Test.startTest();

        Auth.AuthProviderTokenResponse res = new Auth.AuthProviderTokenResponse('test Provider', 'testToken', 'dscsd', 'sdasd');
        Auth.UserData uData = provider.getUserInfo(authProviderConfiguration, res);

        Test.stopTest();

        System.assertEquals('test@sf_mail.com', uData.email);
        System.assertEquals('12345', uData.identifier);
        System.assertEquals('LNAME', uData.firstName);
        System.assertEquals('FNAME', uData.lastName);
    }

    private class AccessTokenHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            JSONGenerator gen = JSON.createGenerator(true);

            String token = 'TEST_token_123_321';
            String refreshToken = 'TEST_refresh_token_123_321';
            String state = 'test_state';

            gen.writeStartObject();
            gen.writeStringField('access_token', token);
            gen.writeStringField('refresh_token', refreshToken);
            gen.writeStringField('state', state);
            gen.writeEndObject();
            String jsonS = gen.getAsString();

            response.setBody(jsonS);
            response.setStatusCode(200);
            return response;
        }
    }

    private class UserInfoHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            String jsonS = '{"email":"test@sf_mail.com","sub":"12345"}';
            response.setBody(jsonS);
            response.setStatusCode(200);
            return response;
        }
    }

    private class AdditionalUserInfoHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            String jsonS = '{"status":"active", "account":{"id":"1234123"},' +
                '"contact":{"lastName":"FNAME","firstName":"LNAME","country":"US"},' +
                '"regionalSettings":{"formattingLocale":{"localeCode": "en-EN"}}}';
            response.setBody(jsonS);
            response.setStatusCode(200);
            return response;
        }
    }

    private class UserInfoMultiRequesMock implements HttpCalloutMock {
        Map<String, HttpCalloutMock> requests;

        public UserInfoMultiRequesMock(Map<String, HttpCalloutMock> requests) {
            this.requests = requests;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpCalloutMock mock = requests.get(req.getEndpoint());
            if (mock != null) {
                return mock.respond(req);
            } else {
                throw new RCAuthProviderTestException('HTTP callout not supported for test methods');
            }
        }

        public void addRequestMock(String url, HttpCalloutMock mock) {
            requests.put(url, mock);
        }
    }

    private class RCAuthProviderTestException extends Exception {}
}