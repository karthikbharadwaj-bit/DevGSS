({
    toggleExpand: function(component, event, helper) {
        if (window.getSelection().type === "Range") {
            return;
        }

        if (component.get('v.entity.state.isExpandable')) {
            helper.toggleExpand(component);
        }
    },

    stopPropagation: function(component, event) {
        event.stopPropagation();
    },

    onAmountClick: function(component, event, helper) {
        try {
            event.stopPropagation();
        } catch (e) {
            console.log(e);
        }

        helper.copyAmountToRefund(component);
        helper.validateRefund(component);
        helper.forceUIvalidate(component);
        helper.fireOnProductChange(component);

        component.set('v.transaction', component.get('v.transaction'));
    },

    refundChanged: function(component, event, helper) {
        helper.validateRefund(component);
    },

    refundBlurred: function(component, event, helper) {
        helper.normalizeRefunds(component);
        helper.fireOnProductChange(component);

        component.set('v.transaction', component.get('v.transaction'));
    },

    onRefundValueChanged: function(component, event, helper) {
        component.find("refundInput").reportValidity();
    },

    focus: function(component, event, helper) {
        helper.forceUIvalidate(component);
    }
})