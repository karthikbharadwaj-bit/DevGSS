({
    checkStatus: function(component, event, helper) {
        helper.quoteType(component);
        helper.approvalStatus(component);
        helper.currentApprover(component);
        helper.numberOfLines(component);
        helper.checkUserAccess(component);
        helper.billingSystem(component);
    },
    openApprovers: function(component, event, helper) {
        $A.util.addClass(component.find('allApprovers'), 'approver-dropdown--open');
        $A.util.addClass(component.find('allApproversOverlay'), 'approver-overlay--open');
    },
    closeApprovers: function(component, event, helper) {
        helper.closeApprovers(component);
    },

})