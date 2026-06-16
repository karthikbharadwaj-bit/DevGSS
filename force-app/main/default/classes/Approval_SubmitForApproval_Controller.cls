/*       
* Created By    : Vishal
* Created Date  : 20-05-2020
* Description   : Controller class for Approval_Submit_For_Approval or Approval_Recall lightning components
* Test Class    :Test_Approval_SubmitForApproval_Ctr    

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/


public class Approval_SubmitForApproval_Controller {
    public static ResponseWrapper resWrapper = new ResponseWrapper();

    @AuraEnabled
    public static ResponseWrapper getInitialData(Id recordId) {
        if (recordId != null) {
            Approval__c approval = [
                    SELECT Id, RecordTypeId, RecordType.DeveloperName, NGBSAmountToIncrease__c, Option__c, (SELECT Id FROM ContentDocumentLinks)
                    FROM Approval__c
                    WHERE Id = :recordId
            ];
            if (approval != null) {
                resWrapper.recordTypeDeveloperName = approval.RecordType.DeveloperName;
                resWrapper.isExistAmountToIncrease = (approval.NGBSAmountToIncrease__c != null && approval.NGBSAmountToIncrease__c > 0);
                resWrapper.isExistAttachment = (approval.ContentDocumentLinks != null && !approval.ContentDocumentLinks.isEmpty()) || approval.Option__c == ApprovalHelper.OPTIONS_AUTOMATIC ;
                if (ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE == approval.RecordTypeId) {
                    resWrapper.isDisableSubmitButton = !(resWrapper.isExistAmountToIncrease && resWrapper.isExistAttachment);
                } else {
                    resWrapper.isDisableSubmitButton = false;
                }
            }
        }
        return resWrapper;
    }

    @AuraEnabled
    public static String submitforApproval(String recId, String comment){
        String message;
        try{
            message = ApprovalHelperCls.submitForApproval(recId, comment);
            return message;
        }catch(Exception e){
            message = e.getMessage();	
            return message;
        }
        
        
        
    }
    
    @AuraEnabled
    public static String recallApproval(String recId){
        String message;
        try{
            message = ApprovalHelperCls.recall(recId);
            return message;
        }catch(Exception e){
            message = e.getMessage();	
            return message;
        }
        
        
        
    }

    public class ResponseWrapper {
        @AuraEnabled
        public String recordTypeDeveloperName { get; set; }
        @AuraEnabled
        public Boolean isDisableSubmitButton { get; set; }
        @AuraEnabled
        public Boolean isExistAttachment { get; set; }
        @AuraEnabled
        public Boolean isExistAmountToIncrease { get; set; }
    }

}