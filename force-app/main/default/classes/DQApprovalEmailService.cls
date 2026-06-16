global class DQApprovalEmailService implements Messaging.InboundEmailHandler {
    final static String MAIL_SERVER_EMAIL = 'mailer-daemon@salesforce.com';
    private final String APPROVE_RESPONSE = 'approve';
    private final String DQ_APPROVAL_PENDING_STATUS = 'Pending';
    private final String DQ_APPROVAL_APPROVED_STATUS = 'Approved';
    private final String DQ_APPROVAL_REJECTED_STATUS = 'Rejected';
    private final String DQ_APPROVAL_CANCELLED_STATUS = 'Cancelled';
    private final Set<String> APPROVE_RESPONSE_WORDS = new Set<String>{'approve', 'approved', 'confirm', 'confirmed','accept', 'accepted'};
    private final String REJECT_RESPONSE = 'reject'; 
    private final Set<String> REJECT_RESPONSE_WORDS = new Set<String>{'reject', 'rejected', 'declined', 'decline'};
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        DQ_Email_Service__c objDQEmailService = new DQ_Email_Service__c();
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        try{
            objDQEmailService.From_Email_Address__c = email.fromAddress;
            objDQEmailService.Subject__c = email.subject;
            if(email.htmlBody != null && email.htmlBody.length() < 131071) {
            	objDQEmailService.Body__c = email.htmlBody;
            } else if(email.htmlBody != null && email.htmlBody.length() > 131071) {
                objDQEmailService.Body__c = email.htmlBody.subString(0,131070);
            }
            List<User> userList;
            if(email.plainTextBody != null) {
                if(email.fromAddress != null) {
                     userList = [SELECT ID FROM User WHERE Email = :email.fromAddress AND User.Profile.UserLicense.Name = 'Salesforce'];                }
                
                String emailMessage = '';
                String dqApprovalId = email.plainTextBody.substringBetween('_ref::','::ref_');
                DQ_Deal_Qualification_Approver__c objDQApprover = DQ_DealQualificationUtil.getDQApproverById(dqApprovalId);
                objDQEmailService.DQ_Deal_Qualification_Approver__c = dqApprovalId;
                List<String> listOfEmailContent = email.plainTextBody.split('\n');
                System.debug('objDQApprover>>>'+objDQApprover);
                if(objDQApprover != null && objDQApprover.Status__c == DQ_APPROVAL_PENDING_STATUS) {
                    if(listOfEmailContent != null && listOfEmailContent.size() > 0) {
                        if(APPROVE_RESPONSE_WORDS.contains(listOfEmailContent[0].trim().toLowerCase())) {
                            // Approve DQ
                            objDQApprover.Status__c = DQ_APPROVAL_APPROVED_STATUS;
                            if(listOfEmailContent.size() > 1) {
                                objDQApprover.Comments__c = listOfEmailContent[1];
                            }
                            emailMessage = 'Approved';
                            
                        } else if(REJECT_RESPONSE_WORDS.contains(listOfEmailContent[0].trim().toLowerCase())) {
                            // Reject DQ
                            objDQApprover.Status__c = DQ_APPROVAL_REJECTED_STATUS;
                            if(listOfEmailContent.size() > 1) {
                                objDQApprover.Comments__c = listOfEmailContent[1];
                            }
                            emailMessage = 'Rejected';
                        }
                        else {
                            emailMessage = 'Wrong Keyword';
                        }
                        if(emailMessage == 'Approved' || emailMessage == 'Rejected'){
                            objDQApprover.Approve_Reject_Date__c = system.now();
                            if(userList != null && userList.size() > 0) {
                                objDQApprover.Approved_By__c = userList[0].Id;
                            }
                            
                            update objDQApprover;
                        }
                    }
                } 
                else if(objDQApprover != null && objDQApprover.Status__c == DQ_APPROVAL_APPROVED_STATUS) {
                    // Already Approved
                    emailMessage = 'Approved already.';
                }
                else if(objDQApprover != null && objDQApprover.Status__c == DQ_APPROVAL_REJECTED_STATUS) {
                    //Already Rejected
                    emailMessage = 'Rejected already.';
                }
                else if(objDQApprover != null && objDQApprover.Status__c == DQ_APPROVAL_CANCELLED_STATUS) {
                    // Already Cancelled
                    emailMessage = 'Cancelled already';
                }
                objDQEmailService.Status__c = emailMessage;
            }
        }
        catch(exception ex) {
            objDQEmailService.Status__c = 'Error';
            objDQEmailService.Error_Details__c = ex.getMessage();
        }
        
        insert objDQEmailService;
        
        result.success = true;
        return result;
    }
}