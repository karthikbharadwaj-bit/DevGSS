({

    /**
     * Perform cart item Selection
     * @param component           {object}  Aura Component
     * @param itemPROD_SFID       {string}  Product Id of selected cart item
     * @param phaseGUID           {string}
     * @param isCustomSelection   {boolean} add item to selection
     * @param isMultipleSelection {boolean} add all items between selected and previously selected item to selection
     */
    handleSelection: function(component, itemPROD_SFID, phaseGUID, isCustomSelection, isMultipleSelection){
        var app = component.get('v.app');

        var source = phaseGUID ? app.getPhase(phaseGUID) : app;

        if (!isCustomSelection && !isMultipleSelection){
            app.deselectAll(itemPROD_SFID);
        }

        source.selectItem(itemPROD_SFID, isCustomSelection, isMultipleSelection);

        this.updateUI(component, app);
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

    deleteItemFromPhase: function(component, itemPROD_SFID, phaseGUID){
        var app = component.get('v.app');
        var phase = app.getPhase(phaseGUID);
        var item = phase.getDragItem(itemPROD_SFID);

        if (!this.isItemsValid([item]))
            item.quantity = item.quantityMax;

        phase.move(item).to(app);

        component.set('v.app', app);
    },

    updateUI: function(component, app){
        // Update UI
        app = app || component.get('v.app');
        app.update();
        component.set('v.isPhasesChanged', app.hasUnsavedChanges);
        component.set('v.app', app);
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

    getItemsByInfo: function(component, itemsInfo){
        var items = [];
        var app = component.get('v.app');

        itemsInfo.forEach(function(itemInfo){
            var source = itemInfo.phaseGUID ? app.getPhase(itemInfo.phaseGUID) : app;
            items.push(source.getDragItem(itemInfo.prod_sfid));
        });

        return items;
    },
    isItemsValid: function(items){
        var valid = true;
        items.forEach(function(item){
            if ((1 > item.quantity) || (item.quantity > item.quantityMax))
                valid = false;
        });
        return valid;
    }
});