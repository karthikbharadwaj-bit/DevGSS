@isTest
private class Test_TerritoryHelper{

    @isTest
    private static void testGetCountryShouldReturnTheCorrectCountry(){
        Test.startTest();
            String returnedCountry = TerritoryHelper.getCountry('usa');
        Test.stopTest();
        System.assertEquals('United States', returnedCountry,
            'test GetCountry should return the correct country');
    }

    @isTest
    private static void testGetCountryWithUpperCaseShouldReturnTheCorrectCountry(){
        Test.startTest();
            String returnedCountry = TerritoryHelper.getCountry('UNITED States');
        Test.stopTest();
        System.assertEquals('United States', returnedCountry,
            'test GetCountry should return the correct country even country contains uppercase letters');
    }

    @isTest
    private static void testGetCountryShouldReturnNullWhenNoCountryIsFound(){
        Test.startTest();
            String returnedCountry = TerritoryHelper.getCountry('unexisting');
        Test.stopTest();
        System.assertEquals(null, returnedCountry,
            'test GetCountry should return null when no country is found');
    }

    @isTest
    private static void testGetStateShouldReturnTheCorrectState(){
        Test.startTest();
            String returnedState = TerritoryHelper.getState('fl');
        Test.stopTest();
        System.assertEquals('Florida', returnedState,
            'test GetState should return the correct state');
    }

    @isTest
    private static void testGetStateWithUpperCaseShouldReturnTheCorrectState(){
        Test.startTest();
            String returnedState = TerritoryHelper.getState('Wa');
        Test.stopTest();
        System.assertEquals('Washington', returnedState,
            'test GetState should return the correct state even state contains uppercase letters');
    }

    @isTest
    static void testGetStateShouldReturnTheStringPassedAsParameterWhenNoStateIsFound(){
        Test.startTest();
            String returnedState = TerritoryHelper.getState('unexisting');
        Test.stopTest();
        System.assertEquals('unexisting', returnedState,
            'test GetState should return null when no state is found');
    }
}