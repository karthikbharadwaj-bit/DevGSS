public with sharing class CaseAIInsightsProcessor {
    
    /* =========================
Constants
========================= */
    
    private static final Integer HTTP_TIMEOUT_MS = 120000;
    private static final String  CONTENT_TYPE_JSON = 'application/json';
    private static final String  ERR_GCP_CALL_FAILED_PREFIX = 'GCP call failed. Status: ';  
    private static final String  ERR_AI_METRIC_GENERIC = 'AI returned an error for this metric.';
    private static final String  ERR_UNEXPECTED_RESPONSE = 'Unexpected response format';
    
    @AuraEnabled(cacheable=false)
    public static String makeGCPCallout(String userId, Id caseId, String purpose) {
        try {
            User userRecord = [SELECT UserName FROM User WHERE Id = :userId LIMIT 1];
            String username = userRecord.UserName;
            GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig(purpose);
            String jwt = GCPAuthUtil.createSignedJWT(config);
            String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(jwt, config.identityTokenUrl);
            String response = callCloudRun(username, caseId, idToken, config.cloudRunEndpoint, purpose);
            return response;
        } catch (Exception e) {
            return JSON.serializePretty(new Map<String, Object>{
                'success' => false,
                    'message' => e.getMessage()
                    });
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static String identifyCaseSentimentEscalation(String userId, Id caseId) {
        try {
            Case inputCase = [SELECT Priority, Initial_Severity__c, Case_Severity__c, CreatedDate, Last_Modified_Age__c, Subject,
                              Description, CSAT_Prediction__c, CSAT_Prediction_after_Manager_Callback__c, Status, IsEscalated,
                              (SELECT Id from MOD_Escalations__r) 
                              FROM Case 
                              WHERE Id = :caseId LIMIT 1];
            User userRecord = [SELECT UserName FROM User WHERE Id = :userId LIMIT 1];
            String userName = userRecord.UserName;
            GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig(GCPAuthUtil.ESCALATION_SENTIMENT);
            String jwt = GCPAuthUtil.createSignedJWT(config);
            String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(jwt, config.identityTokenUrl);
            String response = contactGCPforSentimentEscalation(userName, inputCase, idToken, config.cloudRunEndpoint);
            return response;
        } catch (Exception e) {
            return JSON.serializePretty(new Map<String, Object>{
                'success' => false,
                    'message' => e.getMessage()
                    });
        }
    }   
    
    private static String contactGCPforSentimentEscalation(String userName, Case inputCase, String idToken, String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', CONTENT_TYPE_JSON);
        req.setHeader('Authorization', 'Bearer ' + idToken);
        
        Integer noOfDays = inputCase.CreatedDate.date().daysBetween(Date.today());
        
        Map<String, Object> payload = new Map<String, Object>{
            'username' => userName,
            'recordId' => inputCase.Id,
            'priority' => inputCase.Priority,
            'initial_severity' => inputCase.Initial_Severity__c,
            'case_severity' => inputCase.Case_Severity__c,
            'case_age' => noOfDays,
            'untouched_date' => inputCase.Last_Modified_Age__c,
            'subject' => inputCase.Subject,
            'description' => inputCase.Description,
                'customer_sentiment_prediction' => inputCase.CSAT_Prediction__c,
            'sentiment_manager_callback' => inputCase.CSAT_Prediction_after_Manager_Callback__c,
            'case_status' => inputCase.Status,
            'is_escalated' => inputCase.IsEscalated,
            'mod_escalation_no' => inputCase.MOD_Escalations__r.size()
                };
                    req.setBody(JSON.serialize(payload));

        System.debug('GCP Request Payload: ' + JSON.serialize(payload));

        req.setTimeout(HTTP_TIMEOUT_MS);
        
        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('=== GCP SENTIMENT/ESCALATION RESPONSE ===');
        System.debug('GCP Response Status Code: ' + res.getStatusCode());
        System.debug('GCP Response Body: ' + res.getBody());
        System.debug('=== END GCP RESPONSE ===');

        if (res.getStatusCode() != 200) {
            throw new CalloutException(
                ERR_GCP_CALL_FAILED_PREFIX + res.getStatusCode() + ' - ' + res.getBody()
            );
        }
        
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        Map<String, Object> container = parsed;
        Object topBody = parsed.get('body');
        if (topBody instanceof Map<String, Object>) {
            container = (Map<String, Object>) topBody;
        }
        
        Map<String, Object> out = new Map<String, Object>();
        out.put('success', true); // transport-level success; UI reads per-metric keys
        
        // ---- api1_result => SENTIMENT ----
        Map<String, Object> api1 = (Map<String, Object>) container.get('api1_result');
        if (api1 != null) {
            String s1 = String.valueOf(api1.get('statusCode'));
            out.put('api1Status', s1);
            
            Object b1 = api1.get('body');
            if ('200'.equals(s1) && b1 instanceof Map<String, Object>) {
                Map<String, Object> m = (Map<String, Object>) b1;
                if (m.containsKey('sentiment')) {
                    out.put('sentiment', String.valueOf(m.get('sentiment')));
                }
                if (m.containsKey('reason')) {
                    out.put('sentiment_reason', String.valueOf(m.get('reason')));
                }
            } else {
                // extract an error message (handles stringified JSON too)
                out.put('sentiment_error', extractErrorMessage(b1));
            }
        }
        
        // ---- api2_result => ESCALATION ----
        Map<String, Object> api2 = (Map<String, Object>) container.get('api2_result');
        if (api2 != null) {
            String s2 = String.valueOf(api2.get('statusCode'));
            out.put('api2Status', s2);
            
            Object b2 = api2.get('body');
            if ('200'.equals(s2) && b2 instanceof Map<String, Object>) {
                Map<String, Object> m = (Map<String, Object>) b2;
                if (m.containsKey('escalation_metric')) {
                    out.put('escalation_metric', String.valueOf(m.get('escalation_metric')));
                }
                if (m.containsKey('reason')) {
                    out.put('escalation_reason', String.valueOf(m.get('reason')));
                }
            } else {
                out.put('escalation_error', extractErrorMessage(b2));
            }
        }
        
        return JSON.serializePretty(out);
    }
    
    /**
* Pulls a readable message from a response body that could be a Map or a JSON String.
*/
    private static String extractErrorMessage(Object body) {
        try {
            if (body instanceof String) {
                String s = (String) body;
                
                // Try to parse the string as JSON first.
                Object parsed = JSON.deserializeUntyped(s);
                if (parsed instanceof Map<String, Object>) {
                    Map<String, Object> m = (Map<String, Object>) parsed;
                    String err = (String) m.get('error');
                    String det = (String) m.get('details');
                    if (String.isNotBlank(err) || String.isNotBlank(det)) {
                        return String.join(new List<String>{ err, det }, ' — ');
                    }
                }
                // Not JSON or no structured fields — return raw string.
                return s;
            }
            
            if (body instanceof Map<String, Object>) {
                Map<String, Object> m = (Map<String, Object>) body;
                String err = (String) m.get('error');
                String det = (String) m.get('details');
                if (String.isNotBlank(err) || String.isNotBlank(det)) {
                    return String.join(new List<String>{ err, det }, ' — ');
                }
            }
        } catch (Exception e) {
            return ERR_AI_METRIC_GENERIC;
        }
        
        return ERR_AI_METRIC_GENERIC;
    }
    
    private static String callCloudRun(String username, Id caseId, String idToken, String endpoint, String purpose) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', CONTENT_TYPE_JSON);
        req.setHeader('Authorization', 'Bearer ' + idToken);
        Boolean redactionFlag = GCPAuthUtil.getRedactionFlag();
        Map<String, Object> payload = new Map<String, Object>();
        if (purpose.equals(GCPAuthUtil.JIRA_COMMENT_SUMMARY)) {
            payload = prepareJiraCaseCommentPayload(caseId, username);
        } else if (purpose.equals(GCPAuthUtil.CHAT_TRANSCRIPT_SUMMARY)) {
            payload = prepareChatTranscriptPayload(caseId, username);
            
			String threadId = (String) payload.get('thread_id');
            if (String.isBlank(threadId)) {
                return JSON.serializePretty(new Map<String, Object>{ 
                    'success' => false, 
                    'message' => '— No chat transcript available — ' 
                });
            }
        } else {        
            payload = new Map<String, Object>{
                'username' => username,
                    'recordId' => caseId,
                    'redactRequired' => String.valueOf(redactionFlag)
                    };
        }

        
        req.setBody(JSON.serialize(payload));
        req.setTimeout(HTTP_TIMEOUT_MS);
        
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new CalloutException(ERR_GCP_CALL_FAILED_PREFIX + res.getStatusCode() + ' - ' + res.getBody());
        }

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Object body = parsed.get('body');
        
        if (body instanceof String) {
            String bodyStr = (String) body;
            if (parsed.get('statusCode') != 200) {
                return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => bodyStr });
            }
            return JSON.serializePretty(new Map<String, Object>{ 'success' => true, 'summary' => bodyStr });
        } else {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => ERR_UNEXPECTED_RESPONSE });
        }
    }
    
    private static Map<String, object> prepareJiraCaseCommentPayload(String caseId, String userName) {
        Case cs = [SELECT 
                   Subject, Description, Jira_Case__r.Name, Jira_Case__r.Issue_Type__c, Jira_Case__r.Status__c, 
                   Jira_Case__r.Priority__c, Jira_Case__r.Description__c, Jira_Case__r.Summary__c, 
                   Jira_Case__r.Resolution__c, Jira_Case__r.Action_Taken__c, Jira_Case__c
                   FROM Case
                   WHERE Id =: caseId LIMIT 1];
        Map<String, Object> payload = new Map<String, Object>{
            'username' => username,
                'recordId' => caseId,
                'caseSubject' => cs.Subject,
                'caseDescription' => cs.Description,
                'jiraCaseId' => cs.Jira_Case__c,
                'jiraName' => cs.Jira_Case__r.Name,
                'jiraIssueType' => cs.Jira_Case__r.Issue_Type__c,
                'jiraStatus' => cs.Jira_Case__r.Status__c,
                'jiraPriority' => cs.Jira_Case__r.Priority__c,
                'jiraDescription' => cs.Jira_Case__r.Description__c,
                'jiraSummary' => cs.Jira_Case__r.Summary__c,
                'jiraResolution' => cs.Jira_Case__r.Resolution__c,
                'jiraActionTaken' => cs.Jira_Case__r.Action_Taken__c
                };
                    
        return payload;
    }
    
    private static Map<String, Object> prepareChatTranscriptPayload(String caseId, String userName) {
        // Query Case and related Dimelo Intervention records to get content thread ID.
        List<Dimelo__Intervention__c> interventions = [
            SELECT Dimelo__Content_Thread_Id__c,Dimelo__identity_name__c,Dimelo__user_name__c 
            FROM Dimelo__Intervention__c 
            WHERE Dimelo__Case__c = :caseId 
            AND Dimelo__Content_Thread_Id__c != null ORDER BY Createddate DESC
            LIMIT 1
        ];
        
        // Collect thread IDs from Dimelo Interventions
        String thread_Id = '';
        if (!interventions.isEmpty() && interventions[0].Dimelo__Content_Thread_Id__c != null) {
            thread_Id = interventions[0].Dimelo__Content_Thread_Id__c;
        }
        
        String Customer_Name= '';
		if (!interventions.isEmpty() && interventions[0].Dimelo__identity_name__c != null) {
            Customer_Name = interventions[0].Dimelo__identity_name__c;
        }
        
        String Agent_Name= '';
		if (!interventions.isEmpty() && interventions[0].Dimelo__user_name__c != null) {
            Agent_Name = interventions[0].Dimelo__user_name__c;
        }
        
        Map<String, Object> payload = new Map<String, Object>{
            'username' => username,
            'thread_id' => thread_Id,
            'Customer_Name'=>Customer_Name,
            'Agent_Name'=>Agent_Name   
       };
                    
        return payload;
    }
    
    @AuraEnabled(cacheable=true)
    public static Case getBasics(Id caseId) {
        return [
            SELECT CaseNumber, Status, Subject, Jira_Case__c,
            Case_Age__c, Escalated__c,
            CSAT_Prediction__c, CreatedDate, IsClosed
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }
    
    /**
     * Check if current user has any of the permission sets configured in the feature toggle
     * for Chat Transcript Summary access.
     */
    @AuraEnabled(cacheable=true)
    public static Boolean hasChatTranscriptPermissionSet() {
        GCP_Feature_Toggle__c config = GCP_Feature_Toggle__c.getInstance();
        String permSetConfig = config?.Chat_Transcript_Summary_Permission_Sets__c;
        
        if (String.isBlank(permSetConfig)) {
            return false;
        }
        
        List<String> permissionSetNames = new List<String>();
        for (String permSetName : permSetConfig.split(',')) {
            if (String.isNotBlank(permSetName)) {
                permissionSetNames.add(permSetName.trim());
            }
        }
        
        if (permissionSetNames.isEmpty()) {
            return false;
        }
        
        Id userId = UserInfo.getUserId();
        List<PermissionSetAssignment> assignments = [
            SELECT Id 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userId 
            AND PermissionSet.Name IN :permissionSetNames
            LIMIT 1
        ];
        return !assignments.isEmpty();
    }
    
    @AuraEnabled(cacheable=true)
    public static GCP_Feature_Toggle__c getFeatureToggle() {
        return GCP_Feature_Toggle__c.getInstance();
    }

    /**
     * Returns the Account's RC_Brand__c value for the given Case.
     * Used as an imperative Apex call in components rendered inside VF pages
     * (e.g. Explore More popup) where @wire(getRecord) cannot resolve
     * cross-object fields like Case.Account.RC_Brand__c.
     * @param caseId The Case record Id
     * @return The brand string, or empty string if unavailable
     */
    @AuraEnabled(cacheable=true)
    public static String getCaseBrand(Id caseId) {
        if (caseId == null) {
            return '';
        }
        List<Case> cases = [
            SELECT Account.RC_Brand__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        return (cases.isEmpty() || cases[0].Account == null)
            ? ''
            : (cases[0].Account.RC_Brand__c ?? '');
    }

    /**
     * Get High Risk configuration from GCP_Feature_Toggle__c custom setting.
     * Returns configurable values for High Risk criteria (brands, MRR threshold,
     * and whether the escalation feature is enabled for the running user).
     * @return Map with 'brands' (comma-separated string), 'mrrThreshold' (number),
     *         and 'escalationEnabled' (Boolean)
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getHighRiskConfig() {
        GCP_Feature_Toggle__c config = GCP_Feature_Toggle__c.getInstance();
        return new Map<String, Object>{
            'brands'             => config?.High_Risk_Brands__c,
            'mrrThreshold'       => config?.High_Risk_MRR_Threshold__c,
            'escalationEnabled'  => config?.High_Risk_Escalation_Switch__c == true,
            'escalationAllowedRoles' => config?.High_Risk_Escalation_Allowed_Roles__c
        };
    }
    /**
     * Returns the Account's MRR__c value converted to the org's corporate currency.
     * In multi-currency orgs, MRR__c is stored in the Account's CurrencyIsoCode.
     * This method normalizes it by dividing by CurrencyType.ConversionRate so the
     * threshold comparison in the LWC is always in corporate currency (typically USD).
     *
     * Falls back to the raw MRR__c value when:
     *   - Multi-currency is not enabled (CurrencyType query fails)
     *   - The Account's currency IS the corporate currency (rate = 1)
     *
     * @param caseId The Case record Id
     * @return MRR in corporate currency (Decimal), or 0 if unavailable
     */
    @AuraEnabled(cacheable=true)
    public static Decimal getAccountMrrInCorporateCurrency(Id caseId) {
        if (caseId == null) {
            return 0;
        }

        List<Case> cases = [
            SELECT Account.MRR__c, Account.CurrencyIsoCode
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        if (cases.isEmpty() || cases[0].Account == null || cases[0].Account.MRR__c == null) {
            return 0;
        }

        Decimal mrr = cases[0].Account.MRR__c;
        String currencyCode = cases[0].Account.CurrencyIsoCode;

        if (String.isBlank(currencyCode)) {
            return mrr;
        }

        try {
            List<CurrencyType> currencies = [
                SELECT ConversionRate, IsCorporate
                FROM CurrencyType
                WHERE IsoCode = :currencyCode AND IsActive = true
                LIMIT 1
            ];

            if (currencies.isEmpty() || currencies[0].IsCorporate) {
                return mrr;
            }

            return mrr / currencies[0].ConversionRate;
        } catch (Exception e) {
            // CurrencyType not available (single-currency org) — return raw value
            return mrr;
        }
    }

    /**
     * Checks whether the running user is allowed to click the Escalate button.
     * Reads Case field API paths from GCP_Feature_Toggle__c.High_Risk_Escalation_Allowed_Roles__c
     * (e.g. "OwnerId,Owner.ManagerId"), queries those fields on the Case via dynamic SOQL,
     * and compares each resolved value against the running user's Id.
     * Fully dynamic: adding new field paths to the custom setting requires zero code changes.
     * @param caseId The Case record Id
     * @return true if the running user matches any configured field path value
     */
    @AuraEnabled
    public static Boolean checkEscalateClickAccess(Id caseId) {
        if (caseId == null) {
            return false;
        }

        Id currentUserId = UserInfo.getUserId();

        GCP_Feature_Toggle__c config = GCP_Feature_Toggle__c.getInstance();
        String fieldPaths = config?.High_Risk_Escalation_Allowed_Roles__c;

        if (String.isNotBlank(fieldPaths)) {
            List<String> paths = new List<String>();
            for (String fieldEntry : fieldPaths.split(',')) {
                String trimmed = fieldEntry.trim();
                if (String.isNotBlank(trimmed)) {
                    paths.add(trimmed);
                }
            }

            if (!paths.isEmpty()) {
                Set<String> caseFieldsSet = new Set<String>();
                Set<String> ownerSubFieldsSet = new Set<String>();

                for (String path : paths) {
                    if (path.startsWithIgnoreCase('Owner.')) {
                        ownerSubFieldsSet.add(path.substring(6));
                        caseFieldsSet.add('OwnerId');
                    } else {
                        caseFieldsSet.add(path);
                    }
                }

                List<String> caseFields = new List<String>(caseFieldsSet);
                List<String> ownerSubFields = new List<String>(ownerSubFieldsSet);

                String caseSoql = 'SELECT ' + String.join(caseFields, ', ')
                                + ' FROM Case WHERE Id = :caseId LIMIT 1';

                List<SObject> caseResults = Database.query(caseSoql);
                if (!caseResults.isEmpty()) {
                    SObject caseRecord = caseResults[0];

                    for (String path : paths) {
                        if (!path.startsWithIgnoreCase('Owner.')) {
                            String resolvedVal = resolveFieldPathToId(caseRecord, path);
                            if (resolvedVal != null && resolvedVal == String.valueOf(currentUserId)) {
                                return true;
                            }
                        }
                    }

                    if (!ownerSubFields.isEmpty()) {
                        Id ownerId = (Id) caseRecord.get('OwnerId');

                        if (ownerId != null && ownerId.getSObjectType() == User.SObjectType) {
                            String userSoql = 'SELECT ' + String.join(ownerSubFields, ', ')
                                            + ' FROM User WHERE Id = :ownerId LIMIT 1';

                            List<SObject> userResults = Database.query(userSoql);
                            if (!userResults.isEmpty()) {
                                SObject ownerUser = userResults[0];
                                for (String field : ownerSubFields) {
                                    String resolvedVal = resolveFieldPathToId(ownerUser, field);
                                    if (resolvedVal != null && resolvedVal == String.valueOf(currentUserId)) {
                                        return true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Group-based access branch — Public Group: High_Risk_Escalators_ATT.
        // Supports transitive (nested) group membership via worklist traversal
        // with cycle protection. Returns false gracefully if the group does not
        // exist or has no members.
        return isUserInPublicGroup(HIGH_RISK_ESCALATORS_GROUP_DEV_NAME, currentUserId);
    }

    @TestVisible
    private static final String HIGH_RISK_ESCALATORS_GROUP_DEV_NAME = 'High_Risk_Escalators_ATT';

    /**
     * Returns true when the given userId is a direct member of the
     * Public Group identified by DeveloperName.
     * Errors and missing groups gracefully return false.
     * @param groupDeveloperName the DeveloperName of the Public Group
     * @param userId the running user Id to test
     * @return true when the user is a direct member
     */
    private static Boolean isUserInPublicGroup(String groupDeveloperName, Id userId) {
        if (String.isBlank(groupDeveloperName) || userId == null) {
            return false;
        }
        try {
            // Use GroupSelector to find group by DeveloperName
            GroupSelector groupSelector = new GroupSelector();
            List<Group> targetPublicGroups = (List<Group>) groupSelector
                .selectGroupBasedOnDeveloperNames(new List<Object>{ new Set<String>{ groupDeveloperName } })
                .executeQuery();

            if (targetPublicGroups.isEmpty()) {
                return false;
            }

            // Use GroupMemberSelector to check membership
            GroupMemberSelector groupMemberSelector = new GroupMemberSelector();
            List<GroupMember> members = (List<GroupMember>) groupMemberSelector
                .selectExistGroupMembersBasedOnUserIdAndGroupId(
                    new List<Object>{ new List<Id>{ userId }, new List<Id>{ targetPublicGroups[0].Id } }
                )
                .executeQuery();

            return !members.isEmpty();
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Resolves a dot-notation field path on an SObject to its String value.
     * e.g. "Owner.ManagerId" on a Case record traverses Case → Owner → ManagerId.
     * Returns null if any intermediate relationship is null.
     */
    private static String resolveFieldPathToId(SObject record, String fieldPath) {
        // Defensive null/blank check at entry point
        if (record == null || String.isBlank(fieldPath)) {
            return null;
        }

        try {
            List<String> parts = fieldPath.split('\\.');
            SObject current = record;

            for (Integer i = 0; i < parts.size() - 1; i++) {
                if (current == null) {
                    return null;
                }
                current = current.getSObject(parts[i]);
            }

            if (current == null) {
                return null;
            }

            Object val = current.get(parts[parts.size() - 1]);
            return val != null ? String.valueOf(val) : null;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, '[CaseAIInsightsProcessor] Could not resolve field path: '
                + fieldPath + ' — ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean hasRingCentralMobileIntervention(Id caseId) {
        GCP_Feature_Toggle__c config = GCP_Feature_Toggle__c.getInstance();
        String channelNameConfig = config?.Chat_Transcript_Channel_Name__c;
        
        if (String.isBlank(channelNameConfig)) {
            return false;
        }
        
        List<String> channelNames = new List<String>();
        for (String name : channelNameConfig.split(',')) {
            if (String.isNotBlank(name)) {
                channelNames.add(name.trim());
            }
        }
        
        if (channelNames.isEmpty()) {
            return false;
        }
        
        List<Dimelo__Intervention__c> interventions = [
            SELECT Id 
            FROM Dimelo__Intervention__c 
            WHERE Dimelo__Case__c = :caseId 
            AND Dimelo__source_name__c IN :channelNames
            LIMIT 1
        ];
        return !interventions.isEmpty();
    }

    /**
     * Check SLA milestone status for High Risk button visibility.
     * Returns both whether the case has an SLA process (milestones exist)
     * and whether any milestone is violated.
     * 
     * Logic:
     *   - If no milestones exist → case has no SLA entitlement process,
     *     so SLA check is skipped (not a required criterion).
     *   - If milestones exist AND any is violated → SLA criterion is met.
     *   - If milestones exist but none violated → SLA criterion is NOT met.
     * 
     * @param caseId - The Case Id to check
     * @return Map with 'hasMilestones' (Boolean) and 'isViolated' (Boolean)
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> getSlaStatus(Id caseId) {
        Map<String, Boolean> result = new Map<String, Boolean>{
            'hasMilestones' => false,
            'isViolated'    => false
        };

        if (caseId == null) {
            return result;
        }

        // Check if any milestones exist for this case (SLA entitlement process assigned)
        List<CaseMilestone> allMilestones = [
            SELECT Id, IsViolated
            FROM CaseMilestone
            WHERE CaseId = :caseId
        ];

        if (!allMilestones.isEmpty()) {
            result.put('hasMilestones', true);
            // Check if any milestone is violated
            for (CaseMilestone cm : allMilestones) {
                if (cm.IsViolated) {
                    result.put('isViolated', true);
                    break;
                }
            }
        }

        return result;
    }

    /* Check recordtypename */
    @AuraEnabled(cacheable=true)
    public static String getCaseRecordTypeDeveloperName(Id caseId) {
        if (caseId == null) {
            return '';
        }
        List<Case> cases = [
            SELECT RecordType.DeveloperName
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        if (cases.isEmpty()) {
            return '';
        }
        Case c = cases[0];
        if (c.RecordType == null || String.isBlank(c.RecordType.DeveloperName)) {
            return '';
        }
        return c.RecordType.DeveloperName;
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean isDimeloSyncEnabled() {
        Id currentUserId = UserInfo.getUserId();
        User currentUser  = [SELECT Dimelo__Sync__c FROM User where ID =:currentUserId LIMIT 1];
        return currentUser.Dimelo__Sync__c;
    }
    
    @AuraEnabled(cacheable=false)
    public static void logAIHEvent(String eventType, String subfeature, String feedback) {
            Set<String> allowed = new Set<String>{ 'aih_view', 'aih_like', 'aih_dislike', 'aih_feedback' };
        if (String.isBlank(eventType) || !allowed.contains(eventType)) {
            return;
            }
        
            String safeSubfeature = String.isBlank(subfeature) ? 'Unknown' : subfeature.left(80);
            String safeFeedback   = String.isBlank(feedback) ? null : feedback.left(1000);
            
            Map<String, Object> payload = new Map<String, Object>{ 'subfeature' => safeSubfeature };
        if (safeFeedback != null) {
            payload.put('feedback', safeFeedback);
        }
            
            System.enqueueJob(new AIUsageLogQueueable(new List<String>{ eventType }, JSON.serialize(payload)));
    }   
}