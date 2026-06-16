public with sharing class CreateJiraController {
    
    public enum JiraOperation { CREATE_JIRA, LINK_JIRA }
    
    // Error message constants
    public static final String ERROR_RECORD_TYPE_NOT_ALLOWED = 'Error: Jira action is not allowed for this record type and profile';
    public static final String ERROR_JIRA_CREATE_ENDPOINT_NOT_CONFIGURED = 'Error: Jira create endpoint not configured';
    public static final String ERROR_JIRA_TICKET_EXISTS = 'Error: Jira ticket already exists for this case.';
    public static final String ERROR_ESCALATE_TO_QUEUE_BLANK = 'Error: Can\'t create Jira for this Escalate To Queue - field is blank.';
    public static final String ERROR_NO_PROJECT_MAPPING = 'Error: No Jira project mapping found for queue: {0}';
    public static final String ERROR_MISSING_JIRA_KEY_OR_ID = 'Error: Missing Jira Key or Id in response.';
    public static final String ERROR_JIRA_CREATION_FAILED = 'Error: Jira creation failed with status code {0}';
    public static final String ERROR_JIRA_LINKING_FAILED = 'Error: Jira linking failed with status code {0}';
    public static final String ERROR_INVALID_JIRA_NUMBER = 'Error: Please enter a valid Jira ticket number';
    public static final String ERROR_JIRA_LINK_ENDPOINT_NOT_CONFIGURED = 'Error: Jira link endpoint not configured';
    public static final String ERROR_INVALID_JIRA_RESPONSE = 'Error: Invalid response from Jira. Missing key or URL.';
    public static final String ERROR_GENERIC_EXCEPTION = 'Error: {0}';
    public static final String ERROR_JIRA_KEY_PATTERN = 'Error: Incorrect format. Jira numbers should look like \u2018ABC-456\u2019 or \u2018XYZ789-101\u2019 \u2014 uppercase alphanumeric before the hyphen, and numbers after.';
    
    private static final String NAMED_CRED_JIRA_CREATE = 'callout:Jira_Create';
    private static final String NAMED_CRED_JIRA_LINK = 'callout:Jira_Link';
    private static final String LOG_OBJECT_TYPE = 'Case';

    @AuraEnabled(cacheable=true)
    public static Boolean checkJiraExists(Id caseId) {
        List<SObject> results = new CaseSelector().selectJiraCaseById(caseId).executeQuery();
        if (results.isEmpty()) {
            return false; 
        }
        Case cs = (Case) results[0];
        return cs.Jira_Case__c != null;
    }
    
    
    private static String getCreateDeniedMessage(Id caseId) {
        JiraAccessPermissionService.JiraAccessContext ctx = JiraAccessPermissionService.getAccessContext(caseId);
        if (String.isNotBlank(ctx.deniedCreateMessage)) {
            return ctx.deniedCreateMessage;
        }
        return JiraAccessPermissionService.MSG_OUT_OF_SCOPE_CREATE_LINK;
    }

    private static String getLinkDeniedMessage(Id caseId) {
        JiraAccessPermissionService.JiraAccessContext ctx = JiraAccessPermissionService.getAccessContext(caseId);
        if (String.isNotBlank(ctx.deniedLinkMessage)) {
            return ctx.deniedLinkMessage;
        }
        return JiraAccessPermissionService.MSG_OUT_OF_SCOPE_CREATE_LINK;
    }

    public static Boolean isRecordTypeAllowed(Id caseId, JiraOperation operation) {
        String operationStr = operation == JiraOperation.CREATE_JIRA ? 'Create' : 'Link';
        if (Test.isRunningTest()) {
            List<SObject> results = new CaseSelector().selectJiraCaseById(caseId).executeQuery();
            Case cs = (Case) results[0];
            return TestDataFactory.isRecordTypeAllowed(cs.RecordTypeName__c, operationStr);
        }

           return JiraAccessPermissionService.isOperationAllowed(caseId, operationStr);
    }

   @AuraEnabled(cacheable=true)
    public static JiraAccessContextWrapper getJiraAccessContext(Id caseId) {
        JiraAccessPermissionService.JiraAccessContext accessContext = JiraAccessPermissionService.getAccessContext(caseId);
        return new JiraAccessContextWrapper(accessContext);
    }
    
    @AuraEnabled
    public static String createJira(Id caseId) {  
        String result;
        Exception caughtException;
        try {
            if (!isRecordTypeAllowed(caseId, JiraOperation.CREATE_JIRA)) {
                return 'Error: ' + getCreateDeniedMessage(caseId);
            }
            
            List<SObject> caseResults = new CaseSelector()
                .selectCreateJiraCaseById(caseId)
                .executeQuery();
            if (caseResults.isEmpty()) {
                return String.format(ERROR_GENERIC_EXCEPTION, new List<String>{'Case not found'});
            }
            
            Case cs = (Case) caseResults[0];
                       
            if (cs.Jira_Case__c != null || cs.Jira__c != null) {
                return ERROR_JIRA_TICKET_EXISTS;
            }
            
            if (String.isBlank(cs.Support_Escalate_To__c)) {
                return ERROR_ESCALATE_TO_QUEUE_BLANK;
            }
            
            List<Jira_Queue_Mapping__mdt> queueMappings = [
                SELECT Jira_Project_Mapping__c
                FROM Jira_Queue_Mapping__mdt 
                WHERE Label = :cs.Support_Escalate_To__c
                LIMIT 1
            ];
            
            if (queueMappings.isEmpty()) {
                return String.format(ERROR_NO_PROJECT_MAPPING, new List<String>{cs.Support_Escalate_To__c});
            }
            
            String jiraProjectKey = queueMappings[0].Jira_Project_Mapping__c;
            String jsonData = JiraJsonBuilder.build(cs, jiraProjectKey);
            
            HttpRequest request = HttpHelper.prepareHttpRequest(
                NAMED_CRED_JIRA_CREATE,
                HttpHelper.METHOD_POST,
                jsonData
            );
            request.setTimeout(HttpHelper.MAX_TIMEOUT_MS);

            HttpResponse response = new Http().send(request);

            if (!HttpHelper.isSuccess(response)) {
                return String.format(ERROR_JIRA_CREATION_FAILED, new List<String>{String.valueOf(response.getStatusCode())});
            }
            
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            if (responseBody.containsKey('Notice') && responseBody.get('Notice') == 'Error Occured') {
                return String.format(ERROR_GENERIC_EXCEPTION, new List<String>{(String) responseBody.get('Message')});
            }

            String jiraKey = (String) responseBody.get('key');
            String jiraUrl = (String) responseBody.get('self');
            String jiraId = (String) responseBody.get('id');
            
            if (String.isBlank(jiraKey) || String.isBlank(jiraId)) {
                return ERROR_MISSING_JIRA_KEY_OR_ID;
            }
            
            result = handleJiraCaseRecordCreation(caseId, jiraKey, jiraUrl, jiraId);
            return result;
            
        } catch (Exception e) {
            caughtException = e;
            result = String.format(ERROR_GENERIC_EXCEPTION, new List<String>{e.getMessage()});
            return result;
        } finally {
            if (caughtException != null) {
                logToExceptionHistory(caughtException, caseId, 'createJira');
            }
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean isJiraLinked(Id caseId) {
        try {
             List<SObject> results = new CaseSelector()
                .selectJiraCaseById(caseId)
                .executeQuery();
            if (results.isEmpty()) {
                return false;
            }
            Case cs = (Case) results[0];
            return cs.Jira_Case__c != null || cs.Jira__c != null;
        } catch (Exception e) {
            return false;
        }
    }

    // Regex pattern:
    private static Boolean isValidJiraNumberFormat(String jiraNumber) {
        if (String.isBlank(jiraNumber)) {
            return false;
        }
        
        Pattern jiraPattern = Pattern.compile('^[A-Z][A-Z0-9]*-\\d+$');
        Matcher matcher = jiraPattern.matcher(jiraNumber);
        
        return matcher.matches();
    }
    
    @AuraEnabled
    public static String linkJira(Id caseId, String jiraNumber) {
        String result;
        Exception caughtException;
        try {
            if (!isRecordTypeAllowed(caseId, JiraOperation.LINK_JIRA)) {
                return 'Error: ' + getLinkDeniedMessage(caseId);
            }
                        
            if (String.isBlank(jiraNumber)) {
                return ERROR_INVALID_JIRA_NUMBER;
            }
            
            if (!isValidJiraNumberFormat(jiraNumber)) {
                return ERROR_JIRA_KEY_PATTERN;
            }
            
            
            String jsonData = JiraJsonBuilder.buildForLinking(caseId, jiraNumber);
            
            HttpRequest request = HttpHelper.prepareHttpRequest(
                NAMED_CRED_JIRA_LINK,
                HttpHelper.METHOD_POST,
                jsonData
            );
            request.setTimeout(HttpHelper.MAX_TIMEOUT_MS);

            HttpResponse response = new Http().send(request);

            if (!HttpHelper.isSuccess(response)) {
                return String.format(ERROR_JIRA_LINKING_FAILED, new List<String>{String.valueOf(response.getStatusCode())});
            }
            
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            if (responseBody.containsKey('Notice') && responseBody.get('Notice') == 'Error Occured') {
                return String.format(ERROR_GENERIC_EXCEPTION, new List<String>{(String) responseBody.get('Message')});
            }

            String jiraKey = (String) responseBody.get('Key');
            String jiraUrl = (String) responseBody.get('self');
            String jiraId = (String) responseBody.get('id');
            
            if (String.isBlank(jiraKey) || String.isBlank(jiraUrl) || String.isBlank(jiraId)) {
                return ERROR_INVALID_JIRA_RESPONSE;
            }
            
            Case caseToUpdate = new Case(
                Id = caseId,
                Jira_Case__c = null,
                Jira__c = jiraKey,
                Jira_Link__c = jiraUrl
            );
            Database.update(caseToUpdate);
            
            result = 'Success: ' + jiraKey + '|' + jiraUrl;
            return result;
            
        } catch (Exception e) {
            caughtException = e;
            result = String.format(ERROR_GENERIC_EXCEPTION, new List<String>{e.getMessage() + ' at line ' + e.getLineNumber()});
            return result;
        } finally {
            if (caughtException != null) {
                logToExceptionHistory(caughtException, caseId, 'linkJira');
            }
        }
    }
    
    private static String handleJiraCaseRecordCreation(Id caseId, String jiraKey, String jiraUrl, String jiraId) {
        try {
            Jira_Case__c jiraCase = new Jira_Case__c(
                Name = jiraKey,
                Issue_Id__c = jiraId,
                Issue_Key__c = jiraKey
            );
            insert jiraCase;
            
            Case caseToUpdate = new Case(
                Id = caseId,
                Jira_Case__c = jiraCase.Id,
                Jira__c = jiraKey,
                Jira_Link__c = jiraUrl
            );
            
            Database.update(caseToUpdate);
            
            return 'Success: ' + jiraKey + '|' + jiraUrl;
        } catch (Exception e) {
            return String.format(ERROR_GENERIC_EXCEPTION, new List<String>{e.getMessage()});
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<JiraCommentWrapper> getJiraComments(Id caseId) {
       JiraAccessPermissionService.JiraAccessContext accessContext = JiraAccessPermissionService.getAccessContext(caseId);
       if (!Test.isRunningTest() && (!accessContext.canViewComments || !accessContext.hasLinkedJiraDetail)) {
            return new List<JiraCommentWrapper>();
       }

       List<SObject> caseResults = new CaseSelector()
            .selectJiraCaseById(caseId)
            .executeQuery();
        if (caseResults.isEmpty()) {
            return new List<JiraCommentWrapper>();
        }
        Case cs = (Case) caseResults[0];
        
        if (cs.Jira_Case__c == null) {
            return new List<JiraCommentWrapper>();
        }
        
        List<Jira_Case_Comment__c> comments = [
            SELECT Id, Name, Comment__c, CreatedDate, CreatedBy.Name, Jira_Case__c
            FROM Jira_Case_Comment__c 
            WHERE Jira_Case__c = :cs.Jira_Case__c 
            ORDER BY CreatedDate DESC
        ];
        
        List<JiraCommentWrapper> wrappedComments = new List<JiraCommentWrapper>();
        for (Jira_Case_Comment__c comment : comments) {
            wrappedComments.add(new JiraCommentWrapper(comment, cs.Jira_Case__c));
        }
        return wrappedComments;
    }
    
    private static void logToExceptionHistory(Exception ex, Id recordId, String methodName) {
        try {
            Exception_and_Notification_history__c logRecord = new Exception_and_Notification_history__c(
                Exception__c = ex.getTypeName(),
                Exception_Desc__c = 'CreateJiraController.' + methodName + ': ' + ex.getMessage(),
                Object_Type__c = LOG_OBJECT_TYPE,
                Record_Id__c = recordId != null ? String.valueOf(recordId) : '',
                Line_Number__c = ex.getLineNumber(),
                stackTraceString__c = ex.getStackTraceString()
            );
            Database.insert(logRecord, false);
        } catch (Exception logEx) {
            System.debug(LoggingLevel.ERROR, 'Failed to log exception to history: ' + logEx.getMessage());
        }
    }
    
    public class JiraAccessContextWrapper {
        @AuraEnabled public Boolean canCreate;
        @AuraEnabled public Boolean canLink;
        @AuraEnabled public Boolean canViewComments;
        @AuraEnabled public Boolean hasLinkedJiraDetail;
        @AuraEnabled public Boolean isProfileRecordTypeInScope;
        @AuraEnabled public String message;
        @AuraEnabled public String profileName;
        @AuraEnabled public String recordTypeName;

        @AuraEnabled public String deniedCreateMessage;
        @AuraEnabled public String deniedLinkMessage;
        @AuraEnabled public String commentsAccessMessage;

        public JiraAccessContextWrapper(JiraAccessPermissionService.JiraAccessContext accessContext) {
            this.canCreate = accessContext != null ? accessContext.canCreate : false;
            this.canLink = accessContext != null ? accessContext.canLink : false;
            this.canViewComments = accessContext != null ? accessContext.canViewComments : false;
            this.hasLinkedJiraDetail = accessContext != null ? accessContext.hasLinkedJiraDetail : false;
            this.isProfileRecordTypeInScope = accessContext != null ? accessContext.isProfileRecordTypeInScope : false;
            this.message = accessContext != null ? accessContext.message : '';
            this.profileName = accessContext != null ? accessContext.profileName : '';
            this.recordTypeName = accessContext != null ? accessContext.recordTypeName : '';
            this.deniedCreateMessage = accessContext != null ? accessContext.deniedCreateMessage : '';
            this.deniedLinkMessage = accessContext != null ? accessContext.deniedLinkMessage : '';
            this.commentsAccessMessage = accessContext != null ? accessContext.commentsAccessMessage : '';
        }
    }

    public class JiraCommentWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String body;
        @AuraEnabled public String author;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String formattedDate;
        @AuraEnabled public String jiraCaseId;
        
        public JiraCommentWrapper(Jira_Case_Comment__c comment, Id jiraCaseId) {
            this.id = comment.Id;
            this.name = comment.Name;
            this.body = comment.Comment__c;
            this.author = comment.CreatedBy.Name;
            this.createdDate = comment.CreatedDate;
            this.formattedDate = comment.CreatedDate.format('MMM d, yyyy h:mm a');
            this.jiraCaseId = jiraCaseId;
        }
    }
}