({
    validateRefund: function (component) {
        var product = component.get('v.product');

        product.refund.validate();
    },

    normalizeRefunds: function (component) {
        var product = component.get('v.product');

        if (!RC.object.isNumeric(product.refund.value)) {
            product.refund.value = 0;
        }
    },

    copyAmountToRefund: function (component) {
        var app = component.get('v.app');

        app.copyAmountToRefund(component.get('v.product'));
    },

    forceUIvalidate: function(component){
        component.find('refundInput').focus();
    },

    toggleExpand: function(component){
        var product = component.get('v.product');

        product.isExpanded = !product.isExpanded;

        component.set('v.product', product);
    },

    fireOnProductChange: function (component) {
        component.getEvent("RefundManagementEvent")
            .setParams({params: {bypassAllTransactionsRerendering: true}})
            .fire();
    }
});