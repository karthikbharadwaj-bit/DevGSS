({
    wizardChanged: function (component, event, helper) {
        helper.approvalVisibility(component);
    },

    modalClose: function (component, event, helper) {
        helper.modalClose(component);
    },

    submitForApproval: function (component, event, helper) {
        helper.submitForApproval(component, {
            quoteId: component.get('v.Wizard.currentQuote.record.Id')
        });
    },

    rejectApprovalRequest: function (component, event, helper) {
        helper.approveRejectApprovalRequest(component, {
            action: 'Reject',
            quoteId: component.get('v.Wizard.currentQuote.record.Id'),
            comment: component.find("approveRejectComment").get("v.value"),
        });
    },

    approveApprovalRequest: function (component, event, helper) {
        helper.approveRejectApprovalRequest(component, {
            action: 'Approve',
            quoteId: component.get('v.Wizard.currentQuote.record.Id'),
            comment: component.find("approveRejectComment").get("v.value")
        });
    },

    recallApprovalRequest: function (component, event, helper) {
        helper.recallApprovalRequest(component, {
            action: 'Removed',
            quoteId: component.get('v.Wizard.currentQuote.record.Id'),
            comment: component.find("recallComment").get("v.value")
        });
    },

    recallApprovalModal: function (component) {
        component.set('v.modalType', 'recallApproval');
        var modal = component.find('modal');
        $A.util.addClass(modal, 'slds-fade-in-open');
        $A.util.removeClass(modal, 'slds-hide');
        $A.util.addClass(component.find('modalBg'), 'slds-backdrop--open');
    },

    approveRejectModal: function (component) {
        component.set('v.modalType', 'approveReject');
        var modal = component.find('modal');
        $A.util.addClass(component.find('modalBg'), 'slds-backdrop--open');
        $A.util.addClass(modal, 'slds-fade-in-open');
        $A.util.removeClass(modal, 'slds-hide');
    },

    showPopover: function(component, event, helper){
        var auraId = event.currentTarget.dataset.buttonauraid;
        var target = event.currentTarget;
        helper.showPopover(component, auraId, target);
    },

    hidePopover: function(){
        QW.popover.hide();
    },
});