@isTest
public with sharing class Test_ExcludePartnerNonBusinessHours {
    public Test_ExcludePartnerNonBusinessHours() {

    }
    
    @isTest
    static void testNextFollowUpDate() {
        BusinessHours bh = [SELECT Id, Name FROM BusinessHours LIMIT 1];
        
        ExcludePartnerNonBusinessHours.Requests req = new ExcludePartnerNonBusinessHours.Requests();
        req.businessHoursName = bh.Name;
        req.followUpCount = 0;
        req.followUpInterval = '24,48';
        
        List<ExcludePartnerNonBusinessHours.Requests> records = new List<ExcludePartnerNonBusinessHours.Requests>();
        records.add(req);
        
        List<ExcludePartnerNonBusinessHours.Result> results = ExcludePartnerNonBusinessHours.nextFollowUpDate(records);
        
        System.assertEquals(1, results.size());
        System.assertNotEquals(null, results[0].nextFollowDate);
    }

}