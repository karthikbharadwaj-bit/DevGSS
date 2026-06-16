/*******************************************************************************************************
* Project Name..........: Test Utility                                                                 *
* File..................: Test_Utils.class                                                             *
* Version...............: 1.0                                                                          *
* Created by............: Simplion Technologies                                                        *
* Created Date..........: 24-02-2013                                                                   *
* Last Modified by......: Simplion Technologies                                                        *
* Last Modified Date....: 24-02-2013                                                                   *
* Description...........: This is a utility class to setup records for different objects for testing.  *
********************************************************************************************************/
@isTest  
private class Test_UtilityTest {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
		Test_Utils testUtilsObj = new Test_Utils();
		
		List<Account_Metric__c> accountMetricsList =  new List<Account_Metric__c>();
		accountMetricsList.add(new Account_Metric__c());
		accountMetricsList = testUtilsObj.createAccountMetricRecords(accountMetricsList);
		
		List<Account> accountList =  new List<Account>();
		accountList.add(new Account());
		accountList = testUtilsObj.createAccountRecord(accountList);

		List<Contact> contactList =  new List<Contact>();
		contactList.add(new Contact(AccountId = accountList[0].Id));
		contactList = testUtilsObj.createContactRecord(contactList);
		
		List<Implementation__c> implementationRecordsList = new List<Implementation__c>();
		implementationRecordsList.add(new Implementation__c());
		implementationRecordsList = testUtilsObj.createImplementationRecords(implementationRecordsList);

		List<Opportunity> opportunityList = new List<Opportunity>();
		opportunityList.add(new Opportunity());
		opportunityList = testUtilsObj.createOpportunityRecord(opportunityList);
		
		List<Resource_Pool__c> resourcePoolRecordsList =  new List<Resource_Pool__c>();
		resourcePoolRecordsList.add(new Resource_Pool__c());
		resourcePoolRecordsList = testUtilsObj.createResourcePoolRecords(resourcePoolRecordsList);
		
		List<schedulerConfiguration__c> schedulerRecordsList = new List<schedulerConfiguration__c>();
		schedulerRecordsList.add(new schedulerConfiguration__c());
		schedulerRecordsList = testUtilsObj.createSchedulerConfigurationRecords(schedulerRecordsList);

		List<User> userList =  new List<User>();
		userList.add(new User());
		userList = testUtilsObj.createUserRecord(userList);

		List<Time__c> timeSlotRecordsList =  new List<Time__c>();
		timeSlotRecordsList.add(new Time__c());
		timeSlotRecordsList = testUtilsObj.createTimeSlotRecords(timeSlotRecordsList);

		testUtilsObj.deInitialiseTriggerBypass();
		testUtilsObj.initialiseTriggerBypass();
    }
}