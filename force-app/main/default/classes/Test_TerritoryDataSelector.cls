@isTest
private class Test_TerritoryDataSelector {
    //Territory data fields defined
    private static final String TERRITORY_DATA_NAME = 'Test';
    private static final String TERRITORY_DATA_COUNTRY = 'USA';
    private static final String TERRITORY_DATA_STATE_PROVINCE = 'CA';
    private static final String TERRITORY_DATA_SEGMENT = 'Segment';

	@testSetup
    private static void testData(){
    	Territory_Data__c td = (Territory_Data__c) new SObjectBuilder(Territory_Data__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Territory_Data__c.Name => TERRITORY_DATA_NAME,
                    Territory_Data__c.Country__c => TERRITORY_DATA_COUNTRY,
                    Territory_Data__c.State_Province__c => TERRITORY_DATA_STATE_PROVINCE,
                    Territory_Data__c.Segment__c => TERRITORY_DATA_SEGMENT
                }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectTerritoryDataByCountryStateSegment(){
        List<Territory_Data__c> territoryDataByCountryStateSegment = (List<Territory_Data__c>) new TerritoryDataSelector(true, true)
            .selectTerritoryDataByCountryStateSegment(new List<Object>{new Set<String>{TERRITORY_DATA_COUNTRY},
                													   new Set<String>{TERRITORY_DATA_STATE_PROVINCE},
                                                                       new Set<String>{TERRITORY_DATA_SEGMENT}})
            .executeQuery();

        System.assert(territoryDataByCountryStateSegment.size() >0 );
    }
}