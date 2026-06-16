@isTest
private class Test_OrderItemSelector {
    private static String basePattern = '(^SELECT){1}(\\s[A-z0-9.]+,?\\s?)+';
    private static String subPattern = '(\\(SELECT(\\s[A-z0-9.]+,?)+\\s)';

    private static Set<Id> setIds = new Set<Id>{null};
    private static List<Object> bindings = new List<Object>{setIds};

    @isTest
    private static void verifyOrderItemsByOrderIdsReturnCorrectQuery() {
        QueryFactory qf = new OrderItemSelector()
            .selectOrderItemsByOrderIds(bindings)
            .setQuery();
        String pattern = basePattern + '(FROM OrderItem WHERE OrderId IN :bind0)';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }
    
    @isTest
    private static void verifySelectOrderItemsByIdAndExtId() {
        QueryFactory qf = new OrderItemSelector()
            .selectOrderItemsByIdAndExtId(null,null)
            .setQuery();

        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOrderItemsById() {
        QueryFactory qf = new OrderItemSelector()
            .selectOrderItemsById(null)
            .setQuery();

        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOrderItemsByOrderId() {
        QueryFactory qf = new OrderItemSelector()
            .selectOrderItemsByOrderId(null)
            .setQuery();

        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOrderItems() {
        QueryFactory qf = new OrderItemSelector()
            .selectOrderItems()
            .setQuery();

        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }
}