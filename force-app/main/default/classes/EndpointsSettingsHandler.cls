public with sharing class EndpointsSettingsHandler {

    private static EndpointsSettings__c settings {
        get {
            if (settings == null) {
                settings = EndpointsSettings__c.getInstance();
            }
            return settings;
        }
        private set;
    }

    public static String uqtServerEndpoint {
        get {
            return settings.UQTServerEndpoint__c;
        }
        private set;
    }
}