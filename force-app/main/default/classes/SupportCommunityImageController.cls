public without sharing class SupportCommunityImageController {

    @AuraEnabled(Cacheable=true)
    public static List<SupportCommunityImagelnk__c> getPictures(String place, Integer imgOrder, String country) {
        if(country == null) {
            country = 'en_US';
        }
        String query =
            'SELECT Name, Image__c, Link__c, Place__c'
            + ' FROM SupportCommunityImagelnk__c'
            + ' WHERE Place__c = :place AND Active__c = TRUE AND (Country__c includes (:country) OR Country__c = null)';

        if(imgOrder != null) {
            query += ' AND OrderId__c = :imgOrder';
        }
        query += ' ORDER BY OrderId__c,Id';

        if(imgOrder != null) {
            query += ' LIMIT 1';
        }
        return (List<SupportCommunityImagelnk__c>) Database.query(query);
    }
}