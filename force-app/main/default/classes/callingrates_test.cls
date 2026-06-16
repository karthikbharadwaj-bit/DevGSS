@isTest
private class callingrates_test {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
        // TO DO: implement unit test
        Folder fd = [SELECT Id FROM Folder WHERE Name='VIIFPRInternationalCallingRates'];
        Blob blbObj = Blob.valueOf('44,United Kingdom,1418,United Kingdom - Freephone,Freephone,National Destinations (03 and 05),500,Free');
        Document doc = new Document(Name='BT_Calling_Rates', Body = blbObj ,folderId = fd.Id,isPublic=true,type='csv' );
        insert doc;
		
        callingrates ctrlObj = new callingrates();
        ctrlObj.strSelectedCountry = 'afghanistan';
        ctrlObj.getCountryWiseRates();
        ctrlObj.strSelectedCountry = 'a_';
        ctrlObj.getAllInternationRates();
        ctrlObj.strDomesticName = '1223';
        ctrlObj.getDomesticRates();
        ctrlObj.strDomesticName = 'a_';
        ctrlObj.getAllDomesticRates();
        ctrlObj.getShowDomesticResultPanel();
        ctrlObj.getShowInternationalResultPanel();
    }
    
    @isTest
    static void testRatesWrappConstructor() {

        String countryCode = 'US';
        String countryName = 'United States';
        String domesticCode = '123';
        String domesticName = 'Domestic';
        String internationalType = 'International';
        String domesticType = 'Domestic';
        String areaList = 'Area 1, Area 2';
        String rates = '10 cents per minute';
        String connectionPrice = 'Free';
        String accessCharge = 'None';
        
        callingrates.RatesWrapp rw = new callingrates.RatesWrapp(countryCode, countryName, domesticCode, domesticName, internationalType, domesticType, areaList, rates, connectionPrice, accessCharge);
        
        System.assertEquals(countryCode, rw.countryCode);
        System.assertEquals(countryName, rw.countryName);
        System.assertEquals(domesticCode, rw.domesticCode);
        System.assertEquals(domesticName, rw.domesticName);
        System.assertEquals(internationalType, rw.internationalType);
        System.assertEquals(domesticType, rw.domesticType);
        System.assertEquals(areaList, rw.areaList);
        System.assertEquals(rates, rw.rates);
        System.assertEquals(connectionPrice, rw.connectionPrice);
        System.assertEquals(accessCharge, rw.accessCharge);
    }
    
    @isTest
    static void testGetAlphaWiseRates() {
        callingrates ctrlObj = new callingrates();
        ctrlObj.strSingleWord = 'example';

        Test.startTest();
        PageReference result = ctrlObj.getAlphaWiseRates();
        Test.stopTest();

        System.assertEquals(null, result);
    }
    
    @isTest
    static void testProcessCSVData() {

        List<List<String>> testData = new List<List<String>>();
        List<String> row1 = new List<String>{'US', 'United States', 'US', 'USA', 'International', 'Domestic', 'Area1', '10', '5', '2'};
        List<String> row2 = new List<String>{'CA', 'Canada', 'CA', 'CAN', 'International', 'Domestic', 'Area2', '15', '7', '3'};
        testData.add(row1);
        testData.add(row2);
        
        Test.startTest();
        callingrates instance = new callingrates();
        instance.processCSVData(testData);
        Test.stopTest();
        
        System.assertEquals(true, instance.mapCountry.containsKey('U'));
        System.assertEquals(true, instance.mapCountry.containsKey('C'));
        System.assertEquals(2, instance.filterKey.size());
    }
}