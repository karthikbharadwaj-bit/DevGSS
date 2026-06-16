public class FieldMappingEngine {

    @TestVisible
    private static final String MAPPING_PICKLIST = 'PICKLIST';
    @TestVisible
    private static final String MAPPING_DATETIME = 'DATETIME';
    @TestVisible
    private static final String MAPPING_CURRENCY = 'CURRENCY';
    @TestVisible
    private static final String MAPPING_NUMBER = 'DOUBLE';
    @TestVisible
    private static final String MAPPING_ID = 'ID';
    @TestVisible
    private static final String MAPPING_EMAIL = 'EMAIL';
    @TestVisible
    private static final String MAPPING_REFERENCE = 'REFERENCE';
    @TestVisible
    private static final String MAPPING_STRING = 'STRING';
    @TestVisible
    private static final String MAPPING_BOOLEAN = 'BOOLEAN';
    @TestVisible
    private static final String MAPPING_TEXTAREA = 'TEXTAREA';
    @TestVisible
    private static final String MAPPING_PHONE = 'PHONE';
    @TestVisible
    private static final String BOOLEAN_TRUE = 'true';
    @TestVisible
    private static final String BOOLEAN_FALSE = 'false';
    @TestVisible
    private static final String STRING_ALL = 'ALL';
    private static final String FIELD_RECORDTYPEID = 'recordtypeid';
    private static final String MAPPING_FIELD_TO_FIELD = 'FIELD TO FIELD';
    private static final String DOT_STRING_TO_SPLIT = '\\.';
    private static final String DOT_STRING_TO_CONTAINS = '.';
    private static final String SEMICOLON_STR = ';';

    /*
     * A String used to specify a process name to filter field mapping records result.
     */
    @TestVisible
    private String process;
    /*
     * A String used to specify a profile name to filter field mapping records result.
     */
    @TestVisible
    private String profileName;
    /*
     * A String used to specify a record type name to filter field mapping records result.
     */
    @TestVisible
    private String recordTypeName;
    /*
     * A String used to specify a record type DeveloperName to filter field mapping records result.
     */
    @TestVisible
    private String recordTypeDeveloperName;
    /*
     * Object used as input to field mapping.
     */
    @TestVisible
    private SObject sourceObject;
    /*
     * ObjectType of SObject used as input to field mapping.
     */
    @TestVisible
    private SObjectType sourceObjectType;
    /*
     * Object used as destination of field mapping.
     */
    @TestVisible
    private SObject targetObject;
    /*
     * ObjectType of SObject used as destination of field mapping.
     */
    @TestVisible
    private SObjectType targetObjectType;
    /*
     * A Map used to store valid field mapping records.
     */
    @TestVisible
    private Map<String, Fields_Mapping__mdt> validFieldMappings;
    /*
     * A Map used to store field describes.
     */
    @TestVisible
    private static Map<String, DescribeFieldResult> fieldDescribeMap = new Map<String, DescribeFieldResult>();
    /*
     * Constructs the Field Mapping Engine with profileName and Recordtype.
     */
    public FieldMappingEngine(String process, SObject sourceObject, SObject targetObject, String profileName) {
        this.SetFieldMappingEngineData(process, sourceObject, targetObject, profileName, true);
    }
    /*
     * Constructs the Field Mapping Engine without profileName and without recordtype.
     */
    public FieldMappingEngine(String process, SObject sourceObject, SObject targetObject) {
        this.SetFieldMappingEngineData(process, sourceObject, targetObject, STRING_ALL, false);
    }
    /*
     * Constructs the Field Mapping Engine with profileName and decide if process recordtype values.
     */
    public FieldMappingEngine(
        String process,
        SObject sourceObject,
        SObject targetObject,
        String profileName,
        Boolean isRecordTypeProcessing
    ) {
        this.SetFieldMappingEngineData(process, sourceObject, targetObject, profileName, isRecordTypeProcessing);
    }
    /*
     * Method to set intertal data for Mapping Engine.
     */
    @TestVisible
    private void SetFieldMappingEngineData(
        String process,
        SObject sourceObject,
        SObject targetObject,
        String profileName,
        Boolean isRecordTypeProcessing
    ) {
        this.process = process;
        this.profileName = profileName;
        this.recordTypeDeveloperName = isRecordTypeProcessing ? getRecordTypeDeveloperName(targetObject) : STRING_ALL;
        this.recordTypeName = isRecordTypeProcessing ? getRecordTypeName(targetObject) : STRING_ALL;
        this.sourceObject = sourceObject;
        this.sourceObjectType = sourceObject.getSObjectType();
        this.targetObject = targetObject;
        this.targetObjectType = targetObject.getSObjectType();
        this.validFieldMappings = getValidFieldsMapping();
    }
    /*
     * Method to get Record Type Name for anObject.
     */
    @TestVisible
    private static String getRecordTypeName(SObject anObject) {
        String result = STRING_ALL;
        if (FieldMappingEngine.hasRecordType(anObject)) {
            result = anObject.getSObjectType()
                .getDescribe()
                .getRecordTypeInfosById()
                .get((Id) anObject.get(FIELD_RECORDTYPEID))
                .getName();
        }
        return result;
    }
    /*
     * Method to get Record Type DeveloperName for anObject.
     */
    @TestVisible
    private static String getRecordTypeDeveloperName(SObject anObject) {
        String result = STRING_ALL;
        if (FieldMappingEngine.hasRecordType(anObject)) {
            result = anObject.getSObjectType()
                .getDescribe()
                .getRecordTypeInfosById()
                .get((Id) anObject.get(FIELD_RECORDTYPEID))
                .getDeveloperName();
        }
        return result;
    }
    /*
     * Method to validate if anObject has RecordTypeId field.
     */
    @TestVisible
    private static Boolean hasRecordType(SObject anObject) {
        Boolean result = false;
        Map<Id, Schema.RecordTypeInfo> recTypes = anObject.getSObjectType().getDescribe().getRecordTypeInfosById();
        SObjectField field = anObject.getSObjectType().getDescribe().fields.getMap().get(FIELD_RECORDTYPEID);
        if (!recTypes.isEmpty() && field != null && (Id) anObject.get(FIELD_RECORDTYPEID) != null) {
            result = anObject.getSObjectType().getDescribe().fields.getMap().containsKey(FIELD_RECORDTYPEID);
        }
        return result;
    }
    /*
     * Method to query Fields Mapping records.
     */
    @TestVisible
    private Map<String, Fields_Mapping__mdt> getFieldsMapping() {
        Map<String, Fields_Mapping__mdt> result = new Map<String, Fields_Mapping__mdt>();

        List<Fields_Mapping__mdt> fms = Fields_Mapping__mdt.getAll().values();
        List<Fields_Mapping__mdt> filteredMappings = new List<Fields_Mapping__mdt>();
        for (Fields_Mapping__mdt fm: fms) {
            Boolean isProcessNameMatch = false;
            Boolean isProfileNameMatch = false;
            Boolean isRecordTypeMatch = false;

            if (fm.Process__c.equals(this.process)) {
                isProcessNameMatch = true;
            }

            if (fm.Profile__c.contains(STRING_ALL)
                || fm.Profile__c.contains(this.profileName)) {
                isProfileNameMatch = true;
            }

            if (fm.RecordType__c.contains(STRING_ALL)
                || fm.RecordType__c.contains(this.recordTypeName)
                || fm.RecordType__c.contains(this.recordTypeDeveloperName)) {
                isRecordTypeMatch = true;
            }

            if (isProcessNameMatch && isProfileNameMatch && isRecordTypeMatch) {
                filteredMappings.add(fm);
            }
        }


        for (Fields_Mapping__mdt fieldMapping : filteredMappings) {
            if (!fieldMapping.isTestRecord__c || Test.isRunningTest()) {
                result.put(fieldMapping.Target_Field__c, fieldMapping);
            }
        }
        return result;
    }
    /*
     * Method to get a valid Fields Mapping records.
     */
    public Map<String, Fields_Mapping__mdt> getValidFieldsMapping() {
        Map<String, Fields_Mapping__mdt> result = new Map<String, Fields_Mapping__mdt>();
        Map<String, Fields_Mapping__mdt> fieldMappings = getFieldsMapping();

        for (Fields_Mapping__mdt fieldMapping : fieldMappings.values()) {
            if (validateFieldsMappingRecord(fieldMapping)) {
                if (!result.containsKey(fieldMapping.Target_Field__c)) {
                    result.put(fieldMapping.Target_Field__c, fieldMapping);
                } else if (fieldMapping.Profile__c != STRING_ALL || fieldMapping.RecordType__c != STRING_ALL) {
                    result.put(fieldMapping.Target_Field__c, fieldMapping);
                }
            }
        }
        return result;
    }
    /*
     * Method to validate Fields Mapping records.
     */
    @TestVisible
    private Boolean validateFieldsMappingRecord(Fields_Mapping__mdt fieldMapping) {
        String typeOfMapping = fieldMapping.Type_of_Mapping__c;
        switch on typeOfMapping {
            when 'FIELD TO FIELD' {
                return validateFieldtoFieldMappingRecord(fieldMapping);
            }
            when 'STRING TO FIELD' {
                return validateStringtoFieldMappingRecord(fieldMapping);
            }
            when 'TODAYS DATE TO DATETIME' {
                return validateTodaysDateToFieldMappingRecord(fieldMapping);
            }
            when 'BOOLEAN TO FIELD' {
                return validateBooleantoFieldMappingRecord(fieldMapping);
            }
            when 'STRING TO CURRENCY/NUMBER' {
                return validateStringToNumberMappingRecord(fieldMapping);
            }
            when else {
                return false;
            }
        }
    }

    /*
     * Method to validate Fields Mapping records with StringToCurrency type of mapping.
     */
    @TestVisible
    private Boolean validateStringToNumberMappingRecord(Fields_Mapping__mdt fieldMapping) {
        Boolean result = false;
        DescribeFieldResult fieldDescribe = getField(fieldMapping.Target_Field__c, targetObjectType);
        DisplayType targetFldType = getFieldType(fieldDescribe);
        String sourceValue = String.valueOf(this.sourceObject.get(getFieldString(fieldMapping.Source__c)));

        if (targetFldType != null
            && (targetFldType.name() == MAPPING_CURRENCY || targetFldType.name() == MAPPING_NUMBER)
            && String.isNotBlank(sourceValue)
        ) {
            if (sourceValue.contains('.') && sourceValue.indexOf('.') + 1 < sourceValue.length() - fieldDescribe.getScale()) {
                sourceValue = sourceValue.left(sourceValue.indexOf('.') + fieldDescribe.getScale() + 1);
            }

            String regex = (fieldDescribe.getScale() > 0) ?
                '^(\\d{1,' + (fieldDescribe.getPrecision() - fieldDescribe.getScale()) + '}(\\.\\d{1,'+ fieldDescribe.getScale() +'})?)$' :
                '^(\\d{1,' + (fieldDescribe.getPrecision()) + '})$';

            result = Pattern.matches(regex, sourceValue);
        }

        return result;
    }
    /*
     * Method to validate Fields Mapping records with TodaysDateToField type of mapping.
     */
    @TestVisible
    private Boolean validateTodaysDateToFieldMappingRecord(Fields_Mapping__mdt fieldMapping) {
        Boolean result = false;
        DisplayType targetFldType = getFieldType((getField(fieldMapping.Target_Field__c, targetObjectType)));

        if (targetFldType != null) {
            result = targetFldType.name() == MAPPING_DATETIME;
        }
        return result;
    }
    /*
     * Method to validate Fields Mapping records with BooleanToField type of mapping.
     */
    @TestVisible
    private Boolean validateBooleantoFieldMappingRecord(Fields_Mapping__mdt fieldMapping) {
        Boolean result = false;
        DisplayType targetFldType = getFieldType(getField(fieldMapping.Target_Field__c, targetObjectType));
        String sourceString = fieldMapping.Source__c;

        if (targetFldType != null && sourceString != null) {
            result =
                targetFldType.name() == MAPPING_BOOLEAN &&
                (sourceString == BOOLEAN_FALSE ||
                sourceString == BOOLEAN_TRUE);
        }
        return result;
    }
    /*
     * Method to validate Fields Mapping records with StringtoField type of mapping.
     */
    @TestVisible
    private Boolean validateStringtoFieldMappingRecord(Fields_Mapping__mdt fieldMapping) {
        Boolean result = false;
        DescribeFieldResult field = getField(fieldMapping.Target_Field__c, targetObjectType);
        DisplayType targetFldType = getFieldType(field);
        Integer targetFldLength = getFieldLength(field);

        if (targetFldType != null && targetFldLength != null) {
            result = targetFldType.name() == MAPPING_STRING && targetFldLength >= fieldMapping.Source__c.length();
        }
        return result;
    }
    /*
     * Method to validate Fields Mapping records with FieldtoField type of mapping.
     */
    @TestVisible
    private Boolean validateFieldtoFieldMappingRecord(Fields_Mapping__mdt fieldMapping) {
        Boolean result = false;
        DescribeFieldResult sourceField = getField(fieldMapping.Source__c, sourceObjectType);
        DescribeFieldResult targetField = getField(fieldMapping.Target_Field__c, targetObjectType);
        DisplayType sourceFldType = getFieldType(sourceField);
        DisplayType targetFldType = getFieldType(targetField);
        Integer targetFldLength = getFieldLength(targetField);
        Integer sourceFldLength = getFieldLength(sourceField);
        if (sourceFldType != null && targetFldType != null && targetFldLength != null) {
            String sourceValue = String.valueOf(this.sourceObject.get(getFieldString(fieldMapping.Source__c)));
            Boolean isMappingEmailToString =
                sourceFldType.name() == MAPPING_EMAIL &&
                targetFldType.name() == MAPPING_STRING;
            Boolean isMappingPicklistToString =
                sourceFldType.name().contains(MAPPING_PICKLIST) && targetFldType.name() == MAPPING_STRING;
            Boolean isMappingIdToReference =
                sourceFldType.name() == MAPPING_ID &&
                targetFldType.name() == MAPPING_REFERENCE;
            Boolean isMappingTextToTextArea =
                sourceFldType.name() == MAPPING_STRING &&
                targetFldType.name() == MAPPING_TEXTAREA;
            Boolean isMappingIdToString = sourceFldType.name() == MAPPING_ID && targetFldType.name() == MAPPING_STRING;
            Boolean isMappingTextToPhone =
                sourceFldType.name() == MAPPING_STRING &&
                targetFldType.name() == MAPPING_PHONE &&
                sourceValue != null &&
                Pattern.matches('^[+]*[0-9\\s(),./\\-]+', sourceValue);

            if (
                fieldMapping.No_mapping_null_values__c &&
                this.sourceObject.get(getFieldString(fieldMapping.Source__c)) == null
            ) {
                return false;
            }

            result =
                (sourceFldType == targetFldType ||
                isMappingIdToReference ||
                isMappingIdToString ||
                isMappingEmailToString ||
                isMappingPicklistToString ||
                isMappingTextToTextArea ||
                isMappingTextToPhone) &&
                (targetFldLength >= sourceFldLength ||
                targetFldLength >= (sourceValue != null ? sourceValue.length() : 0));
        }
        return result;
    }
    /*
     * Method to get SObjectType of object in fieldApiName.
     */
    @TestVisible
    private static SObjectType getObjectType(String fieldApiName) {
        return ((SObject)Type.forName(getObjectString(fieldApiName)).newInstance()).getSObjectType();
    }
    /*
     * Method to get SObjectField of field in fieldApiName.
     */
    @TestVisible
    private static DescribeFieldResult getField(String fieldApiName, SObjectType objType) {
        if (!fieldDescribeMap.keySet().contains(fieldApiName) && objType != null) {
            SObjectField field = objType.getDescribe().fields.getMap().get(getFieldString(fieldApiName));
            if (field != null) {
                fieldDescribeMap.put(fieldApiName, field.getDescribe());
            }
        }
        return fieldDescribeMap.get(fieldApiName);
    }
    /*
     * Method to get DisplayType of field in fieldApiName.
     */
    @TestVisible
    private static DisplayType getFieldType(DescribeFieldResult field) {
        return field != null ? field.getType() : null;
    }
    /*
     * Method to get Length of field in fieldApiName.
     */
    @TestVisible
    private static Integer getFieldLength(DescribeFieldResult field) {
        return field != null ? field.getLength() : 0;
    }
    /*
     * Method to process FieldsMappings records.
     */
    public void processFieldsMappings() {
        for (Fields_Mapping__mdt fieldMapping : validFieldMappings.values()) {
            processFieldsMappings(fieldMapping);
        }
    }
    /*
     * Method to process each FieldsMappings record.
     */
    @TestVisible
    private void processFieldsMappings(Fields_Mapping__mdt fieldMapping) {
        switch on fieldMapping.Type_of_Mapping__c {
            when 'FIELD TO FIELD' {
                processFieldtoFieldMappingRecord(fieldMapping);
            }
            when 'STRING TO FIELD' {
                processStringtoFieldMappingRecord(fieldMapping);
            }
            when 'TODAYS DATE TO DATETIME' {
                processTodaysDateToDateTimeMappingRecord(fieldMapping);
            }
            when 'BOOLEAN TO FIELD' {
                processBooleanToFieldMappingRecord(fieldMapping);
            }
            when 'STRING TO CURRENCY/NUMBER' {
                processNumberToFieldMappingRecord(fieldMapping);
            }
        }
    }
    /*
     * Method to process Fields Mapping records with BooleanToField type of mapping.
     */
    @TestVisible
    private void processNumberToFieldMappingRecord(Fields_Mapping__mdt fieldMapping) {
        this.targetObject.put(
            getFieldString(fieldMapping.Target_Field__c),
            Decimal.valueOf((String) this.sourceObject.get(getFieldString(fieldMapping.Source__c)))
        );
    }
    /*
     * Method to process Fields Mapping records with BooleanToField type of mapping.
     */
    @TestVisible
    private void processBooleanToFieldMappingRecord(Fields_Mapping__mdt fieldMapping) {
        Boolean sourceBoolean = fieldMapping.Source__c == BOOLEAN_TRUE;
        this.targetObject.put(getFieldString(fieldMapping.Target_Field__c), sourceBoolean);
    }
    /*
     * Method to process Fields Mapping records with TODAYS DATE TO DATETIME type of mapping.
     */
    @TestVisible
    private void processTodaysDateToDateTimeMappingRecord(Fields_Mapping__mdt fieldMapping) {
        this.targetObject.put(getFieldString(fieldMapping.Target_Field__c), Datetime.now());
    }
    /*
     * Method to process Fields Mapping records with StringtoField type of mapping.
     */
    @TestVisible
    private void processStringtoFieldMappingRecord(Fields_Mapping__mdt fieldMapping) {
        this.targetObject.put(getFieldString(fieldMapping.Target_Field__c), fieldMapping.Source__c);
    }
    /*
     * Method to process Fields Mapping records with FieldtoField type of mapping.
     */
    @TestVisible
    private void processFieldtoFieldMappingRecord(Fields_Mapping__mdt fieldMapping) {
        this.targetObject.put(
            getFieldString(fieldMapping.Target_Field__c),
            this.sourceObject.get(getFieldString(fieldMapping.Source__c))
        );
    }
    /*
     * Method to get Field String of fieldApiName.
     */
    @TestVisible
    private static String getFieldString(String fieldApiName) {
        String result;
        if (fieldApiName.contains(DOT_STRING_TO_CONTAINS)) {
            result = fieldApiName.split(DOT_STRING_TO_SPLIT)[1].toLowerCase();
        }
        return result;
    }
    /*
     * Method to get Object String of fieldApiName.
     */
    @TestVisible
    private static String getObjectString(String fieldApiName) {
        String result;
        if (fieldApiName.contains(DOT_STRING_TO_CONTAINS)) {
            result = fieldApiName.split(DOT_STRING_TO_SPLIT)[0].toLowerCase();
        }
        return result;
    }

    public static List<Fields_Mapping__mdt> getFieldsMappingsForObject(String sObjectApiName) {
        List<Fields_Mapping__mdt> fms = Fields_Mapping__mdt.getAll().values();
        List<Fields_Mapping__mdt> result = new List<Fields_Mapping__mdt>();

        for (Fields_Mapping__mdt fm : fms) {
            if (fm.Source__c.substringBefore('.').containsIgnoreCase(sObjectApiName)) {
                result.add(fm);
            }
        }

        return result;
    }
    public static Set<String> collectSourceFields(List<Fields_Mapping__mdt> mappings) {
        Set<String> result = new Set<String>();
        for (Fields_Mapping__mdt fieldMapping: mappings) {
            String fieldNameSubstring = fieldMapping.Source__c.substringAfter('.');
            if (String.isNotBlank(fieldNameSubstring)) {
                result.add(fieldNameSubstring);
            }
        }

        return result;
    }

    public static Set<String> collectSourceFieldsForObject(String sObjectApiName) {
        return collectSourceFields(getFieldsMappingsForObject(sObjectApiName));
    }
}