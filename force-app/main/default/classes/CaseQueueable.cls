public without sharing class CaseQueueable implements Queueable {
    private Set<Id> accountIds = new Set<Id>();
    private List<DealDeskCaseDescription__c> existingDescsForAccounts;
    private static final String CASE_SUBJECT_MANUAL_PROVISION = 'Products for manual provisioning for Account: ';
    public static final String ACCOUNT_FILED_RC_USER_ID = 'RC_User_ID__c';

    public CaseQueueable(Set<Id> accIds, List<DealDeskCaseDescription__c> existingDescsForAccounts) {
        if (!accIds.isEmpty()) {
            this.accountIds.addAll(accIds);
        }
        this.existingDescsForAccounts = existingDescsForAccounts;
    }

    public void execute(QueueableContext queContext) {
        List<Case> casesToInsert = new List<Case>();
        Map<Id, Account> funnelNotSupportedAccounts = new Map<Id, Account>();
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccountsForDealDeskCase(new List<Object>{
                accountIds
            })
            .executeQuery();

        if(!this.existingDescsForAccounts.isEmpty()) {
            casesToInsert.addAll(getCasesFromCaseDescriptions(this.existingDescsForAccounts));
        }

        for (Account acc : accounts) {
            if (!AccountHelper.isMPUBAccount(acc.Id, acc.Master_Accounts__r)
                && acc.Changes__c != null
                && acc.Changes__c.contains(ACCOUNT_FILED_RC_USER_ID)
            ) {
                // if RC_User_ID__c changed to not empty value
                String regExp = String.format(';{0}|{1};', new List<String>{
                    ACCOUNT_FILED_RC_USER_ID, ACCOUNT_FILED_RC_USER_ID
                });
                acc.Changes__c = acc.Changes__c.replaceAll(regExp, '');
                funnelNotSupportedAccounts.put(acc.Id, acc);
            }
        }

        if (!funnelNotSupportedAccounts.isEmpty()) {
            update funnelNotSupportedAccounts.values();
        }

        if (!funnelNotSupportedAccounts.isEmpty()) {
            casesToInsert.addAll(createCaseForManualProvisioning(funnelNotSupportedAccounts.values()));
        }

        insert casesToInsert;

        delete existingDescsForAccounts;
    }

    private List<Case> getCasesFromCaseDescriptions(List<DealDeskCaseDescription__c> existingDescs) {
        Set<Id> userIdSet = new Set<Id>();
        List<Case> casesFromCaseDescriptions = new List<Case>();

        for (DealDeskCaseDescription__c description : existingDescs) {
            userIdSet.add(description.Account__r.Most_Recent_Opportunity_Owner__c);
        }

        for (DealDeskCaseDescription__c description : existingDescs) {
            Case dealDeskCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_DEALDESK_CASE,
                    Case.OwnerId => description.CaseOwner__c,
                    Case.AccountId => description.Account__c,
                    Case.Opportunity_Reference__c => getOpportunityIdFromCaseDescription(description.CaseDescription__c),
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Origin => CaseHelper.CASE_ORIGIN_AUTO_EMAIL,
                    Case.Subject => description.Subject__c,
                    Case.Case_Category__c => CaseHelper.CASE_CATEGORY_PROVISIONING,
                    Case.Description => description.CaseDescription__c
                })
                .build()
                .getRecord();
            casesFromCaseDescriptions.add(dealDeskCase);
        }

        return casesFromCaseDescriptions;
    }

    private List<Case> createCaseForManualProvisioning(List<Account> accountsWithChangedRCUserId) {
        Set<Id> userIdSet = new Set<Id>();

        for (Account currentAcc : accountsWithChangedRCUserId) {
            userIdSet.add(currentAcc.Most_Recent_Opportunity_Owner__c);
        }

        Map<Id, Contact> userIdToContactMap = buildUserIdToContactMap(userIdSet);
        List<Case> caseListToInsert = new List<Case>();

        for (Account currentAcc : accountsWithChangedRCUserId) {
            Contact endUser = userIdToContactMap.get(currentAcc.Most_Recent_Opportunity_Owner__c);

            Id endUserId = endUser == null ? null : endUser.Id;

            Case dealDeskCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_DEALDESK_CASE,
                    Case.OwnerId => DealDeskCaseGenerator.DEAL_DESK_QUEUE.QueueId,
                    Case.AccountId => currentAcc.Id,
                    Case.Opportunity_Reference__c => getOpportunityId(currentAcc.Funnel_not_supported__c),
                    Case.End_User__c => endUserId,
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Origin => CaseHelper.CASE_ORIGIN_AUTO_EMAIL,
                    Case.Subject => CASE_SUBJECT_MANUAL_PROVISION + currentAcc.Name,
                    Case.Description => currentAcc.Funnel_not_supported__c
                })
                .build()
                .getRecord();

            caseListToInsert.add(dealDeskCase);
        }

        return caseListToInsert;
    }


    private Map<Id, Contact> buildUserIdToContactMap(Set<Id> userIdSet) {
        Map<Id, Contact> userIdToContactMap = new Map<Id, Contact>();
        Map<Id, WrapperEmail> userIdToNameSetsMap = new Map<Id, WrapperEmail>();

        if (userIdSet.isEmpty()) {
            return userIdToContactMap;
        }

        Set<String> firstNameSet = new Set<String>();
        Set<String> lastNameSet = new Set<String>();
        Set<String> emailSet = new Set<String>();

        List<User> userList = new UserSelector()
            .selectUsers()
            .selectFields(
                new List<String>{
                    'Id', 'FirstName', 'LastName', 'Email'
                })
            .setCondition('Id IN :bind0')
            .setQueryBindings(
                new List<Object>{
                    userIdSet
                })
            .executeQuery();

        for (User currentUser : userList) {
            if (userIdToNameSetsMap.containsKey(currentUser.Id)) {
                WrapperEmail wrEmail = userIdToNameSetsMap.get(currentUser.Id);
                wrEmail.firstName.add(currentUser.FirstName);
                wrEmail.lastName.add(currentUser.LastName);
                wrEmail.email.add(currentUser.Email);
            } else {
                WrapperEmail wrEmail = new WrapperEmail(currentUser.FirstName, currentUser.LastName, currentUser.Email);
                userIdToNameSetsMap.put(currentUser.Id, wrEmail);
                firstNameSet.add(currentUser.FirstName);
                lastNameSet.add(currentUser.LastName);
                emailSet.add(currentUser.Email);
            }
        }

        List<Contact> contacts = new ContactSelector().selectContactsByEmail(new List<Object>{
            firstNameSet, lastNameSet, emailSet
        }).executeQuery();

        for (Contact currentContact : contacts) {
            for (Id currentUserId : userIdToNameSetsMap.keySet()) {
                WrapperEmail wrMail = userIdToNameSetsMap.get(currentUserId);
                if (wrMail.isIdentical(currentContact.FirstName, currentContact.LastName, currentContact.Email)) {
                    userIdToContactMap.put(currentUserId, currentContact);
                    break;
                }
            }
        }

        return userIdToContactMap;
    }

    public class WrapperEmail {
        public Set<String> firstName { get; set; }
        public Set<String> lastName { get; set; }
        public Set<String> email { get; set; }

        public WrapperEmail(String firstName, String lastName, String email) {
            this.firstName = new Set<String>{
                firstName
            };
            this.lastName = new Set<String>{
                lastName
            };
            this.email = new Set<String>{
                email
            };
        }

        public Boolean isIdentical(String firstName, String lastName, String email) {
            return this.firstName.contains(firstName) || this.lastName.contains(lastName) || this.email.contains(email);
        }
    }

    private String getOpportunityId(String funnelNotSupported) {
        if (funnelNotSupported == null) {
            return null;
        }
        String oppId = funnelNotSupported.substringAfter('Opportunity:').substringAfter('.com/').substringBefore('"');
        return SFDescribeHelper.isValidSalesforceId(oppId, Schema.Opportunity.sObjectType) ? oppId : null;
    }

    private String getOpportunityIdFromCaseDescription(String description) {
        if (description == null) {
            return null;
        }
        String oppId = description.substringAfter('Opportunity:').substringAfter('.com/').substringBefore('\n');
        return SFDescribeHelper.isValidSalesforceId(oppId, Schema.Opportunity.sObjectType) ? oppId : null;
    }
}