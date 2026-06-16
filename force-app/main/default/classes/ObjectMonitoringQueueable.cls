/**
 * Created by Makhmud.Shafeev on 8/19/2021.
 */

public class ObjectMonitoringQueueable implements Queueable {

    private List<Map<String, String>> values = new List<Map<String, String>>();

    public ObjectMonitoringQueueable(List<Map<String, String>> values) {
        this.values = values;
    }

    public static List<ObjectMonitoring__c> createMonitoringObjects(List<Map<String, String>> values) {
        List<ObjectMonitoring__c> monitoringObjects = new List<ObjectMonitoring__c>();
        if (values != null && !values.isEmpty()) {
            for (Map<String, String> objectValues : values) {
                monitoringObjects.add(ObjectMonitoringHelper.createMonitoringObject(objectValues));
            }
        }
        return monitoringObjects;
    }

    public void execute(QueueableContext context) {
        List<ObjectMonitoring__c> monitoringObjects = createMonitoringObjects(this.values);

        if (!monitoringObjects.isEmpty()) {
            insert monitoringObjects;
        }
    }

}