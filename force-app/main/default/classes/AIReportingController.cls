public with sharing class AIReportingController {

    private static final AIUsageLoggerBase logger = new AIReportingUsageLogger();
    private static Map<String, Schema.DescribeSObjectResult> sobjectDescribeCache = new Map<String, Schema.DescribeSObjectResult>();
    private static Map<String, Map<String, Schema.SObjectField>> sobjectFieldMapCache = new Map<String, Map<String, Schema.SObjectField>>();
    private static Map<String, String> dynamicMetadataCache = new Map<String, String>();

    private static Schema.DescribeSObjectResult getCachedDescribeResult(String objectApiName) {
        if (!sobjectDescribeCache.containsKey(objectApiName)) {
            Schema.SObjectType objType = ((SObject)Type.forName(objectApiName).newInstance()).getSObjectType();
            if (objType != null) {
                sobjectDescribeCache.put(objectApiName, objType.getDescribe());
            }
        }
        return sobjectDescribeCache.get(objectApiName);
    }

    private static Map<String, Schema.SObjectField> getCachedFieldMap(String objectApiName) {
        if (!sobjectFieldMapCache.containsKey(objectApiName)) {
            Schema.DescribeSObjectResult describeResult = getCachedDescribeResult(objectApiName);
            if (describeResult != null) {
                sobjectFieldMapCache.put(objectApiName, describeResult.fields.getMap());
            }
        }
        return sobjectFieldMapCache.get(objectApiName);
    }

    @AuraEnabled(cacheable=true)
    public static Boolean canUserExportReports() {
        try {
            // Check export permission in Permission Sets
            for (PermissionSet ps : [
                SELECT Name, PermissionsExportReport
                FROM PermissionSet
                WHERE Id IN (
                    SELECT PermissionSetId FROM PermissionSetAssignment
                    WHERE AssigneeId = :UserInfo.getUserId()
                ) AND PermissionsExportReport = true
            ]) {
                return true;
            }

            // Check export permission in Profile
            Boolean hasProfilePermission = [
                SELECT PermissionsExportReport
                FROM Profile
                WHERE Id = :UserInfo.getProfileId()
            ].PermissionsExportReport;

            if (hasProfilePermission) {
                return true;
            }
            return false;
        } catch (Exception e) {
            return false;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getLargeDataMessage() {
        return Label.AIReporting_LargeData_Message;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getPromptSuggestions(String searchText) {
        if (String.isBlank(searchText)) {
            return new List<String>();
        }

        List<String> prompts = new List<String>();

        List<AIReporting_Prompt_Setting__mdt> promptRecords = [
            SELECT Prompt_Text__c
            FROM AIReporting_Prompt_Setting__mdt
            WHERE Prompt_Text__c LIKE :('%' + searchText + '%')
            ORDER BY Prompt_Text__c ASC
        ];

        if (!promptRecords.isEmpty()) {
            for (AIReporting_Prompt_Setting__mdt prompt : promptRecords) {
                if (String.isNotBlank(prompt.Prompt_Text__c)) {
                    prompts.add(prompt.Prompt_Text__c);
                }
            }
        }
        return prompts;
    }

    private static List<String> getAccessibleFields(String objectApiName, List<String> fieldNames) {
        List<String> accessible = new List<String>();

        Map<String, Schema.SObjectField> fieldMap = getCachedFieldMap(objectApiName);
        if (fieldMap == null) {
            return accessible;
        }

        for (String fieldName : fieldNames) {
            String trimmedField = fieldName.trim();

            if (trimmedField.contains('.')) {
                List<String> parts = trimmedField.split('\\.');
                if (parts.size() == 2) {
                    String relationshipName = parts[0];
                    String childField = parts[1];

                    // Find the actual reference field with this relationship name
                    Schema.SObjectField parentField = null;
                    for (String fName : fieldMap.keySet()) {
                        Schema.DescribeFieldResult descr = fieldMap.get(fName).getDescribe();
                        if (descr.getType() == Schema.DisplayType.REFERENCE && descr.getRelationshipName() == relationshipName) {
                            parentField = fieldMap.get(fName);
                            break;
                        }
                    }

                    if (parentField != null) {
                        Schema.DescribeFieldResult parentDesc = parentField.getDescribe();
                        if (parentDesc.isAccessible()) {
                            List<Schema.SObjectType> refTypes = parentDesc.getReferenceTo();
                            if (!refTypes.isEmpty()) {
                                Schema.SObjectType refType = refTypes[0];
                                Map<String, Schema.SObjectField> refFieldMap = refType.getDescribe().fields.getMap();
                                if (refFieldMap.containsKey(childField)) {
                                    Schema.DescribeFieldResult childDesc = refFieldMap.get(childField).getDescribe();
                                    if (childDesc.isAccessible()) {
                                        accessible.add(trimmedField);
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (fieldMap.containsKey(trimmedField)) {
                    Schema.DescribeFieldResult describe = fieldMap.get(trimmedField).getDescribe();
                    if (describe.isAccessible()) {
                        accessible.add(trimmedField);
                    }
                }
            }
        }
        return accessible;
    }

    @TestVisible
    private static String getAllowedFieldsPrompt(String objectApiName, String userProfileName, Boolean isAggregateQuery) {
        if (isAggregateQuery) {
            return '';
        }

        List<AIReporting_Field_Config__mdt> configList = [
            SELECT Allowed_Fields__c, Object_Name__c, Profile_Name__c
            FROM AIReporting_Field_Config__mdt
            WHERE Object_Name__c = :objectApiName
            AND Profile_Name__c = :userProfileName
            LIMIT 1
        ];

        String fields = '';
        if (!configList.isEmpty() && String.isNotBlank(configList[0].Allowed_Fields__c)) {
            fields = configList[0].Allowed_Fields__c;
        } else {
            // 🛡️ Fallback to "Default" if profile-specific config not found
            List<AIReporting_Field_Config__mdt> defaultList = [
                SELECT Allowed_Fields__c, Object_Name__c, Profile_Name__c
                FROM AIReporting_Field_Config__mdt
                WHERE Object_Name__c = :objectApiName
                AND Profile_Name__c = 'Default'
                LIMIT 1
            ];
            if (!defaultList.isEmpty() && String.isNotBlank(defaultList[0].Allowed_Fields__c)) {
                fields = defaultList[0].Allowed_Fields__c;
            }
        }

        if (String.isNotBlank(fields)) {
            List<String> allFields = new List<String>();
            for (String f : fields.split(',')) {
                if (!String.isBlank(f)) {
                    allFields.add(f.trim());
                }
            }
            List<String> accessibleFields = getAccessibleFields(objectApiName, allFields);
            return String.join(accessibleFields, ',');
        }
        return '';
    }

    private static String getConfigValue(String configName) {
        List<AIReporting_Config__mdt> configList = [
            SELECT Config_Name__c, Config_Value__c
            FROM AIReporting_Config__mdt
            WHERE Config_Name__c = :configName
            LIMIT 1
        ];

        if (!configList.isEmpty() && String.isNotBlank(configList[0].Config_Value__c)) {
            return configList[0].Config_Value__c;
        }

        return '';
    }

    private static Map<String, Set<String>> loadObjectVariants() {
        Map<String, Set<String>> objectVariants = new Map<String, Set<String>>();

        for (AIReporting_Object_Config__mdt record : [
            SELECT Object_Api_Name__c, Prompt_Keywords__c 
            FROM AIReporting_Object_Config__mdt
            WHERE Object_Api_Name__c != null
        ]) {
            String objectName = record.Object_Api_Name__c.trim();
            Set<String> variants = new Set<String>();

            for (String keyword : record.Prompt_Keywords__c.split(',')) {
                if (!String.isBlank(keyword)) {
                    variants.add(keyword.trim().toLowerCase());
                }
            }

            objectVariants.put(objectName, variants);
        }
        return objectVariants;
    }

    private static Set<String> getObjectsFromPrompt(String userPrompt) {
        Map<String, Set<String>> objectVariants = loadObjectVariants();
        Set<String> objectNames = new Set<String>();

        String promptLower = userPrompt.toLowerCase();

        Boolean useSalesAgreementPath = isSalesAgreementProductPrompt(userPrompt);

        if (useSalesAgreementPath) {
            objectNames.addAll(new Set<String>{ 'Opportunity', 'Quote', 'QuoteLineItem', 'Product2', 'Account' });
        } else {
            for (String objectName : objectVariants.keySet()) {
                for (String keyword : objectVariants.get(objectName)) {
                    if (promptLower.contains(keyword)) {
                        objectNames.add(objectName);
                        break;
                    }
                }
            }
        }

        return objectNames;
    }

    @AuraEnabled
    public static String getAISummary(String tableData) {
        try {
            String summaryTemplate = getConfigValue('Summary_Prompt_Template');   
            String systemMessage = getConfigValue('Summary_System_Message');

            String userPrompt = summaryTemplate + '\n' + tableData;

            HttpResponse response = callOpenAI(systemMessage, userPrompt);

            if (response.getStatusCode() == 200) {
                // ✅ Log feedback after callout
                logger.logSummary();// called when summarize is clicked
                return processChatGPTResponse(response.getBody());
            }
            return JSON.serialize(new Map<String, Object>{ 'error' => 'Error: No response from AI' });
        } catch (Exception e) {
            return JSON.serialize(new Map<String, Object>{ 'error' => e.getMessage() });
        }
    }

    @AuraEnabled
    public static String getAIReport(String queryInput) {
        try {
            if (isSalesAgreementProductPrompt(queryInput)) {
                String result = resolveStepwiseQueryFromOpenAI(queryInput);
                logger.logAccessAndPrompt(queryInput);
                return result;
            }
            String metadataPrompt = getDynamicMetadataBasedOnPrompt(queryInput);
            String baseSystemPrompt = getConfigValue('Query_Generation_System_Message');
            String dynamicFieldInstructions = buildDynamicFieldInstructions(queryInput, false);

            String finalSystemPrompt = baseSystemPrompt + '\n\n' + dynamicFieldInstructions + '\n\nBelow is metadata for fields and record types in this Salesforce org:\n' + metadataPrompt;

            String userPromptTemplate = getConfigValue('Query_User_Prompt_Template');
            String userPrompt = userPromptTemplate + queryInput;

            HttpResponse response = callOpenAI(finalSystemPrompt, userPrompt);            

            if (response.getStatusCode() == 200) {
                logger.logAccessAndPrompt(queryInput);
                return processChatGPTResponse(response.getBody());
            }
            return JSON.serialize(new Map<String, Object>{ 'error' => 'Error: No response from AI' });
        } catch (Exception e) {
            return JSON.serialize(new Map<String, Object>{ 'error' => e.getMessage() });
        }
    }

    private static String resolveStepwiseQueryFromOpenAI(String queryInput) {
        try {
            String metadata = getDynamicMetadataBasedOnPrompt(queryInput);
            String systemPrompt = getConfigValue('Query_Stepwise_System_Message');
            String dynamicFieldInstructions = buildDynamicFieldInstructions(queryInput, true);
            String userPrompt = getConfigValue('Query_User_Prompt_Template') + queryInput;

            // 👇 Append dynamic field instructions to guide OpenAI on what fields to select
            String finalSystemPrompt = systemPrompt + '\n\n' + dynamicFieldInstructions + '\n\nBelow is metadata for fields and record types in this Salesforce org:\n' + metadata;

            HttpResponse response = callOpenAI(finalSystemPrompt, userPrompt);

            if (response.getStatusCode() != 200) {
                return JSON.serialize(new Map<String, Object>{ 'error' => 'Stepwise AI call failed' });
            }

            String responseBody = response.getBody();

            // ✅ Extract content from OpenAI message
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object> choices = (List<Object>) responseMap.get('choices');
            if (choices.isEmpty()) {
                return JSON.serialize(new Map<String, Object>{ 'error' => 'No choices returned from AI' });
            }

            Map<String, Object> message = (Map<String, Object>) ((Map<String, Object>) choices[0]).get('message');
            String content = (String) message.get('content');

            if (String.isBlank(content)) {
                return JSON.serialize(new Map<String, Object>{ 'error' => 'AI returned blank content' });
            }

            // ✅ Clean markdown if needed
            content = content.replaceAll('```json', '').replaceAll('```', '').trim();

            Map<String, Object> stepsMap = (Map<String, Object>) JSON.deserializeUntyped(content);
            String step1 = String.valueOf(stepsMap.get('step1'));
            String step2 = String.valueOf(stepsMap.get('step2'));
            String step3 = String.valueOf(stepsMap.get('step3'));
            
            // ❌ Check for nested subqueries (invalid pattern)
            if ((step1.contains('SELECT') && step1.toLowerCase().contains('from (')) ||
                (step2.contains('SELECT') && step2.toLowerCase().contains('from (')) ||
                (step3.contains('SELECT') && step3.toLowerCase().contains('from ('))) {
                    return JSON.serialize(new Map<String, Object>{
                        'error' => 'AI returned invalid nested SOQL queries. Please retry or rephrase the prompt.'
                            });
                }

            Set<Id> quoteIds = new Set<Id>();
            Set<Id> opportunityIds = new Set<Id>();

            // Step 1: QuoteLineItem → QuoteId
            List<QuoteLineItem> qlis = (List<QuoteLineItem>) Database.query(step1);
            for (QuoteLineItem qli : qlis) {
                if (qli.QuoteId != null) {
                    quoteIds.add(qli.QuoteId);
                }
            }

            // Step 2: Quote → OpportunityId
            if (!quoteIds.isEmpty()) {
                // Final replacement with real ID list
                String step2Final = step2.replace(':QUOTE_IDS_FROM_STEP_1', formatIdList(quoteIds));
                List<Quote> quotes = (List<Quote>) Database.query(step2Final);
                for (Quote qt : quotes) {
                    if (qt.OpportunityId != null) {
                        opportunityIds.add(qt.OpportunityId);
                    }
                }
            }

            if (!opportunityIds.isEmpty()) {
                String step3Final = step3.replace(':OPPTY_IDS_FROM_STEP_2', formatIdList(opportunityIds));
                if (isFinalObjectAccount(queryInput)) {
                    // 🔁 Fetch Opportunity.AccountId and then query Accounts
                    List<Opportunity> opptys = (List<Opportunity>) Database.query(step3Final);
                    Set<Id> accountIds = new Set<Id>();
                    for (Opportunity opp : opptys) {
                        if (opp.AccountId != null) {
                            accountIds.add(opp.AccountId);
                        }
                    }
                    if (!accountIds.isEmpty()) {
                        String profileNm = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
                        String accountFields = getAllowedFieldsPrompt('Account', profileNm, false);
                        String accountQuery = 'SELECT ' + accountFields + ' FROM Account WHERE Id IN ' + formatIdList(accountIds);
                        return executeSOQL(accountQuery);
                    }
                    return JSON.serialize(new Map<String, Object>{
                        'records' => new List<Object>(),
                            'fieldLabels' => new Map<String, String>()
                            });
                }
                return executeSOQL(step3Final);
            }
            else {
                return JSON.serialize(new Map<String, Object>{
                    'records' => new List<Object>(),
                        'fieldLabels' => new Map<String, String>()
                        });
            }
        } catch (Exception ex) {
            return JSON.serialize(new Map<String, Object>{ 'error' => ex.getMessage() });
        }
    }

    @TestVisible
    private static String formatIdList(Set<Id> ids) {
        List<String> quotedIds = new List<String>();
        for (Id id : ids) {
            quotedIds.add('\'' + id + '\'');
        }
        return '(' + String.join(quotedIds, ', ') + ')';
    }

    @TestVisible
    private static Boolean isFinalObjectAccount(String userPrompt) {
        String prompt = userPrompt.toLowerCase();

        // Match if prompt includes any form of "account" + some sales-related context
        Boolean mentionsAccount = prompt.contains('account') || prompt.contains('accounts');
        Boolean mentionsContext = 
            prompt.contains('stage') ||
            prompt.contains('product') ||
            prompt.contains('close date') ||
            prompt.contains('closedate'); // handle no-space case too

        return prompt.contains('list of account') || prompt.contains('list of accounts') ||
            (mentionsAccount && mentionsContext);
    }

    private static String buildDynamicFieldInstructions(String queryInput, Boolean isStepwise) {
        Map<String, Set<String>> objectVariants = new Map<String, Set<String>>();
        Set<String> objectNames = new Set<String>();

        if (isStepwise) {
            // For stepwise, use full variant list (all object keys)
            objectVariants = loadObjectVariants();
            objectNames.addAll(objectVariants.keySet());
        } else {
            // For normal flow, use objects detected from prompt
            objectNames = getObjectsFromPrompt(queryInput);
        } 

        String userProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        Pattern aggPattern = Pattern.compile('\\b(total|sum|average|count|maximum|minimum)\\b');
        Boolean isAggregateQuery = aggPattern.matcher(queryInput.toLowerCase()).find();

        String dynamicPart = '';
        for (String objectName : objectNames) {
            String allowedFields = isAggregateQuery ? '' : getAllowedFieldsPrompt(objectName, userProfileName, isAggregateQuery);
            dynamicPart += '- For ' + objectName + ': select ' + allowedFields + ' in this order of sequence.\n';
        }

        return dynamicPart;
    }

    private static HttpResponse callOpenAI(String systemPrompt, String userPrompt) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Open_AI/v1/chat/completions');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);

        String requestBody = JSON.serialize(new Map<String, Object>{
            'model' => 'gpt-4.1',
                'messages' => new List<Object>{
                    new Map<String, Object>{ 'role' => 'system', 'content' => systemPrompt },
                        new Map<String, Object>{ 'role' => 'user', 'content' => userPrompt }
                },
                    'max_tokens' => 500,
                    'temperature' => 0.3
                    });

        request.setBody(requestBody);
        return http.send(request);
    }

    private static Boolean isSalesAgreementProductPrompt(String prompt) {
        String normalizedPrompt = prompt.toLowerCase().replaceAll('[^a-z0-9]', ''); // remove spaces/punctuation

        // Product-related keywords
        Pattern productPattern = Pattern.compile('product|productname|item|sku|lineitem');
        Boolean mentionsProduct = productPattern.matcher(normalizedPrompt).find();
        
        // Opportunity-related keywords
        Pattern opportunityPattern = Pattern.compile('opportunity|opportunities');
        Boolean mentionsOpportunity = opportunityPattern.matcher(normalizedPrompt).find();

        // Account-related keywords
        Pattern accountPattern = Pattern.compile('account|accounts');
        Boolean mentionsAccount = accountPattern.matcher(normalizedPrompt).find();

        // Return true if:
        // 1. product + opportunity
        // 2. product + account
        // 3. mentions quote/sales agreement logic
        return (mentionsProduct && (mentionsOpportunity || mentionsAccount));
    }

    private static String getDynamicMetadataBasedOnPrompt(String userPrompt) {
        Set<String> objectNames = getObjectsFromPrompt(userPrompt);
        // Build cache key → a sorted joined list of object names       
        List<String> objectNameList = new List<String>(objectNames);
        objectNameList.sort();
        String cacheKey = String.join(objectNameList, '|');
        // Check cache first
        if (dynamicMetadataCache.containsKey(cacheKey)) {
            return dynamicMetadataCache.get(cacheKey);
        }

        List<String> metadataLines = new List<String>();

        for (String objName : objectNames) {
            Schema.DescribeSObjectResult describeResult = getCachedDescribeResult(objName);
            if (describeResult == null) {
                continue;
            }

            metadataLines.add('\n📦 Metadata for Object: ' + objName + '\n');

            Map<String, Schema.SObjectField> fields = getCachedFieldMap(objName);
            for (String fieldName : fields.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fields.get(fieldName).getDescribe();
                String line = 'API Name: ' + fieldName +
                    ', Label: "' + fieldDescribe.getLabel() +
                    '", Type: ' + String.valueOf(fieldDescribe.getType());
                metadataLines.add(line);
                if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
                    List<String> pickVals = new List<String>();
                    for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                        if (entry.isActive()) {
                            String label = entry.getLabel();
                            String apiValue = entry.getValue();
                            metadataLines.add('Label: "' + label + '", API Value: "' + apiValue + '"');
                        }
                    }
                }
            }

            // Dynamically include Child Relationships
            List<Schema.ChildRelationship> childRelationships = describeResult.getChildRelationships();
            if (!childRelationships.isEmpty()) {
                metadataLines.add('\n👶 Child Relationships:');
                for (Schema.ChildRelationship childRel : childRelationships) {
                    String relName = childRel.getRelationshipName();
                    if (String.isBlank(relName)) {
                        // 🔴 skip unknown relationship names
                        continue;
                    }

                    String childLabel = '';

                    Schema.SObjectType childType = childRel.getChildSObject();
                    childLabel = childType.getDescribe().getLabel(); // 🔍 Get the label of the child object
                    metadataLines.add('Child Object: ' + childRel.getChildSObject() +
                                      ', Label: "' + childLabel + '"' +
                                      ', Relationship Name: ' + relName +
                                      ', Field: ' + childRel.getField());
                }
            }
            // Dynamically include Parent (Lookup) Relationships
            metadataLines.add('\n🔗 Parent Relationships (Lookup Fields):');
            for (Schema.SObjectField fld : fields.values()) {
                Schema.DescribeFieldResult fldDescribe = fld.getDescribe();
                if (fldDescribe.getType() == Schema.DisplayType.Reference) {
                    List<Schema.SObjectType> parentTypes = fldDescribe.getReferenceTo();
                    List<String> parentNames = new List<String>();

                    for (Schema.SObjectType parentType : parentTypes) {
                        parentNames.add(parentType.getDescribe().getName());
                    }

                    metadataLines.add('Field: ' + fldDescribe.getName() + ', Parent Objects: ' + String.join(parentNames, ', '));
                }
            }
            metadataLines.add('\n🧭 Relationship Index (for AI reference):');
            metadataLines.add('- Use parent relationships with dot notation (e.g., Opportunity.Owner.Name)');
            metadataLines.add('- Use child relationships with subquery syntax (e.g., (SELECT Id, Name FROM OpportunityLineItems))');

            // Record Type Mappings (only for current object)
            List<RecordType> rtList = [
                SELECT Name, DeveloperName
                FROM RecordType
                WHERE SObjectType = :objName
            ];
            if (!rtList.isEmpty()) {
                metadataLines.add('\n🔁 RecordType Mappings for ' + objName + ':');
                for (RecordType rt : rtList) {
                    metadataLines.add('Label: "' + rt.Name + '" = API Name: "' + rt.DeveloperName + '"');
                }
            }
        }

        String metadata = String.join(metadataLines, '\n');
        if (metadata.length() > 350000) {
            metadata = metadata.substring(0, 350000);
        }

        dynamicMetadataCache.put(cacheKey, metadata);       
        return metadata;
    }

    private static String processChatGPTResponse(String responseBody) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> choices = (List<Object>) responseMap.get('choices');
 
        if (!choices.isEmpty()) {
            Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
            Map<String, Object> messageContent = (Map<String, Object>) firstChoice.get('message');
            String aiResponse = (String) messageContent.get('content');

            if (aiResponse.toLowerCase().contains('select') && aiResponse.toLowerCase().contains('from')) {
                String soqlQuery = cleanAIResponse(aiResponse);
                return executeSOQL(soqlQuery);
            } else {
                return JSON.serialize(new Map<String, Object>{ 'message' => aiResponse });
            }
        }
        return JSON.serialize(new Map<String, Object>{ 'error' => 'Error: No valid response from AI' });
    }

    @TestVisible
    private static String executeSOQL(String soqlQuery) {
        try {
            List<sObject> records = Database.query(soqlQuery, AccessLevel.USER_MODE);
            if (records.isEmpty()) {
                return JSON.serialize(new Map<String, Object>{
                    'records' => new List<Map<String, Object>>(),
                        'fieldLabels' => new Map<String, String>()
                        });
            }

            // 👇 Get object name from first record
            String objectName = records[0].getSObjectType().getDescribe().getName();
            Boolean isAggregate = objectName == 'AggregateResult';

            // 👇 Get profile-based field order (for normal objects only)
            String userProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
            String fieldOrder = getAllowedFieldsPrompt(objectName, userProfileName, isAggregate);
            List<String> orderedFields = String.isNotBlank(fieldOrder) ? fieldOrder.split(',') : new List<String>();
            // ✅ Ensure 'Id' is always included for link construction
            if (!isAggregate && !orderedFields.contains('Id')) {
                orderedFields.add(0, 'Id');
            }

            // 👇 Get Describe map for labels
            Map<String, Schema.SObjectField> describeMap = getCachedFieldMap(objectName);

            Map<String, String> fieldLabelMap = new Map<String, String>();
            for (String apiName : describeMap.keySet()) {
                fieldLabelMap.put(apiName, describeMap.get(apiName).getDescribe().getLabel());
            }

            List<Map<String, Object>> results = new List<Map<String, Object>>();
            for (sObject rec : records) {
                Map<String, Object> orderedMap = new Map<String, Object>();

                if (!isAggregate) {
                    for (String fieldName : orderedFields) {
                        fieldName = fieldName.trim();

                        try {
                            if (fieldName.contains('.')) {
                                // Handle nested field (e.g., Owner.Name)
                                List<String> parts = fieldName.split('\\.');
                                if (parts.size() == 2) {
                                    SObject relatedObj = rec.getSObject(parts[0]);
                                    Object nestedVal = relatedObj != null ? relatedObj.get(parts[1]) : null;
                                    orderedMap.put(fieldName, nestedVal);
                                }
                            } else {
                                if (!describeMap.containsKey(fieldName)) {
                                    continue;
                                }
                                orderedMap.put(fieldName, rec.get(fieldName));
                            }
                        } catch (Exception ex) {
                            continue;
                        }
                    }
                } else {
                    //orderedMap.putAll((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(rec)));
                    Map<String, Object> rawMap = rec.getPopulatedFieldsAsMap();
                    for (String key : rawMap.keySet()) {
                        orderedMap.put(key, rawMap.get(key));
                    }
                }
                orderedMap.put('attributes', new Map<String, Object>{ 'type' => objectName });
                results.add(orderedMap);
            }

            // ✅ Return both results and field labels now
            Map<String, Object> finalResponse = new Map<String, Object> {
                'records' => results,
                'fieldLabels' => fieldLabelMap,
                'soql' => soqlQuery
            };
           return JSON.serializePretty(finalResponse);
        } catch (QueryException qe) {
            Map<String, Set<String>> inaccessibleFields = qe.getInaccessibleFields();
            if (inaccessibleFields != null && inaccessibleFields.size() > 0) {
                return JSON.serialize(new Map<String, Object>{ 'error' => 'You do not have access to the field(s) - ' + inaccessibleFields.values() + ' , so the results aren’t available to view. If you think you should have access, feel free to reach out to your admin.' }); 
            }
            return JSON.serialize(new Map<String, Object>{ 'error' => 'Invalid query: ' + qe.getMessage() });
        } catch (Exception e) {
            return JSON.serialize(new Map<String, Object>{ 'error' => 'Invalid query: ' + e.getMessage() });
        }
    }

    private static String cleanAIResponse(String aiResponse) {
        // Regex pattern to reliably capture full SOQL query
        Pattern fullQueryPattern = Pattern.compile('(?is)(SELECT.+?FROM.+?)(?=```|$)');
        Matcher fullQueryMatcher = fullQueryPattern.matcher(aiResponse);

        if (fullQueryMatcher.find()) {
            String soqlQuery = fullQueryMatcher.group(1).trim();
            // Clean markdown if exists
            soqlQuery = soqlQuery.replaceAll('```sql', '').replaceAll('```', '').trim();
            if(soqlQuery.contains('UserInfo.getUserId()')) {
                Id userid = UserInfo.getUserId();
                soqlQuery = soqlQuery.replace(':UserInfo.getUserId()', '\'' + userid + '\'');
            }
            return soqlQuery;
        }
        throw new AuraHandledException('AI response did not contain a valid SOQL query.');
    }

    @AuraEnabled
    public static String sendEmailWithSummary(String tableDataJson) {
        if (String.isBlank(tableDataJson)) {
            return 'Error: No data available to send.';
        }
        try {
            String summaryResponseJson = getAISummary(tableDataJson);

            String summary = 'Summary not available';
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(summaryResponseJson);

            if (responseMap.containsKey('message')) {
                summary = (String) responseMap.get('message');
            } else if (responseMap.containsKey('error')) {
                return 'Error: ' + (String) responseMap.get('error');
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { UserInfo.getUserEmail() });
            mail.setSubject('AI Report Summary');

            String htmlSummary = summary.replaceAll('\n', '<br/>');

            mail.setHtmlBody('<p>Hi,</p><p>Here is your Salesforce report summary:</p>' +
                             '<div style="font-family:monospace;">' + htmlSummary + '</div><br/>' +
                             '<p>Regards,<br/>AI Assistant</p>');

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            return 'Success';

        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String logFeedback(String feedbackType, String objectName) {
        if (String.isBlank(feedbackType)) { 
            return 'Skipped'; 
        }
        if (feedbackType.toLowerCase() == 'summary_like') {
            logger.logSummaryLike(objectName);
        } else if (feedbackType.toLowerCase() == 'report_like') {
            logger.logLike(objectName);
        } else if (feedbackType.toLowerCase() == 'summary_dislike') {
            logger.logSummaryDislike(objectName);
        } else if (feedbackType.toLowerCase() == 'report_dislike') {
            logger.logDislike(objectName);
        }

        return 'Logged';
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getObjectKeywordMap() {
        List<Map<String, String>> results = new List<Map<String, String>>();

        for (AIReporting_Object_Config__mdt config : [
            SELECT Object_Api_Name__c, Prompt_Keywords__c
            FROM AIReporting_Object_Config__mdt
        ]) {
            if (String.isBlank(config.Object_Api_Name__c) || String.isBlank(config.Prompt_Keywords__c)) { 
                continue;
            }
            Map<String, String> row = new Map<String, String>();
            row.put('objectName', config.Object_Api_Name__c);
            row.put('keywords', config.Prompt_Keywords__c);

            results.add(row);
        }

        return results;
    }
}