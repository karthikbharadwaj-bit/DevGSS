({
	showOrders: function(component, event, helper) {
		var isShowOrders = component.get('v.isShowOrders');
		isShowOrders = !isShowOrders;
		component.set('v.isShowOrders', isShowOrders);
	},
})