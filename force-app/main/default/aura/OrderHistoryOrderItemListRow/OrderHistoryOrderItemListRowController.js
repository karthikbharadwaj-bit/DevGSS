({
	showOrderItems: function(component, event, helper) {
		var isShowOrderItems = component.get('v.isShowOrderItems');
		isShowOrderItems = !isShowOrderItems;
		component.set('v.isShowOrderItems', isShowOrderItems);
	},
})