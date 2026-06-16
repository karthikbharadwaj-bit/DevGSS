@isTest
private class Test_AssetTouchSelector {

    static final String ASSET_ID = '321';

    @testSetup
    static void makeData() {
        new SObjectBuilder(Marketing_Asset__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Marketing_Asset__c.Name => 'Office Stuff',
                    Marketing_Asset__c.Type__c => 'Webinar',
                    Marketing_Asset__c.Asset_ID__c => ASSET_ID,
                    Marketing_Asset__c.Active__c => true
                }
            )
            .create();

        new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Lead.LastName => 'Test Lead',
                    Lead.Email =>'tcm@testfake.com',
                    Lead.LeadSource => 'X',
                    Lead.Status => '1. New C'
                }
            )
            .create();

        new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Contact.LastName => 'Test Contact',
                    Contact.Email => 'contactperson@test.com'
                }
            )
            .create();
    }

    @isTest 
    static void testSelectAssetsForSubquery() {
        
        Test.startTest();

        List<Asset_Touch__c> ats = insertAsset();
        List<Asset_Touch__c> testAts = new AssetTouchSelector()
                .selectAssetsForSubquery()
                .executeQuery();
        
        Test.stopTest();
        
        System.assertEquals(ats.size(), testAts.size(), 'Incorrect Assets were retrieved');
    }

    @isTest 
    static void selectAssetsByLead() {
        
        Lead oneLead = (Lead) new LeadSelector().selectLeads().executeQuery()[0];

        Test.startTest();

        List<Asset_Touch__c> ats = insertAsset();
        List<Asset_Touch__c> testAts = new AssetTouchSelector()
                .selectAssetsByLead(new List<Object> { new Set<Lead> {oneLead} })
                .executeQuery();

        Test.stopTest();
        
        System.assertEquals(ats.size(), testAts.size(), 'Incorrect Assets were retrieved');
    }

    private static List<Asset_Touch__c> insertAsset() {
        
        Lead oneLead = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        MarketingAssetSelector marketingAssetSelector = new MarketingAssetSelector();
        Marketing_Asset__c ma =  (Marketing_Asset__c) new MarketingAssetSelector().selectMarketingAssetByAssetId(new List<Object>{ASSET_ID}).executeQuery()[0];
        
        return new SObjectBuilder(Asset_Touch__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Asset_Touch__c.Lead__c => oneLead.Id,
                    Asset_Touch__c.Marketing_Asset__c => ma.Id,
                    Asset_Touch__c.Unique_Name__c => new ValueProvider.UniqueStringProvider('testAsset'),
                    Asset_Touch__c.Trigger_Recalculation__c => false,
                    Asset_Touch__c.Asset_Touch_DateTime__c => Datetime.now()
                }
            )
            .create()
            .getRecords();
    }
}