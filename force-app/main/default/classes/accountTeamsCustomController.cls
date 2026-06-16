/* Class Name : accountTeamsCustomController
*Business Purpose : To handle the actions to the Account Team Member addition and Account, Contact, Case, Opportunity access.
*Developer Name : Elambaruthi Thanasinghu
 Modification History :
*--------------------------------------------------------------------------------------------------------------------
Date                  User Story#                   Developer Name                    Changes done
*-------------------------------------------------------------------------------------------------------------------
30/03/2022            CRM-4909                      Elambaruthi                       Created a New Class and Added a method to add the current user to the AccountTeamMember
03/04/2023            PBC-13962                     Anjana                            Added method to determine if Account Owner is updated so that a warning can be shown that Renewal Managers ATM will be retained
*/
public with sharing class accountTeamsCustomController {
    public accountTeamsCustomController() {

    }

    @AuraEnabled
    public static void addCurrentUsertoAccountTeamMember(Id accId, Id userId){
        try {
            List<AccountTeamMember> lstATM = new List<AccountTeamMember>();
            Map<ID,Set<ID>> aTeams = New Map<ID,Set<ID>>();
            List<Account> lstATMMapSource = [SELECT Id, OwnerId, (SELECT UserId FROM AccountTeamMembers ) FROM Account WHERE id =:accId];
            for (Account acc :lstATMMapSource) {
                aTeams.put(acc.id,New Set<ID>());
                for(AccountTeamMember team : acc.AccountTeamMembers){
                    aTeams.get(acc.id).add(team.UserId);
                }
            }

            if(userId != null) {
                if(!aTeams.get(accId).contains(userId)) {
                    AccountTeamMember newATM = new AccountTeamMember();
                    newATM.AccountId = accId;
                    newATM.UserId = userId;
                    newATM.AccountAccessLevel = 'Edit';
                    newATM.CaseAccessLevel = 'Edit';
                    newATM.ContactAccessLevel = 'Edit';
                    newATM.OpportunityAccessLevel = 'Edit';
                    newATM.TeamMemberRole = 'Strategic Partner RC Owner';
                    lstATM.add(newATM);
                }
            }
            if(lstATM.size()>0){
                upsert lstATM;
            }
            ConvertLeadController.atmFlag = true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled()
    public static Boolean determineOwnerChange(String recId) {
        List<AccountTeamMember> listAcc=[SELECT Id FROM AccountTeamMember WHERE AccountId =:recId AND TeamMemberRole='Renewals Manager'];
        System.debug('Renewals Manager Account Team Member ' + listAcc);
        if (!listAcc.isEmpty()) {
            List<AccountHistory> accHis = [SELECT id, AccountId, CreatedById, DataType, Field, CreatedDate, NewValue, OldValue FROM AccountHistory  where AccountId = :recId and Field = 'Owner' and CreatedDate > :Datetime.now().addMinutes(-15) ORDER BY CreatedDate DESC limit 1];
            System.debug('Account History ' + accHis);
            return !accHis.isEmpty();
        }
        return false;
    }
}