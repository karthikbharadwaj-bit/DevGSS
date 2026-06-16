/*
* Description   : Test class for GatingAccountSegmentQueuable

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
@isTest
public class Test_GatingAccountSegmentQueuable {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test1() {
        Map<Id,String> mapAccountIdNMarketoSegmentName = new Map<Id,String>();
        Map<Id,String> mapAccountIdNSegmentId = new Map<Id,String>();
        Set<Id> accIds = new Set<Id>();
        Set<String> setCountryNames = new Set<String>();
    	Set<Decimal> setEmployeeNumbers = new Set<Decimal>();
        List<Account> accList = new List<Account>();
        List<Account> accList2 = new List<Account>();
        
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
        accList.add(newAcc);
        
        Account newAcc2 = new Account(Name = 'Test2', ParentId = newAcc.id, Segment_Name__c = seg.Id, Marketo_Segment_Name__c = 'SOHO');
        accList.add(newAcc2);
        
        Account newAcc3 = new Account(Name = 'Test3', ParentId = newAcc2.id, Segment_Name__c = seg.Id, Marketo_Segment_Name__c = 'SOHO');
        accList.add(newAcc3);
        
        Account newAcc4 = new Account(Name = 'Test4', ParentId = newAcc3.id, Segment_Name__c = seg2.Id, Marketo_Segment_Name__c = 'SOHO');
        accList.add(newAcc4);
        
        Account newAcc5 = new Account(Name = 'Test5', ParentId = newAcc4.id, Segment_Name__c = seg2.Id, Marketo_Segment_Name__c = 'SOHO');
        accList.add(newAcc5);
        
        insert accList;
        
        Map<Id, Account> mapfromaccList = new Map<Id, Account>(accList);
        
        
        for(Account acc:accList)
        {
            if(acc.NumberOfEmployees!=null) {
                acc.NumberOfEmployees=9;
            }
            accList2.add(acc);
        	accIds.add(acc.Id);
        }
        
        setCountryNames.add('United States');
        setEmployeeNumbers.add(10);
        Test.startTest();        
        GatingAccountSegmentQueuable uaq = new GatingAccountSegmentQueuable(accIds,setCountryNames,setEmployeeNumbers,mapfromaccList);
        ID jobID = System.enqueueJob(uaq);
        Test.stopTest();
    }
}