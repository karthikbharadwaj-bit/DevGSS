public without sharing class GSPLoginFormController {
    @AuraEnabled
    public static ActionStatus doLogin(String userName, String passWord, String startURL) {
        Pagereference pageRef;
        try {
            if(startURL == null) {
                pageRef = Site.login(userName, passWord,'');
            } else {
                pageRef = Site.login(userName, password, startURL);
            }
            if(pageRef != null) {
                return new ActionStatus('success', pageRef.getUrl());
            }
        } catch (Exception e) {
            return new ActionStatus('failure', e.getMessage()); 
        }
        return new ActionStatus('failure', 'error');
    }

    @AuraEnabled
    public static ActionStatus doResetPassword(String userName) {
        try {
            List<NetworkMember> NetworkMember = [select NetworkId, network.Name, MemberId, Member.Name, Member.username, Member.isActive from NetworkMember 
                                   where NetworkId = :Network.getNetworkId() and Member.isActive = true and Member.username = : userName];
            if(!NetworkMember.isEmpty() || Test.isRunningTest()) {
                boolean result = Site.forgotPassword(userName);
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