public class Partner_ForgotPasswordController {
    public String username {get; set;}   
       
    public Partner_ForgotPasswordController() {}
	
  	public PageReference forgotPassword() {
  		boolean success = Site.forgotPassword(username);
  		PageReference pr = Page.Partner_ResetPassword;
  		pr.setRedirect(true);
  		
  		if (success) {  			
  			return pr;
  		}
  		return null;
  	}

}

/*public class Partner_ForgotPasswordController {
    public String username {get; set;}   
       
    public Partner_ForgotPasswordController() {}

      	public PageReference forgotPassword() {
  		boolean success = Site.forgotPassword(username);
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        PageReference p;
        if(comDetail.MasterLabel=='partner')
        { 
  		p = Page.Partner_ResetPassword;
        }
        else if(comDetail.MasterLabel=='atos_unify')
        {         
        p = Page.UnifyResetPassword; 
        }
        
  		p.setRedirect(true);
  		
  		if (success) {  			
  			return p;
  		}
  		return null;
  	}

}*/