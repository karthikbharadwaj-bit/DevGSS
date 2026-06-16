@isTest
private with sharing class Test_LookupService {
    @isTest
    private static void testHandleRequest(){
        List<LookupController.LookupResult> actualResult = new List<LookupController.LookupResult>();
        List<LookupController.LookupResult> expectedResult = new List<LookupController.LookupResult>();

        LookupService.Params myParamsAreaCodes = new LookupService.Params();
        myParamsAreaCodes.action = 'getLookupSearch';
        myParamsAreaCodes.method = 'getAreaCodes';
        myParamsAreaCodes.searchText = 'I guess I try to find something';
        myParamsAreaCodes.recordId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        myParamsAreaCodes.queryLimit = 3;
        myParamsAreaCodes.params = null;
        String JsonMsgAreaCodes = JSON.serialize(myParamsAreaCodes);

        LookupService.Params myParamsAccs = new LookupService.Params();
        myParamsAccs.action = 'getLookupSearch';
        myParamsAccs.method = 'getAccounts';
        myParamsAccs.searchText = 'I guess I try to find something';
        myParamsAccs.recordId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        myParamsAccs.queryLimit = 3;
        myParamsAccs.params = null;
        String JsonMsgAccs = JSON.serialize(myParamsAccs);

        LookupService.Params myParamsCon = new LookupService.Params();
        myParamsCon.action = 'getLookupSearch';
        myParamsCon.method = 'getContacts';
        myParamsCon.searchText = 'I guess I try to find something';
        myParamsCon.recordId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        myParamsCon.queryLimit = 3;
        myParamsCon.params = null;
        String JsonMsgCon = JSON.serialize(myParamsCon);

        LookupService.Params myParamsQuotes = new LookupService.Params();
        myParamsQuotes.action = 'getLookupSearch';
        myParamsQuotes.method = 'getQuotes';
        myParamsQuotes.searchText = 'I guess I try to find something';
        myParamsQuotes.recordId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        myParamsQuotes.queryLimit = 3;
        myParamsQuotes.params = null;
        String JsonMsgQuotes = JSON.serialize(myParamsQuotes);

        LookupService.Params myParamsProducts = new LookupService.Params();
        myParamsProducts.action = 'getLookupSearch';
        myParamsProducts.method = 'getProducts';
        myParamsProducts.searchText = 'I guess I try to find something';
        myParamsProducts.recordId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        myParamsProducts.queryLimit = 3;
        myParamsProducts.params = null;
        String JsonMsgProducts = JSON.serialize(myParamsProducts);

        LookupService.Params myParamsUsers = new LookupService.Params();
        myParamsUsers.action = 'getLookupSearch';
        myParamsUsers.method = 'getUsers';
        myParamsUsers.searchText = 'I guess I try to find something';
        myParamsUsers.recordId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        myParamsUsers.queryLimit = 3;
        myParamsUsers.params = null;
        String JsonMsgUsers = JSON.serialize(myParamsUsers);

        LookupService.Params myParamsQueues = new LookupService.Params();
        myParamsQueues.action = 'getLookupSearch';
        myParamsQueues.method = 'getQueuesSObjects';
        myParamsQueues.searchText = 'I guess I try to find something';
        myParamsQueues.recordId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        myParamsQueues.queryLimit = 3;
        myParamsQueues.params = new Map<String, String>{'nameOfQueueSupportObject' => 'Account'};
        String JsonMsgQueues = JSON.serialize(myParamsQueues);

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/LookupService';
        req.httpMethod = 'POST';

        req.requestBody = Blob.valueof(JsonMsgAreaCodes);
        RestContext.request = req;
        LookupService.handleRequest();

        actualResult = LookupService.getLookupSearch(myParamsAreaCodes);
        expectedResult = LookupController.getAreaCodes(
            myParamsAreaCodes.searchText,
            myParamsAreaCodes.recordId,
            myParamsAreaCodes.queryLimit,
            myParamsAreaCodes.params);
        System.assertEquals(expectedResult, actualResult);

        req.requestBody = Blob.valueof(JsonMsgAccs);
        RestContext.request = req;
        LookupService.handleRequest();

        actualResult = LookupService.getLookupSearch(myParamsAccs);
        expectedResult = LookupController.getAreaCodes(
            myParamsAccs.searchText,
            myParamsAccs.recordId,
            myParamsAccs.queryLimit,
            myParamsAccs.params);
        System.assertEquals(expectedResult, actualResult);

        req.requestBody = Blob.valueof(JsonMsgCon);
        RestContext.request = req;
        LookupService.handleRequest();

        actualResult = LookupService.getLookupSearch(myParamsCon);
        expectedResult = LookupController.getAreaCodes(
            myParamsCon.searchText,
            myParamsCon.recordId,
            myParamsCon.queryLimit,
            myParamsCon.params);
        System.assertEquals(expectedResult, actualResult);

        req.requestBody = Blob.valueof(JsonMsgQuotes);
        RestContext.request = req;
        LookupService.handleRequest();

        actualResult = LookupService.getLookupSearch(myParamsQuotes);
        expectedResult = LookupController.getAreaCodes(
            myParamsQuotes.searchText,
            myParamsQuotes.recordId,
            myParamsQuotes.queryLimit,
            myParamsQuotes.params);
        System.assertEquals(expectedResult, actualResult);

        req.requestBody = Blob.valueof(JsonMsgProducts);
        RestContext.request = req;
        LookupService.handleRequest();

        actualResult = LookupService.getLookupSearch(myParamsProducts);
        expectedResult = LookupController.getProducts(
            myParamsProducts.searchText,
            myParamsProducts.recordId,
            myParamsProducts.queryLimit,
            myParamsProducts.params);
        System.assertEquals(expectedResult, actualResult);

        req.requestBody = Blob.valueof(JsonMsgUsers);
        RestContext.request = req;
        LookupService.handleRequest();

        actualResult = LookupService.getLookupSearch(myParamsUsers);
        expectedResult = LookupController.getUsers(
            myParamsUsers.searchText,
            myParamsUsers.recordId,
            myParamsUsers.queryLimit,
            myParamsUsers.params);
        System.assertEquals(expectedResult, actualResult);

        req.requestBody = Blob.valueof(JsonMsgQueues);
        RestContext.request = req;
        LookupService.handleRequest();

        actualResult = LookupService.getLookupSearch(myParamsQueues);
        expectedResult = LookupController.getQueuesSObjects(
            myParamsQueues.searchText,
            myParamsQueues.recordId,
            myParamsQueues.queryLimit,
            myParamsQueues.params);
        System.assertEquals(expectedResult, actualResult);
        Test.stopTest();
    }
}