({
    refundChanged: function(component, event, helper) {
        helper.validateRefund(component);
    },

    refundBlurred: function(component, event, helper) {
        helper.normalizeRefunds(component);
        helper.fireOnProductChange(component);

        component.set('v.transaction', component.get('v.transaction'));
    },

    onRefundValueChanged: function(component, event, helper) {
        const refundInput = component.find('refundInput');

        if(refundInput) {
            refundInput.reportValidity();
        }
    },

    stopPropagation: function(component, event) {
        event.stopPropagation();
    },

    onAmountClick: function(component, event, helper) {
        event.stopPropagation();
        helper.copyAmountToRefund(component);
        helper.validateRefund(component);
        helper.forceUIvalidate(component);
        helper.fireOnProductChange(component);

        component.set('v.transaction', component.get('v.transaction'));
    },

    toggleExpand: function(component, event, helper) {
        if (RC.htmlUtils.isTextSelection()) {
            return;
        }

        helper.toggleExpand(component);
    },

    focus: function(component, event, helper) {
        helper.forceUIvalidate(component);
    }
});