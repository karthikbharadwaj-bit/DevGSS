@isTest
public class Test_LeadMerketoActivities{
@testSetup
    static void testSetup() {
        Lead testLead = new Lead(Email='fake@email.com', LastName='Test', Company='Test Co.');
        insert testLead;
    }
    @isTest
    static void getLeadrecord() {
        Lead testLead = [Select Id from Lead];
        Lead retList = lead_MarketoActivities.getLead(String.valueOf(testLead.Id));
        System.assert(retList!= null);
    }

}