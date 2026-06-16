/*
* Description   : Test class for AccountSegmentNameQueuable

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
public class Test_AccountSegmentNameQueuable {
    @isTest static void testAccountSegment() {
        Map<Id,String> mapAccountIdNMarketoSegmentName = new Map<Id,String>();
        Map<Id,String> mapAccountIdNSegmentId = new Map<Id,String>();

        Segment_Master__c seg = new Segment_Master__c();
        seg.Name = 'SOHO';
        seg.Max__c = 19;
        seg.Min__c = 1;
        seg.Country__c = 'United States';
        seg.Start_Date__c = System.today();
        insert seg;
        
        Segment_Master__c seg2 = new Segment_Master__c();
        seg2.Name = 'SOHO2';
        seg2.Max__c = 19;
        seg2.Min__c = 1;
        seg2.Country__c = 'United States';
        seg2.Start_Date__c = System.today();
        insert seg2;
        
        Account newAcc = new Account(Name='Test',Segment_Name__c=seg2.Id,Marketo_Segment_Name__c='SOHO2');
        insert newAcc;
        
        Account newAcc2 = new Account(Name='Test2',ParentId=newAcc.id,Segment_Name__c=seg.Id,Marketo_Segment_Name__c='SOHO');
        insert newAcc2;
        
        mapAccountIdNMarketoSegmentName.put(newAcc2.Id,'Test2');
        mapAccountIdNSegmentId.put(newAcc.Id, String.valueOf(seg.Id));
        
        Test.startTest();
        AccountSegmentNameQueuable accSegment = new AccountSegmentNameQueuable(mapAccountIdNMarketoSegmentName,mapAccountIdNSegmentId);
        System.enqueueJob(accSegment);
        newAcc2.Segment_Name__c = seg2.Id;
        update newAcc2;
        ID jobID = System.enqueueJob(accSegment);
        Test.stopTest();
    }

}