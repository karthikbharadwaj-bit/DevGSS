global with sharing class CMAPIUserAuthenticator implements SpringCMIAuthenticator {
   

    global  CMAPIUserAuthenticator(string clientID, string clientSecret,string authUrl,string dataCenter, string version) {
        this.clientId = clientID;
        this.clientSecret = clientSecret;
        this.authUrl = authUrl;
        this.dataCenter = dataCenter;
        this.version = version;
    }
    
    private string clientId;
    private string clientSecret;
    private string authUrl;
    private string dataCenter;
    private string version;
    private Datetime lastTokenRequest;
    private CLMTokenRequest tokenRequest;
    private string objectAPIURL;
    private string uploadAPIURL;
    private string downloadAPIURL;
    


    global string GetObjectAPIUrl(){
        objectAPIURL = 'https://api' + dataCenter +'.springcm.com/'+ version;
        
        return objectAPIURL;
    }
    
    global string GetUploadAPIUrl(){
       uploadAPIURL = 'https://apiupload' + dataCenter +'.springcm.com/'+ version;
        return uploadAPIURL;
    }

    global string GetDownloadAPIUrl(){ 
        downloadAPIURL = 'https://apidownload' + dataCenter +'.springcm.com/'+ version;
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
            
        system.debug(this.clientId);
        SpringCMHTTPRequestor req = new SpringCMHTTPRequestor(null);
        string body = '{"client_id": "' +clientId +'","client_secret": "'+clientSecret+ '"}';
        string resp = req.Post(authUrl, body, new Map<string, string>());
        system.debug('Token Response');
        system.debug(resp);
        this.tokenRequest = (CLMTokenRequest)JSON.deserialize(resp, CLMTokenRequest.class);
        system.debug(this.tokenRequest.Access_Token);
        this.lastTokenRequest = Datetime.now();
    }

   
}