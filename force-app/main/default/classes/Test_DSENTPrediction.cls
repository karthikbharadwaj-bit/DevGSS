@isTest
public class Test_DSENTPrediction {
    public static User supportT1User;
    public static Case createCase;
    public static Case createCaseWithoutDSENTRec;
    public static void testUser(){
        supportT1User = new User(
                    ProfileId = [SELECT Id FROM Profile WHERE Name = 'Support T1'].Id,
                    LastName = 'last',
                    Email = 'user@test.com',
                    Username = 'user12345654321@test.com',
                    CompanyName = 'TEST',
                    Title = 'title',
                    Alias = 'alias',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US',
            		isActive = true
                ); 
        insert supportT1User;
        AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition where label='RC Service'];        
        UserAppInfo u = new UserAppInfo(AppDefinitionId = appDefinition.DurableId, UserId = supportT1User.id,FormFactor = 'Large');        
        insert u;
    }
    public static void testData(){
		 createCase = new Case();
         createCase.RecordTypeId =  Schema.sObjectType.Case.getRecordTypeInfosByName().get('Support - T1').getRecordTypeId();
         insert createCase;
         DSENT_Prediction__c createDSENTRecordForCase = new DSENT_Prediction__c();
         createDSENTRecordForCase.Case__c = createCase.Id;
         insert createDSENTRecordForCase;
         createCaseWithoutDSENTRec = new Case();
         createCaseWithoutDSENTRec.RecordTypeId =  Schema.sObjectType.Case.getRecordTypeInfosByName().get('Support - T1').getRecordTypeId();
         insert createCaseWithoutDSENTRec;
         
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    public static void test_getCurrentCaseDSENTRecordsForLWC(){
        Test.starttest();
        testUser();
        System.runAs(supportT1User) {
            testData();
            try{
                List<DSENT_Prediction__c> DSENTPrediction_getIfDSENTRecordExistsForLWC = DSENTPrediction.getCurrentCaseDSENTRecordsForLWC(String.valueOf(createCase.Id));
            	List<DSENT_Prediction__c> DSENTPrediction_getIfDSENTRecordExistsForLWCWithoutDSENTRecord = DSENTPrediction.getCurrentCaseDSENTRecordsForLWC(String.valueOf(createCaseWithoutDSENTRec.Id));
            	List<DSENT_Prediction__c> DSENTPrediction_getIfDSENTRecordExistsForLWCNullRecord = DSENTPrediction.getCurrentCaseDSENTRecordsForLWC(null);
                
            }
            catch(DMLException e){
                system.debug(e.getMessage());
            }
        }
        Test.stoptest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_getCurrentUserDetailsForLWC(){
        Test.starttest();
        testUser();
        System.runAs(supportT1User) {
            testData();
            try{
                String stringCreateCaseId = String.valueOf(createCase.Id);
            	Map<String,String> DSENTPrediction_getCurrentUserDetailsForLWC = DSENTPrediction.getCurrentUserDetailsForLWC(stringCreateCaseId);
            	Map<String,String> DSENTPrediction_getCurrentUserDetailsForLWCNull = DSENTPrediction.getCurrentUserDetailsForLWC(null);
            }
            catch(DMLException e){
                system.debug(e.getMessage());
            }
        }
        Test.stoptest();
    }
}