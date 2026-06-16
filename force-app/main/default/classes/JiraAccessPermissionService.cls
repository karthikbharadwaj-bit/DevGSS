public with sharing class JiraAccessPermissionService {
    private static final String OPERATION_CREATE = 'create';
    private static final String OPERATION_LINK = 'link';
    private static final String OPERATION_BOTH = 'both';

    public static final String MSG_OUT_OF_SCOPE_CREATE_LINK =
        'Create/Link Jira is not valid for your profile/recordtype.';
    public static final String MSG_CREATE_DENIED_IN_SCOPE =
        'Create Jira is not valid for your profile/recordtype.';
    public static final String MSG_LINK_DENIED_IN_SCOPE =
        'Link Jira is not valid for your profile/recordtype.';
    public static final String MSG_COMMENTS_NOT_ACCESSIBLE =
        'Jira Comments is not accessible for your profile/recordtype.';

    private static final String LINK_JIRA_MESSAGE = 'You can use the Link Jira button to link the Jira.';

    private static String currentProfileName;
    private static List<PermissionRow> cachedPermissionRows;
    private static Map<Id, JiraAccessContext> accessContextByCaseId = new Map<Id, JiraAccessContext>();

    public class JiraAccessContext {
        @AuraEnabled public Boolean canCreate { get; set; }
        @AuraEnabled public Boolean canLink { get; set; }
        @AuraEnabled public Boolean canViewComments { get; set; }
        @AuraEnabled public Boolean hasLinkedJiraDetail { get; set; }
        @AuraEnabled public Boolean isProfileRecordTypeInScope { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String profileName { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
        /** Shown when Create Jira is not allowed (wrong op or out of scope). */
        @AuraEnabled public String deniedCreateMessage { get; set; }
        /** Shown when Link Jira is not allowed (wrong op or out of scope). */
        @AuraEnabled public String deniedLinkMessage { get; set; }
        /** Shown when Jira comments are not accessible. */
        @AuraEnabled public String commentsAccessMessage { get; set; }

        public JiraAccessContext() {
            this.canCreate = false;
            this.canLink = false;
            this.canViewComments = false;
            this.hasLinkedJiraDetail = false;
            this.isProfileRecordTypeInScope = false;
            this.message = '';
            this.profileName = '';
            this.recordTypeName = '';
            this.deniedCreateMessage = '';
            this.deniedLinkMessage = '';
            this.commentsAccessMessage = '';
        }
    }

    private class PermissionRow {
        public String operationType;
        public String profileKey;
        public Set<String> recordTypeKeys = new Set<String>();
    }

    public static JiraAccessContext getAccessContext(Id caseId) {
        if (caseId == null) {
            return new JiraAccessContext();
        }

        if (!accessContextByCaseId.containsKey(caseId)) {
            accessContextByCaseId.put(caseId, buildAccessContext(caseId));
        }

        return accessContextByCaseId.get(caseId);
    }

    public static Boolean isOperationAllowed(Id caseId, String operationType) {
        JiraAccessContext accessContext = getAccessContext(caseId);
        String operationKey = normalizeOperation(operationType);

        if (operationKey == OPERATION_CREATE) {
            return accessContext.canCreate;
        }
        if (operationKey == OPERATION_LINK) {
            return accessContext.canLink;
        }
        if (operationKey == OPERATION_BOTH) {
            return accessContext.canCreate && accessContext.canLink;
        }

        return false;
    }
    
    public static Boolean isRecordTypeConfigured(String recordTypeName) {
        String recordTypeKey = normalizeKey(recordTypeName);
        if (String.isBlank(recordTypeKey)) {
            return false;
        }

        for (PermissionRow row : getPermissionRows()) {
            if (row.recordTypeKeys.contains(recordTypeKey)) {
                return true;
            }
        }
        return false;
    }
    
    public static Set<String> getConfiguredRecordTypeKeys() {
        Set<String> configuredRecordTypeKeys = new Set<String>();
        for (PermissionRow row : getPermissionRows()) {
            configuredRecordTypeKeys.addAll(row.recordTypeKeys);
        }
        return configuredRecordTypeKeys;
    }

    
    private static JiraAccessContext buildAccessContext(Id caseId) {
        JiraAccessContext accessContext = new JiraAccessContext();
        Case caseRecord = loadCaseContext(caseId);
        if (caseRecord == null) {
            accessContext.message = MSG_OUT_OF_SCOPE_CREATE_LINK;
            applyDeniedMessages(accessContext);
            return accessContext;
        }

        String profileName = getCurrentProfileName();
        String profileKey = normalizeKey(profileName);
        String recordTypeName = caseRecord.RecordTypeName__c;
        String recordTypeKey = normalizeKey(recordTypeName);

        accessContext.profileName = profileName;
        accessContext.recordTypeName = recordTypeName;
        accessContext.hasLinkedJiraDetail = hasLinkedJiraDetail(caseRecord);

        if (String.isBlank(profileKey) || String.isBlank(recordTypeKey)) {
            accessContext.message = MSG_OUT_OF_SCOPE_CREATE_LINK;
            applyDeniedMessages(accessContext);
            return accessContext;
        }

        for (PermissionRow row : getPermissionRows()) {
            if (row.profileKey != profileKey || !row.recordTypeKeys.contains(recordTypeKey)) {
                continue;
            }

            accessContext.isProfileRecordTypeInScope = true;
            accessContext.canViewComments = true;

            if (row.operationType == OPERATION_CREATE || row.operationType == OPERATION_BOTH) {
                accessContext.canCreate = true;
            }
            if (row.operationType == OPERATION_LINK || row.operationType == OPERATION_BOTH) {
                accessContext.canLink = true;
            }
        }

        if (!accessContext.canViewComments) {
            accessContext.message = MSG_OUT_OF_SCOPE_CREATE_LINK;
        } else if (!accessContext.hasLinkedJiraDetail) {
            accessContext.message = LINK_JIRA_MESSAGE;
        }

        applyDeniedMessages(accessContext);
        return accessContext;
    }

    private static void applyDeniedMessages(JiraAccessContext accessContext) {
        if (accessContext == null) {
            return;
        }
        if (!accessContext.isProfileRecordTypeInScope) {
            accessContext.deniedCreateMessage = MSG_OUT_OF_SCOPE_CREATE_LINK;
            accessContext.deniedLinkMessage = MSG_OUT_OF_SCOPE_CREATE_LINK;
        } else {
            if (!accessContext.canCreate) {
                accessContext.deniedCreateMessage = MSG_CREATE_DENIED_IN_SCOPE;
            }
            if (!accessContext.canLink) {
                accessContext.deniedLinkMessage = MSG_LINK_DENIED_IN_SCOPE;
            }
        }
        if (!accessContext.canViewComments) {
            accessContext.commentsAccessMessage = MSG_COMMENTS_NOT_ACCESSIBLE;
        }
    }

    private static Case loadCaseContext(Id caseId) {
        List<SObject> results = new CaseSelector()
            .selectJiraAccessCaseById(caseId)
            .executeQuery();
        return results.isEmpty() ? null : (Case) results[0];
    }

    private static Boolean hasLinkedJiraDetail(Case caseRecord) {
        if (caseRecord == null) {
            return false;
        }

         if (caseRecord.Jira_Case__c != null) {
            return true;
        }

        if (String.isNotBlank(caseRecord.Jira__c)) {
            return true;
        }

        if (caseRecord.Jira_Link__c  != null) {
            return true;
        }

        return false;
    }

    private static String getCurrentProfileName() {
        if (currentProfileName == null) {
            currentProfileName = [
                SELECT Name
                FROM Profile
                WHERE Id = :UserInfo.getProfileId()
                LIMIT 1
            ].Name;
        }
        return currentProfileName;
    }

    private static List<PermissionRow> getPermissionRows() {
        if (cachedPermissionRows != null) {
            return cachedPermissionRows;
        }

        cachedPermissionRows = new List<PermissionRow>();
        for (SF_Jira_Profile_RecordType_Permission__mdt row : [
            SELECT Operation_Type__c, Profile_Name__c, RecordType_Name__c
            FROM SF_Jira_Profile_RecordType_Permission__mdt
            WHERE Profile_Name__c != NULL AND RecordType_Name__c != NULL
        ]) {
            String operationType = normalizeOperation(row.Operation_Type__c);
            String profileKey = normalizeKey(row.Profile_Name__c);
            Set<String> recordTypeKeys = parseCsvToNormalizedSet(row.RecordType_Name__c);
            
            if (String.isBlank(operationType) || String.isBlank(profileKey) || recordTypeKeys.isEmpty()) {
                continue;
            }

            PermissionRow parsedRow = new PermissionRow();
            parsedRow.operationType = operationType;
            parsedRow.profileKey = profileKey;
            parsedRow.recordTypeKeys = recordTypeKeys;
            cachedPermissionRows.add(parsedRow);
        }

        return cachedPermissionRows;
    }

    private static Set<String> parseCsvToNormalizedSet(String rawValue) {
        Set<String> parsedValues = new Set<String>();
        if (String.isBlank(rawValue)) {
            return parsedValues;
        }

        for (String value : rawValue.split(',')) {
            String key = normalizeKey(value);
            if (String.isNotBlank(key)) {
                parsedValues.add(key);
            }
        }

        return parsedValues;
    }

    private static String normalizeKey(String value) {
        return String.isBlank(value) ? '' : value.trim().toLowerCase();
    }

    private static String normalizeOperation(String operationType) {
        String normalizedOperation = normalizeKey(operationType);
        if (normalizedOperation == OPERATION_CREATE
            || normalizedOperation == OPERATION_LINK
            || normalizedOperation == OPERATION_BOTH) {
            return normalizedOperation;
        }
        return '';
    }

    @TestVisible
    private static void resetCache() {
        currentProfileName = null;
        cachedPermissionRows = null;
        accessContextByCaseId.clear();
    }
}