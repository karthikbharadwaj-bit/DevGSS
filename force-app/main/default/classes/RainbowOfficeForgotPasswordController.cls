public class RainbowOfficeForgotPasswordController {
    public String username {get; set;}   
    public boolean invalidUser {get; set;}
    
    public RainbowOfficeForgotPasswordController() {
      invalidUser = false;  
    }
	
  	public PageReference forgotPassword() {
        Profile ALEProfile = [Select Id from Profile where name = 'ALE Rainbow Community - Partner Admin'];
        List<user> userlist = [select id, username from user where profileid=:ALEProfile.id and isactive=true and username=:username];
        if(userlist.size()>0)
        {
            boolean success = Site.forgotPassword(username);
            PageReference pr = Page.RainbowOfficeResetPassword;
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