public class PartnerCommissionEmailServiceCase implements Messaging.InboundEmailHandler {
    
    private static final String PRIORITY = '4 – Medium';
    private static final String STATUS = 'New';
    private static final String ORIGIN = 'Email';
    private static final String GROUP_NAME = 'Partner Commissions';
    private static final String RECORD_TYPE_NAME = 'Partner Commissions';
    
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		Case newCase = new Case();
        Id recordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get(RECORD_TYPE_NAME).getRecordTypeId();
        List<Group> partnerCommissionGroup = (List<Group>) new GroupSelector()
                                    .selectQueueByName(GROUP_NAME)
                                    .executeQuery();
        if (recordTypeId == NULL || partnerCommissionGroup.isEmpty()) {
            result.success=false;
            return result;
        }
        
        List<Contact> ContactList = (List<Contact>) new ContactSelector()
                                .selectContactByMail(new List<Object>{email.fromAddress})
                                .executeQuery(); 
		String caseObject='Case'; 
        String DescriptionField='Description';
        if(ContactList != null && ContactList.size()==1){
            newCase.AccountId = ContactList[0].AccountId;
            newCase.ContactId = ContactList[0].Id;
        }
        
        newCase.RecordTypeId = recordTypeId;
        newCase.Priority = PRIORITY;
        newCase.Origin = ORIGIN;
        newCase.OwnerId = partnerCommissionGroup.get(0).Id;
        newCase.Subject = email.Subject;
        newCase.Description = truncateEmail(caseObject, DescriptionField, email.plainTextBody);
        newCase.SuppliedEmail= email.fromAddress;
        newCase.SuppliedName= email.fromName;
		newCase.Status= STATUS;

        insert newCase;
        	String emailObject='EmailMessage';
            String textBody='TextBody'; 
            String htmlBody='HtmlBody';
            EmailMessage emailMessage = new EmailMessage();
            emailMessage.ParentId = newCase.Id; 
            emailMessage.FromAddress = email.fromAddress;
            emailMessage.ToAddress = String.join(email.toAddresses, ';');
            emailMessage.Subject = email.subject;
            emailMessage.TextBody = truncateEmail(emailObject, textBody, email.plainTextBody);
            emailMessage.HtmlBody = truncateEmail(emailObject, htmlBody, email.htmlBody); 
            emailMessage.Incoming = true; 
            emailMessage.Status = '0';
            insert emailMessage;
        
        List<Attachment> attachmentsToInsert = new List<Attachment>();
        if (email.binaryAttachments != null && email.binaryAttachments.size() > 0) {
            for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                attachmentsToInsert.add(new Attachment(
               		ParentId = newCase.Id,
                    Name = bAttachment.fileName,
                    Body = bAttachment.body
                ));
            }
        }
            
         if (email.textAttachments != null && email.textAttachments.size() > 0) {
             for (Messaging.InboundEmail.TextAttachment tAttachment : email.textAttachments) { 
                 attachmentsToInsert.add(new Attachment(
                     ParentId = newCase.Id, 
                     Name = tAttachment.fileName, 
                     Body = Blob.valueOf(tAttachment.body), 
                     ContentType = 'text/plain' )); 
             } 
         }

            if (!attachmentsToInsert.isEmpty()) {
                insert attachmentsToInsert;
            }
        
        result.success = true;
        return result;
        
    }
    
    public static String truncateEmail(String objectApiName, String fieldApiName, String inputText) {
        if ( String.isBlank(inputText) && String.isBlank(fieldApiName) && String.isBlank(objectApiName)) {
            return inputText;
        }
        if(inputText == Null){
            return Null;
        }
		
        try {
            // Get object describe
            Schema.SObjectType sObjectType = null; 
            if (objectApiName == 'Case') {
                sObjectType = Schema.Case.SObjectType; 
            }else if (objectApiName == 'EmailMessage') { 
                sObjectType = Schema.EmailMessage.SObjectType; 
            }else {
                throw new IllegalArgumentException('Invalid object API name: ' + objectApiName); 
            }
			
            Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap(); 
            Schema.SObjectField sObjectField = fieldMap.get(fieldApiName); 

            if (sObjectField == null) {
                throw new IllegalArgumentException('Invalid field API name: ' + fieldApiName);
            }

            // Get the field's length limit
            Integer maxLength = sObjectField.getDescribe().getLength();

            // Truncate if needed
            return inputText.length() > maxLength
                ? inputText.substring(0, maxLength)
                : inputText;

        } catch (Exception e) {
            // Log and throw errors for visibility
            System.debug('Error in truncateString: ' + e.getMessage());
            throw new IllegalArgumentException('Error truncating string: ' + e.getMessage());
        }
    }
}