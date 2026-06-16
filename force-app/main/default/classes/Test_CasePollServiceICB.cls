@IsTest
private class Test_CasePollServiceICB {

    @IsTest
    private static void testGetByCaseNumber() {
        List<String> caseNumbers;
        List<Case> testCases = new List<Case> {
            new Case(),
            new Case()
        };
        insert testCases;

        testCases = [SELECT CaseNumber FROM Case WHERE Id IN :new Set<Id>{testCases[0].Id, testCases[1].Id}];

        caseNumbers = new List<String>{
            testCases[0].CaseNumber,
            testCases[1].CaseNumber
        };

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"caseNumbers":' + JSON.serialize(caseNumbers) + '}');
        RestContext.request = req;

        CasePollServiceICB.getByCaseNumber();

        String responseBody = RestContext.response.responseBody.toString();

        IcbHelper.IcbResponseParamsData pollResponse = (IcbHelper.IcbResponseParamsData)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParamsData.class);

        System.assertEquals(2, pollResponse.data.cases.size(), 'Response did not return required data');
    }

    @IsTest
    private static void testNotValidRequest() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"caseNumbers":[]}');
        RestContext.request = req;

        CasePollServiceICB.getByCaseNumber();

        String responseBody = RestContext.response.responseBody.toString();

        IcbHelper.IcbResponseParams pollResponse = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        System.assertEquals(IcbHelper.STATUS_ERROR, pollResponse.status, 'It should be validation error');
        System.assert(!pollResponse.messages.isEmpty(), 'Response should contain validation messages');
        System.assertEquals(IcbHelper.EMPTY_REQUEST, pollResponse.messages[0].message,
            'It should be message about empty request');
    }

    @IsTest
    private static void testError() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('not valid json');
        RestContext.request = req;

        CasePollServiceICB.getByCaseNumber();

        String responseBody = RestContext.response.responseBody.toString();

        IcbHelper.IcbResponseParams pollResponse = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        System.assertEquals(IcbHelper.STATUS_ERROR, pollResponse.status, 'It should be caught error');
        System.assert(!pollResponse.messages.isEmpty(), 'Response should contain stack trace');
    }
}