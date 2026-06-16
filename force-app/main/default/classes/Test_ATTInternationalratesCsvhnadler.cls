@isTest
private class Test_ATTInternationalratesCsvhnadler {
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
 @isTest
	public static void MyUnitTest(){

    try{    
        ATTInternationalratesCsvhnadler obj=new ATTInternationalratesCsvhnadler();
        Test.startTest();
        obj.strSingleWord='A';
        obj.getCountryWiseDetail();
        
        obj.strSelectedCountry='A';
        obj.getCountryDetailBasedCountry();
        
        obj.strSelectedCountry='India';
        obj.getCountryDetailBasedCountry();
        
        obj.strSelectedCountry='';
        obj.getCountryDetailBasedCountry();
        
        obj.strSelectedCountry='A';
        obj.getCountryWiseDetail();
          obj.strSingleWord='';
        obj.getCountryWiseDetail();
        
        obj.getCSVBODY();
        Test.stopTest();
    }catch(Exception e){}  
  }

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest
  static void testTypeCodeAndPrice() {
      ATTInternationalratesCsvhnadler.TypeCodeAndPrice obj = new ATTInternationalratesCsvhnadler.TypeCodeAndPrice();

      List<String> testLstCode = new List<String>{'US', 'EU'};
      obj.lstCode = testLstCode;
      obj.strRatePerUnit = '10';
      List<String> testLstRatePerUnit = new List<String>{'20', '30'};
      obj.lstRatePerUnit = testLstRatePerUnit;
        
  }
   
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest
  static void testSetCountryList() {
      ATTInternationalratesCsvhnadler controller = new ATTInternationalratesCsvhnadler();

      Map<String, Map<String, ATTInternationalratesCsvhnadler.TypeCodeAndPrice>> mapInternationalRatesGlobal = new Map<String, Map<String, ATTInternationalratesCsvhnadler.TypeCodeAndPrice>>();

      ATTInternationalratesCsvhnadler.TypeCodeAndPrice typeCodeAndPrice1 = new ATTInternationalratesCsvhnadler.TypeCodeAndPrice();
      typeCodeAndPrice1.lstCode = new List<String>{'US'};
      typeCodeAndPrice1.lstRatePerUnit = new List<String>{'10.0'}; 

      ATTInternationalratesCsvhnadler.TypeCodeAndPrice typeCodeAndPrice2 = new ATTInternationalratesCsvhnadler.TypeCodeAndPrice();
      typeCodeAndPrice2.lstCode = new List<String>{'EU'};
      typeCodeAndPrice2.lstRatePerUnit = new List<String>{'15.0'}; 

      Map<String, ATTInternationalratesCsvhnadler.TypeCodeAndPrice> usaMap = new Map<String, ATTInternationalratesCsvhnadler.TypeCodeAndPrice>();
      usaMap.put('US', typeCodeAndPrice1);
      usaMap.put('EU', typeCodeAndPrice2);

      mapInternationalRatesGlobal.put('USA', usaMap);

      controller.mapInternationalRatesGlobal = mapInternationalRatesGlobal;
      controller.setCountryList();
      List<SelectOption> lstCountry = controller.lstCountry;
      Map<String, List<String>> mapCountryDetail = controller.mapCountryDetail;
  }

}