@isTest
public with sharing class Test_DemandFunnelTrigger {

    private static final String RINGCENTRAL_BRAND = 'RingCentral';
    private static final String RINGCENTRAL_CANADA_BRAND = 'RingCentral Canada';
    private static final String RINGCENTRAL_AU_BRAND = 'RingCentral AU';
    private static final String RINGCENTRAL_EU_BRAND = 'RingCentral EU';
    @isTest
    public static void test_mappingIntededBrandMap_shouldBeFilled() {
        Map<String,Map<String, String>> mappingIntededBrandMap = DemandFunnelTriggerHelper.mappingIntededBrandMap;

        system.assertNotEquals(null, mappingIntededBrandMap,'The map should\'t be null.');
        system.assertNotEquals(0, mappingIntededBrandMap.size(), 'The map should be populated.');
        system.assertNotEquals(0, mappingIntededBrandMap.get(DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_OPPORTUNITY_ACCOUNT).size(),
            'There should be at least 1 value in the map using the key .' + DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_OPPORTUNITY_ACCOUNT
        );
        system.assertNotEquals(0, mappingIntededBrandMap.get(DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_ACCOUNT).size(),
            'There should be at least 1 value in the map using the key .' + DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_ACCOUNT
        );
        system.assertNotEquals(0, mappingIntededBrandMap.get(DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_LEAD).size(),
            'There should be at least 1 value in the map using the key .' + DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_LEAD
        );
        system.assertNotEquals(0, mappingIntededBrandMap.get(DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_PROSPECT_CAMPAIGN_INTENDED_COUNTRY).size(),
            'There should be at least 1 value in the map using the key .' + DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_PROSPECT_CAMPAIGN_INTENDED_COUNTRY
        );
        system.assertNotEquals(0, mappingIntededBrandMap.get(DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_PROSPECT_LEAD_SOURCE).size(),
            'There should be at least 1 value in the map using the key .' + DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_PROSPECT_LEAD_SOURCE
        );
        system.assertNotEquals(0, mappingIntededBrandMap.get(DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_SM_COUNTRY).size(),
            'There should be at least 1 value in the map using the key .' + DemandFunnelTriggerHelper.MDT_MAPING_FIELD_BRAND_SM_COUNTRY
        );
    }
    @isTest
    public static void intendedBrandField_whenDFRIsCreatedUsingOpportunityAccount_shouldPopulateIntendedBrand() {

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

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs;
        Test.startTest();
            dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Demand_Funnel__c.Opportunity__c => opp.Id,
                        Demand_Funnel__c.Lead__c => leadTest.Id,
                        Demand_Funnel__c.Prospect_campaign__c => camp.Id
                    }
                )
                .quantity(50)
                .create()
                .getRecords();
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .executeQuery();

        System.assertEquals(50, dfrs.size(), 'There should be 50 DFRs created.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(RINGCENTRAL_BRAND, dfr.Intended_Brand__c, 'The Intended Brand should be the same as the Opportunity\'s Account Brand');
        }
    }
    @isTest
    public static void intendedBrandField_whenDFRIsCreatedUsingAccount_shouldPopulateIntendedBrand() {

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
                    Account.RC_Brand__c => RINGCENTRAL_CANADA_BRAND
                }
            )
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'Test')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs;
        Test.startTest();
            dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Demand_Funnel__c.Contact__c => cont.Id,
                        Demand_Funnel__c.Lead__c => leadTest.Id,
                        Demand_Funnel__c.Prospect_campaign__c => camp.Id
                    }
                )
                .quantity(50)
                .create()
                .getRecords();
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
    public static void intendedBrandField_whenDFRIsCreatedUsingLeadBrandName_shouldPopulateIntendedBrand() {

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
            .setField(Lead.Lead_Brand_Name__c, RINGCENTRAL_AU_BRAND)
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

        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs;
        Test.startTest();
            dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Demand_Funnel__c.Opportunity__c => opp.Id,
                        Demand_Funnel__c.Lead__c => leadTest.Id,
                        Demand_Funnel__c.Prospect_campaign__c => camp.Id
                    }
                )
                .quantity(50)
                .create()
                .getRecords();
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .executeQuery();

        System.assertEquals(50, dfrs.size(), 'There should be 50 DFRs created.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(RINGCENTRAL_AU_BRAND, dfr.Intended_Brand__c, 'The Intended Brand should be the same as the Lead\'s Brand name');
        }
    }
    @isTest
    public static void intendedBrandField_whenDFRIsCreatedUsingProspectCampaign_shouldPopulateIntendedBrand() {

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
        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs;
        Test.startTest();
            dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Demand_Funnel__c.Opportunity__c => opp.Id,
                        Demand_Funnel__c.Lead__c => leadTest.Id,
                        Demand_Funnel__c.Prospect_campaign__c => camp.Id
                    }
                )
                .quantity(50)
                .create()
                .getRecords();
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
    public static void intendedBrandField_whenDFRIsCreatedUsingSMCountry_shouldPopulateIntendedBrand() {

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
                    Account.RC_Brand__c => 'Test Brand',
                    Account.ZI_Company_Country__c => 'Germany'
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

            Triggers.switchOn();

            List<Demand_Funnel__c> dfrs;
            Test.startTest();
                dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Demand_Funnel__c.Opportunity__c => opp.Id,
                            Demand_Funnel__c.Lead__c => leadTest.Id,
                            Demand_Funnel__c.Prospect_campaign__c => camp.Id
                        }
                    )
                    .quantity(50)
                    .create()
                    .getRecords();
            Test.stopTest();

            dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
                .selectDFRByIds(new Object[]{dfrs})
                .selectField(Demand_Funnel__c.Intended_Brand__c)
                .executeQuery();

            System.assertEquals(50, dfrs.size(), 'There should be 50 DFRs created.');

            for (Demand_Funnel__c dfr : dfrs) {
                System.assertEquals(RINGCENTRAL_EU_BRAND, dfr.Intended_Brand__c, 'The Intended Brand should be the same as the SM Country field');
            }
    }
    @isTest
    public static void intendedBrandField_whenDFRIsCreatedUsingProspectLeadSource_shouldPopulateIntendedBrand() {

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
                    Account.RC_Brand__c => 'Test Brand',
                    Account.ZI_Company_Country__c => 'Germany'
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

        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs;
        Test.startTest();
            dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
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
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .executeQuery();

        System.assertEquals(50, dfrs.size(), 'There should be 50 DFRs created.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(RINGCENTRAL_CANADA_BRAND, dfr.Intended_Brand__c, 'The Intended Brand should be the same as the Prospect_Lead_Source__c field');
        }
    }
    @isTest
    public static void intendedBrandField_whenUpdateProspectLeadSource_shouldUpdateIntededBrand() {

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

        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Demand_Funnel__c.Opportunity__c => opp.Id,
                    Demand_Funnel__c.Lead__c => leadTest.Id,
                    Demand_Funnel__c.Prospect_campaign__c => camp.Id
                }
            )
            .quantity(50)
            .create()
            .getRecords();
        Test.startTest();
            for (Demand_Funnel__c dfr : dfrs) {
                dfr.Prospect_Lead_Source__c = 'Test CA Test';
            }
            update dfrs;
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
    public static void intendedBrandField_whenUpdateLead_shouldUpdateIntededBrand() {

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

        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Demand_Funnel__c.Opportunity__c => opp.Id,
                    Demand_Funnel__c.Lead__c => leadTest.Id,
                    Demand_Funnel__c.Prospect_campaign__c => camp.Id
                }
            )
            .quantity(50)
            .create()
            .getRecords();

        Lead leadTest2 = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.Lead_Brand_Name__c, 'RingCentral AU')
            .create()
            .getRecord();

        DemandFunnelTriggerHelper.opportunityById = new Map<Id, Opportunity>();
        DemandFunnelTriggerHelper.accountById = new Map<Id, Account>();
        DemandFunnelTriggerHelper.leadById = new Map<Id, Lead>();

        Test.startTest();
            for (Demand_Funnel__c dfr : dfrs) {
                dfr.Lead__c = leadTest2.Id;
            }
            update dfrs;
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
    public static void intendedBrandField_whenUpdateAccount_shouldUpdateIntededBrand() {

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

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'Test Brand',
                    Account.RC_Brand__c => RINGCENTRAL_AU_BRAND
                }
            )
            .create()
            .getRecord();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
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

        Triggers.switchOn();
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Demand_Funnel__c.Account__c => acc.Id,
                    Demand_Funnel__c.Lead__c => leadTest.Id,
                    Demand_Funnel__c.Prospect_campaign__c => camp.Id
                }
            )
            .quantity(50)
            .create()
            .getRecords();

        DemandFunnelTriggerHelper.opportunityById = new Map<Id, Opportunity>();
        DemandFunnelTriggerHelper.accountById = new Map<Id, Account>();
        DemandFunnelTriggerHelper.leadById = new Map<Id, Lead>();
        Test.startTest();
            for (Demand_Funnel__c dfr : dfrs) {
                leadTest.ZI_CDP_Account_Id__c = acc2.Id;
            }
            update leadTest;
            Test.getEventBus().deliver();
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
    public static void intendedBrandField_whenUpdateOpportunity_shouldUpdateIntededBrand() {

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


        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id
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
        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Demand_Funnel__c.Opportunity__c => opp.Id,
                    Demand_Funnel__c.Lead__c => leadTest.Id,
                    Demand_Funnel__c.Prospect_campaign__c => camp.Id
                }
            )
            .quantity(50)
            .create()
            .getRecords();

        DemandFunnelTriggerHelper.opportunityById = new Map<Id, Opportunity>();
        DemandFunnelTriggerHelper.accountById = new Map<Id, Account>();
        DemandFunnelTriggerHelper.leadById = new Map<Id, Lead>();
        Test.startTest();
            for (Demand_Funnel__c dfr : dfrs) {
                dfr.Opportunity__c = opp2.Id;
            }
            update dfrs;
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
    public static void accountField_whenDFRIsCreatedUsingOpportunity_shouldPopulateAccount() {

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount2')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
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
        Triggers.switchOn();


        List<Demand_Funnel__c> dfrs;

        Test.startTest();
            dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                .setField(Demand_Funnel__c.Lead__c, leadTest.Id)
                .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
                .quantity(50)
                .create()
                .getRecords();
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc2.Id, dfr.Account__c, 'The account field should be the same as the opportunity account');
        }
    }
    @isTest
    public static void accountField_whenDFRIsCreatedUsingContact_shouldPopulateAccount() {

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount2')
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'testContact')
            .setField(Contact.AccountId, acc2.Id)
            .create()
            .getRecord();
        Triggers.switchOn();


        List<Demand_Funnel__c> dfrs;

        Test.startTest();
            dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                .setField(Demand_Funnel__c.Lead__c, leadTest.Id)
                .setField(Demand_Funnel__c.Contact__c, cont.Id)
                .quantity(50)
                .create()
                .getRecords();
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc2.Id, dfr.Account__c, 'The account field should be the same as the contact account');
        }
    }
    @isTest
    public static void accountField_whenDFRIsCreatedUsingLead_shouldPopulateAccount() {

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .create()
            .getRecord();
        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs;

        Test.startTest();
            dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                .setField(Demand_Funnel__c.Lead__c, leadTest.Id)
                .quantity(50)
                .create()
                .getRecords();
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc.Id, dfr.Account__c, 'The account field should be the same as the lead account');
        }
    }
    @isTest
    public static void accountField_whenDFRIsCreatedUsingNullAccountValue_shouldNotPopulateAccount() {

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity 2016',
                Opportunity.Type => 'Syndicated - New',
                Opportunity.StageName => 'Planning',
                Opportunity.CloseDate => system.today().addMonths(1)
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'testContact')
            .create()
            .getRecord();

        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs;

        Test.startTest();
            dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                .setField(Demand_Funnel__c.Lead__c, leadTest.Id)
                .setField(Demand_Funnel__c.Contact__c, cont.Id)
                .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
                .quantity(50)
                .create()
                .getRecords();
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(null, dfr.Account__c, 'The account field should be null because neither opportunity, lead nor contact have account field populated.');
        }
    }
    @isTest
    public static void accountField_whenUpdateOpportunity_shouldUpdateAccount() {

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount2')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
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
        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Lead__c, leadTest.Id)
            .quantity(50)
            .create()
            .getRecords();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc.Id, dfr.Account__c, 'The account field should be the same as the lead account');
        }

        Test.startTest();
            for (Demand_Funnel__c dfr : dfrs) {
                dfr.Opportunity__c = opp.Id;
            }
            update dfrs;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc2.Id, dfr.Account__c, 'The account field should be the same as the opportunity account');
        }
    }
    @isTest
    public static void accountField_whenUpdateContact_shouldUpdateAccount() {

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount2')
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'testContact')
            .setField(Contact.AccountId, acc2.Id)
            .create()
            .getRecord();

        Triggers.switchOn();


        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Lead__c, leadTest.Id)
            .quantity(50)
            .create()
            .getRecords();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc.Id, dfr.Account__c, 'The account field should be the same as the lead account');
        }

        Test.startTest();
            for (Demand_Funnel__c dfr : dfrs) {
                dfr.Contact__c = cont.Id;
            }
            update dfrs;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc2.Id, dfr.Account__c, 'The account field should be the same as the contact account');
        }
    }
    @isTest
    public static void accountField_whenUpdateLead_shouldUpdateAccount() {

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .create()
            .getRecord();
        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .quantity(50)
            .create()
            .getRecords();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(null, dfr.Account__c, 'The account field should be null');
        }

        Test.startTest();
            for (Demand_Funnel__c dfr : dfrs) {
                dfr.Lead__c = leadTest.Id;
            }
            update dfrs;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc.Id, dfr.Account__c, 'The account field should be the same as the lead account');
        }
    }
}