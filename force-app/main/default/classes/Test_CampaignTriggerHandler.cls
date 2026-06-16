@isTest
public with sharing class Test_CampaignTriggerHandler {
    private static final String RINGCENTRAL_EU_BRAND = 'RingCentral EU';

    @isTest
    public static void intendedBrandDFR_whenUpdateIntendedProduct_ShouldUpdateIntendedBrandOnDFR() {

        List<Campaign> camps = (List<Campaign>) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'camp Test')
            .setField(Campaign.Intended_Country__c, 'CA')
            .quantity(50)
            .create()
            .getRecords();
        
        
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

        List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();
        
        for (Integer i=0 ; i< 50; i++) {
            dfrs.add(
                (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Demand_Funnel__c.Opportunity__c => opp.Id,
                            Demand_Funnel__c.Lead__c => leadTest.Id,
                            Demand_Funnel__c.Prospect_campaign__c => camps[i].Id
                        }
                    )
                    .build()
                    .getRecord()
            );
        }
        
        insert dfrs;
        
        Test.startTest();
            for (Campaign cmp : camps) {
                cmp.Intended_Country__c = 'BE';
            }
            update camps;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
            .executeQuery();

        System.assertEquals(50, dfrs.size(), 'There should be fifty (50) Demand Funnel records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(RINGCENTRAL_EU_BRAND, dfr.Intended_Brand__c, 'The Intended Brand should be RingCentral EU because the campaign intended prouct starts with EU');
        }
    }
}