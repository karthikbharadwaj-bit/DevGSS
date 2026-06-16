@isTest
public class Test_LeadSpace_LeadTrigger {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    public static void Test_Trigger() {
        
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Bypass_Gating_Process_Stage__c = false;
        processStage.Bypass_Enrichment_Process__c = false;
        insert processStage;
        
        Lead l = new Lead(FirstName='Test', LastName='Test', Company='testory', Email='test@ttt.com',LS_Enrichment_Date__c=System.today());
        insert l;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void Test_Trigger_1() {
        
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Bypass_Gating_Process_Stage__c = false;
        processStage.Gating_Lead_Source__c = 'ZoomInfo';
        insert processStage;
        
        Lead l = new Lead(FirstName='Test', LastName='Test', Company='testory', Email='test@ttt.com',LeadSource='ZoomInfo');
        insert l;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void Test_Trigger_2() {
        
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Bypass_Gating_Process_Stage__c = false;
        processStage.Bypass_Enrichment_Process__c = false;
        insert processStage;
        
        Lead l = new Lead(FirstName='Test', LastName='Test', Company='testory', Email='test@ttt.com');
        insert l;
        
        System.enqueueJob(new LeadspaceEnrichmentQueueable(JSON.serialize(l)));
    }
}