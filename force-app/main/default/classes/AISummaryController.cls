public with sharing class AISummaryController {

    @AuraEnabled(cacheable=true)
    public static String generateOpptySummary(Id recordId) {
        String jsonData;
        String systemMessage;
        String userTemplate;
        Opportunity opptyDetail = [
        	SELECT Id, Name, CloseDate, Estimated_12M_Total_Pipeline__c, LeadSource, Brand_Name__c,
            Discovery_Next_Steps__c, STC_Current_Situation__c, StageName, Type, Tier_Name__c,
            Probability, Expiration_Date__c,
            (SELECT Id, Subject, ActivityDate, Status, Type, Description FROM Tasks ORDER BY ActivityDate ASC),
            (SELECT Id, Subject, ActivityDateTime, Description FROM Events ORDER BY ActivityDateTime ASC),
            (SELECT Id, Name, Start_Date__c, End_Date__c, TotalPrice, Initial_Discount__c, Total_Initial_Payment__c FROM Quotes)
            FROM Opportunity 
            WHERE Id = :recordId LIMIT 1
        ];

        jsonData = JSON.serialize(opptyDetail);

       	systemMessage = getConfigValue('Summary_System_Message');
        userTemplate = getConfigValue('Opportunity_Summary_User_Template');

        String userPrompt = userTemplate + '\n\nData = ' + jsonData;
        return makeCall(userPrompt, systemMessage);
    }


    @AuraEnabled(cacheable=true)
    public static String generateAccountSummary(Id recordId) {
        List<Account> accountDetails = [SELECT Id, Name,Type, Industry, RC_Account_Status__c, BillingCountry, CombinedCurrentTotalMRR__c,Next_Renewal_Date__c,
                                        AccountSource, SegmentName__c, SM_Employees__c, RC_Brand__c,
                                        (select Name, RC_Contact_Status__c, Contact_Status__c, Customer_Contact_Role__c, Do_Not_Call__c from Contacts),
                                        (select StageName, Amount, CloseDate from Opportunities),
                                        (select Subject, status from cases)
                                        FROM Account WHERE Id = :recordId];
        String jsonData = JSON.serialize(accountDetails);

        String systemMessage = getConfigValue('Summary_System_Message');
        String userTemplate = getConfigValue('Account_Summary_User_Template');

        String userPrompt = userTemplate + '\n\nData = ' + jsonData;
        return makeCall(userPrompt, systemMessage);
    }

    @AuraEnabled(cacheable=true)
    public static String generateCaseSummary(Id recordId) {
        Case caseDetail = [SELECT CaseNumber, account.name, contact.name, Case_Severity__c, Call_Category__c, subject, description,  Status, 
                           Partner_Case_Status__c, Resolution__c, Reason_Why_Open__c, Invalid_Escalation_Reason__c,
                           (SELECT Id, CommentBody, CreatedById, CreatedDate FROM CaseComments)
                           FROM case WHERE Id = :recordId limit 1];
        String jsonData = JSON.serialize(caseDetail);

        String systemMessage = getConfigValue('Case_Summary_System_Message');
        String userTemplate = getConfigValue('Case_Summary_User_Template');

        String userPrompt = userTemplate + '\n\nData = ' + jsonData;

        return makeCall(userPrompt, systemMessage);
    }
    
    @AuraEnabled(cacheable=true)
    public static String generateLeadSummary(Id recordId) {
        Lead leadDetail = [
                SELECT Id, Name, Phone, Company, Email, LeadSource, Country__c, Industry, Status, Marketo_Segment_Name__c, Lead_Score__c,
                (SELECT Id, Subject, ActivityDate, Status, Type, Description FROM Tasks ORDER BY ActivityDate ASC)
                FROM Lead 
                WHERE Id = :recordId limit 1];
        String jsonData = JSON.serialize(leadDetail);

        String systemMessage = getConfigValue('Case_Summary_System_Message');
        String userTemplate = getConfigValue('Lead_Summary_User_Template');

        String userPrompt = userTemplate + '\n\nData = ' + jsonData;

        return makeCall(userPrompt, systemMessage);
    }



    @AuraEnabled(cacheable=true)
    public static Boolean isRedAccountSummaryEnabled() {
        GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
        return (setting != null && setting.Red_Account_Summary_Switch__c == true);
    }

    @AuraEnabled(cacheable=false)
    public static String generateRedAccountSummary(String userId, Id recordId) {
        try {
            // Reuse QueryFactory/GeneralSelector pattern (see AccountTriggerHandler) instead of inline SOQL.
            List<Red_Account__c> redAccList = (List<Red_Account__c>) new QueryFactory(Red_Account__c.SObjectType)
                .selectFields(new List<String>{
                    'Id',
                    'Executive_Summary__c',
                    'Issue_Summary__c',
                    'Detailed_Action_Plan__c'
                })
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{ recordId })
                .setLimit(1)
                .executeQuery();
            if (redAccList.isEmpty()) {
                return JSON.serialize(new Map<String, Object>{
                    'success' => false,
                    'message' => 'Red Account record not found.'
                });
            }
            Red_Account__c redAcc = redAccList[0];

            // Short-circuit: nothing to summarize if all source fields are blank.
            // Return success=true so the UI shows a friendly message instead of a red error.
            if (
                String.isBlank(redAcc.Executive_Summary__c) &&
                String.isBlank(redAcc.Issue_Summary__c) &&
                String.isBlank(redAcc.Detailed_Action_Plan__c)
            ) {
                return JSON.serialize(new Map<String, Object>{
                    'success' => true,
                    'message' => 'No content available to summarize.'
                });
            }

            // Reuse existing UserSelector building block; chain minimal field set on top.
            List<User> userList = (List<User>) new UserSelector()
                .selectUsersByIdNoFields(new List<Object>{ new Set<Id>{ (Id) userId } })
                .selectFields(new List<SObjectField>{ User.Id, User.Username })
                .setLimit(1)
                .executeQuery();
            if (userList.isEmpty()) {
                return JSON.serialize(new Map<String, Object>{
                    'success' => false,
                    'message' => 'User not found.'
                });
            }
            User userRecord = userList[0];

            Boolean redactRequired = GCPAuthUtil.getRedactionFlag();
            GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig(GCPAuthUtil.RED_ACCOUNT_SUMMARY);
            String jwt = GCPAuthUtil.createSignedJWT(config);
            String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(jwt, config.identityTokenUrl);

            Map<String, Object> payload = new Map<String, Object>{
                'username'      => userRecord.UserName,
                'recordId'      => recordId,
                'risk_reason'   => redAcc.Executive_Summary__c,
                'next_steps'    => redAcc.Detailed_Action_Plan__c,
                'current_status'=> redAcc.Issue_Summary__c,
                'redactRequired'=> String.valueOf(redactRequired)
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint(config.cloudRunEndpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + idToken);
            req.setBody(JSON.serialize(payload));
            req.setTimeout(120000);

            HttpResponse res = new Http().send(req);
            System.debug('Response : '+ res);
            System.debug('Response body : '+ res.getBody());

            // Validate the callout result before attempting to parse the body.
            if (res.getStatusCode() != 200 || String.isBlank(res.getBody())) {
                return JSON.serialize(new Map<String, Object>{
                    'success' => false,
                    'message' => 'Summarization service returned an unexpected response (status code: ' + res.getStatusCode() + ').'
                });
            }
            return parseRedAccountSummaryResponse(res.getBody());
        } catch (Exception e) {
            System.debug('Exception body : '+ e);
            return JSON.serialize(new Map<String, Object>{ 'success' => false, 'message' => e.getMessage() });
        }
    }

    @TestVisible
    private static String parseRedAccountSummaryResponse(String responseBody) {
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Object body = parsed.get('body');
        Map<String, Object> responseMap = parsed;

        if (body instanceof Map<String, Object>) {
            responseMap = (Map<String, Object>) body;
        } else if (body instanceof String) {
            String bodyText = (String) body;
            Object parsedBody;
            try {
                parsedBody = JSON.deserializeUntyped(bodyText);
            } catch (Exception parseException) {
                if (parsed.get('statusCode') == 200) {
                    return JSON.serialize(new Map<String, Object>{ 'success' => true, 'summary' => bodyText });
                }
                return JSON.serialize(new Map<String, Object>{ 'success' => false, 'message' => bodyText });
            }

            if (parsedBody instanceof Map<String, Object>) {
                responseMap = (Map<String, Object>) parsedBody;
            } else {
                return JSON.serialize(new Map<String, Object>{ 'success' => false, 'message' => bodyText });
            }
        }

        Object redAccSummary = responseMap.get('red_account_summary');
        if (redAccSummary instanceof Map<String, Object>) {
            String summary = buildKeyedSummary((Map<String, Object>) redAccSummary);
            return JSON.serialize(new Map<String, Object>{ 'success' => true, 'summary' => summary });
        }

        if (responseMap.containsKey('overall_summary') || responseMap.containsKey('risk_reason')
                || responseMap.containsKey('current_status') || responseMap.containsKey('next_steps')) {
            String summary = buildKeyedSummary(responseMap);
            return JSON.serialize(new Map<String, Object>{ 'success' => true, 'summary' => summary });
        }

        Object message = responseMap.get('message');
        if (message == null) {
            message = responseMap.get('error');
        }
        return JSON.serialize(new Map<String, Object>{
            'success' => false,
            'message' => message == null ? 'Unexpected response format' : String.valueOf(message)
        });
    }

    private static String makeCall(String userPrompt, String systemMessage) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Open_AI/v1/chat/completions');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);

        String requestBody = JSON.serialize(new Map<String, Object>{
            'model' => 'gpt-4.1',
                'messages' => new List<Object>{
                    new Map<String, Object>{ 
                        'role' => 'system',
                            'content' => systemMessage
                            },
                                new Map<String, Object>{ 
                                    'role' => 'user', 
                                        'content' => userPrompt
                                        }
                },
                    'max_tokens' => 500,
                    'temperature' => 0.3
                    });

        request.setBody(requestBody);
        HttpResponse response = http.send(request);
        return processChatGPTResponse(response.getBody());
    }

    private static String processChatGPTResponse(String responseBody) {
        String aiResponse = '';
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> choices = (List<Object>) responseMap.get('choices');

        if (!choices.isEmpty()) {
            Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
            Map<String, Object> messageContent = (Map<String, Object>) firstChoice.get('message');
            aiResponse = (String) messageContent.get('content');
        }
        return aiResponse;
    }

    // Parses the new GCP keyed-JSON format where body.red_account_summary is an object with four
    // string fields (overall_summary, risk_reason, current_status, next_steps), each containing
    // HTML. Strips HTML tags and reconstructs a flat text string with section headers in a fixed
    // order so the LWC _parseSections helper can render bullet/newline structure.
    private static String buildKeyedSummary(Map<String, Object> sections) {
        List<String> lines = new List<String>();
        appendKeyedSection(lines, 'Overall Summary', sections.get('overall_summary'));
        appendKeyedSection(lines, 'Risk Reason',     sections.get('risk_reason'));
        appendKeyedSection(lines, 'Current Status',  sections.get('current_status'));
        appendKeyedSection(lines, 'Next Steps',      sections.get('next_steps'));
        return String.join(lines, '\n');
    }

    private static void appendKeyedSection(List<String> lines, String header, Object value) {
        if (!(value instanceof String)) {
            return;
        }
        String html = (String) value;
        if (String.isBlank(html)) {
            return;
        }
        List<String> bullets = new List<String>();
        for (String part : html.split('</p>')) {
            String clean = part.replaceAll('<[^>]+>', '').replaceAll('\\s+', ' ').trim();
            if (String.isNotBlank(clean)) {
                bullets.add(clean);
            }
        }
        if (bullets.isEmpty()) {
            String clean = html.replaceAll('<[^>]+>', '').replaceAll('\\s+', ' ').trim();
            if (String.isNotBlank(clean)) {
                bullets.add(clean);
            }
        }
        if (!bullets.isEmpty()) {
            lines.add(header);
            for (String b : bullets) {
                lines.add('- ' + b);
            }
        }
    }

    // 🛡️ Safe config fetch
    private static String getConfigValue(String configName) {
        List<AIReporting_Config__mdt> configList = [
            SELECT Config_Value__c
            FROM AIReporting_Config__mdt
            WHERE Config_Name__c = :configName
            LIMIT 1
        ];

        if (!configList.isEmpty() && String.isNotBlank(configList[0].Config_Value__c)) {
            return configList[0].Config_Value__c;
        }
        return '';
    }
    
    // Subfeature-specific logger on purpose: will diverge soon (new tracking fields/payload).
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