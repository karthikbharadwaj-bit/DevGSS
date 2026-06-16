@SuppressWarnings('PMD')
public without sharing class IgniteLoginFormController {
    @AuraEnabled
    public static ActionStatus doLogin(String userName, String passWord, String startURL) {
        Pagereference pageRef;
        try {
            if(startURL == null)
                pageRef = Site.login(userName, passWord, '/RCPartnerProgram/s/');
            else
                pageRef = Site.login(userName, password, startURL);
        } catch (Exception e) {
            return new ActionStatus('failure', e.getMessage()); 
        }
        return new ActionStatus('success', pageRef.getUrl());
    }

    @AuraEnabled
    public static ActionStatus doResetPassword(String userName) {
        try {
            Set<Id> rcProfileIds = new Set<Id>();
            List<Profile> rcProfiles = [Select Id from Profile where name in ('Internal RC Community - Partner Admin', 'Internal Shared Login - Partner Admin')];
            for(Profile prof: rcProfiles) {
                rcProfileIds.add(prof.Id);
            }
            List<user> userlist = [select Id, Username from user where profileId in :rcProfileIds and isActive = true and Username = :userName];

            if(userlist.size() > 0) {
                boolean result = Site.forgotPassword(username);
                return new ActionStatus((result ? 'success' : 'failure'), (result ? 'Link sent to reset the password' : 'Failed to send password reset mail'));
            } else {
                return new ActionStatus('failure', 'Invalid Username - please enter a valid Username'); 
            }
        } catch(Exception e) {
            return new ActionStatus('failure', e.getMessage()); 
        }
    }

    public class ActionStatus {
        public ActionStatus(String status, String url) {
            this.status = status;
            this.url = url;
        }
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String url;
    }
}