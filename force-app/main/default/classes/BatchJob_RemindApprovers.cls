public with sharing class BatchJob_RemindApprovers implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    private static final String query = 'SELECT Id, Status__c, Current_Approver__c, '
        + ' (SELECT Id FROM Attachments), '
        + ' (SELECT Id FROM ContentDocumentLinks) '
        + ' FROM Approval__c '
        + ' WHERE RecordTypeId = \'' + ApprovalHelper.RT_ID_BOB_APPROVAL + '\''
        + ' AND Status__c LIKE \'%Pending%\' AND Current_Approver__c != null ';

    private static final String BOB_ASSIGNMENT_EMAIL_NAME = 'BoB_Assigment_Email';
    private static final String BOB_DRAFT_APPROVAL_EMAIL_NAME = 'BoB_Partner_Review_Draft';
    private static final String BOB_FINAL_APPROVAL_EMAIL_NAME = 'BoB_Partner_Review_Final';
    private static final List<String> TEMPLATE_NAMES = new List<String>{
        BOB_ASSIGNMENT_EMAIL_NAME, BOB_DRAFT_APPROVAL_EMAIL_NAME, BOB_FINAL_APPROVAL_EMAIL_NAME
    };
    private static Map<String, List<Id>> usersByQueueName = new Map<String, List<Id>>();
    private static Map<String, EmailTemplate> templates = new Map<String, EmailTemplate>();
    private static Boolean isIncludeTodaysApprovals = false;
    public BatchJob_RemindApprovers() {}
    public BatchJob_RemindApprovers(Boolean includeTodaysApprovals) {
        isIncludeTodaysApprovals = includeTodaysApprovals;
    }
    static {
        List<Id> treasuryCreditCheckGroup = new List<Id>();
        List<User> treasuryCreditCheckGroupUsers = ApprovalHelperCls.findQueueUsers('Billing_Credit_Check');
        if (!treasuryCreditCheckGroupUsers.isEmpty()) {
            for (User emailRecipient : treasuryCreditCheckGroupUsers) {
                treasuryCreditCheckGroup.add(emailRecipient.Id);
            }
            usersByQueueName.put('Billing Credit Check', treasuryCreditCheckGroup);
        }
        List<Id> invoiceApprovalGroup = new List<Id>();
        List<User> invoiceApprovalGroupUsers = ApprovalHelperCls.findQueueUsers('Invoice_Approval_Queue');
        if (!invoiceApprovalGroupUsers.isEmpty()) {
            for (User emailRecipient : invoiceApprovalGroupUsers) {
                invoiceApprovalGroup.add(emailRecipient.Id);
            }
            usersByQueueName.put('Invoice Approval Queue', invoiceApprovalGroup);
        }
        List<Id> financeApprovalGroup = new List<Id>();
        List<User> financeApprovalGroupUsers = ApprovalHelperCls.findQueueUsers('Finance_Revenue_Team');
        if (!financeApprovalGroupUsers.isEmpty()) {
            for (User emailRecipient : financeApprovalGroupUsers) {
                financeApprovalGroup.add(emailRecipient.Id);
            }
            usersByQueueName.put('Finance Revenue Team', financeApprovalGroup);
        }

        for (EmailTemplate template : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :TEMPLATE_NAMES]) {
            templates.put(template.DeveloperName, template);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        Map<Id, Approval__c> approvalsById = new Map<Id, Approval__c>( (List<Approval__c>) scope );
        if (!isIncludeTodaysApprovals) {
            for (ProcessInstanceStep pis : [SELECT Id, ProcessInstance.TargetObjectId
                                            FROM ProcessInstanceStep
                                            WHERE ProcessInstance.TargetObjectId IN :approvalsById.keySet()
                                                AND CreatedDate = TODAY]) {
                approvalsById.remove(pis.ProcessInstance.TargetObjectId);
            }
        }
        Map<String, Id> approversByName = new Map<String, Id>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Approval__c approval : approvalsById.values()) {
            if (approval.Status__c == 'Pending Finance Approval') {
                Id templateIdForUse;
                System.debug('approval.Attachments >>>>> ' + approval.Attachments);
                System.debug('approval.Attachments.size() >>>>> ' + approval.Attachments.size());
                System.debug('approval.ContentDocumentLinks >>>>> ' + approval.ContentDocumentLinks);
                System.debug('approval.ContentDocumentLinks.size() >>>>> ' + approval.ContentDocumentLinks.size());
                System.debug('Finance Revenue Team >>>>> ' + usersByQueueName.get('Finance Revenue Team'));
                    if ((approval.Attachments.size() + approval.ContentDocumentLinks.size()) == 1) {
                    templateIdForUse = templates.get(BOB_DRAFT_APPROVAL_EMAIL_NAME).Id;
                } else if ((approval.Attachments.size() + approval.ContentDocumentLinks.size()) > 1) {
                    templateIdForUse = templates.get(BOB_FINAL_APPROVAL_EMAIL_NAME).Id;
                } else {
                    continue;
                }
                for (Id userId : usersByQueueName.get('Finance Revenue Team')) {
                    Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(
                        templateIdForUse,
                        userId,
                        approval.Id
                    );
                    String emailSubject = email.getSubject();
                    String emailTextBody = email.getPlainTextBody();
                    String emailHtmlBody = email.getHtmlBody();
                    email.setTargetObjectId(userId);
                    email.setSubject(emailSubject);
                    email.setPlainTextBody(emailTextBody);
                    email.setHtmlBody(emailHtmlBody);
                    email.setSaveAsActivity(false);
                    emails.add(email);
                }
            } else if (usersByQueueName.containsKey(approval.Current_Approver__c)) {
                for (Id userId : usersByQueueName.get(approval.Current_Approver__c)) {
                    Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(
                        templates.get(BOB_ASSIGNMENT_EMAIL_NAME).Id,
                        userId,
                        approval.Id
                    );
                    String emailSubject = email.getSubject();
                    String emailTextBody = email.getPlainTextBody();
                    String emailHtmlBody = email.getHtmlBody();
                    email.setTargetObjectId(userId);
                    email.setSubject(emailSubject);
                    email.setPlainTextBody(emailTextBody);
                    email.setHtmlBody(emailHtmlBody);
                    email.setSaveAsActivity(false);
                    emails.add(email);
                }
            } else {
                approversByName.put(approval.Current_Approver__c, null);
            }
        }
        for (User user : [SELECT Id, Name FROM User WHERE Name IN :approversByName.keySet() AND IsActive = true]) {
            approversByName.put(user.Name, user.Id);
        }
        for (Approval__c approval : approvalsById.values()) {
            if (approversByName.containsKey(approval.Current_Approver__c)
                    && approversByName.get(approval.Current_Approver__c) != null) {

                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(
                    templates.get(BOB_ASSIGNMENT_EMAIL_NAME).Id,
                    approversByName.get(approval.Current_Approver__c),
                    approval.Id
                );
                String emailSubject = email.getSubject();
                String emailTextBody = email.getPlainTextBody();
                String emailHtmlBody = email.getHtmlBody();
                email.setTargetObjectId(approversByName.get(approval.Current_Approver__c));
                email.setSubject(emailSubject);
                email.setPlainTextBody(emailTextBody);
                email.setHtmlBody(emailHtmlBody);
                email.setSaveAsActivity(false);
                emails.add(email);
            }
        }
        if (!emails.isEmpty()){
            Messaging.sendEmail(emails);
        }
    }

    public void finish(Database.BatchableContext context) {
    }

    public void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(new BatchJob_RemindApprovers(), 50);
    }
}