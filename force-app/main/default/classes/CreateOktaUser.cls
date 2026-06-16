public class CreateOktaUser {
    public static String OKTA_URL = 'https://myaccounts-ringcentral.okta.com'; 
    public static String OKTA_API = '00lQfSEOLV6vNsmZmPvklnQjfBlY3iha8iYDEtapFm';
    public static String OKTA_PASSWORD = 'ra!nb0w7';
    Contact contactObj {get;set;}
    public OktaUser oktaUserObj{get;set;}
    public Boolean isLanding{get;set;}
    public Boolean isErrorOccured{get;set;}
    public Boolean authorizationError{get;set;}
    public CreateOktaUser(ApexPages.StandardController controller) {
        authorizationError = false;
        isErrorOccured = false;
        isLanding = true;
        if(controller.getId() == null) {
            isErrorOccured = true;
        }
        contactObj = (Contact) controller.getRecord();
    }
    public PageReference cancel() {
        return new ApexPages.StandardController(contactObj).view();
    }
    public PageReference validateUser() {
        isLanding = false;
        User userObj = null; 
        try {
            userObj = [SELECT Id, FirstName, UserType, LastName, Username, Name, MobilePhone, Phone, OKTAUserID__c, OktaUserPassword__c, IsActive FROM User WHERE ContactId =: contactObj.Id AND UserType='PowerPartner' LIMIT 1];
        } catch(Exception e) {}
        try {
            if(userObj != null) {
                if(userObj.IsActive) {
                    String userStr = isOktaUserAvailalbe(userObj);
                    if(Test.isRunningTest()) {
                    	userStr = '{"profile":{"firstName":"Anuj","lastName":"Shukla","email":"rcindiateam@simplion.com","login":"anuj.shukla@simplion.com","mobilePhone":"(991) 010-2345"}}';
                    }
                    oktaUserObj = (OktaUser)JSON.deserialize(userStr,OktaUser.class);
                    if(oktaUserObj != null) {
                        if(oktaUserObj.id != null || !String.isBlank(userObj.OKTAUserID__c)) {
                            if(String.isBlank(userObj.OKTAUserID__c)) {
                                userObj.OKTAUserID__c = oktaUserObj.id; 
                                userObj.OktaUserPassword__c = CreateOktaUser.OKTA_PASSWORD;
                                update userObj;
                            }
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '<span style="color:#084B8A">'+userObj.Username+'</span>' +' already exists in Okta.'));
                        } else {
                            userStr = makeOktaUser(userObj);
                            if(Test.isRunningTest()) {
		                    	userStr = '{"id":"00u3uty75rWFWAOFWHQJ","profile":{"firstName":"Anuj","lastName":"Shukla","email":"rcindiateam@simplion.com","login":"anuj.shukla@simplion.com","mobilePhone":"(991) 010-2345"}}';
		                    }
                            oktaUserObj = (OktaUser)JSON.deserialize(userStr,OktaUser.class);
                            if(oktaUserObj != null) {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Okta User was successfully created.'));
                                userObj.OKTAUserID__c = oktaUserObj.id;
                                resetOktaPassword(oktaUserObj.id);
                                userObj.OktaUserPassword__c = CreateOktaUser.OKTA_PASSWORD;
                                update userObj;
                            }
                        }
                    }
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This Partner Portal User is Inactive.  Please set this User as Active before creating an Okta User.'));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No Partner Portal User exists for this Contact.'));
            }
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
        }
        return null;
    }
    public String isOktaUserAvailalbe(User userObj) {
    	String endURL = CreateOktaUser.OKTA_URL+'/api/v1/users/'+ userObj.Username;
        String body = null;
        String action = 'GET';
        return callAPIs(endURL, body, action);
    }
    public void resetOktaPassword(String oktaUserId) {
    	String endURL = CreateOktaUser.OKTA_URL+'/api/v1/users/'+oktaUserId+'/lifecycle/reset_password?sendEmail=true';
        String body = null;
        String action = 'GET';
        callAPIs(endURL, body, action);
    }
    public String makeOktaUser(User userObj) {
        String endURL = CreateOktaUser.OKTA_URL+'/api/v1/users?activate=true';
        String body = '{"profile": {"firstName": "'+ userObj.FirstName +'","lastName": "'+userObj.LastName+'","email": "var.okta@ringcentral.com","login": "'+userObj.Username+'","mobilePhone": "'+(userObj.Phone == null ? '' : userObj.Phone)+'"}}';
        String action = 'POST';
        return callAPIs(endURL, body, action);
    }
    private String callAPIs(String endURL, String body, String action) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
    	req.setEndpoint(endURL);
    	if(body != null){
        	req.setBody(body);
        }
        req.setHeader('Content-type', 'application/json');
        req.setHeader('Accept', 'application/json'); 
        req.setHeader('Authorization','SSWS '+CreateOktaUser.OKTA_API);
        req.setMethod(action);
        HTTPResponse res =new HTTPResponse();
        if(!test.isRunningTest()){
        	res = http.send(req);
        }
        return res.getBody();
    }
    
    
    public class OktaUser {
        public String id{get;set;}
        public String errorCode{get;set;}
        public String errorSummary{get;set;}
        public String errorLink{get;set;}
        public String errorId{get;set;}
        public String[] errorCauses{get;set;}
        public Profile profile{get;set;}
    }
    public class Profile {
        public String firstName{get;set;}
        public String lastName{get;set;}
        public String login{get;set;}
        public String email{get;set;}
        public String mobilePhone{get;set;}
    }
}