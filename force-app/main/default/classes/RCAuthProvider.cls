public class RCAuthProvider extends Auth.AuthProviderPluginClass {
    public String redirectUrl;
    private String customMetadataTypeApiName = 'RCAuthProviderConfig__mdt';

    public String getCustomMetadataType() {
        return customMetadataTypeApiName;
    }

    public PageReference initiate(Map<string,string> authProviderConfiguration, String stateToPropagate) {

        //General try catch to show custom error for user
        //Error must be from customizable Label
        try {
            // Not properties cause every step initializeы new constructor
            String authUrl = authProviderConfiguration.get('UserAuthURL__c');
            String scopes = authProviderConfiguration.get('OpenIdScopes__c');
            String clientID = authProviderConfiguration.get('ClientID__c');
            String clientSecret = authProviderConfiguration.get('ClientSecret__c');
            String accessTokenUrl = authProviderConfiguration.get('AccessTokenURL__c');
            String userInfoUrl = authProviderConfiguration.get('UserInfoUrl__c');

            redirectUrl = string.isEmpty(redirectUrl) ? authProviderConfiguration.get('RedirectUrl__c') : redirectUrl;

            if(string.isEmpty(accessTokenUrl) || string.isEmpty(userInfoUrl) || string.isEmpty(redirectUrl) || string.isEmpty(authUrl)) {
                this.onError('Empty required url', null);
            }

            if(string.isEmpty(clientID) || string.isEmpty(clientSecret)) {
                this.onError('Client ID or secret is not defined', null);
            }
            scopes = string.isEmpty(scopes) ? 'openid email' : scopes;

            String url = authUrl + '?client_id=' + clientID +'&scope=' + scopes + '&redirect_uri=' + redirectUrl + '&state=' + stateToPropagate + '&response_type=code&force=true';
            return new PageReference(url);

        } catch (Exception e) {
            PlatformLog.logException(RCAuthProvider.class.getName(), e);
            throw new CustomAuthException(Label.SSOAuthUserError);
        }
    }

    public Auth.AuthProviderTokenResponse handleCallback(Map<string,string> authProviderConfiguration, Auth.AuthProviderCallbackState state ) {
        //Correct state is handled by SF natively

        //Here, the developer will get the callback with actual protocol.
        //Their responsibility is to return a new object called AuthProviderToken
        //This will contain an optional accessToken and refreshToken

        //global try for informing user with customizable exception
        try {
            Http localHttpClient = new Http();
            Map<String,String> queryParams = state.queryParameters;
            String code = queryParams.get('code');
            String sfdcState = queryParams.get('state');

            String accessTokenUrl = authProviderConfiguration.get('AccessTokenURL__c');
            redirectUrl = string.isEmpty(redirectUrl) ? authProviderConfiguration.get('RedirectUrl__c') : redirectUrl;
            String clientID = authProviderConfiguration.get('ClientID__c');
            String clientSecret = authProviderConfiguration.get('ClientSecret__c');
            String providerName = authProviderConfiguration.get('MasterLabel');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(accessTokenUrl);

            req.setHeader('Content-Type','application/x-www-form-urlencoded');
            req.setHeader('Accept','application/json');
            req.setMethod('POST');
            String authHeaderValue = EncodingUtil.base64Encode(Blob.valueOf(clientID + ':' + clientSecret));
            req.setHeader('Authorization', 'BASIC ' + authHeaderValue);

            req.setBody(
                'code=' + code
                    + '&client_id=' + clientID
                    + '&redirect_uri=' + redirectUrl
                    + '&grant_type=authorization_code'
            );

            String responseBody;
            HttpResponse httpRes;
            try {
                httpRes =  localHttpClient.send(req);
                responseBody = httpRes.getBody();
            } catch (Exception e){
                this.onError('Identity provider answered incorrectly', e);
            }

            if(string.isEmpty(responseBody)) {
                this.onError('Identity provider answered with empty response', null);
            }

            String accessToken;
            String refreshToken;

            try {
                Map<string, object> body = (Map<string, object>)JSON.deserializeUntyped(responseBody);
                accessToken = (string) body.get('access_token');
                refreshToken =  (string) body.get('refresh_token');
            } catch (Exception e) {
                this.onError('Identity provider didn`t sent any token', null);
            }

            return new Auth.AuthProviderTokenResponse(providerName, accessToken, refreshToken, sfdcState);

        } catch (Exception e) {
            PlatformLog.logException(RCAuthProvider.class.getName(), e);
            throw new CustomAuthException(Label.SSOAuthUserError);
        }
    }

    public Auth.UserData  getUserInfo(Map<string,string> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {
        //customizable info about failed step for user
        try {
            //Here the developer is responsible for constructing an Auth.UserData object
            String accessToken = response.oauthToken;
            String userInfoUrl = authProviderConfiguration.get('UserInfoUrl__c');
            Http localHttpClient = new Http();

            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setEndpoint(userInfoUrl);
            req.setHeader('Content-Type','application/x-www-form-urlencoded');
            req.setHeader('Accept','application/json');
            req.setMethod('GET');
            Map<string, object> body;

            try {
                HTTPResponse res =  localHttpClient.send(req);
                String responseBody = res.getBody();
                system.debug('BODY   ' + responseBody);
                body = (Map<string, object>)JSON.deserializeUntyped(responseBody);
                system.debug(body);
            } catch (Exception e) {
                this.onError('Identity server answered with information in incorrect format', e);
            }

            String id = (string)body.get('sub');
            string email = (string)body.get('email');
            String fname = '';
            String lname = email;
            String uname = id + '_' + email;
            String locale = null;

            boolean useAdditionalInfo = true;

            if(string.isEmpty(id) || string.isEmpty(email)) {
                this.onError('Identity server answered with incorrect information', null);
            }

            string userAdditionalURL = authProviderConfiguration.get('UserAdditionalInfoUrl__c');

            Map<String,String> provMap = new Map<String,String>();
            provMap.put('provider', authProviderConfiguration.get('MasterLabel'));
            provMap.put('useCustomValues', string.valueOf(true));
            provMap.put('DefaultUserProfileName', authProviderConfiguration.get('DefaultUserProfileName__c'));
            provMap.put('CreatedUserTimeZone', authProviderConfiguration.get('CreatedUserTimeZone__c'));
            provMap.put('DefaultAccountUserID', authProviderConfiguration.get('DefaultAccountUserID__c'));
            provMap.put('CreatedUserTimeZone', authProviderConfiguration.get('CreatedUserTimeZone__c'));
            provMap.put('DefaultAccountUserID', authProviderConfiguration.get('DefaultAccountUserID__c'));
            provMap.put('UserRolesMatching', authProviderConfiguration.get('UserRolesMatching__c'));

            if (!string.isEmpty(userAdditionalURL)) {
                HttpRequest newReq = new HttpRequest();
                newReq.setHeader('Authorization', 'Bearer ' + accessToken);
                newReq.setEndpoint(userAdditionalURL);
                newReq.setHeader('Accept','application/json');
                newReq.setMethod('GET');

                try {
                    HTTPResponse resNew =  localHttpClient.send(newReq);
                    string responseBodyNew = resNew.getBody();
                    Map<string, object> additionalUserInfoFullResponse = (Map<string, object>)JSON.deserializeUntyped(responseBodyNew);

                    string userStatus = (string)additionalUserInfoFullResponse.get('status');

                    System.debug(additionalUserInfoFullResponse);
                    Map<string, object> acountInfo = (Map<string, object>)additionalUserInfoFullResponse.get('account');
                    Map<string, object> acountLanguageInfo = (Map<string, object>)additionalUserInfoFullResponse.get('regionalSettings');
                    Map<string, object> contactInfo = (Map<string, object>)additionalUserInfoFullResponse.get('contact');

                    if(acountInfo != null) {
                        String accountUID = (string)acountInfo.get('id');
                        provMap.put('accountId', accountUID);
                    } else {
                        provMap.put('accountId', null);
                    }

                    if(contactInfo != null) {
                        String country = (String)contactInfo.get('country');
                        fname = (String)contactInfo.get('firstName');
                        lname = (String)contactInfo.get('lastName');
                    }

                    if(acountLanguageInfo != null) {
                        Map<string, object> formattingLocale = (Map<string, object>)acountLanguageInfo.get('formattingLocale');
                        if(formattingLocale != null) {
                            locale = (String)formattingLocale.get('localeCode');
                        }
                    }
                } catch (Exception e) {
                    this.onError('Server with additional info about user answered incorrectly', e);
                }
            }
            else {
                useAdditionalInfo = false;
            }
            provMap.put('useAdditionalInfo', string.valueOf(useAdditionalInfo));
            return new Auth.UserData(id, fname, lname, fname + ' ' + lname, email,
                null, email, null, response.provider, null, provMap);

        } catch (Exception e) {
            PlatformLog.logException(RCAuthProvider.class.getName(), e);
            throw new CustomAuthException(Label.SSOAuthUserError);
        }
    }

    private void onError(string message, Exception e) {
        if (e != null) {
            PlatformLog.logException(RCAuthProvider.class.getName(), e);
            System.debug(e.getMessage() + ' ##### ' + e.getStackTraceString());
        }
        throw new CustomAuthException(message);
    }

    private class CustomAuthException extends Exception{}
}