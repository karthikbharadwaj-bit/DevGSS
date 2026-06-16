@isTest
public class OrderStatusUpdateServiceMock implements WebServiceMock {
    public void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {

        OrderStatusUpdateService.orderStatusUpdateResponse_element responseElement = new OrderStatusUpdateService.orderStatusUpdateResponse_element();
        responseElement.isAccepted = true;
        response.put('response_x', responseElement);
    }
}