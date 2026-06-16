({
    openLocationForm: function (component, params) {
        params.location.resetLocationInputs();
        params.location.isEditLocationMode = true;
        this.toggleClass(false,'location-form_duplicateErrorMsg','slds-hide');

        component.set('v.location', params.location);
        component.set('v.cartItem', params.cartItem);
        component.set('v.phase', params.phase);
        component.set('v.app', params.app);
        component.set('v.isDefaultLocationForm', false);
        component.set('v.target', params.target);
        this.revalidateInputs(component);

        this.setFormPositionAsync(component);
    },

    openDefaultLocationForm: function (component, params) {
        params.location.resetLocationInputs();
        params.location.isEditLocationMode = true;
        this.toggleClass(false,'location-form_duplicateErrorMsg','slds-hide');

        component.set('v.location', params.location);
        component.set('v.app', params.app);
        component.set('v.cartItem', null);
        component.set('v.phase', null);
        component.set('v.isDefaultLocationForm', true);
        component.set('v.target', params.target);
        this.revalidateInputs(component);

        this.setFormPositionAsync(component);
    },

    setFormPositionAsync: function(component){
        setTimeout($A.getCallback(() => this.setFormPosition(component, component.get('v.target'))));
    },

    setFormPosition: function(component, target){
        var positionParams = RC.htmlUtils.setPopoverPosition(
            component.find('locationForm').getElement(),
            target);

        component.set('v.nubbinPosition', positionParams.nubbinPosition);
        component.set('v.style', positionParams.style);
    },

    submitLocationForm: function(component){
        var app = component.get('v.app');
        var phase = app.getPhase(component.get('v.phase.guid'));
        var cartItem = phase.getDragItem(component.get('v.cartItem.prod_sfid'));
        var location = cartItem.getLocation(component.get('v.location.locationMatcherId'));

        let isLocationMatcherIdInputValid = app.isLocationMatcherIdInputValid(
            component.get('v.phase.guid'),
            component.get('v.cartItem.prod_sfid'),
            location.locationMatcherId
        );

        if (location.isLocationInputsValid() && isLocationMatcherIdInputValid) {
            if (app.isMoveProductsAllowed && !location.isIdAndNameUsed) {
                let locationMatcherIdToDelete = location.mergeLocations(cartItem);
                if (locationMatcherIdToDelete) {
                    phase.deleteLocation(locationMatcherIdToDelete);
                }
            } else {
                location.saveInputs();
            }
            location.isEditLocationMode = false;
        }
        this.toggleClass(isLocationMatcherIdInputValid,'location-form_duplicateErrorMsg','slds-hide');
        app.update();

        component.set('v.location', location);
        component.set('v.app', app);
        component.set('v.phase', phase);
        component.set('v.cartItem', cartItem);

        $A.get("e.c:PhaseManagementEvent").setParams({
            action: 'updateApp'
        }).fire();
    },

    submitDefaultLocationForm: function(component){
        var location = component.get('v.location');

        location.saveInputs();
        location.isEditLocationMode = false;

        component.set('v.location', location);

        $A.get("e.c:PhaseManagementEvent").setParams({
            action: 'submitDefaultLocationForm'
        }).fire();
    },

    cancelLocationForm: function (component) {
        var app = component.get('v.app');
        var phase = app.getPhase(component.get('v.phase.guid'));
        var cartItem = phase.getDragItem(component.get('v.cartItem.prod_sfid'));
        var location = cartItem.getLocation(component.get('v.location.locationMatcherId'));
        location.isEditLocationMode = false;
        component.set('v.location', location);

        if (!location.isValid) {
            cartItem.deleteLocation(location.locationMatcherId);
            app.update();
        }

        component.set('v.location', location);
        component.set('v.app', app);
        component.set('v.phase', phase);
        component.set('v.cartItem', cartItem);

        $A.get("e.c:PhaseManagementEvent").setParams({
            action: 'updateApp'
        }).fire();
    },

    cancelDefaultLocationForm: function(component){
        var location = component.get('v.location');

        location.isEditLocationMode = false;

        component.set('v.location', location);

        $A.get("e.c:PhaseManagementEvent").setParams({
            action: 'updateApp'
        }).fire();
    },

    validateAddresses: function (component) {
        var helper = this;
        var location = component.get('v.location');
        location.validation.isInProgress = true;
        component.set('v.location', location);

        RC.salesforce.request(component, 'c.validateAdressesWrapper', {
                addressItemList: JSON.stringify([location.getAdressToValidate({isUserInput: true})])
            })
            .then($A.getCallback(result => {
                location.setValidatedAddressesResult(result);
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to validate address', error)))
            .then($A.getCallback(() => {
                location.validation.isInProgress = false;
                component.set('v.location', location);
                $A.get("e.c:PhaseManagementEvent").setParams({
                    action: 'updateApp'
                }).fire();
                helper.setFormPositionAsync(component);
            }));
    },

    revalidateInputs: function(component){
        component.set('v.isFormRendered', false);
        component.set('v.isFormRendered', true);
    },

    getDefaultAddressFromAccount: function(component) {
        var location = component.get('v.location');

        location.getFieldsFromAccount();
        location.checkValidation();
        component.set('v.location', location);
    },

    toggleClass: function(toggleOn, toggledElement, toggledClass) {
        var elements = document.getElementsByClassName(toggledElement);
        for (var i=0; i<elements.length; i++) {
            if (toggleOn) {
                elements[i].classList.add(toggledClass);
            } else {
                elements[i].classList.remove(toggledClass);
            }
        }
    }
});