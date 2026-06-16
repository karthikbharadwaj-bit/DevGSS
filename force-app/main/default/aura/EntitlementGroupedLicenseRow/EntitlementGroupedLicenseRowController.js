({
    init: function(component, event, helper) {
        helper.initializeDisplayData(component);
    },

    toggleDetails: function(component, event, helper) {
        var isShowDetails = component.get('v.isShowDetails');
        component.set('v.isShowDetails', !isShowDetails);
    }
})