({
    init : function(component, event, helper) {
        component.set("v.isLoading", true);
        helper.fetchData(component, event, helper);
    },

    handleSave : function(component, event, helper) {
        helper.handleSaveEdition(component, event, helper);
    }
})