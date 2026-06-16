({
    doInit: function(component, event, helper){
        helper.setLookupParams(component);
        helper.checkDisabling(component);
    },
    deleteAreaCodeEntry: function(component, event, helper){
        helper.deleteAreaCodeItem(component);
    },
    areaCodeItemChanged: function(component, event, helper){
        var updateTrigger = component.get('v.updateTrigger');
        component.set('v.updateTrigger',++updateTrigger);

        helper.validateAreaCode(component,true);
    },
    stateChanged: function(component, event, helper){
        helper.checkDisabling(component);
    },
    busyChanged: function(component, event, helper){
        helper.checkDisabling(component);
    },
    deletingAreaCodeItemsChanged: function(component, event, helper){
        helper.checkDisabling(component);
    },
    validate: function(component, event, helper){
        helper.validateAreaCode(component);
    },
    quantityBlur: function(component, event, helper){
        helper.normaliseQuantity(component);
    },
    columnsChanged: function(component, event, helper){
        helper.calcColumns(component);
    }
})