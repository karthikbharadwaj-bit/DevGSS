public without sharing class EURestrictedNotificationController {
    
    @AuraEnabled(Cacheable=true)
    public static boolean validateEURestrictedData(Id recordId){
        EUPrivacy eu = new EUPrivacy();
        return recordId!=null ? eu.showComponent(recordId, 'EURestrictedNotificationController'): false; 
    }
    
    @AuraEnabled(Cacheable=true)
    public static boolean hideNotes(Id recordId){
        EUPrivacy eu = new EUPrivacy();
        return recordId!=null ? eu.showComponent(recordId, 'hideNotes'): false; 
    }

    //Below method is introduced to get banner msg from custom metadata and bind dynamically to Banner Component
    @AuraEnabled(Cacheable=true)
    public static String getEUBannerMsg(){
        String msg = '';
        List<EU_Privacy_Setup__mdt> EUPrivacyList = [SELECT Restricted__c from EU_Privacy_Setup__mdt where DeveloperName = 'EUNotificationBannerMsg'];
		if(EUPrivacyList != null && EUPrivacyList.size()>0)
        {
            msg = EUPrivacyList[0].Restricted__c.trim();
        }
        return msg;
    }

}