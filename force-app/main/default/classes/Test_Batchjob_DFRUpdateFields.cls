@isTest
public class Test_Batchjob_DFRUpdateFields {

    private static final String RINGCENTRAL_BRAND = 'RingCentral';
    private static final String RINGCENTRAL_CANADA_BRAND = 'RingCentral Canada';
    private static final String RINGCENTRAL_AU_BRAND = 'RingCentral AU';
    private static final String RINGCENTRAL_EU_BRAND = 'RingCentral EU';
    
    @isTest
    public static void populateIntendedBrand_Using_ProspectLeadSource() {
        RingCentralVariousSettings__c.getOrgDefaults().Number_of_days_to_update_DFR_fields__c = 10;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();
        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt3')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .setField(Campaign.Intended_Product__c, 'Test')
            .create()
            .getRecord();
        
        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.Lead_Brand_Name__c, 'Test brand')
            .create()
            .getRecord();
        
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'Test Brand'
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Brand_Name__c => 'Test'
                }
            )
            .create()
            .getRecord();

                
        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'Test'
                }
            )
            .create()
            .getRecord();


        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Demand_Funnel__c.Opportunity__c => opp.Id,
                    Demand_Funnel__c.Account__c => acc2.Id,
                    Demand_Funnel__c.Lead__c => leadTest.Id,
                    Demand_Funnel__c.Prospect_campaign__c => camp.Id,
                    Demand_Funnel__c.Prospect_Lead_Source__c => 'Test CA Test'
                }
            )
            .quantity(50)
            .create()
            .getRecords();
        Triggers.switchOn();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(null, dfr.Intended_Brand__c, 'The Intended Brand should be null because trigger logic is disabled');
        }

        Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields());
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(RINGCENTRAL_CANADA_BRAND, dfr.Intended_Brand__c, 'The Intended Brand should be RingCentral Canada because the field Prospect_Lead_Source__c contains CA');
        }
    }
    
    @isTest
    public static void populateIntendedBrand_Using_Lead() {
        RingCentralVariousSettings__c.getOrgDefaults().Number_of_days_to_update_DFR_fields__c = 10;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();
        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt3')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .setField(Campaign.Intended_Product__c, 'Test')
            .create()
            .getRecord();
        
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'Test Brand'
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Brand_Name__c => 'Test'
                }
            )
            .create()
            .getRecord();

                
        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'Test'
                }
            )
            .create()
            .getRecord();

        Lead leadTest2 = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.Lead_Brand_Name__c, 'RingCentral AU')
            .create()
            .getRecord();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Demand_Funnel__c.Opportunity__c => opp.Id,
                    Demand_Funnel__c.Account__c => acc2.Id,
                    Demand_Funnel__c.Lead__c => leadTest2.Id,
                    Demand_Funnel__c.Prospect_campaign__c => camp.Id
                }
            )
            .quantity(50)
            .create()
            .getRecords();
        Triggers.switchOn();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(null, dfr.Intended_Brand__c, 'The Intended Brand should be null because trigger logic is disabled');
        }

        Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields());
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(RINGCENTRAL_AU_BRAND, dfr.Intended_Brand__c, 'The Intended Brand should be RingCentral AU because the field Intended_Brand__c is RingCentral AU');
        }
    }
    @isTest
    public static void populateIntendedBrand_Using_Account() {
        RingCentralVariousSettings__c.getOrgDefaults().Number_of_days_to_update_DFR_fields__c = 10;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();
        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt3')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .create()
            .getRecord();
        
                
        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => RINGCENTRAL_CANADA_BRAND
                }
            )
            .create()
            .getRecord();


        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.ZI_CDP_Account_Id__c, acc2.Id)
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .create()
            .getRecord();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Demand_Funnel__c.Lead__c => leadTest.Id,
                    Demand_Funnel__c.Prospect_campaign__c => camp.Id
                }
            )
            .quantity(50)
            .create()
            .getRecords();

        Triggers.switchOn();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(null, dfr.Intended_Brand__c, 'The Intended Brand should be null because trigger logic is disabled');
        }

        Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields());
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .executeQuery();

        System.assertEquals(50, dfrs.size(), 'There should be 50 DFRs created.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(RINGCENTRAL_CANADA_BRAND, dfr.Intended_Brand__c, 'The Intended Brand should be the same as the Account\'s Brand');
        }
    }
    @isTest
    public static void populateIntendedBrand_Using_Opportunity() {
        RingCentralVariousSettings__c.getOrgDefaults().Number_of_days_to_update_DFR_fields__c = 10;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();
        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt3')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .create()
            .getRecord();
        
        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .create()
            .getRecord();
        
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => RINGCENTRAL_BRAND
                }
            )
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => RINGCENTRAL_EU_BRAND
                }
            )
            .create()
            .getRecord();

        Opportunity opp2 = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc2.Id
                }
            )
            .create()
            .getRecord();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Demand_Funnel__c.Opportunity__c => opp2.Id,
                    Demand_Funnel__c.Account__c => acc.Id,
                    Demand_Funnel__c.Lead__c => leadTest.Id,
                    Demand_Funnel__c.Prospect_campaign__c => camp.Id
                }
            )
            .quantity(50)
            .create()
            .getRecords();
        Triggers.switchOn();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(null, dfr.Intended_Brand__c, 'The Intended Brand should be null because trigger logic is disabled');
        }

        Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields());
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .executeQuery();

        System.assertEquals(50, dfrs.size(), 'There should be 50 DFRs created.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(RINGCENTRAL_EU_BRAND, dfr.Intended_Brand__c, 'The Intended Brand should be the same as the Opportunity\'s Account Brand');
        }
    }
    @isTest
    public static void populateIntendedBrand_Using_ProspectCampaign() {
        RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getOrgDefaults();
        settings.Number_of_days_to_update_DFR_fields__c = 10;
        settings.DFRUpdateFields_useCustomSetting__c = false;
        settings.DFRUpdateFields_isDFRIncluded__c = true;
        settings.DFRUpdateFields_isLeadIncluded__c = false;
        settings.DFRUpdateFields_isContactIncluded__c = false;
        settings.DFRUpdateFields_isAccountIncluded__c = false;
        insert settings;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();
        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt3')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .setField(Campaign.Intended_Country__c, 'AU')
            .create()
            .getRecord();
        
        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.Lead_Brand_Name__c, 'Test brand')
            .create()
            .getRecord();
        
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Account.Name => 'testAcc',
                Account.RC_Brand__c => 'Test Brand'
            }
        )
        .create()
        .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Brand_Name__c => 'Test'
                }
            )
            .create()
            .getRecord();

            
        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'Test'
                }
            )
            .create()
            .getRecord();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Demand_Funnel__c.Opportunity__c => opp.Id,
                    Demand_Funnel__c.Account__c => acc2.Id,
                    Demand_Funnel__c.Lead__c => leadTest.Id,
                    Demand_Funnel__c.Prospect_campaign__c => camp.Id
                }
            )
            .quantity(50)
            .create()
            .getRecords();

        Triggers.switchOn();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
        .selectDFRByIds(new Object[]{dfrs})
        .selectField(Demand_Funnel__c.Intended_Brand__c)
        .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
        .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(null, dfr.Intended_Brand__c, 'The Intended Brand should be null because trigger logic is disabled');
        }

        Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields());
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .executeQuery();

        System.assertEquals(50, dfrs.size(), 'There should be 50 DFRs created.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(RINGCENTRAL_AU_BRAND, dfr.Intended_Brand__c, 'The Intended Brand should be the same as the Campaign Intended Product');
        }
    }
    @isTest
    public static void updateFortyDFRUsingOpportunityAccount() {
        DateTime dateStart = DateTime.newInstance(2000, 6, 1);
        DateTime dateEnd = DateTime.now().addDays(2);
        RingCentralVariousSettings__c.getOrgDefaults().Number_of_days_to_update_DFR_fields__c = 10;
        List<Account> accounts = new List<Account>();

        for (integer i=0; i<40; i++) {
            accounts.add(new Account(
                Name = 'Nico -- Test ' + i,
                Segment_Exception_Flag__c = true,
                Emp_Range_Sales_Override__c = 20000
            ));
        }

        Triggers.switchOff();
        insert accounts;

        List<Opportunity> opportunities = new List<Opportunity>();

        for (integer i=0; i<40; i++) {
            opportunities.add(new Opportunity(
                Name = 'Nico -- Test ' + i,
                AccountId = accounts[i].Id,
                stageName = 'Staging',
                closeDate = Date.today().addDays(10)
            ));
        }

        List<Lead> leads = new List<Lead>();

        for (integer i=0; i<40; i++) {
            leads.add(new Lead(
                lastName = 'Nico -- Test ' + i,
                Emp_Range_Sales_Override__c = 100,
                email ='fakeEmail@test.invalid.com',
                Company = 'fakeCompany ' + i
            ));
        }

        insert opportunities;
        insert leads;

        List<Demand_funnel__c> dfrs = new List<Demand_funnel__c>();
        for (integer i=0; i<40; i++) {
            dfrs.add(new Demand_funnel__c(
                Opportunity__c = opportunities[i].Id,
                Lead__c = leads[i].Id)
            );
        }

        insert dfrs;
        Triggers.switchOn();

        Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields());
        Test.stopTest();

        List<demand_funnel__c> updatedDfrs = (List<demand_funnel__c>) new DemandFunnelSelector()
            .selectDFRForFixSMEmployeeField(new List<Object>{dateStart, dateEnd})
            .executeQuery();

        system.assertEquals(40, updatedDfrs.size(), 'There should exists 200 dfr records.');

        for (Demand_funnel__c dfr : updatedDfrs) {
            system.assertEquals(20000, dfr.SM_Employees__c, 'SM Employees field value should be 20000.');
        }

    }
    @isTest
    public static void updateFiftyDFRUsingAccount() {
        DateTime dateStart = DateTime.newInstance(2000, 6, 1);
        DateTime dateEnd = DateTime.now().addDays(2);
        RingCentralVariousSettings__c.getOrgDefaults().Number_of_days_to_update_DFR_fields__c = 10;

        Triggers.switchOff();

        Account acc =  (Account) new sObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'test')
            .setField(Account.Segment_Exception_Flag__c, true)
            .setField(Account.Emp_Range_Sales_Override__c, 20000)
            .create()
            .getRecord();

        Lead ld =  (Lead) new sObjectBuilder(Lead.sObjectType)
            .setField(Lead.LastName, 'test lastname')
            .setField(Lead.FirstName, 'test firstName')
            .setField(Lead.Company, 'test company')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .create()
            .getRecord();

        new sObjectBuilder(Demand_Funnel__c.sObjectType)
            .setField(Demand_Funnel__c.Lead__c, ld.Id)
            .setField(Demand_Funnel__c.SM_Employees__c, 50)
            .quantity(50)
            .create()
            .getRecords();
        Triggers.switchOn();

        Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields());
        Test.stopTest();

        List<demand_funnel__c> updatedDfrs = (List<demand_funnel__c>) new DemandFunnelSelector()
            .selectDFRForFixSMEmployeeField(new List<Object>{dateStart, dateEnd})
            .executeQuery();

        system.assertEquals(50, updatedDfrs.size(), 'There should exists 50 dfr records.');

        for (Demand_funnel__c dfr : updatedDfrs) {
            system.assertEquals(20000, dfr.SM_Employees__c, 'SM Employees field value should be 20000.');
        }

    }
    @isTest
    public static void updateFiftyDFRUsingLead() {
        DateTime dateStart = DateTime.newInstance(2000, 6, 1);
        DateTime dateEnd = DateTime.now().addDays(2);
        RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getOrgDefaults();
        settings.Number_of_days_to_update_DFR_fields__c = 10;
        settings.DFRUpdateFields_useCustomSetting__c = false;
        settings.DFRUpdateFields_isDFRIncluded__c = false;
        settings.DFRUpdateFields_isLeadIncluded__c = true;
        settings.DFRUpdateFields_isContactIncluded__c = false;
        settings.DFRUpdateFields_isAccountIncluded__c = false;
        insert settings;	
        List<Lead> leads = new List<Lead>();

        for (integer i=0; i<50; i++) {
            leads.add(new Lead(
                lastName = 'Nico -- Test ' + i,
                Emp_Range_Sales_Override__c = 20000,
                email ='testing@notarealmail.com',
                Company = 'fakeCompany ' + i
            ));
        }
		
        Triggers.switchOff();
        insert leads;

        Test.startTest();
        List<Demand_funnel__c> dfrs = new List<Demand_funnel__c>();
        for (integer i=0; i<50; i++) {
            dfrs.add(new Demand_funnel__c(
                Lead__c = leads[i].Id
            ));
        }

        insert dfrs;
        Triggers.switchOn();

            Database.executeBatch(new Batchjob_DFRUpdateFields());
        Test.stopTest();

        List<demand_funnel__c> updatedDfrs = (List<demand_funnel__c>) new DemandFunnelSelector()
            .selectDFRForFixSMEmployeeField(new List<Object>{dateStart, dateEnd})
            .executeQuery();

        system.assertEquals(50, updatedDfrs.size(), 'There should exists 50 dfr records.');

        for (Demand_funnel__c dfr : updatedDfrs) {
            system.assertEquals(20000, dfr.SM_Employees__c, 'SM Employees field value should be 20000.');
        }

    }
    @isTest
    public static void defaultSMEmployeesValue() {
        DateTime dateStart = DateTime.newInstance(2000, 6, 1);
        DateTime dateEnd = DateTime.now().addDays(2);
        RingCentralVariousSettings__c.getOrgDefaults().Number_of_days_to_update_DFR_fields__c = 10;

        Triggers.switchOff();
        Lead ld = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.LastName, 'test lastname')
            .setField(Lead.FirstName, 'test firstName')
            .setField(Lead.Company, 'test company')
            .setField(Lead.Email, 'test@emailtest.com')
            .create()
            .getRecord();
        
        new sObjectBuilder(Demand_Funnel__c.sObjectType)
            .setField(Demand_Funnel__c.Lead__c, ld.Id)
            .setField(Demand_Funnel__c.SM_Employees__c, 50)
            .quantity(50)
            .create();
        Triggers.switchOn();

        Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields());
        Test.stopTest();

        List<demand_funnel__c> updatedDfrs = (List<demand_funnel__c>) new DemandFunnelSelector()
            .selectDFRForFixSMEmployeeField(new List<Object>{dateStart, dateEnd})
            .executeQuery();

        system.assertEquals(50, updatedDfrs.size(), 'There should exists 50 dfr records.');

        for (Demand_funnel__c dfr : updatedDfrs) {
            system.assertEquals(1, dfr.SM_Employees__c, 'Default SM Employees value should be 1 (one)');
        }

    }
    @isTest
    static void fixAccountField_whenContactAccountIsPopulated_shouldUpdateAccountField() {
        Triggers.switchOff();
        
        List<Account> accs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'testName')
            .quantity(150)
            .create()
            .getRecords();
        
        List<Contact> conts = new List<Contact>();

        for (Account acc : accs) {
            conts.Add((Contact) new SObjectBuilder(Contact.sObjectType)
                .setField(Contact.AccountId, acc.Id)
                .setField(Contact.lastName, 'lastNameTest')
                .build()
                .getRecord()
            );
        }

        insert conts;
        
        List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();

        for (Contact cont : conts) {
            dfrs.Add((Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.sObjectType)
                .setField(Demand_Funnel__c.Contact__c, cont.Id)
                .build()
                .getRecord()
            );
        }
        
        insert dfrs;

        Triggers.switchOn();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();
        
        System.assertEquals(150, dfrs.size(), 'should have 150 records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(null, dfr.Account__c, 'The account field value should be null.');
        }

        Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields());
        Test.stopTest();


        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
        .selectDFRByIds(new Object[]{dfrs})
            .selectField('Contact__r.AccountId')
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();
        
        System.assertEquals(150, dfrs.size(), 'should have 150 records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertNotEquals(null, dfr.Contact__r?.AccountId, 'The account of the contact related to the dfr should not be null.');
            System.assertEquals(dfr.Contact__r.AccountId, dfr.Account__c, 'The account field value should be null.');
        }
    }
    @isTest
    static void fixAccountField_whenLeadAccountIsPopulated_shouldUpdateAccountField() {
        Triggers.switchOff();
        
        List<Account> accs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'testName')
            .quantity(25)
            .create()
            .getRecords();
        
        List<Lead> leads = new List<Lead>();

        for (Account acc : accs) {
            leads.Add((Lead) new SObjectBuilder(Lead.sObjectType)
                .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
                .setField(Lead.lastName, 'lastNameTest')
                .build()
                .getRecord()
            );
        }

        insert leads;
        
        List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();

        for (Lead aLead : leads) {
            dfrs.Add((Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.sObjectType)
                .setField(Demand_Funnel__c.Lead__c, aLead.Id)
                .build()
                .getRecord()
            );
        }
        
        insert dfrs;

        Triggers.switchOn();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();
        
        System.assertEquals(25, dfrs.size(), 'should have 25 records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(null, dfr.Account__c, 'The account field value should be null.');
        }

        Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields(Datetime.now().addDays(-1), Datetime.now()));
        Test.stopTest();


        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
        .selectDFRByIds(new Object[]{dfrs})
            .selectField('Lead__r.ZI_CDP_Account_Id__c')
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();
        
        System.assertEquals(25, dfrs.size(), 'should have 25 records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertNotEquals(null, dfr.Lead__r?.ZI_CDP_Account_Id__c, 'The account of the lead related to the dfr should not be null.');
            System.assertEquals(dfr.Lead__r.ZI_CDP_Account_Id__c, dfr.Account__c, 'The account field value should be null.');
        }
    }
    @isTest
    static void fixAccountField_whenOpportunityAccountIsPopulated_shouldUpdateAccountField() {
        Triggers.switchOff();
        
        List<Account> accs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'testName')
            .quantity(25)
            .create()
            .getRecords();
        
        List<Opportunity> opps = new List<Opportunity>();

        for (Account acc : accs) {
            opps.Add((Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.Name, 'Test Opportunity')
                .setField(Opportunity.Type, 'Syndicated - New')
                .setField(Opportunity.AccountId, acc.Id)
                .setField(Opportunity.StageName, '1. Qualify')
                .setField(Opportunity.CloseDate, System.today().addMonths(1))
                .build()
                .getRecord()
            );
        }

        insert opps;
        
        List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();

        for (Opportunity opp : opps) {
            dfrs.Add((Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.sObjectType)
                .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
                .build()
                .getRecord()
            );
        }
        
        insert dfrs;

        Triggers.switchOn();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();
        
        System.assertEquals(25, dfrs.size(), 'should have 25 records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(null, dfr.Account__c, 'The account field value should be null.');
        }

        Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields(Datetime.now().addDays(-1), Datetime.now()));
        Test.stopTest();


        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
        .selectDFRByIds(new Object[]{dfrs})
            .selectField('Opportunity__r.AccountId')
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();
        
        System.assertEquals(25, dfrs.size(), 'should have 25 records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertNotEquals(null, dfr.Opportunity__r?.AccountId, 'The account of the Opportunity related to the dfr should not be null.');
            System.assertEquals(dfr.Opportunity__r.AccountId, dfr.Account__c, 'The account field value should be null.');
        }
    }
}