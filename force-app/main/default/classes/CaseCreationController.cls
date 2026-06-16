public with sharing class CaseCreationController {

    private static final String URL_PARAM_ACCOUNT_ID = 'cas4_lkid';
    private static final String URL_PARAM_INCONTACT_ID = HardcodedIdsMapper.getMatchedObjectId('00N80000004jGG9');

    private static final Integer MAX_DEPENDENT_PICKLISTS_ON_PAGE = 10;
    private Integer dependentPicklistCount = 0;

    public Layout layout { get; set; }
    public Case caseObj { get; set; }
    public CaseComment caseCommentObj { get; set; }
    public static String caseTaggingToolPageName {
        get {
            return 'CaseTaggingToolInlinePage';
        }
    }
    public static String recordTypeName { get; set; }
    public static List<CaseLayoutAssignment__c> layoutAssignmentSettings;

    public static List<String> caseTaggingToolFields {
        get {
            List<String> fieldNames = new List<String>();
            for (Schema.SObjectField fildName : CaseTaggingToolInlinePageController.availableFields) {
                fieldNames.add(String.valueOf(fildName));
            }
            return fieldNames;
        }
    }

    private static Boolean ShowClosedStatusesInCaseStatusField 
    {
        get {
            return new CaseSettingsHandler().getShowClosedStatusesInCaseStatusField();
        }
    }

    private static String userProfileName_p;
    public  static String userProfileName {
        get {
            if (userProfileName_p == null) {
                userProfileName_p = [SELECT Id, Name FROM Profile WHERE Id = :userinfo.getProfileId() LIMIT 1].Name;
            }
            return userProfileName_p;
        }
    }

    public SelectOption[] CaseStatuses { get; private set; }

    public CaseCreationController(ApexPages.StandardController stdController) {
        System.PageReference currentPage = ApexPages.currentPage();

        Id recordTypeId = currentPage.getParameters().get('RecordType');
        if(recordTypeId != null) {
            recordTypeName = CaseHelper.RT_INFO_BY_ID.get(recordTypeId).getName();
            populateCaseStatuses(recordTypeId);
        }
        layoutAssignmentSettings = CaseLayoutAssignment__c.getall().values();

        caseObj = (Case) stdController.getRecord();
        caseObj.OwnerId = UserInfo.getUserId();
        caseCommentObj = new CaseComment();
        prepopulateCaseFields(caseObj, currentPage.getParameters());
        layout = buildCustomLayout(getLayout());
    }

    public static PageReference checkAccess() {
        System.PageReference currentPage = ApexPages.currentPage();

        // check record Type Name
        Boolean isAllowedRecordType = false;
        for(CaseLayoutAssignment__c settingRecord : layoutAssignmentSettings) {
            if(settingRecord.RecordType_Name__c == recordTypeName && settingRecord.Profile_Name__c == userProfileName) {
                isAllowedRecordType = true;
            }
        }

        if (!isAllowedRecordType
                || !FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_ALTERNATIVE_CASE_CREATION)) {
            Map <String, String> urlParams = currentPage.getParameters();
            urlParams.remove('save_new');
            urlParams.remove('sfdc.override');
            PageReference standardCaseCreation = new PageReference('/500/e');
            standardCaseCreation.getParameters().putAll(urlParams);
            standardCaseCreation.getParameters().put('nooverride', '1');

            standardCaseCreation.setRedirect(true);
            return standardCaseCreation;
        }
        return null;

    }

    public static Metadata.Layout getLayout() {
        Metadata.Layout layout = new Metadata.Layout();
        if(layoutAssignmentSettings.isEmpty()){
            return layout;
        }
        //Get layout appropriate for current user
        for (CaseLayoutAssignment__c settingRecord : layoutAssignmentSettings) {
            if (settingRecord.Profile_Name__c == userProfileName && settingRecord.RecordType_Name__c == recordTypeName) {
                layout = SFDescribeHelper.getLayoutInfo('Case', settingRecord.Layout_Name__c);
                break;
            }
        }
        return layout;
    }

    public class Layout {
        public List<Section> sections { get; set; }

        public Layout(List<Section> sections) {
            this.sections = sections;
        }
    }

    public class Section {
        public Metadata.LayoutSection sectionMetadata { get; set; }
        public List<Column> columns { get; set; }

        public Section(Metadata.LayoutSection sectionMetadata, List<Column> columns) {
            this.columns = columns;
            this.sectionMetadata = sectionMetadata;
        }
    }

    public class Column {
        public List<Item> items { get; set; }

        public Column(List<Item> items) {
            this.items = items;
        }
    }

    public class Item {
        public Metadata.LayoutItem layoutItem { get; set; }
        public Boolean isEditable { get; set; }
        public Boolean isReadOnly { get; set; }
        public Boolean isRequired { get; set; }
        public Boolean isCaseComment { get; set; }
        public Boolean isCaseStatus {get; private set; }
        public sObject objHolder { get; set; }
        public Boolean isHidden { get; set; }
        public Boolean isDependentPicklist { get; set; }
        public Boolean isAccessible { get; set; }
        public String label { get; set; }

        public Item(Metadata.LayoutItem layoutItem) {
            Boolean isField = layoutItem.field != null;
            Schema.DescribeFieldResult fieldDescribe = null;
            this.isCaseComment = layoutItem.field == 'Comments';
            this.isCaseStatus = (layoutItem.field == Case.Status.getDescribe().getName());
            this.isDependentPicklist = false;
            if (isField) {
                fieldDescribe = this.isCaseComment
                        ? ((SObject) Type.forName('CaseComment').newInstance())
                                .getSObjectType().getDescribe().fields.getMap().get('CommentBody').getDescribe()
                        : ((SObject) Type.forName('Case').newInstance())
                                .getSObjectType().getDescribe().fields.getMap().get(layoutItem.field).getDescribe();

                this.isDependentPicklist = fieldDescribe.isDependentPicklist();
                this.label = fieldDescribe.getLabel();
                this.isAccessible = fieldDescribe.isAccessible();
            }
            this.layoutItem = layoutItem;

            this.isHidden = isField
                    && (!isAccessible
                    || fieldDescribe.isCalculated()
                            || new Set<String>{
                            String.valueOf(Case.SuppliedCompany),
                            String.valueOf(Case.SuppliedEmail),
                            String.valueOf(Case.SuppliedName),
                            String.valueOf(Case.SuppliedPhone),
                            String.valueOf(Case.CreatedById),
                            String.valueOf(Case.LastModifiedById),
                            String.valueOf(Case.CreatedDate),
                            String.valueOf(Case.ClosedDate)
                    }.contains(layoutItem.field));

            Boolean isForceReadOnly = new Set<String>{
                    String.valueOf(Case.OwnerId),
                    String.valueOf(Case.RecordTypeId)
            }.contains(layoutItem.field);
            Boolean isReadOnly = isForceReadOnly ||
                    (layoutItem.behavior == Metadata.UiBehavior.Readonly
                            && UserInfo.getProfileId() != ProfileHelper.PROFILE_ID_SYSADMIN);

            this.isEditable = isField && !isHidden && !isReadOnly;
            this.isReadOnly = isField && !isHidden && isReadOnly;
            this.isRequired = isField && layoutItem.behavior == Metadata.UiBehavior.Required;
        }
    }

    public Layout buildCustomLayout(Metadata.Layout layoutMetadata) {
        List<Section> sections = new List<Section>();

        for (Metadata.LayoutSection sectionMetadata : layoutMetadata.layoutSections) {
            List<Column> columns = new List<Column>();

            for (Metadata.LayoutColumn columnMetadata : sectionMetadata.layoutColumns) {
                List<Item> items = addItems(columnMetadata.layoutItems);

                if (items.size() > 0){
                    columns.add(new Column(items));
                }
            }

            if (columns.size() > 0){
                sections.add(new Section(sectionMetadata, columns));
            }
        }

        return new Layout(sections);
    }

    public PageReference save() {
        try {
            insert caseObj;
            caseCommentObj.ParentId = caseObj.Id;
            insert caseCommentObj;
            return new PageReference('/' + caseObj.Id);
        } catch (Exception ex) {
            return null;
        }
    }

    public List<Item> addItems(List<Metadata.LayoutItem> layoutItems) {
        List<Item> items = new List<Item>();
        if (layoutItems == null){
            return items;
        }

        List<String> ignoredDependentFields = new List<String>();
        Boolean isDependentPicklistOutOfRange = false;

        for (Metadata.LayoutItem itemMetadata : layoutItems) {
            Boolean isAllowedPage = itemMetadata.page_x == caseTaggingToolPageName;
            Boolean isAllowedField = itemMetadata.field != null;

            if (isAllowedField || isAllowedPage) {
                Item newItem = new Item(itemMetadata);

                Boolean isIgnored = false;
                if (!newItem.isHidden && newItem.isDependentPicklist) {
                    dependentPicklistCount++;
                    isDependentPicklistOutOfRange = dependentPicklistCount > MAX_DEPENDENT_PICKLISTS_ON_PAGE;
                    if (isDependentPicklistOutOfRange) {
                        ignoredDependentFields.add(newItem.label);
                        isIgnored = true;
                    }
                }

                if (!newItem.isHidden && !isIgnored){
                    items.add(newItem);
                }
            }
        }

        if (ignoredDependentFields.size() > 0) {
            addIgnoredFieldsMessage(ignoredDependentFields);
        }

        return items;
    }

    public static void addIgnoredFieldsMessage(List<String> ignoredDependentFields) {
        String message = String.format('This page can display a maximum of {0} dependent picklists. ' +
                'The following fields were ignored: {1}',
                new List<String>{
                        String.valueOf(MAX_DEPENDENT_PICKLISTS_ON_PAGE),
                        String.join(ignoredDependentFields, ', ')
                });

        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
    }

    private static void prepopulateCaseFields(Case currentCase, Map<String, String> urlGetParams) {
        for (String paramName : urlGetParams.keyset()) {
            if (paramName == URL_PARAM_ACCOUNT_ID) {
                currentCase.AccountId = urlGetParams.get(paramName);
            } else if (paramName == URL_PARAM_INCONTACT_ID) {
                currentCase.Contact_ID__c = urlGetParams.get(paramName);
            }
        }
    }

    private void populateCaseStatuses(Id recordTypeId) {
        SelectOption[] allCaseStatuses = new CaseStatusesHandler().getCaseStatuses(recordTypeId);

        if (CaseCreationController.ShowClosedStatusesInCaseStatusField) {
            this.CaseStatuses = allCaseStatuses;
        } else {
            this.CaseStatuses = getCaseStatusesWithoutClosed(allCaseStatuses);
        }
    }

    private SelectOption[] getCaseStatusesWithoutClosed(SelectOption[] allCaseStatuses) {
        List<SelectOption> result = new List<SelectOption>();

        CaseStatus[] closeCaseStatuses = [
            SELECT MasterLabel
            FROM CaseStatus
            WHERE IsClosed = true
        ];
        
        for (SelectOption caseStatus : allCaseStatuses) {
            Boolean valid = true;
            for (CaseStatus closedCaseStatus : closeCaseStatuses) {
                if (closedCaseStatus.MasterLabel == caseStatus.getLabel()) {
                    valid = false;
                    break;
                }
            }
            if (valid) { result.add(caseStatus); }
        }
        return result;
    }


    private class CaseSettingsHandler {
        private final String MOCK_RESPONCE = '{"size":1,"totalSize":1,"done":true,"queryLocator":null,' +
            '"entityTypeName":"CaseSettings","records":[{"attributes":{"type":"CaseSettings","url":' +
            '"/services/data/v43.0/tooling/sobjects/CaseSettings/bWRjLzBIRS9DYXNlU2V0dGluZ3M%3D"},' +
            '"CloseCaseThroughStatusChange":false}]}';

        public Boolean getShowClosedStatusesInCaseStatusField() {
            Boolean result = false;
            try {
                HttpRequest req = prepareHttpRequest(UserInfo.getSessionId());
                String json = getJson(req);
                result = getResultFromJson(json);
            }
            catch(Exception ex) {
                System.debug('Failed to get CaseSettings, will use default FALSE value ' + ex);
            }
            return result;
        }

        private HttpRequest prepareHttpRequest(String sessionId) {
            HttpRequest result = new HttpRequest();
            result.setHeader('Authorization', 'Bearer ' + sessionId);
            result.setHeader('Content-Type', 'application/json');
            result.setMethod('GET');
            result.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/data/v43.0/tooling/query/?q=' + 
                'SELECT+CloseCaseThroughStatusChange+FROM+CaseSettings');
            return result;
        }

        private String getJson(HttpRequest req) {
            if (Test.isRunningTest()) {
                return MOCK_RESPONCE;
            }
            Http http = new Http();
            HttpResponse resp = http.send(req);
            return resp.getBody();
        }

        private Boolean getResultFromJson(String jsonResponse) {
            Map<String, Object> root = (Map<String, Object>)Json.deserializeUntyped(jsonResponse);
            if (root.containsKey('done') && root.get('done') == true) {
                if (root.containsKey('records')) {
                    List<Object> entries = (List<Object>)root.get('records');
                    if (entries.size() > 0) {
                        Map<String, Object> entry = (Map<String, Object>)entries[0];
                        if (entry.containsKey('CloseCaseThroughStatusChange')) {
                            return (Boolean)entry.get('CloseCaseThroughStatusChange');
                        }
                    }
                }
            }
            return false;
        }
    }

    private class CaseStatusesHandler {
        private final String MOCK_RESPONSE = '{"controllerValues":{},"defaultValue":{"attributes":null,"label":"New",' +
            '"validFor":[],"value":"New"},"eTag":"3ca63fbdbbe3c4a196160a4549595d2d","url":"/services/data/v43.0/ui-api/' +
            'object-info/Case/picklist-values/01280000000UEY8AAO/Status","values":[{"attributes":null,"label":"Closed",' +
            '"validFor":[],"value":"Closed"},{"attributes":null,"label":"New","validFor":[],"value":"New"},{"attributes"' +
            ':null,"label":"PKI Hold","validFor":[],"value":"PKI Hold"}]}';

        public SelectOption[] getCaseStatuses(Id recordTypeId) {
            SelectOption[] result = null;
            try {
                HttpRequest req = prepareHttpRequest(UserInfo.getSessionId(), recordTypeId);
                String json = getJson(req);
                result = getResultFromJson(json);
            }
            catch(Exception ex) {
                System.debug('Failed to get Case statuses. Will throw an exception due it critical issue' + ex);
                throw ex;
            }
            return result;
        }

        private HttpRequest prepareHttpRequest(String sessionId, Id recordTypeId) {
            HttpRequest result = new HttpRequest();
            result.setHeader('Authorization', 'Bearer ' + sessionId);
            result.setHeader('Content-Type', 'application/json');
            result.setMethod('GET');
            result.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/data/v43.0/ui-api/' + 
                'object-info/Case/picklist-values/' + String.valueOf(recordTypeId) + '/Status');
            return result;
        }

        private String getJson(HttpRequest req) {
            if (Test.isRunningTest()) {
                return MOCK_RESPONSE;
            }
            Http http = new Http();
            HttpResponse resp = http.send(req);
            return resp.getBody();
        }

        private SelectOption[] getResultFromJson(String jsonResponse) {
            List<SelectOption> result = new List<SelectOption>();
            SelectOption defaultOption = null;

            Map<String, Object> root = (Map<String, Object>)Json.deserializeUntyped(jsonResponse);
            
            if (root.containsKey('defaultValue')) {
                Map<String, Object> defaultEntry = (Map<String, Object>)root.get('defaultValue');
                defaultOption = new SelectOption((String)defaultEntry.get('value'), (String)defaultEntry.get('label'));
                result.add(defaultOption);
            }

            if (root.containsKey('values')) {
                List<Object> entries = (List<Object>)root.get('values');
                for (Object entry : entries) {
                    Map<String, Object> option = (Map<String, Object>)entry;
                    if (defaultOption != null && defaultOption.getValue() == (String)option.get('value')) {
                        continue;
                    }
                    result.add(new SelectOption((String)option.get('value'), (String)option.get('label')));
                }
            }
            return result;
        }
    }

}