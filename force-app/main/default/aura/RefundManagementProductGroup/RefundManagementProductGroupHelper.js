({
    toggleExpand: function(component){
        let entity = component.get('v.entity')
            entity.state.isExpanded = !entity.state.isExpanded;
        component.set('v.entity', entity);
    },

    normalizeRefunds: function (component) {
        component.get('v.entity').normalizeRefund();
    },

    copyAmountToRefund: function (component) {
        let availableRefund = component.get('v.app').remainingRefundAmount.value;
            component.get('v.entity').fillRefundAmount(availableRefund);
    },

    validateRefund: function (component) {
        component.get('v.entity').refundAmount.validate();
    },

    forceUIvalidate: function(component){
        component.find('refundInput').focus();
    },

    fireOnProductChange: function (component) {
        component
            .getEvent("RefundManagementEvent")
            .setParams({params: {bypassAllTransactionsRerendering: true}})
            .fire();
    }
})