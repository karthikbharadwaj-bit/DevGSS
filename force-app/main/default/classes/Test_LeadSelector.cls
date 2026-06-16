@isTest
private class Test_LeadSelector {
    
    //Marketing asset fields defined 
    private static final String MARKETING_ASSET_NAME = 'Test';
    private static final String MARKETING_ASSET_ASSET_TITLE = 'Test';
        
    //Campaign fields defined
    private static final String CAMPAIGN_NAME = 'Test';
    private static final String CAMPAIGN_CATEGORY = 'TestCategory';
        
    //Lead fields defined
    private static final String LEAD_FIRST_NAME = 'Test';
    private static final String LEAD_LAST_NAME = 'Test';
    private static final String LEAD_EMAIL = 'testlead@test.com';
    private static final String LEAD_ZI_CDP_ACCOUNT_ID_FROM_LS4SF = 'test';
    private static final String SAASQUATCH_REFERRAL_CODE = 'Saasq-Ref-Code';
    
    
    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Leads should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong lead selected';
        
    @testSetup
    private static void testData(){
        Marketing_Asset__c  testMA = (Marketing_Asset__c ) new SObjectBuilder(Marketing_Asset__c.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Marketing_Asset__c.Name => MARKETING_ASSET_NAME,
                    Marketing_Asset__c.Asset_Title__c  => MARKETING_ASSET_ASSET_TITLE
                }
            )
            .create()
            .getRecord();
        
        Campaign  testCamp = (Campaign ) new SObjectBuilder(Campaign.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Campaign.Name => CAMPAIGN_NAME,
                    Campaign.Category__c   => CAMPAIGN_CATEGORY
                }
            )
            .create()

            .getRecord();
        
		Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => LEAD_FIRST_NAME,
                    Lead.LastName => LEAD_LAST_NAME,
                    Lead.Email => LEAD_EMAIL,
                    Lead.Most_Recent_Asset__c => testMA.Id,
                    Lead.ZI_CDP_AccountId_From_LS4SF__c => LEAD_ZI_CDP_ACCOUNT_ID_FROM_LS4SF,
                    Lead.Most_Recent_Campaign__c => testCamp.Id,
                    Lead.saasquatch__Referral_Code__c => SAASQUATCH_REFERRAL_CODE 
                }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectLeadForConvert(){
        List<Lead> leadByLastName = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(new List<Object>{new Set<String>{LEAD_LAST_NAME}})
            .executeQuery();

        List<Lead> leadForConvert = (List<Lead>) new LeadSelector()
            .selectLeadForConvert(new List<Object>{new Set<Id>{leadByLastName[0].Id}})
            .executeQuery();
        
        System.assertEquals(1, leadForConvert.size(), ASSERT_MESSAGE);
        System.assertEquals(leadByLastName[0].Id, leadForConvert[0].Id, ASSERT_EQUALS_MESSAGE);
    }

	@isTest
    private static void testSelectLeadById(){
        List<Lead> leadByLastName = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(new List<Object>{new Set<String>{LEAD_LAST_NAME}})
            .executeQuery();

        List<Lead> leadById = (List<Lead>) new LeadSelector()
            .selectLeadById(new List<Object>{new Set<Id>{leadByLastName[0].Id}})
            .executeQuery();
        
        System.assertEquals(1, leadById.size(), ASSERT_MESSAGE);
        System.assertEquals(leadByLastName[0].Id, leadById[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectLeads(){
        List<Lead> leads = (List<Lead>) new LeadSelector(true, true)
            .selectLeads()
            .executeQuery();
        
        System.assertEquals(1, leads.size(), ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectLeadsByIds(){
        List<Lead> leadByLastName = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(new List<Object>{new Set<String>{LEAD_LAST_NAME}})
            .executeQuery();
            
        List<Lead> leadsByIds = (List<Lead>) new LeadSelector()
            .selectLeadsByIds(new List<Object>{new Set<Id>{leadByLastName[0].Id}})
            .executeQuery();
        
        System.assertEquals(1, leadsByIds.size(), ASSERT_MESSAGE);
        System.assertEquals(leadByLastName[0].Id, leadsByIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectLeadByLastName(){            
        List<Lead> leadByLastName = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(new List<Object>{new Set<String>{LEAD_LAST_NAME}})
            .executeQuery();
        
        System.assertEquals(1, leadByLastName.size(), ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectLeadsWithAssetTouches(){
        List<Lead> leadByLastName = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(new List<Object>{new Set<String>{LEAD_LAST_NAME}})
            .executeQuery();
            
        List<Lead> leadsWithAssetTouches = (List<Lead>) new LeadSelector()
            .selectLeadsWithAssetTouches(new List<Object>{new Set<Id>{leadByLastName[0].Id}})
            .executeQuery();
        
        System.assertEquals(1, leadsWithAssetTouches.size(), ASSERT_MESSAGE);
        System.assertEquals(leadByLastName[0].Id, leadsWithAssetTouches[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectLeadWithCampaignFields(){
        List<Lead> leadByLastName = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(new List<Object>{new Set<String>{LEAD_LAST_NAME}})
            .executeQuery();
        
        List<Lead> leadWithCampaignFields = (List<Lead>) new LeadSelector()
            .selectLeadWithCampaignFields(new List<Object>{new Set<Id>{leadByLastName[0].Id}})
            .executeQuery();
        
        System.assertEquals(1, leadWithCampaignFields.size(), ASSERT_MESSAGE);
        System.assertEquals(leadByLastName[0].Id, leadWithCampaignFields[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectLeadByIdAndMostRecentCampaign(){
    	List<Lead> leadByLastName = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(new List<Object>{new Set<String>{LEAD_LAST_NAME}})
            .executeQuery();

        List<Campaign> campaignsByName = (List<Campaign>) new CampaignSelector()
            .selectCampaignsByName(new List<Object>{new Set<String>{CAMPAIGN_NAME}})
            .executeQuery();
        
        List<Lead> leadByIdAndMostRecentCampaign = (List<Lead>) new LeadSelector()
            .selectLeadByIdAndMostRecentCampaign(new List<Object>{new Set<Id>{leadByLastName[0].Id},
                												  new Set<Id>{campaignsByName[0].Id}})
            .executeQuery();
        
        System.assertEquals(1, leadByIdAndMostRecentCampaign.size(), ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectShortDataLead(){
    	List<Lead> leadByLastName = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(new List<Object>{new Set<String>{LEAD_LAST_NAME}})
            .executeQuery();
        
        List<Lead> shortDataLead = (List<Lead>) new LeadSelector()
            .selectShortDataLead(new List<Object>{new Set<Id>{leadByLastName[0].Id}})
            .executeQuery();
        
        System.assertEquals(1, shortDataLead.size(), ASSERT_MESSAGE);
        System.assertEquals(leadByLastName[0].Id, shortDataLead[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectLeadsByIdsForSaasquatchEmailing(){
    	List<Lead> leadByLastName = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(new List<Object>{new Set<String>{LEAD_LAST_NAME}})
            .executeQuery();
        
        List<String> LeadsIds = new List<String>();
        LeadsIds.add(leadByLastName[0].Id);

        List<Lead> saasquatchLead = (List<Lead>) new LeadSelector()
            .selectLeadsByIdsForSaasquatchEmailing(new List<Object>{LeadsIds})
            .executeQuery();
        
        System.assertEquals(1, saasquatchLead.size(), ASSERT_MESSAGE);
    }
}