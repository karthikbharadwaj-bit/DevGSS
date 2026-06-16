({
    doInit: function(component, event, helper) {
        helper.getMaxDepth(component);
        helper.checkValid(component);
        helper.overallSearch(component, true);
    },
    selectValue: function(component, event, helper) {
        helper.changeActionfire(component);
        event.stopPropagation();
        var values = JSON.parse(event.currentTarget.dataset.value);
        component.set('v.values', values);
        component.set('v.searchQuery', '');
        if (!component.get('v.isValid')) {
            helper.focus(component);
        }
    },
    startSearch: function(component, event, helper) {
        helper.startSearch(component);
        helper.overallSearch(component);
        helper.showhide(component);
    },
    endSearch: function(component, event, helper) {
        helper.endSearch(component);
    },
    valuesChange: function(component, event, helper) {
        if(component.get('v.isFocused')){
            helper.overallSearch(component);
            helper.showhide(component);
            // collapse suggestions
            component.set('v.expandIndexP1', '');
            component.set('v.expandIndexP2', '');
        }

        helper.styleSearch(component);
        helper.checkValid(component);
        helper.displayValues(component);
    },
    /*
     *  Remove Value for selected picklist and empty all dependant
     */
    removeValue: function(component, event, helper) {
        event.stopPropagation();

        // get value which picklist to empty
        // TODO Will not work with locker service
        // need to find workaround of how to get value attribute
        var elem = event.currentTarget;
        var indexValue = elem.getAttribute('value');

        // remove value and all its childs
        var values = component.get('v.values');
        values.length = parseInt(indexValue);
        component.set('v.values', values);

        helper.startSearch(component);
    },
    /*
     *  Empty values and search query
     */
    removeSearch: function(component, event, helper) {
        component.set('v.values', []);
        component.set('v.searchQuery', '');
        helper.startSearch(component);
        helper.showhide(component);
    },
    /*
     *  Handle Key press
     */
    searchInputKey: function(component, event, helper) {
        // var keycode = event.getParams().keyCode;
        var oldSearchQuery = component.get('v.searchQuery');
        var searchQuery = event.target.value;
        switch (event.keyCode) {
            case 13: // Enter
                console.log("Enter pressed");
                helper.changeActionfire(component);
                helper.setNextValue(component);
                break;
            case 38: // Up pressed
                console.log("Up pressed");
                break;
            case 39: // right pressed
                console.log("right pressed");
                break;
            case 40: //down pressed
                console.log("down pressed");
                break;
            case 37: //left pressed
                console.log("left pressed");
                break;
            case 8: //backspace pressed
                if (!oldSearchQuery) {
                    helper.removeOneValue(component);
                }
                console.log("backspace pressed");
                break;
            default:
        }
    },
    searchInput: function(component, event) {
        var searchQuery = event.target.value;
        component.set('v.searchQuery',searchQuery);
    },
    searchQueryChange: function(component, event, helper) {
        var searchTimeout = component.get('v.searchTimeout');
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout($A.getCallback(function() {
            helper.overallSearch(component);
            helper.showhide(component);
        }), 500);
        component.set('v.searchTimeout', searchTimeout);
        component.set('v.expandIndexP1', '');
        component.set('v.expandIndexP2', '');
    },
    expandGroup: function(component, event) {
        event.stopPropagation();
        var value = event.currentTarget.dataset.value;
        var values = value.split(',');
        component.set('v.expandIndexP1', values[0]);
        component.set('v.expandIndexP2', values[1]);
    },
    requiredChange: function(component, event) {
        var required = event.getParam('value');
        var searchLookupWrapper = component.find('searchLookupWrapper');
        if (required) {
            $A.util.addClass(searchLookupWrapper, "is-required");
        } else {
            $A.util.removeClass(searchLookupWrapper, "is-required");
        }
    },
    errorsChange: function(component, event) {
        var errors = event.getParam('value');
        var searchLookupWrapper = component.find('searchLookupWrapper');
        var searchLookupErrors = component.find('searchLookupErrors');
        if (Array.isArray(errors) && errors.length > 0) {
            $A.util.addClass(searchLookupWrapper, "slds-has-error");
            $A.util.removeClass(searchLookupErrors, "slds-hide");
        } else {
            $A.util.removeClass(searchLookupWrapper, "slds-has-error");
            $A.util.addClass(searchLookupErrors, "slds-hide");
        }
    },
    checkIsValid: function(component, event, helper){
        helper.checkValid(component);
    }
});