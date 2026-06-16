({
    handleSelection: function(component, itemPROD_SFID, phaseGUID, locationMatcherId, isCustomSelection, isMultipleSelection){
        var app = component.get('v.app');

        var source = phaseGUID ? app.getPhase(phaseGUID) : app;
        var site = source.getDragItem(itemPROD_SFID);

        site.select(false);
        if (!isCustomSelection && !isMultipleSelection){
            app.deselectAll();
        }

        site.selectItem(locationMatcherId, isCustomSelection, isMultipleSelection);

        app.update();
        component.set('v.app', app);
    },

    visualiseStartDrag: function(component){
        var data = component.get('v.app');

        data.phases.map(function(phase){
            phase.readyToDrop = !phase.isComplete;
            return phase;
        });
        data.readyToDrop = true;

        component.set('v.app', data);
    },

    /**
     * Removes highlight from drop containers
     */
    visualiseStopDrag: function(component){
        var app = component.get('v.app');

        app.phases.map(function(phase){
            phase.readyToDrop = false;
            return phase;
        });
        app.readyToDrop = false;

        component.set('v.app', app);
    },

    updateUI: function(component, app){
        // Update UI
        app = app || component.get('v.app');
        app.update();
        component.set('v.isPhasesChanged', app.hasUnsavedChanges);
        component.set('v.app', app);
    },

    openLocationForm: function(component){
        var app = component.get('v.app');
        var phase = app.getPhase(component.get('v.phase.guid'));
        var cartItem = phase.getDragItem(component.get('v.cartItem.prod_sfid'));
        var location = cartItem.getLocation(component.get('v.location.locationMatcherId'));

        cartItem.isNoLocationsInfoError = false;
        location.select(false);

        $A.get("e.c:PhaseManagementEvent").setParams({
            action: 'openLocationForm',
            app: app,
            phase: phase,
            cartItem: cartItem,
            location: location,
            target: component.find('editLocationButton').getElement()
        }).fire();

        component.set('v.app', app);
    },

    validateAddresses: function(component){
        var location = component.get('v.location');
        location.validation.isInProgress = true;
        component.set('v.location', location);
        var helper = this;

        RC.salesforce.request(component, 'c.validateAdressesWrapper', {
                addressItemList: JSON.stringify([location.getAdressToValidate()])
            })
            .then($A.getCallback(result => {
                location.setValidatedAddressesResult(result);
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to validate address', error)))
            .then($A.getCallback(() => {
                location.validation.isInProgress = false;
                component.set('v.location', location);
                helper.updateUI(component);
            }));
    }
});