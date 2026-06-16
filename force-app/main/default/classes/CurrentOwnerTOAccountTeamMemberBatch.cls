/* Class Name : CurrentOwnerTOAccountTeamMemberBatch
*Business Purpose : To insert Current Owner as Account team member if they are already not added as an Account team member to open accounts lastmodifieddate in the last 3 years.
*Developer Name : Elambaruthi Thanasinghu
 Modification History : 
*--------------------------------------------------------------------------------------------------------------------
Date                  User Story#                   Developer Name                    Changes done
*-------------------------------------------------------------------------------------------------------------------
05 April 2022            CRM-4971                      Elambaruthi                       Created a script to insert Current Owner as Account team member if they are already not added as an Account team member to open accounts lastmodifieddate in the last 3 years.
*/


global class CurrentOwnerTOAccountTeamMemberBatch implements Database.Batchable<sObject>, Database.Stateful {

    global Integer recordInsertCount;
    global Integer recordInsertErrorCount;
    global String query;
    global CurrentOwnerTOAccountTeamMemberBatch(){
        query='';
        recordInsertCount = 0;
        recordInsertErrorCount = 0;
    }
    global CurrentOwnerTOAccountTeamMemberBatch(String inputQuery){
        recordInsertCount = 0;
        recordInsertErrorCount = 0;
        query = 'AND ' + inputQuery;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug(query);
        return Database.getQueryLocator('SELECT Id, Current_Owner__c, OwnerId, (SELECT UserId FROM AccountTeamMembers) FROM Account WHERE Current_Owner__c != null AND Current_Owner__r.IsActive=True ' + query);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope){
        List<AccountTeamMember> lstATM = new List<AccountTeamMember>();
        Map<ID,Set<ID>> aTeams = New Map<ID,Set<ID>>();

        if(scope.size()> 0){
            for (Account acc :scope) {
                aTeams.put(acc.id,New Set<ID>());
                for(AccountTeamMember team : acc.AccountTeamMembers){
                    aTeams.get(acc.id).add(team.UserId);
                }
            }
            for (Account acc : scope) {
                if(!aTeams.get(acc.Id).contains(acc.Current_Owner__c)) {
                    AccountTeamMember newATM = new AccountTeamMember();
                    newATM.AccountId = acc.Id;
                    newATM.UserId = acc.Current_Owner__c;
                    newATM.AccountAccessLevel = 'Edit';
                    newATM.CaseAccessLevel = 'Edit';
                    newATM.ContactAccessLevel = 'Edit';
                    newATM.OpportunityAccessLevel = 'Edit';
                    newATM.TeamMemberRole = 'Strategic Partner RC Owner';
                    lstATM.add(newATM);
                }    
            }

            if(lstATM.size() > 0) {
                List<Database.UpsertResult> dsrs = Database.Upsert(lstATM, false);
                for(Database.UpsertResult dsr : dsrs){
                    if(!dsr.isSuccess()){
                        recordInsertErrorCount = recordInsertErrorCount + 1;
                    } else{
                        recordInsertCount++;
                    } 
                }
            }

        }
    }   

    global void finish(Database.BatchableContext BC){  
        //Send an email to the User after your batch completes
        
            AsyncApexJob a = [SELECT id, ApexClassId,
                          JobItemsProcessed, TotalJobItems,
                          NumberOfErrors, CreatedBy.Email
                          FROM AsyncApexJob
                          WHERE id = :BC.getJobId()];
            String body = 'Your batch job '
                + 'CurrentOwnerTOAccountTeamMemberBatch '
                + 'has finished. \n'
                + 'There were total'
                + recordInsertCount
                + ' records inserted and there were '
                + recordInsertErrorCount
                + ' failures.';
            String subject = 'ATM - Apex Full Batch Result for CurrentOwnerTOAccountTeamMemberBatch';
            // Define the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setSubject( subject );
                email.setToAddresses( new String[] {a.CreatedBy.Email} );
                email.setPlainTextBody( body );
            
                // Sends the email
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});   
    }        
}