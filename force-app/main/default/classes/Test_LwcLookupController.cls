@isTest
private class Test_LwcLookupController {
    
	@testSetup
	static void testSetup() {
		Account testAccount = TestDataFactory.createAccount(false);
		testAccount.Name = 'TEST 1';
		insert testAccount;
	}

	@isTest
	static void findRecordsTest() {
		List<sobject> result = LwcLookupController.findRecords('TEST ', 'Account', '');
		System.assertNotEquals(null, result);
		System.assertEquals(1, result.size());
	}
}