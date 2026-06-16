/*
* Name         : StartRefundManagement
* Created By   : Alexander savickiy 
* Created Date : 27/April/2018
* Description  : B-4771 (Sprint 58 Moscow). 
* Dependencies : No
*/

global class StartRefundManagement {

    @AuraEnabled
    public static Approval__c getApproval(String recordId){
        Approval__c app = [select Account__c,Account__r.RC_User_ID__c from Approval__c Where Id = :recordId];
        return app;
    }
    
     @AuraEnabled
    public static Feature_Toggle__c getFeatureToggleValue(){
         return Feature_Toggle__c.getInstance();
    }

	/**
     * Method to process Refund Management page validation
     * @param approvalId - Approval__c id
     * @return serialized JSON with list of errors if they exist
     */
    @AuraEnabled
	webservice static String processData(Id approvalId) {

		List<RefundManagementHelper.ErrorWrapper> errorMessagesList = RefundManagementHelper.checkRefundManagementPageAccessPermissions(approvalId);
		return JSON.serialize(errorMessagesList);
	}
}