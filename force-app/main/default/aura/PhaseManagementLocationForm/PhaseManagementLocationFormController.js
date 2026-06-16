({
    submitLocationForm: function (component, event, helper) {
        event.preventDefault();

        if (component.get('v.isDefaultLocationForm'))
            helper.submitDefaultLocationForm(component);
        else
            helper.submitLocationForm(component);

        helper.setFormPositionAsync(component);
    },

    onPhaseManagementEvent: function(component, event, helper){
        var params = event.getParams();

        switch (params.action){
            case 'openLocationForm':
                helper.openLocationForm(component, params);
                break;

            case 'openDefaultLocationForm':
                helper.openDefaultLocationForm(component, params);
                break;
        }
    },

    cancelLocationForm: function (component, event, helper) {
        if (component.get('v.isDefaultLocationForm'))
            helper.cancelDefaultLocationForm(component);
        else
            helper.cancelLocationForm(component);
    },

    copyDefaultAddressFromAccount: function (component, event, helper) {
        if (component.get('v.isDefaultLocationForm'))
            helper.getDefaultAddressFromAccount(component);
    },

    validateLocationMatcherIdInput: function (component, event, helper) {
        var app = component.get('v.app');

        let isLocationMatcherIdInputValid = app.isLocationMatcherIdInputValid(
            component.get('v.phase.guid'),
            component.get('v.cartItem.prod_sfid'),
            component.get('v.location.locationMatcherId')
        );
        helper.toggleClass(isLocationMatcherIdInputValid,'location-form_duplicateErrorMsg','slds-hide');

    },

    onValidateLocation: function(component, event, helper){
        helper.validateAddresses(component);
    },

    onInputChange: function (component) {
        var location = component.get('v.location');
        location.checkValidation();
        component.set('v.location', location);
    },

    toggleIsDetailsShown: function(component, event, helper){
        var location = component.get('v.location');
        location.validation.toggleIsDetailsShown();
        component.set('v.location', location);
        helper.setFormPositionAsync(component);
    }
});