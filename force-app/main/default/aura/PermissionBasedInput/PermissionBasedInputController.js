({
    init: function(component, event, helper) {
        component.set('v.inputValue', component.get('v.recordValue'));
        component.set('v.variant', component.get('v.label') ? component.get('v.variant') : 'label-hidden');
        helper.enterEditModeOnInit(component);
    },

    /**
     * Show Edit Input
     */
    showInput: function(component, event, helper) {
        helper.showInput(component);
    },

    /**
     * Hide Edit Input
     */
    hideInput: function(component, event, helper) {
        component.set('v.inputValue', component.get('v.recordValue'));
        component.find('input').reportValidity();
        helper.hideInput(component);
    },

    inputDisablingChanged: function(component) {
        QW.cssUtils.toggleShow(component, 'editLink', component.get('v.isUserHasEditPermission') && !component.get('v.isInputDisabled'));
    },

    checkIsValid: function(component) {
        return component.find('input').reportValidity();
    },

    onInputChange: function(component, event, helper) {
        if (component.get('v.inputValue') !== component.get('v.recordValue')) {
            helper.updateUI(component);
        }
    }
})