//class for Generic E2C setup

global class GenericE2Csetup implements Messaging.InboundEmailHandler {
    
    public static Boolean isGenericException = false;
    
    private Boolean isValidFromAddress = false;
    private Boolean isTemplateFound = false;
    private Boolean isCaseCreated = false;
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env)
    {
    	Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        //CMR-350292: E2EStaging - Versatel Case Comments logic
        if(email.subject != null && !email.subject.containsIgnoreCase('Comment') && !email.subject.containsIgnoreCase('ID-Extern:'))
        {
        	//Invoke the genericE2CSetupHandler class to get all the metadata records of generic E2C setup
        	GenericE2CSetupHandler handler = new GenericE2CSetupHandler(email);
        
        	//check if the partner/vendor/sender email address is valid
        	if(email.fromAddress != null)
        	{
            	isValidFromAddress = GenericE2CSetupHandler.checkIsValidEmailAddress(email.fromAddress,email);
        	}
        	//create exception record when there is no Valid from Address in the custom metadata type
        	if(isValidFromAddress != null && !isValidFromAddress && isGenericException != true)
        	{
            	GenericE2CExceptionHandler.inValidEmailAddressException(email);
            	result.success = false;
            	return result;
        	}
        	//if valid from address is available check for email template
        	else if(email.fromAddress != null && isValidFromAddress != null && isValidFromAddress)
        	{
           		String emailBody;
            	If(email.htmlBody != null)
            	{
                	emailBody = email.htmlBody.stripHtmlTags();
            	}
            	else if(email.plainTextBody != null)
            	{
                	emailBody = email.plainTextBody;
            	}
            	isTemplateFound = GenericE2CSetupHandler.checkTemplateFound(email.fromAddress,emailBody,email);
        	}
            
        	//if template is found, then try to create case
        	if(email.fromAddress != null && isTemplateFound && (email.htmlBody != null || email.plainTextBody != null))
        	{
            	String emailBody;
            	String emailSubject;
            	if(email.subject != null)
            	{
                	emailSubject = email.subject;
            	}
            	If(email.htmlBody != null)
            	{
                	emailBody = email.htmlBody.stripHtmlTags();
            	}	
            	else if(email.plainTextBody != null)
            	{
                	emailBody = email.plainTextBody;
            	}
            
            	isCaseCreated = GenericE2CSetupHandler.checkCaseCreated(email.fromAddress, emailBody, emailSubject, email);
        	}
        	// if case creation not successful, create a exception record 
        	if(isCaseCreated != null && !isCaseCreated && isGenericException != true)
        	{
            	GenericE2CExceptionHandler.caseNotCreatedException(email);
            	result.success = false;
            	return result; 
        	}
        	else if(isCaseCreated != null && !isCaseCreated)
        	{
            	result.success = true;
            	return result;
        	}
            
        	return result;
        }
        //CMR-350292: E2EStaging - Versatel Case Comments logic        
        else if((email.subject != null && email.subject.containsIgnoreCase('Comment') && email.subject.containsIgnoreCase('RC Ticket:'))||
                (email.subject != null) && email.subject.containsIgnoreCase('ID-Extern:') && email.subject.containsIgnoreCase('Versatel'))
        {
            GenericE2CSetupHandler genericSetup = new GenericE2CSetupHandler(email);
            String PartnerName = GenericE2CSetupHandler.findPartner(email);
            GenericE2CSetupHandler.partnerCaseCommentCreation(email, PartnerName);
        }
        result.success = false;
        return result;
    }
    

}