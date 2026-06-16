public with sharing class SmartFactory {
    // can't map by Schema.sObjectType, use object name string instead
    static map<string, set<string>> excludedFields = new map<string, set<string>>{
            'All' => new Set<String>{'OwnerId', 'LastModifiedById', 'Main_point_of_contact__c'},
            'Account' => new Set<String>{'FirstName', 'LastName', 'LID__LinkedIn_Company_Id__c', 'inContact_account_ID__c'},
            'Contact' => new Set<String>{'LID__LinkedIn_Company_Id__c'}
    };

    public static SObject createSObject(string objectType) {
        return createSObject(objectType, false);
    }

    public static SObject createSObject(string objectType, boolean cascade) {
        System.debug('objectType ' + objectType);

        Schema.sObjectType token = ((SObject)Type.forName(objectType).newInstance()).getSObjectType();
        System.debug('token ' + token);
        SObject obj;
        Map<String, Schema.SObjectField> fieldMap;

        obj = ((SObject)Type.forName(objectType).newInstance()).getSObjectType().newSObject();
        fieldMap = ((SObject)Type.forName(objectType).newInstance()).getSObjectType().getDescribe().fields.getMap();

        for (Schema.SObjectField field : fieldMap.values()) {
            setFieldValue(obj, field, cascade);
        }

        System.debug('SmartFactory object created: ' + obj);
        return obj;
    }

    static boolean isExcludedField(Schema.DescribeFieldResult fieldDescribe) {
        return excludedFields.get('All').contains(fieldDescribe.getName());
    }

    static boolean isExcludedField(SObject obj, Schema.DescribeFieldResult fieldDescribe) {
        set<string> fields = excludedFields.get(obj.getSObjectType().getDescribe().getName());
        return fields == null ? false : fields.contains(fieldDescribe.getName());
    }

    static boolean isPersonAccountField(Schema.DescribeFieldResult fieldDescribe) {
        Boolean CustomPerson = fieldDescribe.getName().substring(fieldDescribe.getName().length()-2,fieldDescribe.getName().length()) == 'pc' && fieldDescribe.isCustom();
        Boolean StandardPerson = fieldDescribe.getName().startsWith('Person') && !fieldDescribe.isCustom();
        return (CustomPerson || StandardPerson);
    }

    static void setFieldValue(SObject obj, Schema.SObjectField field, boolean cascade) {
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

        if (fieldDescribe.isCreateable() &&
                !fieldDescribe.getName().endsWith('pc') && // lookup fields
                !isExcludedField(fieldDescribe) &&
                !isExcludedField(obj, fieldDescribe) &&
                !isPersonAccountField(fieldDescribe)) {

            if (fieldDescribe.getType() == Schema.DisplayType.String) {
                System.debug('Setting field ' + fieldDescribe.getName());
                obj.put(field, 'a');
            } else if (fieldDescribe.getType() == Schema.DisplayType.Reference) {
                string referenceObjectType = fieldDescribe.getReferenceTo()[0].getDescribe().getName();

                if (referenceObjectType == 'RecordType') {
                    setRecordType(obj);
                } else if (cascade && referenceObjectType != obj.getSObjectType().getDescribe().getName()) {
                    // TODO avoid infinite loop for same-type references
                    System.debug('Creating reference to ' + referenceObjectType);
                    SObject reference = createSObject(referenceObjectType);
                    try {
                        insert reference;
                        obj.put(field, reference.Id);
                    } catch(Exception e) {}
                }
            } // TODO put field values for rest of Schema.DisplayTypes
        }
    }

    static void setRecordType(SObject obj) {
        List<Schema.RecordTypeInfo> recordTypes = obj.getSObjectType().getDescribe().getRecordTypeInfos();

        if (recordTypes.size() > 1) { // all objects have default Master type
            System.debug('RecordTypes ' + recordTypes);
            for (Schema.RecordTypeInfo recordType : recordTypes) {
                if (recordType.isAvailable() && recordType.isDefaultRecordTypeMapping()) {
                    obj.put('RecordTypeId', recordType.getRecordTypeId());
                }
            }
        }

    }
}