@isTest
private class Test_AreaCodesSelector {
	//Area codes fields defined 
    private static final String AREA_CODES_NAME = 'Test';
    private static final String AREA_CODES_STATE = 'CA';
    private static final String AREA_CODES_CITY = 'LA';
    private static final String AREA_CODES_COUNTRY = 'USA';
    private static final Decimal AREA_CODES_AREA_CODE = 90001;

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Area codes should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong area codes selected';


    @testSetup
    private static void testData(){
    List<Area_Codes__c> areaCodes = (List<Area_Codes__c>) new SobjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Area_Codes__c.Name => AREA_CODES_NAME,
                Area_Codes__c.State__c => AREA_CODES_STATE,
                Area_Codes__c.City__c => AREA_CODES_CITY,
                Area_Codes__c.Country__c => AREA_CODES_COUNTRY,
                Area_Codes__c.Area_Code__c => AREA_CODES_AREA_CODE
            })
            .create()
            .getRecords();
    }
        
    @isTest
    private static void testSelectAreaCodes(){
        List<Area_Codes__c> areaCodes = (List<Area_Codes__c>) new AreaCodesSelector(true, true)
            .selectAreaCodes()
            .executeQuery();

        System.assert(areaCodes.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectAreaCodesByIds(){
        List<Area_Codes__c> areaCodes = (List<Area_Codes__c>) new AreaCodesSelector()
            .selectAreaCodes()
            .executeQuery();

        List<Area_Codes__c> areaCodesByIds = (List<Area_Codes__c>) new AreaCodesSelector()
            .selectAreaCodesByIds(areaCodes[0].Id)
            .executeQuery();

        System.assert(areaCodesByIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(areaCodesByIds[0].Id, areaCodes[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectAreaCodesForMatchedSync(){
        List<Area_Codes__c> areaCodesForMatchedSync = (List<Area_Codes__c>) new AreaCodesSelector()
            .selectAreaCodesForMatchedSync(new List<Object>{new Set<String>{AREA_CODES_COUNTRY},
                						  					new Set<String>{AREA_CODES_STATE},
                                                            new Set<String>{AREA_CODES_CITY},
                                                            new Set<Decimal>{AREA_CODES_AREA_CODE}},
                                           new List<Object>{})
            .executeQuery();

        System.assert(areaCodesForMatchedSync.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(areaCodesForMatchedSync[0].Country__c, AREA_CODES_COUNTRY, ASSERT_EQUALS_MESSAGE);
    }
    
}