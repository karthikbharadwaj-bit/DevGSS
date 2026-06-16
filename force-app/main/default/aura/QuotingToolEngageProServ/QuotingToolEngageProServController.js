({
    /**
     * Opens modal of specified type
     *  - Engage (CC) ProServ
     *  - Cancel (CC) ProServ
     */
    modalOpen: function (component, event, helper) {
        helper.modalOpen(component, event.getSource().getLocalId());
    },

    /**
     * Close Modal Window
     */
    modalClose: function (component, event, helper) {
        helper.modalClose(component);
    },

    /**
     * Submit button clicked on Engage (CC) ProServ Modal
     */
    submit: function (component, event, helper) {
        var modalInfo = component.get('v.modalInfo');
        switch (modalInfo.type) {
            case helper.ENGAGE_PROSERV:
            case helper.ENGAGE_CC_PROSERV:
                helper.engageProServHelper(component, modalInfo);
                break;
            case helper.CANCEL_PROSERV:
            case helper.CANCEL_CC_PROSERV:
                helper.cancelProServHelper(component, modalInfo);
                break;
        }
    },

    selectReason: function (component, event, helper) {
        var selectedValues = event.getParam("value");
        component.set("v.selectedCaseReasons", selectedValues);
    },

    /**
     * Sync Quote Button Clicked
     */
    sync: function (component, event, helper) {
        helper.syncProServWithSales(component, false);
    },

    /**
     * Switch Service plan button clicked
     */
    switch: function (component, event, helper) {
        helper.switchRequest(component);
    },

    /**
     * v.state attribute changed
     */
    stateChanged: function (component, event, helper) {
        helper.toggleDisabling(component);
        helper.setSyncButtonLabel(component);
    },

    /**
     * v.proServQuote attribute changed
     */
    proServQuoteChanged: function (component, event, helper) {
        helper.toggleDisabling(component);
        helper.setSyncButtonLabel(component);
    },

    /**
     * v.ccProServQuote attribute changed
     */
    ccProServQuoteChanged: function (component, event, helper) {
        helper.toggleDisabling(component);
        helper.setSyncButtonLabel(component);
    },

    /**
     * User interacted with modal window in QuotingToolWrapper component
     */
    modalResponse: function (component, event, helper) {
        var action = event.getParam("action");
        var modalResult = event.getParam("modalResult");
        if (action == "syncProServUnavailable" && modalResult) {
            var syncOnlyAvailable = true;
            helper.syncProServWithSales(component, syncOnlyAvailable);
        }
    },

    showPopover: function (component, event, helper) {
        var auraId = event.currentTarget.dataset.buttonauraid;
        var target = event.currentTarget;
        helper.showPopover(component, auraId, target);
    },

    hidePopover: function () {
        QW.popover.hide();
    },

    proServIsSold: function (component, event, helper) {
        $A.get("e.c:ModalRequestEvent").setParams({
            guid: helper.proServIsSoldModalGUID,
            header: $A.get("$Label.c.QW_Title_ProServIsSoldConfirmationModal"),
            content: $A.get("$Label.c.QW_Message_ProServIsSoldConfirmationModal"),
            buttons: [{
                label: 'Mark as "Sold"',
                variant: 'brand',
                callback: helper.proServIsSold.bind(helper, component)
            }]
        }).fire();
    },

    proServIsOutForSignature: function (component, event, helper) {
        $A.get("e.c:ModalRequestEvent").setParams({
            guid: helper.proServIsSoldModalGUID,
            header: $A.get("$Label.c.QW_Title_ProServIsOutForSignatureConfirmationModal"),
            content: $A.get("$Label.c.QW_Message_ProServIsOutForSignatureConfirmationModal"),
            buttons: [{
                label: 'Mark as "Out for Signature" and Lock Quote',
                variant: 'brand',
                callback: helper.proServIsOutForSignature.bind(helper, component)
            }]
        }).fire();
    },

    unlock: function (component, event, helper) {
        $A.get("e.c:ModalRequestEvent").setParams({
            header: $A.get("$Label.c.QW_Title_UnlockQuoteConfirmationModal"),
            content: $A.get("$Label.c.QW_Message_UnlockQuoteConfirmationModal"),
            buttons: [{
                label: 'Unlock',
                variant: 'brand',
                callback: helper.unlock.bind(helper, component)
            }]
        }).fire();
    },

    /**
     * v.Wizard attribute changed
     */
    wizardChanged: function (component, event, helper) {
        helper.toggleDisplaying(component);
        helper.toggleDisabling(component);
        helper.setSyncButtonLabel(component);
    }
});