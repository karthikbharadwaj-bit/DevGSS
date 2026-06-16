({
    doInit: function (component, event, helper) {
        helper.setForm(component);
        helper.addEventListeners(component);
    },

    openLocationForm: function (component, event, helper) {
        if (component.get('v.disabled')) {
            return;
        }
        helper.fireOnClick(component);
        helper.valueToForm(component);
        component.set('v.isUseAccountBillingAddress', helper.checkIfAccountBillingAddressUsed(component));
        helper.openForm(component);
        helper.forceInputsRevalidation(component);
    },

    cancelLocationForm: function (component, event, helper) {
        helper.closeForm(component);
    },

    submitLocationForm: function (component, event, helper) {
        event.preventDefault();
        helper.formToValue(component);
        helper.closeForm(component);
        helper.fireOnChange(component);
    },

    onUseAccountBillingAddressChanged: function (component, event, helper) {
        if (component.get('v.isUseAccountBillingAddress')) {
            helper.copyFromBillingAddress(component);
        }
        helper.forceInputsRevalidation(component);
    },

    onShippingOptionReady: function (component, event, helper) {
        helper.setInitialValue(component);
        if (component.get('v.useDefaultPicklistValue')) {
            helper.reset(component);
        }
    },

    reset: function (component, event, helper) {
        helper.reset(component);
    },

    updateForm: function (component, event, helper) {
        helper.updateForm(component);
    },

    accountChanged: function (component, event, helper) {
        if (component.get('v.useDefaultPicklistValue')) {
            helper.reset(component);
        }
        helper.updateForm(component);
    },

    contactNameChanged: function (component, event, helper) {
        if (component.get('v.useDefaultPicklistValue')) {
            helper.prepopulateShipAttentionTo(component);
        }
        helper.updateForm(component);
    }
});