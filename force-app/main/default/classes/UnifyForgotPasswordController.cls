public class UnifyForgotPasswordController {
public String username {get; set;}   
public boolean invalidUser {get; set;}
    
    public UnifyForgotPasswordController() {
      invalidUser = false;  
    }
	
  	public PageReference forgotPassword() {
        Profile AtosProfile = [Select Id from Profile where name = 'Atos Partner Community - Partner Admin'];
        List<user> userlist = [select id, username from user where profileid=:AtosProfile.id and isactive=true and username=:username];
        if(userlist.size()>0)
        {
            boolean success = Site.forgotPassword(username);
            PageReference pr = Page.UnifyResetPassword;
            invalidUser = false;
            pr.setRedirect(true);
            return pr;
        }
        else
        {
            invalidUser = true;
            return null;
        }
  	}
}