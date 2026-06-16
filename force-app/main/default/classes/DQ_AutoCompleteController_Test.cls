@isTest
public class DQ_AutoCompleteController_Test {
	@testSetup static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='testcasemanager@test.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testcasemanager@test.com');
        insert u;
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void getRecords() {
    	DQ_AutoCompleteController.getRecords('Testing','user','Id','LastName',null,5);
    }
     
}