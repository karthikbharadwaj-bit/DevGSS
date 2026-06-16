@isTest
public class Test_AccountStructure {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testAccountStructure() {
        Account testAccount1 = new Account();
        testAccount1.Name = 'Test123';
        testAccount1.SignupType__c = 'TRIAL_30NOCC';
        testAccount1.RC_Account_Status__c = 'TRIAL';
        testAccount1.SignupPlatform__c = 'WEB';
        testAccount1.RC_Service_name__c = 'office123';
        testAccount1.RC_Activation_Date__c = null;
        testAccount1.Partner_ID__c = '9852';
        testAccount1.ZI_Id__c='12345';
        insert testAccount1;
        
        AccountStructure.findHierarchyData(testAccount1.id);
    }

}