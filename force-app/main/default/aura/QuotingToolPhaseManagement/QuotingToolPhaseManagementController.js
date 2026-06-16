({
    /**
     * User clicked button
     */
    onButtonEvent: function(component, event){
        switch (event.getParam('name')){
            case 'savePhasesButton':
                component.find('phaseManagement').save();
                break;
            case 'discardPhasesButton':
                component.find('phaseManagement').discard();
                break;
        }
    },
    stopApp: function(component){
        component.find('phaseManagement').stopApp();
    },
    /**
     * v.phases attribute changed
     */
    phasesChanged: function(component){
        var Wizard = component.get('v.Wizard');

        if ( !Wizard.currentQuote ) return;

        Wizard.currentQuote.setPhases( component.get('v.phases') );
        Wizard.update();

        component.set('v.Wizard', Wizard);
    },
    save: function(component){
        return component.find('phaseManagement').save();
    },
    discard: function(component){
        return component.find('phaseManagement').discard();
    },
    /**
     * Reload phases
     * @public
     */
    reloadPhases: function(component, event, helper){
        // If there is no PM.js defined it means that component is not loaded yet.
        // When PM.js will be loaded phases will be loaded automatically
        if (typeof PM !== 'undefined')
            helper.getPhasesAndDiscard(component);
    },
    /**
     * PM js helper file loaded
     * @param component
     * @param event
     * @param helper
     */
    pmLoaded: function(component, event, helper){
        helper.prepareCartItems(component);
        helper.getPhasesAndDiscard(component);
        helper.getIsNewChangeOrder(component);
    },

    /**
     * Delete specified Phase Line Items
     *
     * Arguments:
     * phaseLineItemIdsToDelete
     *
     * @public
     * @returns {Promise || null}
     */
    deletePhaseLineItems: function(component, event){
        var args = event.getParam('arguments');
        return component.find('phaseManagement').deletePhaseLineItemsFromSF(args.phaseLineItemIdsToDelete);
    },

    /**
     * Delete all phases from salesforce
     * @public
     * @returns {Promise || null}
     */
    deletePhases: function(component, event){
        var args = event.getParam('arguments');
        return component.find('phaseManagement').deletePhasesFromSF(args.phaseIdsToDelete);
    },

    /**
     * When user make any changes to phases, we need to set ProServ Status to in Progress
     */
    onChangesSaved: function(component, event, helper){
        var Wizard = component.get('v.Wizard');

        if ( Wizard.opportunity.isClosed
            || !(Wizard.currentQuote.isSynced || Wizard.currentQuote.isCreated ) )
            return;

        helper.changeProServStatus(component);
    },

    cartItemsChanged: function(component, event, helper){
        helper.prepareCartItems(component);
    },

    onNotificationActionEvent: function(component, event) {
        var actionName = event.getParam("name");
        switch (actionName){
            case 'emptyPhases':
            case 'assignAllPhaseLineItems':
                $A.get("e.c:QuotingToolButtonEvent")
                    .setParams({ name: 'phasesTab' })
                    .fire();
                break;
        }
    },

    wizardChanged: function(component, event, helper){
        if(!component.get('v.Wizard.currentQuote'))
            return;

        helper.setPhaseManagementPermissions(component);
    },

    tabsChanged: function(component, event, helper){
        helper.restartAppOnTabOpen(component);
    }
});