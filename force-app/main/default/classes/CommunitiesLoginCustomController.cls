public class CommunitiesLoginCustomController {
    public string userName {get; set;}
    public string password {get; set;}
    
    public PageReference doLogin(){
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        
        String startURL = System.currentPageReference().getParameters().get('startURL');
        system.debug('startURL - ' + startURL);
        
        if(startURL == null)
        {
            if(comDetail.MasterLabel=='partner')
            {
                return Site.login(userName, password, '/partner/s/');
            }
            else
            {
                return null;
            }
        }
        else
        {
            return Site.login(userName, password, startURL);
        }
    }
    
    public PageReference forgotPassword() {
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        PageReference p;
        if(comDetail.MasterLabel=='partner')
        {        
            p = Page.Partner_ForgotPassword;
        }
        p.setRedirect(true);
        return p;
        
    }
}