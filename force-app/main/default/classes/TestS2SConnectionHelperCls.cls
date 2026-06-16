@isTest
private class TestS2SConnectionHelperCls {
    static final String TELUS = 'TELUS';

    @isTest
    static void testGetConnectionIdPositive() {
        PartnerNetworkConnection[] telusActiveConnection = [
            SELECT Id
            FROM PartnerNetworkConnection
            WHERE ConnectionStatus = 'Accepted' AND ConnectionName = :TestS2SConnectionHelperCls.TELUS
        ];
        System.assert(telusActiveConnection.size() == 1, 'Could not find active TELIS connection Id');

        Set<Id> methodResult = S2SConnectionHelperCls.getConnectionId(TestS2SConnectionHelperCls.TELUS);
        System.assert(methodResult.size() == 1, 'S2SConnectionHelperCls.getConnectionId() returned unexpected result');

        System.assert(methodResult.contains(telusActiveConnection[0].Id), 'S2SConnectionHelperCls.getConnectionId() ' +
            'returned unexpected Id');
    }
}