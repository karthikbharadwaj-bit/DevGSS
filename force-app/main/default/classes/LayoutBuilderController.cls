public class LayoutBuilderController {

    public static String mockHtmlContent = '<html>'+
                    '<head>'+
                    '</head>'+
                    '<body>'+
                        '<select id="j_id0:j_id1:Type__c" name="j_id0:j_id1:Type__c">'+
                            '<option value="">--None--</option>'+
                            '<option value="Amendment">Amendment</option>'+
                            '<option value="Enterprise/Majors Agreement">Enterprise/Majors Agreement</option>'+
                            '<option value="Free Services < 3 months">Free Services < 3 months</option>'+
                        '</select>'+
                    '</body>'+
                '</html>';

    @auraEnabled
    public static String getLayout(){
        Metadata.Layout layout = new  Metadata.Layout();
        String profileName = [SELECT Id, Name FROM Profile WHERE Id =: userinfo.getProfileId() LIMIT 1].Name;

        //Get layout appropriate for current user
        List<CaseLayoutAssignment__c> layoutAssignmentSettings = CaseLayoutAssignment__c.getall().values();
        for(CaseLayoutAssignment__c settingRecord : layoutAssignmentSettings) {
            if (settingRecord.Profile_Name__c == profileName) {
               layout = SFDescribeHelper.getLayoutInfo('Case', settingRecord.Layout_Name__c);
            }
        }
        return JSON.serialize(layout);
    }

    public class CustomOption {
        public String value { get; set; }
        public String label { get; set; }

        public CustomOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    public class CustomDescribeFieldResult {
        public String label { get; set; }
        public String name { get; set; }
        public Boolean createable { get; set; }
        public Boolean namePointing { get; set; }
        public String type { get; set; }
        public List<CustomOption> picklistValues { get; set; }
        public List<String> referenceTo { get; set; }

        public CustomDescribeFieldResult(String label, String name, Boolean createable,
            Boolean namePointing, String type, List<CustomOption> picklistValues, List<String> referenceTo) {

            this.label = label;
            this.name = name;
            this.createable = createable;
            this.namePointing = namePointing;
            this.type = type;
            this.picklistValues = picklistValues;
            this.referenceTo = referenceTo;
        }
    }

    @auraEnabled
    public static String getField(String sObjectName, String fieldName){
        if(fieldName == 'Comments') {
            Schema.DescribeFieldResult fieldDescribe = ((SObject)Type.forName('CaseComment').newInstance()).getSObjectType().getDescribe().fields.getMap().get('CommentBody').getDescribe();
            return JSON.serialize(fieldDescribe);
        } else {
            Schema.DescribeFieldResult fieldDescribe = ((SObject)Type.forName(sObjectName).newInstance()).getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe();

            // if current field type pickList or multipicklist - we need to show values only for specific recordType("Support - T1")
            if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST ||
                fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {

                // get picklist options for specific recordType ("Support - T1")
                List<PicklistController.Picklist> picklists = getPickListValues(sObjectName, fieldName);

                PicklistController.Picklist filteredPickList = picklists != null ? picklists.get(0) : null;

                if(filteredPickList != null) {

                    CustomDescribeFieldResult parsedDescribe = (CustomDescribeFieldResult) JSON.deserialize(
                        JSON.serialize(fieldDescribe), CustomDescribeFieldResult.class
                    );

                    // if it is Case.Status field - filter 'closed' statuses
                    Boolean isCaseStatusField = sObjectName == 'Case' && fieldName == 'Status';

                    // show options only for specific recordType
                    parsedDescribe.picklistValues = filterOptions(parsedDescribe, filteredPickList, isCaseStatusField);
                    return JSON.serialize(parsedDescribe);
                }
            }

            return JSON.serialize(fieldDescribe);
        }
    }

    private static List<PicklistController.Picklist> getPickListValues(String sObjectName, String fieldName) {

        // get picklist options for specific recordType ("Support - T1")
        String picklistPageUrlParams = '?' + 'SObjectType=' + sObjectName +
            '&RecordTypeName=' + 'Support%20-%20T1' +
            '&fields=' + fieldName;

        PageReference pr = new PageReference('/apex/Picklist' + picklistPageUrlParams);

        String htmlContent = '';

        if(Test.isRunningTest()) {
            htmlContent = mockHtmlContent.unescapeHtml4();
        }else{
            htmlContent = pr.getContent().toString().unescapeHtml4();
        }

        return PicklistController.parse(htmlContent,'<select ','<option ');
    }

    private static List<CustomOption> filterOptions(CustomDescribeFieldResult parsedDescribe,
        PicklistController.Picklist filteredPickList, Boolean isCaseStatusField) {

        List<CustomOption> optionsForSpecificRecordType = new List<CustomOption>();

        if(parsedDescribe == null || filteredPickList == null) {
            return optionsForSpecificRecordType;
        }

        if(isCaseStatusField == null) {
            isCaseStatusField = false;
        }

        if(isCaseStatusField) {
            // if it Case.Status  field - filter all 'closed' values
            Set<String> caseClosedStatuses = getCaseClosedStatuses();

            for(CustomOption parsedOption : parsedDescribe.picklistValues) {

                Boolean currentOptionFoundInFiltered = false;

                for(PicklistController.Option filteredOption : filteredPickList.Options) {
                    if(filteredOption.Value == parsedOption.value && !caseClosedStatuses.contains(parsedOption.value)) {
                        currentOptionFoundInFiltered = true;
                    }
                }

                if(currentOptionFoundInFiltered) {
                    optionsForSpecificRecordType.add(parsedOption);
                }
            }
        }else{
            for(CustomOption parsedOption : parsedDescribe.picklistValues) {

                Boolean currentOptionFoundInFiltered = false;

                for(PicklistController.Option filteredOption : filteredPickList.Options) {
                    if(filteredOption.Value == parsedOption.value) {
                        currentOptionFoundInFiltered = true;
                    }
                }

                if(currentOptionFoundInFiltered) {
                    optionsForSpecificRecordType.add(parsedOption);
                }
            }
        }

        return optionsForSpecificRecordType;
    }

    private static Set<String> caseClosedStatuses;
    private static Set<String> getCaseClosedStatuses() {
        Set<String> closedStatusesSet = new Set<String>();

        if(caseClosedStatuses == null || caseClosedStatuses.isEmpty()) {
            for(CaseStatus item : [select Id, ApiName, IsClosed from CaseStatus where IsClosed = true]) {
                closedStatusesSet.add(item.ApiName);
            }
            caseClosedStatuses = closedStatusesSet;
        }

        return caseClosedStatuses;
    }

    @auraEnabled
    public static String getNameField(String sObjectName){
        return JSON.serialize(SFDescribeHelper.getNameField(sObjectName));
    }

    @auraEnabled
    public static Id saveRecord(SObject record) {
        Id recordId = null;
        try {
            upsert record;
            recordId = record.Id;
        } catch (DMLException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
        return recordId;
    }

    @auraEnabled
    public static void createAdditionalRecord(String caseId, String commentBody) {
        CaseComment caseCommentForCase = new CaseComment(ParentId = Id.valueOf(caseId), CommentBody = commentBody );
        insert caseCommentForCase;
    }

    @auraEnabled
    public static String getUserProfile () {
        String profileName = [SELECT Id, Name FROM Profile WHERE Id =: Userinfo.getProfileId() LIMIT 1].Name;
        return profileName;
    }
}