({
    loadUserAccessInfo: function (component, event, helper) {
        return helper.loadUserAccessInfo(component);
    },

    createPhase: function (component, event, helper) {
        helper.createPhase(component);

        // Update UI
        helper.updateUI(component);
    },

    onDragEnter: function (component, event) {
        event.preventDefault();
    },

    onDragOver: function (component, event) {
        event.preventDefault();
    },

    onDropInto: function (component, event, helper) {
        event.preventDefault();
        // return if user tries to drop something inappropriate
        try {
            var itemsInfo = JSON.parse(event.dataTransfer.getData("text"));
        } catch (error) {
            console.error(error);
            return;
        }

        // Move item
        var app = component.get('v.app');
        app.moveItems(itemsInfo);

        // Update UI
        helper.updateUI(component, app);

        // Remove drag styling
        helper.visualiseStopDrag(component);
    },

    onDragEnd: function (component, event, helper) {
        helper.visualiseStopDrag(component);
    },

    setAppPermissions: function (component, event, helper) {
        helper.setAppPermissions(component);
    },

    onPhaseManagementEvent: function (component, event, helper) {
        switch (event.getParams().action) {

            case 'updateApp':
                helper.updateUI(component);
                break;

            case 'submitDefaultLocationForm':
                helper.submitDefaultLocationForm(component);
                helper.updateUI(component);
                break;

        }
    },

    openDefaultLocationForm: function(component, event, helper){
        helper.openDefaultLocationForm(component);
    },

    onValidateLocation: function(component, event, helper){
        helper.validateAddresses(component);
    },

    // ================================================================================
    //  Exposed Methods (aura:method)
    // ================================================================================

    discard: function (component, event, helper) {
        PM.spinner.show('check parent order');
        window.setTimeout(
            $A.getCallback(function() {
                helper.refreshApp(component, component.get('v.phases'));
                PM.spinner.hide();
            }), 0
        );
    },

    save: function (component, event, helper) {
        helper.deselectAll(component);
        return helper.save(component);
    },

    startApp: function (component, event, helper) {
        PM.spinner.show('Loading data');
        helper.addEventListeners(component);
    },

    stopApp: function (component, event, helper) {
        helper.removeEventListeners(component);
    },

    reloadPhases: function (component, event, helper) {
        return helper.getPhases(component);
    },

    getPhaseTypePicklist: function (component, event, helper) {
        return helper.getPhaseTypesPicklistValues(component);
    },

    reloadChangeOrderPhases: function (component, event, helper) {
        return helper.reloadChangeOrderPhases(component);
    },

    deletePhaseLineItemsFromSF: function (component, event, helper) {
        var args = event.getParam('arguments');
        return helper.deletePhaseLineItems(component, args.phaseLineItemIdsToDelete);
    },

    deletePhasesFromSF: function (component, event, helper) {
        var args = event.getParam('arguments');
        return helper.deletePhases(component, args.phaseIdsToDelete);
    },

    onListWheel: function (component, event) {
        RC.htmlUtils.trapScroll(event);
    },

    toggleCompletedSection: function (component) {
        component.set('v.isCompletedLoading', true);
        setTimeout($A.getCallback(function () {
            component.set('v.isHideCompetedSection', !component.get('v.isHideCompetedSection'));
            component.set('v.isCompletedLoading', false);
        }), 0);
    },

    toggleNonCompletedSection: function (component) {
        component.set('v.isNonCompletedLoading', true);
        setTimeout($A.getCallback(function () {
            component.set('v.isHideNonCompetedSection', !component.get('v.isHideNonCompetedSection'));
            component.set('v.isNonCompletedLoading', false);
        }), 0);
    }
});