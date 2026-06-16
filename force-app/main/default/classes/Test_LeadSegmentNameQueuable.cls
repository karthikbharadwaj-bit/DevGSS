/*
* Description   : Test class for LeadSegmentNameQueuable

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
public class Test_LeadSegmentNameQueuable {
    @isTest static void testLeadSegment() {
        Map<Id,String> mapAccountIdNMarketoSegmentName = new Map<Id,String>();
        Map<Id,String> mapAccountIdNSegmentId = new Map<Id,String>();
        Map<Id,Lead> oldMap = new Map<Id,Lead>();
        Set<String> setCountryNames = new Set<String>();
    	Set<Decimal> setEmployeeNumbers = new Set<Decimal>();
        Set<Id> leadIds = new Set<Id>();
        List<Lead> leadList = new List<Lead>();
        List<Lead> leadList2 = new List<Lead>();
        

        Segment_Master__c seg = new Segment_Master__c();
        seg.Name = 'SOHO';
        seg.Max__c = 19;
        seg.Min__c = 1;
        seg.Country__c = 'United States';
        seg.Start_Date__c = System.today();
        insert seg;
        
        Lead ld1 = new Lead(LastName='Test',SegmentName__c=seg.Id,Marketo_Segment_Name__c='SOHO',Company='Test Company',email='test@test.com');
        Lead ld2 = new Lead(LastName='Test2',SegmentName__c=seg.Id,Marketo_Segment_Name__c='SOHO',Company='Test Company2',email='test2@test.com',NumberOfEmployees=10);
        Lead ld3 = new Lead(LastName='Test3',SegmentName__c=seg.Id,Marketo_Segment_Name__c='SOHO',Company='Test Company3',email='test3@test.com',LS_Company_Size__c=10);
        Lead ld4 = new Lead(LastName='Test3',SegmentName__c=seg.Id,Marketo_Segment_Name__c='SOHO',Company='Test Company3',email='test3@test.com',ZI_Employees__c=10);
        leadList.add(ld1);
        leadList.add(ld2);
        leadList.add(ld3);
        leadList.add(ld4);
        insert leadList;
         Map<Id, Lead> mapFromList = new Map<Id, Lead>(leadList);
        for(Lead ld:leadList)
        {
            if(ld.NumberOfEmployees!=null) {
                ld.NumberOfEmployees=9;
            }
            if(ld.LS_Company_Size__c!=null) {
                ld.LS_Company_Size__c=9;
            }
            if(ld.ZI_Employees__c!=null) {
                ld.ZI_Employees__c=9;
            }
            leadList2.add(ld);
            leadIds.add(ld.Id);
        }
        update leadList2;
        setCountryNames.add('United States');
        setEmployeeNumbers.add(10);
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Gating_Email_Addresses_List__c='test1@test.com,test2@test.com';
        insert processStage;
        
        Test.startTest();
        LeadSegmentNameQueuable leadSegment = new LeadSegmentNameQueuable(leadIds,setCountryNames,setEmployeeNumbers,mapFromList);
        ID jobID = System.enqueueJob(leadSegment);
        LeadSegmentNameQueuable.sendOwnerMail((Id) new ValueProvider.DummyIdProvider(User.sObjectType).getValue(),ld1.Id);
        Test.stopTest();
    }

}