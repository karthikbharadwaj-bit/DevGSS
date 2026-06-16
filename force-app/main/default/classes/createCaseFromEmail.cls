//Logic to create case from email
//class specific to verizon email template
//Email Service Name - Verizon Partner Support

global class createCaseFromEmail implements Messaging.InboundEmailHandler{

    private static String CONTACT_EMAIL = '';
    private static String CALL_CATEGORY_FIELD = 'call_category__c';
    private static String CASE_CATEGORY_FIELD = 'case_category__c';
    private static String CASE_SEVERITY_FIELD = 'Case_Severity__c';
    private static String OBJECT_NAME = 'case';
    private static String CUSTOM_EXCEPTION_MESSAGE = null;
    private static String ETMSTicketNumber = null;
    private static String caseType = null;
    private static List<Case> duplicateCase;
    private static Boolean isVerifiedDomain = false;
    private static Boolean isException = false;
    private static Boolean isETMSTicketFormatVerified = false;
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope){

         Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Verizon').getRecordTypeId();
         List<Group> queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Support Verizon'];
         Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
         String[] fromAddressDomains;
         if(system.label.verizonFromAddress != null)
         {
           fromAddressDomains = system.label.verizonFromAddress.split(';'); 
         }
         if(system.label.VerizonContactEmailAddress != null)
         {
            CONTACT_EMAIL = system.label.VerizonContactEmailAddress;
         }
         
         try
         {
             //domain verification
             if(fromAddressDomains != null)
             {
                 for(String fromAdd: fromAddressDomains)
                 {
                     if(email.fromAddress.containsIgnoreCase(fromAdd))
                     {
                         isVerifiedDomain = true;
                         break;
                     }
                 }   
             }
             
             //subject verification
             if(isVerifiedDomain == true && email.subject != null && !email.subject.containsIgnoreCase('Vendor Ticket:') && !email.subject.containsIgnoreCase('Your email has been received')) //CMR-326464
             {
                 caseType = 'New Case';
                 String emailSubject = email.subject.trim();
                 Integer startIndex = emailSubject.indexOf('(');
                 Integer endIndex = emailSubject.indexOf(')');
                 if(startIndex != -1 && endIndex != -1)
                 {
                    ETMSTicketNumber = emailSubject.substring(startIndex + 1, endIndex).trim();
                    Pattern p = Pattern.compile('[0-9]{13}');
                    Matcher pm = p.matcher(ETMSTicketNumber);
                    if(pm.matches() && ETMSTicketNumber.length() == 13)
                    {
                        isETMSTicketFormatVerified = true;
                    }
                    else
                    {
                        isETMSTicketFormatVerified = false;
                        isException = true;
                        CUSTOM_EXCEPTION_MESSAGE = 'Verizon ETMS Ticket Number format Mismatch in subject';
                    }
                 
                 }
                 else
                 {
                    isETMSTicketFormatVerified = false;
                    isException = true;
                    CUSTOM_EXCEPTION_MESSAGE = 'Verizon ETMS Ticket Number format Mismatch in subject'; 
                 }
             }
             else if(isVerifiedDomain == true && email.subject != null && email.subject.containsIgnoreCase('Vendor Ticket:') && !email.subject.containsIgnoreCase('Your email has been received')) //CMR-326464
             {
                 caseType = 'Case - comment';
                 if(email.subject.subStringAfter('Vendor Ticket:').length() >= 8)
                 {
                     String CaseNum = email.subject.subStringAfter('Vendor Ticket:').trim().substring(0,8);
                    Pattern p = Pattern.compile('[0-9]{8}');
                    Matcher pm = p.matcher(CaseNum);
                    if(pm.matches() && CaseNum.length() == 8)
                    {
                     //CMR-336244
                     duplicateCase = [SELECT Id,Most_Recent_Subject__c,status,root_cause__c FROM Case WHERE CaseNumber = :CaseNum AND Brand_Identifier__c = 'Verizon'];
                     if(duplicateCase.size() == 0 ||duplicateCase == null || duplicateCase[0] == null){
                         isException = true;
                         CUSTOM_EXCEPTION_MESSAGE = 'No case with the given ticket number found'; 
                     }
                 } 
                    else
                    {
                   isException = true;
                   CUSTOM_EXCEPTION_MESSAGE = 'RC Ticket Number format mismatch';   
                 }
                 }
                 else
                 {
                     isException = true;
                     CUSTOM_EXCEPTION_MESSAGE = 'RC Ticket Number format mismatch';
                 }
             }
             
             //email body parsing
             if(caseType != null && caseType.equalsIgnoreCase('New Case')  && isException != true)
             {
                 // HTML Email parsing
                 String emailBody = null;
                 if(email.htmlBody != null)
                 {
                     String htmlBody = email.htmlBody;
                     emailBody = htmlBody.stripHtmlTags().trim();
                 }
                 else if(email.plainTextBody != null)
                 {
                    emailBody = email.plainTextBody.trim();
                 }
                 else if(email.htmlBody == null && email.plainTextBody == null)
                 {
                     isException = true;
                     CUSTOM_EXCEPTION_MESSAGE = 'Incoming email subject is null';
                 }
                 // new parsing logic
                 if(emailBody != null)
                 {
                     if(!emailBody.containsIgnoreCase('*Account UID:') || !emailBody.containsIgnoreCase('*Account Name:') || !emailBody.containsIgnoreCase('*Case Severity:')||
                        !emailBody.containsIgnoreCase('*Verizon Agent Name:') || !emailBody.containsIgnoreCase('*Ticket Category:') || !emailBody.containsIgnoreCase('*Trouble Type:')||
                        !emailBody.containsIgnoreCase('*How many users are impacted:') || !emailBody.containsIgnoreCase('*When was the issue discovered:') || 
                        !emailBody.containsIgnoreCase('*Were any changes recently implemented that could have caused this issue If yes, what changed and when:')||
                        !emailBody.containsIgnoreCase('*What actions have been taken so far to restore service:') ||
                        !emailBody.containsIgnoreCase('*Steps to recreate the issue (use Work Info as needed):'))
                     {
                         isException = true;
                         CUSTOM_EXCEPTION_MESSAGE = 'Email key field attributes mismatch';
                     }
                     else
                     {
                        String accountUID = emailBody.subStringBetween('*Account UID:','*Account Name:').trim(); 
                        String accountName = emailBody.substringBetween('*Account Name:', '*Case Severity:').trim();
                        String caseSeverity = emailBody.substringBetween('*Case Severity:', '*Verizon Agent Name:').trim();
                        String verizonAgentName = emailBody.substringBetween('*Verizon Agent Name:', '*Ticket Category:').trim();
                        String ticketCategory =  emailBody.substringBetween('*Ticket Category:', '*Trouble Type:').trim();
                        String troubleType =  emailBody.substringBetween('*Trouble Type:', '*How many users are impacted:').trim();
                        String issueDiscovery = emailBody.substringBetween('*When was the issue discovered:', '*Were any changes recently implemented that could have caused this issue If yes, what changed and when:').trim();
                        String recentChanges =  emailBody.substringBetween('*Were any changes recently implemented that could have caused this issue If yes, what changed and when:', '*What actions have been taken so far to restore service:').trim();
                        String actionTaken = emailBody.substringBetween('*What actions have been taken so far to restore service:', '*Steps to recreate the issue (use Work Info as needed):').trim();
                        String workInfo = emailBody.substringAfter('*Steps to recreate the issue (use Work Info as needed):').trim();
                        
                         Case newCase = new Case();
                         
                         //default case information
                         newCase.origin = 'Email';
                         newCase.subject = email.subject;
                         newCase.Most_Recent_Subject__c = email.subject;
                         newCase.Description = emailBody;
                         if(queueId[0] != null)
                         {
                             newCase.OwnerId = queueId[0].Id;
                         }
                         if(recordTypeId != null)
                         {
                             newCase.RecordTypeId = recordTypeId;
                         }
                         Id conId = getContact();
                         if(conId != null)
                         {
                             newCase.ContactId = conId;
                         }
                         
                         //Verizon ETMS Ticket Number
                         if(isETMSTicketFormatVerified == true && ETMSTicketNumber.length() == 13)
                         {
                             newCase.Partner_Case_Number__c = ETMSTicketNumber;
                         }
                         
                         //case information from email template
                         if(accountUID != null && String.isNotBlank(accountUID))
                         {
                             Id accId = getAccount(accountUID);
                             if(accId != null)
                             {
                                 newCase.AccountId = accId;
                             }
                         }
                         if(caseSeverity != null && String.isNotBlank(caseSeverity) && isPickListValuePresent(CASE_SEVERITY_FIELD, caseSeverity))
                         {
                           newCase.Case_Severity__c = caseSeverity;
                         }
                         if(verizonAgentName != null && String.isNotBlank(verizonAgentName))
                         {
                             newCase.Partner_Lead__c = verizonAgentName;
                         }
                         if(ticketCategory != null && String.isNotBlank(ticketCategory) && isPickListValuePresent(CALL_CATEGORY_FIELD,ticketCategory))
                         {
                             newCase.Call_Category__c = ticketCategory;
                         }
                         if(troubleType != null && String.isNotBlank(troubleType) && isPickListValuePresent(CASE_CATEGORY_FIELD, troubleType))
                         {
                             newCase.Case_Category__c = troubleType;
                         }
                         if(issueDiscovery != null && String.isNotBlank(issueDiscovery))
                         {
                             newCase.Issue_Discovery_Date__c = issueDiscovery;
                         }
                         if(recentChanges != null && String.isNotBlank(recentChanges))
                         {
                             newCase.Recent_Changes__c = recentChanges;
                         }
                         if(actionTaken != null && String.isNotBlank(actionTaken))
                         {
                             newCase.Action_Taken__c =  actionTaken;
                         }
                         if(workInfo != null && String.isNotBlank(workInfo))
                         {
                             newCase.Work_Info__c = workInfo;
                         }
                         newCase.Brand_Identifier__c = 'Verizon'; //CMR-336244
                         Database.SaveResult sr = Database.insert(newCase);
                         if(sr.isSuccess())
                         {
                            result.success = true; 
                         }
                         else
                         {
                             result.success = false;
                             isException = true;
                             CUSTOM_EXCEPTION_MESSAGE ='Case Insertion Error: ';
                             for(Database.Error er: sr.getErrors())
                             {
                                 CUSTOM_EXCEPTION_MESSAGE = CUSTOM_EXCEPTION_MESSAGE + ' ' + er.getMessage();
                             }
                            }
                        }  
                     }
                 }
                      
             //case comment from verizon checking, parsing and creation of new case comment
             else if(caseType != null && caseType.equalsIgnoreCase('Case - comment') && isException != true)
             {
                 String emailBody = null;
                 if(email.htmlBody != null)
                 {
                     emailBody = email.htmlBody.stripHtmlTags();
                 }
                 else if(email.plainTextBody != null)
                 {
                     emailBody = email.plainTextBody;
                 }
                 else if(email.plainTextBody == null && email.htmlBody == null)
                 {
                     isException = true;
                     CUSTOM_EXCEPTION_MESSAGE = 'Case comment email body is null';
                 }
                 if(emailBody != null && isException != true)
                 {
                     System.debug('Case: '+duplicateCase[0]);
                     CaseComment newComment = new CaseComment();
                     if(duplicateCase.size() > 0 && duplicateCase[0] != null)
                     {
                        newComment.parentId = duplicateCase[0].Id;
                        newComment.CommentBody = emailBody + '\nNote: This comment was added by Verizon';
                        if(newComment != null)
                        {
                            insert newComment;
                        }
                     }
                 }
                 if(email.subject != null && duplicateCase.size()>0 && duplicateCase[0] != null && duplicateCase[0].most_recent_subject__c != email.subject && isException != true)
                 {
                     if(email.subject != null && email.subject.containsIgnoreCase('Re:'))
                     {
                         duplicateCase[0].most_recent_subject__c = email.subject.subStringAfter('Re:');
                     }
                     else
                     {
                        duplicateCase[0].most_recent_subject__c = email.subject;
                     }
                     if(duplicateCase[0].most_recent_subject__c != null)
                     {
                        update duplicateCase[0]; 
                     }
                 }
                 
                 //Case resolution denied by verizon automatically changes case status from waiting to work in progress
                 if(emailBody != null && emailBody.containsIgnoreCase('Verification Status: denied') && duplicateCase.size()>0 && duplicateCase[0] != null && duplicateCase[0].status == 'Waiting' && isException != true)
                 {
                     duplicateCase[0].status = 'Work in Progress';
                     duplicateCase[0].root_cause__c = null;
                     update duplicateCase[0];
                 }
             }
         }
        catch(Exception e)
        {
             result.success = false;
             isException = true;
             CUSTOM_EXCEPTION_MESSAGE ='Message: '+e.getMessage()+'\n Stack trace string: ' + e.getStackTraceString();  

        }
        finally
        {
            if(isException == true)
            {
                Exception_And_Notification_History__c verizonExc = new Exception_And_Notification_History__c();
                verizonExc.Email_Subject__c = email.subject;
                verizonExc.Email_Body__c = email.plainTextBody;
                verizonExc.Exception__c = 'Verizon E-Bonding error';
                if(CUSTOM_EXCEPTION_MESSAGE == null)
                {
                    verizonExc.stackTraceString__c = 'Unknown Error'; 
                }
                else
                {
                    verizonExc.stackTraceString__c = CUSTOM_EXCEPTION_MESSAGE;
                }
                if(verizonExc != null)
                {
                    String errorEmailBody = null;
                    if(CUSTOM_EXCEPTION_MESSAGE == 'Verizon ETMS Ticket Number format Mismatch in subject' ||
                       CUSTOM_EXCEPTION_MESSAGE == 'Email key field attributes mismatch')
                    {
                        errorEmailBody = '<b>Error Summary: </b>Case Creation Failure.<br/><br/> <b>Error Details: </b>'+CUSTOM_EXCEPTION_MESSAGE;
                    }
                    else if(CUSTOM_EXCEPTION_MESSAGE == 'No case with the given ticket number found' ||
                            CUSTOM_EXCEPTION_MESSAGE == 'RC Ticket Number format mismatch' ||
                            CUSTOM_EXCEPTION_MESSAGE == 'Case comment email body is null')
                    {
                        errorEmailBody = '<b>Error Summary: </b>Case Comment Update Failure.<br/><br/> <b>Error Details:</b> '+CUSTOM_EXCEPTION_MESSAGE;
                    }
                    if(errorEmailBody != null)
                    {
                        Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage();
                        String[] toAddress = system.label.VerizonRecipients.split(';');
                    
                        if(email.subject != null)
                        {
                            errorEmail.subject = email.subject + ' E-Bonding Error';
                        }
                        errorEmail.toAddresses = toAddress;
                        errorEmail.setHtmlBody(errorEmailBody);
                        errorEmail.setOrgWideEmailAddressId([SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com' LIMIT 1].Id);
                        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {errorEmail};
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                        if (results[0].success) 
                        {
                            verizonExc.isEmailSent__c = true;
                        } 
                        else 
                        {
                            verizonExc.isEmailSent__c = false;
                        }
                    }
                    insert verizonExc;
                }
             }
        }
        return result;
     }
    
    private Id getAccount(String accountUid){
        
        List<Account> accId = [SELECT Id FROM Account WHERE RC_User_ID__c =: accountUid];
        if(accId.size()>0){ //CMR-326464
            return accId[0].Id;
        }
        return null;
        
    }
    
    private Id getContact(){
        
        List<Contact> conId = [SELECT Id FROM Contact WHERE Email = :CONTACT_EMAIL];
        if(conId.size()>0){ //CMR-326464
            return conId[0].Id;  
        }
        return null;
        
    }
    
    private Boolean isPickListValuePresent(String fieldName,String value){
        
        Map<String,String> pickListValueMap = new Map<String,String>();
        
        try{
            if(OBJECT_NAME != null && fieldName != null && value != null)
            {
                List<Schema.PicklistEntry> pickListValues = ((SObject)Type.forName(OBJECT_NAME).newInstance()).getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().getPickListValues();
                if(pickListValues != null)
                {
                    for(Schema.PicklistEntry val: pickListValues)
                    {
                        pickListValueMap.put(val.getLabel(),val.getValue());
                    }
                }        
            }
            if(pickListValueMap != null && pickListValueMap.containsKey(value))
            {
                return true;
            }
        }
        catch(Exception e)
        {}
        
        return false;
    }
}