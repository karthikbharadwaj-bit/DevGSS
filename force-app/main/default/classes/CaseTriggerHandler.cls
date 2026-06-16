public with sharing class CaseTriggerHandler {
    private static final Map<Id, Schema.RecordTypeInfo> RT_MAP_BY_ID = CaseHelper.RT_INFO_BY_ID;
    private static final Map<Id, String> RECORD_TYPES_ID_TO_NAME_TO_CREATE_SURVEYS = new Map<Id, String> {
        CaseHelper.RT_ID_IT_HELPDESK_SUPPORT => SurveyHelper.SURVEY_TYPE_IT_HELPDESK_SUPPORT,
        CaseHelper.RT_ID_IT_HELPDESK => SurveyHelper.SURVEY_TYPE_IT_HELPDESC_CSAT,
        CaseHelper.RT_ID_IT_INFRASTRUCTURE => SurveyHelper.SURVEY_TYPE_IT_INFRASTRUCTURE
    };

    @TestVisible
    private static Map<Id, Contact> contactsMapFromCases = getContactsMapFromCases((List<Case>) Trigger.new);
    private static Map<Id, Case> caseWithoutSurveyMap = getCaseWithoutSurveyMap(
        (List<Case>) Trigger.new,
        SurveyHelper.SURVEY_TYPES_FOR_PORTING_AND_CSAT_CASE
    );
    private static final String USER_ID = 'User_ID';
    private static final String CUSTOMER_NAME = 'Customer Name';
    private static final String RMA_COMMENTS = 'RMA Comments';
    private static final String CUSTOMER_CONTACT_EMAIL = 'Customer contact email';
    private static final String RECALL = 'Recall';
    private static final String TAKE_ASSIGNMENT = 'Take Assignment';
    private static final String RC_SUPPORT_AGENT = 'RC Support Agent';
    @TestVisible
    private static final String JIRA_NUMBER_REQUIRED_ERROR = 'Jira # is required.';
    @TestVisible
    private static final String INCIDENT_NUMBER_REQUIRED = 'Incident Number is required.';
    @TestVisible
    private static final String REJECT_REVIEW_REASON_NO_VALUE = '[No Value]';

    public static Boolean bypassForRCEvents = false;

    private static final String ESCALATION_CERT = 'CERT';
    private static final String ESCALATION_CUSTOMER_SUCCESS = 'Customer Success';

    public static Set<Id> setUserId {
        get {
            setUserId = new Set<Id>();
            for (Case caseObj : (List<Case>) Trigger.new) {
                setUserId.add(caseObj.LastModifiedById);
                setUserId.add(caseObj.CreatedById);
                setUserId.add(caseObj.OwnerId);
            }
            setUserId.remove(null);
            return setUserId;
        }
        set;
    }

    public static Map<Id, User> usersMap {
        get {
            if (usersMap == null || usersMap.isEmpty()) {
                usersMap = new Map<Id, User>((List<User>) new UserSelector()
                    .selectUsersByIdNoFields(new List<Object> { setUserId })
                    .selectFields(new List<String> {
                        'Name',
                        'ProfileId',
                        'Profile.Name',
                        'Team__c',
                        'Manager.ManagerId',
                        'Title',
                        'Manager.Manager.Title',
                        'Manager.Title',
                        'Manager.Name',
                        'Manager.Email',
                        'UserRoleId',
                        'IsActive',
                        'ManagerId',
                        'Email'
                    })
                    .setQueryCaching(true)
                    .executeQuery()
                );
            }
            return usersMap;
        }
        set;
    }

    public static Map<String, Group> groupNameToGroup {
        get {
            if (groupNameToGroup == null || groupNameToGroup.isEmpty()) {
                groupNameToGroup = new Map<String, Group>();
                Set<String> setOPSBussUnit = new Set<String> {
                    GroupHelper.RESSELER_TEAM_DEV_NAME,
                    GroupHelper.ENGAGE_DIGITAL_DEV_NAME
                };
                for (CaseRoutingBySupportType__mdt routing : CaseRoutingBySupportType__mdt.getAll().values()) {
                    setOPSBussUnit.add(routing.Owner__c);
                }
                for (Group gp : (List<Group>) new GroupSelector()
                        .selectGroups()
                        .setCondition('Type = :bind0 AND Name IN :bind1')
                        .setQueryBindings(new List<Object> { GroupHelper.GROUP_TYPE_QUEUE, setOPSBussUnit })
                        .setQueryCaching(true)
                        .executeQuery()
                ) {
                    groupNameToGroup.put(gp.Name.toLowerCase(), gp);
                }
            }
            return groupNameToGroup;
        }
        set;
    }

    public static Map<Id, Account> mapToCaseAccount {
        get {
            if (mapToCaseAccount == null || mapToCaseAccount.isEmpty()) {
                Set<Id> setAccountId = new Set<Id>();

                for (Case caseObj : (List<Case>) Trigger.new) {
                    if (caseObj.RecordTypeId != null && caseObj.AccountId != null) {
                        setAccountId.add(caseObj.AccountId);
                    }
                }

                if (setAccountId.isEmpty()) {
                    return new Map<Id, Account>();
                }
                mapToCaseAccount = new Map<Id, Account>((List<Account>) new AccountSelector()
                    .selectAccountsForCase(new List<Object> { setAccountId })
                    .withoutSelectorFieldsIncluded()
                    .selectFields(new List<Schema.SObjectField> {
                        Account.Id,
                        Account.MRR__c,
                        Account.inContract__c,
                        Account.Sales_Agreement_End_Date__c,
                        Account.Number_of_DL_s__c,
                        Account.Name,
                        Account.Current_Owner__c,
                        Account.Current_Owner_Email__c,
                        Account.Most_Recent_Opportunity_Owner_Email__c,
                        Account.Sales_Agreement_Start_Date__c,
                        Account.RC_Brand__c
                    })
                    .setQueryCaching(true)
                    .executeQuery()
                );
            }
            return mapToCaseAccount;
        }
        set;
    }

    @TestVisible
    private static Set<String> excludedRecordTypesForWebCaseRouting {
        get {
            if (excludedRecordTypesForWebCaseRouting == null) {
                excludedRecordTypesForWebCaseRouting = new Set<String>();
                for (Excluded_Web_Case_Record_Types__mdt excludedRT : Excluded_Web_Case_Record_Types__mdt.getAll().values()) {
                    if (String.isNotBlank(excludedRT.Record_Type_Name__c)) {
                        excludedRecordTypesForWebCaseRouting.add(excludedRT.Record_Type_Name__c);
                    }
                }
            }
            return excludedRecordTypesForWebCaseRouting;
        }
        set;
    }

    public static List<Survey__c> surveysByCaseContacts {
        get {
            if (contactsMapFromCases.isEmpty()) {
                return new List<Survey__c>();
            }

            if (surveysByCaseContacts == null || surveysByCaseContacts.isEmpty()) {
                surveysByCaseContacts = (List<Survey__c>) new SurveySelector()
                    .selectSurveysByContactIdAndSurveyType(new List<Object> {
                        contactsMapFromCases.keySet(),
                        SurveyHelper.SURVEY_TYPES_FOR_SUPPORT_TO_SEND_SURVEYS,
                        SurveyHelper.SURVEY_TYPES_FOR_IT_TO_SEND_SURVEYS,
                        SurveyHelper.SURVEY_TYPES_FOR_BIZSERV_TO_SEND_SURVEYS
                    })
                    .setQueryCaching(true)
                    .executeQuery();
            }
            return surveysByCaseContacts;
        }
        set;
    }

    public class CreateCaseContactAttempts extends Triggers.TriggerHandlerBase {
        override public void handle() {
            CaseHelper.createCaseContactAttempts((Map<Id, Case>) Trigger.newMap);
            TriggerHandler.ESB_START = false;
        }
    }

    public class CloseCaseMilestone extends Triggers.TriggerHandlerBase {
        override public void handle() {
            MilestoneUtils.closeCaseMilestone(
                (Map<Id, Case>) Trigger.oldMap,
                (Map<Id, Case>) Trigger.newMap
            );
        }
    }

    public class ValidateOnAfterUpdateEvent extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (BooleanHelper.toBoolean(TriggerHandler.BY_PASS_CASE_Trigger)
                || !TriggerHandler.ALLOW_TRIGGER_REQUEST_ONCE()
                || !TriggerHandler.ESB_START
            ) {
                return;
            }

            try {

                PortingESBHelper.validateOnAfterUpdateEvent(
                    (List<Case>) Trigger.new,
                    (Map<Id, Case>) Trigger.oldMap,
                    RT_MAP_BY_ID
                );
                TriggerHandler.ESB_START = false;

            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.ValidateOnAfterUpdateEvent', e);
            }
        }
    }

    public class ValidateByPassCase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Case caseObj : (List<Case>) Trigger.new) {
                Case oldCaseObj = (Case) Trigger.oldMap.get(caseObj.Id);
                if ((oldCaseObj.isLastCaseCommentPublic__c != caseObj.isLastCaseCommentPublic__c
                        || oldCaseObj.Last_Case_Comment__c != caseObj.Last_Case_Comment__c
                        || oldCaseObj.Last_Public_Comment_Timestamp__c != caseObj.Last_Public_Comment_Timestamp__c
                    ) && TriggerHandler.BY_PASS_CASE_Trigger == true
                ) {
                    TriggerHandler.BY_PASS_CASE_Trigger = false;
                    break;
                }
            }
        }
    }

    public class CloseCaseAssignedMilestone extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                if (EntitlementHelper.IsEntitlementsEnabled()) {
                    EntitlementHelper.closeCaseAssignedMilestone(
                        Trigger.new,
                        (Map<Id, Case>) Trigger.oldMap
                    );
                }
            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.CloseCaseAssignedMilestone', e);
            }
        }
    }

    public class CheckForEmail extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                Severity1_CaseHelperClass.checkForEmail(
                    (Map<Id, Case>) Trigger.newMap,
                    Trigger.isInsert ? null : (Map<Id, Case>) Trigger.oldMap
                );
            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.CheckForEmail', e);
            }
        }
    }

    public class HandleCaseForTelus extends Triggers.TriggerHandlerBase {
        // runs after insert and update and check if case is closed then stop sharing with TELUS
        override public void handle() {
            try {
                TelusExternalSharingHelperCls.stopSharingForClosedCases(Trigger.new);
                if (Trigger.isInsert) {
                    NewHireTriggerClass.createNewHireCases((Map<Id, Case>) Trigger.newMap);
                    TelusExternalSharingHelperCls.updateBackToPartner(Trigger.new);
                }
                if (Trigger.isUpdate) {
                    NewHireTriggerclass.newHireupdate(
                        (Map<Id, Case>) Trigger.newMap,
                        (Map<Id, Case>) Trigger.oldMap
                    );
                }

                TelusExternalSharingHelperCls.shareCasesWithTelus(Trigger.new);
            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.HandleCaseForTelus', e);
            }
        }
    }

    public class CalculateGraduationCompletionRateOverCase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                GraduationScoreCardHelper.calculateGraduationCompletionRateOverCase(
                    Trigger.isDelete ? Trigger.old : Trigger.new,
                    Trigger.isDelete ? null : (Map<Id, Case>) Trigger.oldMap
                );
            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.calculateGraduationCompletionRateOverCase', e);
            }
        }
    }

    public class CreateUpdateJuraIssue extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (System.IsBatch() || System.isFuture()) {
                return;
            }
            for (Case caseNew: (List<Case>) Trigger.new) {
                if (Trigger.isInsert && String.isBlank(caseNew.Jira__c)) {
                    continue;
                }
                if (Trigger.isUpdate) {
                    Case oldCase = (Case) Trigger.oldMap.get(caseNew.Id);
                    if (caseNew.Jira__c == '' || oldCase.Jira__c != '' && caseNew.Jira__c == oldCase.Jira__c) {
                        continue;
                    }
                }
                JIRA_Issue_CreateUpdate.fromTrigger(caseNew.Jira__c, caseNew.Id);
            }
        }
    }

    public class ShareAttachments extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<PartnerNetworkRecordConnection> pnrcList = new List<PartnerNetworkRecordConnection>();

            try {
                List<Case> casesToShare = new List<Case>();
                for (Case cs : (List<Case>) Trigger.new) {
                    if (cs.Status == 'WIP by Partner'
                        && cs.Support_Escalate_To__c == 'inContact Support'
                        && (cs.Status != ((Case) Trigger.oldMap.get(cs.Id)).Status
                            || cs.Support_Escalate_To__c != ((Case) Trigger.oldMap.get(cs.Id)).Support_Escalate_To__c)
                    ) {
                        casesToShare.add(cs);
                    }
                }

                if (casesToShare.isEmpty() || InContactConnectionId__c.getInstance().ID__c == null) {
                    return;
                }
                Id pnc = Id.valueOf(InContactConnectionId__c.getInstance().ID__c);

                Map<Id, PartnerNetworkRecordConnection> oldPnrcList = new Map<Id, PartnerNetworkRecordConnection>(
                    (List<PartnerNetworkRecordConnection>) new PartnerNetworkRecordConnectionSelector()
                    .selectPnrcRecords()
                    .setCondition('LocalRecordId IN :bind0 AND ConnectionId = :bind1 AND EndDate = null')
                    .setQueryBindings(new List<Object> { Trigger.oldMap.keySet(), pnc })
                    .executeQuery()
                );
                for (Case cs : casesToShare) {
                    if (oldPnrcList.containsKey(cs.Id)) {
                        continue;
                    }
                    pnrcList.add(PartnerNetworkConnectionHelper.buildSObject(pnc, cs.Id, 'CaseComment,Attachment'));
                }

                if (!pnrcList.isEmpty()) {
                    insert pnrcList;
                }
            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.ShareAttachments', e);
            }
        }
    }

    public class BasicHandler extends Triggers.TriggerHandlerBase {
        override public void handle() {
            /*************************** Telus S2S Code Starts *************************/
            TelusExternalSharingHelperCls.populateVendorContactFieds(triggerRecords);
            TelusExternalSharingHelperCls.mapTelusAddressToRCAddress(triggerRecords);
            /*************************** Telus S2S Code Ends *************************/

            PortingESBHelper.validateOnBeforeInsertEvent(triggerRecords, RT_MAP_BY_ID);
            PortingESBHelper.populatePrimaryContactForPortingCase(triggerRecords, RT_MAP_BY_ID);
        }
    }

    public class AssignOwnerForClosedLoopRelationshipCases extends Triggers.TriggerHandlerBase {
        Owner_Assignment_for_Relationship_Cases__c ownerAssignmentSettings;

        override public void handle() {
            ownerAssignmentSettings = Owner_Assignment_for_Relationship_Cases__c.getOrgDefaults();
            List<Case> casesToProceed = new List<Case>();
            for (Case c : (List<Case>) triggerRecords) {
                if (c.RecordTypeId == CaseHelper.RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP) {
                    casesToProceed.add(c);
                }
            }
            System.debug(
                LoggingLevel.ERROR,
                'CLF_RR_DEBUG user=' + UserInfo.getUserId()
                + ' profile=' + UserInfo.getProfileId()
                + ' casesToProceed=' + casesToProceed.size()
                + ' ownerAssignmentSettingsNull=' + (ownerAssignmentSettings == null)
                + ' customSettingUpdateable=' + Owner_Assignment_for_Relationship_Cases__c.getSObjectType().getDescribe().isUpdateable()
                + ' canUpdateSettings=' + canUpdateSettings()
            );
            if (!casesToProceed.isEmpty() && canUpdateSettings()) {
                assignOwner(casesToProceed);
            }
        }

        private Boolean canUpdateSettings() {
            return ownerAssignmentSettings != null
                && Owner_Assignment_for_Relationship_Cases__c.getSObjectType().getDescribe().isUpdateable();
        }

        private void assignOwner(Case[] relationshipCases) {
            List<GroupMember> closedLoopQueueMembers = (List<GroupMember>) new GroupMemberSelector()
                .selectByGroupDeveloperName(QueueHelper.CLOSED_LOOP_TEAM)
                .addOrdering(Case.Id, QueryFactory.SortOrder.DESCENDING)
                .setQueryCaching(true)
                .executeQuery();
            System.debug(
                LoggingLevel.ERROR,
                'CLF_RR_DEBUG queueMembers=' + closedLoopQueueMembers.size()
            );
            Case[] rrCases = getCasesToApplyRoundRobinAssignment(relationshipCases);
            System.debug(LoggingLevel.ERROR, 'CLF_RR_DEBUG rrCases=' + rrCases.size());
            if (!closedLoopQueueMembers.isEmpty()) {
                assignCaseOwnerUsingRoundRobin(rrCases, closedLoopQueueMembers);
            }
        }

        private Case[] getCasesToApplyRoundRobinAssignment(Case[] relationshipCases) {
            Case[] casesToApplyRRAssignment = new List<Case>();
            Map<Id, Case[]> clfCasesByAccountId = new Map<Id, Case[]>();
            for (Case clfCase : relationshipCases) {
                if (String.isBlank(clfCase.AccountId)) {
                    continue;
                }
                if (!clfCasesByAccountId.containsKey(clfCase.AccountId)) {
                    clfCasesByAccountId.put(clfCase.AccountId, new List<Case>());
                }
                clfCasesByAccountId.get(clfCase.AccountId).add(clfCase);
            }

            for (Account acc : (Account[]) new AccountSelector()
                .selectTechnicalAccounts(new Object[] {clfCasesByAccountId.keySet()})
                .selectField(Account.CSM__c)
                .executeQuery()
            ) {
                if (String.isBlank(acc.CSM__c)) {
                    casesToApplyRRAssignment.addAll(clfCasesByAccountId.get(acc.Id));
                }
            }
            System.debug(LoggingLevel.ERROR, 'CLF_RR_DEBUG getRR out=' + casesToApplyRRAssignment.size() + ' acctBuckets=' + clfCasesByAccountId.size());          

            return casesToApplyRRAssignment;
        }

        private void assignCaseOwnerUsingRoundRobin(Case[] relationshipCases, GroupMember[] closedLoopQueueMembers) {
            Map<Id, Id> nextCaseOwnerByLastAssignedOwner = new Map<Id, Id>();
            for (Integer i = 0; i < closedLoopQueueMembers.size() - 1; i++) {
                nextCaseOwnerByLastAssignedOwner.put(
                    closedLoopQueueMembers.get(i).UserOrGroupId,
                    closedLoopQueueMembers.get(i + 1).UserOrGroupId
                );
            }
            nextCaseOwnerByLastAssignedOwner.put(
                closedLoopQueueMembers.get(closedLoopQueueMembers.size() - 1).UserOrGroupId,
                closedLoopQueueMembers.get(0).UserOrGroupId
            );
            List<Id> nextCaseOwnerIds = nextCaseOwnerByLastAssignedOwner.values();

            String lastAssignedOwnerId = ownerAssignmentSettings.Last_assigned_owner__c;
            for (Case relationshipCase : relationshipCases) {
                String nextCaseOwner = lastAssignedOwnerId != null && nextCaseOwnerByLastAssignedOwner.containsKey(lastAssignedOwnerId)
                   ? nextCaseOwnerByLastAssignedOwner.get(lastAssignedOwnerId)
                   : nextCaseOwnerIds.get(0);
                relationshipCase.OwnerId = Id.valueOf(nextCaseOwner);
                lastAssignedOwnerId	= nextCaseOwner;
            }
            ownerAssignmentSettings.Last_assigned_owner__c = lastAssignedOwnerId;
            update ownerAssignmentSettings;
        }
    }

    public class ChangeOwnerForProfessionalServices extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Case> psCases = new List<Case>();
            Set<Id> oppIds = new Set<Id>();
            Set<Id> quoteIds = new Set<Id>();

            for (Case newCase : (List<Case>) triggerRecords) {
                if (newCase.RecordTypeId != CaseHelper.RT_ID_PROFESSIONAL_SERVICES) {
                    continue;
                }
                psCases.add(newCase);
                oppIds.add(newCase.Opportunity_Reference__c);
                quoteIds.add(newCase.Quote_Approval_ID__c);
            }
            if (!psCases.isEmpty()) {
                changeOwner(psCases, oppIds, quoteIds);
            }
        }

        private void changeOwner(List<Case> psCases, Set<Id> oppIds, Set<Id> quoteIds) {
            List<Case> psQuotingPageCases = new List<Case>();
            Map<String, Id> psQueuesMap = QueueHelper.getPSQueuesMap();
            for (Case psCase: psCases) {
                if (psCase.Origin == CaseHelper.CASE_ORIGIN_QUOTING_PAGE) {
                    psQuotingPageCases.add(psCase);
                } else {
                    psCase.OwnerId = psQueuesMap.get(QueueHelper.QUEUE_PROFESSIONAL_SERVICES);
                }
            }
            if (psQuotingPageCases.isEmpty()) {
                return;
            }

            Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>(
                (List<Opportunity>) new OpportunitySelector()
                    .selectOpportunitiesForPsCases(oppIds)
                    .executeQuery()
            );
            Map<Id, Quote> quotesMap = new Map<Id, Quote>(
                (List<Quote>) new QuoteSelector()
                    .selectQuotesByIdsWithRecordTypes(quoteIds)
                    .executeQuery()
            );
            for (Case psCase : psQuotingPageCases) {
                changeOwnerForPS(
                    psCase,
                    quotesMap.get(psCase.Quote_Approval_ID__c),
                    oppsMap.get(psCase.Opportunity_Reference__c),
                    psQueuesMap
                );
            }
        }

        @TestVisible
        private void changeOwnerForPS(
            Case psCase,
            Quote quote,
            Opportunity opp,
            Map<String,Id> psQueuesMap
        ) {
            String caseCategory = psCase.Category__c;
            Id ownerId = psCase.OwnerId;
            String subject = !String.isBlank(psCase.Subject) ? psCase.Subject.toLowerCase() : '';
            Boolean isBillingQuote = quote?.RecordTypeId == QuoteHelper.RT_ID_BILLING;
            Boolean isCaseUc = isBillingQuote && CaseHelper.isUcProServCase(psCase);
            Boolean isCaseCc = isBillingQuote && CaseHelper.isCcProServCase(psCase);
            Boolean isCancelationCase = isBillingQuote && subject.contains(CaseHelper.SUBJECT_PS_UC_QUOTE_CANCELATION.toLowerCase()) || subject.contains(CaseHelper.SUBJECT_PS_CC_QUOTE_CANCELATION.toLowerCase());

            if(isCancelationCase && quote.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_CANCELLED){
                ownerId = psQueuesMap.get(QueueHelper.QUEUE_PS_CONTACT_CENTER);
            }else if (quote.ProServ_Status__c == QuoteHelper.PROSERVSTATUS_CANCELLED) {
                ownerId = psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MIDMARKET);
            } else if (CurrencyHelper.CURRENCY_ISO_CODES_FOR_PS_INTERNATIONAL.contains(opp.CurrencyIsoCode)) {
                ownerId = psQueuesMap.get(QueueHelper.QUEUE_PS_INTERNATIONAL);
            } else if (quote?.RecordTypeId == QuoteHelper.RT_ID_PROSERV || isCaseUc) {
                ownerId = getOwnerIdForPSProServQuote(caseCategory, opp, psQueuesMap);
            } else if (quote?.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV || isCaseCc) {
                ownerId = getOwnerIdForPSCCProServQuote(caseCategory, opp, psQueuesMap);
            }
            psCase.OwnerId = ownerId;
        }

        @TestVisible
        private Id getOwnerIdForPSProServQuote(String caseCategory, Opportunity opp, Map<String,Id> psQueuesMap) {
            Id midMarketQueueId = psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MIDMARKET);
            if (String.isBlank(caseCategory)) {
                return midMarketQueueId;
            } else if (caseCategory.contains(CaseHelper.CATEGORY_IMPLEMENTATION_SERVICES)) {
                return getOwnerIdForImplementationCategory(opp, psQueuesMap);
            } else if (caseCategory.contains(CaseHelper.CATEGORY_MANAGED_OR_RECURRING_SERVICES)) {
                return psQueuesMap.get(QueueHelper.QUEUE_PS_MRR_SERVICES);
            } else if (caseCategory.contains(CaseHelper.CATEGORY_VIDEO)) {
                return psQueuesMap.get(QueueHelper.QUEUE_PS_VIDEO);
            } else if (caseCategory.contains(CaseHelper.CATEGORY_AFTERMARKET_SUPPORT)) {
                return psQueuesMap.get(QueueHelper.QUEUE_PS_AFTERMARKET);
            } else {
                return midMarketQueueId;
            }
        }

        @TestVisible
        private Id getOwnerIdForImplementationCategory(Opportunity opp, Map<String,Id> psQueuesMap) {
            String segment = opp?.Owner?.SegmentPicklist__c;
            if (UserHelper.isSegmentEnterprise(opp?.Owner)) {
                return psQueuesMap.get(QueueHelper.QUEUE_PS_NA_ENTERPRISE);
            } else if (segment == UserHelper.SEGMENT_MAJORS || segment == UserHelper.SEGMENT_EXPANSION_MAJORS) {
                return psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MAJORS);
            } else if (UserHelper.SMALL_BUSINESS_SEGMENTS.contains(segment)) {
                return psQueuesMap.get(QueueHelper.QUEUE_PS_SMB);
            } else {
                return psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MIDMARKET);
            }
        }

        @TestVisible
        private Id getOwnerIdForPSCCProServQuote(String caseCategory, Opportunity opp, Map<String,Id> psQueuesMap) {
            Id contactCenterQueueId = psQueuesMap.get(QueueHelper.QUEUE_PS_CONTACT_CENTER);
            if (isCaseCategoryForContactCenterQueue(caseCategory, opp)) {
                return contactCenterQueueId;
            }
            if (caseCategory.contains(CaseHelper.CATEGORY_MANAGED_OR_RECURRING_SERVICES)) {
                return psQueuesMap.get(QueueHelper.QUEUE_PS_MRR_SERVICES);
            }
            if (caseCategory.contains(CaseHelper.CATEGORY_AFTERMARKET_SUPPORT)) {
                return psQueuesMap.get(QueueHelper.QUEUE_PS_AFTERMARKET);
            }

            return contactCenterQueueId;
        }

        private Boolean isCaseCategoryForContactCenterQueue(String caseCategory, Opportunity opp) {
            return String.isBlank(caseCategory)
                || UserHelper.isSegmentEnterprise(opp?.Owner)
                    && caseCategory.contains(CaseHelper.CATEGORY_IMPLEMENTATION_SERVICES);
        }
    }

    public class ChangeRecordType extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Case> newCasesListAfterFiltration = new List<Case>();
            for (Case newCase : (List<Case>) triggerRecords) {
                if (newCase.Case_Category__c == CaseHelper.CASE_CATEGORY_SYSTEM_ISSUE) {
                    newCasesListAfterFiltration.add(newCase);
                }
            }
            if (newCasesListAfterFiltration.isEmpty()) {
                return;
            }

            Boolean isEligibleProfile = isEligibleProfile();
            for (Case newCase : newCasesListAfterFiltration) {
                if (newCase.Origin == CaseHelper.CASE_ORIGIN_CASE || isEligibleProfile) {
                    newCase.RecordTypeId = CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES;
                }
            }
        }

        private Boolean isEligibleProfile() {
            Map<String, Case_Routing_SFDC__c> profilesFromCustomSetting = Case_Routing_SFDC__c.getAll();
            if (profilesFromCustomSetting.isEmpty()) {
                return false;
            }

            Set<String> profilesToSelect = new Set<String>();
            for (Case_Routing_SFDC__c profile : profilesFromCustomSetting.values()) {
                profilesToSelect.add(profile.Profile_Name__c);
            }
            return new Map<Id, Profile>(
                (List<Profile>) new ProfileSelector()
                    .selectProfilesByNames(new List<Object> {profilesToSelect})
                    .executeQuery()
            ).containsKey(UserInfo.getProfileId());
        }
    }

    public class PopulateTotalMRRtoSurveyDateFieldOnCreation extends Triggers.TriggerHandlerBase {
        override public void handle() {
            populateTotalMRRtoSurveyDateField(triggerRecords);
        }

        private void populateTotalMRRtoSurveyDateField(Case[] newCaseList) {
            Map<Id, Case[]> medalliaRelationshipSurveyCasesByAccountId = new Map<Id, Case[]>();

            for (Case newCase : newCaseList) {
                if (newCase.RecordTypeId != CaseHelper.RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP || String.isBlank(newCase.AccountId)) {
                    continue;
                }
                if (!medalliaRelationshipSurveyCasesByAccountId.containsKey(newCase.AccountId)) {
                    medalliaRelationshipSurveyCasesByAccountId.put(newCase.AccountId, new List<Case>());
                }
                medalliaRelationshipSurveyCasesByAccountId.get(newCase.AccountId).add(newCase);
            }
            if (medalliaRelationshipSurveyCasesByAccountId.isEmpty()) {
                return;
            }

            for (Account acc : (Account[]) new AccountSelector()
                .selectPartnerAccountsByIds(new Object[] {medalliaRelationshipSurveyCasesByAccountId.keySet()})
                .selectField(Account.MRR__c)
                .executeQuery()
            ) {
                for (Case relationshipCase : medalliaRelationshipSurveyCasesByAccountId.get(acc.Id)) {
                    relationshipCase.TotalMRRtoSurveyDate__c = StringHelper.safeString(acc.MRR__c);
                }
            }
        }
    }

    //PBC-15924 Email-to-Case: Prevent Case Creation for Bounced or Out-of-Office Emails
    @TestVisible
    private static final String ERROR_MESSAGE_PREVENT_CASE_CREATION = 'This is a case generated from an OOO or Bounced Email';
    public class PreventCaseCreation extends Triggers.TriggerHandlerBase {
        @TestVisible
        private List<Words_to_prevent_case_creation__mdt> stopTermRecords = Words_to_prevent_case_creation__mdt.getAll().values();
        private Pattern stopPattern;

        public PreventCaseCreation() {
            super();
        }

        public PreventCaseCreation(List<Case> cases) {
            super(cases);
        }

        override public void handle() {
            if (stopTermRecords.isEmpty()) {
                return;
            }
            validateCaseAgainstStopTerms(triggerRecords);
        }

        private void validateCaseAgainstStopTerms(List<Case> cases) {
            Set<String> stopTerms = new Set<String>();
            for (Words_to_prevent_case_creation__mdt wordToPreventCaseCreation : stopTermRecords) {
                if (String.isNotBlank(wordToPreventCaseCreation.Word__c)) {
                    stopTerms.add(wordToPreventCaseCreation.Word__c);
                }
            }
            if (stopTerms.isEmpty()) {
                return;
            }

            buildPattern(stopTerms);
            for (Case c : cases) {
                if (isContainsStopTerm(c.Subject)) {
                    c.addError(ERROR_MESSAGE_PREVENT_CASE_CREATION);
                }
            }
        }

        private void buildPattern(Set<String> stopTerms) {
            String regex = '(?i)\\b(?:' + String.join(stopTerms, '|') + ')\\b';
            stopPattern = Pattern.compile(regex);
        }

        private Boolean isContainsStopTerm(String str) {
            return String.isBlank(str) ? false : stopPattern.matcher(str).find();
        }
    }

    public class EntitleAssignmentOncase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Case> casesForEntitlementAssignment = new List<Case>();

            for (Case c : (List<Case>) Trigger.new) {
                if (c.RecordTypeId != CaseHelper.RT_ID_SUPPORT_RC_APP && c.EntitlementId == null) {
                    casesForEntitlementAssignment.add(c);
                }
            }

            if (!casesForEntitlementAssignment.isEmpty()) {
                EntitlementHelper.entitleAssignmentOncase(casesForEntitlementAssignment, '');
            }
        }
    }

    public class SetDateStarted extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Date today = Date.today();
            for (Case currentCase : (List<Case>) triggerRecords) {
                if (currentCase.RecordTypeId != CaseHelper.RT_ID_COLLECTIONS_DISPUTE) {
                    continue;
                }
                if (isChangedField(currentCase, Case.OwnerId)) {
                    currentCase.Date_Started__c = today;
                }
            }
        }
    }

    public class CommonHandlers extends Triggers.TriggerHandlerBase {
        override public void handle() {
            TelusExternalSharingHelperCls.mapFieldsForTelusCases(triggerRecords);
            // Populate Master Account to Case when Billing Account Package was populated
            populateMasterAccount(triggerRecords);
        }

        private void populateMasterAccount(List<Case> cases) {
            List<Id> packageIds = new List<Id>();
            List<Case> casesToPopulate = new List<Case>();
            for (Case c : cases) {
                if (shouldPopulateMasterAccount(c)) {
                    packageIds.add(c.Billing_Account_Package__c);
                    casesToPopulate.add(c);
                }
            }
            if (packageIds.isEmpty()) {
                return;
            }

            Map<Id, Package__c> linkedPackages = new Map<Id, Package__c>(
                (List<Package__c>) new PackageSelector()
                    .selectPackagesForCasesById(packageIds)
                    .executeQuery()
            );
            for (Case c : casesToPopulate) {
                Package__c linkedPackage = linkedPackages.get(c.Billing_Account_Package__c);
                c.AccountId = linkedPackage.Account__r.Master_Account__c != null
                     ? linkedPackage.Account__r.Master_Account__c
                     : linkedPackage.Account__r.Id;
            }
        }

        private Boolean shouldPopulateMasterAccount(Case c) {
            return c.Billing_Account_Package__c != null
                && CaseHelper.CASE_RT_FOR_PACKAGE.contains(c.RecordTypeId);
        }
    }

    public class AttachContactInCases extends Triggers.TriggerHandlerBase {
        override public void handle() {
            CaseITHelpDeskHelper obj = new CaseITHelpDeskHelper();
            obj.checkContact(Trigger.new, RT_MAP_BY_ID);
            CaseITHelpDeskHelper.findMissingAccount(Trigger.new);
        }
    }

    public class MapContactOnTelusSharedCases extends Triggers.TriggerHandlerBase {
        // this functional covered in testMapFieldsForTelusCases
        override public void handle() {
            List<Case> newCaseIdsList = new List<Case>();
            for (Case caseObj : (List<Case>) Trigger.new) {
                if (caseObj.AccountId != null && caseObj.RecordTypeId != CaseHelper.RT_ID_SUPPORT_RC_APP) {
                    newCaseIdsList.add(caseObj);
                }
            }
            if (newCaseIdsList.size() != 0) {
                TelusExternalSharingHelperCls.mapContactOnTelusSharedCases(newCaseIdsList);
            }
        }
    }

    public class WebCaseRouting extends Triggers.TriggerHandlerBase {
        override public void handle() {
            // LTR-2556
            if (bypassForRCEvents) {
                return;
            }
            
            // Collect account IDs from web cases
            Set<Id> accountIds = new Set<Id>();
            for (Case caseObj : (List<Case>) Trigger.new) {
                if (caseObj.Origin == CaseHelper.CASE_ORIGIN_WEB && caseObj.AccountId != null) {
                    accountIds.add(caseObj.AccountId);
                }
            }
            
            if (accountIds.isEmpty()) {
                return;
            }
            
            // Get entitlements grouped by type
            Map<String, Set<Id>> accIdsBySupportType = AccountHelper.getSupportedAccountIdsGroupedBySupportType(accountIds);
            Set<Id> managedServicesAccountIds = accIdsBySupportType.get(CaseHelper.ENTITLEMENT_NAME_MANAGED_SERVICES) != null 
                ? accIdsBySupportType.get(CaseHelper.ENTITLEMENT_NAME_MANAGED_SERVICES) 
                : new Set<Id>();
            
            List<Case> casesToRoute = new List<Case>();
            
            for (Case caseObj : (List<Case>) Trigger.new) {
                if (caseObj.Origin != CaseHelper.CASE_ORIGIN_WEB) {
                    continue;
                }
                
                // Managed Services accounts: route all record types except excluded ones (takes precedence)
                if (managedServicesAccountIds.contains(caseObj.AccountId) && !isExcludedRecordType(caseObj.RecordTypeName__c)) {
                    casesToRoute.add(caseObj); 
                } 
                // Non-Managed Services accounts: only route Support Case record type
                else if (caseObj.RecordTypeId == CaseHelper.RT_ID_SUPPORT_CASE) {
                    casesToRoute.add(caseObj);
                }
            }
            
            if (!casesToRoute.isEmpty()) {
                CaseRouting.execute(casesToRoute, groupNameToGroup, accIdsBySupportType);
            }
        }

        private Boolean isExcludedRecordType(String recordTypeName) {
            return excludedRecordTypesForWebCaseRouting.contains(recordTypeName);
        }
    }

    public class CaseCreationOnPRM extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Group grp = groupNameToGroup.get(GroupHelper.RESSELER_TEAM_DEV_NAME.toLowerCase());
            for (Case caseObj : (List<Case>) triggerRecords) {
                try {
                    if (caseObj.RecordTypeId == CaseHelper.RT_ID_SALES_CUST_FORM) {
                        caseObj.Sales_Owner_Manager_Email__c = usersMap.get(caseObj.OwnerID)?.Manager.Email;
                    }

                    if (caseObj.RecordTypeId == CaseHelper.RT_ID_RESELLER_TEAM && grp != null) {
                        caseObj.OwnerId = grp.Id;
                    }
                } catch (Exception e) {
                    caseObj.Sales_Owner_Manager_Email__c = null;
                }
            }
        }
    }

    public class InsertManagerFieldForSupportRecordType extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (ProfileHelper.isCurrentUserSysAdmin()) {
                return;
            }
            Map<Id, Employee__c> empMap = getEmployeeIdToEmployeeMap();

            for (Case caseObj : (List<Case>) Trigger.new) {
                if (!Test.isRunningTest() && String.valueOf(caseObj.OwnerId).startsWith('00G')) {
                    continue;
                }

                Id caseOwnerProfileId = usersMap.get(caseObj.OwnerId)?.ProfileId;
                if (ProfileHelper.isSysAdmin(caseOwnerProfileId)) {
                    caseObj.Support_Owner_Manager__c = null;
                    continue;
                }

                String fName = empMap.get(caseObj.OwnerId)?.Manager_Employee_Number__r.First_Name__c;
                String lName = empMap.get(caseObj.OwnerId)?.Manager_Employee_Number__r.Last_Name__c;
                if (fName != null && lName != null) {
                    caseObj.Support_Owner_Manager__c = fName + ' ' + lName;
                }
            }
        }

        private Map<Id, Employee__c> getEmployeeIdToEmployeeMap() {
            Map<Id, Employee__c> empMap = new Map<Id, Employee__c>();
            for (Employee__c employee : (List<Employee__c>) new EmployeeSelector()
                    .selectEmployeeForDFR(new List<Object> { setUserId })
                    .selectFields(new List<String> {
                        'Manager_Employee_Number__r.First_Name__c',
                        'Manager_Employee_Number__r.Last_Name__c',
                        'User__c'
                    })
                    .setQueryCaching(true)
                    .executeQuery()
            ) {
                empMap.put(employee.User__c, employee);
            }

            return empMap;
        }
    }

    public class CalculateBalanceAndPortOutStatus extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Case caseObj : (List<Case>) Trigger.new) {
                try {
                    if (RT_MAP_BY_ID.get(caseObj.RecordTypeId)?.getName() != CaseHelper.RT_NAME_PORTING_OUT
                        || mapToCaseAccount.get(caseObj.AccountId) == null
                    ) {
                        continue;
                    }

                    calculateAccountBalance(caseObj);
                    getCasePortOut(caseObj);

                } catch (Exception e) {
                    PlatformLog.logException('Error CaseTriggerHandler.CalculateBalanceAndPortOutStatus', e);
                    caseObj.addError(e);
                }
            }
        }

        private void calculateAccountBalance(Case caseObj) {
            Account caseAcc = mapToCaseAccount.get(caseObj.AccountId);
            Date startDate = caseAcc?.Sales_Agreement_Start_Date__c;
            Date endDate = caseAcc?.Sales_Agreement_End_Date__c;

            if (endDate == null || startDate == null) {
                return;
            }

            if (System.today() < startDate) {
                Decimal n = Math.ceil(Decimal.valueOf(startDate.daysBetween(endDate)) / 30);
                caseObj.Account_Balance__c = n * NumberHelper.toNumber(caseAcc?.MRR__c);

            } else if (System.today() >= startDate && System.today() < endDate) {
                Decimal n = Math.ceil(Decimal.valueOf(System.today().daysBetween(endDate)) / 30);
                caseObj.Account_Balance__c = n * NumberHelper.toNumber(caseAcc?.MRR__c);

            } else if (System.today() >= endDate) {
                caseObj.Account_Balance__c = 0;
            }
        }

        private void getCasePortOut(Case caseObj) {
            Account caseAcc = mapToCaseAccount.get(caseObj.AccountId);

            if (String.isBlank(caseObj.No_Phone_Numbers_to_Port_Out__c)) {
                caseObj.No_Phone_Numbers_to_Port_Out__c = '0';
            }
            if (Integer.valueOf(caseObj.No_Phone_Numbers_to_Port_Out__c) <= NumberHelper.toNumber(caseAcc?.Number_of_DL_s__c)) {
                caseObj.Full_or_Partial_Port_Out__c = 'Partial';
            } else {
                caseObj.Full_or_Partial_Port_Out__c = 'Full';
            }
        }
    }

    public class PortOutCloseForCase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                List<Exception_And_Notification_History__c> lstEANH = new List<Exception_And_Notification_History__c>();

                for (Case caseObj : (List<Case>) Trigger.new) {
                    Account caseAcc = mapToCaseAccount.get(caseObj.AccountId);

                    if (caseAcc != null) {
                        caseObj.Account_Current_Owner__c = caseAcc.Current_Owner__c;
                    }

                    String strStatus = ((Case) Trigger.oldMap?.get(caseObj.id))?.Status;

                    if (RT_MAP_BY_ID.get(caseObj.RecordTypeId)?.getName() == CaseHelper.RT_NAME_PORTING_OUT
                        && strStatus != CaseHelper.CASE_STATUS_CLOSED
                        && caseObj.Status == CaseHelper.CASE_STATUS_CLOSED
                        && caseObj.AccountId != null
                        && NumberHelper.toNumber(caseAcc?.Number_of_DL_s__c) != 0
                    ) {
                        String toAddress = !String.isBlank(caseAcc?.Current_Owner_Email__c)
                            ? caseAcc.Current_Owner_Email__c
                            : caseAcc?.Most_Recent_Opportunity_Owner_Email__c;

                        if (!String.isBlank(toAddress) && toAddress != UserRC.rcsfSyncUserObj.Email__c) {
                            lstEANH.add(buildEANH(caseObj, caseAcc, toAddress));
                        }
                    }
                }

                if (lstEANH.size() > 0) {
                    insert lstEANH;
                }

            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.PortOutCloseForCase', e);
            }
        }

        private Exception_And_Notification_History__c buildEANH(Case caseObj, Account caseAcc, String toAddress) {
            return (Exception_And_Notification_History__c) new SObjectBuilder(Exception_And_Notification_History__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Exception_And_Notification_History__c.Email_Subject__c => 'Customer ' + caseAcc.Name + ' has just completed a ' + caseObj.Full_or_Partial_Port_Out__c,
                    Exception_And_Notification_History__c.To_Address_1__c => toAddress,
                    Exception_And_Notification_History__c.Object_Type__c => 'case - PortOut',
                    Exception_And_Notification_History__c.content_label_01__c => 'Account: ',
                    Exception_And_Notification_History__c.content_var_01__c => caseAcc.Name,
                    Exception_And_Notification_History__c.content_label_02__c => ' No. of DLs: ',
                    Exception_And_Notification_History__c.content_var_02__c => String.valueOf(StringHelper.safeString(caseAcc.Number_of_DL_s__c)),
                    Exception_And_Notification_History__c.content_label_03__c => 'Partial vs. Full: ',
                    Exception_And_Notification_History__c.content_var_03__c => caseObj.Full_or_Partial_Port_Out__c,
                    Exception_And_Notification_History__c.content_label_04__c => 'Account Balance on Port-Out: ',
                    Exception_And_Notification_History__c.content_var_04__c => 'USD '+ String.valueOf(StringHelper.safeString(caseObj.Account_Balance__c)),
                    Exception_And_Notification_History__c.content_label_05__c => 'Port Out Case Number: ',
                    Exception_And_Notification_History__c.content_var_05__c => caseObj.CaseNumber,
                    Exception_And_Notification_History__c.content_label_06__c => 'Port Out Case Link: ',
                    Exception_And_Notification_History__c.content_var_06__c => URL.getOrgDomainUrl().toExternalForm() + '/' + caseObj.Id
                })
                .build()
                .getRecord();
        }
    }

    public class HandleEngageDigitalCaseUpdates extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                for (Case caseObj : (List<Case>) Trigger.new) {
                    Case oldCaseObj = (Case) Trigger.OldMap?.get(caseObj.Id);
                    Group grpEngageDigital = groupNameToGroup.get(GroupHelper.ENGAGE_DIGITAL_DEV_NAME.toLowerCase());

                    Boolean isNewCaseAssignedToEngageDigital = oldCaseObj == null && caseObj.OwnerId != null && caseObj.OwnerId == grpEngageDigital.Id;
                    Boolean isCaseEscalatedToEngageDigital = oldCaseObj != null && caseObj.Support_Escalate_To__c != oldCaseObj.Support_Escalate_To__c && caseObj.Support_Escalate_To__c == 'RC Engage Digital Support';

                    if (isNewCaseAssignedToEngageDigital || isCaseEscalatedToEngageDigital) {
                        caseObj.Status = CaseHelper.CASE_STATUS_NEW;
                        caseObj.Engage_Case_Type__c = BooleanHelper.toBoolean(contactsMapFromCases.get(caseObj.ContactId)?.Preferred_Language__c.containsIgnoreCase('fr_'))
                            ? 'Digital case - FR'
                            : 'Digital case - EN';

                        if (Trigger.isUpdate) {
                            caseObj.OwnerId = grpEngageDigital.Id;
                            caseObj.RecordTypeId = CaseHelper.RT_ID_SUPPORT_CASE;
                        }
                    }
                }
            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.HandleEngageDigitalCaseUpdates', e);
            }
        }
    }

    public class UpdateCaseOwnerAndManagerDetails extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Case caseObj : (List<Case>) Trigger.new) {
                User caseUser = usersMap.get(caseObj.OwnerId);

                caseObj.Case_Owner_Manager_Email__c = StringHelper.safeString(caseUser?.Manager.Email);
                caseObj.Case_Owner_Manager_Title__c = StringHelper.safeString(caseUser?.Manager.Manager.Title);
                caseObj.Case_Owner_Supervisor_Title__c = StringHelper.safeString(caseUser?.Manager.Title);
                caseObj.Case_Owner_Supervisor__c = caseUser?.ManagerId;
                caseObj.Case_Owner_Manager__c = caseUser?.Manager.ManagerId;
            }
        }
    }

    public class ProcessT1ShippingAndUpdateDetails extends Triggers.TriggerHandlerBase {
        private Map<String, Id> rcUserIdToAccountId = new Map<String, Id>();
        private Map<Id, Contact> idToContact = new Map<Id, Contact>();
        private Map<Integer, String> caseIndexToUserID = new Map<Integer, String>();
        private Map<Integer, String> caseIndexToEmail = new Map<Integer, String>();
        private Map<Integer, String> caseIndexToCustomerName = new Map<Integer, String>();
        private Map<String, User> userEmailToUser = new Map<String, User>();
        private List<Case> t1ShippingCases = new List<Case>();

        override public void handle() {
            try {
                prepareDataFromTrigger();

                if (t1ShippingCases.isEmpty()) {
                    return;
                }
                prepareDataFromDB();

                for (Case caseObj : t1ShippingCases) {
                    Integer caseIndex = t1ShippingCases.indexOf(caseObj);
                    String contactId = getContactId(caseIndex);

                    caseObj.ContactId = contactId != null ? contactId : caseObj.ContactId;
                    caseObj.AccountId = rcUserIdToAccountId.get(caseIndexToUserID.get(caseIndex));

                    String caseEmail = caseIndexToEmail.get(caseIndex);
                    if (userEmailToUser.containsKey(caseEmail.toLowerCase())) {
                        caseObj.OwnerId = userEmailToUser.get(caseEmail).Id;
                        caseObj.Support_Owner_Manager__c = userEmailToUser.get(caseEmail).Manager.Name;
                    }
                }
            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.ProcessT1ShippingAndUpdateDetails', e);
            }
        }

        private void prepareDataFromTrigger() {
            for (Case caseObj : (List<Case>) Trigger.new) {
                if (!Label.NotForShippingEmail.equalsIgnoreCase(caseObj.SuppliedEmail)
                    || !String.valueOf(caseObj.RecordTypeId).equalsIgnoreCase(CaseHelper.RT_ID_SUPPORT_T1_SHIPPING)
                    || !RC_SUPPORT_AGENT.equalsIgnoreCase(usersMap.get(caseObj.OwnerId)?.Name)
                    || !RC_SUPPORT_AGENT.equalsIgnoreCase(usersMap.get(UserInfo.getUserId())?.Name)
                    || !CaseHelper.CASE_STATUS_NEW.equalsIgnoreCase(caseObj.Status)
                ) {
                    continue;
                }
                t1ShippingCases.add(caseObj);
                String description = caseObj.Description;
                Integer caseIndex = t1ShippingCases.indexOf(caseObj);

                if (description.indexOf(USER_ID) + 9 < description.indexOf(CUSTOMER_NAME) - 1) {
                    String userID = description.substring(description.indexOf(USER_ID) + 9, description.indexOf(CUSTOMER_NAME) - 1);
                    caseIndexToUserID.put(caseIndex, userID);
                }
                if (description.indexOf(CUSTOMER_NAME) + 15 < description.indexOf(RMA_COMMENTS) - 1) {
                    String customerName = description.substring(description.indexOf(CUSTOMER_NAME) + 15, description.indexOf(RMA_COMMENTS) - 1).toLowerCase();
                    caseIndexToCustomerName.put(caseIndex, customerName);
                }
                if (description.indexOf(CUSTOMER_CONTACT_EMAIL) + 24 < description.indexOf(USER_ID) - 1) {
                    String customerEmail = description.substring(description.indexOf(CUSTOMER_CONTACT_EMAIL) + 24, description.indexOf(USER_ID) - 1).toLowerCase();
                    caseIndexToEmail.put(caseIndex, customerEmail);
                }
            }
        }

        private void prepareDataFromDB() {
            for (Account acc: (List<Account>) new AccountSelector()
                    .selectAccounts()
                    .withoutSelectorFieldsIncluded()
                    .selectFields(new List<Schema.SObjectField> { Account.Id, Account.RC_User_ID__c })
                    .setCondition('RC_User_ID__c IN :bind0')
                    .subselect(new ContactSelector()
                        .selectContacts()
                        .withoutSelectorFieldsIncluded()
                        .selectFields(new List<Schema.SObjectField> {
                            Contact.Id,
                            Contact.Name,
                            Contact.AccountId,
                            Contact.CreatedDate
                        })
                        .setCondition('Name IN :bind1')
                    )
                    .setQueryBindings(new List<Object> { caseIndexToUserID.values(), caseIndexToCustomerName.values() })
                    .setQueryCaching(true)
                    .executeQuery()
            ) {
                rcUserIdToAccountId.put(acc.RC_User_ID__c, acc.Id);

                for (Contact c : acc.Contacts) {
                    idToContact.put(c.Id, c);
                }
            }

            for (User u : (List<User>) new UserSelector()
                    .selectUsers()
                    .selectFields(new List<String> { 'Id', 'Name', 'Email', 'Manager.Name' })
                    .setCondition('Email IN :bind0 AND IsActive = TRUE AND User_Profile_License__c = \'Salesforce\'')
                    .setQueryBindings(new List<Object> { caseIndexToEmail.values() })
                    .setQueryCaching(true)
                    .executeQuery()
            ) {
                userEmailToUser.put(u.Email, u);
            }
        }

        private Id getContactId(Integer caseIndex) {
            Id resultId;
            for (Contact cont : idToContact.values()) {
                if (cont.AccountId == rcUserIdToAccountId.get(caseIndexToUserID.get(caseIndex))
                    && cont.Name.equalsIgnoreCase(caseIndexToCustomerName.get(caseIndex).toLowerCase())
                    && (resultId == null || cont.CreatedDate > idToContact.get(resultId).CreatedDate)
                ) {
                    resultId = cont.Id;
                }
            }

            return resultId;
        }
    }

    public class HandleCaseForPortingESB extends Triggers.TriggerHandlerBase {
        override public void handle() {
            PortingESBHelper.updateCaseContact(Trigger.new);

            if (Test.isRunningTest() || Feature_Toggle__c.getInstance().ESBPortingNewFlow__c) {
                PortingESBHelper.updateContactName(Trigger.new);
            }
        }
    }

    public class AssignUserDetailsToCase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            // Relationship Survey Date Assignment
            List<Case> validCases = new List<Case>();
            Set<Id> contactIds = new Set<Id>();
            Set<String> helpDeskAndInfrastructureRtIds = new Set<String> {
                CaseHelper.RT_ID_IT_HELPDESK_SUPPORT,
                CaseHelper.RT_ID_IT_HELPDESK,
                CaseHelper.RT_ID_IT_INFRASTRUCTURE
            };

            for (Case c : (List<Case>) Trigger.new) {
                if (c.ContactId == null) {
                    c.User_Name__c = c.Title__c = c.Department__c = '';
                    continue;
                }

                if ((c.ContactId != ((Case) Trigger.oldMap?.get(c.Id))?.ContactId || Trigger.isInsert)
                    && helpDeskAndInfrastructureRtIds.contains(c.RecordTypeId)
                ) {
                    contactIds.add(c.ContactId);
                    validCases.add(c);
                }
            }

            if (validCases.isEmpty()) {
                return;
            }

            Map<Id, User> contactIdToUser = new Map<Id, User>();
            Set<String> emails = new Set<String>();

            List<Contact> contactsWithEmail = (List<Contact>) new ContactSelector()
                .selectContacts()
                .withoutSelectorFieldsIncluded()
                .selectFields(new List<Schema.SObjectField> { Contact.Id, Contact.Email })
                .setCondition('Id IN :bind0 AND Account.Name = \'RC Internal\' AND Email != null')
                .setQueryBindings(new List<Object> { contactIds })
                .setQueryCaching(true)
                .executeQuery();

            for (Contact con : contactsWithEmail) {
                emails.add(con.Email);
            }
            List<User> users = (List<User>) new UserSelector()
                .selectUsers()
                .withoutSelectorFieldsIncluded()
                .selectFields(new List<Schema.SObjectField> {
                    User.Id,
                    User.Email,
                    User.Name,
                    User.Manager__c,
                    User.Title,
                    User.Department
                })
                .setCondition('Email IN :bind0')
                .setQueryBindings(new List<Object> { emails })
                .setQueryCaching(true)
                .executeQuery();

            for (Contact con : contactsWithEmail) {
                for (User user : users) {
                    if (con.Email == user.Email) {
                        contactIdToUser.put(con.Id, user);
                        break;
                    }
                }
            }

            for (Case c : validCases) {
                User u = contactIdToUser.get(c.ContactId);
                c.User_Name__c = StringHelper.safeString(u?.Name);
                c.Title__c = StringHelper.safeString(u?.Title);
                c.Department__c = StringHelper.safeString(u?.Department);
            }
        }
    }

    /*
     * This trigger represents a Workflow Rule named "Update Contact Email (custom) and Contact Phone (custom) in Case":
     * Object: Case
     * Rule Criteria: "OR (NOT(ISBLANK( Contact.FirstName )), NOT(ISBLANK( Contact.LastName)) )"
     * Evaluation Criteria: "Evaluate the rule when a record is created, and every time it's edited"
     * */
    public class PopulateCaseFieldsWithContactFields extends Triggers.TriggerHandlerBase {
        public PopulateCaseFieldsWithContactFields() {
            super();
        }

        public PopulateCaseFieldsWithContactFields(List<Case> newCasesList) {
            super(newCasesList);
        }

        override public void handle() {
            for (Case caseRecord : (List<Case>) TriggerRecords) {
                this.inhabitCaseFieldsWithContactFields(caseRecord);
            }
        }

        private void inhabitCaseFieldsWithContactFields(Case caseRecord) {
            Contact contactObj = contactsMapFromCases.get(caseRecord.ContactId);
            if (this.isContactNameBlank(contactObj)) {
                return;
            }
            caseRecord.Contact_Email_custom__c = contactObj.Email;
            caseRecord.Contact_Phone_custom__c = contactObj.Phone;
        }

        private Boolean isContactNameBlank(Contact c) {
            return String.isBlank(c?.LastName) && String.isBlank(c?.FirstName);
        }
    }

    /*
     * This trigger represents a Workflow Rule named "Escalation Actual Date Update For Remaing":
     * Object: Case
     * Rule Criteria: "Case: Escalate To not equal to Support - System Ops,Telecom (Ops)"
     * Evaluation Criteria: "Evaluate the rule when a record is created, and any time it's edited to subsequently meet criteria"
     * */
    public class UpdateEscalationActualDate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Case caseRecord : (List<Case>) triggerRecords) {
                this.clearActualEscalationDate(caseRecord);
            }
        }

        private void clearActualEscalationDate(Case caseRecord) {
            if (this.shouldClearActualEscalation(caseRecord)) {
                caseRecord.Actual_Escalation__c = null;
            }
        }

        private Boolean shouldClearActualEscalation(Case caseRecord) {
            return Trigger.isInsert && !this.isEscalatedToOps(caseRecord)
                || Trigger.isUpdate && this.isRecordEditedToMeetCriteria(caseRecord);
        }

        private Boolean isRecordEditedToMeetCriteria(Case caseRecord) {
            Boolean isEscalatedToChangedFromOps = isChangedFieldFrom(caseRecord, Case.Support_Escalate_To__c, CaseHelper.SUPPORT_ESCALATE_TO_SYSTEM_OPS)
                || isChangedFieldFrom(caseRecord, Case.Support_Escalate_To__c, CaseHelper.SUPPORT_ESCALATE_TO_TELECOM_OPS);

            return isEscalatedToChangedFromOps && !this.isEscalatedToOps(caseRecord);
        }

        private Boolean isEscalatedToOps(Case caseRecord) {
            return isChangedFieldToAnyString(
                caseRecord,
                Case.Support_Escalate_To__c,
                new Set<String> {CaseHelper.SUPPORT_ESCALATE_TO_SYSTEM_OPS, CaseHelper.SUPPORT_ESCALATE_TO_TELECOM_OPS}
            );
        }
    }

    @TestVisible
    class AutoSyncParams {
        public Case targetCase;
        public Opportunity targetOpty;
        public Quote targetQuote;
        public List<Account> accsToUpdate;
        public QuoteLineItem targetQuoteLineItem;
        public Boolean isMPUB;

        @TestVisible
        private AutoSyncParams() {}

        public AutoSyncParams(Case affectedCase) {
            this.targetCase = affectedCase;

            List<Opportunity> oppList = (List<Opportunity>) new OpportunitySelector()
                .selectTechOptyForAutoSyncByMasterOppId(this.targetCase.Opportunity_Reference__c)
                .setQueryCaching(true)
                .executeQuery();
            for (Opportunity opp : oppList) {
                if (opp.IsMultiProductTechnicalOpportunity__c
                    && opp.Tier_Name__c == OpportunityHelper.TIER_RC_CONTACT_CENTER
                ) {
                    this.targetOpty = opp;
                    break;
                }
            }
            if (this.targetOpty == null) {
                this.targetOpty = oppList[0];
            }

            List<Quote> linkedQuotes = (List<Quote>) new QuoteSelector()
                .selectQuotes()
                .subselect(new QuoteLineItemSelector().selectQuoteLineItems())
                .subselect(new ServiceInfoSelector().selectServiceInfo())
                .setCondition('OpportunityId = :bind0')
                .setQueryBindings(this.targetOpty.Id)
                .setQueryCaching(true)
                .executeQuery();

            Quote primaryQuote = QuoteHelper.getPrimaryQuote(linkedQuotes, true);
            for (Quote qt : linkedQuotes) {
                if (qt.MasterQuote__c == primaryQuote.Id && QuoteHelper.isRCCC(qt)) {
                    this.isMPUB = !qt.ServiceInfo__r.isEmpty();
                    this.targetQuote = qt;
                    break;
                }
            }
            this.targetQuote = this.targetQuote == null ? primaryQuote : this.targetQuote;
            this.targetQuoteLineItem = (QuoteLineItem) QuoteLineItemHelper.getPrimaryQuoteLineItem(this.targetQuote);
            this.accsToUpdate = getAccountsToUpdate();
        }

        @TestVisible
        private List<Account> getAccountsToUpdate() {
            List<Account> accsToUpdate = new List<Account>();

            Account affectedAccount = this.targetOpty.Account;
            Case affectedCase = this.targetCase;
            Quote primaryQuote = this.targetQuote;
            QuoteLineItem primaryQuoteLineItem = this.targetQuoteLineItem;

            Boolean doUpdate = false;
            Account accToUpdate = new Account(Id = affectedAccount.Id);
            if (affectedAccount.Provision_Date__c == null) {
                accToUpdate.Provision_Date__c = affectedCase.Provision_Date__c;
                doUpdate = true;
            }

            if (shouldUpdateInContactBUId(affectedAccount)) {
                // inContact_account_ID__c can only be assigned to a Master Account
                Account masterAcc = setInContactBUIdToMasterAccount(affectedAccount, accToUpdate, affectedCase);
                if (accToUpdate.Id != masterAcc.Id) {
                    accsToUpdate.add(masterAcc);
                }
                doUpdate = true;
            }

            if (affectedAccount.inContact_Cluster__c == null) {
                accToUpdate.inContact_Cluster__c = affectedCase.inContact_Cluster__c;
                doUpdate = true;
            }

            if (affectedAccount.Service_Status__c == null) {
                accToUpdate.Service_Status__c = AccountHelper.SERVICE_STATUS_CONTRACT_COMPLETE;
                doUpdate = true;
            }

            if (primaryQuote != null) {
                accToUpdate.InContact_Service__c =
                    BillingWrappers.parseQuotePackageInfo(primaryQuote.Package_Info__c)?.edition?.name;
                doUpdate = true;
            }

            if (affectedAccount.No_of_InContact_Seats__c == null && primaryQuoteLineItem != null) {
                accToUpdate.No_of_InContact_Seats__c = primaryQuoteLineItem.NewQuantity__c;
                doUpdate = true;
            }

            if (doUpdate) {
                accsToUpdate.add(accToUpdate);
            }

            return accsToUpdate;
        }

        private Boolean shouldUpdateInContactBUId(Account affectedAccount) {
            return AccountHelper.getMasterAccount(affectedAccount).inContact_account_ID__c == null;
        }

        private Account setInContactBUIdToMasterAccount(Account affectedAccount, Account accToUpdate, Case affectedCase) {
            Account masterAccToUpdate = affectedAccount.IsMultiProductTechnicalAccount__c
                                    ? affectedAccount.Master_Account__r
                                    : accToUpdate;
            masterAccToUpdate.inContact_account_ID__c = String.valueOf(affectedCase.inContact_BU_ID__c?.intValue());
            return masterAccToUpdate;
        }

    }

    public class AutoSyncWithNGBS extends Triggers.TriggerHandlerBase {
        @TestVisible
        private AutoSyncParams params;

        override public void handle() {
            NGBSSyncables.ISyncable syncable;
            try {
                for (Case cs : (List<Case>) this.triggerRecords) {
                    if (
                        this.isChangedFieldFrom(cs, Case.inContact_Status__c, null)
                        && cs.RecordTypeId == CaseHelper.RT_ID_INCONTACT_ORDER
                        && cs.Opportunity_Reference__c != null
                    ) {
                        params = new AutoSyncParams(cs);
                        break;
                    }
                }

                if (params == null) {
                    return;
                }

                syncable = NGBSSyncables.getSyncable(params.isMPUB, params.targetQuote.Id, params.targetOpty);
                syncable.setICBProvisioning();
                syncable.updateSObject();

                if (OrderHelper.TYPE_CHANGE_ORDER.equalsIgnoreCase(params.targetCase.CC_Order_Type__c)) {
                    IcbHelper.startAutoSync(params.targetQuote.Id);
                }
            } catch (Exception e) {
                if (params != null) {
                    System.enqueueJob(new ICBNotificationQueueable(params.targetOpty, params.targetCase, e));
                } else {
                    PlatformLog.logException('Error CaseTriggerHandler.AutoSyncWithNGBS', e);
                }
            }

            try {
                if (params?.accsToUpdate.isEmpty() == false) {
                    update params.accsToUpdate;
                }
            } catch (Exception e) {
                System.enqueueJob(new ICBNotificationQueueable(
                    params.targetOpty,
                    params.targetCase,
                    'Failed to update Account: {0} Account Data: ' + params.accsToUpdate[0].Id,
                    e
                ));
            }
        }
    }

    public class ValidateCaseStatusForDealAndOrderSupportRT extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Case> newList = (List<Case>) triggerRecords;
            if (isInsert()) {
                validateStatusFieldOnInsert(newList);
            } else if (isUpdate()) {
                validateDOSCaseStatusFieldOnUpdate(newList);
            }
        }

        private void validateStatusFieldOnInsert(List<Case> newCasesList) {
            for (Case newCase : newCasesList) {
                if (newCase.RecordTypeId == CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT && newCase.Status != CaseHelper.CASE_STATUS_NEW) {
                    newCase.addError(Label.CaseDOSShouldBeInNewStatus);
                }
            }
        }

        private void validateDOSCaseStatusFieldOnUpdate(List<Case> newCases) {
            Boolean isUserInQueue = CaseHelper.isUserIsQueuesMember(CaseHelper.DEAL_AND_ORDER_SUPPORT_QUEUES_NAMES);
            Boolean isUserAllowedToChangeStatus = CustomPermissionHelper.currentUserHasPermissionSet(CustomPermissionHelper.PERMISSION_SET_LABEL_ALLOW_DOS_CASE_STATUS_CHANGE);
            if (isUserInQueue || isUserAllowedToChangeStatus) {
                return;
            }

            for (Case editedCase : newCases) {
                if (editedCase.RecordTypeId == CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT
                    && isChangedField(editedCase, Case.Status)
                ) {
                    editedCase.addError(Label.CaseOnlyQueueMemberCanChangeStatus);
                }
            }
        }
    }

    public class PopulateFields extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Case> newList = (List<Case>) triggerRecords;
            if (isInsert()) {
                populateOpportunityMRRonInsert(newList);
            } else if (isUpdate()) {
                populateOpportunityMRRonUpdate(newList, (Map<Id, Case>) oldMap());
            }
            populateDateFieldsOnCase(newList);
        }

        private void populateDateFieldsOnCase(List<Case> cases) {
            DateTime now = Datetime.now();
            for (Case cs : cases) {
                if (cs.Status == CaseHelper.CASE_STATUS_WIP) {
                    cs.TimeFromCreatedToWIP__c = HelperUtils.getTimeBetweenDates(cs.CreatedDate, now);
                    continue;
                }
                if (cs.Status != CaseHelper.CASE_STATUS_CLOSED && cs.Status != CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE) {
                    continue;
                }

                if (cs.TimeFromCreatedToWIP__c != null) {
                    DateTime dateWhenCaseWasInWip = CaseHelper.getOriginalTime(cs, 'TimeFromCreatedToWIP__c');
                    cs.TimeFromWIPToClosed__c = HelperUtils.getTimeBetweenDates(dateWhenCaseWasInWip, now);
                }
                if (cs.FirstResponseTime__c != null) {
                    DateTime firstResponseDate = CaseHelper.getOriginalTime(cs, 'FirstResponseTime__c');
                    cs.TimeFromFirstResponseToClosed__c = HelperUtils.getTimeBetweenDates(firstResponseDate, now);
                }
            }
        }

        private void populateOpportunityMRRonInsert(List<Case> casesNewList) {
            Set<Id> oppIds = new Set<Id>();

            for (Case caseItem : casesNewList) {
                oppIds.add(caseItem.Opportunity_Reference__c);
            }
            populateOpportunityMRR(oppIds, casesNewList);
        }

        private void populateOpportunityMRRonUpdate(List<Case> casesNewList, Map<Id, Case> caseOldMap) {
            Set<Id> oppIds = new Set<Id>();

            for (Case caseItem : casesNewList) {
                if (caseOldMap.get(caseItem.Id).Opportunity_Reference__c != caseItem.Opportunity_Reference__c) {
                    oppIds.add(caseItem.Opportunity_Reference__c);
                }
            }
            populateOpportunityMRR(oppIds, casesNewList);
        }

        private void populateOpportunityMRR(Set<Id> oppIds, List<Case> casesNewList) {
            if (oppIds.isEmpty()) {
                return;
            }

            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(
                (List<Opportunity>) new OpportunitySelector()
                    .selectOpportunitiesWithTotalMRRByIds(oppIds)
                    .executeQuery()
            );

            for (Case caseItem : casesNewList) {
                caseItem.OpportunityMRR__c = opportunityMap.get(caseItem.Opportunity_Reference__c)?.Total_MRR__c;
            }
        }
    }

    //Make 'Jira Number' and 'Incident Number' fields mandatory with 'Product/Platform Issues' record type cases
    public class ValidateCaseFieldsForProductIssues extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Case caseObj : (List<Case>) triggerRecords) {
                if (!isRTProductPlatfromIssues(caseObj)) {
                    continue;
                }

                if (caseObj.Type == CaseHelper.CASE_TYPE_PRODUCT_DEFECT
                    && caseObj.Support_Escalate_To__c == CaseHelper.CASE_TYPE_PRODUCT_DEFECT
                    && String.isBlank(caseObj.Jira__c)
                ) {
                    caseObj.Jira__c.addError(JIRA_NUMBER_REQUIRED_ERROR);
                }
                if (caseObj.Type == CaseHelper.CASE_TYPE_PLATFORM_INCIDENT
                    && caseObj.Support_Escalate_To__c == CaseHelper.CASE_TYPE_PLATFORM_INCIDENT
                    && String.isBlank(caseObj.Support_Jira__c)
                ) {
                    caseObj.Support_Jira__c.addError(INCIDENT_NUMBER_REQUIRED);
                }
            }
        }

        private Boolean isRTProductPlatfromIssues(Case caseObj) {
            return RT_MAP_BY_ID.get(caseObj.RecordTypeId)?.getName() == CaseHelper.RT_NAME_PRODUCT_PLATFORM_ISSUES;
        }
    }

    //Map Address fields from Telus to RC and populate Vendor Contact fields
    public class UpdateAddressAndContactInfoFieldsForTelusBrand extends Triggers.TriggerHandlerBase {
        override public void handle() {
            TelusExternalSharingHelperCls.mapTelusAddressToRCAddress((List<Case>) triggerRecords);
            TelusExternalSharingHelperCls.populateVendorContactFieds((List<Case>) triggerRecords);
        }
    }

    // Validate the input accepting for RCESB/Support Manager Porting, Support Agent Porting users only.
    public class ValidateFieldsForPortingCase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (!TriggerHandler.BY_PASS_CASE_Trigger && String.isNotBlank(UserInfo.getProfileId())) {
                Profile profile = getProfileById(UserInfo.getProfileId());
                if (profile == null) {
                    profile = new Profile();
                }
                PortingESBHelper.validateOnBeforeUpdateEvent((List<Case>) triggerRecords, (Map<Id, Case>) oldMap(), profile);
            }
        }

        private Profile getProfileById(Id profileId) {
            return (Profile) new ListOptional(new ProfileSelector()
                .selectProfileById(new List<Object> {profileId})
                .setQueryCaching(true)
                .executeQuery()
            ).getFirst();
        }
    }

    // Populate primary Contact for Porting Case
    public class PopulateContactForPortingCase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            PortingESBHelper.populatePrimaryContactForPortingCase((List<Case>) triggerRecords, CaseTriggerHandler.RT_MAP_BY_ID);
        }
    }

    // Update related Orders if fields are changed
    public class UpdateRelatedOrders extends Triggers.TriggerHandlerBase {
        Map<SObjectField, SObjectField> caseToOrderFieldsMap = new Map<SObjectField, SObjectField> {
            Case.inContact_BU_ID__c => Order.inContact_Account_ID__c,
            Case.Provision_Date__c => Order.Provision_Date__c,
            Case.inContact_Cluster__c => Order.inContact_Cluster__c,
            Case.inContact_Status__c => Order.Status
        };

        override public void handle() {
            Map<Id, Order> orderToUpdateMap = new Map<Id, Order>();
            for (Case caseObj : (List<Case>) triggerRecords) {
                if (!isRTInContactOrder(caseObj) || String.isBlank(caseObj.Order__c)) {
                    continue;
                }

                if (isChangedField(caseObj, Case.inContact_BU_ID__c)) {
                    populateOrdersToUpdateMap(orderToUpdateMap, caseObj, Case.inContact_BU_ID__c);
                }

                if (isChangedField(caseObj, Case.Provision_Date__c)) {
                    populateOrdersToUpdateMap(orderToUpdateMap, caseObj, Case.Provision_Date__c);
                }

                if (isChangedField(caseObj, Case.inContact_Cluster__c)) {
                    populateOrdersToUpdateMap(orderToUpdateMap, caseObj, Case.inContact_Cluster__c);
                }

                if (isChangedFieldToAnyString(caseObj, Case.inContact_Status__c, CaseHelper.CASE_IN_CONTACT_STATUSES)) {
                    populateOrdersToUpdateMap(orderToUpdateMap, caseObj, Case.inContact_Status__c);
                }
            }

            if (!orderToUpdateMap.isEmpty()) {
                update orderToUpdateMap.values();
            }
        }

        private void populateOrdersToUpdateMap(Map<Id, Order> orderToUpdateMap, Case caseObj, SObjectField caseField) {
            SObjectField orderField = caseToOrderFieldsMap.get(caseField);
            Object caseFieldValue = getCaseFieldValue(caseObj, caseField);

            Order orderObj = orderToUpdateMap.get(caseObj.Order__c) != null
                ? orderToUpdateMap.get(caseObj.Order__c)
                : new Order(Id = caseObj.Order__c);
            orderObj.put(orderField, caseFieldValue);
            orderToUpdateMap.put(caseObj.Order__c, orderObj);
        }

        private Object getCaseFieldValue(Case caseObj, SObjectField caseField) {
            if (caseObj.get(caseField) instanceOf Date) {
                return (Date) caseObj.get(caseField);
            }
            return caseField == Case.inContact_Status__c
                ? getOrderStatusByCaseInContactStatus(caseObj.inContact_Status__c)
                : String.valueOf(caseObj.get(caseField));
        }

        private Boolean isRTInContactOrder(Case caseObj) {
            return RT_MAP_BY_ID.get(caseObj.RecordTypeId)?.getName() == CaseHelper.RT_NAME_INCONTACT_ORDER;
        }

        private String getOrderStatusByCaseInContactStatus(String status) {
            return status == CaseHelper.CASE_STATUS_COMPLETED ? OrderHelper.STATUS_PROVISIONED : OrderHelper.STATUS_REQUIRES_ATTENTION;
        }
    }

    // When any other tier escalate cases back to Support tier 1,
    // change case owner to the case creator if the case creator has the Support T1 profile and agent is active user.
    public class ChangeCaseOwnerForSupportT1User extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Boolean hasCustomPermissionSupportAgentT1 = FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_SUPPORT_AGENT_T1);
            for (Case caseObj : (List<Case>) triggerRecords) {
                User user = usersMap.get(caseObj.CreatedById);
                if (user == null) {
                    continue;
                }

                if (isChangedFieldTo(caseObj, Case.Support_Escalate_To__c, CaseHelper.SUPPORT_ESCALATE_TO_TIER_1)
                    && caseObj.Support_Tier_1_Esc_Count__c >= 1
                    && (ProfileHelper.isSupportT1Profile(user.ProfileId) || hasCustomPermissionSupportAgentT1)
                    && user.IsActive
                ) {
                    caseObj.OwnerId = caseObj.CreatedById;
                }
            }
        }
    }

    public class PopulateCasePortingFields extends Triggers.TriggerHandlerBase {
        Map<String, String> portingRejectReasonMap = new Map<String, String> {
            'LEC request COB' => 'COB',
            'PIN not Found' => 'PIN',
            'Incorrect account number' => 'Account',
            'Illegible auth name/name missing' => 'LOA'
        };
        Date today = Date.today();
        override public void handle() {
            for (Case caseObj : (List<Case>) triggerRecords) {
                if (isChangedFieldTo(caseObj, Case.Status, CaseHelper.CASE_STATUS_SUBMIT)) {
                    updatePortingSubmitDates(caseObj);
                }

                if (caseObj.Porting_First_Submit_Date__c != null
                    && String.isBlank(caseObj.Porting_First_Reject_Reason__c)
                    && isChangedFieldTo(caseObj, Case.Status, CaseHelper.CASE_STATUS_REJECT)
                ) {
                    caseObj.Porting_First_Reject_Reason__c = caseObj.Porting_Reject_Reason__c;
                }

                if ((isChangedFieldTo(caseObj, Case.Status, CaseHelper.CASE_STATUS_CLOSED) && caseObj.Porting_Complete_Date__c == null)
                    && CaseHelper.CASE_RTS_FOR_PORTING_FIELDS.contains(RT_MAP_BY_ID.get(caseObj.RecordTypeId)?.getName())
                ) {
                    caseObj.Porting_Complete_Date__c = today;
                }

                if ((caseObj.Status == CaseHelper.CASE_STATUS_SUBMIT || caseObj.Status == CaseHelper.CASE_STATUS_REJECT)
                    && String.isBlank(caseObj.Porting_RC_Review__c)
                ) {
                    caseObj.Porting_RC_Review__c = caseObj.Status == CaseHelper.CASE_STATUS_SUBMIT
                        ? CaseHelper.CASE_PORTING_RC_REVIEW_ACCEPTED
                        : CaseHelper.CASE_PORTING_RC_REVIEW_REJECTED;
                }

                if (String.isBlank(caseObj.Porting_RC_Review_Reject_Reason__c) && caseObj.Porting_RC_Review__c == CaseHelper.CASE_PORTING_RC_REVIEW_REJECTED) {
                    caseObj.Porting_RC_Review_Reject_Reason__c = mapRCRejectReviewReason(caseObj.Porting_Reject_Reason__c);
                }
            }
        }

        private String mapRCRejectReviewReason(String rejectReason) {
            String rcRejectReviewReason = portingRejectReasonMap.get(rejectReason);
            return String.isBlank(rcRejectReviewReason) ? REJECT_REVIEW_REASON_NO_VALUE : rcRejectReviewReason;
        }

        private Date getPortingSubmitDate(Date lastChangeDate) {
            return lastChangeDate != null ? lastChangeDate : today;
        }

        private void updatePortingSubmitDates(Case caseObj) {
            Date portingAdminChangeDate = getPortingSubmitDate(caseObj.Porting_Admin_Last_Change_Date__c);
            caseObj.Porting_Last_Submit_Date__c = portingAdminChangeDate;
            if (caseObj.Porting_First_Submit_Date__c == null) {
                caseObj.Porting_First_Submit_Date__c = portingAdminChangeDate;
            }
        }
    }

    public class CreateSurveysForPortingInRTCases extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Survey__c> surveyForPortingCases = new List<Survey__c>();
            for (Case caseObj : (List<Case>) triggerRecords) {
                if (!isValidCase(caseObj)) {
                    continue;
                }
                try {
                    surveyForPortingCases.add(
                        buildSurveyForCase(caseObj, SurveyHelper.SURVEY_TYPE_PORTING)
                    );
                } catch (Exception e) {
                    caseObj.addError(e);
                }
            }

            createSurveys(surveyForPortingCases, CreateSurveysForPortingInRTCases.class.getName());
        }

        private Map<Id, Integer> getContactIdToCaseCount() {
            Map<Id, Integer> contactIdToPortingCaseCount = new Map<Id, Integer>();
            for (AggregateResult result : (List<AggregateResult>) new CaseSelector().newQueryFactory()
                .setFactoryName('selectContactIdToCaseCount')
                .setAggregateFunction(QueryFactory.AggregateFunction.COUNT, Case.Id)
                .setCondition('ContactId IN :bind0 AND RecordType.Name IN :bind1 AND Status IN :bind2')
                .setGroupBy(Case.ContactId)
                .setQueryBindings(new List<Object> {contactsMapFromCases.keySet(), CaseHelper.CASE_RTS_FOR_PORTING_SURVEY, CaseHelper.CASE_STATUSES_FOR_RELATED_CONTACT})
                .setQueryCaching(true)
                .executeQuery()
            ) {
                contactIdToPortingCaseCount.put((Id) result.get('ContactId'), (Integer) result.get('expr0'));
            }
            return contactIdToPortingCaseCount;
        }

        private Boolean isValidCase(Case caseObj) {
            Boolean isCaseStatusEligible = CaseHelper.CASE_STATUSES_FOR_SURVEY.contains(caseObj.Status) && isChangedField(caseObj, Case.Status);
            if (!isCaseStatusEligible || HelperUtils.isMedallia) {
                return false;
            }
            Boolean isCaseFound = caseWithoutSurveyMap.get(caseObj.Id) != null;
            Map<Id, Integer> contactIdToCaseCountMap = getContactIdToCaseCount();
            Boolean isSinglePortingCasePerContact = contactIdToCaseCountMap.get(caseObj.ContactId) == 1;
            Boolean isRingCentralBrandCase = OpportunityHelper.BRAND_RINGCENTRAL.equalsIgnoreCase(mapToCaseAccount.get(caseObj.AccountId)?.RC_Brand__c);
            return isCaseFound && isSinglePortingCasePerContact && isRingCentralBrandCase;
        }
    }

    public class CreateSurveysForSupportCSATRTCases extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Survey__c> surveyForCSATCases = new List<Survey__c>();
            for (Case caseObj : (List<Case>) triggerRecords) {
                if (!isValidCase(caseObj)) {
                    continue;
                }
                Set<Id> contactIdsWithSurveys = getContactIdsWithSurveys(SurveyHelper.SURVEY_TYPES_FOR_SUPPORT_TO_SEND_SURVEYS);
                Boolean isCaseContactWithoutSurveys = caseObj.ContactId != null && !contactIdsWithSurveys.contains(caseObj.ContactId);
                if (RT_MAP_BY_ID.get(caseObj.RecordTypeId)?.getName() == CaseHelper.RT_NAME_SUPPORT_T1_VAR_PARTNERS && isCaseContactWithoutSurveys) {
                    try {
                        surveyForCSATCases.add(
                            buildSurveyForCase(caseObj, SurveyHelper.SURVEY_TYPE_VAR_SUPPORT_CSAT)
                        );
                    } catch (Exception e) {
                        caseObj.addError(e);
                    }
                    continue;
                }

                String accountBrand = mapToCaseAccount.get(caseObj.AccountId)?.RC_Brand__c;
                String surveyType = getSurveyType(caseObj);
                if (!isSuitableAccountBrand(accountBrand) || String.isBlank(surveyType)) {
                    continue;
                }

                try {
                    surveyForCSATCases.add(
                        buildSurveyForCase(caseObj, surveyType)
                    );
                } catch (Exception e) {
                    caseObj.addError(e);
                }
            }

            createSurveys(surveyForCSATCases, CreateSurveysForSupportCSATRTCases.class.getName());
        }

        private Boolean isSuitableAccountBrand(String brand) {
            return String.isNotBlank(brand)
                && (brand.startsWithIgnoreCase(OpportunityHelper.BRAND_RINGCENTRAL)
                || brand.equalsIgnoreCase(OpportunityHelper.BRAND_ATTOFFICE)
                || brand.equalsIgnoreCase(OpportunityHelper.BRAND_RINGCENTRAL_OFFICE_HAND_ATT)
                || brand.equalsIgnoreCase(OpportunityHelper.BRAND_CLEARWIRE)
                || brand.equalsIgnoreCase(OpportunityHelper.BRAND_TELUS_BUSINESS_CONNECT));
        }

        private String getSurveyType(Case caseObj) {
            String recordTypeName = RT_MAP_BY_ID.get(caseObj.RecordTypeId)?.getName();
            String surveyType;
            if (recordTypeName == CaseHelper.RT_NAME_PORTING_PHONE) {
                surveyType = SurveyHelper.SURVEY_TYPE_PORTING_PHONE_SUPPORT;
            } else if (recordTypeName == CaseHelper.RT_NAME_SUPPORT_TECH_ASSIST || caseObj.Product_Assistance__c != CaseHelper.CASE_PRODUCT_ASSISTANCE) {
                surveyType = SurveyHelper.SURVEY_TYPE_SUPPORT_CSAT;
            }

            return surveyType;
        }

        private Boolean isValidCase(Case caseObj) {
            if (!isCaseEligibleForSurveyCreation(caseObj)) {
                return false;
            }

            Boolean isCaseMeetSupportDispositionLevels = caseObj.Support_Disposition_Level_1__c != CaseHelper.INTERNAL_WORK_FLOW
                && !CaseHelper.SUPPORT_DISPOSITION_LEVELS_2.contains(caseObj.Support_Disposition_Level_2__c)
                && caseObj.Support_Disposition_Level_3__c != CaseHelper.LEVEL_BLOCKED_COUNTRY;
            return isCaseMeetSupportDispositionLevels && caseWithoutSurveyMap.get(caseObj.Id) != null;
        }
    }

    public class CreateSurveysForITRTCases extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Survey__c> surveyForITCases = new List<Survey__c>();
            for (Case caseObj : (List<Case>) triggerRecords) {
                if (!isValidCase(caseObj)) {
                    continue;
                }
                try {
                    String surveyType = RECORD_TYPES_ID_TO_NAME_TO_CREATE_SURVEYS.get(caseObj.RecordTypeId);
                    surveyForITCases.add(
                        buildSurveyForCase(caseObj, surveyType)
                    );
                } catch (Exception ex) {
                    caseObj.addError(ex);
                }
            }

            createSurveys(surveyForITCases, CreateSurveysForITRTCases.class.getName());
        }

        private Boolean isValidCase(Case caseObj) {
            if (!CaseHelper.CASE_RTS_FOR_IT_SURVEYS.contains(RT_MAP_BY_ID.get(caseObj.RecordTypeId)?.getName())) {
                return false;
            }
            Set<Id> contactIdsWithSurveys = getContactIdsWithSurveys(SurveyHelper.SURVEY_TYPES_FOR_IT_TO_SEND_SURVEYS);
            Boolean isCaseContactWithoutSurveys = caseObj.ContactId != null && !contactIdsWithSurveys.contains(caseObj.ContactId);
            return isChangedFieldTo(caseObj, Case.Status, CaseHelper.CASE_STATUS_CLOSED)
                && caseObj.Request_Type__c != CaseHelper.CASE_STATUS_DUPLICATE
                && isCaseContactWithoutSurveys;
        }
    }

    public class CreateSurveysForBizServRTCases extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Survey__c> surveyForBizServCases = new List<Survey__c>();
            for (Case caseObj : (List<Case>) triggerRecords) {
                if (!isValidCase(caseObj)) {
                    continue;
                }
                try {
                    surveyForBizServCases.add(
                        buildSurveyForCase(caseObj, SurveyHelper.SURVEY_TYPE_BIZ_SERV_CRM)
                    );
                } catch (Exception ex) {
                    caseObj.addError(ex);
                }

            }

            createSurveys(surveyForBizServCases, CreateSurveysForBizServRTCases.class.getName());
        }

        private Boolean isValidCase(Case caseObj) {
            if (RT_MAP_BY_ID.get(caseObj.RecordTypeId)?.getName() != CaseHelper.RT_NAME_INTERNAL_BUSINESS_SERVICES) {
                return false;
            }
            Set<Id> contactIdsWithSurveys = getContactIdsWithSurveys(SurveyHelper.SURVEY_TYPES_FOR_BIZSERV_TO_SEND_SURVEYS);
            Boolean isCaseContactWithoutSurveys = caseObj.ContactId != null && !contactIdsWithSurveys.contains(caseObj.ContactId);
            return isChangedFieldTo(caseObj, Case.Status, CaseHelper.CASE_STATUS_CLOSED)
                && caseObj.Is_Quickwin__c == CaseHelper.IS_QUICKWIN_SUPPORT
                && caseObj.Resolution_Code__c == CaseHelper.RESOLUTION_CODE_RESOLVED_SUCCESSFULLY
                && isCaseContactWithoutSurveys;
        }
    }

    public class CreateSurveysForSupportMedalliaCases extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Case> casesForMedalliaSurvey = new List<Case>();
            for (Case caseObj : (List<Case>) triggerRecords) {
                if (!isValidCase(caseObj)) {
                    continue;
                }

                caseObj.MedalliaRecordAlreadyCreated__c = true;
                casesForMedalliaSurvey.add(caseObj);
            }

            if (!casesForMedalliaSurvey.isEmpty()) {
                try {
                    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
                    if (!TriggerHandler.BY_PASS_CASE_ON_UPDATE && !bypassTrigger.Bypass_Medallia_Survey__c) {
                        MedalliaSurveyHelper.insertSupportMedalliaSurvey(casesForMedalliaSurvey, CaseTriggerHandler.RT_MAP_BY_ID);
                    }
                    TriggerHandler.BY_PASS_CASE_ON_UPDATE();
                } catch(Exception ex) {
                    PlatformLog.logException('Error CaseTriggerHandler.CreateSurveysForSupportMedalliaCases', ex);
                }
            }
        }

        private Boolean isValidCase(Case caseObj) {
            if (!isCaseEligibleForSurveyCreation(caseObj) || !HelperUtils.isMedallia) {
                return false;
            }
            if (String.isBlank(caseObj.Support_Disposition_Level_1__c)
                && CaseHelper.INTERNAL_WORKFLOW.equalsIgnoreCase(caseObj.Support_Disposition_Level_1__c)
                && String.isBlank(caseObj.CloseCustomerSupportLevel1__c)
            ) {
                return false;
            }
            Account acc = mapToCaseAccount.get(caseObj.AccountId);
            Boolean isNotTelusBrand = !OpportunityHelper.BRAND_TELUS_BUSINESS_CONNECT.equalsIgnoreCase(acc?.RC_Brand__c);
            return isNotTelusBrand && !caseObj.MedalliaRecordAlreadyCreated__c && String.isNotBlank(caseObj.ContactId);
        }
    }

    public class SendMedalliaInvitation extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                sendInvitation((List<Case>) triggerRecords);
            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.SendMedalliaInvitation', e);
            }
        }

        //CR-86101: Send Medallia Invitation
        private void sendInvitation(List<Case> newCaseList) {
            List<Case> caseListToSend = new List<Case>();
            Map<Id, Case> caseIdWithMap = new Map<Id, Case>();
            for (Case c : newCaseList) {
                if (!shouldProceedWithCase(c)) {
                    continue;
                }
                caseIdWithMap.put(c.Id, c);
                if (c.RecordTypeId != CaseHelper.RT_ID_CERT || c.Call_Outcome__c != CaseHelper.CALL_OUTCOME_CANCELLED) {
                    caseListToSend.add(c);
                }
            }
            if (caseIdWithMap.isEmpty()) {
                return;
            }

            Set<String> eRFLabels = new Set<String> {
                'Account.Owner.Email', 						 	// Account Owner
                'Account.Account_Owner_Manager_Email__c', 		// Account Owner Manager
                'Account.Current_Owner__r.Email',              	// Current Owner
                'Account.Current_Owner_Manager_Email__c', 		// Current Owner Manager
                'Account.CSM__r.Email',							// CSM
                'Account.CSM__r.manager.Email',					// CSM Manager
                'Account.Technical_Account_Manager__r.Email',  	// TAM
                'Case_Owner_Email__c',                   		// CERT agent (based on Case created by)
                'Case_Owner_Manager_Email__c'            		// CERT agent Manager (based on Case created by)
            };
            Set<SObjectField> fieldsToQuery = new Set<SobjectField> {
                Case.Id,
                Case.CaseNumber,
                Case.Brand_Account__c,
                Case.AccountId,
                Case.ContactId
            };
            List<Case> casesToBeUpdated = (List<Case>) new CaseSelector()
                .selectCasesByIds(caseIdWithMap.keySet())
                .selectFields(eRFLabels)
                .selectFields(fieldsToQuery)
                .executeQuery();

            for (Case c : casesToBeUpdated) {
                caseIdWithMap.get(c.Id).Email_Recipient_Fields_Medallia__c = String.join(getEmails(c), '|');
            }
            if (!caseIdWithMap.isEmpty() && !caseListToSend.isEmpty()){
                MedalliaSurveyHelper.sendMedalliaInvitation(caseIdWithMap.values(), new List<Account>());
            }
        }

        private Boolean shouldProceedWithCase(Case c) {
            return isUpdate()
                && (c.AccountId != null && isChangedFieldTo(c, Case.Status, CaseHelper.CASE_STATUS_CLOSED));
        }

        private Set<String> getEmails(Case c) {
            Set<String> emails = new Set<String>();
            collectEmailsFromAcc(c.Account, emails);
            emails.add(c.Case_Owner_Email__c);
            emails.add(c.Case_Owner_Manager_Email__c);

            emails.removeAll(new Set<String> {null, ''});
            return emails;
        }

        private void collectEmailsFromAcc(Account acc, Set<String> emails) {
            if (acc == null) {
                return;
            }
            emails.add(acc.Owner?.Email);
            emails.add(acc.Account_Owner_Manager_Email__c);
            emails.add(acc.Current_Owner__r?.Email);
            emails.add(acc.Current_Owner_Manager_Email__c);
            emails.add(acc.CSM__r?.Email);
            emails.add(acc.CSM__r?.Manager?.Email);
            emails.add(acc.Technical_Account_Manager__r?.Email);
        }
    }

    /* Case 07225831: (QW) Automation on Support CNR Cases
    If case record type one of (T1, T2, T3, Chat, Case, QoS, and T1 (VAR and Partners))
    And status has been changed from 'Waiting on Customer' to 'Updated by Customer'
    Then change Case Owner from 'CNR Queue' to the last agent who handled the case
    And Case.CNR_Status__c = false
    */
    public class UpdateSupportCNRCases extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                transferCaseFromCNRQueueToLastActiveCaseOwner((Map<Id, Case>) newMap());
            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.UpdateSupportCNRCases', e);
            }
        }

        private void transferCaseFromCNRQueueToLastActiveCaseOwner(Map<Id,Case> caseMap) {
            Set<Id> caseIds = getFilteredCases(caseMap);
            if (caseIds.isEmpty()) {
                return;
            }

            Map<Id, List<Id>> caseIdToOldOwners = getPreviousUserCaseOwnerMap(caseIds);
            if (caseIdToOldOwners.isEmpty()){
                return;
            }

            Set<Id> ownerIds = getPreviousUserCaseOwnerIds(caseIdToOldOwners);
            if (ownerIds.isEmpty()) {
                return;
            }

            Set<Id> activeUserIds = getActiveUserIds(ownerIds);
            if (activeUserIds.isEmpty()) {
                return;
            }

            setActiveUserAsNewCaseOwner(caseMap, caseIdToOldOwners, activeUserIds);
        }

        private Set<Id> getFilteredCases(Map<Id, Case> caseMap) {
            Set<Id> caseIds = new Set<Id>();
            for (Case c : caseMap.values()) {
                if (!checkIfCaseShouldBeFiltered(c)) {
                    caseIds.add(c.Id);
                }
            }
            return caseIds;
        }

        private Boolean checkIfCaseShouldBeFiltered(Case c) {
            return c.OwnerId != CaseHelper.CNRQUEUE_ID
                || !CaseHelper.CASE_RT_IDS_TO_REASSIGN_ON_LAST_CASE_OWNER.contains(c.RecordTypeId)
                || !isChangedFieldFrom(c, Case.Status, CaseHelper.CASE_STATUS_WAITING_ON_CUSTOMER)
                || !isChangedFieldTo(c, Case.Status, CaseHelper.CASE_STATUS_UPDATED_BY_CUSTOMER);
        }

        private Map<Id, List<Id>> getPreviousUserCaseOwnerMap(Set<Id> caseIds) {
            Map<Id, List<Id>> caseIdToOldOwners = new Map<Id, List<Id>>();
            SObjectType userType = User.sObjectType;
            List<CaseHistory> caseHistories = (List<CaseHistory>) new CaseHistorySelector()
                .selectCaseHistoriesForCasesAndByField(new List<Object> {caseIds, 'Owner'})
                .addOrdering(CaseHistory.CaseId, QueryFactory.SortOrder.ASCENDING)
                .addOrdering(CaseHistory.CreatedDate, QueryFactory.SortOrder.DESCENDING)
                .executeQuery();

            for (CaseHistory chObj : caseHistories) {
                Id newOwnerId = (Id) String.valueOf(chObj.NewValue);
                Id oldOwnerId = (Id) String.valueOf(chObj.OldValue);
                if (!caseIdToOldOwners.containsKey(chObj.CaseId) && newOwnerId.getSobjectType() == userType) {
                    caseIdToOldOwners.put(chObj.CaseId, new List<Id> { newOwnerId });
                } else if (oldOwnerId.getSobjectType() == userType) {
                    caseIdToOldOwners.get(chObj.CaseId).add(oldOwnerId);
                }
            }
            return caseIdToOldOwners;
        }

        private Set<Id> getPreviousUserCaseOwnerIds(Map<Id,List<Id>> caseIdToOldOwners) {
            Set<Id> ownerIds = new Set<Id>();
            for (Id caseId : caseIdToOldOwners.keySet()) {
                ownerIds.addAll(caseIdToOldOwners.get(caseId));
            }
            return ownerIds;
        }

        private Set<Id> getActiveUserIds(Set<Id> ownerIds) {
            Set<Id> activeUserIds = new Set<Id>();
            List<User> users = (List<User>) new UserSelector()
                .selectUsersByIds(ownerIds)
                .withoutSelectorFieldsIncluded()
                .selectField(User.Id)
                .addCondition('IsActive = true')
                .executeQuery();
            for (User usrObj : users) {
                activeUserIds.add(usrObj.Id);
            }
            return activeUserIds;
        }

        private void setActiveUserAsNewCaseOwner(Map<Id,Case> caseMap, Map<Id,List<Id>> caseIdToOldOwners, Set<Id> activeUserIds) {
            for (Id caseId : caseIdToOldOwners.keySet()) {
                for (Id ownerId : caseIdToOldOwners.get(caseId)) {
                    if (!activeUserIds.contains(ownerId)) {
                        continue;
                    }

                    caseMap.get(caseId).OwnerId = ownerId;
                    caseMap.get(caseId).CNR_Status__c = false;
                    break;
                }
            }
        }
    }

    public class UpdateDescriptionCodeForCases extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                JeopardyHelper.updateDescriptionCodeForCompletedCase((Map<Id, Case>) Trigger.newMap);
            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.UpdateDescriptionCodeForCases', e);
            }
        }
    }

    public class PopulateCaseDates extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                medalliaPopulateDate((List<Case>) triggerRecords);
            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.PopulateCaseDates', e);
            }
        }

        // Relationship Survey Date Assigned, Date Received field update
        private void medalliaPopulateDate(List<Case> newCaseList) {
            Date today = Date.today();
            for (Case newCase : newCaseList) {
                if (isInsert()) {
                    newCase.Date_Assigned__c = today;
                    newCase.Date_Received__c = today;
                } else if (isUpdate() && isChangedField(newCase, Case.OwnerId)) {
                    newCase.Date_Assigned__c = today;
                }
            }
        }
    }

    public class CreateCaseFeedForParentCase extends Triggers.TriggerHandlerBase {
        private final String TEXT_POST_CASE_FEED_TYPE = 'TextPost';
        override public void handle() {
            try {
                Map<Id, Case> parentCaseIdToChildCase = getParentCaseIdToChildCaseMap();
                if (parentCaseIdToChildCase.isEmpty()) {
                    return;
                }
                insert buildCaseFeedItems(parentCaseIdToChildCase);

            } catch (Exception e) {
                PlatformLog.logException('Error CaseTriggerHandler.CreateCaseFeedForParentCase', e);
            }
        }

        private List<FeedItem> buildCaseFeedItems(Map<Id, Case> parentCaseIdToChildCase) {
            List<FeedItem> caseFeeds = new List<FeedItem>();

            for (Id parentCaseId : parentCaseIdToChildCase.keySet()) {
                FeedItem cf = (FeedItem) new SObjectBuilder(FeedItem.SObjectType)
                    .setFields(new Map<SObjectField, Object> {
                        FeedItem.ParentId => parentCaseId,
                        FeedItem.Body => getCaseFeedBody(parentCaseIdToChildCase.get(parentCaseId)),
                        FeedItem.Type => TEXT_POST_CASE_FEED_TYPE,
                        FeedItem.IsRichText => true
                    })
                    .build()
                    .getRecord();
                caseFeeds.add(cf);
            }

            return caseFeeds;
        }

        private Map<Id, Case> getParentCaseIdToChildCaseMap() {
            Map<Id, Case> parentCaseIdToChildCase = new Map<Id, Case>();
            for (Case newCase : (List<Case>) triggerRecords) {
                if (newCase.ParentId == null) {
                    continue;
                }
                parentCaseIdToChildCase.put(newCase.ParentId, newCase);
            }

            return parentCaseIdToChildCase;
        }

        private String getCaseFeedBody(Case childCase) {
            return String.format(Label.Case_Feed_Item_Message_Created, new List<String> { generateCaseURL(childCase) });
        }

        private String generateCaseURL(Case childCase) {
            return '<a href="' + StringHelper.createObjectLink(childCase.Id) + '">' + childCase.CaseNumber + '</a>';
        }
    }

    public class MakeCallOutToSCP extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Case> casesToProcess = new List<Case>();
            RC_Platform_API_setting__mdt setting = [SELECT Case_Origin__c, Internal_Case_RTs__c, Ebonding_Case_Rts__c ,MakeCallouts__c, Client_ID__c, PrivateKey__c, BaseURL__c
                                                     FROM RC_Platform_API_setting__mdt WHERE MasterLabel = 'SCP_API' LIMIT 1];

            if(setting != null && setting.MakeCallouts__c) {
                for (Case caseNew: (List<Case>) TriggerRecords) {
                    if (String.isNotBlank(caseNew.CaseUID__c) && String.isNotBlank(caseNew.ContactEmail) &&
                        (setting.Ebonding_Case_Rts__c.contains(caseNew.RecordTypeName__c) ||
                        (setting.Internal_Case_RTs__c.contains(caseNew.RecordTypeName__c) &&
                        (caseNew.Origin != null && !setting.Case_Origin__c.contains(caseNew.Origin)))))  {
                              casesToProcess.add(caseNew);
                    }
                }
            }

            if(casesToProcess.size()>0){
                 System.enqueueJob(new RCPlatformAPICalloutQueueableJob(casesToProcess, setting));
            }
        }
    }

    public class UpdateInternalBusinessServiceCaseDescription extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Case> ibsCaseList = new List<Case>();
            List<String> affectedUserIdList = new List<String>();
            Map<Id, User> usrMap = new Map<Id, User>();
            
            for (Case newCase : (List<Case>) triggerRecords) {
                if (newCase.RecordTypeId == CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES && newCase.Affected_User__c != null && !String.isBlank(newCase.Steps_to_Reproduce__c) 
                    && !String.isBlank(newCase.Actual_Result__c) && !String.isBlank(newCase.Expected_Result__c) && !String.isBlank(newCase.Error_Link__c)) {
                        ibsCaseList.add(newCase);
                        affectedUserIdList.add(newCase.Affected_User__c);
                    }
            }
            if(!affectedUserIdList.isEmpty()){
                usrMap = getUserMap(affectedUserIdList);
            }
            
            if(!ibsCaseList.isEmpty()){
                for(Case cs : ibsCaseList){
                    cs.Description = concatenateCaseDescription(cs, usrMap).left(31900);
                }
            }
            
        }
        
        private Map<Id, User> getUserMap(List<String> userIdList) {
            return new Map<Id, User>((List<User>)new UserSelector().selectUserById(userIdList).executeQuery());
        }
        
        private String concatenateCaseDescription(Case cs, Map<Id, User> usrMap){
            String des = '';
            des += 'Affected User : '+(usrMap.containsKey(cs.Affected_User__c) ? usrMap.get(cs.Affected_User__c).Name : '');
            des += '\n\n Steps to Reproduce  : '+cs.Steps_to_Reproduce__c;
            des += '\n\n Actual Result  : '+cs.Actual_Result__c;
            des += '\n\n Expected Result  : '+cs.Expected_Result__c;
            des += '\n\n Link to Affected Record  : '+cs.Error_Link__c;
            return des;
        }
    }

    private static Map<Id, Case> getCaseWithoutSurveyMap(List<Case> cases, Set<String> surveyTypes) {
        if (cases == null || cases.isEmpty()) {
            return new Map<Id, Case>();
        }

        Map<Id, Case> caseWithoutSurveysMap = new Map<Id, Case> ();
        for (Case caseObj : (List<Case>) new CaseSelector()
                .selectCases()
                .selectFields(new List<Schema.SObjectField> {Case.Id})
                .subselect(new SurveySelector()
                    .selectSurveys()
                    .withoutSelectorFieldsIncluded()
                    .withoutSelectorOrderByIncluded()
                    .selectFields(new List<Schema.SObjectField> {Survey__c.Id})
                    .setCondition('SurveyType__c IN :bind1'))
                .setCondition('Id IN :bind0')
                .setQueryBindings(new List<Object> {cases, surveyTypes})
                .setQueryCaching(true)
                .executeQuery()
        ) {
            if (caseObj.Surveys__r.isEmpty()) {
                caseWithoutSurveysMap.put(caseObj.Id, caseObj);
            }
        }
        return caseWithoutSurveysMap;
    }

    private static Boolean isCaseEligibleForSurveyCreation(Case caseObj) {
        String caseRecordTypeName = RT_MAP_BY_ID.get(caseObj.RecordTypeId)?.getName();
        Boolean isCaseContainNeededRT = CaseHelper.CASE_RECORD_TYPES_FOR_SURVEY.contains(caseRecordTypeName);

        if (!isCaseContainNeededRT || String.isNotBlank(caseObj.Support_Jira__c)) {
            return false;
        }

        Boolean isStatusChangedToClosed = CoreObjectBase.isFieldChangedTo(caseObj, Case.Status, CaseHelper.CASE_STATUS_CLOSED)
            || (CoreObjectBase.isFieldChangedTo(caseObj, Case.Status, CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE) && CaseHelper.CASE_RECORD_TYPES_FOR_CLOSED_NOT_RESPONSE_STATUS.contains(caseRecordTypeName));
        return isStatusChangedToClosed;
    }

    private static Set<Id> getContactIdsWithSurveys(Set<String> surveyTypes) {
        Set<Id> contactIdsWithSurveys = new Set<Id>();
        for (Survey__c surveyObj : surveysByCaseContacts) {
            if (!surveyTypes.contains(surveyObj.SurveyType__c)) {
                continue;
            }
            contactIdsWithSurveys.add(surveyObj.Contact__c);
        }
        return contactIdsWithSurveys;
    }

    private static Survey__c buildSurveyForCase(Case caseObj, String surveyType) {
        return SurveyHelper.buildSurveyForCase(
            caseObj,
            surveyType,
            usersMap,
            contactsMapFromCases
        );
    }

    private static void createSurveys(List<Survey__c> surveysToCreate, String handlerName) {
        if (!surveysToCreate.isEmpty()) {
            try {
                insert surveysToCreate;
            } catch (Exception ex) {
                PlatformLog.logException('Error CaseTriggerHandler.' + handlerName, ex);
            }
        }
    }

    private static String addOpsPrefix(String item) {
        return 'OPS ' + item;
    }

    @TestVisible
    private static Map<Id, Contact> getContactsMapFromCases(List<Case> cases) {
        if (cases == null || cases.isEmpty()) {
            return new Map<Id, Contact>();
        }

        Set<Id> contactIds = new Set<Id>();
        for (Case c : cases) {
            if (c.ContactId != null) {
                contactIds.add(c.ContactId);
            }
        }
        if (contactIds.isEmpty()) {
            return new Map<Id, Contact>();
        }

        return new Map<Id, Contact>(
            (List<Contact>) CaseTriggerHandler.selectContactsByIds(contactIds).executeQuery()
        );
    }

    // one-time selector that is used to also cache the query in TestCaseTriggerHandler unit tests
    @TestVisible
    private static QueryFactory selectContactsByIds(Set<Id> contactIds) {
        return new ContactSelector()
            .selectContactsByIds(new List<Object> {contactIds})
            .selectFields(new Set<Schema.SObjectField> {
                Contact.Id,
                Contact.LastName,
                Contact.FirstName,
                Contact.Email,
                Contact.Phone,
                Contact.Preferred_Language__c
            })
            .withoutSelectorFieldsIncluded()
            .setQueryCaching(true);
    }

   
    /**
    * Handles round-robin assignment of cases escalated to CERT or Customer Success teams.
    * 
    * Business Rules:
    * - Only processes cases with RecordType = 'Sales Customer Form'
    * - Only triggers on Support_Escalate_To__c field changes to 'CERT' or 'Customer Success'
    * - Assigns cases in round-robin fashion based on Case_Assignee__c records
    * - Updates assignee timestamps to maintain round-robin order
    * - Continuation in Flow 'Round Robin CERT Case RT' to set the SLA and follow ups
    * 
    */
    public class RoundRobinAssignment extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Case> casesToProcess = new List<Case>();
            if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
                for (Case newCase : (List<Case>) triggerRecords) {
                    
                    if (shouldProcessCase(newCase)) {
                        casesToProcess.add(newCase);
                    }
                }
                
                // Process cases in bulk for round-robin assignment
                if (!casesToProcess.isEmpty()) {
                    assignCasesRoundRobin(casesToProcess);
                }
            }
        }

        /**
         * Determines if a case should be processed for round-robin assignment
         */
        private Boolean shouldProcessCase(Case caseRecord) {
            return caseRecord.RecordTypeId == CaseHelper.RT_ID_SALES_CUST_FORM && 
                caseRecord.Support_Escalate_To__c != null && 
                (isChangedFieldTo(caseRecord, Case.Support_Escalate_To__c, ESCALATION_CERT) ||
                    isChangedFieldTo(caseRecord, Case.Support_Escalate_To__c, ESCALATION_CUSTOMER_SUCCESS));
        }
        
        private void assignCasesRoundRobin(List<Case> cases) {
            Integer casesSize = cases.size();
            List<Case_Assignee__c> assignees = getAssignees(casesSize);
            
            // Do not route if assignees are unavailable
            if (assignees.isEmpty()) {
                return;
            }
            // Assign cases in round-robin fashion
            Map<Id, Case_Assignee__c> assigneesToUpdateMap = new Map<Id, Case_Assignee__c>();
            Integer currentIndex = 0;
            Integer assigneeSize = assignees.size();
            
            for (Case c : cases) {
                Case_Assignee__c assignee = assignees[currentIndex];
                c.OwnerId = assignee.Case_Agent__c;
                assignee.Case_Assigned__c = System.now();
                
                // Use Map to avoid duplicates - if same assignee appears multiple times,
                // only the latest timestamp will be kept
                assigneesToUpdateMap.put(assignee.Id, assignee);
                
                // Move to next assignee, reset to 0 if we've reached the end
                currentIndex++;
                if (currentIndex >= assigneeSize) {
                    currentIndex = 0;
                }
            }
            
            // Convert Map values to List for update
            List<Case_Assignee__c> assigneesToUpdate = assigneesToUpdateMap.values();
            
            // Update assignee records to persist the new timestamps
            if (!assigneesToUpdate.isEmpty()) {
                    update assigneesToUpdate;
            }
        }

        private List<Case_Assignee__c> getAssignees(Integer caseCount) {
            try {
                return [SELECT Id, Case_Agent__c, Case_Assigned__c, Region__c, isActive__c 
                        FROM Case_Assignee__c 
                        WHERE isActive__c = true
                        AND Case_Agent__c != null
                        AND Case_Type__c = :CaseHelper.CASE_TYPE_CERT_CUSTOMER_SUCCESS_ESCALATION
                        ORDER BY Case_Assigned__c ASC NULLS FIRST
                        LIMIT :caseCount];
            } catch (Exception e) {
                return new List<Case_Assignee__c>();
            }
        }
        
    }

}