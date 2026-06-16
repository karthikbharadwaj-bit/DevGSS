@isTest
private class Test_DemandFunnelSelector {
	//Account feilds defined
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_ID = '12345';
    
    //Contact fields defined
    private static final String CONTACT_FL_NAME = 'Test1';
    private static final String CONTACT_EMAIL = 'test@test.com';
    private static final String CONTACT_PHONE = '1234567890';
    private static final String CONTACT_PREFFERED_LANGUAGE = 'en_US';

    //Opportunity fields defined
    private static final String OPPORTUNITY_NAME = 'TestOpportunity';
    private static final String OPPORTUNITY_NAME_BRAND = 'RingCentral';
    private static final String OPPORTUNITY_NAME_TIER = 'Office';
    private static final String OPPORTUNITY_NAME_STAGE = '1. Qualify';
    private static final String OPPORTUNITY_CURRENCY_ISO_CODE = 'USD';

    //Lead fields defined
    private static final String LEAD_FL_NAME = 'Test';
    private static final String LEAD_EMAIL = 'testlead@test.com';

    //Demand funnel fields defined
    private static final String DEMAND_FUNNEL_CONTACT_EMAIL_ON_CREATION = 'test@test.com';
    private static final String DEMAND_FUNNEL_PRE_OPPORTUNITY_CLOSE_REASON = 'Test';

    //Assert message defined
    private static final String ASSERT_MESSAGE = 'Demand funnels should be selected';

