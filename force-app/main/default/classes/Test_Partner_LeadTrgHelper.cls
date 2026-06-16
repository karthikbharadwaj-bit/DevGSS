@isTest
public class Test_Partner_LeadTrgHelper {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethod1(){
        
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Contact contact=PartnerRecordsUtil.partnerContact;
        Deal_Registration__c dealObj =PartnerRecordsUtil.createAvayaDeal();
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> listOfNewLeads=new List<Lead>();
        
        Lead leadObj = PartnerRecordsUtil.createAvayaLead(dealObj);
        oldLeadMap.put(leadObj.Id,leadObj);
        Map<Id, Lead> newLeadMap = new Map<Id, Lead>();
        
        Lead newLead = leadObj.clone(true, true);
        newLead.Avaya_Cloud_Specialist__c = contact.Id;
        listOfNewLeads.add(newLead);
        
        Test.startTest();
        Partner_LeadTrgHelper.leadBeforeMappings(newLead, oldLeadMap);
        Partner_LeadTrgHelper.leadBeforeMappings(newLead, null);
        Partner_LeadTrgHelper.recalculateDealSupportsOfLead(listOfNewLeads,oldLeadMap);
        Test.stopTest();
    }
}