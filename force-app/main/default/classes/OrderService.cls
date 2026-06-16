@RestResource(urlMapping='/OrderService/*')
global without sharing class OrderService {

    @HttpPost
    global static void handleRequest() {
        String result = '';
        String body = RestContext.request.requestBody.toString();
        BillingWrappers.OrdersParams params = (BillingWrappers.OrdersParams)JSON.deserialize(body, BillingWrappers.OrdersParams.class);
        RestResponse response = RestContext.response;
        if (response == null) {
            response = new RestResponse();
            RestContext.response = response;
        }
        try {
            if (params.action == 'getOrderForSuborderManagement') {
                result = JSON.serialize(getOrderForSuborderManagement(params.orderId));
            }
            if (params.action == 'updateOrder') {
                result = JSON.serialize(updateOrder(params.orderId, params.opportunityId));
            }
            if (params.action == 'updateOrderStatus') {
                result = JSON.serialize(updateOrderStatus(params.orderId, params.status));
            }
            if (params.action == 'updatePackageStatus') {
                result = JSON.serialize(updatePackageStatus(params.orderId, params.status));
            }
            response.responseBody = Blob.valueOf(result);
        } catch(Exception e) {
            Map<String,String> errorMessage = new Map<String,String>();
            errorMessage.put('error', e.getMessage());
            errorMessage.put('stackTrace', e.getStackTraceString());
            response.responseBody = Blob.valueOf(JSON.serialize(errorMessage));
        }
    }

    @TestVisible
    private static Order updateOrder(Id orderId, String opportunityId) {
        Order order = (Order) new ListOptional(new OrderSelector()
            .selectOrdersByIds(new List<Object>{new List<Id>{orderId}})
            .executeQuery()
        ).getFirst();
        if (order != null) {
            order.RelatedChangeOpportunity__c = opportunityId;
            // currently, triggers are switched off, remove, if Triggers logic should be executed in future updates
            Triggers.switchOff();
            update order;
            Triggers.switchOn();
        }
        return order;
    }

    @TestVisible
    private static Order updateOrderStatus(Id orderId, String status) {
        Order order = (Order) new ListOptional(new OrderSelector()
            .selectOrdersByIds(new List<Object>{new List<Id>{orderId}})
            .executeQuery()
        ).getFirst();
        if (order != null && order.Status != status) {
            order.Status = status;
            update order;
        }
        return order;
    }

    @TestVisible
    private static BillingWrappers.OrderWrapper getOrderForSuborderManagement(Id orderId) {
        Order order = (Order) new ListOptional(new OrderSelector()
            .selectOrdersForSuborderManagement(new List<Object>{new List<Id>{orderId}})
            .executeQuery()
        ).getFirst();

        return new BillingWrappers.OrderWrapper(order);
    }

    @TestVisible
    private static Response updatePackageStatus(Id orderId, String status) {
        Order order = (Order) new ListOptional(new OrderSelector()
            .selectOrdersWithPackage(new List<Object>{new List<Id>{orderId}})
            .executeQuery()
        ).getFirst();
        Response resp = new Response();

        if (order.PackageId__r.Id != null && status == OrderHelper.STATUS_COMPLETED) {
            String billingPackageId = order.PackageId__r.Account_Package_Id__c;
            String accountBillingId = order.Account.Billing_ID__c;
            HttpResponse response;
            try {
                response = NGBSAPI.updatePackageStatus(accountBillingId, billingPackageId, PackageHelper.PACKAGE_STATUS_DELETED);
            } catch (Exception e) {
                PlatformLog.logException('OrderService', e);
            }
            if (response.getStatusCode() == 200) {
                Package__c pkg = new Package__c(
                    Id = order.PackageId__r.Id,
                    Package_Status__c = PackageHelper.PACKAGE_STATUS_DELETED
                );
                update pkg;
            }

            resp.setData('responseStatus', response.getStatus());
            resp.setData('responseCode', response.getStatusCode());
            resp.setData('responseBody', response.getBody());
        }

        return resp;
    }
}