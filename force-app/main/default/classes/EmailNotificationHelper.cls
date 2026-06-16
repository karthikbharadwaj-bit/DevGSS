public class EmailNotificationHelper {
    @TestVisible
    private static final String EMAIL_NOTIFICATION_HELPER_CLASS_NAME = 'EmailNotificationHelper';

    public static void sendEmailNotification(Set<Id> legalRequestIdSet, Map<Id,Legal_Requests__c> oldMap){
        List<Legal_Requests__c> updatedLegalRequestList = [SELECT id,OwnerId,Owner.Email,Owner.Name,Status__c,recordType.Name,
                                                          (SELECT id,Advisor_Name__c,Advisor_Name__r.Name,Advisor_Name__r.Email FROM Legal_Requests_Watchers__r WHERE Advisor_Name__c != NULL),
                                                          (SELECT id FROM Attachments LIMIT 1)
                                                           FROM Legal_Requests__c WHERE ID In : legalRequestIdSet];
        Id updateNotificationTemplateID;
        try{
            updateNotificationTemplateID = [SELECT id FROM EmailTemplate where Name = 'Legal Request Update Notification'].Id;
        }catch(exception e){
            if(!Test.isRunningTest()){
            	trigger.new[0].addError('Email Templates are missing.');
            }
        }

        Boolean fieldUpdated = false;
        Boolean requestSubmited = false;

        List<Messaging.SingleEmailMessage> singleEmailMessageList = new List<Messaging.SingleEmailMessage>();
        for(Legal_Requests__c requestObj : updatedLegalRequestList){
            if(
                (requestObj.Status__c == oldMap.get(requestObj.Id).Status__c)||
                (requestObj.Status__c != oldMap.get(requestObj.Id).Status__c && requestObj.Status__c != 'Submitted')
              ){
                fieldUpdated = true;
            }

            if(requestObj.Status__c != oldMap.get(requestObj.Id).Status__c && requestObj.Status__c == 'Submitted'){
                requestSubmited = true;
            }
                if(fieldUpdated){
                	if(!String.valueOf(requestObj.OwnerId).startsWith('00G')){
                    	SingleEmailMessageList.add(EmailNotificationHelper.createEmailMessage(requestObj.Owner.Name,requestObj.recordType.Name,requestObj.Id,requestObj.owner.Email));
                	}
                    if(requestObj.Legal_Requests_Watchers__r != null && requestObj.Legal_Requests_Watchers__r.size() > 0){
                        for(Legal_Requests_Watchers__c watcherObj : requestObj.Legal_Requests_Watchers__r){
                        	system.debug('name='+watcherObj.Advisor_Name__c);
                            SingleEmailMessageList.add(EmailNotificationHelper.createEmailMessage(watcherObj.Advisor_Name__r.Name,requestObj.recordType.Name,requestObj.Id,watcherObj.Advisor_Name__r.Email));
                        }
                    }
                } else {
                     boolean attachmentExsist = false;

                    if(requestObj.Attachments != NULL && requestObj.Attachments.size() > 0){
                    	attachmentExsist = true;
                    }
                    if(requestObj.Legal_Requests_Watchers__r != null && requestObj.Legal_Requests_Watchers__r.size() > 0){
                        for(Legal_Requests_Watchers__c watcherObj : requestObj.Legal_Requests_Watchers__r){
                            SingleEmailMessageList.add(createSubmitrequestEmailMessage(requestObj.Id, watcherObj.Advisor_Name__r.Name, watcherObj.Advisor_Name__r.Email,requestObj.recordType.Name,attachmentExsist));
                        }
                    }

                    SingleEmailMessageList.add(EmailNotificationHelper.createSubmitrequestEmailMessage(requestObj.Id,'Team','patents@ringcentral.com',requestObj.recordType.Name,attachmentExsist));
                }
        }
        if(SingleEmailMessageList!=null && SingleEmailMessageList.size() > 0 && !Test.isRunningTest()){
        	Messaging.sendEmail(SingleEmailMessageList);
        }
    }

    public static Messaging.SingleEmailMessage createEmailMessage(Id ownerId, Id whatId, Id templateId) {
        return createEmailMessage(ownerId, null, null, null, whatId, templateId);
    }

    public static Messaging.SingleEmailMessage createEmailMessage(Id targetObjectId, String subject, String plainTextBody) {
        return createEmailMessage(targetObjectId, subject, plainTextBody, false);
    }

    public static Messaging.SingleEmailMessage createEmailMessage(Id targetObjectId, String subject, String textBody, Boolean isHtml) {
        return isHtml
               ? createEmailMessage(targetObjectId, subject, textBody, null, null, null)
               : createEmailMessage(targetObjectId, subject, null, textBody, null, null);
    }

    public static Messaging.SingleEmailMessage createEmailMessage(Id targetObjectId, String subject, String htmlBody, String plainTextBody, Id whatId, Id templateId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(targetObjectId);
        mail.setSaveAsActivity(false);

        if (subject != null) {
            mail.setSubject(subject);
        }

        if (whatId != null) {
            mail.setWhatId(whatId);
        }

        if (templateId != null) {
            mail.setTemplateId(templateId);
        } else if (String.isNotBlank(htmlBody)) {
            mail.setHtmlBody(htmlBody);
        } else {
            mail.setPlainTextBody(plainTextBody);
        }

        return mail;
    }

    public static Messaging.SingleEmailMessage createEmailMessage(String name,String recordTypeName,String recordId,String email){
        Messaging.SingleEmailMessage mailObj = new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>{email};
      	mailObj.setToAddresses(sendTo);
      	mailObj.setSubject('Legal Request Update Notification');
      	String body = 'Hi '+name+',<br/><br/>';
		body += 'One Legal Request has been modified. Please have a look.<br/><br/>';
		if(recordTypeName == 'Invention'){
			body += '<a href="https://rc-portal.force.com/helpdesk/inventionticket?id='+recordId+'">Click Here to view Legal Request</a><br/><br/>';
		}else{
			body += '<a href="https://rc-portal.force.com/helpdesk/fossticket?id='+recordId+'">Click Here to view Legal Request</a><br/><br/>';
		}
		mailObj.setHtmlBody(body);
        return mailObj;
    }

    public static Messaging.SingleEmailMessage createSubmitrequestEmailMessage(String recordId, String name, String email, String recordTypeName, Boolean attachmentExsist){
        Messaging.SingleEmailMessage mailObj = new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>{email};
      	mailObj.setToAddresses(sendTo);
      	mailObj.setSubject('Legal Request Submit Notification');
      	String body = 'Hi '+name+',<br/><br/>';
		body += 'One Legal Request has been Submitted. Please have a look.<br/><br/>';
		if(recordTypeName == 'Invention'){
			body += '<a href="https://rc-portal.force.com/helpdesk/inventionticket?id='+recordId+'">Click Here to view Legal Request</a><br/><br/>';
		}else{
			body += '<a href="https://rc-portal.force.com/helpdesk/fossticket?id='+recordId+'">Click Here to view Legal Request</a><br/><br/>';
		}
		if(attachmentExsist){
			body += 'Note : This Legal Request has Attachments with it.<br/><br/> Thanks';
		}
		mailObj.setHtmlBody(body);
        return mailObj;
    }
    public static Messaging.SingleEmailMessage createErrorEmailMessageForCCteam(Exception e, Case affectedCase){
        String errorMessage = 'While Sync with NGBS an error has occurred.';
        String messageDetails = e.getMessage() + '<br>' + e.getStackTraceString();
        return createEmailMessageForCCteam(errorMessage, messageDetails, affectedCase);
    }

    public static Messaging.SingleEmailMessage createEmailMessageForCCteam(String message, String messageDetails, Case affectedCase){
        try{
            String oppLink = '';
            String caseLink = '';
            Messaging.SingleEmailMessage mailObj = new Messaging.SingleEmailMessage();
            OrgWideEmailAddress[] emailSender = [SELECT Id From OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];
            Emails__c[] email = [SELECT Email_Address__c From Emails__c WHERE Name = 'ccdesk'];
            if(emailSender.size() > 0 && email.size() > 0 && email[0].Email_Address__c != null){
                List<String> emailsToSend = new List<String>();
                emailsToSend.add(email[0].Email_Address__c);

                if(affectedCase != null){
                    oppLink = '<br>Opportunity details: <a href="'+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/Opportunity/'
                    + affectedCase.Opportunity_Reference__c +'/view">'+ affectedCase.Opportunity_Reference__c +'</a>';
                    caseLink = '<br>Case details: <a href="'+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/Case/'
                    + affectedCase.Id +'/view">'+ affectedCase.CaseNumber +'</a>';
                }

                String body = 'Could you please take a look?<br>' + message + '<br>Details: ' + messageDetails + oppLink + caseLink;
                mailObj.setOrgWideEmailAddressId(emailSender[0].Id);
                mailObj.setSubject(message);
                mailObj.setToAddresses(emailsToSend);
                mailObj.setHtmlBody(body);
                return mailObj;
            } else {
                System.debug('Email wasn\'t send to CCteam. Check if the email adresses are valid.');
                return null;
            }
        }catch(Exception e){
            System.debug('Email wasn\'t send to CCteam due to error - ' + e.getMessage() + '/n' + e.getStackTraceString());
            return null;
        }
    }

    public static Messaging.SingleEmailMessage createEmailMessageForCCteam(String message, String messageDetails, Opportunity affectedOpportunity, Case affectedCase){
        if(affectedCase == null) {
            String oppLink = '<br>Opportunity details: <a href="'+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/Opportunity/'
            + affectedOpportunity.Id +'/view">'+ affectedOpportunity.Name +'</a>';

            messageDetails += oppLink;
        }
        return createEmailMessageForCCteam(message, messageDetails, affectedCase);
    }

    public static void sendSingleEmailMessages(List<Messaging.SingleEmailMessage> mails) {
        handleSendEmailResult(Messaging.sendEmail(mails));
    }

    @TestVisible
    private static void handleSendEmailResult(List<Messaging.SendEmailResult> results) {
        List<PlatformLog__c> errorLogs = new List<PlatformLog__c>();
        for (Messaging.SendEmailResult result : results) {
            if (result.isSuccess()) {
                continue;
            }

            String errorMessage = '';
            for (Messaging.SendEmailError error : result.getErrors()) {
                errorMessage += error.getMessage() + '\n---\n';
            }

            errorLogs.add(PlatformLog.buildLog(EMAIL_NOTIFICATION_HELPER_CLASS_NAME, errorMessage, EMAIL_NOTIFICATION_HELPER_CLASS_NAME, null, null));
        }

        if (!errorLogs.isEmpty()) {
            Database.insert(errorLogs);
        }
    }

    public static void sendEmailNotificationToGroupMembers(String groupDeveloperName, String subject, String plainTextBody) {
        List<GroupMember> queueMembers = (List<GroupMember>) new GroupMemberSelector()
            .selectByGroupDeveloperName(groupDeveloperName)
            .executeQuery();
        if (queueMembers.isEmpty()) {
            return;
        }

        List<Id> recipients = (List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, queueMembers, String.valueOf(GroupMember.UserOrGroupId), true);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Id recipientId : recipients) {
            if (recipientId.getSobjectType() != User.sObjectType) {
                continue;
            }

            mails.add(createEmailMessage(recipientId, subject, plainTextBody));
        }

        if (!mails.isEmpty()) {
            sendSingleEmailMessages(mails);
        }
    }
    public static void sendEmail(Exception e, Case cs) {
        sendEmail(null, null, null, cs, e);
    }

    public static void sendEmail(String message, String messageDetail, Opportunity opp, Case cs) {
        sendEmail(message, messageDetail, opp, cs, null);
    }

    public static void sendEmail(
        String message,
        String messageDetail,
        Opportunity opp,
        Case cs,
        Exception e
    ) {
        Messaging.SingleEmailMessage singleEmail = e != null
            ? createErrorEmailMessageForCCteam(e, cs)
            : createEmailMessageForCCteam(message, messageDetail, opp, cs);

        sendEmail(singleEmail);
    }

    private static void sendEmail(Messaging.SingleEmailMessage singleEmail) {
        if (singleEmail == null) {
            return;
        }

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { singleEmail });
        } catch (Exception e) {
            PlatformLog.logException('CaseCreateServiceICB.createCase: SendEmail Exception', e);
        }
    }

    @future
    public static void sendEmailNotificationToProServTeamForClonedQuote(Id clonedProServQuoteId, Id originalProServQuoteId) {        
        try {
            List<Quote> quotes = new QuoteSelector()
                    .selectQuotesByIds(new List<Object>{new Set<Id>{clonedProServQuoteId, originalProServQuoteId}})
                    .executeQuery();
    
            Map<Id, Quote> quotesById = new Map<Id, Quote>(quotes);
            Quote clonedQuote = quotesById.get(clonedProServQuoteId);
            Quote originalQuote = quotesById.get(originalProServQuoteId);

            List<Case> proServCases = (List<Case>) new CaseSelector()
                .selectCaseByOpportunityAndQuoteAndRecordTypeName(
                    new List<Object>{
                        originalQuote.OpportunityId, originalQuote.MasterQuote__c, CaseHelper.RT_NAME_PROFESSIONAL_SERVICES
                    })
                .executeQuery();

            List<OrgWideEmailAddress> proServOrgWideEmailAddressList = (List<OrgWideEmailAddress>) new QueryFactory(OrgWideEmailAddress.SObjectType)
                .selectFields(new List<String>{ 'Id' })
                .setCondition('DisplayName = :bind0')
                .setQueryBindings(new List<String>{ EmailHelper.ORG_WIDE_EMAIL_ADDRESS_NAME_RC_PROSERV })
                .executeQuery();
    
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
            for (Case cs : proServCases) {
                if (!CaseHelper.isUcProServCase(cs) && !CaseHelper.isCcProServCase(cs)) {
                    continue;
                }

                Emails__c emailSetting = CaseHelper.isUcProServCase(cs) ? 
                    Emails__c.getValues(QuotingToolQuoteApexController.PROSERV_EMAILS_CUSTOM_SETTING_NAME) : 
                    Emails__c.getValues(QuotingToolQuoteApexController.CC_PROSERV_EMAILS_CUSTOM_SETTING_NAME);

                if (emailSetting == null || String.isBlank(emailSetting.Email_Address__c)) {
                    continue;
                }

                String subject = CaseHelper.isUcProServCase(cs) ? 'UC' : 'CC';
                subject += ' Cloned quote requested for ' + originalQuote.Opportunity.Account.Name;

                String baseUrl = Url.getOrgDomainUrl().toExternalForm();
                String oppLink = 'Opportunity: <a href="' + baseUrl + '/lightning/r/Opportunity/' + originalQuote.Opportunity.Id + '/view">' + originalQuote.Opportunity.Name + '</a><br/>';
                String quoteLink = 'Cloned Quote: <a href="' + baseUrl + '/lightning/r/Quote/' + clonedQuote.MasterQuote__c + '/view">' + clonedQuote.MasterQuote__r.Name + '</a><br/><br/>';

                String body = 'A new quote containing ProServ packages has been cloned.<br/><br/>' + oppLink + quoteLink;
                
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();

                if (!proServOrgWideEmailAddressList.isEmpty()) {
                    emailMessage.setOrgWideEmailAddressId(proServOrgWideEmailAddressList[0].Id);
                }
                emailMessage.setSubject(subject);
                emailMessage.setHtmlBody(body);
                emailMessage.setToAddresses(new List<String>{ emailSetting.Email_Address__c });

                emailMessages.add(emailMessage);
            }

            sendSingleEmailMessages(emailMessages);
        } catch (Exception e) {
            PlatformLog.logException('sendEmailNotificationToProServTeamForClonedQuote for quote id: ' + clonedProServQuoteId, e);
        }
    }
}