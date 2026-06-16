({
	init: function(component, event, helper) {
		helper.getOrdersFromController(component);
	},

	confirmPrompt: function(component, event, helper) {
		helper.showPrompt(component, false);
		helper.getOrdersFromController(component);
	},

	closePrompt: function(component, event, helper) {
		helper.showPrompt(component, false);
	},
})