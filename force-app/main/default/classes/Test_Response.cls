@isTest
private class Test_Response {

    // constructor
    @isTest
    private static void verifyInitStateWhenEmptyConstructorIsInvoked() {
        Response res = new Response();
        System.assert(res.isSuccess());
        System.assertEquals(0, res.data.size());
        System.assertEquals(0, res.messages.size());
    }
    @isTest
    private static void verifyInitStateWhenConstructorIsInvokedWithMessageDetails() {
        Response res = new Response('test msg', 'test msg details', RESPONSE.SEVERITY_ERROR);
        System.assert(res.isSuccess());
        System.assertEquals(0, res.data.size());
        System.assertEquals(1, res.messages.size());
        Response.ResponseMessage rm = res.messages.get(0);
        System.assertEquals(RESPONSE.SEVERITY_ERROR, rm.severity);
        System.assertEquals('test msg', rm.message);
        System.assertEquals('test msg details', rm.messageDetails);
    }
    @isTest
    private static void verifyInitStateWhenConstructorIsInvokedWithResponseMessages() {
        List<Response.ResponseMessage> messages = new List<Response.ResponseMessage> {
            new Response.ResponseMessage('test msg 1', 'test msg details 1', RESPONSE.SEVERITY_INFO),
            new Response.ResponseMessage('test msg 2', 'test msg details 2', RESPONSE.SEVERITY_WARNING, 'url link', 'url label')
        };
        Response res = new Response(messages);
        System.assert(res.isSuccess());
        System.assertEquals(0, res.data.size());
        System.assertEquals(2, res.messages.size());

        Response.ResponseMessage rm = res.messages.get(0);
        System.assertEquals(RESPONSE.SEVERITY_INFO, rm.severity);
        System.assertEquals('test msg 1', rm.message);
        System.assertEquals('test msg details 1', rm.messageDetails);

        rm = res.messages.get(1);
        System.assertEquals(RESPONSE.SEVERITY_WARNING, rm.severity);
        System.assertEquals('test msg 2', rm.message);
        System.assertEquals('test msg details 2', rm.messageDetails);
        System.assertEquals('url link', rm.url);
        System.assertEquals('url label', rm.urlLabel);
    }
    @isTest
    private static void verifyInitStateWhenConstructorIsInvokedWithException() {
        Response res = new Response( new AquivaHelper.AquivaException('Test exception') );
        System.assert(res.isError());
        System.assertEquals('AquivaHelper.AquivaException', res.typeName);
        System.assert(String.isNotBlank(res.stackTrace));

        System.assertEquals(0, res.data.size());
        System.assertEquals(1, res.messages.size());

        Response.ResponseMessage rm = res.messages.get(0);
        System.assertEquals(RESPONSE.SEVERITY_ERROR, rm.severity);
        System.assertEquals('Test exception', rm.message);
        System.assertEquals(null, rm.messageDetails);
    }
    // error
    @isTest
    private static void verifyStateWhenErrorIsInvokedWithMessageDetails() {
        Response res = new Response();
        res.error('test error msg', 'test error msg details');
        System.assert(res.isError());
        System.assertEquals(1, res.messages.size());

        Response.ResponseMessage rm = res.messages.get(0);
        System.assertEquals(RESPONSE.SEVERITY_ERROR, rm.severity);
        System.assertEquals('test error msg', rm.message);
        System.assertEquals('test error msg details', rm.messageDetails);
    }
    // warning
    @isTest
    private static void verifyStateWhenWarningIsInvokedWithMessage() {
        Response res = new Response();
        res.warning('test warning msg');
        System.assert(res.isWarning());
        System.assertEquals(1, res.messages.size());

        Response.ResponseMessage rm = res.messages.get(0);
        System.assertEquals(RESPONSE.STATUS_WARNING, rm.severity);
        System.assertEquals('test warning msg', rm.message);
        System.assertEquals(null, rm.messageDetails);
    }
    @isTest
    private static void verifyStateWhenWarningIsInvokedWithMessageDetails() {
        Response res = new Response();
        res.warning('test warning msg', 'test warning msg details');
        System.assert(res.isWarning());
        System.assertEquals(1, res.messages.size());

        Response.ResponseMessage rm = res.messages.get(0);
        System.assertEquals(RESPONSE.STATUS_WARNING, rm.severity);
        System.assertEquals('test warning msg', rm.message);
        System.assertEquals('test warning msg details', rm.messageDetails);
    }
    // info
    @isTest
    private static void verifyStateWhenInfoIsInvokedWithMessage() {
        Response res = new Response();
        res.info('test info msg');
        System.assert(res.isInfo());
        System.assertEquals(1, res.messages.size());

        Response.ResponseMessage rm = res.messages.get(0);
        System.assertEquals(RESPONSE.STATUS_INFO, rm.severity);
        System.assertEquals('test info msg', rm.message);
        System.assertEquals(null, rm.messageDetails);
    }
    @isTest
    private static void verifyStateWhenInfoIsInvokedWithMessageDetails() {
        Response res = new Response();
        res.info('test info msg', 'test info msg details');
        System.assert(res.isInfo());
        System.assertEquals(1, res.messages.size());

        Response.ResponseMessage rm = res.messages.get(0);
        System.assertEquals(RESPONSE.STATUS_INFO, rm.severity);
        System.assertEquals('test info msg', rm.message);
        System.assertEquals('test info msg details', rm.messageDetails);
    }
    // messages
    @isTest
    private static void verifyStateWhenAddMessageInInvokedWithUrlParams() {
        Response res = new Response();
        res.addMessage('test msg 2', 'test msg details 2', RESPONSE.SEVERITY_WARNING, 'url link', 'url label');

        Response.ResponseMessage rm = res.messages.get(0);
        System.assertEquals(RESPONSE.SEVERITY_WARNING, rm.severity);
        System.assertEquals('test msg 2', rm.message);
        System.assertEquals('test msg details 2', rm.messageDetails);
        System.assertEquals('url link', rm.url);
        System.assertEquals('url label', rm.urlLabel);
    }

