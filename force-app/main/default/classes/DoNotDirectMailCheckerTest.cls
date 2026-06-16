@IsTest
private class DoNotDirectMailCheckerTest {


    @IsTest
    static void testTogglesReflectLatestValue() {
        Account a = new Account(Name = 'Acme Co');
        insert a;

        // Start with TRUE
        Contact c = new Contact(
            LastName = 'Contact DND',
            AccountId = a.Id,
            Do_Not_Direct_Mail__c = true
        );
        insert c;

        Test.startTest();
        // 1) Should read TRUE
        DoNotDirectMailChecker.Result r1 =
            DoNotDirectMailChecker.getDoNotDirectMail(c.Id);
        

        System.assertEquals('Contact', r1.objectApiName, 'Object API name should be Contact');
        System.assertEquals(true, r1.doNotDirectMail, 'Expected initial TRUE');

        // Toggle to FALSE and read again (should reflect latest)
        c.Do_Not_Direct_Mail__c = false;
        update c;

        
        DoNotDirectMailChecker.Result r2 =
            DoNotDirectMailChecker.getDoNotDirectMail(c.Id);
        Test.stopTest();

        System.assertEquals(false, r2.doNotDirectMail, 'Expected updated FALSE after toggle');
    }

    @IsTest
    static void testObjectWithoutFieldReturnsNull() {
        // Account does NOT have Do_Not_Direct_Mail__c
        Account a = new Account(Name = 'No Field Here');
        insert a;

        Test.startTest();
        DoNotDirectMailChecker.Result r =
            DoNotDirectMailChecker.getDoNotDirectMail(a.Id);
        Test.stopTest();

        System.assertEquals('Account', r.objectApiName, 'Should return the correct object API name');
        System.assertEquals(null, r.doNotDirectMail, 'Should return null when field is absent');
    }

}