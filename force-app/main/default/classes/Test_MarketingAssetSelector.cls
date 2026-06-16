@isTest
private class Test_MarketingAssetSelector {
    //Marketing asset fields defined
    private static final String MARKETING_ASSET_NAME = 'Test';
    private static final String MARKETING_ASSET_TYPE = 'Webinar';
    private static final String MARKETING_ASSET_ASSET_ID = '123';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Marketing assets should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong marketing asset selected';

    @testSetup
    private static void testData(){
        Marketing_Asset__c company = (Marketing_Asset__c) new SObjectBuilder(Marketing_Asset__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Marketing_Asset__c.Name => MARKETING_ASSET_NAME,
                    Marketing_Asset__c.Type__c => MARKETING_ASSET_TYPE,
                    Marketing_Asset__c.Asset_ID__c => MARKETING_ASSET_ASSET_ID
                    }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectMarketingAssets(){
        List<Marketing_Asset__c> marketingAssets = (List<Marketing_Asset__c>) new MarketingAssetSelector(true, true)
            .selectMarketingAssets()
            .executeQuery();

        System.assert(marketingAssets.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectMarketingAssetById(){
        List<Marketing_Asset__c> marketingAssets = (List<Marketing_Asset__c>) new MarketingAssetSelector()
            .selectMarketingAssets()
            .executeQuery();

        List<Marketing_Asset__c> marketingAssetById = (List<Marketing_Asset__c>) new MarketingAssetSelector()
            .selectMarketingAssetById(new List<Object>{new Set<Id>{marketingAssets[0].Id}})
            .executeQuery();
        
        System.assert(marketingAssetById.size() > 0, ASSERT_MESSAGE);
       	System.assertEquals(marketingAssets[0].Id, marketingAssets[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectMarketingAssetByName(){
        List<Marketing_Asset__c> marketingAssetByName = (List<Marketing_Asset__c>) new MarketingAssetSelector()
            .selectMarketingAssetByName(new List<Object>{new Set<String>{MARKETING_ASSET_NAME}})
            .executeQuery();

        System.assert(marketingAssetByName.size() > 0, ASSERT_MESSAGE);
		System.assertEquals(MARKETING_ASSET_NAME, marketingAssetByName[0].Name, ASSERT_EQUALS_MESSAGE);        
    }
    
    
    @isTest
    private static void testSelectMarketingAssetByAssetId(){
        List<Marketing_Asset__c> marketingAssetByAssetId = (List<Marketing_Asset__c>) new MarketingAssetSelector()
            .selectMarketingAssetByAssetId(new List<Object>{new Set<String>{MARKETING_ASSET_ASSET_ID}})
            .executeQuery();

        System.assert(marketingAssetByAssetId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(MARKETING_ASSET_ASSET_ID, marketingAssetByAssetId[0].Asset_ID__c, ASSERT_EQUALS_MESSAGE);       
    }
    
    @isTest
    private static void testSelectMarketingAssetsByIds(){
        List<Marketing_Asset__c> marketingAssets = (List<Marketing_Asset__c>) new MarketingAssetSelector()
            .selectMarketingAssets()
            .executeQuery();

        List<Marketing_Asset__c> marketingAssetsByIds = (List<Marketing_Asset__c>) new MarketingAssetSelector()
            .selectMarketingAssetsByIds(new List<Object>{new Set<Id>{marketingAssets[0].Id}})
            .executeQuery();

        System.assert(marketingAssetsByIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(marketingAssets[0].Id, marketingAssetsByIds[0].Id, ASSERT_EQUALS_MESSAGE);   
    }
    
    @isTest
    private static void testSelectActiveMarketingAssetsByAssetIds(){
        List<Marketing_Asset__c> activeMarketingAssetsByAssetIds = (List<Marketing_Asset__c>) new MarketingAssetSelector()
            .selectActiveMarketingAssetsByAssetIds(new List<Object>{new Set<String>{MARKETING_ASSET_ASSET_ID}})
            .executeQuery();

        System.assert(activeMarketingAssetsByAssetIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(MARKETING_ASSET_ASSET_ID, activeMarketingAssetsByAssetIds[0].Asset_ID__c, ASSERT_EQUALS_MESSAGE);
    }
}