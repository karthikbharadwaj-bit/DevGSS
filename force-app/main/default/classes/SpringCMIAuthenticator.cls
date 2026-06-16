Global  interface SpringCMIAuthenticator {

    string AccessToken();
    Datetime TokenExpiration();
    string GetObjectAPIUrl();
    string GetUploadAPIUrl();
    string GetDownloadAPIUrl();
    //Datetime LastTokenRequest();

}