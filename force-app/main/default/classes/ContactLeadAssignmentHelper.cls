public class ContactLeadAssignmentHelper { 
    public Static void validateCampaign(List<Contact> contactList) {
        try {
        Map<String, Campaign> defaultCampaignMap = CampaignAssignmentHelper.findCampaings(new List<CampaignWrapper>());
        Map<String, Campaign> defaultCampaign_15DigitMap = new Map<String, Campaign>();
        if(defaultCampaignMap!=null && defaultCampaignMap.size() > 0){
            for(String keyValue : defaultCampaignMap.keySet()){
                if(keyValue.length() > 15){
                    defaultCampaign_15DigitMap.put(keyValue.subString(0,15),defaultCampaignMap.get(keyValue));
                }
            }
        }
        for(Contact contactObj :contactList) {          
            if((!String.isBlank(contactObj.Primary_Campaign__c) && defaultCampaignMap != null && 
                            ((defaultCampaignMap.get(contactObj.Primary_Campaign__c.toUpperCase()) != null) || 
                            (defaultCampaign_15DigitMap != null && defaultCampaign_15DigitMap.get(contactObj.Primary_Campaign__c.toUpperCase()) != null))) 
                            ) {
                contactObj.Primary_Campaign__c = null;
            }
            //As per new case "02410144"
            if((!String.isBlank(contactObj.Most_Recent_Campaign__c) && defaultCampaignMap != null && 
                            ((defaultCampaignMap.get(string.valueOf(contactObj.Most_Recent_Campaign__c).toUpperCase()) != null) || 
                            (defaultCampaign_15DigitMap != null && defaultCampaign_15DigitMap.get(string.valueOf(contactObj.Most_Recent_Campaign__c).toUpperCase()) != null))) 
                            ) {
                contactObj.Most_Recent_Campaign__c = null;
            }
            //End As per new case "02410144"
            }
        } catch(Exception ex) {
            ExceptionHelper.createExceptionAndNotificacionHistory(ex, contactList, 'Contact Exception');
        }
    }
    public static Map<String, Campaign> assignCampaignToContact(List<Contact> contactList) {
        Map<String, Campaign> campaignMap = new Map<String, Campaign>(); 
        List<CampaignWrapper> camWrapperList = new List<CampaignWrapper>();
        
        for(Contact contactObj : contactList) {
            //camWrapperList.add(new CampaignWrapper(contactObj.AID__c, contactObj.BMID__c, contactObj.PID__c, contactObj.Primary_Campaign__c, false));
            // Case 03336769 changes {  
            camWrapperList.add(new CampaignWrapper(contactObj.AID__c, contactObj.BMID__c, contactObj.PID__c,contactObj.DNIS__c, null, false));
            //}Case 03336769 changes 
        }
        
        Map<String, Campaign> criteriaToCamapaignMap = CampaignAssignmentHelper.findCampaingsLogic(camWrapperList);
        for(Contact contactObj :contactList) {
            Campaign campaignObj = CampaignAssignmentHelper.getLeadCampaignLogic(new CampaignWrapper(contactObj.AID__c, contactObj.BMID__c, contactObj.PID__c, contactObj.DNIS__c,contactObj.Primary_Campaign__c, false), criteriaToCamapaignMap);
            if(campaignObj != null) {
                contactObj.Primary_Campaign__c = campaignObj.Id;
                // Case 03336769 changes {
                contactObj.Most_Recent_Campaign__c = campaignObj.id;
                //}Case 03336769 changes
                campaignMap.put((String)contactObj.Primary_Campaign__c, campaignObj);
            }
        }
        return campaignMap;
    }
}