/**
 * Created by Makhmud.Shafeev on 8/19/2021.
 */

public without sharing class ObjectMonitoringHelper {

    public static final String soqlOlderSetting = 'LAST_N_WEEKS:2';
    public static final String soqlOlder2Weeks = 'SELECT Id, ObjectName__c FROM ObjectMonitoring__c WHERE CreatedDate < ' + soqlOlderSetting;

    public enum ObjectMonitoringValues {
        objectId,
        objectName,
        fieldName,
        newValue,
        oldValue,
        userId,
        stackTrace,
        triggerAction,
        comments
    }

    public class MonitoringAddObject extends Triggers.TriggerHandlerBase {

        private String objectName;

        public MonitoringAddObject(String objectName) {
            this.objectName = objectName;
        }

        override public void handle() {

            ObjectMonitoringSettings__c settings = ObjectMonitoringSettings__c.getValues(this.objectName);

            List<SObject> objectsList = (List<SObject>) (!Trigger.isDelete ? Trigger.new : Trigger.old);
            Map<Id, SObject> oldValues = Trigger.oldMap;

            List<Map<String, String>> valueList = new List<Map<String, String>>();

            if (settings != null) {
                List<String> settingFieldsNames = settings.ObjectFields__c.split(';');

                for (SObject obj : objectsList) {
                    Map<String, Object> fieldsToValue = obj.getPopulatedFieldsAsMap();
                    SObjectDescribeHelper sObjectDescr = SObjectDescribeHelper.getDescribe(objectName);
                    Map<String, String> valuesMap = new Map<String, String>();
                    for (String fieldName : settingFieldsNames) {
                        if (fieldsToValue.containsKey(fieldName)) {
                            Schema.SObjectField field = sObjectDescr.getField(fieldName.toLowerCase());
                            if (isChangedField(obj, field)) {

                                Id objectId = (Id) obj.get('Id');
                                valuesMap.put(ObjectMonitoringValues.objectId.name(), objectId);
                                valuesMap.put(ObjectMonitoringValues.objectName.name(), objectName);
                                valuesMap.put(ObjectMonitoringValues.fieldName.name(), fieldName);
                                valuesMap.put(ObjectMonitoringValues.newValue.name(), String.valueOf(obj.get(fieldName)));
                                if (oldValues != null && oldValues.containsKey(objectId)) {
                                    valuesMap.put(ObjectMonitoringValues.oldValue.name(), String.valueOf(oldValues.get(objectId).get(fieldName)));
                                }
                                valuesMap.put(ObjectMonitoringValues.userId.name(), String.valueOf(System.UserInfo.getUserId()));
                                valuesMap.put(ObjectMonitoringValues.triggerAction.name(), getTriggerAction());
                                valuesMap.put(ObjectMonitoringValues.stackTrace.name(), new DmlException().getStackTraceString());

                                valueList.add(valuesMap);
                            }
                        }
                    }
                }
            }

            if (!valueList.isEmpty()) {
                if (Limits.getLimitQueueableJobs() > Limits.getQueueableJobs()) {
                    System.enqueueJob(new ObjectMonitoringQueueable(valueList));
                } else {
                    List<ObjectMonitoring__c> monitoringObjects = ObjectMonitoringQueueable.createMonitoringObjects(valueList);
                    if (!monitoringObjects.isEmpty()) {
                        insert monitoringObjects;
                    }
                }
            }
        }
    }

    public static Map<String, String> createObjectMonitoringMap(Id objectId, String objectName, String fieldName, String newValue, String oldValue, String userId, String comments, String stackTrace) {
        return new Map<String, String>{
            ObjectMonitoringValues.objectId.name() => objectId,
            ObjectMonitoringValues.objectName.name() => objectName,
            ObjectMonitoringValues.fieldName.name() => fieldName,
            ObjectMonitoringValues.newValue.name() => newValue,
            ObjectMonitoringValues.oldValue.name() => oldValue,
            ObjectMonitoringValues.userId.name() => userId,
            ObjectMonitoringValues.comments.name() => comments,
            ObjectMonitoringValues.stackTrace.name() => stackTrace
        };
    }

    public static ObjectMonitoring__c createMonitoringObject(Map<String, String> objectValues) {
        ObjectMonitoring__c objMonitoring = new ObjectMonitoring__c();
        if (objectValues.containsKey(ObjectMonitoringValues.objectId.name())) {
            objMonitoring.ObjectId__c = objectValues.get(ObjectMonitoringValues.objectId.name());
        }
        if (objectValues.containsKey(ObjectMonitoringValues.objectName.name())) {
            objMonitoring.ObjectName__c = objectValues.get(ObjectMonitoringValues.objectName.name());
        }
        if (objectValues.containsKey(ObjectMonitoringValues.fieldName.name())) {
            objMonitoring.FieldName__c = objectValues.get(ObjectMonitoringValues.fieldName.name());
        }
        if (objectValues.containsKey(ObjectMonitoringValues.newValue.name())) {
            objMonitoring.FieldNewValue__c = objectValues.get(ObjectMonitoringValues.newValue.name());
        }
        if (objectValues.containsKey(ObjectMonitoringValues.oldValue.name())) {
            objMonitoring.FieldOldValue__c = objectValues.get(ObjectMonitoringValues.oldValue.name());
        }
        if (objectValues.containsKey(ObjectMonitoringValues.userId.name())) {
            objMonitoring.UserId__c = objectValues.get(ObjectMonitoringValues.userId.name());
        }
        if (objectValues.containsKey(ObjectMonitoringValues.triggerAction.name())) {
            objMonitoring.TriggerAction__c = objectValues.get(ObjectMonitoringValues.triggerAction.name());
        }
        if (objectValues.containsKey(ObjectMonitoringValues.stackTrace.name())) {
            objMonitoring.StackTrace__c = objectValues.get(ObjectMonitoringValues.stackTrace.name());
        }
        if (objectValues.containsKey(ObjectMonitoringValues.comments.name())) {
            objMonitoring.Comments__c = objectValues.get(ObjectMonitoringValues.comments.name());
        }

        return objMonitoring;
    }

    public static void createObjectMonitoring(Id objectId, String objectName, String fieldName, String newValue, String oldValue, String userId, String comments, String stackTrace) {
        Map<String, String> valuesMap = createObjectMonitoringMap(objectId, objectName, fieldName, newValue, oldValue, userId, comments, stackTrace);
        System.enqueueJob(new ObjectMonitoringQueueable(new List<Map<String, String>>{valuesMap}));
    }

    public static void createObjectMonitoring(Id objectId, String objectName, String fieldName, String newValue, String oldValue, String userId, String comments) {
        createObjectMonitoring(objectId, objectName, fieldName, newValue, oldValue, userId, comments, new DmlException().getStackTraceString());
    }

    public static String generateCSVStructure(String objectId) {
        List<FieldSetMember> fieldSetMembers = SObjectType.ObjectMonitoring__c.FieldSets.CSV.getFields();
        String generatedCSVFile = '';
        String soql = 'SELECT {0} FROM ObjectMonitoring__c WHERE ObjectId__c = :objectId ORDER BY CreatedDate';

        for (FieldSetMember fieldMember : fieldSetMembers) {
            if (generatedCSVFile.length() > 1) {
                generatedCSVFile += ',';
            }
            generatedCSVFile += fieldMember.getFieldPath();
        }
        soql = String.format(soql, new List<String> {
                generatedCSVFile
        });
        generatedCSVFile += '\n';

        for (List<ObjectMonitoring__c> objectsMonitoring : Database.query(soql)) {
            for (ObjectMonitoring__c objectMonitoring : objectsMonitoring) {
                Integer maxCount = fieldSetMembers.size();
                for (Integer index = 0; index < maxCount; index++) {
                    FieldSetMember fieldMember =  fieldSetMembers.get(index);

                    if (fieldMember.getFieldPath().containsIgnoreCase(ObjectMonitoringValues.comments.name()) ||
                            fieldMember.getFieldPath().containsIgnoreCase(ObjectMonitoringValues.stackTrace.name())) {
                        generatedCSVFile += '"' + objectMonitoring.get(fieldMember.getFieldPath()) + '"';
                    } else {
                        generatedCSVFile += objectMonitoring.get(fieldMember.getFieldPath());
                    }

                    generatedCSVFile += (index == maxCount - 1) ? '\n' :  ',';
                }
            }
        }
        return generatedCSVFile;
    }

    public static String getObjectAPINameById(String objectId) {
        return ((Id) objectId)?.getSObjectType().getDescribe().getName();
    }

    public static String getTriggerAction() {
        String triggerAction = null;
        if (Trigger.isBefore && Trigger.isInsert) {
            triggerAction = TriggerOperation.BEFORE_INSERT.name();
        } else if (Trigger.isAfter && Trigger.isInsert) {
            triggerAction = TriggerOperation.AFTER_INSERT.name();
        } else if (Trigger.isBefore && Trigger.isUpdate) {
            triggerAction = TriggerOperation.BEFORE_UPDATE.name();
        } else if (Trigger.isAfter && Trigger.isUpdate) {
            triggerAction = TriggerOperation.AFTER_UPDATE.name();
        } else if (Trigger.isBefore && Trigger.isDelete) {
            triggerAction = TriggerOperation.BEFORE_DELETE.name();
        } else if (Trigger.isAfter && Trigger.isDelete) {
            triggerAction = TriggerOperation.AFTER_DELETE.name();
        } else if (Trigger.isUndelete) {
            triggerAction = TriggerOperation.AFTER_UNDELETE.name();
        }
        return triggerAction;
    }

}