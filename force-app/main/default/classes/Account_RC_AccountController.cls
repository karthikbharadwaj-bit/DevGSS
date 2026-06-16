/*       
* Created By    : Madhumita
* Created Date  : 04-05-2020
* Description   : Controller class for Account_RC_Account lightning component
* Test Class    : Test_Account_RC_AccountController

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Account_RC_AccountController {
    
    private static final String ERROR_GREATER_MESSAGE = 'UserId is either Null or greater than 20';
    private static final String ERROR_UNABLE_RC_ACCOUNT = 'Unable to launch RC Account. Error during processing';
    
    public static accdetailWrapper accWrapper = new accdetailWrapper();
    public class accdetailWrapper {
        @AuraEnabled public String rcUserid{get;set;}
        @AuraEnabled public String brandName{get;set;}
        @AuraEnabled public String errorMessage{get;set;}
    }

    @AuraEnabled
    public static accdetailWrapper launchRCAccount(String objectId) {
        String result = '';
       
        try {
            Id recId = (Id) objectId;
            String objectNameType = recId.getSobjectType().getDescribe().getName();
            
            QueryFactory qFactory = new AccountSelector().selectAccountById(recId)
                    .withoutSelectorOrderByIncluded()
                    .withoutSelectorFieldsIncluded()
                    .selectFields(new Set<String>{
                            'Id', 'RC_User_ID__c', 'RC_Brand__c'
                    });
            if (objectNameType == 'Case') {
                qFactory.setCondition('Id IN (SELECT AccountId FROM Case WHERE Id = :bind0)');
            }
            Account accObj = (Account) qFactory.executeQuery().get(0);
            accWrapper.rcUserid = accObj.RC_User_ID__c;
            accWrapper.brandName = accObj.RC_Brand__c;
            Boolean isCorrect = (accWrapper.rcUserid != null && accWrapper.rcUserid != '' && accWrapper.rcUserid.length() < 20);
            if (!isCorrect) {
                accWrapper.errorMessage =  ERROR_GREATER_MESSAGE;
            }
        } catch (Exception ex) {
            accWrapper.errorMessage = ERROR_UNABLE_RC_ACCOUNT;
        }
        return accWrapper;
    }
    
    @AuraEnabled
    public static Response getUrlForSCPNavigation(String objectId) {
        RingCentralVariousSettings__c val = RingCentralVariousSettings__c.getInstance(UserInfo.getUserId());
        accdetailWrapper accDetailsWrapper = new accdetailWrapper();

        if (val == null || String.isEmpty(val.RC_Account_SCP_URL_Template__c)) {
            val = RingCentralVariousSettings__c.getInstance();
        }
        accDetailsWrapper = launchRCAccount(objectId);
        if (accDetailsWrapper.errorMessage == ERROR_GREATER_MESSAGE) {
            accDetailsWrapper.rcUserid = null;
        }
        Response res = new Response();
        res.setData('urlTemplate', val.RC_Account_SCP_URL_Template__c);
        res.setData('accUserId',  accDetailsWrapper.rcUserid);
        return res;
    }
    
    @AuraEnabled
    public static Boolean shouldHideYesButton() {
        String userProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        String allowedProfiles = Label.RC_Account_Component_Hide_Yes_Button_Profiles;
        
        if (String.isNotBlank(allowedProfiles)) {
            List<String> restrictedProfiles = allowedProfiles.split(',');
            return restrictedProfiles.contains(userProfileName);
        }
        
        return false;
    }

}