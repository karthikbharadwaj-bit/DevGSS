/* 
*Class Name         : Batch_CreateTasksForRelationshipSurvey
*Business Purpose   : Create a Task per Account for Relationship Survey invites for which customer has not responded
* Test Class        : Test_Batch_CreateTasksRelationshipSurvey
*Developer Name     : Anjana Ravikumar
Modification History:
*--------------------------------------------------------------------------------------------------------------------
Date              User Story#                   Developer Name                    Changes done
*-------------------------------------------------------------------------------------------------------------------
11/20/2023         PBC-16919                   Anjana Ravikumar                   New Batch Class
*/
global class Batch_CreateTasksForRelationshipSurvey implements Database.Batchable<sObject>, Database.Stateful {
    global Set<Id> uniqueAccountIds;
    global Integer recordInsertCount;
    global Integer recordInsertErrorCount;
    public final String Query; 
    private static final String RS_SERVICE_NAME = 'sfdc_create_relationship_survey';
    private static final String RELATIONSHIP_SURVEY = 'Relationship_Survey';
    private static final String RC_ADMIN_USER_CONTACT_ROLE = 'RC Admin User';

    public Batch_CreateTasksForRelationshipSurvey() {
        recordInsertCount = 0;
        recordInsertErrorCount = 0;
        uniqueAccountIds = new Set<Id>();
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String statusVal = '';
        List<String> statusValList = new List<String>();
        Datetime fromDateVal;
        Datetime toDateVal;
        Medallia_RS_Task_Settings__c RSTasksSetting = Medallia_RS_Task_Settings__c.getInstance();
        
        for (Medallia_Post_Launch_Activity__mdt medTasks : Medallia_Post_Launch_Activity__mdt.getAll().values()) {
            if(medTasks.DeveloperName == RELATIONSHIP_SURVEY) {
                statusVal = statusVal == '' ? medTasks.Invitation_Status__c : (statusVal + ',' + medTasks.Invitation_Status__c);
            }
        }
        if (String.isNotBlank(statusVal) ) {
            statusValList =  statusVal.split(',');
        }
        if (Test.isRunningTest()) {
            fromDateVal =  Datetime.now().addDays(-2);
            toDateVal = Datetime.now();
        } else if (RSTasksSetting != null) {
            fromDateVal = RSTasksSetting.Start_Date_Time__c;
            toDateVal = RSTasksSetting.End_Date_Time__c != null ? RSTasksSetting.End_Date_Time__c : Datetime.now();
        }
        return Database.getQueryLocator([SELECT Id, medallia_xm__Account__c,medallia_xm__Contact__c, medallia_xm__Account__r.CSM__c, medallia_xm__Date_To_Send__c, medallia_xm__Status__c, medallia_xm__ParentId__c FROM Medallia_xm__Invitation__c WHERE (medallia_xm__Medallia_Service__c = :RS_SERVICE_NAME and medallia_xm__Status__c IN :statusValList and CreatedDate >= :fromDateVal and CreatedDate <= :toDateVal)]);
    }

    global void execute(Database.BatchableContext BC, List<Medallia_xm__Invitation__c> invitations){
        Medallia_RS_Task_Settings__c RSTasksSetting = Medallia_RS_Task_Settings__c.getInstance();
        List<Task> accountTaskList = new List<Task>();
        List<Medallia_Post_Launch_Activity__mdt> medList = Medallia_Post_Launch_Activity__mdt.getAll().values(); 
        List<Medallia_Post_Launch_Activity__mdt> medRSList = new List<Medallia_Post_Launch_Activity__mdt>(); 
        List<AccountContactRole> accContactRoleList = new List<AccountContactRole>(); 
        Map<Id,Id> accPrimContactMap = new Map<Id,Id>(); 
        Map<Id,Medallia_xm__Invitation__c> uniqueAccInviteMap = new Map<Id,Medallia_xm__Invitation__c>(); 
        

        for (Medallia_Post_Launch_Activity__mdt medTasks : medList) {
            if(medTasks.DeveloperName == RELATIONSHIP_SURVEY){
                medRSList.add(medTasks);
            }
        }
        // Collect unique Accounts and corresponding invitation record from the list of invitations
        for (Medallia_xm__Invitation__c invite : invitations) { 
            if(invite.medallia_xm__Contact__c != null && invite.medallia_xm__Account__c != null && invite.medallia_xm__Account__r != null && invite.medallia_xm__Account__r.CSM__c != null ) {
                if (!uniqueAccountIds.contains(invite.medallia_xm__Account__c)) {
                    uniqueAccountIds.add(invite.medallia_xm__Account__c);
                    uniqueAccInviteMap.put(invite.medallia_xm__Account__c,invite);
                }
            }
        }

        if (uniqueAccInviteMap.keySet().size() > 0 && uniqueAccountIds.size() > 0) {
            // Storing the details of Contact Role/Primary contact for each Account record
            accContactRoleList = [SELECT Id,Role, isPrimary, AccountId, ContactId, contact.AccountId from AccountContactRole where (isPrimary = true or Role = :RC_ADMIN_USER_CONTACT_ROLE) and contact.accountId IN :uniqueAccountIds and accountId IN :uniqueAccountIds LIMIT 50000];

            for (Id accId : uniqueAccountIds) {
                Id primaryContactId;
                Id RCAdminContactId;
                for (AccountContactRole acr : accContactRoleList) {
                    if (accId == acr.contact.AccountId && acr.AccountId == acr.contact.AccountId) { // making sure contact belongs to the Account(from invitations) 
                        if (acr.isPrimary) {
                            primaryContactId = acr.contactId;
                            break;
                        } else {
                            RCAdminContactId = acr.contactId;
                        }
                    }
                }
                if(primaryContactId != null || RCAdminContactId !=null){
                    // For determining Name(WhoId) for Task. First preference for mapping is for 'Primary Contact' then a Contact with role 'RC Admin User' under the Account
                    accPrimContactMap.put(accId, primaryContactId != null ? primaryContactId : RCAdminContactId);
                }
            }

            for (Id uniqueAccountId : uniqueAccInviteMap.keySet()) { 
                Medallia_xm__Invitation__c invite = uniqueAccInviteMap.get(uniqueAccountId);
                for(Medallia_Post_Launch_Activity__mdt medRSData : medRSList) {
                    List<String> statusList = medRSData.Invitation_Status__c != null ? medRSData.Invitation_Status__c.split(',') : new List<String>();
                    if (statusList.contains(invite.medallia_xm__Status__c)) {
                        Task accountTask = new Task();
                        accountTask.Subject = medRSData.Subject__c;
                        accountTask.RecordTypeId = Task.SObjectType.getDescribe().getRecordTypeInfosByName().get(medRSData.Task_Record_Type__c)?.getRecordTypeId();
                        accountTask.WhatId = invite.medallia_xm__Account__c;
                        // WhoId is determined as follows - Primary contact or Contact with Role 'RC Admin User' or a contact from the Invitation record
                        accountTask.WhoId = accPrimContactMap.containsKey(invite.medallia_xm__Account__c) ? accPrimContactMap.get(invite.medallia_xm__Account__c) : invite.medallia_xm__Contact__c;
                        accountTask.OwnerId = invite.medallia_xm__Account__r.CSM__c;
                        accountTask.Activity_Type__c =  medRSData.Activity_Type__c;
                        accountTask.Type =  medRSData.Type__c;
                            if (!Test.isRunningTest() && RSTasksSetting != null) {
                                accountTask.Date_of_Activity__c = RSTasksSetting.Task_Date_of_Activity__c != null ? RSTasksSetting.Task_Date_of_Activity__c : Date.today();
                                accountTask.ActivityDate =  RSTasksSetting.Task_Due_Date__c; // Due Date
                            } else { // For test methods
                                accountTask.Date_of_Activity__c = Date.today();
                                accountTask.ActivityDate =  Date.today().addDays(2);
                            }

                        accountTaskList.add(accountTask);
                    }
                }
            }
        }
        if (accountTaskList.size() > 0) {
            List<Database.SaveResult> result = Database.insert(accountTaskList, false);
            Integer index = 0;
            for(Database.SaveResult res : result){
                if(!res.isSuccess()) {
                    recordInsertErrorCount = recordInsertErrorCount + 1;
                    String errMsg = res.getErrors()[0].getMessage();
                    System.debug('Account ID - ' + accountTaskList[index].accountId + ' Error - ' + errMsg);
                } else {
                    recordInsertCount = recordInsertCount + 1; 
                }
                index++;
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        AsyncApexJob a = [SELECT id, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedBy.Email
        FROM AsyncApexJob WHERE id = :BC.getJobId()];
        String body = 'Your batch job Batch_CreateTasksForRelationshipSurvey has finished. \n'
        + 'There were total of ' + recordInsertCount
        + ' records inserted and there were ' + recordInsertErrorCount
        + ' failures.';
        String subject = 'Medallia RS Tasks - Apex Full Batch Result for Batch_CreateTasksForRelationshipSurvey';
        // Define the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject( subject );
        email.setToAddresses( new String[] {UserInfo.getUserEmail()} );
        email.setPlainTextBody( body );
        
        if (!Test.isRunningTest()){
        // Sends the email
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email}); 
        }
    }
}