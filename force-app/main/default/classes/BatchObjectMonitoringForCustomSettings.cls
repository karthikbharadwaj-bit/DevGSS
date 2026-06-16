global class BatchObjectMonitoringForCustomSettings implements Database.Batchable<Map<String, Set<String>>> {

    public BatchObjectMonitoringForCustomSettings() {}

    public Iterable<Map<String, Set<String>>> start(Database.BatchableContext bc) {
        List<Map<String, Set<String>>> result = new List<Map<String, Set<String>>>();
        // get list of hierarchy custom settings names and create MAP: fieldsByObjectName<ObjName, List<Field>>
        Map<String, Set<String>> fieldsByObjectName = customSettingsMonitoringWithFields();
        // generate list of maps for execute method
        for (String settingName: fieldsByObjectName.keySet()) {
            Map<String, Set<String>> m = new Map<String, Set<String>>();
            m.put(settingName, fieldsByObjectName.get(settingName));
            result.add(m);
        }
        return result;
    }

    public void execute(Database.BatchableContext info, List<Map<String, Set<String>>> scope) {
        List<ObjectMonitoring__c> objs = new List<ObjectMonitoring__c>();
        List<ObjectMonitoring__c> objsToDelete = new List<ObjectMonitoring__c>();

        // iterate by settings names and create objs if needed
        for (Map<String, Set<String>> m: scope) {
            String settingName = (new List<String>(m.keySet())).get(0);
            List<String> fieldNames = new List<String>(m.get(settingName));
            List<ObjectMonitoring__c> objsTemp = customSettingMonitoring(settingName, fieldNames);
            if (!objsTemp.isEmpty()) {
                objs.addAll(objsTemp);
            }
        }

        // before inserting, select all ObjectMonitorings by ObjName and FieldName for deletion
        for (ObjectMonitoring__c objM: objs) {
            List<ObjectMonitoring__c> needToRemove = selectOldRecords(objM.ObjectName__c, objM.FieldName__c);
            if (!needToRemove.isEmpty()) {
                objsToDelete.addAll(needToRemove);
            }
        }

        if (!objs.isEmpty()) {
            insert objs;
        }

        if (!objsToDelete.isEmpty()) {
            delete objsToDelete;
        }
    }

    public static Map<String, Set<String>> customSettingsMonitoringWithFields() {
        List<ObjectMonitoringSettings__c> settings = ObjectMonitoringSettings__c.getAll().values();
        Map<String, Set<String>> fieldsByObjectName = new Map<String, Set<String>>();
        for (ObjectMonitoringSettings__c setting: settings) {
            Schema.SObjectType sObjType = ((SObject) Type.forName(setting.ObjectName__c).newInstance()).getSObjectType();
            if (sObjType.getDescribe().isCustomSetting()) {
                List<String> objectFields = setting.ObjectFields__c.split(';');
                if (!fieldsByObjectName.containsKey(setting.ObjectName__c)) {
                    fieldsByObjectName.put(setting.ObjectName__c, new Set<String>(objectFields));
                } else {
                    Set<String> exOjectFields = fieldsByObjectName.get(setting.ObjectName__c);
                    exOjectFields.addAll(objectFields);
                    fieldsByObjectName.put(setting.ObjectName__c, exOjectFields);
                }
            }
        }
        return fieldsByObjectName;
    }

    public static List<ObjectMonitoring__c> customSettingMonitoring(String settingName, List<String> fieldNames) {
        List<ObjectMonitoring__c> objs = new List<ObjectMonitoring__c>();
        // 1 - select all ObjectMonitoring objects with object by settingName
        List<AggregateResult> aggregateResults = (List<AggregateResult>) Database.query(
            'SELECT Max(CreatedDate), ObjectName__c, FieldName__c, FieldNewValue__c ' +
                ' FROM ObjectMonitoring__c ' +
                ' WHERE ObjectName__c = :settingName ' +
                ' GROUP BY ObjectName__c, FieldName__c, FieldNewValue__c' +
                ' ORDER BY Max(CreatedDate) DESC');

        // 2 - create MAP: ValuesMap<Field, oldValue>
        Map<String, String> valuesMap = new Map<String, String>();
        for (AggregateResult ar : aggregateResults) {
            String agrFieldName = (String) ar.get('FieldName__c');
            String agrValue = (String) ar.get('FieldNewValue__c');
            if (!valuesMap.containsKey(agrFieldName)) {
                valuesMap.put(agrFieldName, agrValue);
            }
        }

        // 3 - select org defaults by settingName and fieldNames
        Id orgId = UserInfo.getOrganizationId();
        String fieldsStr = String.join(fieldNames, ', ');
        sObject orgsDefaults = Database.query('SELECT LastModifiedById, ' + fieldsStr + ' FROM ' + settingName +
            ' WHERE ' + 'SetupOwnerId = \'' + String.valueOf(orgId) + '\'').get(0);

        // 4 - iterate by fieldNames and if difference is found, ObjectMonitoring will be created
        for (String fieldName: fieldNames) {
            if (!valuesMap.containsKey(fieldName) || valuesMap.get(fieldName) != String.valueOf(orgsDefaults.get(fieldName))) {
                Map<String, String> monitoringMap = ObjectMonitoringHelper.createObjectMonitoringMap(
                    (Id) orgsDefaults.get('Id'),
                    settingName,
                    fieldName,
                    String.valueOf(orgsDefaults.get(fieldName)),
                    valuesMap.get(fieldName),
                    (String) orgsDefaults.get('LastModifiedById'),
                    '',
                    '');
                ObjectMonitoring__c objMon = ObjectMonitoringHelper.createMonitoringObject(monitoringMap);
                objs.add(objMon);
            }
        }

        return objs;
    }

    public static List<ObjectMonitoring__c> selectOldRecords(String settingName, String fieldName) {
        return Database.query(
            'SELECT Id FROM ObjectMonitoring__c '
                + ' WHERE ObjectName__c = :settingName'
                   + ' AND FieldName__c = :fieldName'
                   + ' AND CreatedDate < ' + ObjectMonitoringHelper.soqlOlderSetting
                   + ' LIMIT 1000'
        );
    }

    public void finish(Database.BatchableContext bc) {}
}