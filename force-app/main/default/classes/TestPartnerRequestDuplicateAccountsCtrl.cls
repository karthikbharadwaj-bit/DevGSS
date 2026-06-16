@isTest
private class TestPartnerRequestDuplicateAccountsCtrl {

    private static Integer partnerIdCounter = 0;

    private static String PartnerId
    {
        get {
            partnerIdCounter++;
            return String.valueOf(partnerIdCounter);
        }
    }

    @isTest
    static void partnerRequestWillBeProcessed() {
        Account acc1 = getAccount('Account #1');
        Account acc2 = getAccount('Account #2');

        insert new Account[] { acc1, acc2 };

        Partner_Request__c request = new Partner_Request__c();
        request.Partner_Company_Name__c = 'New Partner Company';
        request.FoundDuplicateAccountIds__c = acc1.Id + ',' + acc2.Id;
        request.Partner_Email_Address__c = 'fake@mail.tld';
        request.Partner_First_Name__c = 'John';
        request.Partner_Last_Name__c = 'Doe';
        request.Partner_Phone__c = '1234567';
        insert request;

        Partner_Request__c[] requests = [
            SELECT FoundDuplicateAccountIds__c
            FROM Partner_Request__c
        ];

        System.assertEquals(1, requests.size(), 'Unexpected record count');

        ApexPages.StandardController ctrl = new ApexPages.StandardController(requests[0]);
        PartnerRequestDuplicateAccountsCtrl prCtrl = new PartnerRequestDuplicateAccountsCtrl(ctrl);

        System.assert(prCtrl.FoundDuplicates != null, 'Unexpected null value');
        System.assertEquals(2, prCtrl.FoundDuplicates.size(), 'Property should contains 2 Account records');
    }

    static Account getAccount(String name) {
        Account a = new Account();
        a.Name = name;
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId();
        a.Partner_ID__c = TestPartnerRequestDuplicateAccountsCtrl.PartnerId;
        return a;
    }
}