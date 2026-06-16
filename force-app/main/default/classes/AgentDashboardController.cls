public with sharing class AgentDashboardController {
    
    private static final Integer HTTP_TIMEOUT_MS = 120000;
    private static final String  CONTENT_TYPE_JSON = 'application/json';
    private static final String  ERR_GCP_CALL_FAILED_PREFIX = 'GCP call failed. Status: ';
    
    @AuraEnabled(cacheable=false)
    public static String getBatchCasesWithInsights(String userId) {
        try {
            // Get user info
            User userRecord = [SELECT UserName FROM User WHERE Id = :userId LIMIT 1];
            String userName = userRecord.UserName;
            
             GCP_Feature_Toggle__c GCP = GCP_Feature_Toggle__c.getInstance();
             Integer CaseCount = (GCP != null && GCP.Agent_Dashboard_CaseCount__c != null) 
                    ? Integer.valueOf(GCP.Agent_Dashboard_CaseCount__c) 
                    : 30;
            
            // Query latest 30 open cases assigned to the user.
            // Date_Assigned__c is intentionally excluded: FLS on that field is restricted to
            // certain profiles only, so it cannot be safely read in user context. The assigned
            // date is derived below from CaseHistory instead.
            List<Case> cases = [
                SELECT Id, CaseNumber, Priority, Initial_Severity__c, Case_Severity__c, 
                       CreatedDate, Last_Modified_Age__c, Subject, Description, 
                       CSAT_Prediction__c, CSAT_Prediction_after_Manager_Callback__c, 
                       Status, IsEscalated, LastModifiedDate, LastModifiedBy.Name, Date_Started__c,
                       RecordType.Name,
                       (SELECT Id FROM MOD_Escalations__r)
                FROM Case
                WHERE OwnerId = :userId 
                AND IsClosed = false
                ORDER BY CreatedDate DESC
                LIMIT :CaseCount
            ];
            
            if (cases.isEmpty()) {
                return JSON.serializePretty(new Map<String, Object>{
                    'success' => true,
                    'cases' => new List<Object>()
                });
            }

            // Derive the date the current owner was assigned using CaseHistory.
            // Logic mirrors the trigger (CaseTriggerHandler.PopulateCaseDates):
            //   - on insert           → assigned date = case creation date
            //   - on OwnerId change   → assigned date = date of the last owner change
            // CaseHistory.Field = 'Owner' records are created automatically by the platform
            // whenever OwnerId is updated (requires Owner field history tracking to be enabled).
            // Querying CaseHistory runs in system context and has no FLS dependency.
            Set<Id> caseIds = new Map<Id, Case>(cases).keySet();
            List<CaseHistory> ownerHistory = [
                SELECT CaseId, CreatedDate
                FROM CaseHistory
                WHERE CaseId IN :caseIds
                AND Field = 'Owner'
                ORDER BY CreatedDate DESC
            ];

            // Keep only the most recent ownership-change entry per case
            Map<Id, Date> assignedDateByCaseId = new Map<Id, Date>();
            for (CaseHistory ch : ownerHistory) {
                if (!assignedDateByCaseId.containsKey(ch.CaseId)) {
                    assignedDateByCaseId.put(ch.CaseId, ch.CreatedDate.date());
                }
            }
            System.debug('Queries: ' + Limits.getQueries());
            System.debug('Rows: ' + Limits.getQueryRows());
            
            List<Map<String, Object>> casePayloads = new List<Map<String, Object>>();
            
            for (Case c : cases) {
                Integer noOfDays = c.CreatedDate.date().daysBetween(Date.today());

                // Use the most recent owner-change date from CaseHistory;
                // fall back to CreatedDate when the owner has never changed (mirrors insert trigger)
                Date assignedDate = assignedDateByCaseId.containsKey(c.Id)
                    ? assignedDateByCaseId.get(c.Id)
                    : c.CreatedDate.date();
                
                Map<String, Object> casePayload = new Map<String, Object>{
                    'recordID'                      => c.Id,
                    'case_id'                       => c.Id,
                    'caseNumber'                    => c.CaseNumber,
                    'priority'                      => c.Priority,
                    'initial_severity'              => c.Initial_Severity__c,
                    'case_severity'                 => c.Case_Severity__c,
                    'case_age'                      => noOfDays,
                    'untouched_date'                => c.Last_Modified_Age__c,
                    'subject'                       => c.Subject,
                    'description'                   => c.Description,
                    'customer_sentiment_prediction' => c.CSAT_Prediction__c,
                    'sentiment_manager_callback'    => c.CSAT_Prediction_after_Manager_Callback__c,
                    'case_status'                   => c.Status,
                    'is_escalated'                  => c.IsEscalated,
                    'mod_escalation_no'             => c.MOD_Escalations__r.size(),
                    'assignedDate'                  => assignedDate,
                    'lastModifiedByName'            => c.LastModifiedBy.Name,
                    'lastModifiedDate'              => c.LastModifiedDate,
                    'recordTypeName'                => c.RecordType != null ? c.RecordType.Name : null
                };
                
                casePayloads.add(casePayload);
            }
            system.debug('casePayloads::'+casePayloads);
            system.debug('case number::'+casePayloads.size());
            // Use GCPAuthUtil with AGENT_DASHBOARD purpose.
            GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig(GCPAuthUtil.AGENT_DASHBOARD);
            String jwt = GCPAuthUtil.createSignedJWT(config);
            String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(jwt, config.identityTokenUrl);
            
            String response = callAgentDashboardGCP(userName, casePayloads, idToken, config.cloudRunEndpoint);
            
            return response;
            
        } catch (Exception e) {
            System.debug('Error in getBatchCasesWithInsights: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return JSON.serializePretty(new Map<String, Object>{
                'success' => false,
                'message' => e.getMessage()
            });
        }
    }
        
   	 private static String callAgentDashboardGCP(
        String userName, 
        List<Map<String, Object>> casePayloads, 
        String idToken, 
        String endpoint
    ) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', CONTENT_TYPE_JSON);
            req.setHeader('Authorization', 'Bearer ' + idToken);
            
            Map<String, Object> batchPayload = new Map<String, Object>{
                'username' => userName,
                'cases' => casePayloads
            };
            
            String requestBody = JSON.serialize(batchPayload);
            System.debug('Agent Dashboard GCP Request body: ' + requestBody);
            System.debug('Agent : ' + userName);
            
            req.setBody(requestBody);
            req.setTimeout(HTTP_TIMEOUT_MS);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('Agent Dashboard GCP Response status: ' + res.getStatusCode());
            System.debug('Agent Dashboard GCP Response body: ' + res.getBody());
            
            if (res.getStatusCode() != 200) {
                throw new CalloutException(
                    ERR_GCP_CALL_FAILED_PREFIX + res.getStatusCode() + ' - ' + res.getBody()
                );
            }
            
            // Parse response
            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            // Handle GCP format: { "body": { "<caseId>": { case_sentiment, case_sentiment_reason, escalation_sentiment, escalation_sentiment_reason } }, "statusCode": 200 }
            Object bodyObj = parsed.get('body');
            Object statusCodeObj = parsed.get('statusCode');
            if (bodyObj instanceof Map<String, Object> && statusCodeObj != null && '200'.equals(String.valueOf(statusCodeObj))) {
                Map<String, Object> bodyByCaseId = (Map<String, Object>) bodyObj;
                List<Map<String, Object>> processedResults = new List<Map<String, Object>>();
                for (Map<String, Object> casePayload : casePayloads) {
                    String caseId = (String) casePayload.get('recordID');
                    Object insightsObj = bodyByCaseId.get(caseId);
                    Map<String, Object> insights = (insightsObj instanceof Map<String, Object>) ? (Map<String, Object>) insightsObj : null;
                    Map<String, Object> processedCase = new Map<String, Object>();
                    processedCase.put('caseId', casePayload.get('recordID'));
                    processedCase.put('caseNumber', casePayload.get('caseNumber'));
                    processedCase.put('priority', casePayload.get('priority'));
                    processedCase.put('status', casePayload.get('case_status'));
                    processedCase.put('caseAge', casePayload.get('case_age'));
                    processedCase.put('assignedDate', casePayload.get('assignedDate'));
                    processedCase.put('lastModifiedByName', casePayload.get('lastModifiedByName'));
                    processedCase.put('lastModifiedDate', casePayload.get('lastModifiedDate'));
                    processedCase.put('recordTypeName', casePayload.get('recordTypeName'));
                    if (insights != null) {
                        processedCase.put('sentiment', insights.get('case_sentiment'));
                        processedCase.put('sentimentReason', insights.get('case_sentiment_reason'));
                        processedCase.put('escalationMetric', insights.get('escalation_sentiment'));
                        processedCase.put('escalationReason', insights.get('escalation_sentiment_reason'));
                    } else {
                        processedCase.put('sentiment', 'N/A');
                        processedCase.put('sentimentReason', '');
                        processedCase.put('escalationMetric', 'N/A');
                        processedCase.put('escalationReason', '');
                    }
                    processedResults.add(processedCase);
                }
                return JSON.serializePretty(new Map<String, Object>{
                    'success' => true,
                    'cases' => processedResults
                });
            }
            
            // Check if response has batch results (legacy format with results array)
            Object batchResults = parsed.get('results');
            if (batchResults != null) {
                List<Object> results = (List<Object>) batchResults;
                List<Map<String, Object>> processedResults = new List<Map<String, Object>>();
                
                for (Object resultObj : results) {
                    Map<String, Object> result = (Map<String, Object>) resultObj;
                    Map<String, Object> processedCase = new Map<String, Object>();
                    
                    // Extract basic case info
                    processedCase.put('caseId', result.get('recordID'));
                    processedCase.put('caseNumber', result.get('caseNumber'));
                    processedCase.put('priority', result.get('priority'));
                    processedCase.put('status', result.get('case_status'));
                    processedCase.put('caseAge', result.get('case_age'));
                    processedCase.put('assignedDate', result.get('assignedDate'));
                    processedCase.put('lastModifiedByName', result.get('lastModifiedByName'));
                    processedCase.put('lastModifiedDate', result.get('lastModifiedDate'));
                    processedCase.put('recordTypeName', result.get('recordTypeName'));
                    
                    // Extract sentiment
                    Map<String, Object> api1 = (Map<String, Object>) result.get('api1_result');
                    if (api1 != null && '200'.equals(String.valueOf(api1.get('statusCode')))) {
                        Object b1 = api1.get('body');
                        if (b1 instanceof Map<String, Object>) {
                            Map<String, Object> sentimentBody = (Map<String, Object>) b1;
                            processedCase.put('sentiment', sentimentBody.get('sentiment'));
                            processedCase.put('sentimentReason', sentimentBody.get('reason'));
                        }
                    } else {
                        processedCase.put('sentiment', 'N/A');
                        processedCase.put('sentimentReason', 'Unable to retrieve sentiment');
                    }
                    
                    // Extract escalation
                    Map<String, Object> api2 = (Map<String, Object>) result.get('api2_result');
                    if (api2 != null && '200'.equals(String.valueOf(api2.get('statusCode')))) {
                        Object b2 = api2.get('body');
                        if (b2 instanceof Map<String, Object>) {
                            Map<String, Object> escalationBody = (Map<String, Object>) b2;
                            processedCase.put('escalationMetric', escalationBody.get('escalation_metric'));
                            processedCase.put('escalationReason', escalationBody.get('reason'));
                        }
                    } else {
                        processedCase.put('escalationMetric', 'N/A');
                        processedCase.put('escalationReason', 'Unable to retrieve escalation');
                    }
                    
                    processedResults.add(processedCase);
                }
                
            return JSON.serializePretty(new Map<String, Object>{
                'success' => true,
                'cases' => processedResults
            });
        }
            
            // Fallback if no batch results - return cases with N/A for GCP data
            List<Map<String, Object>> fallbackResults = new List<Map<String, Object>>();
            for (Map<String, Object> casePayload : casePayloads) {
                Map<String, Object> fallbackCase = new Map<String, Object>();
                fallbackCase.put('caseId', casePayload.get('recordID'));
                fallbackCase.put('caseNumber', casePayload.get('caseNumber'));
                fallbackCase.put('priority', casePayload.get('priority'));
                fallbackCase.put('status', casePayload.get('case_status'));
                fallbackCase.put('caseAge', casePayload.get('case_age'));
                fallbackCase.put('assignedDate', casePayload.get('assignedDate'));
                fallbackCase.put('lastModifiedByName', casePayload.get('lastModifiedByName'));
                fallbackCase.put('lastModifiedDate', casePayload.get('lastModifiedDate'));
                fallbackCase.put('recordTypeName', casePayload.get('recordTypeName'));
                fallbackCase.put('sentiment', 'N/A');
                fallbackCase.put('sentimentReason', 'Response format not recognized');
                fallbackCase.put('escalationMetric', 'N/A');
                fallbackCase.put('escalationReason', 'Response format not recognized');
                fallbackResults.add(fallbackCase);
            }
            
            return JSON.serializePretty(new Map<String, Object>{
                'success' => true,
                'cases' => fallbackResults,
                'warning' => 'GCP response format not recognized, showing cases without AI insights'
            });
            
        } catch (Exception e) {
            System.debug('Error calling Agent Dashboard GCP: ' + e.getMessage());
            throw e;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Integer getClosedCasesCountLastMonth(String userId) {
        List<AggregateResult> results = [
            SELECT COUNT(Id) cnt
            FROM Case
            WHERE OwnerId = :userId
            AND IsClosed = true
            AND ClosedDate = LAST_N_DAYS:30
        ];
        return results.isEmpty() ? 0 : (Integer) results[0].get('cnt');
    }
    
}