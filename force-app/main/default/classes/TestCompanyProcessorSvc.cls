@isTest
private class TestCompanyProcessorSvc {

    @isTest
    static void testGetNormalizedCountryShouldReturnTheValueProvidedInCustomSettings(){
        new SObjectBuilder(CompanyMatchingCountryMapping__c.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                CompanyMatchingCountryMapping__c.Name => 'USA',
                CompanyMatchingCountryMapping__c.ToCountry__c => 'United States'
            }
        )
        .create();

        String countryToNormalize = 'USA';
        CompanyProcessorSvc serviceUnderTest = new LeadCompanyProcessorSvc();

        Test.startTest();
            String normalizedCountry = serviceUnderTest.getNormalizedCountry(countryToNormalize);
        Test.stopTest();

        System.assertEquals('United States', normalizedCountry, 
            'Normalized country should be United States');
    }

    @isTest
    static void testGetCountryDomainKeyShouldReturnTheExpectedResult(){
        String domainKey = 'yahoo.com';
        String countryKey = 'united states';
        String expectedCountryDomainKey = countryKey + '|' + domainKey;
        CompanyProcessorSvc serviceUnderTest = new LeadCompanyProcessorSvc();

        Test.startTest();
            String returnedCountryDomainKey = serviceUnderTest.getCountryDomainKey(countryKey, domainKey);
        Test.stopTest();

        System.assertEquals(expectedCountryDomainKey, returnedCountryDomainKey,
            'GetCountryDomainKey should return a valid country domain key when valid input data is provided');
    }

    @isTest
    static void testGetNormalizedCountryShouldReturnUnitedStatesIfCountryIsNotInCustomSetting(){
        CompanyMatchingCountryMapping__c testCustomSetting = (CompanyMatchingCountryMapping__c) 
                                                new SObjectBuilder (CompanyMatchingCountryMapping__c.SObjectType)
                                                .setField(CompanyMatchingCountryMapping__c.Name, 'CA')
                                                .setField(CompanyMatchingCountryMapping__c.ToCountry__c, 'Canada')
                                                .create()
                                                .getRecord();

        CompanyProcessorSvc serviceUnderTest = new LeadCompanyProcessorSvc();
        Test.startTest();
        String normalizedCountry = serviceUnderTest.getNormalizedCountry('non existant country');
        Test.stopTest();

        System.assertEquals(normalizedCountry, 'United States',
            'If the country to normalize is not in the custom setting it should be normalized to United States');
    }
}