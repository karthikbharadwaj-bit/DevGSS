global with sharing class DSAPIUserAuthenticator implements SpringCMIAuthenticator {

    global  DSAPIUserAuthenticator(string apiAccountID, string iss, string aud, string sub, string pkey,string dataCenter,string version, String scope) {
        this.version = version;
        this.apiAccountID = apiAccountID;
        this.iss = iss;
        this.aud = aud;
        this.sub = sub;
        this.pkey = pkey;
        this.dataCenter = dataCenter;
        this.scope = scope;
    }

    private string version;
    private string apiAccountID;
    private string iss;
    private string aud;
    private string sub;
    private string pkey;
    private string dataCenter;
    private string scope;
    private Datetime lastTokenRequest;
    private CLMTokenRequest tokenRequest;
    private string objectAPIURL;
    private string uploadAPIURL;
    private string downloadAPIURL;


    global string GetObjectAPIUrl(){
       objectAPIURL = 'https://api' + dataCenter +'.springcm.com/'+ version+'/'+apiAccountID;


        return objectAPIURL;
    }

    global string GetUploadAPIUrl(){
        uploadAPIURL = 'https://apiupload' + dataCenter +'.springcm.com/'+ version+'/'+apiAccountID;

        return uploadAPIURL;
    }

    global string GetDownloadAPIUrl(){
        downloadAPIURL = 'https://apidownload' + dataCenter +'.springcm.com/'+ version+'/'+apiAccountID;

        return downloadAPIURL;
    }

    global string AccessToken()
     {

            if (tokenRequest ==null || Datetime.now() > TokenExpiration())
            {
                GetNewToken();
            }
            return tokenRequest.Access_Token;
    }

    global DateTime TokenExpiration()
    { return LastTokenRequest.addSeconds(Integer.valueOf(tokenRequest.Expires_In));
    }
    // global DateTime LastTokenRequest(){

    // }

    global void GetNewToken() {

        String access_token = null;

        //Instantiate a request object
        HttpRequest req = new HttpRequest();
        //set the request METHOD
        req.setMethod('POST');

        //set the request endpoint
        String authendpoint =  'https://'+aud+'/oauth/token';
        System.Debug(LoggingLevel.INFO, '**RequestAuthEndpoint' + authendpoint);
        req.setEndPoint(authendpoint);

        //set the request headers
        //1. Content -type
        String authRequestContentType = 'application/x-www-form-urlencoded';
        System.Debug(LoggingLevel.INFO, '**authRequestContentType ' + authRequestContentType);
        req.setHeader('Content-type', authRequestContentType);

        //2. Host
        String authRequestDomain = aud;
        System.Debug(LoggingLevel.INFO, '**authRequestDomain ' + authRequestDomain);
        req.setHeader('Host', authRequestDomain);

        //Body of the request
        String alg = 'RS256';
        DocusignJWT jwtObject = new DocusignJWT(alg, sub, iss, pkey, scope, authRequestDomain);

	//Set the request body
        String requestBody = 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion='+ jwtObject.issue();
        System.Debug(LoggingLevel.INFO, '**RequestAuthBody' + requestBody);
        req.setBody(requestBody);

        //call the service
        Http http = new Http();
        HTTPResponse res = http.send(req);

        System.Debug(LoggingLevel.INFO, '**ResponseAuthBody' + res.getbody());
        System.Debug(LoggingLevel.INFO, '**ResponseAuth' + res);

	//Obtain the access token from the Response
        if (res.getStatusCode() == 200) {
            this.tokenRequest = (CLMTokenRequest)JSON.deserialize(res.getBody(), CLMTokenRequest.class);
            system.debug(this.tokenRequest.Access_Token);
            this.lastTokenRequest = Datetime.now();
        }

    }
}