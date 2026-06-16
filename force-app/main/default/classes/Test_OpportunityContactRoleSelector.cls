@isTest
private class Test_OpportunityContactRoleSelector {
    //Account fields defined 
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_ID = '12345';
    
    //Opportunity fields defined
    private static final String OPPORTUNITY_NAME = 'TestOpportunity';
    private static final String OPPORTUNITY_BRAND_NAME = 'RingCentral';
    private static final String OPPORTUNITY_TIER_NAME = 'Office';
    private static final String OPPORTUNITY_STAGE_NAME = '7. Closed Won';
    private static final String OPPORTUNITY_STAGE_NAME_QUALIFY = '1. Qualify';
    private static final String OPPORTUNITY_CURRENCY_ISO_CODE = 'USD';
        
    //Contact fields defined
    private static final String CONTACT_FIRST_NAME = 'Test';
    private static final String CONTACT_LAST_NAME = 'Test';
    private static final String CONTACT_EMAIL = 'test@test.com';
    private static final String CONTACT_PHONE = '1234567890';
    private static final String CONTACT_PREFFERED_LANGUAGE = 'en_US';
    
	//Assert messages defined
	private static final String ASSERT_MESSAGE = 'Opportunity contact roles should be selected';

    @testSetup
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
        
        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
            		Opportunity.AccountId => testAcc.Id,
            		Opportunity.Name => OPPORTUNITY_NAME,
            		Opportunity.Brand_Name__c => OPPORTUNITY_BRAND_NAME,
            		Opportunity.Tier_Name__c => OPPORTUNITY_TIER_NAME,
            		Opportunity.StageName => OPPORTUNITY_STAGE_NAME,
                    Opportunity.CloseDate => Date.newInstance(2022, 12, 17),
            		Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
					}
            )
            .create()
            .getRecord();
        
        Opportunity testOppQualify = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
            		Opportunity.AccountId => testAcc.Id,
            		Opportunity.Name => OPPORTUNITY_NAME,
            		Opportunity.Brand_Name__c => OPPORTUNITY_BRAND_NAME,
            		Opportunity.Tier_Name__c => OPPORTUNITY_TIER_NAME,
            		Opportunity.StageName => OPPORTUNITY_STAGE_NAME_QUALIFY,
            		Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
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
                    Contact.Contact_Status__c => '2. Contacted',
                    Contact.Preferred_Language__c => CONTACT_PREFFERED_LANGUAGE
                }
            )
            .create()
            .getRecord();
        
         OpportunityContactRole testOCR = (OpportunityContactRole) new SobjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
            		OpportunityContactRole.ContactId  => testContact.Id,   
                    OpportunityContactRole.OpportunityId => testOpp.Id,
                    OpportunityContactRole.isPrimary => TRUE,
                    OpportunityContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY
					}
            )
            .create()
            .getRecord();  
        
        OpportunityContactRole testOCRQualify = (OpportunityContactRole) new SobjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
            		OpportunityContactRole.ContactId  => testContact.Id,   
                    OpportunityContactRole.OpportunityId => testOppQualify.Id,
                    OpportunityContactRole.isPrimary => TRUE,
                    OpportunityContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY
					}
            )
            .create()
            .getRecord(); 
    }
    
    @isTest
    private static void testSelectOpportunityContactRoles(){
        List<OpportunityContactRole> opportunityContactRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector(true, true)
                .selectOpportunityContactRoles()
                .executeQuery();
       	
        System.assert(opportunityContactRoles.size() > 0, ASSERT_MESSAGE );
    }
    
    @isTest
    private static void testSelectOCRForLeadConvert(){
        List<OpportunityContactRole> opportunityContactRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRoles()
                .executeQuery();

        List<OpportunityContactRole> oCRForLeadConvert = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
            	.selectOCRForLeadConvert(new List<Object>{new Set<Id>{opportunityContactRoles[0].OpportunityId},
                									  	  new Set<Id>{opportunityContactRoles[0].ContactId}})
                .executeQuery();
        
        System.assert(oCRForLeadConvert.size() > 0, ASSERT_MESSAGE );
    }
    
    @isTest
    private static void testSelectOpportunityContactRolesByOppId(){
        List<OpportunityContactRole> opportunityContactRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRoles()
                .executeQuery();

        List<OpportunityContactRole> opportunityContactRolesByOppId = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRolesByOppId(new List<Object>{new Set<Id>{opportunityContactRoles[0].OpportunityId}})
                .executeQuery();

        System.assert(opportunityContactRolesByOppId.size() > 0, ASSERT_MESSAGE );
    }
    
    @isTest
    private static void testSelectPrimaryOpportunityContactRolesByOppIds(){
        List<OpportunityContactRole> opportunityContactRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRoles()
                .executeQuery();

        List<OpportunityContactRole> primaryOpportunityContactRolesByOppIds = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectPrimaryOpportunityContactRolesByOppIds(new List<Object>{new Set<Id>{opportunityContactRoles[0].OpportunityId}})
                .executeQuery();

        System.assert(primaryOpportunityContactRolesByOppIds.size() > 0, ASSERT_MESSAGE );
    }
    
    @isTest
    private static void testSelectOCRForOpportunityClose(){
        List<OpportunityContactRole> opportunityContactRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRoles()
                .executeQuery();
                
        List<OpportunityContactRole> oCRForOpportunityClose = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOCRForOpportunityClose(new List<Object>{new Set<Id>{opportunityContactRoles[0].OpportunityId}})
                .executeQuery();

        System.assert(oCRForOpportunityClose.size() > 0, ASSERT_MESSAGE );
    }

    @isTest
    private static void testSelectOpportunityContactRolesByListOppIds(){
        List<OpportunityContactRole> opportunityContactRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRoles()
                .executeQuery();

        List<OpportunityContactRole> opportunityContactRolesByListOppIds = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRolesByListOppIds(new List<Object>{new Set<Id>{opportunityContactRoles[0].OpportunityId}})
                .executeQuery();

        System.assert(opportunityContactRolesByListOppIds.size() > 0, ASSERT_MESSAGE );
    }
    
    @isTest
    private static void testSelectOCRWhereOpportunityIsOpenAndContactIdMatchesAndIsPrimary(){
        List<OpportunityContactRole> opportunityContactRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRoles()
                .executeQuery();

        List<OpportunityContactRole> oCRWhereOpportunityIsOpenAndContactIdMatchesAndIsPrimary = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOCRWhereOpportunityIsOpenAndContactIdMatchesAndIsPrimary(new List<Object>{new Set<Id>{opportunityContactRoles[1].ContactId}})
                .executeQuery();

        System.assert(oCRWhereOpportunityIsOpenAndContactIdMatchesAndIsPrimary.size() > 0, ASSERT_MESSAGE );
    }

    @isTest
    private static void testSelectOpportunityContactRolesByListConIds(){
        List<OpportunityContactRole> opportunityContactRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRoles()
                .executeQuery();

        List<OpportunityContactRole> opportunityContactRolesByListConIds = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRolesByListConIds(new List<Object>{new Set<Id>{opportunityContactRoles[0].ContactId}})
                .executeQuery();

        System.assert(opportunityContactRolesByListConIds.size() > 0, ASSERT_MESSAGE );
    }
        
    @isTest
    private static void testSelectOppConRolesByListConIdsAndListOppIds(){
        List<OpportunityContactRole> opportunityContactRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRoles()
                .executeQuery();

        List<OpportunityContactRole> oppConRolesByListConIdsAndListOppIds = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
            	.selectOppConRolesByListConIdsAndListOppIds(new List<Object>{new Set<Id>{opportunityContactRoles[0].OpportunityId},
                									  	  					 new Set<Id>{opportunityContactRoles[0].ContactId}})
                .executeQuery();

        System.assert(oppConRolesByListConIdsAndListOppIds.size() > 0, ASSERT_MESSAGE );
    }
    
    @isTest
    private static void testSelectOCRbyContactsId(){
        List<OpportunityContactRole> opportunityContactRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRoles()
                .executeQuery();

        List<OpportunityContactRole> oCRbyContactsId = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOCRbyContactsId(new List<Object>{new Set<Id>{opportunityContactRoles[0].ContactId}})
                .executeQuery();

        System.assert(oCRbyContactsId.size() > 0, ASSERT_MESSAGE );
    }
    
    @isTest
    private static void testSelectOppConRolesWithClosedWonOppbyContactsId(){
        List<OpportunityContactRole> opportunityContactRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRoles()
                .executeQuery();

        List<OpportunityContactRole> oppConRolesWithClosedWonOppbyContactsId = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOppConRolesWithClosedWonOppbyContactsId(new List<Object>{new Set<Id>{opportunityContactRoles[0].ContactId}})
                .executeQuery();

        System.assert(oppConRolesWithClosedWonOppbyContactsId.size() > 0, ASSERT_MESSAGE );
    }
       
    
    @isTest
    private static void testSelectOCRForFixContactStatusField(){
        Datetime startDate = Datetime.newInstance(2021, 12, 12);
    	Datetime endDate = Datetime.newInstance(2030, 12, 14);
        
        List<OpportunityContactRole> oCRForFixContactStatusField = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
            .selectOCRForFixContactStatusField(new List<Object>{startDate, endDate})
                .executeQuery();

        System.assert(oCRForFixContactStatusField.size() > 0, ASSERT_MESSAGE );
    }
}