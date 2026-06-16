public class GCPFeatureToggle {

    @AuraEnabled(cacheable=true)
    public static Boolean isFeatureEnabled() {
        GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
        return (setting != null && setting.Enable_Switch__c == true);
    }
}