@IsTest
private class Test_UniversalDataSyncService {

    private static UniversalDataSyncService.ResponseWrapper invokeProcessWithBody(String body) {
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/universal-data-sync/v1';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        return UniversalDataSyncService.process();
    }

    @IsTest
    static void testProcessMissingBody() {
        RestContext.request = null;
        RestContext.response = new RestResponse();

        UniversalDataSyncService.ResponseWrapper resp = UniversalDataSyncService.process();

        System.assertEquals(false, resp.success, 'Response should not be successful when body is missing.');
        System.assertEquals(1, resp.errors.size(), 'Exactly one error is expected.');
        System.assertEquals('Request body is required.', resp.errors[0]);
    }

    @IsTest
    static void testProcessNullPayload() {
        UniversalDataSyncService.ResponseWrapper resp = invokeProcessWithBody('null');

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(false, resp.success);
        System.assertEquals('Request payload could not be parsed.', resp.errors[0]);
    }

    @IsTest
    static void testProcessUnsupportedOperation() {
        String body = '{"objectApiName":"Account","operation":"DELETE","records":[{"attributes":{"type":"Account"},"Id":"001000000000000AAA"}]}';

        UniversalDataSyncService.ResponseWrapper resp = invokeProcessWithBody(body);

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(false, resp.success);
        System.assertEquals(true, resp.errors[0].contains('Unsupported operation DELETE'));
    }

    @IsTest
    static void testProcessUnknownObjectReturns500() {
        String body = '{"objectApiName":"NonExisting__c","operation":"UPDATE","records":[{"Id":"001000000000000AAA"}]}';

        UniversalDataSyncService.ResponseWrapper resp = invokeProcessWithBody(body);

        System.assertEquals(500, RestContext.response.statusCode);
        System.assertEquals(false, resp.success);
        System.assertEquals(1, resp.errors.size());
    }

    @IsTest
    static void testHandleRequestUpdateSuccess() {
        Account acc = new Account(Name = 'Before Update');
        insert acc;

        UniversalDataSyncService.RequestWrapper wrapper = new UniversalDataSyncService.RequestWrapper();
        wrapper.objectApiName = 'Account';
        wrapper.operation = 'UPDATE';
        wrapper.allOrNone = true;
        wrapper.disableTriggers = false;
        wrapper.records = new List<SObject>{
            new Account(
                Id = acc.Id,
                Name = 'After Update'
            )
        };

        Test.startTest();
        UniversalDataSyncService.ResponseWrapper resp = UniversalDataSyncService.handleRequest(wrapper);
        Test.stopTest();

        System.assertEquals(true, resp.success);

        Account updated = [SELECT Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals('After Update', updated.Name);
    }

    @IsTest
    static void testHandleRequestInsertSuccess() {
        UniversalDataSyncService.RequestWrapper wrapper = new UniversalDataSyncService.RequestWrapper();
        wrapper.objectApiName = 'Account';
        wrapper.operation = 'INSERT';
        wrapper.allOrNone = true;
        wrapper.disableTriggers = false;
        wrapper.records = new List<SObject>{
            new Account(
                Name = 'Inserted From Service'
            )
        };

        Test.startTest();
        UniversalDataSyncService.ResponseWrapper resp = UniversalDataSyncService.handleRequest(wrapper);
        Test.stopTest();

        System.assertEquals(true, resp.success);

        Integer countAcc = [SELECT COUNT() FROM Account WHERE Name = 'Inserted From Service'];
        System.assertEquals(1, countAcc);
    }

    @IsTest
    static void testRequestWrapperHelpers() {
        UniversalDataSyncService.RequestWrapper wrapper = new UniversalDataSyncService.RequestWrapper();

        System.assertEquals('UPDATE', wrapper.getOperation(), 'Default operation should be UPDATE when not set.');

        wrapper.operation = ' insert ';
        System.assertEquals('INSERT', wrapper.getOperation(), 'Operation should be normalized to INSERT.');

        System.assertEquals(false, wrapper.isAllOrNone(), 'allOrNone should default to false.');
        wrapper.allOrNone = true;
        System.assertEquals(true, wrapper.isAllOrNone(), 'allOrNone should be true when explicitly set.');
    }
}