    @isTest
    static void testAddMessageForSWNInstance() {
        Response res = new Response();
        SWNMessageHelper.SWNMessage msg1 = new SWNMessageHelper.SWNMessage();
        SWNMessageHelper.SWNMessage msg2 = new SWNMessageHelper.SWNMessage(
            Response.STATUS_SUCCESS, 'test header', 'test msg'
        );
        Test.startTest();
            res.addMessage(msg1);
            res.addMessage(msg2);
        Test.stopTest();

        Assert.areEqual(1, res.messages.size(), 'Should be only one message');
        Assert.areEqual(msg2.status, res.messages[0].severity, 'Statuses should be equal');
        Assert.areEqual(msg2.header, res.messages[0].message, 'Headers should be equal');
        Assert.areEqual(msg2.message, res.messages[0].messageDetails, 'Messages shoul be equal');
    }
    // data
    @isTest
    private static void verifySetData() {
        Response res = new Response();
        res.setData('test', 'data');
        System.assert(res.isSuccess());
        System.assertEquals(0, res.messages.size());
        System.assertEquals('data', res.getData('test'));
    }
    @isTest
    private static void verifySetDataWithResponse() {
        Response dataRes = new Response();
        dataRes.error('test error msg');
        dataRes.setData('test', 'data');

        Response res = new Response();
        res.setData(dataRes);

        System.assert(res.isError());
        System.assertEquals('data', res.getData('test'));
        System.assertEquals(1, res.messages.size());

        Response.ResponseMessage rm = res.messages.get(0);
        System.assertEquals(RESPONSE.SEVERITY_ERROR, rm.severity);
        System.assertEquals('test error msg', rm.message);
    }
}