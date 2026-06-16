/**
 * Created by Makhmud.Shafeev on 8/31/2021.
 */

global class BatchObjectMonitoring implements Database.Batchable<SObject> {

    public String query;

    public BatchObjectMonitoring() {
    }

    public BatchObjectMonitoring(String query) {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('BatchObjectMonitoring start');
        if (query == null) {
            // selected all rows created 2 week ago
            query = ObjectMonitoringHelper.soqlOlder2Weeks;
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext param1, List<ObjectMonitoring__c> objectMonitoring) {
        System.debug('BatchObjectMonitoring execute');
        Set<String> custSettNames = BatchObjectMonitoringForCustomSettings.customSettingsMonitoringWithFields().keySet();
        List<ObjectMonitoring__c> objectsToDelete = new List<ObjectMonitoring__c>();

        for (ObjectMonitoring__c obj: objectMonitoring) {
            if (!custSettNames.contains(obj.ObjectName__c)) {
                objectsToDelete.add(obj);
            }
        }

        if (!objectsToDelete.isEmpty()) {
            List<Database.DeleteResult> results = Database.delete(objectsToDelete, true);

            for (Database.DeleteResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error err : result.getErrors()) {
                        System.debug('Errors ' + err.getStatusCode() + ' : ' + err.getMessage() + ' : ' + err.getFields());
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext param) {
        System.debug('BatchObjectMonitoring finish');
    }

}