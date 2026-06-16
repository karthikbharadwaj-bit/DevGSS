public class MailHelper {
	
	public final String EMAIL_USED_WHEN_ATTACHMENT_ADDED_TO_CASE = (RingCentralVariousSettings__c.getInstance()
		?.Email_used_when_Attachment_added_to_Case__c
	);

    public void createMail(String textBody, String htmlBody, String targetObjectId, String replyTo,
                            Boolean activity, String displayName, String subject) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        try {
        	if(targetObjectId !=null) {
	        	mail.setTargetObjectId(targetObjectId);
			}
	        mail.setSaveAsActivity(activity);
	        mail.setSenderDisplayName(displayName); 
	        mail.setsubject(subject);
	        if(textbody != null) {
	            mail.setPlainTextBody(textbody);
			}
	        if(htmlBody != null) {
	            mail.setHtmlBody(htmlBody);
			}
	        if(replyTo != null && replyTo != '') {
	            mail.setReplyTo(replyTo);
			}
	        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch(Exception e) {}
    }
     public void createMail(String textBody, String htmlBody, String targetObjectId, String replyTo,
                            Boolean activity, String displayName, String subject, String[] toAddresses, String[] ccAddress, String[] bccAddress) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        try {
        	if(targetObjectId !=null) {
	        	mail.setTargetObjectId(targetObjectId);
			}
	        mail.setSaveAsActivity(activity);
	        mail.setSenderDisplayName(displayName);
	        mail.setsubject(subject);
	        if(textbody != null) {
	            mail.setPlainTextBody(textbody);
			}
	        if(htmlBody != null) {
	            mail.setHtmlBody(htmlBody);
			}
	        if(!String.isBlank(replyTo)) {
	            mail.setReplyTo(replyTo);
			}
	        if(toAddresses != null && toAddresses.size() != 0) {    
	        	mail.setToAddresses(toAddresses);
	        }
	        if(ccAddress != null && ccAddress.size() != 0) {    
	        	mail.setCcAddresses(ccAddress);
	        }
	        
	        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch(Exception e) {}
    }
    
    public Messaging.SingleEmailMessage createMail(
		String textBody, 
		String htmlBody, 
		String targetObjectId, 
		String replyTo,    
		Boolean activity, 
		String displayName, 
		String subject, 
		String toAddress
	) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        try {
        	if (targetObjectId !=null) {
	        	mail.setTargetObjectId(targetObjectId);
			}
	        
			mail.setSaveAsActivity(activity);
	        mail.setsubject(subject);
	       
		    if (textbody != null) {
	            mail.setPlainTextBody(textbody);
			}
	        
			if (htmlBody != null) {
	            mail.setHtmlBody(htmlBody);
			}
	        
			if (replyTo != null && replyTo != '') {
	            mail.setReplyTo(replyTo);
			}
	        
			if (toAddress != null) {  
	        	String[] toAddresses = new String[] {toAddress}; 
	        	mail.setToAddresses(toAddresses);
	        } 
			
			if (EMAIL_USED_WHEN_ATTACHMENT_ADDED_TO_CASE != null) {
				mail.setOrgWideEmailAddressId((Id) EMAIL_USED_WHEN_ATTACHMENT_ADDED_TO_CASE);
			} else {
				mail.setSenderDisplayName(displayName);
			}

	        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch(Exception e) {
			mail = null;
		}

		return mail;
    }
    
    public Messaging.SingleEmailMessage createAgentCreditMail(String textBody, String htmlBody, String targetObjectId, String replyTo,
                            Boolean activity, String displayName, String subject, String[] toAddresses, String[] ccAddress, String[] bccAddress) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        try {
        	if(targetObjectId !=null) {
        		mail.setTargetObjectId(targetObjectId);
			}
	        mail.setSaveAsActivity(activity);
	        mail.setSenderDisplayName(displayName);
	        mail.setsubject(subject);
	        if(textbody != null) {
	            mail.setPlainTextBody(textbody);
			}
	        if(htmlBody != null) {
	            mail.setHtmlBody(htmlBody);
			}
	        if(!String.isBlank(replyTo)) {
	            mail.setReplyTo(replyTo);
			}
	        if(toAddresses != null && toAddresses.size() != 0) {    
	        	mail.setToAddresses(toAddresses);
	        }
	        if(ccAddress != null && ccAddress.size() != 0) {    
	        	mail.setCcAddresses(ccAddress);
	        }	    
	        return mail;  
        } catch(Exception e) {return mail;}
    }
}