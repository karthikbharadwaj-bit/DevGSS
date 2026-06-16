@isTest
private class Test_LeadQualificationSelector {
	//Lead fields defined
    private static final String LEAD_FIRST_NAME = 'Test';
    private static final String LEAD_LAST_NAME = 'Test';
    private static final String LEAD_EMAIL = 'testlead@test.com';
	
    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Lead qualifications or fields should be selected';
    
    @testSetup
    private static void testData(){
		Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => LEAD_FIRST_NAME,
                    Lead.LastName => LEAD_LAST_NAME,
                    Lead.Email => LEAD_EMAIL
                }
            )
            .create()
            .getRecord();

        Lead_Qualification__c lq = (Lead_Qualification__c) new SObjectBuilder(Lead_Qualification__c.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead_Qualification__c.Lead__c => testLead.Id
                }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectqualificationsForLeadConvert(){
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Lead_Qualification__c> qualificationsForLeadConvert = (List<Lead_Qualification__c>) new LeadQualificationSelector()
            .selectQualificationsForLeadConvert(leads[0].Id, 0, 5)
            .executeQuery();

        System.assert(qualificationsForLeadConvert.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectLeadQualificationsForBackendConvert(){
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Lead_Qualification__c> qualificationsForLeadConvert = (List<Lead_Qualification__c>) new LeadQualificationSelector(true, true)
            .selectQualificationsForLeadConvert(leads[0].Id, 0, 5)
            .executeQuery();
            
        List<Lead_Qualification__c> leadQualificationsForBackendConvert = (List<Lead_Qualification__c>) new LeadQualificationSelector()
            .selectLeadQualificationsForBackendConvert(new List<Object>{qualificationsForLeadConvert[0].Id})
            .executeQuery();

        System.assert(leadQualificationsForBackendConvert.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testGetFieldListForLeadConverting(){
        List<SObjectField> fieldListForLeadConverting = (List<SObjectField>) new LeadQualificationSelector().getFieldListForLeadConverting();
        
        System.assert(fieldListForLeadConverting.size() > 0, ASSERT_MESSAGE);
    }
}