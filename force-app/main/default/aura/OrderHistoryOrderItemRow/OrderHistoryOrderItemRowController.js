({
	init: function(component, event, helper) {
		component.set('v.currencyPrecision', helper.calcPrecision( component.get('v.data.ListPrice') ));
	},

	preventShow: function(component, event, helper) {
		event.stopPropagation();
	},
})