@IsTest
private class Test_QueueHelper {
    @isTest
    static void testGetPSQueuesMap() {
        Test.startTest();
            Map<String, Id> psQueuesMap = QueueHelper.getPSQueuesMap();
        Test.stopTest();

        Assert.isNotNull(psQueuesMap, 'QueueHelper.getPSQueuesMap() must return a map');
        for (String queueName : QueueHelper.PROSERV_QUEUES) {
            Assert.isTrue(
                psQueuesMap.containsKey(queueName),
                'QueueHelper.getPSQueuesMap() should return a map with key ' + queueName
            );
            Assert.areEqual(
                Group.SobjectType,
                psQueuesMap.get(queueName).getSobjectType(),
                'QueueHelper.getPSQueuesMap() should return an Id value of type Group'
            );
        }
    }
}