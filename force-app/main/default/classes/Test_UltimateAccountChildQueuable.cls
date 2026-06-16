/*
* Description   : Test class for UltimateAccountChildQueuable

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
@isTest
public class Test_UltimateAccountChildQueuable {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test1() {
        Map<Id,String> mapAccountIdNMarketoSegmentName = new Map<Id,String>();
        Map<Id,String> mapAccountIdNSegmentId = new Map<Id,String>();
        List<Account> accList = new List<Account>();
        
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
        
        Account newAcc = new Account(Name='Test');
        insert newAcc;
        accList.add(newAcc);
        
        Account newAcc2 = new Account(Name = 'Test2', ParentId = newAcc.id, Segment_Name__c = seg.Id, Marketo_Segment_Name__c = 'SOHO');
        insert newAcc2;
        accList.add(newAcc2);
        
        Account newAcc3 = new Account(Name = 'Test3', ParentId = newAcc2.id, Segment_Name__c = seg.Id, Marketo_Segment_Name__c = 'SOHO');
        insert newAcc3;
        accList.add(newAcc3);
        
        Account newAcc4 = new Account(Name = 'Test4', ParentId = newAcc3.id, Segment_Name__c = seg2.Id, Marketo_Segment_Name__c = 'SOHO');
        insert newAcc4;
        accList.add(newAcc4);
        
        Account newAcc5 = new Account(Name = 'Test5', ParentId = newAcc4.id, Segment_Name__c = seg2.Id, Marketo_Segment_Name__c = 'SOHO');
        insert newAcc5;
        accList.add(newAcc5);
        
        Map<Id, Account> mapfromaccList = new Map<Id, Account>(accList);
        
        Map<Id, String> testMap = new Map<Id, String>();
        testMap.put(newAcc.Id, String.valueof(newAcc.Id));
        testMap.put(newAcc2.Id, String.valueof(newAcc.Id));
        testMap.put(newAcc3.Id, String.valueof(newAcc2.Id));
        testMap.put(newAcc4.Id, String.valueof(newAcc3.Id));
        testMap.put(newAcc5.Id, String.valueof(newAcc4.Id));
        
        UltimateAccountChildQueuable uaq = new UltimateAccountChildQueuable(testMap,mapfromaccList);
        Test.startTest();
        System.enqueueJob(uaq);
        
        testMap.remove(newAcc2.Id);
        System.enqueueJob(uaq);
        
        testMap.remove(newAcc3.Id);
        System.enqueueJob(uaq);
        
        testMap.remove(newAcc4.Id);
        System.enqueueJob(uaq);
        Test.stopTest();
    }
}