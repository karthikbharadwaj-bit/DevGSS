({
    doInit: function (component, event, helper) {
        helper.loadOpportunity(component);
    },
    
    handleOnClick : function(component, event, helper) {
		component.set("v.isCalculatorLoad", true);
    },

	closeModel: function (component, event, helper) {
		component.set("v.isCalculatorLoad", false);
	}
})