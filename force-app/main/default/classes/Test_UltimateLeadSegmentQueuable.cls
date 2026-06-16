/*
* Description   : Test class for UltimateLeadSegmentQueuable

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
@isTest
public class Test_UltimateLeadSegmentQueuable {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testLeadSegment() {
        Map<Id,String> mapUltimateSMCountry = new Map<Id,String>();
        Map<Id,Double> mapUltimateSMEmp = new Map<Id,Double>();
        Map<Id,String> mapUltimateSegmentName = new Map<Id,String>();
        Map<Id,String> mapUltimateMarketoSegmentName = new Map<Id,String>();
        Map<Id,Lead> oldMap = new Map<Id,Lead>();
        Set<String> setCountryNames = new Set<String>();
    	Set<Decimal> setEmployeeNumbers = new Set<Decimal>();
        Set<Id> leadIds = new Set<Id>();
        List<Lead> leadList = new List<Lead>();
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User testUser = new User(
            Alias = 'standt',
            Email='standarduser757@testorg.com',
            EmailEncodingKey='UTF-8',
            LastName='Testing',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='standarduser757@testorg.com',
            isActive=true
        );
        insert testUser;

        Segment_Master__c seg = new Segment_Master__c();
        seg.Name = 'SOHO';
        seg.Max__c = 19;
        seg.Min__c = 1;
        seg.Country__c = 'United States';
        seg.Start_Date__c = System.today();
        insert seg;
        
        Account newAcc = new Account(Name='Test',Segment_Name__c=seg.Id,Marketo_Segment_Name__c='SOHO2');
        insert newAcc;
        
        mapUltimateSMCountry.put(newAcc.Id,'United States');
        mapUltimateSMEmp.put(newAcc.Id,10);
        mapUltimateSegmentName.put(newAcc.Id,seg.Id);
        mapUltimateMarketoSegmentName.put(newAcc.Id,'SOHO');
        
        Lead ld1 = new Lead(LastName='Test2',zi_cdp_account_id__c=newAcc.Id,Company='Test Company',email='test@test.com');
        leadList.add(ld1);
        insert leadList;
        for(Lead ld:leadList)
        {
            leadIds.add(ld.Id);
        }
        Map<Id, Lead> mapFromList = new Map<Id, Lead>(leadList);
        setCountryNames.add('United States');
        setEmployeeNumbers.add(10);
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Gating_Email_Addresses_List__c='test1@test.com,test2@test.com';
        insert processStage;
        
        Test.startTest();
        UltimateLeadSegmentQueuable ultimateLeadSegment = new UltimateLeadSegmentQueuable(leadIds,mapUltimateSMCountry,mapUltimateSMEmp,mapUltimateSegmentName,mapUltimateMarketoSegmentName,mapFromList);
        ID jobID = System.enqueueJob(ultimateLeadSegment);
        UltimateLeadSegmentQueuable.sendOwnerMail(testUser.Id ,ld1.Id);
        Test.stopTest();
    }

}