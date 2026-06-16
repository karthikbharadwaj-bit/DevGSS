({
    doInit: function (component, event, helper) {
        
        const cmp = component.find("justificationTextArea"),
            cmpValue = cmp.get("v.value"),
            elaCmp = component.find("isEla"),
            elaCmpValue = elaCmp.get('v.value');
     

        if (!$A.util.isUndefinedOrNull(elaCmpValue) && !$A.util.isEmpty(elaCmpValue)) {
            component.set("v.isValid", helper.validateField(component));
        } else {
            component.set("v.isValid", true);
        }

        if (!$A.util.isUndefinedOrNull(cmpValue) && !$A.util.isEmpty(cmpValue)) {
           component.set("v.isValid", true);
        } else {
            component.set("v.isValid", false);
        }

        helper.handleValueChangeAction(component);
    },

    checkForValid: function (component, event, helper) {
        const cmpValue = event.getSource().get("v.value");
        if (!$A.util.isUndefinedOrNull(cmpValue) && !$A.util.isEmpty(cmpValue)) {
            component.set("v.isValid", true);
        } else {
            component.set("v.isValid", false);
        }
    },

    addRow: function(component, event, helper) {
        helper.addTrueUpDateRecord(component, event, helper);
    },

    removeRow: function(component, event, helper) {
        //Get the account list
        var DQTrueUpDateList = component.get("v.DQTrueUpDateList");
        //Get the target object
        var selectedItem = event.currentTarget;
        //Get the selected item index
        var index = selectedItem.dataset.record;
        DQTrueUpDateList.splice(index, 1);
        component.set("v.DQTrueUpDateList", DQTrueUpDateList);
    },

    validateFieldsForELA: function(component, event, helper) {
        return helper.validateField(component);
    },

    handleValueChangeAction: function (component, event, helper) {
        helper.handleValueChangeAction(component);
    }
})