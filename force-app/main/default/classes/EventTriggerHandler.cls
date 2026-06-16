public without sharing class EventTriggerHandler {
    public static Boolean teamMemberCreationViaEvent = false;
    public static User currentUser {
        get {
            if (currentUser == null) {
                //Fields needed for AccountTriggerHelperExt.updateLastTouchedSalesPerson:
                //FirstName, LastName, Email, Phone
                currentUser = (User) new ListOptional(new UserSelector()
                    .selectUserById(new List<Object> { UserInfo.getUserId() })
                    .selectFields(new List<String> { 'Profile.Name', 'Implementation_Dispatcher__c' })
                    .executeQuery()
                ).getFirst();
                
            }
            return currentUser;
        }
        set;
    }

    public EventTriggerHandler() {}

    public List<SObject> getOpportunityOrAccountTeamMembersToInsert(List<Event> newEvents) {
        teamMemberCreationViaEvent = true;
        //We care about the manual insertion by Sales Engineer (profile check) context only
        if (System.isBatch() || System.isFuture() || (!currentUser.Profile.Name.startsWith('Sales Engineer') && !Test.isRunningTest())) {
            return new List<SObject>();
        }

        List<SObject> membersToInsert = new List<SObject>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> primaryEngineerAccountMembers = new Set<Id>();
        Set<Id> idsTriggeredBySeEventType = new Set<Id>();
        for (Event e : newEvents) {
            if (!EventTriggerHelper.RT_IDS_EVENT.contains(e.RecordTypeId) || e.WhatId == null) {
                continue;
            }

            if (e.RecordTypeId == EventTriggerHelper.RT_ID_SE_EVENT) {
                idsTriggeredBySeEventType.add(e.WhatId);
            }

            if (String.valueOf(e.WhatId).startsWith('001')) {
                accountIds.add(e.WhatId);
            }
            if (String.valueOf(e.WhatId).startsWith('006')) {
                opportunityIds.add(e.WhatId);
            }
            if (String.valueOf(e.WhatId).startsWith('500')) {
                caseIds.add(e.WhatId);
            }
        }

        if (!caseIds.isEmpty()) {
            handleCases(caseIds, opportunityIds, accountIds);
        }

        if (!accountIds.isEmpty()) {
            handleAccounts(membersToInsert, accountIds, primaryEngineerAccountMembers);
        }

        if (!opportunityIds.isEmpty()) {
            handleOpportunities(membersToInsert, opportunityIds, primaryEngineerAccountMembers, idsTriggeredBySeEventType);
        }
        return membersToInsert;
    }

    private void handleCases(Set<Id> caseIds, Set<Id> opportunityIds, Set<Id> accountIds) {
        for (Case c : (List<Case>) new CaseSelector()
                .selectCasesByIds(caseIds)
                .setCondition('AccountId != null OR Opportunity_Reference__c != null')
                .selectFields(new List<Schema.SObjectField> { Case.Opportunity_Reference__c, Case.AccountId })
                .executeQuery()
        ) {
            if (c.Opportunity_Reference__c != null) {
                opportunityIds.add(c.Opportunity_Reference__c);
            } else {
                accountIds.add(c.AccountId);
            }
        }
    }

    private void handleAccounts(List<SObject> membersToInsert, Set<Id> accountIds, Set<Id> primaryEngineerAccountMembers) {
        for (Account a : (List<Account>) new AccountSelector()
                .selectAccountsByIds(new List<Object> { accountIds, currentUser.Id, OpportunityTeamHelper.ROLE_SALES_ENGINEER_PRIMARY })
                .withoutSelectorFieldsIncluded()
                .selectField('Id')
                .subselect(new AccountTeamMemberSelector()
                    .selectAccountTeamMembers()
                    .setCondition('UserId = :bind1 OR TeamMemberRole = :bind2')
                )
                .executeQuery()
        ) {
            Boolean memberAlreadyExists = false;
            for (AccountTeamMember accMember : a.AccountTeamMembers) {
                if (currentUser.Id != accMember.UserId) {
                    continue;
                }
                memberAlreadyExists = true;
                break;
            }
            if (memberAlreadyExists) {
                continue;
            }

            AccountTeamMember newAccountTeamMember = new AccountTeamMember(
                AccountId = a.Id,
                UserId = currentUser.Id,
                TeamMemberRole = a.AccountTeamMembers.isEmpty() 
                    ? OpportunityTeamHelper.ROLE_SALES_ENGINEER_PRIMARY 
                    : OpportunityTeamHelper.ROLE_SALES_ENGINEER_SECONDARY 
            );

            if (newAccountTeamMember.TeamMemberRole == OpportunityTeamHelper.ROLE_SALES_ENGINEER_PRIMARY) {
                primaryEngineerAccountMembers.add(newAccountTeamMember.AccountId);
            }

            membersToInsert.add(newAccountTeamMember);
        }
    }

    private void handleOpportunities(
        List<SObject> membersToInsert,
        Set<Id> opportunityIds,
        Set<Id> primaryEngineerAccountMembers,
        Set<Id> idsTriggeredBySeEventType
    ) {
        Set<Id> accIds = new Set<Id>();
        for (Opportunity o : (List<Opportunity>) new OpportunitySelector()
                .selectOpportunities()
                .selectFields(new List<Schema.SObjectField> { Opportunity.Id, Opportunity.AccountId })
                .setCondition('Id IN :bind0')
                .setQueryBindings(new List<Object> { opportunityIds, currentUser.Id, OpportunityTeamHelper.ROLE_SALES_ENGINEER_PRIMARY })
                .subselect(new OpportunityTeamMemberSelector()
                    .newQueryFactory()
                    .selectFields(new List<Schema.SObjectField> { OpportunityTeamMember.Id, OpportunityTeamMember.UserId })
                    .setCondition('UserId = :bind1 OR TeamMemberRole = :bind2')
                )
                .executeQuery()
        ) {
            Boolean memberAlreadyExists = false;
            for (OpportunityTeamMember oppMember : o.OpportunityTeamMembers) {
                if (currentUser.Id != oppMember.UserId) {
                    continue;
                }
                memberAlreadyExists = true;
                break;
            }
            if (memberAlreadyExists) {
                continue;
            }

            OpportunityTeamMember newOpportunityTeamMember = new OpportunityTeamMember(
                OpportunityId = o.Id,
                UserId = currentUser.Id,
                TeamMemberRole = o.OpportunityTeamMembers.isEmpty() 
                    ? OpportunityTeamHelper.ROLE_SALES_ENGINEER_PRIMARY 
                    : OpportunityTeamHelper.ROLE_SALES_ENGINEER_SECONDARY 
            );
            if (newOpportunityTeamMember.TeamMemberRole == OpportunityTeamHelper.ROLE_SALES_ENGINEER_PRIMARY
                && !primaryEngineerAccountMembers.contains(o.AccountId)
                && !idsTriggeredBySeEventType.contains(o.AccountId)
                && !idsTriggeredBySeEventType.contains(o.Id)
            ) {
                accIds.add(o.AccountId);
            }
            membersToInsert.add(newOpportunityTeamMember);
        }

        handleExtraAccountTeamMembers(membersToInsert, accIds);
    }

    private void handleExtraAccountTeamMembers(List<SObject> membersToInsert, Set<Id> accIds) {
        if (accIds.size() == 0) {
            return;
        }
        for (Account acc : (List<Account>) new AccountSelector()
                .selectAccountsByIds(new List<Object> { accIds, AccountHelper.PAID_STATUS, currentUser.Id })
                .withoutSelectorFieldsIncluded()
                .selectField('Id')
                .setCondition('Id IN :bind0 AND RC_Account_Status__c = :bind1')
                .subselect(new AccountTeamMemberSelector()
                    .selectAccountTeamMembers()
                    .setCondition('UserId = :bind2')
                )
                .executeQuery()
        ) {
            Id accountMemberId;
            if (acc.AccountTeamMembers.size() > 0) {
                if (acc.AccountTeamMembers[0].TeamMemberRole == OpportunityTeamHelper.ROLE_SALES_ENGINEER_PRIMARY) {
                    continue;
                }
                accountMemberId = acc.AccountTeamMembers[0].Id;
            }

            membersToInsert.add(new AccountTeamMember(
                Id = accountMemberId,
                AccountId = acc.Id,
                UserId = currentUser.Id,
                OpportunityAccessLevel = 'Read',
                TeamMemberRole = OpportunityTeamHelper.ROLE_SALES_ENGINEER_PRIMARY
            ));
        }
    }

    public class RcActivityInfoCreation extends Triggers.TriggerHandlerBase {
        override public void handle() {
            EventTriggerHelper.populateDFRActivityFields(Trigger.new);
        }
    }
}