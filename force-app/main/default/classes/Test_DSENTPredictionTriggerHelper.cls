@isTest
public class Test_DSENTPredictionTriggerHelper {
	public static User supportT1User;
    public static Case createCase;
    public static Case createCaseWithoutDSENTRec;
    public static List<DSENT_Prediction__c> testData()
    {
        Case createCaseWithDSENTRecInScopeRT = new Case();
        Case createCaseWithDSENTRecOutScopeRT = new Case();
        createCaseWithDSENTRecInScopeRT.RecordTypeId =  Schema.sObjectType.Case.getRecordTypeInfosByName().get('Support - T1').getRecordTypeId();
        createCaseWithDSENTRecOutScopeRT.RecordTypeId =  Schema.sObjectType.Case.getRecordTypeInfosByName().get('CERT').getRecordTypeId();
        
        List<Case> caseList=new List<Case>();
        caseList.add(createCaseWithDSENTRecInScopeRT);
        caseList.add(createCaseWithDSENTRecOutScopeRT);

        Triggers.switchOff();
        insert caseList;
        Triggers.switchOn();
        
        List<DSENT_Prediction__c> listOfTestRecords = new List<DSENT_Prediction__c>();
        for(Integer i=0;i<100;i++){
            DSENT_Prediction__c dsentRecord_i = new DSENT_Prediction__c(Case__c = createCaseWithDSENTRecInScopeRT.Id);
            listOfTestRecords.add(dsentRecord_i);
        }
        for(Integer i=0;i<100;i++){
            DSENT_Prediction__c dsentRecord_i = new DSENT_Prediction__c(Case__c = createCaseWithDSENTRecOutScopeRT.Id);
            listOfTestRecords.add(dsentRecord_i);
        }
        return listOfTestRecords;
    }
    public static void testUser()
    {
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
                    LocaleSidKey = 'en_US'
                ); 
        insert supportT1User;
        
    }
    public static void inScopeApplicationInfo(Boolean inScope)
    {
        if(inScope)
        {
            AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition where label='Service Console'];        
            UserAppInfo u = new UserAppInfo(AppDefinitionId = appDefinition.DurableId, UserId = supportT1User.id,FormFactor = 'Large');        
            insert u;
        }
        else if(!inScope)
        {
            AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition where label='Sales' limit 1];        
            UserAppInfo u = new UserAppInfo(AppDefinitionId = appDefinition.DurableId, UserId = supportT1User.id,FormFactor = 'Large');        
            insert u;
        }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_executeDSENTPredictionTrigger_insert_inScopeApp(){
        Test.starttest();
        testUser();
        System.runAs(supportT1User) {
            inScopeApplicationInfo(true);
            List<DSENT_Prediction__c> listOfTestRecordsInScope = testData();
            try
            {
                Database.SaveResult[] result = Database.insert(listOfTestRecordsInScope);
            }
            catch(DMLException e)
            {
                system.debug(e.getMessage());
            }
        }
        Test.stoptest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_executeDSENTPredictionTrigger_insert_outOfScopeApp(){
        Test.starttest();
        testUser();
        System.runAs(supportT1User) {
            inScopeApplicationInfo(false);
            List<DSENT_Prediction__c> listOfTestRecordsOutOfScope = testData()!=null?testData():new List<DSENT_Prediction__c>();
            try
            {
                if(listOfTestRecordsOutOfScope.size()>0)
                {
                    Database.SaveResult[] result = Database.insert(listOfTestRecordsOutOfScope);
                }
            }
            catch(DMLException e)
            {
                system.debug(e.getMessage());
            }
            
        }
        Test.stoptest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_executeDSENTPredictionTrigger_update()
    {
        Test.starttest();
            testUser();
            System.runAs(supportT1User) {
                inScopeApplicationInfo(true);
                DSENT_Prediction__c updateDSENTRecord = testData()!=null && testData().size()>0 ? testData()[0]:new DSENT_Prediction__c();
                try
                {
                    insert updateDSENTRecord;
                }
                catch(DMLException e)
                {
                    system.debug(e.getMessage());
                }
                updateDSENTRecord.Actions_Taken_by_TL__c = 'Test';
                try
                {
                    update updateDSENTRecord;
                }
                catch(DMLException e)
                {
                    system.debug(e.getMessage());
                }
                DSENT_Prediction__c existingCaseDSENTRecord = new DSENT_Prediction__c();
                existingCaseDSENTRecord.Case__c = updateDSENTRecord.Case__c;
                
                try
                {
                    insert existingCaseDSENTRecord;
                }
                catch(DMLException e)
                {
                    system.debug(e.getMessage());
                }
                
            }
            Test.stoptest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_executeDSENTPredictionTrigger_delete(){
        Test.starttest();
            testUser();
            System.runAs(supportT1User) {
                inScopeApplicationInfo(true);
                DSENT_Prediction__c updateDSENTRecord = testData()!=null && testData().size()>0 ? testData()[0]:new DSENT_Prediction__c();
                insert updateDSENTRecord;
                try
                {
                    delete updateDSENTRecord;
                }
                catch(DMLException e)
                {
                    system.debug(e.getMessage());
                }
            }
            Test.stoptest();
    }
}