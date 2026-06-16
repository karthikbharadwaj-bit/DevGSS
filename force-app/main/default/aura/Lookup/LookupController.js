({
    /**
     * Component init
     */
    doInit: function (component, event, helper) {
        var value = component.get('v.value');
        if (value) {
            helper.setValue(component, value);
        }
        helper.resetLimit(component);
        helper.generateUniqueId(component);
    },
    search: function (component, event, helper) {
        let timer = component.get('v.timer');
        clearTimeout(timer);
        
        timer = setTimeout(
            $A.getCallback(
                () => {
            		helper.resetLimit(component);
            		const searchText = component.get('v.searchText');
            		if (searchText.length !== 1 ) {
     					helper.getItems(component);       
	        		}
            		clearTimeout(timer);
            		component.set('v.timer', null);
                }
			), 1000);
        
        component.set('v.timer', timer);
    },
    /**
     * Lookup input focused
     */
    inputFocus: function (component, event, helper) {
        if (!component.get('v.loadMore')) helper.resetLimit(component);

        helper.showListbox(component);
        helper.inputFocus(component);
        helper.getItems(component, component.get('v.loadMore'));

        component.set('v.loadMore', false);
    },
    /**
     * Lookup input blurred
     */
    inputBlur: function (component, event, helper) {
        if (component.get('v.loadMore')) {
            component.find('comboboxInput').focus();
        } else {
            helper.hideListbox(component);
            helper.inputBlur(component);
        }
    },
    /**
     * Remove button clicked
     */
    inputClear: function (component, event, helper) {
        helper.removeValues(component);
        component.set('v.searchText', '');
        component.find('comboboxInput').focus();
        helper.fireOnChange(component);
    },
    /**
     * Search button clicked
     */
    inputSearch: function (component, event, helper) {
        component.find('comboboxInput').focus();
    },

    /**
     * User selected new value
     */
    lookupEventHandler: function (component, event, helper) {
        var action = event.getParam('action');
        var params = event.getParam('params');
        var guid = event.getParam('guid');

        if (component.get('v.guid') === guid) {

            switch (action) {

                // User Selected Record
                case 'itemSelected':
                    helper.itemSelectedHandler(component, params.item);
                    break;

                // Load Results
                case 'loadMore':
                    helper.loadMore(component);
                    break;

            }

        }
    },

    /**
     * Value (v.value) Changed
     */
    valueChanged: function (component, event, helper) {
        var value = component.get('v.value');
        var selectedValue = component.get('v.selectedValue');
        if (value === undefined && selectedValue === undefined) {
            return;
        }
        if (value && (!selectedValue || selectedValue && value !== selectedValue.Id)) {
            helper.setValue(component, value);
        } else if (!value) {
            component.set('v.selectedValue', null);
        }
    },

    /**
     * Load more results
     * Increase limit and search again
     */
    loadMore: function (component, event, helper) {
        helper.loadMore(component);
    },

    /**
     * Search Result Array (v.searchResult) updated
     */
    searchResultChanged: function (component, event, helper) {
        helper.setListboxHeight(component);
        if (!component.get('v.listIsRelative') && component.get('v.isRendered')) {
            helper.updateListbox(component);
        }
    },

    /**
     * Loading status (v.isLoading) updated
     */
    isLoadingChanged: function (component, event, helper) {
        if (!component.get('v.listIsRelative') && component.get('v.isRendered')) {
            helper.updateListbox(component);
        }
    },

    doNothing: function (component, event, helper) {
    },

    disabledChanged: function (component, event) {
        // Bug: Firefox do not fire blur event when input becomes disabled
        // Force it to do so
        if (event.getParam('value') && !event.getParam('oldValue')) {
            component.find('comboboxInput').blur();
        }
    }
})