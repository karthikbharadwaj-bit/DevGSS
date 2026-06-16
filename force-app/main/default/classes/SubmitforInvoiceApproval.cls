/**************************************************************************************************************
Class Name  : SubmitforInvoiceApproval
CreatedBy   : Sheetalraj G
Date        : 14-Feb-2022
Description : This class used when Submit for Invoice Approval button is clicked
*************************************************************************************************************/

public with sharing class SubmitforInvoiceApproval {
    private static final String RC_ACC_STATUS_CANCELLED = 'Canceled';

    /**********************************************************************************************************
      MethodName : submitApproval
      Parameters : Approval ID and Comments 
      Return type: String
      Description: Returns Success if Inserted successfully and Error messages.
    ************************************************************************************************************/
    
    @AuraEnabled
    public static String submitApproval(String recrdId, String comments) {
    	
        string ApprovalProcessName;
        Id taxExemptRecordtypeId = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get('Tax Exempt Approval').getRecordTypeId();
        string response;
        
        try {
        	ProcessDefinition pd = [SELECT Id, Name, DeveloperName, Type, Description, TableEnumOrId, State FROM ProcessDefinition Where type = 'Approval' and State = 'Active'
								and Name like '%Invoice Request Approval%']; 
        ApprovalProcessName = pd.DeveloperName;
        
        Approval__c appr = [SELECT Id, CreatedById, CreatedBy.Name, Status__c,Opportunity__c, Opportunity__r.Special_TOS_Approval__c,Tax_Exempt_Approval__c, Industry__c, Account_Status__c, Level1Approver__c
                            FROM Approval__c WHERE Id = :recrdId LIMIT 1];
        
        User currentUser = (User) new UserSelector()
                            .selectCurrentUserForSettingsService()
                            .executeQuery()
                            .get(0);

        if (appr.Account_Status__c == RC_ACC_STATUS_CANCELLED) {
            return System.Label.AccountStatusCanceled;
        }else if (currentUser.ManagerId == null) {
            return System.Label.InvoiceApprovalManagerNotFound;
        }else if (currentUser.ManagerId != null && appr.Level1Approver__c != currentUser.ManagerId) {
            updateProcessInstance(recrdId, null, currentUser.ManagerId);
        }
        if(appr.Tax_Exempt_Approval__c == true){
        	
            List<Approval__c> taxExemptAppr = [Select id,RecordTypeId,Opportunity__c,Tax_Exempt_Approval__c from Approval__c where Status__c = 'Approved' and
                                              RecordTypeId =:taxExemptRecordtypeId and Opportunity__c = :appr.Opportunity__c];
            
            if(taxExemptAppr.size() > 0) {
                	Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                	req.setObjectId(recrdId);
                    req.setComments(String.valueOf(comments));
                    req.setSubmitterId(UserInfo.getUserId());
                    req.setProcessDefinitionNameOrId(ApprovalProcessName);
                    Approval.ProcessResult approvalResult = Approval.process(req);
                    System.debug('Invoice submitted for approval successfully: '+approvalResult .isSuccess());
                    
                	if(approvalResult .isSuccess()){
                        updateProcessInstance (recrdId, approvalResult.getInstanceId(), currentUser.ManagerId);
                         return 'Invoice Request Submitted Successfully';
                    }
                
            }
            else
            {
                return 'No Approved Tax Exempt Approval Record';
            }
            
            
        }
        else
        {
            // We need Approval Process Name to Send approval to VP if the Tax Exempt Approval Checkbox is not checked for the 
            // Exempted Industry, Here we can check the Industry Condition before creating Approval Submit request.
            	/*String cstmLabel_TaxExemptedIndusties = system.Label.Tax_Exempt_Industries;
            	if(cstmLabel_TaxExemptedIndusties.contains(appr.Industry__c))	{
                	// Redirect to the Invoice request to his or her VP
            	}*/
            
        	    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(recrdId);
                req.setComments(String.valueOf(comments));
                req.setSubmitterId(UserInfo.getUserId());
                req.setProcessDefinitionNameOrId(ApprovalProcessName);
                Approval.ProcessResult approvalResult = Approval.process(req);
                System.debug('Invoice submitted for approval successfully: '+approvalResult .isSuccess());
                    
                if(approvalResult .isSuccess()){
                    updateProcessInstance (recrdId, approvalResult.getInstanceId(), currentUser.ManagerId);
                        return 'Invoice Request Submitted Successfully';
                }
        }
        
        return response;
            
        }
        catch(Exception e) {
            response = e.getMessage();
            return response;
        }
        
    }
    private static void updateProcessInstance(String recordId, String processId, Id managerId){
        Approval__c app = new Approval__c(Id= recordId, InvoiceApprovalType__c= processId, Level1Approver__c=managerId);
        Triggers.switchOff();
        update app;
        Triggers.switchOn();
    }
}