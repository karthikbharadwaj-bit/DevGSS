({
    /**
     * User clicked on draggable item
     */
    onDragItemClick: function(component, event, helper){
        var isCartItemClick = component.get('v.isCartItemClick');
        if (!isCartItemClick){
            component.set('v.isCartItemClick', true);
            return;
        }

        var itemPROD_SFID = event.currentTarget.dataset.prod_sfid;
        var phaseGUID = event.currentTarget.dataset.phaseguid;
        var isMultipleSelection = event.shiftKey;
        var isCustomSelection = event.metaKey || event.ctrlKey;

        var app = component.get('v.app');
        var source = phaseGUID ? app.getPhase(phaseGUID) : app;
        var item = source.getDragItem(itemPROD_SFID);
        if (!item.isMovable)
            return;

        var itemsInfo = app.getAllSelectedItemsInfo();
        let repeatedPLI = false;
        if (itemsInfo.length === 1) {
            repeatedPLI = phaseGUID !== undefined || itemsInfo[0].phaseGUID !== undefined;
        }
        component.set('v.preventDeselection', true);
        component.set('v.hasSelectedCartItems', true);
        
        if (app.isNewChangeOrder && !isMultipleSelection && !isCustomSelection && repeatedPLI) {
            app.deselectAll();
        }        
        helper.handleSelection(component, itemPROD_SFID, phaseGUID, isCustomSelection, isMultipleSelection);
    },

    stopPropagation: function(component, event){
        event.stopPropagation();
    },

    /**
     * User Dragged cart item element
     */
    onDragItemDragStart: function(component, event, helper){
        console.log('CartItem.onDragItemDragStart');
        var app = component.get('v.app');
        var cartItem = component.get('v.cartItem');

        if (!cartItem.selected){
            app.deselectAll();
            helper.updateUI(component, app);
        }

        var itemsInfo = app.getAllSelectedItemsInfo();
        if (itemsInfo.length === 0){
            cartItem.select(true);
            itemsInfo = app.getAllSelectedItemsInfo();
        }

        // if (!helper.isItemsValid(helper.getItemsByInfo(component, itemsInfo))) {
        //     return;
        // }

        // Define the draggable item properties
        event.dataTransfer.setData("text", JSON.stringify(itemsInfo));
        event.dataTransfer.dropEffect = "move";

        helper.visualiseStartDrag(component);
    },
    /**
     * User Clicked delete icon on Cart Item
     */
    deleteItem: function(component, event, helper){
        var itemPROD_SFID = event.currentTarget.dataset.prod_sfid;
        var phaseGUID = event.currentTarget.dataset.phaseguid;
        var app = component.get('v.app');
        app.deselectAll();
        component.set('v.app', app);

        // Move item from phase to unassigned
        helper.deleteItemFromPhase(component, itemPROD_SFID, phaseGUID);

        helper.updateUI(component);
    },

    onDragItemQuantityInputBlur: function(component){
        component.set('v.preventDeselection', true);
        component.set('v.isDraggable', true);
    },

    onDragItemQuantityInputFocus: function(component){
        component.set('v.isDraggable', false);
    },

    onDragEnd: function(component, event, helper){
        console.log('CartItem.onDragEnd');
        helper.visualiseStopDrag(component);
    },

    addLocation: function(component){
        var app = component.get('v.app');
        var phase = app.getPhase(component.get('v.phase.guid'));
        var cartItem = phase.getDragItem(component.get('v.cartItem.prod_sfid'));

        cartItem.isUnassignedLocationsError = false;
        if(cartItem.unassignedQuantity === 0)
            return;

        var addedLocation = cartItem.addLocation();
        addedLocation.showEditLocationFormOnRender = true;
        app.update();

        component.set('v.app', app);
    },

    toggleDetails: function(component){
        var app = component.get('v.app');
        var phase = app.getPhase(component.get('v.phase.guid'));
        var cartItem = phase.getDragItem(component.get('v.cartItem.prod_sfid'));

        cartItem.isDetailsShown = !cartItem.isDetailsShown;

        component.set('v.app', app);
        component.set('v.isCartItemClick', false);
    },

    onLocationInputBlur: function(component, event, helper){
        helper.updateUI(component);
    },

    onMouseOverDetails: function(component){
        component.set('v.isDraggable', false);
        component.set('v.isCartItemClick', false);
    },

    onMouseOutDetails: function(component){
        component.set('v.isDraggable', true);
        component.set('v.isCartItemClick', true);
    }
});