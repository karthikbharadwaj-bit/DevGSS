@isTest
private class HelperUtils_Test {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
        // TO DO: implement unit test
        
        List<Account> accLst = new List<Account>();
        accLst.add(new Account(Name = 'Account 1', Account_Mobile_Number__c = '09013038181'));
        insert accLst;
        Carrier_Data__c crrObj = new Carrier_Data__c(Carrier_Wireless_Phone_Number__c = '09013038181');
        insert crrObj;
        
        HelperUtils.updateCarrierDataRecordNew(accLst);
        
    }

    @isTest
    static void testIsSObjectInList() {

        String testAccId1 = (String) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();
        String testAccId2 = testAccId1.substring(0, testAccId1.length() - 1) + 'A';

        List<Account> accLst = (List<Account>)  new SObjectBuilder(Account.SObjectType)
            .setField(Account.Id, (Id) testAccId1)
            .quantity(1)
            .build()
            .getRecords();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Id, (Id) testAccId2)
            .build()
            .getRecord();

        Assert.isFalse(HelperUtils.isSObjectInList(acc2, accLst), 'SObject must not be in list');

        accLst.add(acc2);
        Assert.isTrue(HelperUtils.isSObjectInList(acc2, accLst), 'SObject must be in list');
        
    }
}