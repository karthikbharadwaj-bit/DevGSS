/**
 * Controller for High Risk Case Email functionality.
 * Invokes the ATT_High_Risk_Escalation_Email flow to send notifications.
 * 
 * Recipient list is fully configurable via GCP_Feature_Toggle__c custom setting:
 *   - High_Risk_Email_Fields__c    : comma-separated SOQL field paths on Case
 *                                    (e.g. Owner.Email, Account.CSM__r.Email)
 *   - High_Risk_Email_Addresses__c   : comma-separated hardcoded email addresses
 *   - High_Risk_Email_Addresses_2__c : overflow field for additional hardcoded emails
 * 
 * At least one email address field (High_Risk_Email_Addresses__c or _2__c)
 * must be configured. If both are blank, the method throws an
 * AuraHandledException so admins are alerted to complete the configuration.
 * 
 * Null/blank emails resolved from the configured fields are silently skipped.
 * Duplicates are auto-removed via Set.
 * 
 * Also passes AI-generated escalation reasons from the UI to include
 * in the email body for business context.
 */
public with sharing class CaseHighRiskEmailController {

    private static final String ERR_CASE_ID_REQUIRED       = 'Case Id is required.';
    private static final String ERR_EMAIL_FIELDS_MISSING    = 'Escalation email fields are not configured. '
        + 'Please populate High_Risk_Email_Fields__c in GCP Feature Toggle custom setting.';
    private static final String ERR_EMAIL_ADDRESSES_MISSING = 'Escalation email addresses are not configured. '
        + 'Please populate High_Risk_Email_Addresses__c in GCP Feature Toggle custom setting.';
    private static final String ERR_CASE_NOT_FOUND           = 'Case not found for the given Id.';
    private static final String ERR_CASE_CLOSED             = 'Cannot send escalation email for a closed case.';
    private static final String ERR_FLOW_INVOCATION         = 'Error invoking High Risk Email flow: ';

    @AuraEnabled
    public static void sendHighRiskEmail(Id caseId, String escalationReasons) {
        if (caseId == null) {
            throw new AuraHandledException(ERR_CASE_ID_REQUIRED);
        }

        // ── 1. Read recipient config from Custom Setting ──
        GCP_Feature_Toggle__c config = GCP_Feature_Toggle__c.getInstance();

        String emailFieldsStr = config?.High_Risk_Email_Fields__c;
        if (String.isBlank(emailFieldsStr)) {
            throw new AuraHandledException(ERR_EMAIL_FIELDS_MISSING);
        }

        List<String> emailFieldPaths = new List<String>();
        for (String fieldEntry : emailFieldsStr.split(',')) {
            String trimmed = fieldEntry.trim();
            if (String.isNotBlank(trimmed)) {
                emailFieldPaths.add(trimmed);
            }
        }

        // Parse hardcoded email addresses from both fields directly into a Set
        Set<String> recipientSet = new Set<String>();
        for (String rawField : new List<String>{
            config?.High_Risk_Email_Addresses__c,
            config?.High_Risk_Email_Addresses_2__c
        }) {
            if (String.isNotBlank(rawField)) {
                for (String addr : rawField.split(',')) {
                    String trimmed = addr.trim();
                    if (String.isNotBlank(trimmed)) {
                        recipientSet.add(trimmed);
                    }
                }
            }
        }

        if (recipientSet.isEmpty()) {
            throw new AuraHandledException(ERR_EMAIL_ADDRESSES_MISSING);
        }

        // ── 2. Build dynamic SOQL with configured fields ──
        Set<String> selectFields = new Set<String>{ 'Id', 'IsClosed' };
        selectFields.addAll(emailFieldPaths);

        String soql = 'SELECT ' + String.join(new List<String>(selectFields), ', ')
                     + ' FROM Case WHERE Id = :caseId LIMIT 1';

        List<Case> caseResults = Database.query(soql);
        if (caseResults.isEmpty()) {
            throw new AuraHandledException(ERR_CASE_NOT_FOUND);
        }
        Case targetCase = caseResults[0];

        if (targetCase.IsClosed) {
            throw new AuraHandledException(ERR_CASE_CLOSED);
        }

        // ── 3. Resolve each field path to an email value ──
        for (String fieldPath : emailFieldPaths) {
            String email = resolveFieldPath(targetCase, fieldPath);
            if (String.isNotBlank(email)) {
                recipientSet.add(email);
            }
        }

        recipientSet.remove(null);
        recipientSet.remove('');

        String recipientsCsv = String.join(new List<String>(recipientSet), ',');

        // ── 4. Invoke the Flow ──
        Map<String, Object> params = new Map<String, Object>{
            'caseId'             => String.valueOf(targetCase.Id),
            'emailRecipients'    => recipientsCsv,
            'escalationReasons'  => escalationReasons != null ? escalationReasons : ''
        };

        try {
            Flow.Interview.ATT_High_Risk_Escalation_Email flow =
                new Flow.Interview.ATT_High_Risk_Escalation_Email(params);
            flow.start();
        } catch (Exception e) {
            throw new AuraHandledException(ERR_FLOW_INVOCATION + e.getMessage());
        }
    }

    /**
     * Traverse a dot-separated field path on an SObject to get a String value.
     * e.g. "Account.SE__r.Email" on a Case record will:
     *   1. getSObject('Account')
     *   2. getSObject('SE__r')
     *   3. get('Email')
     * Returns null if any intermediate relationship is null (silently handles blanks).
     */
    private static String resolveFieldPath(SObject record, String fieldPath) {
        try {
            List<String> parts = fieldPath.split('\\.');
            SObject current = record;

            // Traverse intermediate relationships (all parts except the last)
            for (Integer i = 0; i < parts.size() - 1; i++) {
                if (current == null) {
                    return null;
                }
                current = current.getSObject(parts[i]);
            }

            if (current == null) {
                return null;
            }

            // Get the final field value
            Object val = current.get(parts[parts.size() - 1]);
            return val != null ? String.valueOf(val) : null;
        } catch (Exception e) {
            // Silently handle any field resolution errors (e.g. bad path)
            return null;
        }
    }
}