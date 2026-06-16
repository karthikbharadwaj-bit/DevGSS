public class RainbowOfficeLoginController {
    
    public string userName {get; set;}
    public string password {get; set;}
    
    public PageReference doLogin() {
        String startURL = System.currentPageReference().getParameters().get('startURL');
        system.debug('startURL - ' + startURL);
        if(startURL == null)
        {
            return Site.login(userName, password, '/rainbowoffice/s/');  
        }
        else
        {
            return Site.login(userName, password, startURL);
        }
    }
    
    public PageReference forgotPassword() {
        PageReference p = Page.RainbowOfficeForgotPassword;
        p.setRedirect(true);
        return p;  
    }
    
}