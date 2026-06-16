@isTest
private class Test_EndpointsSettingsHandler {
    @isTest
    private static void testUqtServerEndpoint() {
        String endpoint = 'https://test.endpoint.com';
        insert new EndpointsSettings__c(UQTServerEndpoint__c = endpoint);
        Assert.areEqual(endpoint, EndpointsSettingsHandler.uqtServerEndpoint, 'The UQTServerEndpoint__c should match the test value.');
    }
}