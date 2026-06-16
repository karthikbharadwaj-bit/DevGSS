public with sharing class AIBannerController {

    @AuraEnabled(cacheable=true)
    public static AIBannerWrapper getBannerSettings() {
            AI_Banner__c bannerSetting = AI_Banner__c.getInstance();           
            AIBannerWrapper wrapper = new AIBannerWrapper();

            if (bannerSetting == null) {
                return wrapper; // Return default wrapper.
            }

                Boolean switchEnabled = bannerSetting.Switch__c != null ? bannerSetting.Switch__c : false;
                
                Boolean isWithinDateRange = isDateWithinRange(bannerSetting.From_Date__c, bannerSetting.To_Date__c);
                
                wrapper.isVisible = switchEnabled && isWithinDateRange;
                wrapper.heading = bannerSetting.Heading__c;
                wrapper.content = bannerSetting.Content__c;
                wrapper.gifResource = bannerSetting.Gif__c;
                wrapper.backgroundColor = bannerSetting.Background_Color__c;
                return wrapper;
    }
    
    private static Boolean isDateWithinRange(DateTime fromDateTime, DateTime toDateTime) {
        DateTime now = DateTime.now();
        
        if (fromDateTime == null && toDateTime == null) {
            return true;
        }
        
        if (fromDateTime != null && toDateTime == null) {
            return now >= fromDateTime;
        }
        
        if (fromDateTime == null && toDateTime != null) {
            return now <= toDateTime;
        }
        
        return now >= fromDateTime && now <= toDateTime;
    }
    
    public class AIBannerWrapper {
        @AuraEnabled public Boolean isVisible { get; set; }
        @AuraEnabled public String heading { get; set; }
        @AuraEnabled public String content { get; set; }
        @AuraEnabled public String gifResource { get; set; }
        @AuraEnabled public String backgroundColor { get; set; }
        
        public AIBannerWrapper() {
            this.isVisible = false;
            this.heading = '';
            this.content = '';
            this.gifResource = '';
            this.backgroundColor = '';
        }
    }
}