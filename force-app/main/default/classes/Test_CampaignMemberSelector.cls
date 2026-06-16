@isTest
private class Test_CampaignMemberSelector {
	//Account fields defined 
    private static final String ACCOUNT_NAME = 'Test';

    //Contact fields defined
    private static final String CONTACT_FIRST_NAME = 'Test';
    private static final String CONTACT_LAST_NAME = 'Test';
    private static final String CONTACT_EMAIL = 'test@test.com';
    private static final String CONTACT_PHONE = '1234567890';
    private static final String CONTACT_PREFFERED_LANGUAGE = 'en_US';

    //Lead fields defined
    private static final String LEAD_FIRST_NAME = 'Test';
    private static final String LEAD_LAST_NAME = 'Test';
    private static final String LEAD_EMAIL = 'testlead@test.com';
	
    //Campaign fields defined
    private static final String CAMPAIGN_NAME = 'Test';
    
    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Campaign members should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong campaign member selected';

    @testSetup
    private static void testData(){
         Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test'
                }
            )
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_LAST_NAME,
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.Phone => CONTACT_PHONE,
                    Contact.Preferred_Language__c => CONTACT_PREFFERED_LANGUAGE
                }
            )
            .create()
            .getRecord();
        
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
        
        Campaign testCamp = (Campaign) new SObjectBuilder(Campaign.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Campaign.Name => CAMPAIGN_NAME
                }
            )
            .create()
            .getRecord();
        
        CampaignMember testCampMember = (CampaignMember) new SObjectBuilder(CampaignMember.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    CampaignMember.CampaignId => testCamp.Id,
                    CampaignMember.ContactId => testContact.Id,
                    CampaignMember.LeadId => testLead.Id
                }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectCampaignMemberForLeadConvert(){
        List<CampaignMember> campaignMemberForLeadConvert = (List<CampaignMember>) new CampaignMemberSelector(true, true)
            .selectCampaignMemberForLeadConvert()
            .executeQuery();   
        
        System.assert(campaignMemberForLeadConvert.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectCampaignMemberForOpportunityMethods(){
        List<CampaignMember> campaignMemberForLeadConvert = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery(); 
        
        List<CampaignMember> campaignMemberForOpportunityMethods = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForOpportunityMethods(new List<Object>{new Set<Id>{campaignMemberForLeadConvert[0].ContactId}})
            .executeQuery();  
        
        System.assert(campaignMemberForOpportunityMethods.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(campaignMemberForLeadConvert[0].Id, campaignMemberForOpportunityMethods[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectCampaignMemberByLeadAndCampaignIds(){
        List<CampaignMember> campaignMemberForLeadConvert = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery(); 
        
        List<CampaignMember> campaignMemberByLeadAndCampaignIds = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(new List<Object>{new Set<Id>{campaignMemberForLeadConvert[0].LeadId},
                													new Set<Id>{campaignMemberForLeadConvert[0].CampaignId}})
            .executeQuery();   
        
        System.assert(campaignMemberByLeadAndCampaignIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(campaignMemberForLeadConvert[0].Id, campaignMemberByLeadAndCampaignIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectCampaignMemberByContactAndCampaignIds(){
        List<CampaignMember> campaignMemberForLeadConvert = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery(); 

        List<CampaignMember> campaignMemberByContactAndCampaignIds = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByContactAndCampaignIds(new List<Object>{new Set<Id>{campaignMemberForLeadConvert[0].ContactId},
                														  new Set<Id>{campaignMemberForLeadConvert[0].CampaignId}})
            .executeQuery(); 
        
        System.assert(campaignMemberByContactAndCampaignIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(campaignMemberForLeadConvert[0].Id, campaignMemberByContactAndCampaignIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }
	
    @isTest
    private static void testSelectCampaignMembersByLeadAndCampaignORByContactAndCampaign(){
        List<CampaignMember> campaignMemberForLeadConvert = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery(); 
        
        List<CampaignMember> campaignMembersByLeadAndCampaignORByContactAndCampaign = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMembersByLeadAndCampaignORByContactAndCampaign(new List<Object>{new Set<Id>{campaignMemberForLeadConvert[0].LeadId},
                														  				   new Set<Id>{campaignMemberForLeadConvert[0].CampaignId},
                                                                                           new Set<Id>{campaignMemberForLeadConvert[0].ContactId}})
            .executeQuery();   
        
        System.assert(campaignMembersByLeadAndCampaignORByContactAndCampaign.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(campaignMemberForLeadConvert[0].Id, campaignMembersByLeadAndCampaignORByContactAndCampaign[0].Id, ASSERT_EQUALS_MESSAGE);
    }
}