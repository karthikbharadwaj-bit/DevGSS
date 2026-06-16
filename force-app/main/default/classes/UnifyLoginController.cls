public class UnifyLoginController {
    public string userName {get; set;}
    public string password {get; set;}
    
    public PageReference doLogin() {
        String startURL = System.currentPageReference().getParameters().get('startURL');
        system.debug('startURL - ' + startURL);
        
        if(startURL == null)
        {
            return Site.login(userName, password, '/atosunify/s/'); 
        }
        else
        {
            return Site.login(userName, password, startURL);
        }
    }
    
    public PageReference forgotPassword() {
        PageReference p = Page.UnifyForgotPassword;
        p.setRedirect(true);
        return p; 
    }
    
}