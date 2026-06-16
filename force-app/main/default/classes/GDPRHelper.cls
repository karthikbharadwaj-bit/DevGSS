public without sharing class GDPRHelper {

    @TestVisible
    public String sObjectName;
    public Integer priority;
    public String whereClause;
    public Integer retentionPeriod;
    public List<String> fieldsToScramble;
    public Boolean isUserDeactivation = false;
    public Integer scopeLimit = 200;
    public Integer csvLogLimit = 20000;
    public Case newCase;

    private Boolean isTestMode;

    @TestVisible
    private String objKeyPostfix {
        get {
            return objKeyPostfix;
        }
        set {
            objKeyPostfix = String.isNotBlank(value)
                ? '.' + value.trim()
                : '';
        }
    }
    public String fullNameWithPrifix {
        get {
            return this.sObjectName + this.objKeyPostfix;
        }
    }

    public Map<Id, SObject> recordsToExport;

    @TestVisible
    private String customWhereClause;

    private Boolean isContact { get {return this.sObjectName.equalsIgnoreCase('contact');} }
    private Boolean isAccount { get {return this.sObjectName.equalsIgnoreCase('account');} }
    private Boolean isLead { get {return this.sObjectName.equalsIgnoreCase('lead');} }
    private Boolean isOpportunity { get {return this.sObjectName.equalsIgnoreCase('opportunity');} }
    private Boolean isUser { get {return this.sObjectName.equalsIgnoreCase('user');} }

    public List<String> fieldsToLog {
        get{
            if (this.isAccount) {
                return new List<String> {
                    'Id', 'RC_User_ID__c','Name'
                };
            } else if (this.isContact) {
                return new List<String> {
                    'Id', 'Name', 'Email'
                };
            } else if (this.isLead) {
                return new List<String> {
                    'Id', 'Name', 'Email', 'Company'
                };
            } else if (this.isOpportunity) {
                return new List<String> {
                    'Id', 'AccountId', 'Account.Name'
                };
            } else if (this.isUser) {
                return new List<String> {
                    'Id', 'Name', 'Email'
                };
            }
            return new List<String> { 'Id' };
        }
    }

    public static final String CSV_FILE_EXTENSION = '.csv';
    public static final String SUBJECT = ' data deletion report';
    public static final String STATUS = 'New';
    public static final String SFDC_DATA_DELETION = 'SFDC Data Deletion';
    public static final String ATTACHMENT_DESCRIPTION = System.Label.SFDC_Data_Deletion_Attachment_Description;
    public static final String CASE_DESCRIPTION = System.Label.SFDC_Data_Deletion_Case_Description;

    @TestVisible
    private static final Map<String, String> objectToWhereClauseMap = new Map<String, String>{
        'Account_Hierarchy__c' => 'id IN (SELECT AH_Name__c FROM Account where RC_Churn_Date__c < LAST_N_MONTHS:{retention}) AND Id NOT IN (SELECT AH_Name__c FROM Account where RC_Churn_Date__c > LAST_N_MONTHS:120 OR RC_Churn_Date__c = null)',
        'ACE__c' => 'Agent_Name__r.IsActive = false AND Agent_Name__r.DeactivationDate__c < LAST_N_MONTHS:{retention}',
        'Agent_Credit__c' => 'Account__r.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Asset__c' => 'OwnerId in (Select Id From User Where DeactivationDate__c < LAST_N_MONTHS:{retention}) and Owner.IsActive = false',
        'BigWins_Form__c' => 'Account_Name__r.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Carrier_Data__c' => 'Account__r.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Coaching_Log__c' => 'Employee_ID__r.Termination_Date__c < LAST_N_MONTHS:{retention}',
        'Contract' => 'Account.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Demand_Funnel__c' => 'Account__r.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Employee__c' => 'Termination_Date__c < LAST_N_MONTHS:{retention}',
        'Hardware_Line_Item__c' => 'RingCentral_Hardware_Phase__r.Opportunity__r.account.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Implementation__c' => 'Account__r.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Jeopardy_History__c' => 'Cases__r.Account.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'JIRA_Case__c' => 'OwnerId IN (SELECT Id FROM User WHERE DeactivationDate__c < LAST_N_MONTHS:{retention}) AND Owner.IsActive = false',
        'Lead_Qualification__c' => 'Account__r.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Legal_Requests_Watchers__c' => 'Advisor_Name__r.IsActive = false AND Advisor_Name__r.DeactivationDate__c < LAST_N_MONTHS:{retention}',
        'Mavenlink_Integrator__c' => 'Account__c IN (SELECT Id FROM Account WHERE RC_User_ID__c != null AND RC_Churn_Date__c < LAST_N_MONTHS:{retention})',
        'Medallia_Survey__c' => 'Account__c IN (SELECT Id FROM Account WHERE RC_Churn_Date__c < LAST_N_MONTHS:{retention})',
        'NDA_Contract__c' => 'Account__r.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Network_Information__c' => 'Account__r.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Partner_Request__c' => 'CreatedDate < LAST_N_MONTHS:{retention}',
        'Quality_Monitoring_Form__c' => 'Agent_Name__r.isActive = false AND Agent_Name__r.DeactivationDate__c < LAST_N_MONTHS:{retention}',
        'RC_Article_Rating__c' => 'RCLastModifiedByName__c != \'scrambled\' AND RCLastModifiedBy__c IN (SELECT Id FROM User WHERE DeactivationDate__c < LAST_N_MONTHS:{retention} AND isActive = false)',
        'RC_Article_Rating__c.CreatedBy' => 'RCCreatedByName__c != \'scrambled\' AND RCCreatedBy__c IN (SELECT Id FROM User WHERE DeactivationDate__c < LAST_N_MONTHS:{retention} AND isActive = false)',
        'RC_User_Article_Rating__c' => 'RC_User_Id__c != null AND OwnerId IN (SELECT Id FROM User WHERE DeactivationDate__c < LAST_N_MONTHS:{retention} AND isActive = false)',
        'Service_Catalog__c' => 'Status__c in (\'Inactive\', \'Retired\') AND LastModifiedDate < LAST_N_MONTHS:{retention}',
        'SLA__c' => 'CreatedDate  < LAST_N_MONTHS:{retention}',
        'Survey__c' => 'Agent__r.IsActive = false AND Agent__r.DeactivationDate__c < LAST_N_MONTHS:{retention}',
        'LiveChatTranscript' => 'CreatedDate < LAST_N_MONTHS:{retention}',
        'LiveChatTranscript.Case' => 'Case.Account.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Contact' => 'Account.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Account_Metric__c' => 'Account_ID__r.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Account_Plan__c' => 'Account__r.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Lead' => 'LastActivityDate < LAST_N_MONTHS:{retention} AND Date_Status_Changed__c < LAST_N_MONTHS:{retention}',
        'Order' => 'Account.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Task' => '',
        'Event' => 'OwnerId in (SELECT Id FROM User WHERE DeactivationDate__c < LAST_N_MONTHS:{retention}) AND Owner.IsActive = false',
        'Approval__c' => 'Account__r.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Tax_Location__c' => '',
        'Opportunity' => 'Account.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Case' => 'Account.RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'Account' => 'RC_Churn_Date__c < LAST_N_MONTHS:{retention}',
        'User' => 'IsActive = false AND DeactivationDate__c < LAST_N_MONTHS:{retention} AND Scrambled__c = false'
    };
    @TestVisible
    private static final String RETENTION_PLACEHOLDER = '{retention}';

    /**
    *   Constructors and initialization method
    */
    public GDPRHelper (
        String sObjName, String objKeyPostfix, Decimal p, Decimal retPeriod,
        List<String> scrambleFields, Decimal scope, Decimal csvlogLimit
    ) {
        this.init(sObjName, objKeyPostfix, p, retPeriod, scrambleFields, scope, csvlogLimit, false);
    }

    public GDPRHelper (GDPR_Requests__c req, boolean testRun) {
        String scrambleFieldsStr = StringHelper.safeString(req.FieldsToScramble1__c)
                                + StringHelper.safeString(req.FieldsToScramble2__c)
                                + StringHelper.safeString(req.FieldsToScramble3__c)
                                + StringHelper.safeString(req.FieldsToScramble4__c)
                                + StringHelper.safeString(req.FieldsToScramble5__c);
        List<String> fToScr = !String.isBlank(scrambleFieldsStr) ? scrambleFieldsStr.replace(' ', '').split(';') : null;

        this.init(
            req.Object_name__c, req.Object_Key_Postfix__c, req.Priority__c, req.RetentionPeriod__c,
            fToScr, req.ScopeLimit__c, req.CsvLogLimit__c, testRun
        );
    }

    private void init (
        String sObjName, String objKeyPostfix, Decimal p, Decimal retPeriod,
        List<String> scrambleFields, Decimal scope, Decimal csvlogLimit, Boolean testRun
    ) {
        this.sObjectName = sObjName;
        this.objKeyPostfix = objKeyPostfix;
        this.priority = p != null ? Integer.valueOf(p) : 0;
        this.retentionPeriod = retPeriod > 60 ? Integer.valueOf(retPeriod) : 60;
        this.whereClause = (
                            objectToWhereClauseMap.get(this.fullNameWithPrifix) != null
                                ? objectToWhereClauseMap.get(this.fullNameWithPrifix)
                                : ''
                            ).replace(RETENTION_PLACEHOLDER, String.valueOf(this.retentionPeriod));
        this.fieldsToScramble = scrambleFields;
        this.scopeLimit = scope > 0 && scope <= 200 ? Integer.valueOf(scope) : 200;
        this.csvLogLimit = csvlogLimit > 0 ? Integer.valueOf(csvlogLimit) : this.csvLogLimit;
        this.recordsToExport = new Map<Id, SObject>();
        this.isTestMode = testRun;
    }

    public Boolean isValid () {
        SObjectDescribeHelper sObjectDescr = SObjectDescribeHelper.getDescribe(this.sObjectName);
        if (String.isBlank(this.sObjectName) || sObjectDescr == null
        || (String.isBlank(this.whereClause) && String.isBlank(this.customWhereClause))) {
            return false;
        }

        if (fieldsToScramble != null) {
            Map<String, Schema.SObjectField> existingFields = sObjectDescr.getFieldsMap();
            for (String fieldName : fieldsToScramble) {
                if (!existingFields.containsKey(fieldName)) {
                    PlatformLog.logResult(
                        'GDPRHelper.isValid',
                        'Invalid field type ' + fieldName + ' for sObject type ' + sObjectName,
                        null, null, null, false
                    );
                    return false;
                }
            }
            if (
                !(sObjectDescr.getSObjectType() == RC_Article_Rating__c.sObjectType)
                && sObjectDescr.getField('Scrambled__c') == null
            ) {
                PlatformLog.logResult(
                    'GDPRHelper.isValid',
                    'Scrambled__c field do not exist on the sObject type ' + sObjectName,
                    null, null, null, false
                );
                return false;
            }
        }

        return true;
    }

    public void setCustomWhere (String customWhere) {
        this.customWhereClause = customWhere;
    }

    private String getQuery (Boolean idOnly) {
        SObjectDescribeHelper sObjectDescr = SObjectDescribeHelper.getDescribe(this.sObjectName);

        String fieldsListToQuery;
        if (idOnly) {
            fieldsListToQuery = ' Id ';
        } else if (this.isUserDeactivation) {
            fieldsListToQuery = ' Id, IsActive, IsPortalEnabled';
        } else if (this.fieldsToScramble != null) {
            fieldsListToQuery = 'Id, ' + String.join(this.fieldsToScramble, ', ');
        } else {
            fieldsListToQuery = ' Id ';
        }
        if (!idOnly && this.fieldsToLog != null) {
            for (String fName : fieldsToLog) {
                if (fName.equalsIgnoreCase('id')) {
                    continue;
                }
                if (this.fieldsToScramble == null || !this.fieldsToScramble.contains(fName)) {
                    fieldsListToQuery += ', ' + fName;
                }
            }
        }
        String query = 'SELECT ' + fieldsListToQuery
                        + ' FROM ' + this.sObjectName;
        query += ' WHERE ' + (!String.isBlank(this.customWhereClause)
                                ? this.customWhereClause
                                : this.whereClause);
        // In order to prevent continious scrambling of the same record for each batch run,
        // the Scrambled__c field must be presented on the object, so such records could be excluded from scope.
        // For RC_Article_Rating__c different logic is used, so Scrambled__c field shouldn't be added to the query
        if (
            !(sObjectDescr.getSObjectType() == RC_Article_Rating__c.sObjectType)
            && (this.fieldsToScramble != null || this.isUser)
            && !this.isUserDeactivation
            && !Test.isRunningTest()
        ) {
            query += ' AND Scrambled__c = false ';
        }

        return query;
    }

    public List<sObject> getRecords () {
        return Database.query(this.getQuery(false));
    }

    public Database.QueryLocator getQueryLocator () {
        return Database.getQueryLocator(this.getQuery(false));
    }


    /**
    *   Processors
    */
    public void processRequest (List<SObject> scope) {
        addRecordsForExport(scope);

        if (this.isTestMode) {
            return;
        }
        if (this.isUserDeactivation) {
            this.processUserDeactivation((List<User>)scope);
        } else if (this.isUser) {
            processUserScramble((List<User>)scope);
        } else if (this.fieldsToScramble != null) {
            this.processScrambling(scope);
        } else {
            this.processDelete(scope);
        }
    }

    private void processUserDeactivation (List<sObject> users) {
        for (User usr: (List<User>)users) {
            usr.isActive = false;
            usr.IsPortalEnabled = false;
        }
        this.logUpdateResult('GDPRHelper.processUserDeactivation', Database.update(users, false));
    }

    private void processUserScramble (List<User> users) {
        List<User> usersToSetScrambled = new List<User>();
        for (User u : users) {
            UserManagement.obfuscateUser(u.Id);
            usersToSetScrambled.add(new User(Id = u.Id, Scrambled__c = true));
        }

        update usersToSetScrambled;
    }

    private void processScrambling (List<sObject> scope) {
        List<sObject> objectsToLog = scope.clone();
        SObjectDescribeHelper sObjectDescr = SObjectDescribeHelper.getDescribe(this.sObjectName);

        Boolean isCurrentObjRcArticleRating = sObjectDescr.getSObjectType() == RC_Article_Rating__c.sObjectType;

        for (sObject sObj : scope) {
            for (String fieldName : this.fieldsToScramble) {
                String valueToScramble = (String)sObj.get(fieldName);
                if (valueToScramble != null) {
                    String scrambledValue = GDPRHelper.isEmailField(fieldName, sObjectDescr.getFieldsMap())
                                            ? StringHelper.getRandomString(valueToScramble.length()) + '@scramble.com'
                                            : isCurrentObjRcArticleRating
                                                ? 'scrambled'
                                                : StringHelper.getRandomString(valueToScramble.length());

                    sObj.put(fieldName, scrambledValue);
                }
            }

            // won`t be Scrambled__c field in test or if working on RC_Article_Rating__c object
            if (!isCurrentObjRcArticleRating && !Test.isRunningTest()) {
                sObj.put('Scrambled__c', true);
            }
        }

        Database.SaveResult[] saveRes = Database.update(scope, false);
        this.logUpdateResult('GDPRHelper.processScrambling', saveRes);
    }

    private void processDelete (List<sObject> scope) {
        this.logDeleteResult('GDPRHelper.processDelete', Database.delete(scope, false));
    }


    /**
    * Logger methods
    */

    public Boolean shouldLogSuccess() {
        return (this.isTestMode || this.isContact || this.isAccount || this.isLead || this.isOpportunity || this.isUser)
                && !this.isUserDeactivation;
    }

    private void removeFailedRecordFromExportMap(Id recordId) {
        if (this.recordsToExport.containsKey(recordId)) {
            this.recordsToExport.remove(recordId);
        }
    }

    public void logUpdateResult (String name, Database.SaveResult[] resultList) {
        PlatformLog__c[] logs = new List<PlatformLog__c>();
        for(Database.SaveResult result : resultList){
            if(!result.success){
                logs.add( getResultLog(name, result.getId(), result.getErrors()) );
            }
        }
        PlatformLog.logResults(logs);
    }

    public void logDeleteResult (String name, Database.DeleteResult[] resultList) {
        PlatformLog__c[] logs = new List<PlatformLog__c>();
        for (Database.DeleteResult result : resultList) {
            if (!result.success) {
                removeFailedRecordFromExportMap(result.getId());
                logs.add( getResultLog(name, result.getId(), result.getErrors()));
            }
        }
        PlatformLog.logResults(logs);
    }

    private void addRecordsForExport(List<SObject> scope) {
        if (shouldLogSuccess()) {
            this.recordsToExport.putAll(scope);
        }
    }

    public String createCSV() {
        return new CsvBuilder().createCSV(this.recordsToExport.values(), this.fieldsToLog);
    }

    public void createCaseWithCSVs() {
        Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name =:SFDC_DATA_DELETION LIMIT 1].Id;
        Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(SFDC_DATA_DELETION).getRecordTypeId();

        if(this.newCase == null) {
            TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
            TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
            this.newCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Case.RecordTypeId => rtId,
                        Case.OwnerId => queueId,
                        Case.Status => STATUS,
                        Case.Subject => this.fullNameWithPrifix + SUBJECT,
                        Case.Description => CASE_DESCRIPTION
                    })
                .create()
                .getRecord();
            TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
            TriggerHandler.BY_PASS_CASE_ON_UPDATE = false;
        }

        Attachment attachment = new Attachment();
        attachment.Name = this.sObjectName + CSV_FILE_EXTENSION;
        attachment.ParentId = this.newCase.Id;
        attachment.Description = ATTACHMENT_DESCRIPTION;
        attachment.Body = Blob.valueOf(createCSV());
        insert attachment;
    }

    public void deleteSimilarCase() {
        String currentSubject = this.fullNameWithPrifix + SUBJECT;
        List<Case> similarCases = [SELECT Id FROM Case WHERE Subject =:currentSubject];
        if (!similarCases.isEmpty()) {
            delete similarCases;
        }
    }

    public void logAsCsv(Boolean isFinalBatchStep) {
        if(this.shouldLogSuccess()) {
            if(isFinalBatchStep) {
                this.createCaseWithCSVs();
            } else if(this.recordsToExport.size() >= this.csvLogLimit) {
                this.createCaseWithCSVs();
                this.recordsToExport.clear();
            }
        }
    }

    /**
    *   Static helper methods
    */
    public static List<GDPRHelper> getRequestsQueue (Boolean testRun) {

        List<GDPRHelper> requests = new List<GDPRHelper>();
        List<GDPR_Requests__c> gdprSettings = getSortedRequests();

        for (GDPR_Requests__c gdprSetting : gdprSettings) {
            GDPRHelper r = new GDPRHelper(gdprSetting, testRun);
            if (!r.isValid()) {
                continue;
            }
            if (r.isContact && !testRun) {
                GDPRHelper userDeactivationRequest = new GDPRHelper('User', null, r.priority, null, null, null, null);
                userDeactivationRequest.isUserDeactivation = true;
                userDeactivationRequest.setCustomWhere(' ContactId IN (' + r.getQuery(true) + ') ');
                requests.add(userDeactivationRequest);
            }
            requests.add(r);
        }

        return requests;
    }

    public static List<GDPR_Requests__c> getSortedRequests () {
        List<GDPR_Requests__c> requestSettings = GDPR_Requests__c.getAll().values();

        for (Integer i = 0; i < requestSettings.size(); i++) {
            for (Integer j = i; j < requestSettings.size(); j++) {
                if (requestSettings[i].Priority__c > requestSettings[j].Priority__c) {
                    GDPR_Requests__c temp = requestSettings[i];
                    requestSettings[i] = requestSettings[j];
                    requestSettings[j] = temp;
                }
            }
        }

        return requestSettings;
    }

    public static PlatformLog__c getResultLog (String name, Id recordId,  Database.Error[] errors) {

        String errorMessage = '';
        for (Database.Error e : errors) {
            errorMessage += e.getMessage() + '\n';
        }

        PlatformLog__c log = PlatformLog.buildLog(name, recordId, errorMessage, null, null);

        return log;
    }

    public static Boolean isEmailField (String fName, Map<String, Schema.SObjectField> existingFields) {
        Schema.SObjectField fieldToken = existingFields.get(fName);
        if (fieldToken == null) {
            return false;
        }
        Schema.DescribeFieldResult fDescribe = fieldToken.getDescribe();

        return fDescribe.getType() == Schema.DisplayType.Email || fName.toLowerCase() == 'username';
    }

}