@isTest
private class Test_FedRampSyncAccountWS {
    @isTest
    static void testSyncAccountWsSynAccountNew() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.RC_User_ID__c => '123456'
            })
            .create()
            .getRecord();

        SyncAccountWS.syncAcctInputParam syncParams = new SyncAccountWS.syncAcctInputParam();
        syncParams.In_RCUserID = '123456';
        syncParams.In_FirstName = 'testFirstName';
        syncParams.In_LastName = 'testLastName';
        syncParams.In_ContactEmail = 'test@gmail.com';

        FedRampSyncAccountWS.RequestParams requestParams = new FedRampSyncAccountWS.RequestParams();
        requestParams.action = 'SyncAccountWs.synAccountNew';
        requestParams.syncAcctInputParam = new List<SyncAccountWS.syncAcctInputParam>{syncParams};

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(requestParams));

        Test.startTest();
            FedRampSyncAccountWS.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('SyncAccountWs.synAccountNew'), 'SyncAccountWs.synAccountNew parameter is expected');
    }

    @isTest
    static void testSyncAccountWsSynAccountCreateUser() {
        FedRampSyncAccountWS.RequestParams requestParams = new FedRampSyncAccountWS.RequestParams();
        requestParams.action = 'SyncAccountWs.synAccountCreateUser';
        requestParams.syncAcctInputParam = new List<SyncAccountWS.syncAcctInputParam>{new SyncAccountWS.syncAcctInputParam()};

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(requestParams));

        Test.startTest();
            FedRampSyncAccountWS.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('SyncAccountWs.synAccountCreateUser'), 'SyncAccountWs.synAccountCreateUser parameter is expected');
    }

    @isTest
    static void testSyncAccountSynAccountCreateUsers() {
        FedRampSyncAccountWS.RequestParams requestParams = new FedRampSyncAccountWS.RequestParams();
        requestParams.action = 'SyncAccountWs.synAccountCreateUsers';
        requestParams.syncAcctInputParam = new List<SyncAccountWS.syncAcctInputParam>{new SyncAccountWS.syncAcctInputParam()};

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(requestParams));

        Test.startTest();
            FedRampSyncAccountWS.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('SyncAccountWs.synAccountCreateUsers'), 'SyncAccountWs.synAccountCreateUsers parameter is expected');
    }

    @isTest
    static void testSyncAccountWsBillingApplyBillingIdAndPackages() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.RC_User_ID__c => '123456'
            })
            .create()
            .getRecord();

        FedRampSyncAccountWS.RequestParams requestParams = new FedRampSyncAccountWS.RequestParams();
        SyncAccountWsBilling.BillingAcctInfo billAccInfo = new SyncAccountWsBilling.BillingAcctInfo();
        billAccInfo.rcUserID = '1234567';

        requestParams.action = 'SyncAccountWsBilling.applyBillingIdAndPackages';
        requestParams.billingAcctInfo = billAccInfo;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(requestParams));

        Test.startTest();
            FedRampSyncAccountWS.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('SyncAccountWsBilling.applyBillingIdAndPackages'), 'SyncAccountWsBilling.applyBillingIdAndPackages parameter is expected');
    }

    @isTest
    static void testSyncAccountWsBillingSynAccountNew() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.RC_User_ID__c => '123456'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling syncParams = new SyncAccountWsBilling.syncAcctInputParamBilling();
        syncParams.In_RCUserID = '123456';
        syncParams.In_FirstName = 'testFirstName';
        syncParams.In_LastName = 'testLastName';
        syncParams.In_ContactEmail = 'test@gmail.com';

        FedRampSyncAccountWS.RequestParams requestParams = new FedRampSyncAccountWS.RequestParams();
        requestParams.action = 'SyncAccountWsBilling.synAccountNew';
        requestParams.syncAcctInputParamBilling = syncParams;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(requestParams));

        Test.startTest();
            FedRampSyncAccountWS.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('SyncAccountWsBilling.synAccountNew'), 'SyncAccountWsBilling.synAccountNew parameter is expected');
    }

    @isTest
    static void testSyncAccountWsBillingSynAccountCreateUser() {
        FedRampSyncAccountWS.RequestParams requestParams = new FedRampSyncAccountWS.RequestParams();
        requestParams.action = 'SyncAccountWsBilling.synAccountCreateUser';
        requestParams.syncAcctInputParamBilling = new SyncAccountWSBilling.syncAcctInputParamBilling();

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(requestParams));

        Test.startTest();
            FedRampSyncAccountWS.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('SyncAccountWsBilling.synAccountCreateUser'), 'SyncAccountWsBilling.synAccountCreateUser parameter is expected');
    }
}