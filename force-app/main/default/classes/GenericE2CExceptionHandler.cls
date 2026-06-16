public class GenericE2CExceptionHandler {
	
    private static Exception_And_Notification_History__c exceptionRecord;
    
    public static void inValidEmailAddressException(Messaging.inboundEmail email)
    {
		exceptionRecord = new Exception_And_Notification_History__c();
		exceptionRecord.Sender_Display_Name__c = email.fromAddress;
        exceptionRecord.Email_Subject__c = email.subject;
        if(email.htmlBody != null)
        {
           exceptionRecord.Email_Body__c = email.htmlBody.stripHTMLTags(); 
        }
        else if(email.plainTextBody != null)
        {
            exceptionRecord.Email_Body__c = email.plainTextBody;
        }
        exceptionRecord.Exception_Desc__c = 'The email from address does not match with the custom metadata type records from addresses';
        if(exceptionRecord != null)
        {
            insert exceptionRecord;
        }
    }
    
    public static void caseNotCreatedException(Messaging.inboundEmail email)
    {
        exceptionRecord = new Exception_And_Notification_History__c();
		exceptionRecord.Sender_Display_Name__c = email.fromAddress;
        exceptionRecord.Email_Subject__c = email.subject;
        if(email.htmlBody != null)
        {
           exceptionRecord.Email_Body__c = email.htmlBody.stripHTMLTags(); 
        }
        else if(email.plainTextBody != null)
        {
            exceptionRecord.Email_Body__c = email.plainTextBody;
        }
        exceptionRecord.Exception_Desc__c = 'Template format mismatch or subject format mismatch';
        if(exceptionRecord != null)
        {
            insert exceptionRecord;

            if(GenericE2CSetupHandler.toEmailAddresses != null){
                Id orgWideId;
                if(GenericE2CSetupHandler.fromAddresses != null){
                    orgWideId = Id.valueOf(GenericE2CSetupHandler.fromAddresses);
                }
                String plainTextBody = 'Failed to Create/Update Case. \n\n Reason: '+exceptionRecord.Exception_Desc__c;
                String htmlBody = 'Failed to Create/Update Case. <br/><br/> Reason: '+exceptionRecord.Exception_Desc__c;
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            	emailMessage.toaddresses = GenericE2CSetupHandler.toEmailAddresses.split(';');
                emailMessage.setSubject('Failure: '+email.subject);
                emailMessage.setHtmlBody(htmlBody);
                emailMessage.plaintextbody = plainTextBody;
                emailMessage.setOrgWideEmailAddressId(orgWideId);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailMessage});
            }
        }
    }
    
    public static void genericException(Messaging.inboundEmail email,String message)
    {
        exceptionRecord = new Exception_And_Notification_History__c();
		exceptionRecord.Sender_Display_Name__c = email.fromAddress;
        exceptionRecord.Email_Subject__c = email.subject;
        if(email.htmlBody != null)
        {
           exceptionRecord.Email_Body__c = email.htmlBody.stripHTMLTags(); 
        }
        else if(email.plainTextBody != null)
        {
            exceptionRecord.Email_Body__c = email.plainTextBody;
        }
        exceptionRecord.Exception_Desc__c = message;
        if(exceptionRecord != null)
        {
            insert exceptionRecord;
        }
    }
    
    public static void invalidPartnerName(Messaging.inboundEmail email,String message)
    {
        exceptionRecord = new Exception_And_Notification_History__c();
		exceptionRecord.Sender_Display_Name__c = email.fromAddress;
        exceptionRecord.Email_Subject__c = email.subject;
        if(email.htmlBody != null)
        {
           exceptionRecord.Email_Body__c = email.htmlBody.stripHTMLTags(); 
        }
        else if(email.plainTextBody != null)
        {
            exceptionRecord.Email_Body__c = email.plainTextBody;
        }
        exceptionRecord.Exception_Desc__c = message;
        if(exceptionRecord != null && System.label.No_Reply_RC_email != null)
        {

            	Id orgWide = Id.valueOf(System.label.No_Reply_RC_email);
                String plainTextBody = exceptionRecord.Exception_Desc__c;
                String htmlBody = exceptionRecord.Exception_Desc__c;
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
                emailMessage.toaddresses = new List<String>{email.fromAddress};
                emailMessage.setSubject('Failure - DO NOT REPLY: '+email.subject);
                emailMessage.setHtmlBody(htmlBody);
                emailMessage.plaintextbody = plainTextBody;
                emailMessage.setOrgWideEmailAddressId(orgWide);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailMessage});
        }
        
    }
    
    public static void caseCommentNotCreateException(Messaging.inboundEmail email,String message)
    {
        exceptionRecord = new Exception_And_Notification_History__c();
		exceptionRecord.Sender_Display_Name__c = email.fromAddress;
        exceptionRecord.Email_Subject__c = email.subject;
        if(email.htmlBody != null)
        {
           exceptionRecord.Email_Body__c = email.htmlBody.stripHTMLTags(); 
        }
        else if(email.plainTextBody != null)
        {
            exceptionRecord.Email_Body__c = email.plainTextBody;
        }
        exceptionRecord.Exception_Desc__c = message;
        if(exceptionRecord != null)
        {
            insert exceptionRecord;
            
            if(GenericE2CSetupHandler.toEmailAddresses != null){
                Id orgWideId;
                if(GenericE2CSetupHandler.fromAddresses != null){
                    orgWideId = Id.valueOf(GenericE2CSetupHandler.fromAddresses);
                }
                String plainTextBody = 'Failed to Update Case. \n\n Reason:'+exceptionRecord.Exception_Desc__c;
                String htmlBody = 'Failed to Update Case. \n\n Reason:'+exceptionRecord.Exception_Desc__c;
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            	emailMessage.toaddresses = GenericE2CSetupHandler.toEmailAddresses.split(';');
                emailMessage.setSubject('Failure: '+email.subject);
                emailMessage.setHtmlBody(htmlBody);
                emailMessage.plaintextbody = plainTextBody;
                emailMessage.setOrgWideEmailAddressId(orgWideId);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailMessage});
            }
        } 
    }
    
    public static void genericException(String message)
    {
        exceptionRecord = new Exception_And_Notification_History__c();
        exceptionRecord.Exception_Desc__c = message;
        if(exceptionRecord != null)
        {
            insert exceptionRecord;
        }
        
    }
    
    public static void accountUIDMismatchException(Messaging.InboundEmail email,String message)
    {
                exceptionRecord = new Exception_And_Notification_History__c();
		exceptionRecord.Sender_Display_Name__c = email.fromAddress;
        exceptionRecord.Email_Subject__c = email.subject;
        if(email.htmlBody != null)
        {
           exceptionRecord.Email_Body__c = email.htmlBody.stripHTMLTags(); 
        }
        else if(email.plainTextBody != null)
        {
            exceptionRecord.Email_Body__c = email.plainTextBody;
        }
        exceptionRecord.Exception_Desc__c = message;
        if(exceptionRecord != null)
        {
            insert exceptionRecord;

            if(GenericE2CSetupHandler.toEmailAddresses != null){
                Id orgWideId;
                if(GenericE2CSetupHandler.fromAddresses != null){
                    orgWideId = Id.valueOf(GenericE2CSetupHandler.fromAddresses);
                }
                String plainTextBody = 'Case Not created. \n\n Reason:'+exceptionRecord.Exception_Desc__c;
                String htmlBody = 'Case Not created. \n\n Reason:'+exceptionRecord.Exception_Desc__c;
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            	emailMessage.toaddresses = GenericE2CSetupHandler.toEmailAddresses.split(';');
                emailMessage.setSubject('Failure: '+email.subject);
                emailMessage.setHtmlBody(htmlBody);
                emailMessage.plaintextbody = plainTextBody;
                emailMessage.setOrgWideEmailAddressId(orgWideId);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailMessage});
            }
    }
}
}