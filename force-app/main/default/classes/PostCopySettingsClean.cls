public with sharing class PostCopySettingsClean extends PostCopyWorker {

    public override String getClassName() {
        return PostCopySettingsClean.class.getName();
    }

    public override void run() {
        Map<String, PostCopyCustomSettingsManagement__c> allFields = PostCopyCustomSettingsManagement__c.getAll();
        Map<String, Set<String>> objectToFieldSet = new Map<String, Set<String>>();
        Set<String> listCustomSettings = new Set<String>();

        for (PostCopyCustomSettingsManagement__c s : allFields.values()) {
            SObjectDescribeHelper currentCustomSetting = SObjectDescribeHelper.getDescribe(s.Custom_Setting_API_Name__c);
            if (currentCustomSetting == null) {
                continue;
            }
            Map<String,Schema.SObjectField> fields = currentCustomSetting.getFieldsMap();
            if (String.isEmpty(s.Field_Name__c)) {
                listCustomSettings.add(s.Custom_Setting_API_Name__c);
            } else if (fields.keySet().contains(s.Field_Name__c.toLowerCase())) {

                if (!objectToFieldSet.containsKey(s.Custom_Setting_API_Name__c)) {
                    objectToFieldSet.put(s.Custom_Setting_API_Name__c, new Set<String>{s.Field_Name__c});
                    continue;
                }
                objectToFieldSet.get(s.Custom_Setting_API_Name__c).add(s.Field_Name__c);
            }
        }
        //Handle hierarchy custom settings
        List<SObject> customSettingsToUpdate = new List<SObject>();

        for (String objName : objectToFieldSet.keySet()) {
            String table = objName;
            List<SObject> customSetting = new List<SObject>();
                try {
                    customSetting = Database.query('SELECT Id FROM ' + table);
                } catch ( Exception e ) {
                    PostCopyUtil.createLogObj(getClassName(), e);
                }
                for (SObject s : customSetting) {
                    for(String field : objectToFieldSet.get(objName)) {
                        s.put(field, '');
                    }
                    customSettingsToUpdate.add(s);
                }

        }

        //Handle list custom setiings
        List<SObject> customSettingsToDelete = new List<SObject>();
        try {
            for (String name : listCustomSettings) {
                customSettingsToDelete.addAll(Database.query('SELECT Id FROM ' + name));
            }
        } catch (Exception e) {
            PostCopyUtil.createLogObj(getClassName(), e);
        }

        try {
            update customSettingsToUpdate;
            delete customSettingsToDelete;
        } catch (DmlException e) {
            PostCopyUtil.createLogObj(getClassName(), e);
        }
    }
}