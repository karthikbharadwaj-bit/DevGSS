@isTest
private class Test_FedRampAccountUpdaterSync {

    static final String RC_USER_ID = '11235';

    @testSetup
    static void createData() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'OldName',
                    Account.RC_User_Id__c => RC_USER_ID
                }
            )
            .create()
            .getRecord();
    }

    @isTest static void testUpdateAccount() {

        Account accUpdt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'NewName',
                    Account.RC_User_Id__c => RC_USER_ID
                }
            )
            .build()
            .getRecord();

        RestRequest request = new RestRequest();
        request.requestUri = 'test.com';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf(JSON.serialize(new List<Account>{accUpdt}));
        RestContext.request = request;

        Test.startTest();
            FedRampAccountUpdaterSync.updateAccount();
        Test.stopTest();

        List<Account> updatedAccounts = (List<Account>) new AccountSelector()
            .selectAccountsByUserIds(new List<Object>{new Set<String>{RC_USER_ID}})
            .executeQuery();

        System.assertEquals(200, RestContext.response.statusCode, 'Status code is not 200');
        System.assertEquals('NewName',
            updatedAccounts.get(0).Name,
            'Name field on Account should be populated with data from request body');
    }
}