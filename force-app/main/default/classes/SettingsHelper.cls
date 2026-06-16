global with sharing class SettingsHelper {
    @AuraEnabled
    webservice static EndpointsSettings__c getEndpointsSettings() {
        return EndpointsSettings__c.getInstance();
    }

    public static final RingCentralVariousSettings__c RC_SETTINGS = RingCentralVariousSettings__c.getInstance();
    public static final Feature_Toggle__c FEATURE_TOGGLE = Feature_Toggle__c.getInstance();

    // returns List<BrandToAllowedCountryMapping__mdt> as JSON string
    @AuraEnabled
    webservice static String getBrandToAllowedCountryMapping() {
        return JSON.serialize(BrandToAllowedCountryMapping__mdt.getAll().values());
    }

    public static Map<String, String> getCountryCodesFullName() {
        Map<String, String> resultMap = new Map<String, String>();

        for (CountryCodes__c countryCodeRecord : CountryCodes__c.getAll().values()) {
            for (String countryName : countryCodeRecord.CountryName__c.split(';')) {
                resultMap.put(countryName, countryCodeRecord.CountryNameFull__c);
            }
        }
        return resultMap;
    }

    public static Map<String, String> getCountryAlphaCode() {
        Map<String, String> resultMap = new Map<String, String>();

        for (CountryCodes__c countryCodeRecord : CountryCodes__c.getAll().values()) {
            for (String countryName : countryCodeRecord.CountryName__c.split(';')) {
                resultMap.put(countryName, countryCodeRecord.Name);
            }
        }
        return resultMap;
    }
}