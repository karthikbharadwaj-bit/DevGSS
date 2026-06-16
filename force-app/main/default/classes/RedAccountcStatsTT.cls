@isTest
private class RedAccountcStatsTT {

    @isTest
    static void testTrigger() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Red_Account__c o = new Red_Account__c();
        o.EscalatedAccount__c = acc.Id;
        o.Issue_Category__c = 'Other';
        o.Issue_Status__c = 'New';
        o.Primary_Competitor__c = 'Comcast';
        o.Primary_Reason_for_Red__c = 'Support Issues';
        o.Sub_Reason_for_Red__c = 'Adoption Issues';

        insert o;
    	
        List<Red_Account__c> l = [SELECT Id, Issue_Category__c, Issue_Status__c, Primary_Competitor__c, Primary_Reason_for_Red__c, Sub_Reason_for_Red__c
                                  FROM Red_Account__c 
                                  WHERE Id = :o.Id 
                                  LIMIT 1];
        update l;
        System.assertNotEquals(null, l);
    }
}