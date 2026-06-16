@isTest
private class Test_OrderStatusUpdateService {

    @isTest static void testOrderStatusUpdateInvocation() {
        Test.setMock(WebServiceMock.class, new OrderStatusUpdateServiceMock());
        OrderStatusUpdateService.OrderStatusService wrapper = new OrderStatusUpdateService.OrderStatusService();

        Test.startTest();

        Boolean isAccepted = wrapper.orderStatusUpdate('pon', 'new', 'jcode', 
                                                        Datetime.now(), 'rejected', 
                                                        Date.today(), 'account', Double.ValueOf(1), 'type');
        Test.stopTest();
        System.assert(isAccepted);
    }

}