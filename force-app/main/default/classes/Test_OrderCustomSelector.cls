@isTest
private class Test_OrderCustomSelector {
    @isTest
    static void testSelectOrders() {
        List<Order__c> orderList = (List<Order__c>) new SObjectBuilder(Order__c.SObjectType)
            .quantity(5)
            .create()
            .getRecords();

        Test.startTest();
            List<Order__c> selectedOrders = new OrderCustomSelector()
                .selectOrders()
                .executeQuery();
        Test.stopTest();

        System.assertEquals(
            orderList.size(),
            selectedOrders.size(),
            'Incorrect Orders were retrieved'
        );
    }

    @isTest
    static void testSelectOrdersForSFToSFSync() {
        List<Order__c> orderList = (List<Order__c>) new SObjectBuilder(Order__c.SObjectType)
            .quantity(5)
            .create()
            .getRecords();

        Test.startTest();
        Set<Id> orderIdSet = new Set<Id>{orderList[0].Id, orderList[1].Id};
            List<Order__c> selectedOrders = (List<Order__c>) new OrderCustomSelector()
                .selectOrdersForSFToSFSync(new List<Object>{orderIdSet})
                .executeQuery();
        Test.stopTest();

        System.assertEquals(
            2,
            selectedOrders.size(),
            'Incorrect Orders were retrieved'
        );
    }
}