    @testsetup
    private static void testData(){
        
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.Billing_ID__c => ACCOUNT_BILLING_ID
                }
            )
            .create()
            .getRecord();
        
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CONTACT_FL_NAME,
                    Contact.LastName => CONTACT_FL_NAME,
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.Phone => CONTACT_PHONE,
                    Contact.Preferred_Language__c => CONTACT_PREFFERED_LANGUAGE
                }
            )
            .build()
            .getRecord();
        
        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
            		Opportunity.AccountId => testAcc.Id,
            		Opportunity.Name => OPPORTUNITY_NAME,
            		Opportunity.Brand_Name__c => OPPORTUNITY_NAME_BRAND,
            		Opportunity.Tier_Name__c => OPPORTUNITY_NAME_TIER,
            		Opportunity.StageName => OPPORTUNITY_NAME_STAGE,
            		Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
					}
            )
            .create()
            .getRecord();
        
        Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => LEAD_FL_NAME,
                    Lead.LastName => LEAD_FL_NAME,
                    Lead.Email => LEAD_EMAIL
                }
            )
            .create()
            .getRecord();

        Demand_Funnel__c testDemandFunnel = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Demand_Funnel__c.Account__c => testAcc.Id,
                    Demand_Funnel__c.Lead__c => testLead.Id,
                    Demand_Funnel__c.Contact_Email_on_Creation__c => DEMAND_FUNNEL_CONTACT_EMAIL_ON_CREATION,
                    Demand_Funnel__c.Contact__c => testContact.Id, 
                    Demand_Funnel__c.Opportunity__c => testOpp.Id,
                    Demand_Funnel__c.Pre_Opportunity_Close_Reason__c => DEMAND_FUNNEL_PRE_OPPORTUNITY_CLOSE_REASON
                }
            )
            .create()
            .getRecord();
        
    }
    
    @isTest
    private static void testSelectDFRForTQLUpdate(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRForTQLUpdate = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForTQLUpdate(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        System.assert(dFRForTQLUpdate.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectDFRByLeadIds(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRByLeadIds = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByLeadIds(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        System.assert(dFRByLeadIds.size() > 0, ASSERT_MESSAGE);
    }   
    
    @isTest
    private static void testSelectDFRByLeadIdsAndPreOpportunityReasonNull(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRByLeadIdsAndPreOpportunityReasonNull = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByLeadIdsAndPreOpportunityReasonNull(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        System.assert(dFRByLeadIdsAndPreOpportunityReasonNull.size() > 0, ASSERT_MESSAGE);
    }   
    
    @isTest
    private static void testSelectDFRByOpportunittiesIdAndPreOpportunityReasonNull(){
    	List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery();
            
        List<Demand_Funnel__c> dFRByOpportunittiesIdAndPreOpportunityReasonNull = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByOpportunittiesIdAndPreOpportunityReasonNull(new List<Object>{new Set<Id>{opportunities[0].Id}})
            .executeQuery();

        System.assert(dFRByOpportunittiesIdAndPreOpportunityReasonNull.size() > 0, ASSERT_MESSAGE);
    }  

	@isTest
    private static void testSelectDFRByOpportunitiesId(){
    	List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery();
            
        List<Demand_Funnel__c> dFRByOpportunitiesId = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByOpportunitiesId(new List<Object>{new Set<Id>{opportunities[0].Id}})
            .executeQuery();

        System.assert(dFRByOpportunitiesId.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectDFRById(){
    	List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery();
            
        List<Demand_Funnel__c> dFRByOpportunitiesId = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByOpportunitiesId(new List<Object>{new Set<Id>{opportunities[0].Id}})
            .executeQuery();

        List<Demand_Funnel__c> testSelectDFRById = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRById(new List<Object>{new Set<Id>{dFRByOpportunitiesId[0].Id}})
            .executeQuery();

        System.assert(testSelectDFRById.size() > 0, ASSERT_MESSAGE);
    }  
    
    @isTest
    private static void testSelectDFRByIds(){
    	Demand_Funnel__c testDF = [SELECT Id FROM Demand_Funnel__c WHERE Contact_Email_on_Creation__c = 'test@test.com' LIMIT 1];
        List<Demand_Funnel__c> testSelectDFRByIds = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new List<Object>{new Set<Id>{testDF.Id}})
            .executeQuery();

        System.assert(testSelectDFRByIds.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testSelectDFRForUpdatingIntendedBrandFieldValue(){
    	List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery();
            
        List<Demand_Funnel__c> dFRByOpportunitiesId = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByOpportunitiesId(new List<Object>{new Set<Id>{opportunities[0].Id}})
            .executeQuery();

        List<Demand_Funnel__c> dFRForUpdatingIntendedBrandFieldValue = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForUpdatingIntendedBrandFieldValue(new List<Object>{new Set<Id>{dFRByOpportunitiesId[0].Id}})
            .executeQuery();

        System.assert(dFRForUpdatingIntendedBrandFieldValue.size() > 0, ASSERT_MESSAGE);
    } 

    @isTest
    private static void testSelectDFRByLeadID(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRByLeadID = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByLeadID(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        System.assert(dFRByLeadID.size() > 0, ASSERT_MESSAGE);
    }  
        
    @isTest
    private static void testSelectDFRByOpportunityID(){
    	List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery();

        List<Demand_Funnel__c> dFRByOpportunityID = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByOpportunityID(new List<Object>{new Set<Id>{opportunities[0].Id}})
            .executeQuery();

        System.assert(dFRByOpportunityID.size() > 0, ASSERT_MESSAGE);
    } 

    @isTest
    private static void testSelectDFRByLeadList(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRByLeadList = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByLeadList(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        System.assert(dFRByLeadList.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testSelectMQLOwnersByLeadID(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> mQLOwnersByLeadID = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectMQLOwnersByLeadID(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        System.assert(mQLOwnersByLeadID.size() > 0, ASSERT_MESSAGE);
    } 

    @isTest
    private static void testSelectDFRForMarketingAssetProcessing(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRForRelatedList = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForRelatedList(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        List<Demand_Funnel__c> dFRByLeadAccountOrOpportunity = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByLeadAccountOrOpportunity(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();
        
        List<Demand_Funnel__c> dFRForMarketingAssetProcessing = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForMarketingAssetProcessing(new List<Object>{new Set<Id>{dFRByLeadAccountOrOpportunity[0].Lead__c}, 
                                                                   new Set<Id>{dFRForRelatedList[0].Contact__c}, 
                                                                   new Set<Id>{dFRByLeadAccountOrOpportunity[0].Opportunity__c}, 
                                                                   new Set<Id>{dFRByLeadAccountOrOpportunity[0].Account__c}})
            .executeQuery();

        System.assert(dFRForMarketingAssetProcessing.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testSelectActiveDFRByContactId(){
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRForRelatedList = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForRelatedList(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        List<Demand_Funnel__c> activeDFRByContactId = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectActiveDFRByContactId(new List<Object>{new Set<Id>{dFRForRelatedList[0].Contact__c}})
            .executeQuery();

        System.assert(activeDFRByContactId.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testSelectDFRByContact(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRForRelatedList = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForRelatedList(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        List<Demand_Funnel__c> dFRByContact = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByContact(new List<Object>{new Set<Id>{dFRForRelatedList[0].Contact__c}})
            .executeQuery();

        System.assert(dFRByContact.size() > 0, ASSERT_MESSAGE);
    } 

    @isTest
    private static void testSelectDFRByContactTest(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRForRelatedList = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForRelatedList(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        List<Demand_Funnel__c> dFRByContactTest = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByContactTest(new List<Object>{new Set<Id>{dFRForRelatedList[0].Contact__c}})
            .executeQuery();

        System.assert(dFRByContactTest.size() > 0, ASSERT_MESSAGE);
    } 

	@isTest
    private static void testSelectDFRByLeadAccountOrOpportunity(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRByLeadAccountOrOpportunity = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByLeadAccountOrOpportunity(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        System.assert(dFRByLeadAccountOrOpportunity.size() > 0, ASSERT_MESSAGE);
    } 

    @isTest
    private static void testSelectActiveDFRForConvertLead(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> activeDFRForConvertLead = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectActiveDFRForConvertLead(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        System.assert(activeDFRForConvertLead.size() > 0, ASSERT_MESSAGE);
    } 
    
	@isTest
    private static void testSelectActiveDFRByContactIdForOwnerChange(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRForRelatedList = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForRelatedList(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        List<Demand_Funnel__c> activeDFRByContactIdForOwnerChange = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectActiveDFRByContactIdForOwnerChange(new List<Object>{new Set<Id>{dFRForRelatedList[0].Contact__c}})
            .executeQuery();

        System.assert(activeDFRByContactIdForOwnerChange.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testSelectDFRForRelatedList(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRForRelatedList = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForRelatedList(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        System.assert(dFRForRelatedList.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testSelectDFRForAccountUpdate(){
        List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery();

        List<Demand_Funnel__c> dFRForAccountUpdate = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForAccountUpdate(new List<Object>{new Set<Id>{opportunities[0].Id}})
            .executeQuery();

        System.assert(dFRForAccountUpdate.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testSelectDFRByLeadOrContact(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRForRelatedList = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForRelatedList(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();

        List<Demand_Funnel__c> dFRByLeadOrContact = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByLeadOrContact(new List<Object>{new Set<Id>{dFRForRelatedList[0].Contact__c}})
            .executeQuery();

        System.assert(dFRByLeadOrContact.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testSelectActiveDFRByOpportunitiesId(){
    	List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery();

        List<Demand_Funnel__c> activeDFRByOpportunitiesId = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectActiveDFRByOpportunitiesId(new List<Object>{new Set<Id>{opportunities[0].Id}})
            .executeQuery();

        System.assert(activeDFRByOpportunitiesId.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void selectDFRForUpdateFields(){
    	Datetime startDate = Datetime.newInstance(2020, 12, 12);

        List<Demand_Funnel__c> dFRForUpdateFields = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForUpdateFields(new List<Datetime>{startDate}, false, false, false, false)
            .executeQuery();

        System.assert(dFRForUpdateFields.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectDFRForUpdateFieldsBetweenDates(){
		Datetime startDate = Datetime.newInstance(2020, 12, 12);
    	Datetime endDate = Datetime.newInstance(2030, 12, 14);
        
        List<Demand_Funnel__c> dFRForUpdateFieldsBetweenDates = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForUpdateFieldsBetweenDates(new List<Datetime>{startDate, 
                												 	 endDate}, 
                                                  false, 
                                                  false, 
                                                  false, 
                                                  false)
            .executeQuery();

        System.assert(dFRForUpdateFieldsBetweenDates.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectDFRForAddOpportunity(){
    	List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        List<Demand_Funnel__c> dFRForRelatedList = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForRelatedList(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();
        
        List<Demand_Funnel__c> dFRForAddOpportunity = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForAddOpportunity(new List<Object>{new Set<Id>{dFRForRelatedList[0].Contact__c}})
            .executeQuery();

        System.assert(dFRForAddOpportunity.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testSelectDFRToFixIntendedBrandFieldValue(){
		Datetime startDate = Datetime.newInstance(2021, 12, 12);
    	Datetime endDate = Datetime.newInstance(2030, 12, 14);
        
        List<Demand_Funnel__c> dFRToFixIntendedBrandFieldValue = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRToFixIntendedBrandFieldValue(new List<Object>{startDate,endDate})
            .executeQuery();

        System.assert(dFRToFixIntendedBrandFieldValue.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testSelectDFRForFixAccountField(){
		Datetime startDate = Datetime.newInstance(2021, 12, 12);
    	Datetime endDate = Datetime.newInstance(2030, 12, 14);
        
        List<Demand_Funnel__c> dFRForFixAccountField = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRForFixAccountField(new List<Object>{new Set<Datetime>{startDate},
                										  new Set<Datetime>{endDate}})
            .executeQuery();

        System.assert(dFRForFixAccountField.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testSelectDFRForFixSMEmployeeField(){
		Datetime startDate = Datetime.newInstance(2021, 12, 12);
    	Datetime endDate = Datetime.newInstance(2030, 12, 14);
        
        List<Demand_Funnel__c> dFRForFixSMEmployeeField = (List<Demand_Funnel__c>) new DemandFunnelSelector(true, true)
            .selectDFRForFixSMEmployeeField(new List<Object>{startDate, endDate})
            .executeQuery();

        System.assert(dFRForFixSMEmployeeField.size() > 0, ASSERT_MESSAGE);
    } 
    
    @isTest
    private static void testGetTALFields(){
        List<Schema.SObjectField> tALFields = (List<Schema.SObjectField>) new DemandFunnelSelector().getTALFields();
        
        System.assert(tALFields.size() > 0);
    }
    
    @isTest
    private static void testselectDFRsForSALHandOff(){
        // Create a test Lead record
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'testlead@test.com'
        );
        insert lead;

        // Create a test Demand_Funnel__c record
        Demand_Funnel__c dfr = new Demand_Funnel__c(
            Lead__c = lead.Id,
            Intended_Brand__c = 'Test Brand',
            SAL_Handoff_Date__c = Date.today(),
            SAL_DateTime_Exited__c = null,
            SAL_DateTime_Entered__c = Date.today()
        );
        insert dfr;

        // Select the test Demand_Funnel__c record using the DFR Selector
        List<Demand_Funnel__c> dfrForSALHandOff = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRsForSALHandoff(new Set<Id>{lead.Id})
            .executeQuery();

        // Assert that the selected Demand_Funnel__c record matches the queried record
        System.assertEquals(dfr.Id, dfrForSALHandOff[0].Id);
        System.assertEquals(dfr.Lead__c, dfrForSALHandOff[0].Lead__c);
        System.assertEquals(dfr.SAL_Handoff_Date__c, dfrForSALHandOff[0].SAL_Handoff_Date__c);
    }

    @isTest
    private static void testSelectDFRsForDowngrade() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'AccName',
                    Account.Billing_ID__c => '121241'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'TEst',
                    Contact.LastName => 'LName',
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'test@te.com',
                    Contact.Phone => '123134123',
                    Contact.Contact_Status__c => '2. Contacted'
                }
            )
            .create()
            .getRecord();
        Test.stopTest();
        
        List<Demand_Funnel__c> dfrsForDowngrade = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRsForDowngrade(new List<Object>{datetime.now().addDays(1)})
            .executeQuery();

        // Assert that the selected Demand_Funnel__c record matches the queried record
        System.assert(dfrsForDowngrade.size() > 0, 'A dfr should have been found');
    }

}