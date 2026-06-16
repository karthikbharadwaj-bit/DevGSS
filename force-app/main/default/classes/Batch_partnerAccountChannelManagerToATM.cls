/* Class Name : Batch_partnerAccountChannelManagerToATM
*Business Purpose : To insert Channel Manager as Account team member if they are already not added as an Account team member.
*Developer Name : Anjana Ravikumar
Modification History : 
*--------------------------------------------------------------------------------------------------------------------
Date                  User Story#                   Developer Name                    Changes done
*-------------------------------------------------------------------------------------------------------------------
04 May 2022                                         Anjana  Ravikumar                  New Batch Class
*/

global class Batch_partnerAccountChannelManagerToATM implements Database.Batchable<SObject>, Database.Stateful {
    global Integer recordInsertCount;
    global Integer recordInsertErrorCount;
    @TestVisible
    String atmRole = 'Account Manager';
    @TestVisible
    String accessLevel = 'Edit';
    String query = '';
    Boolean isPartnerAccounts;
    
    global Batch_partnerAccountChannelManagerToATM() {
        recordInsertCount = 0;
        recordInsertErrorCount = 0;
        isPartnerAccounts = true;
        query = 'SELECT Id, Inside_Sales_Rep__c, Partner_Account__c, (SELECT UserId , TeamMemberRole,AccountId FROM AccountTeamMembers) FROM ACCOUNT WHERE RecordType.Name = \'Partner Account\' AND Inside_Sales_Rep__c != null and Inside_Sales_Rep__r.isActive = true';
    }
    global Batch_partnerAccountChannelManagerToATM(Boolean runPartnerAcc, String condition) {
        recordInsertCount = 0;
        recordInsertErrorCount = 0;
        isPartnerAccounts = runPartnerAcc;
        if (runPartnerAcc) {
            query = 'SELECT Id, Inside_Sales_Rep__c, Partner_Account__c, (SELECT UserId , TeamMemberRole,AccountId FROM AccountTeamMembers) FROM ACCOUNT WHERE RecordType.Name = \'Partner Account\' AND Inside_Sales_Rep__c != null and Inside_Sales_Rep__r.isActive = true ' + condition;
        } else {
            query = 'select Id, Partner_Account__c, Partner_Account__r.Inside_Sales_Rep__c, (SELECT UserId , TeamMemberRole FROM AccountTeamMembers) from Account where RecordType.Name = \'Customer Account\' and Partner_Account__r.Inside_Sales_Rep__c != null and Partner_Account__r.Inside_Sales_Rep__r.isActive = true ' + condition;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        List<AccountTeamMember> lstATM = new List<AccountTeamMember>();
        List<Id> ATMUserIdList = new List<Id>();
        if (isPartnerAccounts) {
            for (Account acc : scope) {
                if (acc.AccountTeamMembers != null) {
                    for (AccountTeamMember atm: acc.AccountTeamMembers) {
                        ATMUserIdList.add(atm.userId);
                    }
                }
                system.debuG('ATMUserIdList'+ATMUserIdList);
                if (!ATMUserIdList.contains(acc.Inside_Sales_Rep__c)){
                    lstATM.add(constructATMObj(acc.Id, acc.Inside_Sales_Rep__c));
                }
            }
        } else {
            for (Account acc : scope) {
                if (acc.AccountTeamMembers != null) {
                    for (AccountTeamMember atm: acc.AccountTeamMembers) {
                        ATMUserIdList.add(atm.UserId);
                    }
                }
                system.debuG('ATMUserIdList'+ATMUserIdList);
                if (!ATMUserIdList.contains(acc.Partner_Account__r.Inside_Sales_Rep__c)){
                    lstATM.add(constructATMObj(acc.Id, acc.Partner_Account__r.Inside_Sales_Rep__c));
                }
            }
        }
        Triggers.switchoff();
        System.debug('!!!!!!!!!! ' + lstATM);
        if(lstATM.size() > 0) {
            List<Database.UpsertResult> result = Database.Upsert(lstATM, false);
            Integer index = 0;
            for(Database.UpsertResult res : result){
                if(!res.isSuccess()) {
                    recordInsertErrorCount = recordInsertErrorCount + 1;
                    String errMsg = res.getErrors()[0].getMessage();
                    System.debug('Account ID - ' + lstATM[index].accountId + ' Error - ' + errMsg);
                } else {
                    recordInsertCount = recordInsertCount + 1; 
                }
                index++;
            }
        }
        Triggers.switchOn();
    }
        
    global void finish(Database.BatchableContext BC) {
        //Send an email to the User after your batch completes
        Triggers.switchOn();
        AsyncApexJob a = [SELECT id, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedBy.Email
                          FROM AsyncApexJob WHERE id = :BC.getJobId()];
        String body = 'Your batch job '
            + 'Batch_partnerAccountChannelManagerToATM '
            + 'has finished. \n'
            + 'There were total of '
            + recordInsertCount
            + ' records inserted and there were '
            + recordInsertErrorCount
            + ' failures.';
        String subject = 'ATM - Apex Full Batch Result for Batch_partnerAccountChannelManagerToATM';
        // Define the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject( subject );
        email.setToAddresses( new String[] {'anjana.ravikumar@ringcentral.com'} );
        email.setPlainTextBody( body );
        
        // Sends the email
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email}); 
    }
    
    @TestVisible
    private AccountTeamMember constructATMObj(Id accountId, Id channelManagerId) {
        AccountTeamMember newATM = new AccountTeamMember();
        newATM.AccountId = accountId;
        newATM.UserId = channelManagerId;
        newATM.AccountAccessLevel = accessLevel;
        newATM.CaseAccessLevel = accessLevel;
        newATM.ContactAccessLevel = accessLevel;
        newATM.OpportunityAccessLevel = accessLevel;
        newATM.TeamMemberRole = atmRole;
        return newATM;   
    }
}