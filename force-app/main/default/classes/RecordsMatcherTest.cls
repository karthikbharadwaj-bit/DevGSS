@isTest
private class RecordsMatcherTest {
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	private static void testName() {
		List<Account> targetRecords = new List<Account>();
		targetRecords.add(new Account(
			Name = 'TestAccount1',
			Description = '{Name} notEqual TestAccount1%%{Name} notEqual TestAccount2'
		));
		targetRecords.add(new Account(
			Name = 'TestAccount2'
		));
		targetRecords.add(new Account(
			Name = 'TestAccount3'
		));
		targetRecords.add(new Account(
			Name = 'TestAccount4'
		));
		insert targetRecords;
		
		Contact sourceRecord = new Contact(
			Description = '{Name} equal TestAccount1',
			LastName = 'Test',
			AccountId = targetRecords[0].Id
		);
		insert sourceRecord;
		sourceRecord = [select Id, LastName, Description, AccountId, Account.Description from Contact where Id = :sourceRecord.Id];

        List<SObject> results1 = RecordsMatcher.match(targetRecords, sourceRecord, 'Account.Description');
        List<SObject> results2 = RecordsMatcher.match(targetRecords, sourceRecord, 'Description');
        List<SObject> results3 = RecordsMatcher.match(targetRecords, sourceRecord, '{Name} equal TestAccount2', 'string');
        List<SObject> results4 = RecordsMatcher.match(targetRecords, sourceRecord, '{Name} contains TestAccount1', 'string');
        System.assertEquals(1, results4.size(), 'Should contain TestAccount1');
        List<SObject> results5 = RecordsMatcher.match(targetRecords, sourceRecord, '{Name} notcontains TestAccount1', 'string');
        System.assertEquals(3, results5.size(), 'Should not contain TestAccount1');
        List<SObject> results6 = RecordsMatcher.match(targetRecords, sourceRecord, '{Name} startswith Test', 'string');
        List<SObject> results7 = RecordsMatcher.match(targetRecords, sourceRecord, '{Name} endswith Account1', 'string');
    }
}