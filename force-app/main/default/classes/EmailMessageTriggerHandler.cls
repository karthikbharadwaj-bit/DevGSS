public with sharing class EmailMessageTriggerHandler {
    public class EmailMessageBefore extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Profile objProfile =null;
            Profile adminProfile =null;
            for(Profile objProf:[SELECT p.Name FROM Profile p WHERE id = :UserInfo.getProfileId()]) {
                if(objProf!=null) {
                    objProfile =objProf;
                }
            }
            if(System.Test.isRunningTest()) {
                objProfile = [SELECT Name FROM Profile WHERE Name = 'Sales Rep - Lightning' LIMIT 1];
            }
            adminProfile = [SELECT Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
            if(Trigger.isDelete) {
                for(EmailMessage objEmailMessage : (List<EmailMessage>) Trigger.old) {
                    //CHECK IF RECORD IS EXEC SPONSORSHIP AND ACTIVITY ID IS NULL
                    if(!String.isBlank(objEmailMessage.Subject) && objEmailMessage.subject.contains('Executive Sponsorship') && objEmailMessage.activityid == null){
                        objProfile = adminProfile;
                    }
                    if(objProfile !=null && objProfile.Name!='System Administrator') {
                        objEmailMessage.addError('You do not have permission to delete this record,'
                                                + ' please contact your system administrator.');
                    }
                }
            }

            /*Engage Digital Email to Case*/
            Set<Id> setCaseIds = new Set<Id>();
            Map<Id,Case> mapEmailMsgToCase = new Map<Id, Case>();
            List<Case> updCaseList = new List<Case>();
            List<Case> closeCaseList = new List<Case>();
            List<String> fromAddressList = new List<String>();

            if(Trigger.isInsert){
                for(EmailMessage emailMsg : (List<EmailMessage>)Trigger.new){
                    if(emailMsg.ParentId != null && AquivaHelper.getObjectNameById(emailMsg.ParentId) == 'Case'){
                        setCaseIds.add(emailMsg.ParentId);
                    }
                }

                if(setCaseIds.size() > 0 ){
                    mapEmailMsgToCase = new Map<Id, Case>([SELECT Id, Status, Engage_Case_Type__c, IsClosed, Cx_Replied_on_Closed_Case__c, ContactId, Original_RecordType__c, Brand_Account__c, Origin
                        FROM CASE WHERE Id = :setCaseIds]);
                }

                for(EmailMessage emailMsg : (List<EmailMessage>)Trigger.new){
                    if(emailMsg.ParentId != null && emailMsg.Incoming && ((emailMsg.Subject != null && emailMsg.Subject.contains('ref:_')) || (emailMsg.TextBody != null && emailMsg.TextBody.contains('ref:_'))) && !mapEmailMsgToCase.isEmpty() && mapEmailMsgToCase.containsKey(emailMsg.ParentId) && mapEmailMsgToCase.get(emailMsg.ParentId).Engage_Case_Type__c != null && mapEmailMsgToCase.get(emailMsg.ParentId).Engage_Case_Type__c.contains('Digital case')){
                        if(mapEmailMsgToCase.get(emailMsg.ParentId).IsClosed){
                            mapEmailMsgToCase.get(emailMsg.ParentId).Cx_Replied_on_Closed_Case__c += 1;
                            closeCaseList.add(mapEmailMsgToCase.get(emailMsg.ParentId));
                            fromAddressList.add(emailMsg.FromAddress);
                        }else{
                            mapEmailMsgToCase.get(emailMsg.ParentId).Status = 'Updated by Customer';
                            mapEmailMsgToCase.get(emailMsg.ParentId).Last_Customer_Update__c = Datetime.now();
                        }
                        updCaseList.add(mapEmailMsgToCase.get(emailMsg.ParentId));
                    }
                    // Now we apply logic to handle the signature change for BT cases
                    if (emailMsg.ParentId != null && mapEmailMsgToCase.containsKey(emailMsg.ParentId)) {
                        // Check if the email body matches the Web-to-Case template (Old BT Portal)
                        if (CaseCommentHelperForOutboundEmails.isEmailMatchingTemplate(emailMsg, 'Web-to-Case (Sample)')) {
                            Case relatedCase = mapEmailMsgToCase.get(emailMsg.ParentId);
                            // Query the number of email messages for this case to check if it's the first email for Old BT Portal
                            Integer emailCount = [SELECT COUNT() FROM EmailMessage WHERE ParentId = :relatedCase.Id];                           
                            // Check if this is a BT Business case (Support Case, Origin as Web, and Brand as BT Business)
                            if (relatedCase.Original_RecordType__c == 'Support_Case' 
                                && relatedCase.Origin == 'Web' 
                                && relatedCase.Brand_Account__c == 'BT Business' && emailCount == 0) {                                    
                                    // Ensure the email body exists before replacing
                                    String emailBody = emailMsg.HtmlBody;                                    
                                    // Check if the default signature exists and replace it
                                    if (emailBody != null && emailBody.contains('RingCentral Customer Service')) {
                                        // Replace the signature with BT Business
                                        String newSignature = 'The BT Cloud Work team';  // New signature for BT Business cases                                        
                                        // Perform the replacement
                                        emailBody = emailBody.replace('RingCentral Customer Service', newSignature);                                        
                                        // Update the email message HtmlBody
                                        emailMsg.HtmlBody = emailBody;
                                    }
                                }
                        }
                    }
                }

                if(!updCaseList.isEmpty()){
                    update updCaseList;
                }

                if(!closeCaseList.isEmpty()){
                    CaseHelper.sendEmail('RC_EDS_Closed_Case', closeCaseList, fromAddressList);
                }
            }
        }
    }
    public class EmailMessageAfter extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if(Trigger.isInsert && Trigger.isAfter){
                if(!Test.isRunningTest()){
                    handleExecNotifTracking(Trigger.newmap.keySet()); //TEST CLASS: ExecSupportNotification_Test
                }
            }

            if (!Trigger.isDelete) {
                Map<Id, EmailMessage[]> emailMessageByParentId = new Map<Id, EmailMessage[]>();
                EmailMessage[] emailMessagesRelatedToACase = new EmailMessage[]{};

                for (EmailMessage emailMess : (EmailMessage[]) Trigger.new) {
                    if (emailMess.parentId?.getSObjectType() == Case.SObjectType) {
                        if(!emailMessageByParentId.containsKey(emailMess.parentId)){
                            emailMessageByParentId.put(emailMess.parentId, new EmailMessage[]{});
                        }
                        emailMessageByParentId.get(emailMess.parentId).add(emailMess);
                        emailMessagesRelatedToACase.add(emailMess);
                    }
                }

                if (emailMessageByParentId.size() > 0 ) {
                    Case[] clfCases = getCloseLoopMedalliaFeedbackCases(emailMessageByParentId.keySet());
                    if (clfCases.size() > 0) {
                        createCaseCommentsForCLPCases(clfCases, emailMessageByParentId);
                        updateCaseStatusToUpdatedByCustomer(clfCases, emailMessageByParentId);
                    }
                }
            }
        }

        private void updateCaseStatusToUpdatedByCustomer(Case[] clfCases, Map<Id, EmailMessage[]> emailMessageByParentId) {
            Case[] casesToUpdate = new Case[]{};
            for (Case clfCase : clfCases) {
                if(!clfCase.IsClosed) {
                    for (EmailMessage emailMess : emailMessageByParentId.get(clfCase.Id)) {
                        if (emailMess.Incoming) {
                            casesToUpdate.add(new Case(
                                Id = clfCase.Id,
                                Status = CaseHelper.CASE_STATUS_UPDATED_BY_CUSTOMER
                            ));
                            break;
                        }
                    }
                }
            }
            if (!casesToUpdate.isEmpty()) {
                List<Database.SaveResult> updateResults = Database.update(casesToUpdate, false);
                PlatformLog.logErrors('EmailMessageTriggerHandler - updateCaseStatusToUpdatedByCustomer', updateResults, casesToUpdate);
            }
        }

        private Case[] getCloseLoopMedalliaFeedbackCases(Set<Id> caseIds) {
            return (Case[]) new CaseSelector()
                .selectCasesByIdsAndRecordTypes(new Object[]{caseIds,new String[]{CaseHelper.RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP}})
                .executeQuery();
        }

        private void createCaseCommentsForCLPCases(Case[] clfCases, Map<Id, EmailMessage[]> emailMessageByParentId) {
            CaseComment[] caseComments = new CaseComment[]{};
            for (Case clfCase : clfCases) {
                for (EmailMessage email : emailMessageByParentId.get(clfCase.Id)) {
                    caseComments.add(new CaseComment(
                        ParentId = clfCase.Id,
                        CommentBody = email.TextBody.substringBefore('________________________________')
                    ));
                }
            }
            if (caseComments.size() > 0) {
                Database.SaveResult[] saveResults = Database.insert(caseComments,false);
                List<PlatformLog__c> platformLogToInsert = new  List<PlatformLog__c>();
                for (Integer i = 0; i < saveResults.size(); ++i) {
                    if (!saveResults[i].isSuccess()) {
                        for (Database.Error error : saveResults[i].getErrors()) {
                            platformLogToInsert.add(PlatformLog.buildLog(
                            'EmailMessageTriggerHandler - createCaseCommentsForCLPCases. Case ID: '+ caseComments[i].parentId,
                            error.getMessage(),
                            null, null, null
                            ));
                        }
                    }
                }

                if(!platformLogToInsert.isEmpty()){
                    insert platformLogToInsert;
                }
            }
        }
    }
    public static void handleExecNotifTracking(Set<Id> newRecs){
        //ITEA-633 Competitive Deal E-Staff Notification
        //TEST CLASS: ExecSupportNotification_Test
        List <String> threadIds = new List <String>();
        Map <String, EmailMessage> msgIdSourceMsg = new Map <String, EmailMessage>();
        Map <Id, Task> oppIDSourceTask = new Map<Id, Task>();
        Map <String, EmailMessage> msgToClone = new Map<String, EmailMessage>();
        Map <String, Task> taskToInsert = new Map<String, Task>();
        Map <Id, Task> taskMap = new Map<Id, Task>();
        //Map <Id, Attachment> attachmentMap = new Map<Id, Attachment>([SELECT SystemModstamp, ParentId, OwnerId, Name, LastModifiedDate, LastModifiedById, IsPrivate, IsDeleted,
        //                                                              Id, Description, CreatedDate, CreatedById, ContentType, BodyLength, Body from attachment]);
        //List<Id> casesToDelete = new List<Id>();
        List<EmailMessage> msgToDelete = new List<EmailMessage>();
        List<EmailMessage> msgToInsert = new List<EmailMessage>();
        List<EmailMessage> msgToUpdate = new List<EmailMessage>();
        List<Task> taskToUpdate = new List<Task>();
        //List<Task> taskToInsert = new List<Task>();
        for(EmailMessage newMsg : [SELECT Id, ThreadIdentifier FROM EmailMessage WHERE Id =:newRecs]){
            if(newMsg.ThreadIdentifier != null){
                threadIds.add(newMsg.ThreadIdentifier);
            }
        }
        if(!threadIds.isEmpty()){
            for(EmailMessage srcMsg: [SELECT id, MessageIdentifier, ThreadIdentifier, activityid, htmlbody
                                      FROM EmailMessage
                                      WHERE Subject like '%Executive Sponsorship Requested%'
                                      AND Incoming = false
                                      AND MessageIdentifier =:threadIds
                                      order by createddate desc]){
                                          msgIdSourceMsg.put(srcMsg.threadidentifier, srcMsg);

                                      }
        }
        for(Task t: [SELECT Id, WhatId, description FROM Task where subject like 'Email: Executive Sponsorship Requested%' order by createddate asc]){
            oppIDSourceTask.put(t.whatId, t);
            taskMap.put(t.Id, t);
        }
        //system.debug(Trigger.newmap.keyset());
        for(EmailMessage newMsg : [SELECT Id, ThreadIdentifier, MessageIdentifier,
                                   BccAddress, CcAddress, FromAddress, FromName, HasAttachment,
                                   Headers, HtmlBody, Incoming, IsExternallyVisible, MessageDate,
                                   ReplyToEmailMessageId, Status, Subject, TextBody, ToAddress, /*ValidatedFromAddress,*/ parentid, activityid,
                                   (SELECT Id FROM Attachments) FROM EmailMessage WHERE Id =:newRecs]){
             if(newMsg.Subject.contains('Executive Sponsorship Requested')){
                 System.debug(newMsg.id);
                 //source message
                 if(newMsg.MessageIdentifier == newMsg.ThreadIdentifier && newMsg.Incoming == true){
                     Id oppId = null;
                     if(!String.isEmpty(newMsg.HtmlBody)){
                         String domainURL= URL.getOrgDomainUrl().toExternalForm() + '/';
                         String domainURLAlt = URL.getOrgDomainUrl().toExternalForm().replace('http:', 'https:') + '/';
                         oppId = newMsg.HtmlBody.contains(domainURL) ==true? newMsg.HtmlBody.substringafter(domainURL).substringbefore('">') : newMsg.HtmlBody.substringafter(domainURLAlt).substringbefore('">');
                     }
                     EmailMessage cloneMsg = newMsg.clone(false, true);
                     cloneMsg.status = '1';
                     cloneMsg.ActivityId = oppIDSourceTask.get(oppId) != null? oppIDSourceTask.get(oppId).id : null;
                     cloneMsg.Incoming = false;
                     cloneMsg.parentId = newMsg.ParentId;
                     //cloneMsg.subject = oppId;
                     msgToInsert.add(cloneMsg);

                     msgToDelete.add(newMsg);
                 }
                 else{
                     if(newMsg.MessageIdentifier != newMsg.ThreadIdentifier && newMsg.ActivityId == null){
                         //FIND SRC MESSAGE
                         //CREATE TASK WITH WHATID = SRCMSG.ACTIVITYID.WHATID

                         EmailMessage srcMsg = msgIdSourceMsg.get(newMsg.ThreadIdentifier);
                         system.debug(srcMsg);
                         if(srcMsg != null){
                             Id oppId = null;
                             if(!String.isEmpty(srcMsg.HtmlBody)){
                                 String domainURL= URL.getOrgDomainUrl().toExternalForm() + '/';
                                 String domainURLAlt = URL.getOrgDomainUrl().toExternalForm().replace('http:', 'https:') + '/';
                                 oppId = srcMsg.HtmlBody.contains(domainURL) ==true? srcMsg.HtmlBody.substringafter(domainURL).substringbefore('">') : srcMsg.HtmlBody.substringafter(domainURLAlt).substringbefore('">');
                             }
                             Task t = new Task();
                             t.Subject = 'Email: ' + newMsg.Subject;
                             t.Description = newMsg.Textbody;
                             t.WhatId = oppId;
                             t.tasksubtype = 'email';
                             t.status = 'Completed';
                             t.ActivityDate = system.today();
                             taskToInsert.put(newMsg.messageidentifier, t);
                             msgToClone.put(newMsg.MessageIdentifier, newMsg);
                             //taskMsg.put(t, newMsg);
                         }
                     }

                 }

             }
        }
        system.debug(tasktoInsert);
        Database.insert(taskToInsert.values());
        /*system.debug([SELECT Id FROM EmailMessage where parentid in :casesToDelete]);
        Database.delete([SELECT Id FROM Case WHERE Id in :casesToDelete]);*/

        for(String msgId: msgToClone.keySet()){
            EmailMessage newMsg = msgToClone.get(msgId);
            if(newMsg != null){
                EmailMessage cloneMsg = newMsg.clone(false, true);
                cloneMsg.status = '1';
                cloneMsg.ActivityId = taskToInsert.get(msgId).Id;
                cloneMsg.Incoming = false;
                cloneMsg.parentId = newMsg.ParentId;
                //cloneMsg.subject = oppId;
                msgToInsert.add(cloneMsg);
                taskMap.put(taskToInsert.get(msgId).Id, taskToInsert.get(msgId));
            }
            if(newMsg.HasAttachment == true){
                newMsg.Subject = 'FOR DELETE ' + newMSg.Subject;
                msgtoUpdate.add(newMsg);
            }
            else{
                msgToDelete.add(new EmailMessage(Id = newMsg.Id));
                //casesToDelete.add(newMsg.relatedToId);
            }
        }


        system.debug(msgToInsert);
        Database.insert(msgToInsert);

        system.debug(msgToDelete);
        Database.delete(msgToDelete);

        system.debug(msgToUpdate);
        Database.update(msgToUpdate);

        for(EmailMessage newMSg: msgToInsert){
            Task t = taskMap.get(newMsg.ActivityId);
            if(t != null){
               t.description = 'Email contents logged in tasks are in plain-text. To view the HTML version, see the Email Message: ' + URL.getOrgDomainUrl().toExternalForm() + '/' + newMsg.id + '\n\n' + t.description;
                taskToUpdate.add(t);
            }
        }
        Database.update(taskToUpdate);
    }

    public static void handleAttachmentsExecSupport(Set<Id> attIds){
        //TEST CLASS: ExecSupportNotification_Test
        List <Id> parentIds = new List<Id>();
        List <String> threadIds = new List<String>();
        Map <String, EmailMessage> msgIdCloneMsg = new Map <String, EmailMessage>();
        Map <Id, EmailMessage> parentMsgMap = new Map <Id, EmailMessage>();
        List<Id> msgToDelete = new List<Id>();
        //List<Id> caseToDelete = new List<Id>();
        List<Attachment> attToInsert = new List<Attachment>();

        for(Attachment att: [SELECT Id, parentId FROM Attachment WHERE Id =: attIds]){
            parentIds.add(att.parentId);
        }

        if(!parentIds.isEmpty()){
            for(EmailMessage parentMsg: [SELECT id, MessageIdentifier, ThreadIdentifier
                                    FROM EmailMessage
                                    WHERE Subject like '%Executive Sponsorship Requested%'
                                    AND Subject like 'FOR DELETE%'
                                    AND Id =: parentIds
                                    ]){
                                        parentMsgMap.put(parentMsg.Id, parentMsg);
                                        if(parentMsg.threadIdentifier != null){
                                            threadIds.add(parentMsg.threadIdentifier);
                                        }
                                    }
        }
        if(!threadIds.isEmpty()){
            for(EmailMessage cloneMsg: [SELECT id, MessageIdentifier, ThreadIdentifier, activityid
                                        FROM EmailMessage
                                        WHERE Subject like '%Executive Sponsorship Requested%'
                                        and (not subject like '%FOR DELETE%')
                                        AND ThreadIdentifier =: threadIds
                                        ]){
                                            msgIdCloneMsg.put(cloneMsg.MessageIdentifier, cloneMsg);

                                        }
        }
        for(Attachment att: [SELECT SystemModstamp, ParentId, OwnerId, Name, LastModifiedDate, LastModifiedById, IsPrivate, IsDeleted,
                                    Id, Description, CreatedDate, CreatedById, ContentType, BodyLength, Body, parent.type
                            FROM attachment WHERE ID IN :attIds]){
            if(att.parentid != null){
                if(att.parent.type == 'EmailMessage'){
                    //get the parent here
                    EmailMessage parent = parentMsgMap.get(att.parentid);
                    if(parent != null){
                        msgToDelete.add(att.parentId);
                        //caseToDelete.add(parent.relatedtoid);

                        Attachment cloneAtt = att.clone(false, true);
                        cloneAtt.parentId = msgIdCloneMsg.get(parent.MessageIdentifier).id;
                        attToInsert.add(cloneAtt);

                        Attachment cloneAtt2 = att.clone(false, true);
                        cloneAtt2.parentId = msgIdCloneMsg.get(parent.MessageIdentifier).activityid;
                        attToInsert.add(cloneAtt2);
                    }
                }

            }

        }
        Database.insert(attToInsert);
        Database.delete(msgToDelete);
        //Database.delete(caseToDelete);
    }

    /**
     * QTC-792 Added for parsing text body from emails received through Active Eyes E2C
     */
    public class EmailMessageAfterCreateCase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if(Trigger.isInsert && Trigger.isAfter){
                List<Case> caseList = new List<Case>();
                for(EmailMessage emailMsg : (List<EmailMessage>)Trigger.new){
                    if (emailMsg.Incoming && emailMsg.ToAddress == System.Label.Active_Eyes_E2C_Address) {
                        caseList.add(parseEmailBody(emailMsg));
                    }
                }
                if (!caseList.isEmpty()) {
                    Set<Id> accIds = new Set<Id>();
                    for (Case caseVal : caseList) {
                        accIds.add(caseVal.AccountId);
                    }
                    Map<Id,Id> accContactMap = lookUpContact(accIds); // Map<AccountId,ContactId>
                    List<String> caseSeverityPickLst = getPicklistValues('Case', 'Case_Severity__c');
                    Map<String,String> caseSevMap = new Map<String,String>();
                    for (String caseSev : caseSeverityPickLst) {
                        String caseSevNum = '';
                        Pattern p = Pattern.compile('([0-9]+)');
                        Matcher pm = p.matcher( caseSev );
                        if( pm.find() ){
                            try {
                                caseSevNum = pm.group(1);
                            } catch(Exception e) {
                                System.debug('Error occurred ' + e.getMessage());
                            }
                            if(!caseSevMap.containsKey(caseSevNum)) {
                                caseSevMap.put(caseSevNum,caseSev);
                            }
                        }
                    }
                    for (Case caseRec : caseList) {
                        System.debug('caseRec.Case_Severity__c before ' + caseRec.Case_Severity__c);
                        Pattern p = Pattern.compile('([0-9]+)');
                        Matcher pm = p.matcher(caseRec.Case_Severity__c);
                        String caseSevNum = '';
                        if( pm.find() ){
                            try {
                                caseSevNum = pm.group(1);
                            } catch(Exception e) {
                                System.debug('Error occurred ' + e.getMessage());
                            }
                            if(caseSevNum != '' && caseSevMap.keySet().size() > 0 && caseSevMap.containsKey(caseSevNum)) {
                                    caseRec.Case_Severity__c = caseSevMap.get(caseSevNum);
                                    System.debug('caseRec.Case_Severity__c after ' + caseRec.Case_Severity__c);
                                }
                            }
                        if (accContactMap.keySet().size() > 0) {
                            if (accContactMap.containsKey(caseRec.AccountId)) {
                                caseRec.ContactId = accContactMap.get(caseRec.AccountId);
                            }
                        }
                    }
                    Database.update(caseList,false);
                }
            }
        }
        public List<String> getPicklistValues(String objectName, String fieldName) {
            List<String> values = new List<string>();
            List<Schema.PicklistEntry> PicklistValues = ((SObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues();
            for( Schema.PicklistEntry PicklistValue : PicklistValues){
                values.add(string.valueof(PicklistValue.getValue()));
            }
            return values;
        }

        public Case parseEmailBody(EmailMessage email) {
            Case c = new Case();
            c.Id = email.parentId;
            System.debug('Case ID' + email.parentId);

            if(email.parentId != null && email.TextBody != null && email.TextBody != ''){
                c.description = email.TextBody;
                String[] emailBodyRows = email.TextBody.split('\n');
                String PIIFields = '';


                for (String bodyRow:emailBodyRows) {
                  String[] rowContents = bodyRow.split(':', 2);
                  String label = rowContents.size() > 0 ? rowContents[0].trim().toLowerCase() : '';
                  String value = rowContents.size() > 1 ? rowContents[1].trim() : '';

                  switch on label {
                      when 'record id' {
                          c.AccountId = value;
                      }
                      when 'severity level' {
                          c.Case_Severity__c = value; // find exact value from picklist
                      }
                      when 'customer email' {
                          String subStr = value.substringAfter('<mailto');
                          c.Alternate_Email__c = value.replaceAll('\\<mailto:(.*)','');
                          PIIFields = bodyRow;
                      }
                    }
                    }
                    c.description = excludePIIFields(c.description, PIIFields);
                }
                return c;
        }

        public string excludePIIFields(String source, String removeStr) {
            return String.isNotBlank(source) ? source.remove('\n' + removeStr) : source;
        }

        public Map<Id,Id> lookUpContact(Set<Id> accId) {
            Map<Id,Id> accContactMap = new Map<Id,Id>();
            List<Account> accList = [SELECT Id, (SELECT Id from Contacts limit 1) from Account where Id IN :accId];
            for(Account a : accList) {
                if(!accContactMap.containskey(a.Id)) {
                    List<Contact> conList = (List<Contact>)a.Contacts;
                    if (conList.size() > 0) {
                        accContactMap.put(a.Id, conList[0].Id);
                    }
                }
            }
            return accContactMap;
        }
    }

    public class PopulateFirstMessageDateOnRelatedCase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, EmailMessage> caseToFirstEmailMap = new Map<Id, EmailMessage>();
            for (EmailMessage emailMsg : (List<EmailMessage>) Trigger.new) {
                if (!caseToFirstEmailMap.containsKey(emailMsg.ParentId)
                    || (caseToFirstEmailMap.containsKey(emailMsg.ParentId)
                    && caseToFirstEmailMap.get(emailMsg.ParentId).MessageDate < emailMsg.MessageDate)
                    ) {
                    caseToFirstEmailMap.put(emailMsg.ParentId, emailMsg);
                }
            }

            if (!caseToFirstEmailMap.keySet().isEmpty()) {
                List<Case> casesForUpdate = new List<Case>();
                List<Case> cases = (List<Case>) new CaseSelector()
                    .selectCasesByIds(caseToFirstEmailMap.keySet())
                    .executeQuery();

                if (!cases.isEmpty()) {
                    for (Case cs : cases) {
                        if (cs.FirstResponseTime__c != null) {
                            continue;
                        }
                        casesForUpdate.add(new Case(
                            Id = cs.Id,
                            FirstResponseTime__c = HelperUtils.getTimeBetweenDates(cs.CreatedDate, caseToFirstEmailMap.get(cs.Id).MessageDate)
                        ));
                    }
                }
                if (!casesForUpdate.isEmpty()) {
                    TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
                    update casesForUpdate;
                }
            }
        }
    }
    //Included as part of PBC-20631 - Add Automated Emails from CNR Flow as Case Comments on Case
	public class CreateCaseCommentsForEmailsFromStandardCNRFlow extends Triggers.TriggerHandlerBase {
        override public void handle() {
            String FROM_NAME_OF_CNR_CASE = 'RingCentral Technical Support';
            if(Trigger.isInsert && Trigger.isAfter) {
                List<CaseComment> caseComments=new List<CaseComment>();
                List<Id> caseIds = new List<Id>();
                CNR_Case_Condition__c cnrCaseCondition = CNR_Case_Condition__c.getOrgDefaults();
                List<String> brands = cnrCaseCondition.Brands__c!=null ? cnrCaseCondition.Brands__c.split(',') : new List<String>();
	            List<String> recordtypes = cnrCaseCondition.RecordTypes__c != null ? cnrCaseCondition.RecordTypes__c.split(',') : new List<String>();
                for(EmailMessage emailMsg : (List<EmailMessage>)Trigger.new) {
                    if (emailMsg.FromName == FROM_NAME_OF_CNR_CASE && !emailMsg.Subject.contains('thread')) {
                    	caseIds.add(emailMsg.ParentId);
                    }
                }
                if(caseIds.size()>0){
                    Map<Id,Case> caseMap = new Map<Id,Case>([Select Id,RecordTypeName__c,Brand_Account__c from Case 
                                                         where Id in :caseIds 
                                                         and RecordTypeName__c in :recordtypes
                                                         and Brand_Account__c in :brands
                                                         ]);
                    if(caseMap.size() > 0){
                         for(EmailMessage emailMsg : (List<EmailMessage>)Trigger.new) {
                             if(caseIds.contains(emailMsg.ParentId)){
                                        caseComments.add(new CaseComment(
                                            ParentId = emailMsg.ParentId,
                                            CommentBody = emailMsg.TextBody,
                                            IsPublished = false
                                        ));
                             }
                         }
                    }
                    if (caseComments.size() > 0) {
                         insert caseComments;
                    }
                }  
            }
        }
	}
    //Included as part of PBC-21492 and PBC-21738 - Add Automated Emails from Partner CNR Flow as Case Comments on Case
    public class CreateCaseCommentsForEmailsFromPartnerCNRFlow extends Triggers.TriggerHandlerBase {
        override public void handle() {
			String HIDDEN_TEXT = 'CNR_FOLLOWUP';
            List<String> fromAddresses = new List<String>();
            List<CaseComment> caseComments=new List<CaseComment>();
            
            for(Partner_CNR_setting__mdt  setting: [select Sender_email__c from Partner_CNR_setting__mdt ]){
                if(!fromAddresses.contains(setting.Sender_email__c)){
                    fromAddresses.add(setting.Sender_email__c);
                }
            }
            
        	if(Trigger.isInsert && Trigger.isAfter) {
                for(EmailMessage emailMsg : (List<EmailMessage>)Trigger.new) {
                    if(emailMsg.HtmlBody!= null && emailMsg.HtmlBody.contains(HIDDEN_TEXT) && fromAddresses.contains(emailMsg.fromAddress)) {
                        caseComments.add(new CaseComment(
                                            ParentId = emailMsg.ParentId,
                                            CommentBody = emailMsg.TextBody,
                                            IsPublished = false));
                    }
                }
            }
            
            if (caseComments.size() > 0) {
                insert caseComments;
            }
        }
    }

    /**
    * Included as part of PBC-25253 - Creation of public case comments for BT case emails.
    */
    public class CreateCaseCommentsForBTCaseEmails extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Integer MAX_COMMENT_LENGTH = CaseCommentHelperForOutboundEmails.getMaxCommentLength(); // Fetch max length for comments
            
            if (Trigger.isInsert && Trigger.isAfter) {
                Map<Id, EmailMessage> emailByCaseId = new Map<Id, EmailMessage>(); // Collecting email by case ID
                
                // Step 1: Filter outgoing emails linked to cases
                for (EmailMessage email : (List<EmailMessage>) Trigger.new) {
                    if (!email.Incoming && email.ParentId != null && String.valueOf(email.ParentId).startsWith('500')) {
                        emailByCaseId.put(email.ParentId, email);
                    }
                }
                
                if (emailByCaseId.isEmpty()) {
                    return; // No relevant emails to process
                }
                
                // Step 2: Query Cases that match BT Business
                Map<Id, Case> matchingCases = new Map<Id, Case>([
                    SELECT Id, Original_RecordType__c, Brand_Account__c
                    FROM Case
                    WHERE Id IN :emailByCaseId.keySet()
                    AND Original_RecordType__c = 'Support_Case'
                    AND Origin = 'Web'
                    AND Brand_Account__c = 'BT Business'
                ]);
                
                if (matchingCases.isEmpty()) {
                    return; // No matching BT cases
                }
                
                // Step 3: Prepare a list of emails and cases to be passed to CaseCommentHelperForOutboundEmails
                Map<Id, EmailMessage> validEmailMessages = new Map<Id, EmailMessage>();
                
                for (EmailMessage emailMsg : (List<EmailMessage>) Trigger.new) {
                    if (emailMsg.ParentId != null && emailByCaseId.containsKey(emailMsg.ParentId)) {
                        Case caseRecord = matchingCases.get(emailMsg.ParentId);
                        
                        // Check if it's the first email for the BT case and if the email subject contains the Default Web-to-Case template                       
                        if (isFirstEmailForBTCase(caseRecord.Id) && 
                            CaseCommentHelperForOutboundEmails.isEmailMatchingTemplate(emailMsg, 'Web-to-Case (Sample)')) {
                                // Skip processing for the Default Web-to-Case email template and prevent email sending                                
                                continue; // Skip creating case comment and email sending
                            }
                        
                        // Collect valid email messages to pass to CaseCommentHelperForOutboundEmails
                        validEmailMessages.put(emailMsg.ParentId, emailMsg);
                    }
                }
                
                // Step 4: Call CaseCommentHelperForOutboundEmails to create the case comments
                if (!validEmailMessages.isEmpty()) {
                    // CaseCommentHelperForOutboundEmails will handle the insertion of the case comments
                    CaseCommentHelperForOutboundEmails.createCaseComments(validEmailMessages, matchingCases, MAX_COMMENT_LENGTH);
                }
            }
        }
        
        /**
        * Checks if this is the first email for the BT case
        * @param caseId The case Id
        * @return Boolean indicating if it's the first email
         */
        private Boolean isFirstEmailForBTCase(Id caseId) {
            
            // Query to check if there are any emails associated with this case
            Integer emailCount = [SELECT COUNT() FROM EmailMessage WHERE ParentId = :caseId];
            return emailCount == 1; // If no emails are associated, it's the first email which is the default Web to Case Email for the BT Case
        }
    }
    
    
    public class CreateCaseCommentsForDevPortalEmails extends Triggers.TriggerHandlerBase {
        
        override public void handle() {
            // Fetch Case Comment Body Length
            Integer MAX_COMMENT_LENGTH = CaseCommentHelperForOutboundEmails.getMaxCommentLength();
            if (Trigger.isInsert && Trigger.isAfter) {
                Map<Id, EmailMessage> emailByCaseId = new Map<Id, EmailMessage>();
                for (EmailMessage email : (List<EmailMessage>) Trigger.new) {
                    if (!email.Incoming && email.ParentId != null && String.valueOf(email.ParentId).startsWith('500')) {
                        emailByCaseId.put(email.ParentId, email);
                    }
                }
                
                if (emailByCaseId.isEmpty()) {
                    return; // No relevant emails to process
                }
                
                // Query Cases
                Map<Id, Case> matchingCases = new Map<Id, Case>([
                    SELECT Id, Original_RecordType__c, Brand_Account__c
                    FROM Case
                    WHERE Id IN :emailByCaseId.keySet()
                    AND Original_RecordType__c = 'Developer_Platform'
                ]);
                
                if (matchingCases.isEmpty()) {
                    return; // No matching Developer Portal cases
                }
                
                // Call common utility method to create case comments
                CaseCommentHelperForOutboundEmails.createCaseComments(emailByCaseId, matchingCases, MAX_COMMENT_LENGTH);
            }
        }
    }
    
    public class CreateCaseCommentsForEmailsFromTCRCNRFlow extends Triggers.TriggerHandlerBase {
        override public void handle() {
            String UNIQUE_TEXT = 'TCR';
            List<CaseComment> caseComments = new List<CaseComment>();
            List<Id> caseIds = new List<Id>();
            
            if(Trigger.isInsert && Trigger.isAfter) {
                // Step 1: Identify TCR CNR emails by unique text
                for(EmailMessage emailMsg : (List<EmailMessage>)Trigger.new) {
                    if(emailMsg.HtmlBody != null && 
                       emailMsg.Subject.contains(UNIQUE_TEXT) && 
                       emailMsg.ParentId != null) {
                        caseIds.add(emailMsg.ParentId);
                    }
                }
                
                // Step 2: Verify parent cases are TCR cases
                if(caseIds.size() > 0) {
                    Map<Id, Case> caseMap = new Map<Id, Case>([
                        Select Id, Case_Reason__c, CNR_Status__c 
                        from Case 
                        where Id in :caseIds 
                        and Case_Reason__c = 'TCR Support'
                    ]);
                    
                    // Step 3: Create case comments for matching emails
                    if(caseMap.size() > 0) {
                        for(EmailMessage emailMsg : (List<EmailMessage>)Trigger.new) {
                            if(caseMap.containsKey(emailMsg.ParentId)) {
                                // Truncate comment body if too long
                                String commentBody = String.isNotBlank(emailMsg.TextBody) 
                                    ? emailMsg.TextBody 
                                    : 'No email body provided.';
                                
                                Integer MAX_COMMENT_LENGTH = 32000; // CaseComment max length
                                if(commentBody.length() > MAX_COMMENT_LENGTH) {
                                    commentBody = commentBody.substring(0, MAX_COMMENT_LENGTH - 3) + '...';
                                }
                                
                                caseComments.add(new CaseComment(
                                    ParentId = emailMsg.ParentId,
                                    CommentBody = commentBody,
                                    IsPublished = false // Private comment
                                ));
                            }
                        }
                    }
                }
                
                // Step 4: Insert case comments
                if (caseComments.size() > 0) {
                    insert caseComments;
                }
            }
        }
    }
    
}