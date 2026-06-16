/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Test_GraduationScoreCardHelper {

    @isTest
    static void GraduationScoreCardHelperTest() {
        
        GraduationScoreCardHelper objGraduationScoreCardHelper = new GraduationScoreCardHelper();
        List<Account> listAccount =  getAccountTestRecords();
        insert listAccount;
        List<Implementation__c> listImpl = getImplementationTestRecords(listAccount[1].Id);
    	insert listImpl;
    	
    	System.assertNotEquals(null,GraduationScoreCardHelper.getImplementationCompletionDetails(listImpl[0], null, GraduationScoreCardHelper.STR_INSERT));
    	System.assertNotEquals(null,GraduationScoreCardHelper.getImplementationCompletionDetails(listImpl[1], listImpl[0], GraduationScoreCardHelper.STR_UPDATE));
    	System.assertNotEquals(null,GraduationScoreCardHelper.getImplementationCompletionDetails(listImpl[0], listImpl[1], GraduationScoreCardHelper.STR_UPDATE));
    	
    	GraduationScoreCardHelper.updateAccountOnImplementationDeletion(listImpl);
    	List<Account_Metric__c> listAccountMetring = getAccountMetricTestRecords(listAccount[0].Id, listAccount[1].Id);
    	insert listAccountMetring;
    	GraduationScoreCardHelper.adopGradCompRateOnAccountMetric(listAccountMetring, null);
    	
    	Map<Id, Account_Metric__c> mapMetric = new Map<Id, Account_Metric__c>();
        mapMetric.put(listAccountMetring[0].Id,listAccountMetring[0]);
        mapMetric.put(listAccountMetring[1].Id,listAccountMetring[1]);
    	
    	GraduationScoreCardHelper.adopGradCompRateOnAccountMetric(listAccountMetring, mapMetric);
    	
    	mapMetric.put(listAccountMetring[1].Id,listAccountMetring[0]);
        mapMetric.put(listAccountMetring[0].Id,listAccountMetring[1]);
    	
    	GraduationScoreCardHelper.adopGradCompRateOnAccountMetric(listAccountMetring, mapMetric);
    	GraduationScoreCardHelper.calculateCompletionOnAccountMetricDeletion(listAccountMetring);
    	
    	List<Case> listCAse = getCaseList(listAccount[0].Id);
    	insert listCase;
    	Map<Id, Case> mapCase = new Map<Id, Case>();
    	mapCase.put(listCase[0].Id, listCase[0]);
    	GraduationScoreCardHelper.calculateGraduationCompletionRateOverCase(listCAse,mapCase);
    	listAccountMetring[0].Metric_23_value__c = null;
    	listAccountMetring[1].Metric_23_value__c = 12;
    	GraduationScoreCardHelper.checkValuesAdoption(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_23_value__c = 2;
    	listAccountMetring[1].Metric_23_value__c = 12;
    	GraduationScoreCardHelper.checkValuesAdoption(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_18_value__c = null;
    	listAccountMetring[1].Metric_18_value__c = 12;
    	GraduationScoreCardHelper.checkValuesAdoption(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_18_value__c = 2;
    	listAccountMetring[1].Metric_18_value__c = 12;
    	GraduationScoreCardHelper.checkValuesAdoption(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_27_value__c = null;
    	listAccountMetring[1].Metric_27_value__c = 12;
    	GraduationScoreCardHelper.checkValuesAdoption(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_27_value__c = 2;
    	listAccountMetring[1].Metric_27_value__c = 12;
    	GraduationScoreCardHelper.checkValuesAdoption(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_11_value__c = null;
    	listAccountMetring[1].Metric_11_value__c = 12;
    	GraduationScoreCardHelper.checkValuesAdoption(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_11_value__c = 2;
    	listAccountMetring[1].Metric_11_value__c = 12;
    	GraduationScoreCardHelper.checkValuesAdoption(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_18_value__c = 12;
    	listAccountMetring[1].Metric_18_value__c = null;
    	GraduationScoreCardHelper.checkValuesAdoption(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_27_value__c = 12;
    	listAccountMetring[1].Metric_27_value__c = NULL;
    	GraduationScoreCardHelper.checkValuesAdoption(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_11_value__c = 12;
    	listAccountMetring[1].Metric_11_value__c = null;
    	GraduationScoreCardHelper.checkValuesAdoption(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_3_value__c=null;
    	listAccountMetring[1].Metric_3_value__c=12;
    	GraduationScoreCardHelper.checkValuesGraduation(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_3_value__c=2;
    	listAccountMetring[1].Metric_3_value__c=12;
    	GraduationScoreCardHelper.checkValuesGraduation(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_28_value__c=null;
    	listAccountMetring[1].Metric_28_value__c=12;
    	GraduationScoreCardHelper.checkValuesGraduation(listAccountMetring[0],listAccountMetring[1]);
    	
    	listAccountMetring[0].Metric_28_value__c=2;
    	listAccountMetring[1].Metric_28_value__c=12;
    	GraduationScoreCardHelper.checkValuesGraduation(listAccountMetring[0],listAccountMetring[1]);
    	
    	listImpl[0].Account__c = null;
    	listImpl[1].Account__c = null;
    	GraduationScoreCardHelper.updateAccountOnImplementationDeletion(listImpl);
    	
    	listAccount[0].Graduation_Kit__c = true;
    	GraduationScoreCardHelper.getGraduationCompRateAccount(listAccount[0]);
    	
    	listAccount[0].Current_Owner_Email__c = 'abc@cc.com';
    	GraduationScoreCardHelper.getGraduationCompRateAccount(listAccount[0]);
    	
    	listAccount[0].Current_Owner_Email__c = 'sfdchelp@ringcentral.com';
    	listAccount[0].Number_of_DL_s__c=5;
    	GraduationScoreCardHelper.getGraduationCompRateAccount(listAccount[0]);
    }
    
     public static List<Account> getAccountTestRecords(){ 
    	
    	List<Account> listAccount = new List<Account>();
    	Account objAccount = new Account(Name='Test1', Current_Owner_Email__c='abc@test.com',Number_of_DL_s__c=260);
    	
    	listAccount.add(objAccount);
    	
    	Account objAccount1 = new Account(Name='Test2', Current_Owner_Email__c='abc@test.com',Number_of_DL_s__c=20);
    	listAccount.add(objAccount1);
    	
    	//insert listAccount;
    	
    	return listAccount;
    }
    
    public static List<Implementation__c> getImplementationTestRecords(String strAccountId){
    	
    	List<Implementation__c> listImpl = new List<Implementation__c>();
    	Implementation__c objImpl = new Implementation__c();
    	objImpl.Account__c = strAccountId;
    	objImpl.Account_Review__c =  'Overview;Messages;Activity Log;Contacts;Billing;Webinars;Support Portal;Survey';
        objImpl.Company_Numbers_and_Info__c =  'Company Caller ID;Company Address;Add Number;User My Existing Number (Porting)';
        objImpl.Users__c = 'Unassigned Ext;Add Users;Permissions;User Info;Phones & Numbers;Screening, Greeting;& Hold Music;Call Handling and Forwarding;Messages & Notifications;Outbound Caller ID;Outbound Fax Settings';
        objImpl.Phones_Devices__c =  'Phone Serial Number;Phone Nickname;E911';
        objImpl.Groups__c = 'Add Group;Call Queues;Paging;Shared Lines';
        objImpl.Tools__c =  'Mobile App;Softphone;RC Meetings';
    	listImpl.add(objImpl);
    	
    	Implementation__c objImpl1 = new Implementation__c();
    	objImpl1.Account__c = strAccountId;
    	objImpl1.Account_Review__c =  'Overview;Messages;Activity Log;Contacts;Billing;Webinars;Support Portal';
        objImpl1.Company_Numbers_and_Info__c =  'Company Caller ID;Company Address;Add Number';
        objImpl1.Users__c = 'Unassigned Ext;Add Users;Permissions;User Info;Phones & Numbers;Screening, Greeting;& Hold Music;Call Handling and Forwarding;Messages & Notifications;Outbound Caller ID;Outbound Fax Settings';
        objImpl1.Phones_Devices__c =  'Phone Serial Number;Phone Nickname';
        objImpl1.Groups__c = 'Add Group;Call Queues;Paging;';
        objImpl1.Tools__c =  'Mobile App;Softphone;';
    	listImpl.add(objImpl1);
    	
    	//insert listImpl;
    	
    	return listImpl;
    }
    
     public static List<Account_Metric__c> getAccountMetricTestRecords(String strAccountId1, String strAccount2){
    	
    	List<Account_Metric__c> listAccount = new List<Account_Metric__c>();
    	Account_Metric__c objAccount = new Account_Metric__c();
    	objAccount.Account_ID__c = strAccountId1;
    	objAccount.Metric_3_value__c = 12;
    	objAccount.Metric_11_value__c = 1;
    	objAccount.Metric_18_value__c = 2;
    	objAccount.Metric_23_value__c = 2;
    	objAccount.Metric_27_value__c = 1;
    	objAccount.Metric_28_value__c = .5;
    	listAccount.add(objAccount);
    	
    	Account_Metric__c objAccount1 = new Account_Metric__c();
    	objAccount1.Account_ID__c = strAccount2;
    	objAccount1.Metric_3_value__c = 11;
    	objAccount1.Metric_11_value__c = 11;
    	objAccount1.Metric_18_value__c = 22;
    	objAccount1.Metric_23_value__c = 22;
    	objAccount1.Metric_27_value__c = 12;
    	objAccount1.Metric_28_value__c = 1.5;
    	listAccount.add(objAccount1);
    	
    	//insert listAccount;
    	
    	return listAccount;
    }
    
    public static List<Case> getCaseList(String strAccountId){
    	String recTypeId = Schema.SObjectType.Case.RecordTypeInfosByName.get('Support - T3').RecordTypeId ;
    	List<Case> listCase = new List<Case>();
    	Case objCase = new Case(AccountId=strAccountId, RecordTypeId = recTypeId);
    	listCase.add(objCase);
    	return listCase;
    }

    @isTest
    static void testPicklistDontHaveSameValue() {
        Test.startTest();
            // Test scenario 1: Both strings are null
            Boolean result1 = GraduationScoreCardHelper.picklistDontHaveSameValue(null, null);
            
            // Test scenario 2: First string is null, second is not
            Boolean result2 = GraduationScoreCardHelper.picklistDontHaveSameValue(null, 'Value1;Value2');
            
            // Test scenario 3: First string is not null, second is null
            Boolean result3 = GraduationScoreCardHelper.picklistDontHaveSameValue('Value1;Value2', null);
            
            // Test scenario 4: Both strings have same values
            Boolean result4 = GraduationScoreCardHelper.picklistDontHaveSameValue('Value1;Value2', 'Value1;Value2');
            
            // Test scenario 5: Strings have different values
            Boolean result5 = GraduationScoreCardHelper.picklistDontHaveSameValue('Value1;Value2', 'Value1;Value3');
            
            // Test scenario 6: First string has more values
            Boolean result6 = GraduationScoreCardHelper.picklistDontHaveSameValue('Value1;Value2;Value3', 'Value1;Value2');
            
            // Test scenario 7: Second string has more values
            Boolean result7 = GraduationScoreCardHelper.picklistDontHaveSameValue('Value1;Value2', 'Value1;Value2;Value3');
        Test.stopTest();
        
        System.assertEquals(false, result1, 'Both null strings should return false');
        System.assertEquals(true, result2, 'First null, second not null should return true');
        System.assertEquals(true, result3, 'First not null, second null should return true');
        System.assertEquals(false, result4, 'Same values should return false');
        System.assertEquals(true, result5, 'Different values should return true');
        System.assertEquals(true, result6, 'First string with extra value should return true');
        System.assertEquals(true, result7, 'Second string with extra value should return true');
    }
    
    @isTest
    static void testCalculateGraduationCompletionRate() {
        // Create test data using SObjectBuilder
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Graduation Account',
                    Account.Graduation_Kit__c => true,
                    Account.Current_Owner_Email__c => 'test@example.com',
                    Account.Number_of_DL_s__c => 100
                }
            )
            .create()
            .getRecord();
            
        Account_Metric__c metric = (Account_Metric__c) new SObjectBuilder(Account_Metric__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Metric__c.Account_ID__c => acc.Id,
                    Account_Metric__c.Metric_3_value__c => 5,
                    Account_Metric__c.Metric_28_value__c => 0.5,
                    Account_Metric__c.Adoption_Phase_Completion_Rate__c => 80
                }
            )
            .create()
            .getRecord();
            
        Implementation__c impl = (Implementation__c) new SObjectBuilder(Implementation__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Implementation__c.Account__c => acc.Id,
                    Implementation__c.Account_Graduation_Status__c => 'Done'
                }
            )
            .create()
            .getRecord();
            
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.AccountId => acc.Id,
                    Case.RecordTypeId => Schema.SObjectType.Case.RecordTypeInfosByName.get('Support - T3').RecordTypeId
                }
            )
            .create()
            .getRecord();
            
        // Test the method
        List<Account> accounts = new List<Account>{ acc };
        Map<Id, Account> oldMap = new Map<Id, Account>{ acc.Id => acc.clone(true, true, true) };
            
        Test.startTest();
            GraduationScoreCardHelper.calculateGraduationCompletionRate(accounts, oldMap);
        Test.stopTest();
            
        // Verify results
        Account_Metric__c updatedMetric = [
            SELECT Id, Graduation_Phase_Completion_Rate__c, Account_Graduation_Status__c 
            FROM Account_Metric__c 
            WHERE Id = :metric.Id
        ];
            
        System.assertNotEquals(null, updatedMetric.Graduation_Phase_Completion_Rate__c, 
            'Graduation Phase Completion Rate should be calculated');
        System.assertEquals('Done', updatedMetric.Account_Graduation_Status__c, 
            'Account Graduation Status should be updated to Done');
    }
    
    @isTest
    static void testCheckCaseRecordType() {
        // Create test cases with different record types
        Id supportT3RecTypeId = Schema.SObjectType.Case.RecordTypeInfosByName.get('Support - T3').RecordTypeId;
        Id otherRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().values()[0].getRecordTypeId();
        if (otherRecTypeId == supportT3RecTypeId && Schema.SObjectType.Case.getRecordTypeInfosByName().values().size() > 1) {
            otherRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().values()[1].getRecordTypeId();
        }
        
        Case newCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Subject => 'Test Case',
                    Case.RecordTypeId => supportT3RecTypeId
                }
            )
            .build()
            .getRecord();
            
        Case oldCase = newCase.clone(true, true, true);
        oldCase.RecordTypeId = otherRecTypeId;
        
        Map<Id, Case> oldMap = new Map<Id, Case>();
        oldMap.put(newCase.Id, oldCase);
        
        Test.startTest();
            // Test when record type changes to T3
            Boolean result1 = GraduationScoreCardHelper.checkCaseRecordType(newCase, oldMap, supportT3RecTypeId);
            
            // Test when record type changes from T3
            Case newCase2 = newCase.clone(true, true, true);
            newCase2.RecordTypeId = otherRecTypeId;
            Case oldCase2 = oldCase.clone(true, true, true);
            oldCase2.RecordTypeId = supportT3RecTypeId;
            Map<Id, Case> oldMap2 = new Map<Id, Case>();
            oldMap2.put(newCase2.Id, oldCase2);
            Boolean result2 = GraduationScoreCardHelper.checkCaseRecordType(newCase2, oldMap2, supportT3RecTypeId);
            
            // Test when no record type change
            Case newCase3 = newCase.clone(true, true, true);
            newCase3.RecordTypeId = otherRecTypeId;
            Case oldCase3 = oldCase.clone(true, true, true);
            oldCase3.RecordTypeId = otherRecTypeId;
            Map<Id, Case> oldMap3 = new Map<Id, Case>();
            oldMap3.put(newCase3.Id, oldCase3);
            Boolean result3 = GraduationScoreCardHelper.checkCaseRecordType(newCase3, oldMap3, supportT3RecTypeId);
        Test.stopTest();
        
        System.assertEquals(true, result1, 'Should return true when changing to T3 record type');
        System.assertEquals(true, result2, 'Should return true when changing from T3 record type');
        System.assertEquals(false, result3, 'Should return false when no record type change');
    }
    
    @isTest
    static void testGetAdoptionCompRateAccountMetric() {
        // Create test data
        Account_Metric__c metric = (Account_Metric__c) new SObjectBuilder(Account_Metric__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Metric__c.Metric_18_value__c => 1, // 100% of 25 = 25
                    Account_Metric__c.Metric_23_value__c => 2, // > 1 = 25
                    Account_Metric__c.Metric_27_value__c => 0, // >= 0 = 25
                    Account_Metric__c.Metric_11_value__c => 1  // = 1 = 25
                }
            )
            .build()
            .getRecord();
            

        Decimal result = GraduationScoreCardHelper.getAdoptionCompRateAccountMetric(metric);

        // Should return 100 (25 + 25 + 25 + 25)
        System.assertEquals(100, result, 'Adoption completion rate calculation should be correct');
        
        // Test with different values
        metric.Metric_18_value__c = 0.5; // 50% of 25 = 12.5
        metric.Metric_23_value__c = 0; // <= 1 = 0
        
        Test.startTest();
            Decimal result2 = GraduationScoreCardHelper.getAdoptionCompRateAccountMetric(metric);
        Test.stopTest();
        
        // Should return 12.5 + 0 + 25 + 25 = 62.5
        System.assertEquals(62.5, result2, 'Adoption completion rate calculation should reflect new values');
    }
    
    @isTest
    static void testGetGraduationCompRateAccountMetric() {
        // Create test data
        Account_Metric__c metric = (Account_Metric__c) new SObjectBuilder(Account_Metric__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Metric__c.Metric_3_value__c => 2, // > 1 = 12.5
                    Account_Metric__c.Metric_28_value__c => 0.5 // < 1 = 50
                }
            )
            .build()
            .getRecord();
            
        Decimal result = GraduationScoreCardHelper.getGraduationCompRateAccountMetric(metric);
        
        // Should return 62.5 (12.5 + 50)
        System.assertEquals(62.5, result, 'Graduation completion rate calculation should be correct');
        
        // Test with different values
        metric.Metric_3_value__c = 0.5; // <= 1 = 0
        metric.Metric_28_value__c = 1.5; // >= 1 = 0
        
        Test.startTest();
            Decimal result2 = GraduationScoreCardHelper.getGraduationCompRateAccountMetric(metric);
        Test.stopTest();
        
        // Should return 0 (0 + 0)
        System.assertEquals(0, result2, 'Graduation completion rate calculation should reflect new values');
    }
}