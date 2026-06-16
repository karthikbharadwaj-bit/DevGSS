@isTest
public class Test_Partner_OpportunityTrgHelper {
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
    static void testMethod1(){
        
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Contact contact=PartnerRecordsUtil.partnerContact;
        Opportunity oppObj =PartnerRecordsUtil.createAvayaOpportunity();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        List<Opportunity> listOfNewOpps=new List<Opportunity>();
        
        
        oldOppMap.put(oppObj.Id,oppObj);
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();
        
        Opportunity newOpp = oppObj.clone(true, true);
        newOpp.Avaya_Cloud_Specialist__c = contact.Id;
        listOfNewOpps.add(newOpp);
        
        Test.startTest();
        Partner_OpportunityTrgHelper.oppBeforeMappings(newOpp, oldOppMap);
     	Partner_OpportunityTrgHelper.oppBeforeMappings(newOpp, null);
        Partner_OpportunityTrgHelper.oppAfterMappings(listOfNewOpps,oldOppMap);
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethod2(){
        
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Account acc=PartnerRecordsUtil.partnerAccount;
        Opportunity oppObj =PartnerRecordsUtil.createAvayaOpportunity();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        List<Opportunity> listOfNewOpps=new List<Opportunity>();
        
        
        oldOppMap.put(oppObj.Id,oppObj);
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();
        
        Contact contact2 = new Contact(
                    FirstName = 'Test 2',
                    Lastname = 'McTestysdf',
                    AccountId = acc.id,
                    Partner_Portal_View__c='Full',
                    Email = System.now().millisecond() + 'test@2test.com'
                );
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
        insert contact2;
            Opportunity newOpp = oppObj.clone(true, true);
            newOpp.AccountId = acc.id;
            //newOpp.Avaya_Cloud_Specialist__c = contact.Id;
            newOpp.Portal_Cloud_Specialist__c = contact2.Id;
            listOfNewOpps.add(newOpp);
            //update listOfNewOpps;
        }
        
        
        Test.startTest();
      
        Partner_OpportunityTrgHelper.oppAfterMappings(listOfNewOpps,oldOppMap);
        Partner_OpportunityTrgHelper.oppAfterMappings(listOfNewOpps,null);
        Test.stopTest();
    }
}