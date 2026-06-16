public class BatchJob_UpdateDSAAccounts implements Database.Batchable<SObject>, Database.Stateful {
    
    // Stateful variables to track results across batches
    public Integer totalProcessed = 0;
    public Integer totalSuccessful = 0;
    public Integer totalFailed = 0;
    public List<String> errorMessages = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, OwnerId, Owner.Email, Owner.Name,
                   RC_Account_Status__c, RC_Upgrade_Date__c,
                   Current_Owner__c, Current_Owner_Email__c, Current_Owner_Name__c,
            	   Current_Owner_Previous__c, Current_Owner_Email_Previous__c,
                   MRR_Transfer_Effective_Date__c,
                   (SELECT Id, UserId, TeamMemberRole FROM AccountTeamMembers)
            FROM Account
            WHERE RC_Account_Status__c = 'Paid'
            AND Hold_Out__c = false
            AND RC_Upgrade_Date__c != NULL
            AND RC_Upgrade_Date__c <= :System.now().addDays(-3)
            AND Id IN (
                SELECT AccountId
                FROM AccountTeamMember
                WHERE TeamMemberRole IN ('DSA Expansion', 'MEMX Expansion', 'MMMX Expansion')
            )
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();
        List<AccountTeamMember> teamMembersToReinsert = new List<AccountTeamMember>();
        Map<Id, Messaging.SingleEmailMessage> accountIdToEmailMap = new Map<Id, Messaging.SingleEmailMessage>();
        String teamRole = '';

        List<OrgWideEmailAddress> orgWideEmailList = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress 
                                                      WHERE Address = 'noreply@ringcentral.com' LIMIT 1];
        OrgWideEmailAddress orgWideEmail = orgWideEmailList.isEmpty() ? null : orgWideEmailList[0];

        // Gather required User Ids from AccountTeamMembers
        Set<Id> userIds = new Set<Id>();
        for (Account acc : scope) {
            if (acc.AccountTeamMembers != null) {
                for (AccountTeamMember atm : acc.AccountTeamMembers) {
                    userIds.add(atm.UserId);
                }
            }
        }

        // Query Users in bulk
        Map<Id, User> userMap = new Map<Id, User>();
        if (!userIds.isEmpty()) {
            userMap = new Map<Id, User>(
                [SELECT Id, Email, Name FROM User WHERE Id IN :userIds]
            );
        }

        for (Account acc : scope) {
            User dsaRep;
            if (acc.AccountTeamMembers != null) {
                for (AccountTeamMember atm : acc.AccountTeamMembers) {
                    if (atm.TeamMemberRole == 'DSA Expansion' && userMap.containsKey(atm.UserId)) {
                        dsaRep = userMap.get(atm.UserId);
                        teamRole = 'DSA';
                    } else if(atm.TeamMemberRole == 'MMMx Expansion' && userMap.containsKey(atm.UserId)){
                        dsaRep = userMap.get(atm.UserId);
                        teamRole = 'MMMx';                        
                    } else if(atm.TeamMemberRole == 'MEMx Expansion' && userMap.containsKey(atm.UserId)){
                        dsaRep = userMap.get(atm.UserId);
                        teamRole = 'MEMx';                        
                    } else if (atm.TeamMemberRole != 'DSA Expansion' && atm.TeamMemberRole != 'MMMx Expansion' && atm.TeamMemberRole != 'MEMx Expansion') {
                        // Retain all other team members (non-DSA)
                        teamMembersToReinsert.add(
                            new AccountTeamMember(
                                AccountId = acc.Id,
                                UserId = atm.UserId,
                                TeamMemberRole = atm.TeamMemberRole
                            )
                        );
                    }
                }
            }

            if (dsaRep == null) {
                continue;
            }
            
            // Update Account owner and related fields for DSA
            if(teamRole == 'DSA'){
            	acc.OwnerId = dsaRep.Id;
            	acc.MRR_Transfer_Effective_Date__c = System.today();
            	acc.Current_Owner__c = dsaRep.Id;
            	acc.Current_Owner_Email__c = dsaRep.Email;
            	acc.Current_Owner_Name__c = dsaRep.Name;
            	accountsToUpdate.add(acc); 
            } else{
            	acc.Current_Owner_Previous__c = acc.OwnerId;
            	acc.Current_Owner_Email_Previous__c = acc.Owner.Email;
            	acc.OwnerId = dsaRep.Id;
                acc.Current_Owner__c = dsaRep.Id;
				acc.Current_Owner_Name__c = dsaRep.Name;
            	acc.Current_Owner_Email__c = dsaRep.Email;
            	acc.MRR_Transfer_Effective_Date__c = System.today();
            	accountsToUpdate.add(acc);
            }
            // Prepare email (only if OrgWideEmailAddress exists) - map to account for later sending
            if (orgWideEmail != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setSaveAsActivity(false);
                mail.setOrgWideEmailAddressId(orgWideEmail.Id);
                mail.setToAddresses(new String[] { dsaRep.Email });
                if(teamRole == 'DSA'){
                	mail.setSubject('A new DSA account - ' + acc.Name + ' - has been assigned to you!');
                	mail.setPlainTextBody(
                    	'Hi ' + dsaRep.Name + ',\n\n' +
                    	'A new DSA account "' + acc.Name + '" has been assigned to you. ' +
                    	'Please check the next steps for this account and follow up with the customer.\n\n' +
                    	'Account: ' + URL.getOrgDomainUrl().toExternalForm() +
                    	'/lightning/r/Account/' + acc.Id + '/view\n\n' +
                    	'Thanks!'
                	);
                } else{
                    mail.setSubject('A new ' + teamRole + ' - ' + acc.Name + ' - has been assigned to you!');
            		mail.setPlainTextBody(
                		'Hi ' + dsaRep.Name + ',\n\n' +
                		'A new ' + teamRole + ' account has been assigned to you. ' +
                		'Please check the next steps for this account and follow up with the customer.\n\n' +
                		'Account: ' + URL.getOrgDomainUrl().toExternalForm() +
                		'/lightning/r/Account/' + acc.Id + '/view\n\n' +
                		'Thanks!'
            		);
                }                
                accountIdToEmailMap.put(acc.Id, mail);
            }
        }

        // Update accounts using Database.SaveResult for partial success
        Set<Id> successfulAccountIds = new Set<Id>();
        if (!accountsToUpdate.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(accountsToUpdate, false);
            
            for (Integer i = 0; i < saveResults.size(); i++) {
                totalProcessed++;
                Database.SaveResult sr = saveResults[i];
                Account acc = accountsToUpdate[i];
                
                if (sr.isSuccess()) {
                    totalSuccessful++;
                    successfulAccountIds.add(sr.getId());
                    System.debug('Successfully updated Account: ' + acc.Name + ' (ID: ' + acc.Id + ')');
                } else {
                    totalFailed++;
                    String errorMsg = 'Failed to update Account: ' + acc.Name + ' (ID: ' + acc.Id + '). Errors: ';
                    for (Database.Error err : sr.getErrors()) {
                        errorMsg += err.getStatusCode() + ': ' + err.getMessage() + ' - Fields: ' + err.getFields() + '; ';
                    }
                    errorMessages.add(errorMsg);
                    System.debug(errorMsg);
                }
            }
        }

        // Re-insert retained team members using Database.SaveResult
        if (!teamMembersToReinsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(teamMembersToReinsert, false);
            
            for (Integer i = 0; i < insertResults.size(); i++) {
                Database.SaveResult sr = insertResults[i];
                AccountTeamMember atm = teamMembersToReinsert[i];
                
                if (!sr.isSuccess()) {
                    String errorMsg = 'Failed to insert AccountTeamMember for Account ID: ' + atm.AccountId + '. Errors: ';
                    for (Database.Error err : sr.getErrors()) {
                        errorMsg += err.getStatusCode() + ': ' + err.getMessage() + '; ';
                    }
                    errorMessages.add(errorMsg);
                    System.debug(errorMsg);
                }
            }
        }

        // Send emails only for successfully updated accounts
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        for (Id accountId : successfulAccountIds) {
            if (accountIdToEmailMap.containsKey(accountId)) {
                emailsToSend.add(accountIdToEmailMap.get(accountId));
            }
        }
        
        if (!emailsToSend.isEmpty()) {
            Messaging.SendEmailResult[] emailResults = Messaging.sendEmail(emailsToSend, false);
            
            for (Integer i = 0; i < emailResults.size(); i++) {
                Messaging.SendEmailResult emailResult = emailResults[i];
                if (!emailResult.isSuccess()) {
                    String errorMsg = 'Failed to send email. Errors: ';
                    for (Messaging.SendEmailError err : emailResult.getErrors()) {
                        errorMsg += err.getStatusCode() + ': ' + err.getMessage() + '; ';
                    }
                    errorMessages.add(errorMsg);
                    System.debug(errorMsg);
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('===== Batch Job Completed: BatchJob_UpdateDSAAccounts =====');
        System.debug('Total Accounts Processed: ' + totalProcessed);
        System.debug('Total Successful Updates: ' + totalSuccessful);
        System.debug('Total Failed Updates: ' + totalFailed);
        
        if (!errorMessages.isEmpty()) {
            System.debug('===== Errors Encountered =====');
            for (String errorMsg : errorMessages) {
                System.debug(errorMsg);
            }
        }
        
        // Get batch job details (only if BatchableContext is not null)
        if (bc != null) {
            AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedDate, CompletedDate
                                FROM AsyncApexJob 
                                WHERE Id = :bc.getJobId()];
            
            System.debug('Job Status: ' + job.Status);
            System.debug('Job Items Processed: ' + job.JobItemsProcessed + ' of ' + job.TotalJobItems);
            System.debug('Number of Errors: ' + job.NumberOfErrors);
            System.debug('Started: ' + job.CreatedDate);
            System.debug('Completed: ' + job.CompletedDate);
        } else {
            System.debug('BatchableContext is null (likely in test context) - skipping job details query');
        }
    }
}