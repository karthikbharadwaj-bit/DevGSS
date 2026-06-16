({

    onDragItemQuantityInputBlur: function (component) {
        var app = component.get('v.app');
        var phase = app.getPhase(component.get('v.phase.guid'));
        var cartItem = phase.getDragItem(component.get('v.cartItem.prod_sfid'));
        var location = cartItem.getLocation(component.get('v.location.locationMatcherId'));

        location.quantityInput.validate({
            max: cartItem.unassignedQuantity + location.quantity
        });
        if (location.quantityInput.isValid)
            location.saveQuantity();

        app.update();
        component.set('v.app', app);
        component.set('v.preventDeselection', true);
        component.set('v.isDraggable', true);
    },

    onDragItemQuantityInputFocus: function (component) {
        component.set('v.isDraggable', false);
    },

    deleteItem: function (component) {
        var app = component.get('v.app');

        var phase = app.getPhase(component.get('v.phase.guid'));
        phase.deleteLocation(component.get('v.location.locationMatcherId'));
        app.update();

        component.set('v.app', app);
    },

    onLocationClick: function (component, event, helper) {
        event.stopPropagation();

        var itemPROD_SFID = component.get('v.cartItem.prod_sfid');
        var phaseGUID = component.get('v.phase.guid');
        var isMultipleSelection = event.shiftKey;
        var isCustomSelection = event.metaKey || event.ctrlKey;

        var app = component.get('v.app');
        var source = phaseGUID ? app.getPhase(phaseGUID) : app;
        var cartItem = source.getDragItem(itemPROD_SFID);
        var location = cartItem.getLocation(component.get('v.location.locationMatcherId'));

        if (!cartItem.isMovable || !location.isMovable || location.isEditLocationMode)
            return;

        var isWasSelected = location.selected;

        helper.handleSelection(component, itemPROD_SFID, phaseGUID, location.locationMatcherId, isCustomSelection, isMultipleSelection);

        if (!isWasSelected && location.selected)
            location.quantityInput.value = location.quantity;

        component.set('v.app', app);
    },

    // ================================================================================
    //  Location Dragging
    // ================================================================================

    onDragItemDragStart: function (component, event, helper) {
        event.stopPropagation();

        var app = component.get('v.app');
        var location = component.get('v.location');

        if (!location.selected) {
            app.deselectAll();
            app.update();
            component.set('v.app', app);
        }

        var itemsInfo = app.getAllSelectedItemsInfo();
        if (itemsInfo.length === 0) {
            location.select(true);
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

    onDragEnd: function (component, event, helper) {
        // helper.visualiseStopDrag(component);
        event.stopPropagation();
    },

    stopPropagation: function (component, event) {
        event.stopPropagation();
    },

    // ================================================================================
    //  Location Form
    // ================================================================================

    openLocationForm: function (component, event, helper) {
        helper.openLocationForm(component)
    },

    onValidateLocation: function(component, event, helper){
        event.stopPropagation();
        helper.validateAddresses(component);
    },
});