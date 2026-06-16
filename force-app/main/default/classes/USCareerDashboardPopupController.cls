public with sharing class USCareerDashboardPopupController {
    public String query {get; set;}
    public List<Coaching_Log__c> CLogs {get; set;}
    public String tid {get; set;}
    
    public USCareerDashboardPopupController() {
        tid = Apexpages.currentPage().getParameters().get('tid');
        if(String.isNotBlank(tid)){
            CLogs = [SELECT Coaching_Date__c, ASP1__c, CLOSE_RATE__c, UPSELL__c, BOOKINGS_QUALITY_TARGET__c, 
            NETBOOKINGS_MTD_TARGET__c FROM Coaching_Log__c WHERE Account_Executive__c=:tid  
            ORDER BY Coaching_Date__c DESC LIMIT 6];
        }
    }
}